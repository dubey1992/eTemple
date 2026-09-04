# Phase 1 Plan — Public Website & Bilingual CMS

> **Objective (spec §Phase 1):** Convert the current prototype into a dynamic Flutter Web
> public website whose content can be maintained from the backend.

---

## A. Requirement review

### Features required by the specification

| # | Requirement | Where it lands |
|---|---|---|
| 1 | Hindi default; English switch always visible on the public site | Already built in Phase 0; extended to CMS content |
| 2 | Home page hero section with temple name and devotional tagline | `HomeScreen` hero, driven by `site_settings` + the `home` page |
| 3 | About / mission section | `about` CMS page, excerpted on the home screen |
| 4 | Temple address and management information | `site_settings` contact block |
| 5 | Configurable navigation menu and footer | `navigation_items` table + `site_settings` footer fields |
| 6 | SEO-friendly titles, descriptions and social preview metadata | Runtime `SeoMetadata` service + a pre-render/static tool |
| 7 | Responsive mobile/tablet/desktop layouts | Existing `Breakpoints`, extended to the new sections |
| 8 | Admin-editable static content pages | `PUT /api/admin/pages/{id}` + a focused Flutter editor |
| 9 | Loading, empty, error and offline states for public API screens | Existing `state_views.dart`, applied to every new screen |

### Entity fields (spec §Phase 1 — pages)

`id`, `slug` (unique), `title_hi`, `title_en`, `content_hi`, `content_en`,
`meta_title_hi`, `meta_title_en`, `meta_description_hi`, `meta_description_en`,
`status` (draft/published), `published_at`.

### APIs (spec §Phase 1)

- `GET  /api/public/pages/{slug}?lang=hi|en`
- `GET  /api/public/site-settings`
- `PUT  /api/admin/pages/{id}`
- `PUT  /api/admin/site-settings`

Added because the phase needs them and they follow the same contract:
`GET /api/admin/pages` (list for the editor) and `GET /api/admin/pages/{id}`
(load draft content, which the public endpoint must never return).

### Business / validation rules (spec §Phase 1)

- If English content is missing, the system may show the Hindi version with a
  **clear fallback rule**.
- Only published content is visible publicly.
- Hindi remains the initial language unless the visitor explicitly switches.
- Flutter route slugs and page refresh/deep-link behaviour must work in
  production hosting.

### Dependencies from completed phases

From **Phase 0**: the API envelope (`ApiResponse` ↔ `ApiEnvelopeParser`), error
codes, `auth:sanctum` + `active` middleware, the `roles`/`users` tables, the
Riverpod/go_router/theme/localization foundation, `Breakpoints`, `state_views`,
and the `PublicShell` / `AdminShell` chrome.

### Ambiguities and the assumptions taken

| # | Ambiguity | Assumption (safest, reversible) |
|---|---|---|
| B1 | The spec names `GET/PUT /api/.../site-settings` but never defines its fields. | A **singleton `site_settings` row** (bilingual tagline, footer text, contact block, map link, social links, default SEO) plus a separate **`navigation_items`** table so menu entries can be reordered and hidden individually. Both are returned by the one public endpoint. |
| B2 | "Temple address and management information" overlaps Phase 3's `temple_profile`. | Phase 1 serves the address from `site_settings`. Phase 3 introduces the authoritative `temple_profile` and **migrates** these fields to it; nothing here is duplicated into a second source of truth in the meantime. Documented so Phase 3 does not create a conflict. |
| B3 | Per-role permissions are Phase 2, but Phase 1 exposes admin write endpoints. | A `PagePolicy` / `SiteSettingsPolicy` gate on the **role slug** — `super-admin`, `admin`, `content-manager` may write; `treasurer` and `viewer` may not. This uses the Phase 0 baseline role model without building the Phase 2 permission matrix, which will replace it. Leaving every authenticated user able to edit content would be worse. |
| B4 | "Clear fallback rule" is not specified. | When the requested language's field is blank the API serves the Hindi value and reports it: every localized block carries `language` (what was actually served) and `fallback_used`. The UI shows an unobtrusive notice when English was requested but Hindi was served. Content is never overwritten or merged. |
| B5 | Flutter Web cannot emit per-route metadata for crawlers on its own. | Two layers: (a) **runtime** — the app rewrites `<title>`, description, canonical, `og:*` and `<html lang>` on navigation; (b) **pre-render** — `tool/generate_static_meta.dart` reads the published pages from the API after `flutter build web` and writes a per-slug `index.html` carrying real meta tags plus the unchanged Flutter bootstrap, and emits `sitemap.xml`/`robots.txt`. The Flutter UI is not replaced. |
| B6 | Should CMS content accept HTML? | **No.** Content is stored and rendered as plain text with paragraph breaks. Accepting HTML would mean an XSS surface and a sanitizer this project does not need yet. A richer format can be introduced later behind a stated content type. |
| B7 | Where do page routes live without colliding with `/login`, `/admin`? | Specific routes are declared first; a catch-all `/:slug` is declared **last**, so `/about` is a clean SEO URL. An unknown slug returns 404 from the API and the screen renders the not-found view. |
| B8 | Production must not ship invented temple content. | `PageStructureSeeder` (production-safe) creates the required page rows as **drafts with empty content**. `DevelopmentContentSeeder` (dev-only, refuses in production) fills sample text, clearly marked. |

---

## B. Design before code

### B1. Database

**`pages`** — exactly the specified fields.

| Column | Type | Notes |
|---|---|---|
| `id` | big increments | |
| `slug` | string(120), unique | URL slug, lowercase kebab |
| `title_hi` / `title_en` | string(200) / nullable | English optional → falls back |
| `content_hi` / `content_en` | longText / nullable | Plain text (B6) |
| `meta_title_hi` / `meta_title_en` | string(200), nullable | |
| `meta_description_hi` / `meta_description_en` | string(320), nullable | |
| `status` | enum(`draft`,`published`), default `draft` | |
| `published_at` | timestamp, nullable | Set when first published |
| `updated_by` | FK → `users.id`, nullable, nullOnDelete | Audit trail for edits |
| timestamps | | |

Index: `(status, slug)` for the public lookup.

**`site_settings`** — singleton (`id = 1`, enforced by the service).

`tagline_hi/en`, `footer_text_hi/en`, `address_line1/2`, `village`, `panchayat`,
`police_station`, `district`, `state`, `postal_code`, `country`, `contact_phone`,
`contact_email`, `map_url`, `social_links` (json, nullable),
`default_meta_title_hi/en`, `default_meta_description_hi/en`, `updated_by`, timestamps.

**`navigation_items`**

`id`, `label_hi`, `label_en` (nullable), `route` (string — internal path or absolute URL),
`sort_order` (int), `is_visible` (bool, default true), timestamps.

### B2. API contract

All responses use the Phase 0 envelope. New error code: none needed —
`NOT_FOUND` covers an unknown or unpublished slug.

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/public/pages/{slug}?lang=hi\|en` | public | Published only. 404 for draft or unknown. Returns the resolved language + fallback flag |
| GET | `/api/public/site-settings?lang=hi\|en` | public | Settings + visible navigation, resolved for the language |
| GET | `/api/admin/pages` | session + `manage-content` | Paginated list incl. drafts |
| GET | `/api/admin/pages/{id}` | session + `manage-content` | Both languages raw, no fallback |
| PUT | `/api/admin/pages/{id}` | session + `manage-content` | Validated update; sets `published_at` on first publish |
| PUT | `/api/admin/site-settings` | session + `manage-content` | Settings + full navigation replacement |

Public localized block shape, used by both public endpoints:

```jsonc
{
  "title":   { "value": "…", "language": "hi", "fallback_used": true },
  "content": { "value": "…", "language": "en", "fallback_used": false }
}
```

### B3. Flutter design

```
lib/features/content/
  data/        content_api (repository impl), content_providers
  domain/      page_content, localized_text, site_settings, navigation_item,
               content_repository
  presentation/ home_screen, page_screen, admin_pages_screen,
                admin_page_editor_screen, widgets/
lib/core/seo/  seo_metadata.dart (+ web/io conditional implementations)
```

Routes added:

| Path | Group | Screen |
|---|---|---|
| `/` | public | `HomeScreen` (hero + about excerpt + address) |
| `/:slug` | public, declared **last** | `PageScreen` |
| `/admin/pages` | admin | `AdminPagesScreen` |
| `/admin/pages/:id` | admin | `AdminPageEditorScreen` |

State: `siteSettingsProvider` (FutureProvider, feeds shell nav/footer),
`pageProvider(slug, lang)` (family), `adminPagesProvider`, editor controller.

### B4. Validation / business rules implemented

- Server: `slug` immutable after creation; `title_hi` and `content_hi` required
  (Hindi is the source language); English optional; `status` in enum;
  `published_at` stamped on the draft→published transition and never cleared.
- Server: public queries filter `status = published` **in the query**, not in the
  resource, so a draft cannot leak through a serialization mistake.
- Server: policies deny `treasurer` and `viewer` (B3).
- Client: required-field validation mirrors the server; server remains authoritative.

### B5. Test plan

Backend: page/site-settings migration shape; public endpoint returns published
only; 404 for draft and unknown; language resolution + fallback flags; admin list
/show/update authorization per role (5 roles × allowed/denied); validation
failures; `published_at` stamped once; navigation replacement; settings singleton.

Flutter: model parsing incl. fallback flags and missing optionals; repository
mapping and 404 → not-found; home/page screens' loading/empty/error/offline
states; Hindi default and English switch on CMS content; fallback notice shown;
responsive layout at 3 widths; router deep-link `/about` and unknown slug;
admin editor validation and permission-driven states; SEO metadata service.

### B6. Acceptance criteria

1. `flutter analyze`, `flutter test`, `flutter build web --release`, `php artisan test`,
   `pint --test` all green; migrations verified up/rollback/up on MariaDB.
2. A visitor sees Hindi first; the English switch changes CMS content, with a
   clear notice when Hindi is shown as a fallback.
3. Draft pages are unreachable publicly by any request.
4. `treasurer` and `viewer` cannot write content; the server enforces it.
5. `/about` deep-links and survives refresh; unknown slugs render not-found.
6. Page metadata updates at runtime and the pre-render tool emits static meta.
7. No production temple content is hardcoded in source.

---

## C. Implementation order

1. Migrations + models → 2. policies, services, Form Requests → 3. API resources,
controllers, routes + backend tests → 4. Flutter models/repository →
5. providers/state → 6. screens/routes/editor → 7. SEO service + pre-render tool
→ 8. Flutter tests → 9. regression + docs.

## D. Quality gate

Recorded in `docs/phase-reports/PHASE_1_COMPLETION.md` with real command output.
Not declared COMPLETE unless every gate item passes.

---

## Out of scope for Phase 1 (deferred, deliberately)

Committee/trustee directory and `temple_profile` (Phase 3); events (Phase 4);
gallery/media (Phase 5); donations (Phase 6); enquiry form (Phase 7);
announcements banner (Phase 8); the permission matrix and user management
(Phase 2); rich-text/HTML content (B6).

## Side task (not a spec requirement)

Replace the default Flutter favicon and PWA icons with a temple mark drawn from
the Phase 0 design tokens. Tracked here so it appears in the completion report.
