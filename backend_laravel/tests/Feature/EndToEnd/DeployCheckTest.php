<?php

declare(strict_types=1);

namespace Tests\Feature\EndToEnd;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * The check that checks the deployment.
 *
 * **A check that passes everywhere proves nothing**, so most of this file is
 * about making `deploy:check` fail: a development environment must be rejected,
 * and each individual danger must be caught on its own, with the others healthy,
 * so that a green run means something (PHASE_12_PLAN §C2).
 */
class DeployCheckTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    /**
     * Everything a real deployment would have set, so that a single sabotage
     * in each test below is the *only* thing wrong.
     */
    private function productionConfiguration(): void
    {
        config([
            'app.env' => 'production',
            'app.debug' => false,
            'app.key' => 'base64:'.base64_encode(random_bytes(32)),
            'app.url' => 'https://api.radhakrishnathakurwadi.com',
            'app.frontend_url' => 'https://radhakrishnathakurwadi.com',
            'app.timezone' => 'Asia/Kolkata',
            'session.secure' => true,
            'session.http_only' => true,
            'session.same_site' => 'lax',
            'cors.allowed_origins' => ['https://radhakrishnathakurwadi.com'],
            'sanctum.stateful' => ['radhakrishnathakurwadi.com'],
            'mail.default' => 'smtp',
            'mail.from.address' => 'no-reply@radhakrishnathakurwadi.com',
            'queue.default' => 'sync',
            'announcements.channels.sms.enabled' => false,
            'announcements.channels.whatsapp.enabled' => false,
            'accounting.attachments.disk' => 'local',
            'media.disk' => 'local',
        ]);

        app()->detectEnvironment(static fn (): string => 'production');

        User::factory()->withRole(Role::SUPER_ADMIN)->create([
            'email' => 'chair@radhakrishnathakurwadi.com',
            'status' => User::STATUS_ACTIVE,
        ]);
    }

    /**
     * Set a real environment value for the duration of one test.
     *
     * `putenv()` alone is not enough: the `.env` file's own value is already in
     * `$_ENV` and `$_SERVER`, and the repository reads those adapters before
     * the putenv one — so the empty value from `.env` would keep winning. These
     * are the two the repository actually consults.
     */
    private function withEnvironmentValue(string $key, string $value): void
    {
        $previousEnv = $_ENV[$key] ?? null;
        $previousServer = $_SERVER[$key] ?? null;

        $_ENV[$key] = $value;
        $_SERVER[$key] = $value;

        $this->beforeApplicationDestroyed(static function () use ($key, $previousEnv, $previousServer): void {
            if ($previousEnv === null) {
                unset($_ENV[$key]);
            } else {
                $_ENV[$key] = $previousEnv;
            }

            if ($previousServer === null) {
                unset($_SERVER[$key]);
            } else {
                $_SERVER[$key] = $previousServer;
            }
        });
    }

    /** Runs the command and returns [exit code, output]. */
    private function runCheck(): array
    {
        $exit = Artisan::call('deploy:check');

        return [$exit, Artisan::output()];
    }

    /**
     * The whole point. A machine set up for development is not a machine the
     * village should be pointed at, and the command says so.
     */
    public function test_it_refuses_a_development_environment(): void
    {
        [$exit, $output] = $this->runCheck();
        $this->assertSame(1, $exit);

        // Named individually, because a failure that says only "not ready" is
        // not a failure anybody can act on.
        $this->assertStringContainsString('APP_DEBUG is off', $output);
        $this->assertStringContainsString('Mail goes somewhere real', $output);
    }

    public function test_a_correctly_configured_deployment_passes_its_configuration_checks(): void
    {
        $this->productionConfiguration();

        [, $output] = $this->runCheck();

        foreach ([
            'APP_ENV is production',
            'APP_DEBUG is off',
            'APP_URL is https',
            'The session cookie is HTTPS-only',
            'CORS names exact origins',
            'Every allowed origin is https',
            'The site host is stateful for Sanctum',
            'Mail goes somewhere real',
            'Ledger bills are on a private disk',
            'The roles are seeded',
            'There is at least one active Super Admin',
            'No demo accounts remain',
        ] as $check) {
            $this->assertMatchesRegularExpression(
                '/ok\s+'.preg_quote($check, '/').'/',
                $output,
                "{$check} should have passed",
            );
        }
    }

    public function test_debug_left_on_is_caught(): void
    {
        $this->productionConfiguration();
        config(['app.debug' => true]);

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+APP_DEBUG is off/', $output);
    }

    /**
     * A wildcard origin cannot be combined with credentials — the browser
     * refuses the pairing — so this would not be a subtle failure. It would be
     * a site where nobody can sign in.
     */
    public function test_a_wildcard_cors_origin_is_caught(): void
    {
        $this->productionConfiguration();
        config(['cors.allowed_origins' => ['*']]);

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+CORS names exact origins/', $output);
    }

    public function test_bills_on_a_public_disk_are_caught(): void
    {
        $this->productionConfiguration();
        config(['accounting.attachments.disk' => 'public']);

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+Ledger bills are on a private disk/', $output);
    }

    public function test_a_site_with_no_super_admin_is_caught(): void
    {
        $this->productionConfiguration();
        User::query()->delete();

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+There is at least one active Super Admin/', $output);
    }

    public function test_demo_accounts_left_behind_are_caught(): void
    {
        $this->productionConfiguration();
        User::factory()->withRole(Role::TREASURER)->create([
            'email' => 'demo.treasurer@thakurbari.local',
        ]);

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+No demo accounts remain/', $output);
    }

    /**
     * The failure this project has feared since Phase 8: an announcement the
     * committee believes went out, sitting in a table because no worker is
     * running. Old jobs are the evidence, and this is the only place anything
     * looks for it.
     */
    public function test_a_queue_with_no_worker_behind_it_is_caught(): void
    {
        $this->productionConfiguration();
        config(['queue.default' => 'database']);

        DB::table('jobs')->insert([
            'queue' => 'default',
            'payload' => '{}',
            'attempts' => 0,
            'reserved_at' => null,
            'available_at' => now()->subHour()->getTimestamp(),
            'created_at' => now()->subHour()->getTimestamp(),
        ]);

        [$exit, $output] = $this->runCheck();
        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+A queue worker is running/', $output);
        $this->assertStringContainsString('recorded as sent', $output);
    }

    /**
     * Turning on a channel with no provider behind it makes a send appear to
     * succeed and deliver nothing — worse than not offering the channel.
     */
    public function test_a_channel_with_no_provider_is_caught(): void
    {
        $this->productionConfiguration();
        config(['announcements.channels.sms.enabled' => true]);

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression('/XX\s+Announcement channels have providers behind them/', $output);
    }

    /**
     * An empty `DEV_ADMIN_EMAIL=` is the correct production state, not a
     * finding.
     *
     * The committed template ships the key present and empty so it is visibly
     * unset, and `env()` returns "" rather than null for that. Reading it as
     * "configured" failed a correctly deployed site — found on the real host on
     * 2026-09-06, where every other check passed.
     */
    public function test_an_empty_dev_admin_setting_is_not_a_finding(): void
    {
        $this->productionConfiguration();
        $this->withEnvironmentValue('DEV_ADMIN_EMAIL', '');

        [, $output] = $this->runCheck();

        $this->assertMatchesRegularExpression(
            '/ok\s+No development administrator is configured/',
            $output,
        );
    }

    public function test_a_dev_admin_that_really_is_set_is_caught(): void
    {
        $this->productionConfiguration();
        $this->withEnvironmentValue('DEV_ADMIN_EMAIL', 'admin@example.test');

        [$exit, $output] = $this->runCheck();

        $this->assertSame(1, $exit);
        $this->assertMatchesRegularExpression(
            '/XX\s+No development administrator is configured/',
            $output,
        );
    }

    /**
     * The two things PHP cannot see from inside itself are said out loud rather
     * than quietly omitted.
     */
    public function test_it_names_what_it_cannot_check_itself(): void
    {
        $this->productionConfiguration();

        [, $output] = $this->runCheck();

        $this->assertStringContainsString('Still to check from a browser', $output);
        $this->assertStringContainsString('accounts/attachments', $output);
        $this->assertStringContainsString('real IP', $output);
    }
}
