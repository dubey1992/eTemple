<?php

declare(strict_types=1);

namespace Tests\Feature\Events;

use App\Models\Event;
use App\Models\Role;
use App\Models\User;
use App\Support\EventType;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Server-side authorization for the Phase 4 endpoints.
 *
 * Every case calls the API directly with a role that should be refused. The
 * specification is explicit that hiding a Flutter control is never the access
 * control, so a passing widget test could not stand in for any of these.
 */
class EventAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function actingAsRole(string $slug): User
    {
        $user = User::factory()->withRole($slug)->create();
        $this->actingAs($user, 'web');

        return $user;
    }

    /** Roles the seeded matrix does not grant `events.manage`. @return array<string, array{string}> */
    public static function rolesWithoutEventsManage(): array
    {
        return [
            'treasurer' => [Role::TREASURER],
            'viewer' => [Role::VIEWER],
        ];
    }

    /** @return array<string, mixed> */
    private function payload(): array
    {
        return [
            'event_type' => EventType::FESTIVAL,
            'title_hi' => 'घुसपैठ',
            'start_at' => '2026-10-15 18:00:00',
            'status' => Event::STATUS_PUBLISHED,
        ];
    }

    public function test_the_public_endpoints_need_no_authentication(): void
    {
        $this->getJson('/api/public/events')->assertOk();
    }

    public function test_a_guest_cannot_reach_the_admin_endpoints(): void
    {
        $event = Event::factory()->create();

        $this->getJson('/api/admin/events')->assertUnauthorized();
        $this->postJson('/api/admin/events', $this->payload())->assertUnauthorized();
        $this->putJson("/api/admin/events/{$event->id}", $this->payload())->assertUnauthorized();
        $this->deleteJson("/api/admin/events/{$event->id}")->assertUnauthorized();
    }

    #[DataProvider('rolesWithoutEventsManage')]
    public function test_a_role_without_events_manage_cannot_create(string $slug): void
    {
        $this->actingAsRole($slug);

        $this->postJson('/api/admin/events', $this->payload())
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->assertSame(0, Event::query()->count());
    }

    #[DataProvider('rolesWithoutEventsManage')]
    public function test_a_role_without_events_manage_cannot_edit_or_delete(string $slug): void
    {
        $event = Event::factory()->create();
        $this->actingAsRole($slug);

        $this->putJson("/api/admin/events/{$event->id}", $this->payload())->assertForbidden();
        $this->deleteJson("/api/admin/events/{$event->id}")->assertForbidden();

        $this->assertSame(1, Event::query()->count());
    }

    public function test_a_content_manager_holds_events_manage_by_default(): void
    {
        // The seeded matrix encodes the specification's role prose: the person
        // who runs the website's content also runs the calendar.
        $this->actingAsRole(Role::CONTENT_MANAGER);

        $this->postJson('/api/admin/events', $this->payload())->assertStatus(201);
    }

    public function test_a_viewer_may_read_the_calendar_but_not_change_it(): void
    {
        // Reading is gated on content.view, writing on events.manage, so the
        // calendar can be shown to someone who cannot edit it.
        Event::factory()->create();
        $this->actingAsRole(Role::VIEWER);

        $this->getJson('/api/admin/events')->assertOk();
        $this->postJson('/api/admin/events', $this->payload())->assertForbidden();
    }

    public function test_granting_events_manage_takes_effect_immediately(): void
    {
        $user = $this->actingAsRole(Role::VIEWER);

        $this->postJson('/api/admin/events', $this->payload())->assertForbidden();

        $role = $user->role;
        $role->permissions = [...$role->effectivePermissions(), Permission::EVENTS_MANAGE];
        $role->save();

        $this->actingAs($user->refresh(), 'web');
        $this->postJson('/api/admin/events', $this->payload())->assertStatus(201);
    }

    public function test_a_deactivated_account_loses_access_even_with_the_permission(): void
    {
        $user = User::factory()->withRole(Role::CONTENT_MANAGER)->create();
        $this->actingAs($user, 'web');
        $this->getJson('/api/admin/events')->assertOk();

        $user->forceFill(['status' => User::STATUS_INACTIVE])->save();

        $this->actingAs($user->refresh(), 'web');
        $this->getJson('/api/admin/events')->assertStatus(403);
    }

    public function test_a_super_admin_passes_every_check(): void
    {
        $this->actingAsRole(Role::SUPER_ADMIN);

        $this->postJson('/api/admin/events', $this->payload())->assertStatus(201);
    }
}
