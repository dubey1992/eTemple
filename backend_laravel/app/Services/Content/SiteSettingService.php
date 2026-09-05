<?php

declare(strict_types=1);

namespace App\Services\Content;

use App\Models\NavigationItem;
use App\Models\SiteSetting;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Business rules for the site-settings singleton and the navigation menu.
 */
class SiteSettingService
{
    public function __construct(private readonly AuditLogger $audit) {}

    /**
     * The one settings row, created empty on first access.
     *
     * Empty is the correct initial state: the specification forbids shipping
     * invented temple content, so an unconfigured site shows empty states until
     * the committee fills it in.
     */
    public function current(): SiteSetting
    {
        return SiteSetting::query()->oldest('id')->firstOr(
            callback: static fn () => SiteSetting::query()->create([]),
        );
    }

    /** @return Collection<int, NavigationItem> */
    public function visibleNavigation(): Collection
    {
        return NavigationItem::query()
            ->visible()
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();
    }

    /** @return Collection<int, NavigationItem> */
    public function allNavigation(): Collection
    {
        return NavigationItem::query()
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();
    }

    /**
     * Update the settings and, when supplied, replace the navigation menu.
     *
     * Navigation is replaced wholesale inside a transaction: the editor sends
     * the menu it wants, and a partial failure must not leave the public site
     * with half a menu.
     *
     * @param  array<string, mixed>  $attributes
     * @param  list<array<string, mixed>>|null  $navigation
     */
    public function update(array $attributes, ?array $navigation, User $editor): SiteSetting
    {
        return DB::transaction(function () use ($attributes, $navigation, $editor) {
            $settings = $this->current();
            $before = $settings->only(array_keys($attributes));
            $settings->fill($attributes);
            $settings->updated_by = $editor->id;
            $settings->save();

            if ($navigation !== null) {
                NavigationItem::query()->delete();

                foreach (array_values($navigation) as $index => $item) {
                    NavigationItem::query()->create([
                        'label_hi' => $item['label_hi'],
                        'label_en' => $item['label_en'] ?? null,
                        'route' => $item['route'],
                        'sort_order' => $item['sort_order'] ?? $index,
                        'is_visible' => $item['is_visible'] ?? true,
                    ]);
                }
            }

            // Settings are the site's own configuration; a change here is
            // visible to every visitor, so it leaves a trace.
            $this->audit->recordChange(
                action: AuditAction::SITE_SETTINGS_UPDATED,
                entity: $settings,
                before: $before,
                after: $settings->only(array_keys($before)),
                // The menu is replaced wholesale when it is sent at all, so
                // "how many items" is the honest summary; the items themselves
                // are the navigation table's own business.
                context: $navigation === null
                    ? null
                    : 'मेन्यू बदला / Menu replaced: '.count($navigation).' items',
            );

            return $settings->refresh();
        });
    }
}
