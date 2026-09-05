<?php

declare(strict_types=1);

namespace App\Http\Resources\Admin;

use App\Models\AuditLog;
use App\Support\AuditAction;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One entry of the trail, as the Super Admin reading it sees it.
 *
 * There is no public counterpart and there is not going to be.
 *
 * @mixin AuditLog
 */
class AuditLogResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'action' => $this->action,
            'action_label' => AuditAction::label($this->action),
            // The name is the copy stored on the row, so a deleted account's
            // actions still say who took them.
            'actor_name' => $this->actor_name,
            'actor_role' => $this->actor_role,
            'user_id' => $this->user_id,
            'entity_type' => $this->entity_type,
            'entity_id' => $this->entity_id,
            'entity_label' => $this->entity_label,
            'before_data' => $this->before_data,
            'after_data' => $this->after_data,
            'context' => $this->context,
            'ip_address' => $this->ip_address,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
