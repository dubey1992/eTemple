<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\PageFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * A bilingual CMS page (spec Phase 1 entity).
 *
 * @property int $id
 * @property string $slug
 * @property string $title_hi
 * @property string|null $title_en
 * @property string $content_hi
 * @property string|null $content_en
 * @property string $status
 * @property Carbon|null $published_at
 */
class Page extends Model
{
    /** @use HasFactory<PageFactory> */
    use HasFactory;

    public const STATUS_DRAFT = 'draft';

    public const STATUS_PUBLISHED = 'published';

    /** Slugs the application itself relies on; see PageStructureSeeder. */
    public const SLUG_HOME = 'home';

    public const SLUG_ABOUT = 'about';

    /** @var list<string> */
    protected $fillable = [
        'slug',
        'title_hi',
        'title_en',
        'content_hi',
        'content_en',
        'meta_title_hi',
        'meta_title_en',
        'meta_description_hi',
        'meta_description_en',
        'status',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['published_at' => 'datetime'];
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /**
     * Public visibility is filtered in the query, never in the serializer, so a
     * draft cannot leak through a presentation mistake.
     *
     * @param  Builder<Page>  $query
     * @return Builder<Page>
     */
    public function scopePublished(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PUBLISHED);
    }

    public function isPublished(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }
}
