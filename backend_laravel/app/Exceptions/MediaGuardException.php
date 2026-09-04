<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals from the media library.
 *
 * Upload refusals surface as 422 against the `file` field, so the uploader sees
 * which file was rejected and why rather than a generic failure. The deletion
 * guard is a 409 with its own code, because "this is in use" is a conflict with
 * the state of the site rather than a malformed request — and the client shows
 * it differently.
 */
final class MediaGuardException extends DomainException
{
    public static function tooLarge(int $maxKb): self
    {
        return self::upload(sprintf(
            'The file is larger than the %d MB upload limit.',
            (int) round($maxKb / 1024),
        ));
    }

    public static function unsupportedType(string $detected): self
    {
        return self::upload(sprintf(
            'Files of type %s cannot be uploaded. Use a JPEG, PNG or WebP image.',
            $detected,
        ));
    }

    public static function notAnImage(): self
    {
        return self::upload('The file could not be read as an image.');
    }

    public static function dimensionsOutOfRange(): self
    {
        return self::upload('The image dimensions are outside the accepted range.');
    }

    public static function uploadFailed(): self
    {
        return self::upload('The upload did not complete. Please try again.');
    }

    public static function imageSupportMissing(): self
    {
        // Not the uploader's fault and not something they can fix, so this is a
        // 500 rather than a 422: the deployment is misconfigured.
        return new self(
            ApiErrorCode::SERVER_ERROR,
            'Image processing is unavailable on this server (the GD extension is not installed).',
            500,
        );
    }

    public static function unsupportedVideoHost(): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            'Only YouTube links can be embedded.',
            422,
            ['external_url' => ['Only YouTube links can be embedded.']],
        );
    }

    /**
     * Deletion refused because something on the site still points at this file.
     *
     * The referring records are named: "cannot delete" without saying why is a
     * dead end for a committee member who cannot read the database
     * (PHASE_5_PLAN assumption M7).
     *
     * @param  list<array{type: string, label: string}>  $references
     */
    public static function inUse(array $references): self
    {
        return new self(
            ApiErrorCode::MEDIA_IN_USE,
            'This file is still used elsewhere on the site. Unpublish it instead, '
                .'or remove it from the items listed before deleting.',
            409,
            ['references' => $references],
        );
    }

    private static function upload(string $message): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            $message,
            422,
            ['file' => [$message]],
        );
    }
}
