<?php

declare(strict_types=1);

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * Schema guard: the Phase 0 entity fields named by the specification must exist
 * exactly as designed, so a later migration cannot silently drop one.
 */
class MigrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_roles_table_has_the_specified_columns(): void
    {
        $this->assertTrue(Schema::hasTable('roles'));

        foreach (['id', 'slug', 'name', 'description', 'permissions', 'status', 'created_at', 'updated_at'] as $column) {
            $this->assertTrue(
                Schema::hasColumn('roles', $column),
                "roles table is missing the [{$column}] column."
            );
        }
    }

    public function test_users_table_has_the_specified_columns(): void
    {
        $this->assertTrue(Schema::hasTable('users'));

        $expected = [
            'id', 'first_name', 'last_name', 'email', 'mobile',
            'password', 'role_id', 'status', 'last_login_at',
            'created_at', 'updated_at',
        ];

        foreach ($expected as $column) {
            $this->assertTrue(
                Schema::hasColumn('users', $column),
                "users table is missing the [{$column}] column."
            );
        }
    }

    public function test_supporting_framework_tables_exist(): void
    {
        foreach (['password_reset_tokens', 'sessions', 'cache', 'jobs', 'personal_access_tokens'] as $table) {
            $this->assertTrue(Schema::hasTable($table), "Missing table [{$table}].");
        }
    }

    public function test_pages_table_has_the_specified_columns(): void
    {
        $this->assertTrue(Schema::hasTable('pages'));

        $expected = [
            'id', 'slug',
            'title_hi', 'title_en', 'content_hi', 'content_en',
            'meta_title_hi', 'meta_title_en',
            'meta_description_hi', 'meta_description_en',
            'status', 'published_at', 'updated_by',
            'created_at', 'updated_at',
        ];

        foreach ($expected as $column) {
            $this->assertTrue(
                Schema::hasColumn('pages', $column),
                "pages table is missing the [{$column}] column."
            );
        }
    }

    public function test_site_settings_and_navigation_tables_exist(): void
    {
        $this->assertTrue(Schema::hasTable('site_settings'));
        $this->assertTrue(Schema::hasTable('navigation_items'));

        foreach (['tagline_hi', 'tagline_en', 'footer_text_hi', 'village', 'district',
            'contact_email', 'map_url', 'social_links',
            'default_meta_title_hi', 'default_meta_description_en'] as $column) {
            $this->assertTrue(
                Schema::hasColumn('site_settings', $column),
                "site_settings table is missing the [{$column}] column."
            );
        }

        foreach (['label_hi', 'label_en', 'route', 'sort_order', 'is_visible'] as $column) {
            $this->assertTrue(
                Schema::hasColumn('navigation_items', $column),
                "navigation_items table is missing the [{$column}] column."
            );
        }
    }

    public function test_login_attempts_table_records_the_history(): void
    {
        $this->assertTrue(Schema::hasTable('login_attempts'));

        foreach (['id', 'user_id', 'email', 'outcome', 'ip_address', 'user_agent', 'created_at'] as $column) {
            $this->assertTrue(
                Schema::hasColumn('login_attempts', $column),
                "login_attempts table is missing the [{$column}] column."
            );
        }
    }
}
