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

        foreach (['tagline_hi', 'tagline_en', 'footer_text_hi',
            'contact_phone', 'contact_email', 'social_links',
            'default_meta_title_hi', 'default_meta_description_en'] as $column) {
            $this->assertTrue(
                Schema::hasColumn('site_settings', $column),
                "site_settings table is missing the [{$column}] column."
            );
        }

        // Phase 3 moved the address to temple_profiles. A move, not a copy:
        // these columns must be gone, or the site has two addresses.
        foreach (['address_line1', 'village', 'panchayat', 'police_station',
            'district', 'state', 'postal_code', 'country', 'map_url'] as $column) {
            $this->assertFalse(
                Schema::hasColumn('site_settings', $column),
                "site_settings still has the [{$column}] column; the address was supposed to move."
            );
        }

        foreach (['label_hi', 'label_en', 'route', 'sort_order', 'is_visible'] as $column) {
            $this->assertTrue(
                Schema::hasColumn('navigation_items', $column),
                "navigation_items table is missing the [{$column}] column."
            );
        }
    }

    public function test_temple_profile_table_owns_the_identity_and_address(): void
    {
        $this->assertTrue(Schema::hasTable('temple_profiles'));

        $expected = [
            'id', 'name_hi', 'name_en',
            'history_hi', 'history_en', 'mission_hi', 'mission_en',
            // Bilingual since the prototype match: `अमरपुर पंखोरिया` and
            // `Amarpur Pankhoriya` are one village in two scripts.
            'address_line1_hi', 'address_line1_en',
            'address_line2_hi', 'address_line2_en',
            'village_hi', 'village_en',
            'panchayat_hi', 'panchayat_en',
            'police_station_hi', 'police_station_en',
            'district_hi', 'district_en',
            'state_hi', 'state_en',
            'postal_code',
            'country_hi', 'country_en',
            'logo_url', 'map_url', 'established_year',
            'updated_by', 'created_at', 'updated_at',
        ];

        foreach ($expected as $column) {
            $this->assertTrue(
                Schema::hasColumn('temple_profiles', $column),
                "temple_profiles table is missing the [{$column}] column."
            );
        }
    }

    public function test_committee_members_table_carries_the_consent_record(): void
    {
        $this->assertTrue(Schema::hasTable('committee_members'));

        $expected = [
            'id', 'name_hi', 'name_en', 'designation_hi', 'designation_en',
            'bio_hi', 'bio_en', 'phone', 'email', 'photo_url',
            'tenure_start', 'tenure_end', 'is_published',
            'contact_consent_at', 'consent_recorded_by',
            'show_phone_publicly', 'show_email_publicly', 'show_photo_publicly',
            'sort_order', 'created_by', 'updated_by', 'created_at', 'updated_at',
        ];

        foreach ($expected as $column) {
            $this->assertTrue(
                Schema::hasColumn('committee_members', $column),
                "committee_members table is missing the [{$column}] column."
            );
        }
    }

    public function test_events_table_stores_the_recurrence_rule(): void
    {
        $this->assertTrue(Schema::hasTable('events'));

        $expected = [
            'id', 'event_type',
            'title_hi', 'title_en', 'description_hi', 'description_en',
            'venue_hi', 'venue_en',
            'start_at', 'end_at',
            'recurrence', 'recurrence_days', 'recurrence_until',
            'poster_url', 'is_featured', 'status',
            'created_by', 'updated_by', 'created_at', 'updated_at',
        ];

        foreach ($expected as $column) {
            $this->assertTrue(
                Schema::hasColumn('events', $column),
                "events table is missing the [{$column}] column."
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
