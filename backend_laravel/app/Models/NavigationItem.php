<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\NavigationItemFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * One entry in the configurable public navigation menu.
 *
 * @property int $id
 * @property string $label_hi
 * @property string|null $label_en
 * @property string $route
 * @property int $sort_order
 * @property bool $is_visible
 */
class NavigationItem extends Model
{
    /** @use HasFactory<NavigationItemFactory> */
    use HasFactory;

    /** @var list<string> */
    protected $fillable = ['label_hi', 'label_en', 'route', 'sort_order', 'is_visible'];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['is_visible' => 'boolean', 'sort_order' => 'integer'];
    }

    /**
     * @param  Builder<NavigationItem>  $query
     * @return Builder<NavigationItem>
     */
    public function scopeVisible(Builder $query): Builder
    {
        return $query->where('is_visible', true);
    }
}
