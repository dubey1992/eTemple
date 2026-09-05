<?php

declare(strict_types=1);

namespace Tests\Feature\Reports;

use App\Models\Donation;
use App\Models\Role;
use App\Models\User;
use App\Reports\ReportRunner;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use ZipArchive;

/**
 * The three formats.
 *
 * Most of these are about a file arriving intact and harmless on a committee
 * member's Windows laptop, which is the only place these files are ever going
 * to be opened.
 */
class ReportExportTest extends TestCase
{
    use RefreshDatabase;

    private User $treasurer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        $this->treasurer = User::factory()->withRole(Role::TREASURER)->create();

        Donation::factory()->confirmed()->ofRupees(1_200)->create([
            'donor_name' => 'रामप्रसाद यादव',
            'donation_date' => now()->subDays(5)->toDateString(),
        ]);

        $this->actingAs($this->treasurer, 'web');
    }

    private function download(string $format, string $extra = ''): string
    {
        return $this->get("/api/admin/reports/donations/export?format={$format}{$extra}")
            ->assertOk()
            ->getContent();
    }

    /**
     * Without a byte-order mark, Excel on Windows opens a UTF-8 CSV as
     * Windows-1252 and every Hindi name becomes mojibake — the most likely
     * first experience of this feature.
     */
    public function test_the_csv_begins_with_a_byte_order_mark(): void
    {
        $csv = $this->download('csv');

        $this->assertStringStartsWith("\xEF\xBB\xBF", $csv);
    }

    public function test_the_csv_uses_crlf_line_endings(): void
    {
        $csv = $this->download('csv');

        $this->assertStringContainsString("\r\n", $csv);
        // No bare LF anywhere: every newline is part of a CRLF pair.
        $this->assertSame(
            substr_count($csv, "\n"),
            substr_count($csv, "\r\n"),
        );
    }

    /**
     * Money as a plain decimal, so the treasurer can select the column and see
     * a total. The rupee symbol would make it text.
     */
    public function test_money_is_a_plain_decimal_in_the_csv(): void
    {
        $csv = $this->download('csv');

        $this->assertStringContainsString('1200.00', $csv);
        $this->assertStringNotContainsString('₹1,200.00', $csv);
    }

    /**
     * A donor recorded as a formula is an attack carried out by the reader's
     * own spreadsheet, and the temple would be the one that handed them the
     * file.
     */
    public function test_a_cell_that_looks_like_a_formula_cannot_execute(): void
    {
        Donation::factory()->confirmed()->ofRupees(100)->create([
            'donor_name' => '=HYPERLINK("http://evil.example","Click")',
            'donation_date' => now()->subDays(2)->toDateString(),
        ]);

        $csv = $this->download('csv', '&include_personal=1');

        // Present, and neutralised: the apostrophe is what stops Excel and
        // LibreOffice evaluating it, and both strip it on display.
        $this->assertStringContainsString('"\'=HYPERLINK', $csv);
        $this->assertStringNotContainsString('"=HYPERLINK', $csv);
    }

    public function test_the_csv_carries_the_header_block_and_the_figures(): void
    {
        $csv = $this->download('csv');

        // What it is, what it was filtered to, and when it was made.
        $this->assertStringContainsString('रिपोर्ट', $csv);
        $this->assertStringContainsString('छाँट', $csv);
        $this->assertStringContainsString('तैयार किया', $csv);
        $this->assertStringContainsString($this->treasurer->fullName(), $csv);
    }

    /**
     * The workbook is written by hand, so the gate reads it back rather than
     * hoping (PHASE_10_PLAN assumption N4). This asserts the package structure;
     * `xlsx_readback.py` in the delivery gate parses it with an independent
     * reader.
     */
    public function test_the_xlsx_is_a_well_formed_package(): void
    {
        $bytes = $this->download('xlsx');

        $path = tempnam(sys_get_temp_dir(), 'rkt-test-');
        file_put_contents($path, $bytes);

        $zip = new ZipArchive;
        $this->assertTrue($zip->open($path) === true, 'the workbook is not a readable zip');

        foreach ([
            '[Content_Types].xml',
            '_rels/.rels',
            'xl/workbook.xml',
            'xl/_rels/workbook.xml.rels',
            'xl/styles.xml',
            'xl/worksheets/sheet1.xml',
        ] as $part) {
            $this->assertNotFalse($zip->locateName($part), "missing part: {$part}");
        }

        $sheet = (string) $zip->getFromName('xl/worksheets/sheet1.xml');
        $zip->close();
        @unlink($path);

        // Every part must parse, or Excel refuses the whole file rather than
        // complaining about one cell.
        $this->assertNotFalse(simplexml_load_string($sheet), 'sheet1.xml is not valid XML');

        // Money as a number, not a string: a column of text cannot be summed.
        $this->assertStringContainsString('<v>1200.00</v>', $sheet);

        // A workbook is a zip, so its text lives inside a member rather than in
        // the bytes — which is also why the delivery gate opens one with an
        // independent reader rather than grepping it.
        $this->assertStringContainsString(
            'रामप्रसाद',
            $this->sheetXml($this->download('xlsx', '&include_personal=1')),
        );
    }

    /** The worksheet XML from a workbook's bytes. */
    private function sheetXml(string $bytes): string
    {
        $path = tempnam(sys_get_temp_dir(), 'rkt-test-');
        file_put_contents($path, $bytes);

        $zip = new ZipArchive;
        $zip->open($path);
        $sheet = (string) $zip->getFromName('xl/worksheets/sheet1.xml');
        $zip->close();
        @unlink($path);

        return $sheet;
    }

    public function test_the_xlsx_strips_control_characters_that_would_break_it(): void
    {
        Donation::factory()->confirmed()->ofRupees(100)->create([
            'donor_name' => "बिल\x07 संख्या",
            'donation_date' => now()->subDays(2)->toDateString(),
        ]);

        $sheet = $this->sheetXml($this->download('xlsx', '&include_personal=1'));

        $this->assertStringNotContainsString("\x07", $sheet);
        $this->assertNotFalse(simplexml_load_string($sheet));
    }

    /**
     * The "PDF" format is a print-ready document, for the reason
     * `ReceiptRenderer` gives: no PHP PDF library shapes Devanagari.
     */
    public function test_the_pdf_format_is_a_printable_html_document(): void
    {
        $response = $this->get('/api/admin/reports/donations/export?format=pdf')->assertOk();

        $this->assertStringContainsString(
            'text/html',
            (string) $response->headers->get('Content-Type'),
        );
        // Opened in a tab to be printed, not downloaded.
        $this->assertStringStartsWith(
            'inline;',
            (string) $response->headers->get('Content-Disposition'),
        );

        $html = $response->getContent();
        $this->assertStringContainsString('@media print', $html);
        $this->assertStringContainsString('window.print()', $html);
        // A long report runs to several sheets; the heading row has to repeat.
        $this->assertStringContainsString('display: table-header-group', $html);
        // Money is formatted for a person here, unlike the spreadsheet formats.
        $this->assertStringContainsString('₹1,200.00', $html);
    }

    public function test_the_printable_document_escapes_what_it_prints(): void
    {
        Donation::factory()->confirmed()->ofRupees(100)->create([
            'donor_name' => '<script>alert(1)</script>',
            'donation_date' => now()->subDays(2)->toDateString(),
        ]);

        $html = $this->get('/api/admin/reports/donations/export?format=pdf&include_personal=1')
            ->assertOk()
            ->getContent();

        $this->assertStringNotContainsString('<script>alert(1)</script>', $html);
        $this->assertStringContainsString('&lt;script&gt;', $html);
    }

    public function test_csv_and_xlsx_are_downloads_with_a_dated_name(): void
    {
        foreach (['csv', 'xlsx'] as $format) {
            $response = $this->get("/api/admin/reports/donations/export?format={$format}")
                ->assertOk();

            $disposition = (string) $response->headers->get('Content-Disposition');

            $this->assertStringStartsWith('attachment;', $disposition);
            $this->assertStringContainsString('donations-'.now()->format('Y-m-d'), $disposition);
            $this->assertSame('nosniff', $response->headers->get('X-Content-Type-Options'));
        }
    }

    public function test_an_unknown_format_is_refused_by_name(): void
    {
        $this->getJson('/api/admin/reports/donations/export?format=docx')
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
    }

    public function test_the_export_limit_is_a_real_ceiling(): void
    {
        $this->assertSame(10_000, ReportRunner::EXPORT_LIMIT);
    }
}
