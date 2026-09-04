<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Media\ReorderMediaRequest;
use App\Http\Requests\Media\StorePhotoRequest;
use App\Http\Requests\Media\StoreVideoRequest;
use App\Http\Requests\Media\UpdateMediaRequest;
use App\Http\Resources\Media\AdminMediaResource;
use App\Models\Media;
use App\Models\User;
use App\Services\Media\MediaService;
use App\Support\ApiResponse;
use App\Support\MediaType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MediaController extends Controller
{
    public function __construct(private readonly MediaService $media) {}

    /**
     * GET /api/admin/media?status=&type=&album=
     *
     * The whole library including drafts. Reading needs `content.view` only, so
     * a Viewer can see what has been uploaded without being able to change it.
     */
    public function index(Request $request): JsonResponse
    {
        $status = $request->query('status');
        $type = $request->query('type');
        $album = $request->query('album');

        $items = $this->media->adminList([
            ...(is_string($status) && in_array($status, Media::statuses(), true)
                ? ['status' => $status] : []),
            ...(is_string($type) && MediaType::exists($type) ? ['type' => $type] : []),
            ...(is_string($album) && $album !== '' ? ['album' => (int) $album] : []),
        ])
            ->map(fn (Media $item) => (new AdminMediaResource($item))->resolve($request))
            ->all();

        return ApiResponse::success($items, ['count' => count($items)]);
    }

    /** GET /api/admin/media/{media} */
    public function show(Media $media): JsonResponse
    {
        return ApiResponse::success(new AdminMediaResource($media));
    }

    /**
     * POST /api/admin/media (multipart) — upload a photograph.
     *
     * The file is validated, stripped and re-encoded before any row exists, so
     * a refused upload leaves nothing behind at all.
     */
    public function store(StorePhotoRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $media = $this->media->createPhoto([
            ...$request->validated(),
            'file' => $request->file('file'),
        ], $actor);

        return ApiResponse::success(new AdminMediaResource($media), null, 201);
    }

    /** POST /api/admin/media/video (JSON) — link a video. Nothing is uploaded. */
    public function storeVideo(StoreVideoRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $media = $this->media->createVideo($request->validated(), $actor);

        return ApiResponse::success(new AdminMediaResource($media), null, 201);
    }

    /** PUT /api/admin/media/{media} */
    public function update(UpdateMediaRequest $request, Media $media): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $updated = $this->media->update($media, $request->validated(), $actor);

        return ApiResponse::success(new AdminMediaResource($updated));
    }

    /** POST /api/admin/media/reorder */
    public function reorder(ReorderMediaRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        /** @var list<int> $ids */
        $ids = array_map('intval', $request->validated()['ids']);
        $this->media->reorder($ids, $actor);

        return ApiResponse::message('Gallery order updated.');
    }

    /**
     * DELETE /api/admin/media/{media}
     *
     * Refused with 409 and a list of referring records when the site still
     * points at this file — see MediaService::referencesTo().
     */
    public function destroy(Media $media): JsonResponse
    {
        $this->media->delete($media);

        return ApiResponse::noContent();
    }

    /**
     * GET /api/admin/media/{media}/references
     *
     * What would block deletion, asked before trying. The editor can then say
     * so up front rather than offering a button that fails.
     */
    public function references(Media $media): JsonResponse
    {
        $references = $this->media->referencesTo($media);

        return ApiResponse::success([
            'references' => $references,
            'can_delete' => $references === [],
        ]);
    }
}
