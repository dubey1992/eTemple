<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Models\Role;
use App\Support\Permission;
use Tests\TestCase;

/**
 * The catalogue is the contract the whole matrix rests on, and the defaults
 * encode the role descriptions the specification gives in prose.
 */
class PermissionCatalogueTest extends TestCase
{
    public function test_every_key_is_module_dot_action_and_unique(): void
    {
        $keys = Permission::all();

        $this->assertNotEmpty($keys);
        $this->assertSame($keys, array_values(array_unique($keys)), 'duplicate permission key');

        foreach ($keys as $key) {
            $this->assertMatchesRegularExpression(
                '/^[a-z]+\.[a-z_]+$/',
                $key,
                "[{$key}] is not in module.action form",
            );
        }
    }

    public function test_catalogue_labels_and_phases_are_present(): void
    {
        foreach (Permission::catalogue() as $module => $definition) {
            $this->assertNotEmpty($definition['label'], "module [{$module}] has no label");
            $this->assertIsInt($definition['phase']);
            $this->assertNotEmpty($definition['permissions']);
        }
    }

    public function test_exists_recognises_only_catalogue_keys(): void
    {
        $this->assertTrue(Permission::exists(Permission::CONTENT_MANAGE));
        $this->assertFalse(Permission::exists('content.destroy-everything'));
        $this->assertFalse(Permission::exists(''));
    }

    public function test_defaults_reference_only_real_keys(): void
    {
        foreach (Permission::defaultsByRole() as $role => $keys) {
            foreach ($keys as $key) {
                $this->assertTrue(
                    Permission::exists($key),
                    "role [{$role}] defaults to unknown key [{$key}]",
                );
            }
        }
    }

    public function test_super_admin_is_not_given_a_stored_default_set(): void
    {
        // Its set is computed, so storing one would be a second source of truth
        // that could drift and lock the temple out.
        $this->assertArrayNotHasKey(Role::SUPER_ADMIN, Permission::defaultsByRole());
    }

    public function test_a_treasurer_runs_money_but_not_security(): void
    {
        $treasurer = Permission::defaultsByRole()[Role::TREASURER];

        $this->assertContains(Permission::DONATIONS_MANAGE, $treasurer);
        $this->assertContains(Permission::ACCOUNTS_MANAGE, $treasurer);
        $this->assertContains(Permission::REPORTS_VIEW, $treasurer);

        $this->assertNotContains(Permission::SECURITY_MANAGE, $treasurer);
        $this->assertNotContains(Permission::USERS_MANAGE, $treasurer);
        $this->assertNotContains(Permission::ROLES_MANAGE, $treasurer);
        $this->assertNotContains(Permission::CONTENT_MANAGE, $treasurer);
    }

    public function test_a_content_manager_never_sees_financial_detail(): void
    {
        $contentManager = Permission::defaultsByRole()[Role::CONTENT_MANAGER];

        $this->assertContains(Permission::CONTENT_MANAGE, $contentManager);
        $this->assertContains(Permission::MEDIA_MANAGE, $contentManager);
        $this->assertContains(Permission::EVENTS_MANAGE, $contentManager);

        // The specification is explicit about this one.
        $this->assertNotContains(Permission::DONATIONS_VIEW, $contentManager);
        $this->assertNotContains(Permission::DONATIONS_MANAGE, $contentManager);
        $this->assertNotContains(Permission::ACCOUNTS_VIEW, $contentManager);
        $this->assertNotContains(Permission::ACCOUNTS_MANAGE, $contentManager);
    }

    public function test_an_admin_cannot_reshape_roles_or_security_by_default(): void
    {
        $admin = Permission::defaultsByRole()[Role::ADMIN];

        $this->assertContains(Permission::USERS_MANAGE, $admin);
        $this->assertContains(Permission::CONTENT_MANAGE, $admin);
        $this->assertNotContains(Permission::ROLES_MANAGE, $admin);
        $this->assertNotContains(Permission::SECURITY_MANAGE, $admin);
    }

    public function test_a_viewer_can_only_view(): void
    {
        foreach (Permission::defaultsByRole()[Role::VIEWER] as $key) {
            $this->assertStringEndsWith('.view', $key, "viewer was granted [{$key}]");
        }
    }
}
