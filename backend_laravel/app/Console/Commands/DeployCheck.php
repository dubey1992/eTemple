<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\AuditLog;
use App\Models\Role;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Throwable;

/**
 * Is this deployment actually safe to open to the village?
 *
 * Every check here answers a question that **no test on a developer's machine
 * can answer**, because the answer lives in the host's `.env`, the host's
 * `php.ini` and the host's database. That is the whole reason this exists: the
 * suite proves the code is right, and this proves the deployment is
 * (PHASE_12_PLAN §C2).
 *
 * It is aimed at cPanel, where there is no root, the PHP configuration comes
 * from a web page, and the CLI and the web server commonly read *different*
 * `php.ini` files — so it prints which one it is reading and says plainly that
 * some answers must also be checked from the browser.
 *
 * Run it after every deployment:
 *
 *     php artisan deploy:check
 *
 * A failure exits non-zero, so it can be a cron entry that mails the committee
 * when something drifts.
 */
class DeployCheck extends Command
{
    protected $signature = 'deploy:check
        {--strict : Treat warnings as failures}';

    protected $description = 'Verify this deployment is configured for production.';

    /** @var list<array{status: string, name: string, detail: string}> */
    private array $results = [];

    public function handle(): int
    {
        $this->line('');
        $this->info('Radha Krishna Thakurwadi — deployment check');
        $this->line('  environment: '.app()->environment());
        $this->line('  php:         '.PHP_VERSION.' ('.PHP_SAPI.')');
        $this->line('  php.ini:     '.(php_ini_loaded_file() ?: 'none loaded'));
        $this->line('');

        $this->checkApplication();
        $this->checkSessionAndOrigins();
        $this->checkMail();
        $this->checkPhp();
        $this->checkStorage();
        $this->checkDatabase();
        $this->checkQueue();
        $this->checkDevelopmentLeftovers();

        return $this->report();
    }

    // --- the checks ----------------------------------------------------------

    private function checkApplication(): void
    {
        $this->assert(
            'APP_ENV is production',
            app()->environment('production'),
            'It is "'.app()->environment().'". Seeders, error pages and cache behaviour all read this.',
        );

        // The one that matters most. A stack trace on a public URL names the
        // database, the paths and often the credentials.
        $this->assert(
            'APP_DEBUG is off',
            config('app.debug') === false,
            'Debug pages print stack traces, environment values and paths to anybody who triggers an error.',
        );

        $this->assert(
            'APP_KEY is set',
            is_string(config('app.key')) && config('app.key') !== '',
            'Sessions and encrypted values cannot be trusted without it. Run: php artisan key:generate',
        );

        $this->assert(
            'APP_URL is https',
            Str::startsWith((string) config('app.url'), 'https://'),
            'Password-reset links and printable receipts are built from APP_URL.',
        );

        $this->assert(
            'The timezone is Asia/Kolkata',
            config('app.timezone') === 'Asia/Kolkata',
            'Receipt dates, the financial year and the event calendar are all read in local time.',
        );
    }

    private function checkSessionAndOrigins(): void
    {
        $this->assert(
            'The session cookie is HTTPS-only',
            config('session.secure') === true,
            'SESSION_SECURE_COOKIE=false lets the session cookie travel over plain HTTP.',
        );

        $this->assert(
            'The session cookie is HttpOnly',
            config('session.http_only') === true,
            'Script must not be able to read the session cookie.',
        );

        $this->assert(
            'SameSite is lax or strict',
            in_array(config('session.same_site'), ['lax', 'strict'], true),
            '"none" is only needed when the API is on a different site, which this deployment avoids.',
        );

        $origins = (array) config('cors.allowed_origins');

        $this->assert(
            'CORS names exact origins',
            $origins !== [] && ! in_array('*', $origins, true),
            'A wildcard cannot be combined with credentials, and the browser will refuse every request.',
        );

        $this->assert(
            'Every allowed origin is https',
            $origins !== [] && collect($origins)->every(fn ($o) => Str::startsWith((string) $o, 'https://')),
            'Allowed: '.implode(', ', $origins),
        );

        $stateful = (array) config('sanctum.stateful');
        $frontend = parse_url((string) config('app.frontend_url'), PHP_URL_HOST);

        $this->assert(
            'The site host is stateful for Sanctum',
            $frontend !== null && collect($stateful)->contains(
                fn ($domain) => Str::contains((string) $domain, (string) $frontend),
            ),
            "SANCTUM_STATEFUL_DOMAINS does not mention {$frontend}, so every sign-in will be refused.",
        );
    }

    private function checkMail(): void
    {
        $mailer = config('mail.default');

        $this->assert(
            'Mail goes somewhere real',
            ! in_array($mailer, ['log', 'array'], true),
            "MAIL_MAILER is \"{$mailer}\": nothing is sent, and every invitation and password reset lands in storage/logs.",
        );

        $from = (string) config('mail.from.address');

        $this->assert(
            'The from address is on the temple\'s own domain',
            $from !== '' && ! Str::endsWith($from, ['.local', '.test', 'example.com']),
            "It is \"{$from}\". Mail from a domain with no SPF record is filed as spam.",
        );
    }

    private function checkPhp(): void
    {
        // gd: every upload is re-encoded through it, which is what strips the
        // location data out of a photograph. zip: the .xlsx export is written
        // by hand with ZipArchive.
        foreach (['gd' => 'photograph uploads are refused without it',
            'zip' => 'the Excel export cannot be written',
            'intl' => 'dates and numbers format wrongly',
            'mbstring' => 'Devanagari is truncated mid-character',
            'pdo_mysql' => 'nothing works at all',
            'fileinfo' => 'uploads cannot be judged by their bytes',
            'openssl' => 'nothing encrypted can be read'] as $extension => $consequence) {
            $this->assert(
                "The {$extension} extension is loaded",
                extension_loaded($extension),
                ucfirst($consequence).'. Add it on the cPanel "Select PHP Version" page.',
            );
        }

        $this->warnIf(
            'exif is loaded',
            extension_loaded('exif'),
            'Optional: without it a portrait photograph may be shown on its side.',
        );

        $this->assert(
            'memory_limit is at least 128M',
            $this->bytes((string) ini_get('memory_limit')) >= 128 * 1024 * 1024
                || (int) $this->bytes((string) ini_get('memory_limit')) === -1,
            'An export of ten thousand rows is built in memory. Current: '.ini_get('memory_limit'),
        );

        // PHP's own upload walls are a second, independent limit, and the
        // application's is meaningless if they are lower.
        $configured = (int) config('media.max_upload_kb', 8192) * 1024;
        foreach (['upload_max_filesize', 'post_max_size'] as $directive) {
            $this->assert(
                "{$directive} allows an ".round($configured / 1024 / 1024, 1).'MB upload',
                $this->bytes((string) ini_get($directive)) >= $configured,
                'It is '.ini_get($directive).', so a large photograph is silently truncated.',
            );
        }
    }

    private function checkStorage(): void
    {
        $this->assert(
            'storage/ is writable',
            is_writable(storage_path()),
            'Logs, sessions, the cache and uploads all live under it.',
        );

        if (config('media.disk') === 'public') {
            $this->assert(
                'storage:link has been run',
                is_link(public_path('storage')) || is_dir(public_path('storage')),
                'Without it every uploaded photograph 404s while the database insists it exists. Run: php artisan storage:link',
            );
        }

        // Bills carry a trader's name and telephone number. On the public disk
        // they would be a permanent, unauthenticated URL.
        $attachmentDisk = (string) config('accounting.attachments.disk');
        $root = (string) config("filesystems.disks.{$attachmentDisk}.root");

        $this->assert(
            'Ledger bills are on a private disk',
            $attachmentDisk !== 'public' && ! Str::contains($root, ['public', 'htdocs', 'www']),
            "ACCOUNTS_ATTACHMENT_DISK is \"{$attachmentDisk}\" ({$root}). Bills must never be web-reachable.",
        );

        $readable = true;
        try {
            Storage::disk($attachmentDisk)->exists('.probe');
        } catch (Throwable) {
            $readable = false;
        }

        $this->warnIf(
            'The private disk answers',
            $readable,
            "The disk \"{$attachmentDisk}\" could not be read.",
        );
    }

    private function checkDatabase(): void
    {
        try {
            DB::connection()->getPdo();
        } catch (Throwable $exception) {
            $this->assert('The database answers', false, $exception->getMessage());

            return;
        }

        $this->assert('The database answers', true, '');

        $pending = collect(app('migrator')->getMigrationFiles(database_path('migrations')))
            ->keys()
            ->diff(app('migrator')->getRepository()->getRan())
            ->count();

        $this->assert(
            'Every migration has run',
            $pending === 0,
            "{$pending} are pending. The site will fail on whatever they were going to create.",
        );

        $this->assert(
            'The roles are seeded',
            Schema::hasTable('roles') && Role::query()->count() > 0,
            'No account can be created without a role. Run: php artisan db:seed --class=RoleSeeder --force',
        );

        $this->assert(
            'There is at least one active Super Admin',
            User::query()
                ->where('status', User::STATUS_ACTIVE)
                ->whereHas('role', fn ($q) => $q->where('slug', Role::SUPER_ADMIN))
                ->exists(),
            'Nobody can administer this site, and there is no way in from outside.',
        );

        $this->assert(
            'The audit trail exists',
            Schema::hasTable((new AuditLog)->getTable()),
            'Phase 11 requires it, and every export of personal data is recorded in it.',
        );
    }

    private function checkQueue(): void
    {
        $connection = (string) config('queue.default');

        if ($connection === 'sync') {
            // Not a failure. On shared hosting with no worker, sending inline is
            // slower but honest: the announcement screen then reports a real
            // failure instead of recording a send that never left.
            $this->warnIf(
                'A queue worker is running',
                false,
                'QUEUE_CONNECTION=sync: announcements and acknowledgements are sent inline. Slower, but nothing can be silently lost.',
            );

            return;
        }

        if ($connection !== 'database' || ! Schema::hasTable('jobs')) {
            $this->warnIf('A queue worker is running', false, "Queue connection is \"{$connection}\"; this check only understands sync and database.");

            return;
        }

        // The evidence that no worker is running: something queued a while ago
        // and is still sitting there. This is the check that catches Phase 8's
        // worst failure — an announcement recorded as sent that never left.
        $stale = DB::table('jobs')
            ->where('created_at', '<', now()->subMinutes(10)->getTimestamp())
            ->count();

        $this->assert(
            'A queue worker is running',
            $stale === 0,
            "{$stale} jobs have been waiting more than ten minutes. Announcements are recorded as sent and are not being delivered. "
            .'Add the cron entry from docs/DEPLOYMENT_CPANEL.md.',
        );
    }

    /**
     * Anything that was useful in development and is dangerous in production.
     */
    private function checkDevelopmentLeftovers(): void
    {
        // `DEV_ADMIN_EMAIL=` with nothing after it is the *correct* production
        // state — the committed template ships it that way so the key is
        // visible and obviously empty — and `env()` returns "" for it rather
        // than null. Reading that as "configured" made a correctly deployed
        // site fail its own check, which is worse than not checking: it teaches
        // whoever runs it that a red line is normal.
        $configured = static fn (mixed $value): bool => is_string($value) && trim($value) !== '';

        $this->assert(
            'No development administrator is configured',
            ! $configured(env('DEV_ADMIN_EMAIL')) && ! $configured(env('DEV_ADMIN_PASSWORD')),
            'DEV_ADMIN_EMAIL/DEV_ADMIN_PASSWORD have values. Empty them in .env.',
        );

        // The demo accounts created for role testing, and the seeded example
        // donors. Either one in production is a real account or a false figure.
        $demoAccounts = User::query()->where('email', 'like', 'demo.%')->count();

        $this->assert(
            'No demo accounts remain',
            $demoAccounts === 0,
            "{$demoAccounts} accounts whose address begins \"demo.\" are still active.",
        );

        $this->assert(
            'Announcement channels have providers behind them',
            ! config('announcements.channels.sms.enabled') && ! config('announcements.channels.whatsapp.enabled'),
            'SMS or WhatsApp is enabled with no provider wired up: a send appears to succeed and delivers nothing.',
        );
    }

    // --- plumbing ------------------------------------------------------------

    private function assert(string $name, bool $passed, string $detail): void
    {
        $this->results[] = [
            'status' => $passed ? 'pass' : 'fail',
            'name' => $name,
            'detail' => $passed ? '' : $detail,
        ];
    }

    private function warnIf(string $name, bool $passed, string $detail): void
    {
        $this->results[] = [
            'status' => $passed ? 'pass' : 'warn',
            'name' => $name,
            'detail' => $passed ? '' : $detail,
        ];
    }

    private function bytes(string $value): int
    {
        $value = trim($value);
        if ($value === '' || $value === '-1') {
            return -1;
        }

        $unit = strtolower(substr($value, -1));
        $number = (int) $value;

        return match ($unit) {
            'g' => $number * 1024 * 1024 * 1024,
            'm' => $number * 1024 * 1024,
            'k' => $number * 1024,
            default => $number,
        };
    }

    private function report(): int
    {
        $failed = 0;
        $warned = 0;

        foreach ($this->results as $result) {
            [$mark, $method] = match ($result['status']) {
                'pass' => ['  ok  ', 'line'],
                'warn' => ['  --  ', 'comment'],
                default => ['  XX  ', 'error'],
            };

            $this->{$method}($mark.$result['name']);

            if ($result['detail'] !== '') {
                $this->line('        '.$result['detail']);
            }

            if ($result['status'] === 'fail') {
                $failed++;
            }
            if ($result['status'] === 'warn') {
                $warned++;
            }
        }

        // Two things this cannot see from inside PHP, and both matter. Printed
        // whatever the result: they are reminders, not findings, and a run that
        // failed on something else still needs them done.
        $this->line('');
        $this->comment('Still to check from a browser, because PHP cannot see them:');
        $this->line('  1. https://<domain>/storage/accounts/attachments/ is NOT served');
        $this->line('  2. A visitor\'s real IP reaches Laravel (submit the contact form from two networks)');

        $passed = count($this->results) - $failed - $warned;
        $this->line('');
        $this->line("{$passed} passed, {$warned} to look at, {$failed} failed.");

        if ($failed > 0) {
            $this->error('This deployment is not ready. Fix the failures above and run it again.');

            return self::FAILURE;
        }

        if ($warned > 0 && $this->option('strict')) {
            $this->error('Warnings are failures under --strict.');

            return self::FAILURE;
        }

        return self::SUCCESS;
    }
}
