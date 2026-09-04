# Phase 5 Completion Report — Gallery & Video Darshan

**Date:** 2026-09-09
**Status: COMPLETE.** Every specified requirement is delivered, and the three
URL fields Phases 3 and 4 left waiting on this phase are now filled from the
library rather than typed.

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 (**gd**, exif) ·
Composer 2.10.3 · Laravel 12.69.1 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 5 requirement | Status | Where |
|---|---|---|---|
| 1 | `media` + `albums`: type, bilingual titles, `file_url`, `external_url`, `thumbnail_url`, `sort_order`, `status`, `uploaded_by` | ✅ | `media` and `albums` tables — §2 |
| 2 | Public gallery/videos endpoints + admin media CRUD | ✅ | 15 endpoints — §3 |
| 3 | Server-side MIME/size validation, metadata stripping, optimized responsive variants | ✅ | `ImageProcessor` — §4 |
| 4 | Lazy-loading, memory-conscious Flutter gallery | ✅ | §6 |
| 5 | Deletion guard when media is referenced by a page or an event | ✅ | §5 |

---

## 2. Database changes

| Migration | Table |
|---|---|
| `2026_09_09_000000_create_albums_table` | `albums` — bilingual title/description, unique `slug`, `cover_media_id`, `sort_order`, `status`, audit columns |
| `2026_09_09_000001_create_media_table` | `media` — `album_id`, `media_type`, bilingual title/caption, the four stored paths, the video columns, `mime_type`/`byte_size`/`width`/`height`/`original_name`/`checksum`, `sort_order`, `status`, `uploaded_by`/`updated_by`; indexed on `(status, media_type, sort_order)`, `(album_id, sort_order)` and `checksum` |
| `2026_09_09_000002_add_album_cover_foreign_key` | Closes the circle: an album's cover is one of its photographs, so the key can only be added once both tables exist — and must be dropped first on the way down, or `rollback` cannot drop `media` |

Verified on **MariaDB 12.3.3**: `migrate:fresh` (18) → `rollback` (16) →
`migrate` (16) → `db:seed`.

`media.album_id` is `nullOnDelete`, so deleting an album never deletes
photographs. That asymmetry is the point: an album is an arrangement, and losing
an arrangement must not lose the content.

---

## 3. API endpoints

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/media?lang=&type=&album=&page=&per_page=` | public |
| GET | `/api/public/media/{id}?lang=` | public |
| GET | `/api/public/albums?lang=` | public |
| GET | `/api/admin/media?status=&type=&album=` | `content.view` |
| GET | `/api/admin/media/{id}` | `content.view` |
| GET | `/api/admin/media/{id}/references` | `content.view` |
| POST | `/api/admin/media` (multipart) | `media.manage` + `throttle:media-upload` |
| POST | `/api/admin/media/video` (JSON) | `media.manage` |
| POST | `/api/admin/media/reorder` | `media.manage` |
| PUT/DELETE | `/api/admin/media/{id}` | `media.manage` |
| GET | `/api/admin/albums`, `/api/admin/albums/{id}` | `content.view` |
| POST/PUT/DELETE | `/api/admin/albums[/{id}]` | `media.manage` |

Documented in `docs/api/openapi.yaml` (now **v0.6.0** — 39 paths, 31 schemas).

`media.manage` was defined in Phase 2's catalogue and labelled "available in
phase 5"; this phase attached endpoints to a key the committee could already
grant. Reading is gated on `content.view` so a Viewer can see the library
without being able to change it — the same split as Phases 3 and 4.

Uploads carry their own rate limit. It is the only endpoint in the application
that consumes disk, and it should not share an allowance with reading a page.

---

## 4. The upload path — the part that matters most

This is the first place the application takes a **file** from outside, which
makes it the first place where a validation mistake is an arbitrary file write
and a careless success is a privacy leak: a phone photograph of a villager's
home carries GPS coordinates in its EXIF block.

**Nothing the client says is trusted.** Not the file name, not the extension,
not the `Content-Type` header — all three are attacker-controlled. Three checks
run server-side, in order:

1. **Size**, from the file itself, before the bytes are read into memory.
2. **The MIME the server detects** from the bytes (`finfo`), against an
   allow-list of JPEG, PNG and WebP. No GIF — animation would survive
   re-encoding as a single frame and surprise the uploader. No SVG — it is a
   script container, and there is no safe way to serve one from the same origin
   as the admin session.
3. **Decodability**: the bytes must actually parse as an image of the detected
   type, with dimensions in range. A polyglot that sniffs as JPEG but does not
   decode is refused here.

**The strip is a re-encode, not an edit.** Every accepted image is decoded and
written afresh through GD, so EXIF, XMP, IPTC, colour profiles and anything
appended to the file are simply not carried across — nothing is copied. Editing
metadata out in place is the alternative and it is worse: it means trusting a
parser on hostile input and keeping whatever the parser did not recognise.

The same pass produces the responsive variants, so one decode satisfies both
halves of the specification's third requirement:

| Variant | Longest edge | Used for |
|---|---|---|
| `thumb` | 480 px | gallery grid, admin list, pickers |
| `medium` | 1080 px | the lightbox on a phone |
| `large` | 1920 px | the lightbox on a desktop |

Nothing is upscaled: an image smaller than a bound has fewer stored files, and
the smaller URLs resolve to the one that exists. **The original is not kept** —
a 12 MP phone photograph is 4000 px wide and nothing on this site ever displays
it, so keeping it costs disk and backup for a view that never happens.

Stored names are generated (`ULID` + a suffix + the extension for the
**detected** type). No value derived from user input reaches a filesystem path;
the uploaded name is kept only as a display label. A refused upload leaves
neither a row nor a file, and a half-written variant set is cleaned up before
the error is raised.

**GD is now a hard dependency**, added to `php.ini` locally and to the CI
extension list. `ImageProcessor` refuses to start an upload without it rather
than falling through to storing an unstripped original — which is exactly the
kind of silent degradation this phase exists to prevent.

---

## 5. The deletion guard

Deleting a media item is refused (409, `MEDIA_IN_USE`) while any of these still
points at it:

* the temple logo (`temple_profiles.logo_url`),
* a committee member's photograph (`committee_members.photo_url`),
* an event poster (`events.poster_url`),
* an album cover (`albums.cover_media_id`),
* a page whose body embeds the URL.

The refusal **names the referring records**. "Cannot delete" with no reason is a
dead end for a committee member who cannot read the database, and the thing they
usually actually want — unpublishing — is offered in the same message.

The Flutter editor asks `/references` *before* honouring the delete button, so a
blocked deletion is explained rather than attempted and refused; the server
checks again on the way in, so something added between the question and the
answer is still caught.

The page check is a `LIKE` against the stored body. Inelegant, and correct: a
page body is free text with embedded URLs and there is no join to be had. At
village scale the pages table has single-digit rows.

---

## 6. Flutter surface

| Path | Screen |
|---|---|
| `/gallery`, `/gallery?album=` | Public gallery — photographs and video darshan, with a lightbox |
| `/admin/media` | The library: filters, reordering, upload |
| `/admin/media/new`, `/admin/media/:id` | `AdminMediaEditorScreen` |
| `/admin/albums`, `/admin/albums/new`, `/admin/albums/:id` | Albums |

**"Lazy-loading, memory-conscious" is three separate things**, and all three are
implemented:

1. **The list is lazy.** The gallery is built from slivers with a
   `SliverGrid.builder`, not a `shrinkWrap` grid inside a scroll view — which
   would build every tile immediately and defeat the point.
2. **The bytes are lazy.** A grid tile requests the 480 px variant and never the
   full photograph; the lightbox requests 1080 px on a phone and 1920 px on a
   desktop.
3. **The decode is bounded.** Every image passes `cacheWidth`, so the decoded
   bitmap matches the size on screen rather than the size of the file. Without
   it a 1920 px image in a 300 px tile costs ~15 MB of RAM, and twenty tiles is
   the end of the page on a village phone.

Plus the ordinary states: loading, empty, error and a retry, on both the public
gallery and the library.

### The integration this phase existed to make possible

`logo_url`, `photo_url` and `poster_url` have been plain text boxes since Phases
3 and 4 because there was no library to choose from. They now carry a
**`MediaPickerField`**: a committee member picks a photograph and the field is
filled with exactly the URL the deletion guard compares against, so the picker
and the guard agree by construction. The text box stays editable — removing it
would make an externally hosted image impossible and would hide values entered
before this phase existed.

### Matching the approved design

The gallery block rebuilds the prototype's CSS grid exactly — `2fr 1fr 1fr`,
180 px rows, the first child spanning two rows — rather than approximating it
with a uniform grid, because that uneven rhythm is what makes the block read as
a gallery instead of a contact sheet. It narrows the way the prototype's own
media queries do.

**The empty state is the prototype, unchanged.** With nothing published the
block renders the design's five emoji tiles on their gold gradient, under the
caption that says the photographs "will appear here" — which is what that design
already *is*. Seeding five invented photographs so a demo looks full would have
put fabricated temple content in the database.

The home page gains the gallery in the prototype's own position, between the
events and the committee, and `गैलरी / Gallery` joins the seeded navigation.

---

## 7. Tests and command results

```
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  156 files, 0 changed
$ flutter test                                       394/394 passed
$ flutter build web --release                        Built build\web
$ ./vendor/bin/pint --test                           passed
$ php artisan test                                   362 passed (1387 assertions)
$ migrate → rollback → migrate → db:seed (MariaDB)   reversible
```

**Backend, 362 tests** (279 from Phases 0–4 + 83 new):

* `ImageProcessingTest` (18) — against **real bytes**, not `UploadedFile::fake()`,
  because a fake file has no image structure and could not prove that anything
  was stripped, resized or refused. It builds a JPEG with a genuine EXIF APP1
  segment (the same block that carries GPS) and asserts the marker is absent
  from every stored variant; also appended payloads, the three variants and
  their exact widths, no upscaling, aspect ratio, alpha handling, path safety,
  and six refusals.
* `MediaPublicTest` (19) — drafts invisible, unpublished albums empty, ordering,
  pagination and its cap, the type filter, the language fallback, and that the
  public payload carries no administrative detail.
* `MediaManagementTest` (32) — upload, five YouTube URL shapes accepted and five
  refused, editing, the file **not** replaceable, reordering, all five deletion
  guards, and album slug generation.
* `MediaAuthorizationTest` (14) — every endpoint × refused roles, guest,
  a deactivated account, immediate effect of a grant.

**All 279 Phase 0–4 tests pass unchanged.**

**Flutter, 394 tests** (329 + 65 new): the domain models and their defensive
parsing, `GalleryQuery` value equality, the drafts, the gallery screen's tabs
and paging and error retry, the prototype mosaic at all three breakpoints, the
placeholder empty state, the lightbox, the library and its filters and
reordering, the editor including the upload and the blocked-deletion panel, the
albums screens, the picker, and the home-page block; plus two breadcrumb tests.

### Live verification against the running API

The test suite is not the whole gate for this phase: a photograph carrying real
EXIF was uploaded **through HTTP** to the running server, the stored variants
were fetched back over HTTP, and their bytes were checked. Thirty-two checks,
all passing — the strip, the variants, the refusals, and the deletion guard
refusing and then allowing once the referring event was removed, with the files
confirmed gone from disk afterwards.

---

## 8. Defects found and fixed during the phase

| # | Defect | Fix |
|---|---|---|
| 1 | **Every photograph failed to load in the browser.** Flutter Web fetches image *bytes*, which needs `Access-Control-Allow-Origin` — and uploads are static files served by the web server, which never runs Laravel's CORS middleware. The gallery was empty on a correctly-built site | `MediaImage` uses `WebHtmlElementStrategy.fallback`: the byte path (and its bounded decode) when the header is present, a plain `<img>` element when it is not. The header is still the right answer and the deployment checklist now asks for it — this stops a missing one from emptying the gallery |
| 2 | `finfo_file()` warns on some content it recognises, and under Laravel's error handler that warning became an `ErrorException` **instead of our own refusal** — a 500 where a 422 belonged | The file is read once and inspected in memory with `finfo_buffer`, which is also one fewer disk read |
| 3 | Modifying provider state in `initState` to apply a shared `?album=` link threw: `initState` runs inside the build phase | Applied in a post-frame callback, and only as the *initial* filter — once the visitor taps a chip the choice is theirs |
| 4 | `MediaQuery` as a domain class name collided with Flutter's own widget | Renamed `GalleryQuery` before it spread |
| 5 | The gallery's chips threw "No Material widget found" when the screen was pumped outside a shell | The screen is always inside the public shell's `Scaffold` in the application; the test harness now mirrors that, as the events tests already did |

---

## 9. Known issues and technical debt

1. **Videos are linked, not embedded.** Playing one inline would put a
   third-party iframe on the temple's own origin; the visitor is sent to the
   provider in a new tab instead. An embed behind an explicit consent click is
   the better long-term answer and is not built.
2. **No video uploads or transcoding**, by design (PHASE_5_PLAN M1).
3. **`page.content` still embeds URLs by copy-and-paste.** The deletion guard
   covers a URL already in a body, but there is no editor affordance to insert
   one.
4. **Reordering is one item at a time** (up/down arrows), and is disabled while
   a filter is on. A drag-and-drop reorder is the obvious improvement; the
   navigation menu and the committee want the same thing and are recorded below.
5. **No duplicate detection in the UI.** `checksum` is stored and indexed for
   it; nothing reads it yet.
6. **Album covers are chosen from a dropdown of titles**, not thumbnails.
7. Carried: two-factor authentication (Phase 2 §7); the build-time name in
   `web/index.html` and `manifest.json` (Phase 3 §9.1); reorderable editors for
   the navigation menu and the committee; consent changes not audit-logged
   (Phase 11); no per-occurrence event overrides (Phase 4 §10.1); no calendar
   export; no cross-stack end-to-end test (Phase 12); pre-render tool not wired
   into CI.

---

## 10. Deployment notes added this phase

`docs/DEPLOYMENT_CHECKLIST.md` gained four items that will break the gallery if
missed, all of them silent failures:

* **`gd` must be installed for the web user**, not merely on the CLI — the two
  often load different `php.ini` files, and without it every upload is refused.
* **`php artisan storage:link`**, once per environment.
* **`Access-Control-Allow-Origin` on `/storage/`** when the site and the API are
  on different origins, which they are by default here.
* The uploads directory must be **backed up and excluded from the deployment
  artefact**, so a release never removes the committee's photographs.

---

## 11. Next phase

**Phase 6 — Donations & Receipts.** Planned but **not started**. It is the
prototype's `दान` section, and the first phase that handles money.
