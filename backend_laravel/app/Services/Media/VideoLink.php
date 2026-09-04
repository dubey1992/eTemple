<?php

declare(strict_types=1);

namespace App\Services\Media;

use App\Exceptions\MediaGuardException;

/**
 * A validated video link — "video darshan" without hosting the video.
 *
 * A ten-minute aarti recording is hundreds of megabytes; village shared hosting
 * has neither the disk nor the outbound bandwidth, and it would have to be
 * transcoded for phones. The committee already records to a phone and posts to
 * YouTube, so this phase embeds what exists (PHASE_5_PLAN assumption M1).
 *
 * What is stored is the **video id**, extracted here, not whatever URL was
 * typed. An arbitrary iframe src coming out of an admin form is a stored-XSS
 * vector; `dQw4w9WgXcQ` is not.
 */
final class VideoLink
{
    public const YOUTUBE = 'youtube';

    private function __construct(
        public readonly string $provider,
        public readonly string $reference,
        public readonly string $url,
        public readonly string $thumbnailUrl,
    ) {}

    /** @throws MediaGuardException */
    public static function parse(string $input): self
    {
        $url = trim($input);
        $parts = parse_url($url);

        if ($parts === false || ! isset($parts['host'], $parts['scheme'])) {
            throw MediaGuardException::unsupportedVideoHost();
        }

        if (! in_array(strtolower($parts['scheme']), ['http', 'https'], true)) {
            throw MediaGuardException::unsupportedVideoHost();
        }

        $host = strtolower($parts['host']);
        /** @var list<string> $allowed */
        $allowed = (array) config('media.video_hosts', []);
        if (! in_array($host, $allowed, true)) {
            throw MediaGuardException::unsupportedVideoHost();
        }

        $id = self::youtubeId($host, $parts);
        if ($id === null) {
            throw MediaGuardException::unsupportedVideoHost();
        }

        return new self(
            provider: self::YOUTUBE,
            reference: $id,
            // Rebuilt from the id rather than kept as typed, so nothing the
            // admin pasted — tracking parameters included — is stored or later
            // handed to a browser.
            url: 'https://www.youtube.com/watch?v='.$id,
            thumbnailUrl: 'https://i.ytimg.com/vi/'.$id.'/hqdefault.jpg',
        );
    }

    /** The player URL the client embeds. */
    public function embedUrl(): string
    {
        return 'https://www.youtube-nocookie.com/embed/'.$this->reference;
    }

    /** @param array<string, mixed> $parts */
    private static function youtubeId(string $host, array $parts): ?string
    {
        $path = isset($parts['path']) && is_string($parts['path']) ? trim($parts['path'], '/') : '';

        // youtu.be/<id>
        if ($host === 'youtu.be') {
            return self::validId($path);
        }

        // youtube.com/watch?v=<id>
        if ($path === 'watch') {
            $query = [];
            if (isset($parts['query']) && is_string($parts['query'])) {
                parse_str($parts['query'], $query);
            }
            $value = $query['v'] ?? null;

            return is_string($value) ? self::validId($value) : null;
        }

        // youtube.com/embed/<id>, /live/<id>, /shorts/<id>
        foreach (['embed/', 'live/', 'shorts/'] as $prefix) {
            if (str_starts_with($path, $prefix)) {
                return self::validId(substr($path, strlen($prefix)));
            }
        }

        return null;
    }

    /**
     * YouTube ids are exactly 11 characters of an unreserved alphabet. Anything
     * else is refused rather than sanitised: a value that has to be cleaned
     * before use is a value we do not understand.
     */
    private static function validId(string $candidate): ?string
    {
        $id = explode('/', $candidate)[0];
        $id = explode('?', $id)[0];

        return preg_match('/^[A-Za-z0-9_-]{11}$/', $id) === 1 ? $id : null;
    }
}
