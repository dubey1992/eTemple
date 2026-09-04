<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Media\StoreAlbumRequest;
use App\Http\Resources\Media\AdminAlbumResource;
use App\Models\Album;
use App\Models\User;
use App\Services\Media\MediaService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AlbumController extends Controller
{
    public function __construct(private readonly MediaService $media) {}

    /** GET /api/admin/albums */
    public function index(Request $request): JsonResponse
    {
        $albums = $this->media->adminAlbums()
            ->map(fn (Album $album) => (new AdminAlbumResource($album))->resolve($request))
            ->all();

        return ApiResponse::success($albums, ['count' => count($albums)]);
    }

    /** GET /api/admin/albums/{album} */
    public function show(Album $album): JsonResponse
    {
        $album->loadCount('media');

        return ApiResponse::success(new AdminAlbumResource($album));
    }

    /** POST /api/admin/albums */
    public function store(StoreAlbumRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $album = $this->media->createAlbum($request->validated(), $actor);

        return ApiResponse::success(new AdminAlbumResource($album), null, 201);
    }

    /** PUT /api/admin/albums/{album} */
    public function update(StoreAlbumRequest $request, Album $album): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $updated = $this->media->updateAlbum($album, $request->validated(), $actor);

        return ApiResponse::success(new AdminAlbumResource($updated));
    }

    /**
     * DELETE /api/admin/albums/{album}
     *
     * The album's photographs survive, unfiled: an album is an arrangement, and
     * losing an arrangement must never lose the content.
     */
    public function destroy(Album $album): JsonResponse
    {
        $this->media->deleteAlbum($album);

        return ApiResponse::noContent();
    }
}
