<?php

declare(strict_types=1);

namespace Tests\Feature\Content;

use App\Models\Page;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPageEditingTest extends TestCase
{
    use RefreshDatabase;

    private User $editor;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->editor = User::factory()->withRole(Role::CONTENT_MANAGER)->create();
    }

    /** @param array<string, mixed> $overrides */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'title_hi' => 'हमारे बारे में',
            'content_hi' => 'मंदिर की जानकारी।',
            'status' => Page::STATUS_DRAFT,
        ], $overrides);
    }

    public function test_the_editor_sees_drafts_and_both_languages_raw(): void
    {
        $page = Page::factory()->hindiOnly()->create(['slug' => 'about']);

        $this->actingAs($this->editor, 'web')
            ->getJson("/api/admin/pages/{$page->id}")
            ->assertOk()
            // No fallback is applied here: the editor must see that English is empty.
            ->assertJsonPath('data.title_en', null)
            ->assertJsonPath('data.status', Page::STATUS_DRAFT);
    }

    public function test_the_page_list_is_paginated_with_the_shared_meta_convention(): void
    {
        Page::factory()->count(3)->create();

        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/pages?per_page=2')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.has_more', true)
            ->assertJsonCount(2, 'data');
    }

    public function test_an_edit_is_saved_and_attributed_to_the_editor(): void
    {
        $page = Page::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['title_hi' => 'नया']))
            ->assertOk()
            ->assertJsonPath('data.title_hi', 'नया');

        $this->assertSame($this->editor->id, $page->fresh()->updated_by);
    }

    public function test_publishing_stamps_published_at_once_and_never_moves_it(): void
    {
        $page = Page::factory()->create();
        $this->assertNull($page->published_at);

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['status' => Page::STATUS_PUBLISHED]))
            ->assertOk();

        $firstPublishedAt = $page->fresh()->published_at;
        $this->assertNotNull($firstPublishedAt);

        // Unpublish, then publish again: the original date must survive.
        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['status' => Page::STATUS_DRAFT]))
            ->assertOk();
        $this->assertEquals($firstPublishedAt, $page->fresh()->published_at);

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['status' => Page::STATUS_PUBLISHED]))
            ->assertOk();
        $this->assertEquals($firstPublishedAt, $page->fresh()->published_at);
    }

    public function test_the_slug_cannot_be_changed_through_the_editor(): void
    {
        $page = Page::factory()->create(['slug' => 'about']);

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['slug' => 'hijacked']))
            ->assertOk();

        $this->assertSame('about', $page->fresh()->slug);
    }

    public function test_hindi_is_required_but_english_is_optional(): void
    {
        $page = Page::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", ['status' => Page::STATUS_DRAFT])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure(['error' => ['details' => ['title_hi', 'content_hi']]]);

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['title_en' => null, 'content_en' => null]))
            ->assertOk();
    }

    public function test_an_unknown_status_is_rejected(): void
    {
        $page = Page::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['status' => 'archived']))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['status']]]);
    }

    public function test_editing_a_missing_page_returns_not_found(): void
    {
        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/pages/999999', $this->payload())
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_publishing_makes_the_page_publicly_visible(): void
    {
        $page = Page::factory()->create(['slug' => 'about']);

        $this->getJson('/api/public/pages/about')->assertNotFound();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload(['status' => Page::STATUS_PUBLISHED]))
            ->assertOk();

        $this->getJson('/api/public/pages/about')
            ->assertOk()
            ->assertJsonPath('data.title.value', 'हमारे बारे में');
    }
}
