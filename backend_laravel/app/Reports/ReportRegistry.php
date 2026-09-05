<?php

declare(strict_types=1);

namespace App\Reports;

use App\Models\User;
use App\Support\Permission;
use Illuminate\Contracts\Container\Container;

/**
 * The catalogue of standard reports.
 *
 * Six, chosen because each answers a question a village temple committee
 * actually asks; see PHASE_10_PLAN §2 for what is deliberately absent and why.
 *
 * `availableTo()` filters by permission, so the console is never offered a
 * report it cannot run — the same courtesy the admin menu extends, and, as
 * there, never the access control: every endpoint checks again.
 */
class ReportRegistry
{
    /** @var list<class-string<Report>> */
    private const REPORTS = [
        Reports\DonationRegisterReport::class,
        Reports\DonationSummaryReport::class,
        Reports\IncomeExpenditureReport::class,
        Reports\LedgerReport::class,
        Reports\EventsReport::class,
        Reports\EnquiriesReport::class,
    ];

    public function __construct(private readonly Container $container) {}

    /** @return list<Report> */
    public function all(): array
    {
        return array_map(
            fn (string $class) => $this->container->make($class),
            self::REPORTS,
        );
    }

    public function find(string $key): ?Report
    {
        foreach ($this->all() as $report) {
            if ($report->key() === $key) {
                return $report;
            }
        }

        return null;
    }

    /**
     * The reports this account may run.
     *
     * `reports.view` is the ticket into the module; each report's own key is
     * what decides whether it appears. A Content Manager holds neither
     * `reports.view` nor any of the money keys and sees nothing here.
     *
     * @return list<Report>
     */
    public function availableTo(User $user): array
    {
        if (! $user->can(Permission::REPORTS_VIEW)) {
            return [];
        }

        return array_values(array_filter(
            $this->all(),
            static fn (Report $report) => $user->can($report->permission()),
        ));
    }

    public function mayRun(User $user, Report $report): bool
    {
        return $user->can(Permission::REPORTS_VIEW) && $user->can($report->permission());
    }

    /**
     * Whether this account may see the report's personal columns.
     *
     * Separate from running it: a treasurer may read the enquiry report's
     * counts without being handed a list of villagers' telephone numbers unless
     * they hold the key for it and asked (assumption N2).
     */
    public function maySeePersonal(User $user, Report $report): bool
    {
        $permission = $report->personalPermission();

        return $permission !== null && $user->can($permission);
    }
}
