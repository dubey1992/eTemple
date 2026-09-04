<?php

declare(strict_types=1);

namespace App\Http\Resources\Content;

use App\Models\NavigationItem;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin NavigationItem
 */
class NavigationItemResource extends JsonResource
{
    public function __construct(NavigationItem $item, private readonly ?Language $language = null)
    {
        parent::__construct($item);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        // Public callers get one resolved label; the editor gets both languages.
        if ($this->language === null) {
            return [
                'id' => $this->id,
                'label_hi' => $this->label_hi,
                'label_en' => $this->label_en,
                'route' => $this->route,
                'sort_order' => $this->sort_order,
                'is_visible' => $this->is_visible,
            ];
        }

        return [
            'id' => $this->id,
            'label' => LocalizedText::resolve($this->label_hi, $this->label_en, $this->language)->toArray(),
            'route' => $this->route,
            'sort_order' => $this->sort_order,
        ];
    }
}
