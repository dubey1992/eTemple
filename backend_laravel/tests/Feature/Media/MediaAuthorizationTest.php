<?php

declare(strict_types=1);

namespace Tests\Feature\Media;

use App\Models\Album;
use App\Models\Media;
use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Server-side authorization for the Phase 5 endpoints.
 *
 * Every case calls the API directly with a role that should be refused. The
 * specification is explicit that hiding a Flutter control is never the access
 * control, so a passing widget test could not stand in for any of these.
 */
class MediaAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        config()->set('media.disk', 'public');
        $this->seed(RoleSeeder::class);
    }

    private function actingAsRole(string $slug): User
    {
        $user = User::factory()->withRole($slug)->create();
        $this->actingAs($user, 'web');

        return $user;
    }

    /** Roles the seeded matrix does not grant `media.manage`. @return array<string, array{string}> */
    public static function rolesWithoutMediaManage(): array
    {
        return [
            'treasurer' => [Role::TREASURER],
            'viewer' => [Role::VIEWER],
        ];
    }

    /** @return array<string, mixed> */
    private function videoPayload(): array
    {
        return [
            'external_url' => 'https://youtu.be/abcdefghijk',
            'title_hi' => 'घुसपैठ',
            'status' => Media::STATUS_PUBLISHED,
        ];
    }

    public function test_the_public_endpoints_need_no_authentication(): void
    {
        $this->getJson('/api/public/media')->assertOk();
        $this->getJson('/api/public/albums')->assertOk();
    }

    public function test_a_guest_cannot_reach_the_admin_endpoints(): void
    {
        $media = Media::factory()->create();
        $album = Album::factory()->create();

        $this->getJson('/api/admin/media')->assertUnauthorized();
        $this->postJson('/api/admin/media/video', $this->videoPayload())->assertUnauthorized();
        $this->putJson("/api/admin/media/{$media->id}", [])->assertUnauthorized();
        $this->deleteJson("/api/admin/media/{$media->id}")->assertUnauthorized();
        $this->postJson('/api/admin/media/reorder', ['ids' => [$media->id]])->assertUnauthorized();

        $this->getJson('/api/admin/albums')->assertUnauthorized();
        $this->deleteJson("/api/admin/albums/{$album->id}")->assertUnauthorized();
    }

    #[DataProvider('rolesWithoutMediaManage')]
    public function test_a_role_without_media_manage_cannot_upload_or_link(string $slug): void
    {
        $this->actingAsRole($slug);

        $this->postJson('/api/admin/media/video', $this->videoPayload())
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->assertSame(0, Media::query()->count());
    }

    #[DataProvider('rolesWithoutMediaManage')]
    public function test_a_role_without_media_manage_cannot_edit_delete_or_reorder(string $slug): void
    {
        $media = Media::factory()->create();
        $this->actingAsRole($slug);

        $this->putJson("/api/admin/media/{$media->id}", [
            'title_hi' => 'बदला हुआ',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertForbidden();

        $this->postJson('/api/admin/media/reorder', ['ids' => [$media->id]])->assertForbidden();
        $this->deleteJson("/api/admin/media/{$media->id}")->assertForbidden();

        $this->assertSame(1, Media::query()->count());
        $this->assertFalse($media->refresh()->isPublished());
    }

    #[DataProvider('rolesWithoutMediaManage')]
    public function test_a_role_without_media_manage_cannot_change_albums(string $slug): void
    {
        $album = Album::factory()->create();
        $this->actingAsRole($slug);

        $this->postJson('/api/admin/albums', [
            'title_hi' => 'नया एल्बम',
            'status' => Album::STATUS_PUBLISHED,
        ])->assertForbidden();

        $this->deleteJson("/api/admin/albums/{$album->id}")->assertForbidden();

        $this->assertSame(1, Album::query()->count());
    }

    public function test_a_content_manager_holds_media_manage_by_default(): void
    {
        // The seeded matrix encodes the specification's role prose: the person
        // who runs the website's content also runs the gallery.
        $this->actingAsRole(Role::CONTENT_MANAGER);

        $this->postJson('/api/admin/media/video', $this->videoPayload())->assertStatus(201);
    }

    public function test_a_viewer_may_read_the_library_but_not_change_it(): void
    {
        // Reading is gated on content.view, writing on media.manage, so the
        // library can be shown to someone who cannot edit it.
        Media::factory()->create();
        $this->actingAsRole(Role::VIEWER);

        $this->getJson('/api/admin/media')->assertOk();
        $this->getJson('/api/admin/albums')->assertOk();
        $this->postJson('/api/admin/media/video', $this->videoPayload())->assertForbidden();
    }

    public function test_granting_media_manage_takes_effect_immediately(): void
    {
        $user = $this->actingAsRole(Role::VIEWER);

        $this->postJson('/api/admin/media/video', $this->videoPayload())->assertForbidden();

        $role = $user->role;
        $role->permissions = [...$role->effectivePermissions(), Permission::MEDIA_MANAGE];
        $role->save();

        $this->actingAs($user->refresh(), 'web');
        $this->postJson('/api/admin/media/video', $this->videoPayload())->assertStatus(201);
    }

    public function test_a_deactivated_account_loses_access_even_with_the_permission(): void
    {
        $user = User::factory()->withRole(Role::CONTENT_MANAGER)->create();
        $this->actingAs($user, 'web');
        $this->getJson('/api/admin/media')->assertOk();

        $user->forceFill(['status' => User::STATUS_INACTIVE])->save();

        $this->actingAs($user->refresh(), 'web');
        $this->getJson('/api/admin/media')->assertStatus(403);
    }

    public function test_a_super_admin_passes_every_check(): void
    {
        $this->actingAsRole(Role::SUPER_ADMIN);

        $this->postJson('/api/admin/media/video', $this->videoPayload())->assertStatus(201);
    }

    public function test_media_manage_is_in_the_permission_catalogue(): void
    {
        // Phase 2 defined the key and labelled it "available in phase 5"; this
        // phase attached endpoints to a key the committee could already grant.
        $this->assertTrue(Permission::exists(Permission::MEDIA_MANAGE));
    }
}
