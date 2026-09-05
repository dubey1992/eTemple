<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\AuditLog;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

/**
 * Apply a retention policy to the audit trail.
 *
 * The only way rows leave that table, and deliberately a separate act rather
 * than an edit: a log that grows forever fills a shared host's disk and takes
 * the site down with it, which is not more secure than a log with a stated
 * retention (PHASE_11_PLAN assumption S4).
 *
 * Three things make it hard to run by accident:
 *
 *  * the age is required — there is no default, because a default retention is
 *    a retention nobody chose;
 *  * it says what it will remove and asks, unless `--force`;
 *  * it writes an audit row recording that it ran, how far back it went and how
 *    many rows went with it. Pruning a trail without leaving a mark is exactly
 *    the hole a trail exists to close.
 *
 * Not scheduled. Nothing on this deployment runs on a timer the committee has
 * not set up themselves.
 */
class PruneAuditLog extends Command
{
    protected $signature = 'audit:prune
        {--older-than= : Remove entries older than this many days}
        {--force : Do not ask}';

    protected $description = 'Remove audit entries older than a chosen age.';

    public function handle(AuditLogger $audit): int
    {
        $days = (int) $this->option('older-than');

        if ($days < 1) {
            $this->error('Give an age in days, for example: audit:prune --older-than=730');
            $this->line('There is no default on purpose: a retention nobody chose is not a policy.');

            return self::FAILURE;
        }

        $cutoff = Carbon::now()->subDays($days)->startOfDay();
        $count = AuditLog::query()->where('created_at', '<', $cutoff)->count();

        if ($count === 0) {
            $this->info("Nothing is older than {$cutoff->toDateString()}.");

            return self::SUCCESS;
        }

        $this->warn(
            "This will permanently remove {$count} audit entries recorded before "
            .$cutoff->toDateString().'.'
        );

        if (! $this->option('force') && ! $this->confirm('Continue?', false)) {
            $this->line('Nothing was removed.');

            return self::SUCCESS;
        }

        $removed = AuditLog::prune($cutoff);

        // The mark it leaves behind. Written after the delete, so it survives.
        $audit->record(
            action: AuditAction::AUDIT_PRUNED,
            context: "{$removed} entries recorded before {$cutoff->toDateString()} were removed"
                ." (retention: {$days} days)",
        );

        $this->info("Removed {$removed} entries.");

        return self::SUCCESS;
    }
}
