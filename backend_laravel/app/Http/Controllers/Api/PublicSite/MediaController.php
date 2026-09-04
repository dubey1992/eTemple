<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Media\PublicAlbumResource;
use App\Http\Resources\Media\PublicMediaResource;
use App\Models\Album;
use App\Models\Media;
use App\Services\Media\MediaService;
use App\Support\ApiResponse;
use App\Support\Language;
use App\Support\MediaType;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MediaController extends Controller
{
    public function __construct(private readonly MediaService $media) {}

    /**
     * GET /api/public/media?lang=&type=&album=&page=&per_page=
     *
     * Published items only, filtered in the query rather than the serializer, and
     * paginated: an unbounded gallery response is a denial-of-service against our
     * own API, and worse here than elsewhere because every row carries three URLs.
     */
    public function index(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));
        $type = $request->query('type');
        $album = $request->query('album');

        $page = $this->media->publicList([
            ...(is_string($type) && MediaType::exists($type) ? ['type' => $type] : []),
            ...(is_string($album) && $album !== '' ? ['album' => $album] : []),
            'per_page' => (int) $request->integer('per_page', MediaService::DEFAULT_PER_PAGE),
        ]);

        return ApiResponse::paginated(
            $page,
            array_map(
                fn (Media $item) => (new PublicMediaResource($item, $language))->resolve($request),
                $page->items(),
            ),
        );
    }

    /** GET /api/public/media/{media}?lang= — a draft is indistinguishable from absent. */
    public function show(Request $request, int $media): JsonResponse
    {
        $item = $this->media->publiclyVisibleById($media);

        if ($item === null) {
            throw new ModelNotFoundException;
        }

        $language = Language::fromRequest($request->query('lang'));

        return ApiResponse::success(new PublicMediaResource($item, $language));
    }

    /** GET /api/public/albums?lang= */
    public function albums(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));

        $albums = $this->media->publicAlbums()
            ->map(fn (Album $album) => (new PublicAlbumResource($album, $language))->resolve($request))
            ->all();

        return ApiResponse::success($albums, ['count' => count($albums)]);
    }
}
