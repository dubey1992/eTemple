<?php

declare(strict_types=1);

namespace Tests\Feature\Accounting;

use App\Models\AccountingCategory;
use App\Models\Role;
use App\Models\Transaction;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

/**
 * Bills: what is accepted, where they live, and who may read one.
 *
 * The type is decided by **reading the file**, never by its name or the
 * browser's `Content-Type` — Phase 5's rule, applied to the one place in this
 * phase that touches disk.
 */
class AttachmentTest extends TestCase
{
    use RefreshDatabase;

    private User $treasurer;

    private AccountingCategory $category;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        Storage::fake('local');

        $this->treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $this->category = AccountingCategory::factory()->expense()->create();
        $this->actingAs($this->treasurer, 'web');
    }

    /** @param array<string, mixed> $extra */
    private function record(array $extra = []): TestResponse
    {
        return $this->post('/api/admin/transactions', array_merge([
            'amount' => '1200',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->category->id,
            'payment_mode' => 'cash',
        ], $extra));
    }

    public function test_a_photograph_of_a_bill_is_stored_on_the_private_disk(): void
    {
        $id = $this->record([
            'attachment' => UploadedFile::fake()->image('bill.jpg', 800, 600),
        ])->assertCreated()->json('data.id');

        $transaction = Transaction::query()->findOrFail($id);

        Storage::disk('local')->assertExists($transaction->attachment_path);
        $this->assertStringStartsWith('accounts/attachments/', $transaction->attachment_path);
        $this->assertSame('image/jpeg', $transaction->attachment_mime);
    }

    public function test_a_pdf_is_accepted_because_that_is_what_a_bank_sends(): void
    {
        $pdf = UploadedFile::fake()->createWithContent(
            'statement.pdf',
            "%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n%%EOF\n",
        );

        $id = $this->record(['attachment' => $pdf])->assertCreated()->json('data.id');

        $this->assertSame('application/pdf', Transaction::query()->findOrFail($id)->attachment_mime);
    }

    public function test_a_script_renamed_to_jpg_is_refused_by_its_bytes(): void
    {
        $disguised = UploadedFile::fake()->createWithContent(
            'bill.jpg',
            "<?php echo 'this is not a photograph'; ?>",
        );

        $this->record(['attachment' => $disguised])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['attachment']]]);

        $this->assertSame(0, Transaction::query()->count());
    }

    public function test_an_svg_is_refused(): void
    {
        $svg = UploadedFile::fake()->createWithContent(
            'bill.svg',
            '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>',
        );

        $this->record(['attachment' => $svg])->assertStatus(422);
    }

    public function test_the_stored_name_is_generated_not_the_uploaders(): void
    {
        $id = $this->record([
            'attachment' => UploadedFile::fake()->image('../../etc/passwd.jpg', 100, 100),
        ])->assertCreated()->json('data.id');

        $transaction = Transaction::query()->findOrFail($id);

        // The path is a uuid on the configured prefix; the original name is
        // kept only for display, with its separators stripped.
        $this->assertStringNotContainsString('passwd', $transaction->attachment_path);
        $this->assertStringNotContainsString('..', $transaction->attachment_path);
        $this->assertStringNotContainsString('/', (string) $transaction->attachment_name);
    }

    public function test_the_bill_is_streamed_back_as_a_download_never_rendered(): void
    {
        $id = $this->record([
            'attachment' => UploadedFile::fake()->image('bill.jpg', 200, 200),
        ])->assertCreated()->json('data.id');

        $response = $this->get("/api/admin/transactions/{$id}/attachment")->assertOk();

        $this->assertSame('image/jpeg', $response->headers->get('Content-Type'));
        $this->assertStringStartsWith('attachment;', (string) $response->headers->get('Content-Disposition'));
        $this->assertSame('nosniff', $response->headers->get('X-Content-Type-Options'));
    }

    public function test_replacing_a_bill_removes_the_one_it_replaced(): void
    {
        $id = $this->record([
            'attachment' => UploadedFile::fake()->image('first.jpg', 200, 200),
        ])->assertCreated()->json('data.id');

        $first = Transaction::query()->findOrFail($id)->attachment_path;

        $this->post("/api/admin/transactions/{$id}", [
            '_method' => 'PUT',
            'amount' => '1200',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->category->id,
            'payment_mode' => 'cash',
            'attachment' => UploadedFile::fake()->image('second.jpg', 200, 200),
        ])->assertOk();

        $second = Transaction::query()->findOrFail($id)->attachment_path;

        $this->assertNotSame($first, $second);
        Storage::disk('local')->assertMissing($first);
        Storage::disk('local')->assertExists($second);
    }

    /**
     * A bill on an approved entry is part of the evidence for a figure the
     * village has read. Replacing it is not an edit to a note.
     */
    public function test_the_bill_on_an_approved_entry_cannot_be_replaced(): void
    {
        $id = $this->record([
            'attachment' => UploadedFile::fake()->image('bill.jpg', 200, 200),
        ])->assertCreated()->json('data.id');

        $this->postJson("/api/admin/transactions/{$id}/approve")->assertOk();

        $original = Transaction::query()->findOrFail($id)->attachment_path;

        $this->post("/api/admin/transactions/{$id}", [
            '_method' => 'PUT',
            'amount' => '1200',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->category->id,
            'payment_mode' => 'cash',
            'attachment' => UploadedFile::fake()->image('other.jpg', 200, 200),
        ])->assertStatus(409);

        $this->assertSame($original, Transaction::query()->findOrFail($id)->attachment_path);
    }

    public function test_a_reversal_keeps_its_bill(): void
    {
        $id = $this->record([
            'attachment' => UploadedFile::fake()->image('bill.jpg', 200, 200),
        ])->assertCreated()->json('data.id');

        $path = Transaction::query()->findOrFail($id)->attachment_path;

        $this->postJson("/api/admin/transactions/{$id}/reverse", [
            'reversal_reason' => 'गलत श्रेणी में दर्ज',
        ])->assertOk();

        Storage::disk('local')->assertExists($path);
        $this->assertSame($path, Transaction::query()->findOrFail($id)->attachment_path);
    }
}
