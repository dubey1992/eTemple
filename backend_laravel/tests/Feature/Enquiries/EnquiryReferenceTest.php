<?php

declare(strict_types=1);

namespace Tests\Feature\Enquiries;

use App\Models\Enquiry;
use App\Services\Enquiries\EnquiryReferenceGenerator;
use App\Support\EnquiryCategory;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/**
 * The reference a villager quotes when they telephone the temple.
 */
class EnquiryReferenceTest extends TestCase
{
    use RefreshDatabase;

    private EnquiryReferenceGenerator $generator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->generator = app(EnquiryReferenceGenerator::class);
    }

    public function test_the_financial_year_runs_april_to_march(): void
    {
        // The boundary, from both sides: 31 March is still the old year.
        $this->assertSame('2025-26', $this->generator->financialYearLabel(Carbon::parse('2026-03-31')));
        $this->assertSame('2026-27', $this->generator->financialYearLabel(Carbon::parse('2026-04-01')));
        $this->assertSame('2026-27', $this->generator->financialYearLabel(Carbon::parse('2026-12-31')));
        $this->assertSame('2026-27', $this->generator->financialYearLabel(Carbon::parse('2027-01-01')));

        // A century roll-over must not produce "2099-100".
        $this->assertSame('2099-00', $this->generator->financialYearLabel(Carbon::parse('2099-05-01')));
    }

    public function test_the_sequence_restarts_each_financial_year(): void
    {
        Enquiry::factory()->create(['reference' => 'RKT/E/2025-26/0007']);

        $this->assertSame(1, $this->generator->nextSequence('2026-27'));
        $this->assertSame(8, $this->generator->nextSequence('2025-26'));
    }

    public function test_the_sequence_reads_the_highest_not_the_count(): void
    {
        // Nothing is deleted here, but a spam row still holds its reference,
        // and numbering that started above one must not collide.
        Enquiry::factory()->create(['reference' => 'RKT/E/2026-27/0050']);
        Enquiry::factory()->spam()->create(['reference' => 'RKT/E/2026-27/0051']);

        $this->assertSame(52, $this->generator->nextSequence('2026-27'));
    }

    public function test_the_sequence_orders_by_number_not_by_string(): void
    {
        // '0009' sorts after '0010' only if length is ignored; with four digits
        // it cannot happen, but the numbering must survive outgrowing them.
        Enquiry::factory()->create(['reference' => 'RKT/E/2026-27/9999']);
        Enquiry::factory()->create(['reference' => 'RKT/E/2026-27/10000']);

        $this->assertSame(10001, $this->generator->nextSequence('2026-27'));
    }

    public function test_the_database_refuses_a_duplicate_reference(): void
    {
        Enquiry::factory()->create(['reference' => 'RKT/E/2026-27/0001']);

        // Uniqueness is the index, not the application's arithmetic.
        $this->expectException(QueryException::class);
        Enquiry::factory()->create(['reference' => 'RKT/E/2026-27/0001']);
    }

    public function test_every_category_has_a_bilingual_label(): void
    {
        foreach (EnquiryCategory::all() as $code) {
            $label = EnquiryCategory::label($code);

            $this->assertNotSame($code, $label, "{$code} has no label");
            // The acknowledgement e-mail is rendered by the server and cannot
            // reach Flutter's translations, so the words live here too.
            $this->assertMatchesRegularExpression('/\p{Devanagari}/u', $label);
        }

        $this->assertSame('अन्य / Other', EnquiryCategory::label('a-code-from-the-future'));
    }
}
