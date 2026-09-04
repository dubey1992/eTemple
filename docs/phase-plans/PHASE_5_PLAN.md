# Phase 5 Plan — Gallery & Video Darshan

**Written before code**, per the working agreement. Assumptions are numbered
`M1…M12`.

---

## 1. Requirement review

From `IMPLEMENTATION_PLAN.md` (spec Phase 5):

| # | Requirement |
|---|---|
| 1 | `media` (+ optional `albums`): `media_type`, bilingual titles, `file_url`, `external_url`, `thumbnail_url`, `sort_order`, `status`, `uploaded_by` |
| 2 | Public gallery/videos endpoints + admin media CRUD |
| 3 | Server-side MIME/size validation, metadata stripping, optimized responsive variants |
| 4 | Lazy-loading, memory-conscious Flutter gallery |
| 5 | Deletion guard when media is referenced by a page or an event |

Requirement 3 is the one that shapes everything. This is the first phase that
accepts a **file** from the outside world, so it is also the first phase where a
validation mistake is an arbitrary-file-write, and where a careless success is a
privacy leak — a phone photograph of a villager's home carries GPS coordinates
in its EXIF block.

Requirement 5 is the reason `poster_url`, `photo_url` and `logo_url` have been
plain URL strings for two phases: nothing could be guarded until there was a
library to guard.

---

## 2. Assumptions and decisions

### M1 — Photos are uploaded; videos are linked, never uploaded

`media_type` is `photo` or `video`.

* A **photo** is an uploaded file. `file_url` is set, `external_url` is null.
* A **video** is a link to YouTube. `external_url` is set, `file_url` is null.

Video hosting is not something this project should attempt. A ten-minute aarti
recording is hundreds of megabytes; village shared hosting has neither the disk
nor the outbound bandwidth, and it would have to be transcoded for phones. The
committee already records to a phone and posts to YouTube. "Video darshan" is
therefore *embedding what already exists*, and the schema's own `external_url`
column says the specification anticipated exactly this.

The provider allow-list is `youtube.com`, `youtu.be`. An arbitrary `<iframe>`
src from an admin form is a stored-XSS vector; a validated video **id** is not.

### M2 — Uploads are validated by content, never by the name or the sent type

Three independent checks, in this order, all server-side:

1. **Size** — before anything else, from `UploadedFile::getSize()`, capped by
   config (default 8 MB). PHP's own `upload_max_filesize` is a second wall.
2. **Real MIME** — `finfo_file()` on the temporary file. The browser's
   `Content-Type` header and the file name are both attacker-controlled and
   are used for *nothing*.
3. **Decodability** — `getimagesize()` must agree it is an image of the
   detected type, and its dimensions must be within bounds. A polyglot file
   that sniffs as JPEG but does not decode is refused.

The stored name is generated (`ulid + extension-from-detected-type`); the
uploaded name is kept only as a display label, escaped. Nothing derived from
user input ever reaches a filesystem path.

Accepted types: `image/jpeg`, `image/png`, `image/webp`. Not GIF (animation
would survive re-encoding as a single frame and surprise the uploader), not
SVG — SVG is a script container, and there is no safe way to serve one from
the same origin as the admin session.

### M3 — Metadata is stripped by re-encoding, not by editing

Every accepted image is decoded with GD and re-encoded to a new file. This is
the strip: EXIF, XMP, IPTC, colour profiles and any appended payload are simply
not carried across, because nothing is copied — the pixels are read and written
afresh.

Editing metadata out in place is the alternative, and it is worse: it means
trusting a parser on hostile input and leaving anything the parser did not
recognise. Re-encoding is also what produces the responsive variants, so the
same pass satisfies both halves of requirement 3.

**GD is now a hard dependency.** It is enabled in `php.ini` locally and added to
the CI extension list, and `MediaService` refuses to start an upload without it
rather than silently storing an unstripped original.

### M4 — Three stored variants, chosen by the caller's need

| Variant | Longest edge | Used for |
|---|---|---|
| `thumb` | 480 px | gallery grid, admin list, pickers |
| `medium` | 1080 px | the lightbox on a phone, page embeds |
| `large` | 1920 px | the lightbox on a desktop |

The original is **not** kept. A 12 MP phone photograph is 4000 px wide; nothing
in this site ever displays it, so keeping it costs disk and bandwidth for a view
that never happens. `large` at 1920 px is beyond any screen this site targets.

An image smaller than a variant's bound is never upscaled — the variant simply
reuses the next size down, so a 600 px image has a `thumb` and a `medium`, and
`large` resolves to `medium`. JPEG quality 82, WebP 82; PNG stays PNG only when
the source had alpha, otherwise it becomes JPEG, because a photograph stored as
PNG is several times larger for no visible gain.

### M5 — Files are served from a disk, and the disk is configuration

Storage goes through Laravel's `public` disk (`storage/app/public`, exposed by
`php artisan storage:link`). The disk name is `media.disk` in config, so a
production deployment can point at S3 or a CDN without touching a line of code.

The API returns **absolute URLs** built from the disk, never a filesystem path,
and the database stores the disk-relative path. A deployment that changes its
domain does not need a data migration.

### M6 — Albums exist, and are optional for any given photo

`albums` is marked optional in the specification. It is built, because the
first Janmashtami produces sixty photographs and a flat list is unusable from
that day onward. It stays cheap: one table, one nullable foreign key, and one
public query parameter.

`media.album_id` is nullable and `nullOnDelete` — deleting an album never
deletes photographs. That asymmetry is deliberate: an album is an arrangement,
and losing an arrangement must never lose the content.

### M7 — Deletion is guarded, and the guard names the referrer

A media item is refused deletion (409, `MEDIA_IN_USE`) when it is referenced by:

* `temple_profiles.logo_url`
* `committee_members.photo_url`
* `events.poster_url`
* an album cover (`albums.cover_media_id`)
* any published or draft page whose body contains the file URL

The error lists **what** refers to it, in both languages, because "cannot
delete" without saying why is a dead end for a committee member who cannot read
the database. Unpublishing is always available and is what most people actually
want; the message says so.

The page check is a `LIKE` against the stored body. It is not elegant, but a
page body is free text with embedded URLs and there is no join to be had. At
village scale the pages table has single-digit rows.

### M8 — `media.manage` gates writes; `content.view` gates admin reads

The same split as Phases 3 and 4: a Viewer can see the library without being
able to change it. Uploads, edits, reordering and deletion all need
`media.manage`, which the Phase 2 catalogue has been granting to Content
Managers since before this module existed.

Every one of these is enforced by route middleware and re-asserted in the form
request. Hiding the upload button in Flutter is not an access control.

### M9 — Only published media reaches the public endpoints

`status` is `draft` or `published`, filtered **in the query**, exactly as pages
and events are. A photograph uploaded by mistake and left in draft is
indistinguishable from one that does not exist, including through a direct
`/api/public/media/{id}`.

There is no `cancelled` here — the events equivalent exists because devotees
planned around a cancelled festival. Nobody plans around a photograph.

### M10 — The public gallery is paginated, and the client asks for a page

Default 24 items, maximum 60. An unbounded gallery response is the same
denial-of-service the Phase 4 window cap prevents, and it is worse here because
each row carries three URLs.

Ordering is `sort_order` then newest first, so the committee's arrangement wins
and anything unarranged still appears in a sensible order.

### M11 — The Flutter gallery is lazy in three separate senses

Requirement 4 says "lazy-loading, memory-conscious", which is three things:

1. **The list is lazy.** `GridView.builder` — tiles are built when they scroll
   into view, not all at once.
2. **The bytes are lazy.** A grid tile requests `thumb`, never the full image.
   The lightbox requests `medium` or `large` by form factor.
3. **The decode is bounded.** Every `Image.network` passes `cacheWidth`, so the
   decoded bitmap in memory matches the size on screen rather than the size of
   the file. Without it a 1920 px image in a 300 px tile costs ~15 MB of RAM
   per tile, and a phone with twenty tiles on screen dies.

Plus the ordinary states: loading, empty, error, and a retry.

### M12 — The empty gallery renders the approved prototype's placeholder tiles

The prototype's gallery is five emoji tiles on a gold gradient, under the words
"photos … will appear here". That is *literally an empty state*, so it is built
as one: with no published photographs the section renders exactly those tiles
and exactly that copy.

The alternative — seeding five invented photographs so the demo looks full —
would put fabricated temple content in the database, which the working
agreement forbids. This way the customer sees the approved design pixel for
pixel, and the first real upload replaces it with real photographs.

---

## 3. Database design

### `albums` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `title_hi` | string(200) | required |
| `title_en` | string(200) | nullable — Hindi is the fallback |
| `description_hi` / `description_en` | text | nullable |
| `slug` | string(120) unique | shareable `/gallery?album=janmashtami-2026` |
| `cover_media_id` | fk → media, nullOnDelete | |
| `sort_order` | unsigned smallint, default 0 | |
| `status` | string(20), default `draft` | |
| `created_by` / `updated_by` | fk → users, nullOnDelete | |

### `media` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `album_id` | fk → albums, nullable, nullOnDelete | M6 |
| `media_type` | string(20) | `photo` \| `video` |
| `title_hi` | string(200) | required |
| `title_en` | string(200) | nullable |
| `caption_hi` / `caption_en` | text | nullable |
| `file_path` | string(500) | disk-relative, photos only |
| `thumb_path` / `medium_path` / `large_path` | string(500) | the variants, M4 |
| `external_url` | string(500) | videos only |
| `provider` / `provider_ref` | string(30) / string(100) | `youtube` + video id |
| `thumbnail_url` | string(500) | video poster, derived or overridden |
| `mime_type` | string(100) | the **detected** type, M2 |
| `byte_size` | unsigned integer | after re-encoding |
| `width` / `height` | unsigned smallint | of `large` |
| `original_name` | string(255) | display only, never a path |
| `checksum` | char(64) | sha-256 of the stored `large`, for duplicate detection |
| `sort_order` | unsigned smallint, default 0 | |
| `status` | string(20), default `draft` | M9 |
| `uploaded_by` / `updated_by` | fk → users, nullOnDelete | |

Indexes: `(status, media_type, sort_order)` for the public gallery,
`(album_id, sort_order)` for an album page, `checksum` for duplicates.

`albums.cover_media_id` and `media.album_id` are mutually referential, so the
foreign key on `albums.cover_media_id` is added in a **second migration** after
both tables exist, and dropped first on the way down.

### Existing tables

`temple_profiles.logo_url`, `committee_members.photo_url` and
`events.poster_url` keep their shape. They now hold URLs the media library
produced, chosen through a picker rather than typed. Keeping them as URLs
rather than converting to foreign keys means Phases 3 and 4 are not disturbed,
and an externally hosted image stays possible; the deletion guard is what makes
the reference safe (M7).

---

## 4. API surface

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/media?lang=&type=&album=&page=&per_page=` | public |
| GET | `/api/public/media/{id}?lang=` | public |
| GET | `/api/public/albums?lang=` | public |
| GET | `/api/admin/media?status=&type=&album=` | `content.view` |
| GET | `/api/admin/media/{id}` | `content.view` |
| POST | `/api/admin/media` (multipart, photo) | `media.manage` |
| POST | `/api/admin/media/video` (JSON, link) | `media.manage` |
| PUT | `/api/admin/media/{id}` | `media.manage` |
| POST | `/api/admin/media/reorder` | `media.manage` |
| DELETE | `/api/admin/media/{id}` | `media.manage` |
| GET | `/api/admin/albums` | `content.view` |
| POST/PUT/DELETE | `/api/admin/albums[/{id}]` | `media.manage` |

Upload is rate-limited separately (`throttle:media-upload`, 30/minute): it is
the most expensive endpoint in the application and the one that consumes disk.

---

## 5. Flutter surface

| Path | Screen |
|---|---|
| `/gallery` | Public gallery — photos and videos, prototype mosaic, lightbox |
| `/admin/media` | `AdminMediaScreen` — library, filters, upload, reorder |
| `/admin/media/new`, `/admin/media/:id` | `AdminMediaEditorScreen` |
| `/admin/albums` | `AdminAlbumsScreen` |

Plus, and this is the integration that matters:

* A reusable **`MediaPickerField`**, used by the event editor's poster, the
  committee member's photograph and the temple profile's logo. Those three
  fields stop being "paste a URL here".
* A **gallery section on the home page**, in the prototype's position between
  the events and the committee, showing the six most recent photographs.
* A `गैलरी / Gallery` navigation item, seeded to match the prototype.
* Admin breadcrumbs for every new route — asserted by the existing test that
  requires *every* admin route to produce a trail.

---

## 6. Implementation order

1. Migrations + `Media`, `Album` models + factories.
2. `ImageProcessor` (validate, strip, resize) — the security core, tested first
   against real bytes, including hostile ones.
3. `MediaService` — create/update/delete, the deletion guard, reordering.
4. Form requests, resources, controllers, routes, rate limiter.
5. Backend tests: validation, stripping, variants, authorization, the guard.
6. Flutter domain + repository + providers.
7. Public gallery, mosaic, lightbox; home section.
8. Admin library, editor, album screens, breadcrumbs.
9. `MediaPickerField` wired into events, committee and profile.
10. l10n, seeder, OpenAPI, CI extension list, docs.
11. Gate.

---

## 7. Delivery gate

`flutter pub get` · `flutter analyze` · `dart format --set-exit-if-changed` ·
`flutter test` · `flutter build web --release` · `pint --test` ·
`php artisan test` · migrate → rollback → migrate → seed on MariaDB ·
all Phase 0–4 tests unchanged · a real photograph uploaded through the running
API and confirmed stripped of EXIF.

---

## 8. Explicitly out of scope

* Video **file** uploads and transcoding (M1).
* Live streaming.
* Client-side image cropping/rotation.
* A rich-text editor that inserts media into a page body — the guard covers
  URLs already in a body, but inserting them is still copy-and-paste.
* Bulk multi-file upload in one request: one file per request keeps the
  validation path single and auditable. The UI may queue several.
* Face detection, tagging, or any automatic classification of villagers.
