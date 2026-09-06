# Phase 1 Completion Report — Public Website & Bilingual CMS

**Date:** 2026-09-05
**Status: COMPLETE** — every Phase 1 requirement is implemented and every
delivery-gate check is green on both stacks, including migrations verified
against MariaDB.

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 · Composer 2.10.3 ·
Laravel 12.69.1 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 1 requirement | Status | Where |
|---|---|---|---|
| 1 | Hindi default; English switch always visible on the public site | ✅ | Phase 0 foundation, now driving CMS content too |
| 2 | Home page hero with temple name and devotional tagline | ✅ | `HomeScreen._Hero`, tagline from `site_settings` |
| 3 | About / mission section | ✅ | `about` CMS page, excerpted on the home screen |
| 4 | Temple address and management information | ✅ | `AddressCard` from the `site_settings` contact block |
| 5 | Configurable navigation menu and footer | ✅ | `navigation_items` table + footer fields, rendered by `PublicShell` |
| 6 | SEO titles, descriptions and social preview metadata | ✅ | Runtime `SeoScope`/`SeoMetadataService` **and** `tool/generate_static_meta.dart` |
| 7 | Responsive mobile/tablet/desktop layouts | ✅ | Existing breakpoints; menu collapses to a drawer under 1024 px |
| 8 | Admin-editable static content pages | ✅ | `PUT /api/admin/pages/{id}` + `AdminPagesScreen` / `AdminPageEditorScreen` |
| 9 | Loading, empty, error and offline states | ✅ | Every new screen; covered by widget tests |

### Entity fields (spec §Phase 1)

All twelve specified `pages` fields exist exactly as named: `id`, `slug`,
`title_hi`, `title_en`, `content_hi`, `content_en`, `meta_title_hi`,
`meta_title_en`, `meta_description_hi`, `meta_description_en`, `status`,
`published_at`. Plus `updated_by` and timestamps for the audit trail.

### Business / validation rules

| Rule | How it is enforced |
|---|---|
| Missing English falls back to Hindi with a **clear** rule | `LocalizedText` resolves per block and reports `language` + `fallback_used`; the UI shows one notice per page |
| Only published content is publicly visible | The `published` filter is in the **query** (`PageService::publishedBySlug`), not the serializer, so a draft cannot leak through a presentation mistake |
| Hindi remains the initial language | Unchanged from Phase 0; the browser locale is deliberately ignored |
| Route slugs, refresh and deep links work in production hosting | Catch-all `/:slug` declared last; verified against a host that rewrites unknown paths to `index.html` |

---

## 2. Database / migration changes

| Migration | Table |
|---|---|
| `2026_09_05_000000_create_pages_table` | `pages` — the twelve spec fields, `updated_by` FK (nullOnDelete), index on `(status, slug)` |
| `2026_09_05_000001_create_site_settings_table` | `site_settings` — singleton: bilingual tagline/footer, contact block, `social_links` json, default SEO |
| `2026_09_05_000002_create_navigation_items_table` | `navigation_items` — bilingual label, route, `sort_order`, `is_visible` |

Verified on **MariaDB 12.3.3**: `migrate` → `rollback` (correct reverse order) →
`migrate` → `db:seed`.

**Seeders.** `PageStructureSeeder` is production-safe and idempotent: it creates
the `home` and `about` rows as **drafts with empty content**. That is structure,
not content — the specification forbids shipping invented temple text, so the
committee publishes each page once they have written it.
`DevelopmentContentSeeder` fills sample copy and refuses to run in production;
its `about` page is deliberately Hindi-only so the fallback path is visible
locally.

---

## 3. API endpoints created

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/public/pages/{slug}?lang=hi\|en` | public | Published only. A draft and an unknown slug return an identical 404 |
| GET | `/api/public/site-settings?lang=hi\|en` | public | Answers on a fresh install with empty values, not an error |
| GET | `/api/admin/pages` | session + `manage-content` | Paginated, includes drafts |
| GET | `/api/admin/pages/{id}` | session + `manage-content` | Both languages raw, no fallback |
| PUT | `/api/admin/pages/{id}` | session + `manage-content` | Slug immutable; `published_at` stamped once |
| GET/PUT | `/api/admin/site-settings` | session + `manage-content` | `navigation` replaces the whole menu in a transaction |

Localized block contract, shared by both public endpoints:

```jsonc
{ "value": "…", "language": "hi", "fallback_used": true }
```

Documented in `docs/api/openapi.yaml` (now v0.2.0, 12 paths, 11 schemas).

---

## 4. Flutter routes, screens and components

| Path | Group | Screen |
|---|---|---|
| `/` | public | `HomeScreen` — hero, about excerpt, address |
| `/:slug` | public, declared **last** | `PageScreen` |
| `/admin/pages` | admin | `AdminPagesScreen` |
| `/admin/pages/:id` | admin | `AdminPageEditorScreen` |

New: `features/content/` (domain `LocalizedValue`, `PageContent`,
`EditablePage`, `SiteSettings`, `NavigationEntry`, `ContactInfo`; data
repository + providers; presentation screens, `SeoScope`, `FallbackNotice`,
`ContentBody`, `ContentSection`, `AddressCard`) and `core/seo/`
(`PageMetadata`, `SeoMetadataService` with web/VM implementations).

`PublicShell` now renders the admin-configured menu — inline on desktop, in a
drawer below 1024 px — and the CMS footer, falling back to the temple's identity
if settings fail to load. The Phase 0 `FoundationHomeScreen` placeholder was
deleted.

---

## 5. Roles and permissions

Content writes require the **`manage-content`** ability: `super-admin`, `admin`
and `content-manager` may edit; `treasurer` and `viewer` may not. This is a
deliberate narrowing rather than "any authenticated user" — a Treasurer has no
business rewriting the temple's public pages. Phase 2 replaces this gate with
the permission matrix.

Enforced server-side and asserted per role by
`AdminContentAuthorizationTest` (data-provider cases, one application per role).

---

## 6. Tests and command results

```
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  79 files, 0 changed
$ flutter test                                       167/167 passed
$ flutter build web --release                        Built build/web
$ ./vendor/bin/pint --test                           passed
$ php artisan test                                   98 passed (360 assertions)
$ migrate → rollback → migrate → db:seed (MariaDB)   all reversible
$ dart run tool/generate_static_meta.dart            2 routes pre-rendered
```

**Backend, 98 tests** (49 from Phase 0 + 49 new): `LocalizedTextTest` (the
fallback rule in isolation), `PublicPageTest` (language resolution, blank-value
handling, draft invisibility, draft-vs-missing indistinguishability, draft text
absent from the response body), `AdminPageEditingTest` (raw both-language view,
pagination meta, `published_at` stamped once and never moved, slug immutability,
Hindi required / English optional, publish makes it public), `SiteSettingsTest`
(fresh-install behaviour, singleton invariant, menu ordering and hidden items,
wholesale menu replacement, transaction rollback on invalid input),
`AdminContentAuthorizationTest` (5 roles × allowed/denied, guest, blocked).

**Flutter, 167 tests** (107 from Phase 0 + 60 new): model parsing including
defensive handling of malformed navigation entries and missing optionals;
`HomeScreen` (CMS hero, excerpt-only about, address, loading, unconfigured-site
empty states, settings outage with retry, fallback notice, three breakpoints);
`PageScreen` (paragraphs, not-found for unknown slug, retry for transport
failure, empty published page, plain-text rendering of markup-looking content);
`PublicShell` (desktop menu, drawer below 1024 px, CMS footer, degradation when
settings fail); admin list and editor (status chips, Hindi-only badge,
unauthorized state, validation, blank English sent as absent, publish toggle,
server field errors, disabled while saving); SEO metadata composition and
truncation.

### Live verification against MariaDB

| Check | Result |
|---|---|
| `GET /api/public/pages/home` | 200, Hindi content and SEO metadata |
| `GET /api/public/pages/about?lang=en` | English **title** served, Hindi **content** with `fallback_used: true` — per-block resolution working |
| `GET /api/public/site-settings` | tagline, 2-item menu, address block |
| Pre-render tool | `index.html`, `about/index.html`, `sitemap.xml`, `robots.txt` |

---

## 7. Defects found and fixed during the phase

| # | Defect | Fix |
|---|---|---|
| 1 | Pre-rendered titles read `राधा कृष्ण ठाकुरवाड़ी, अमरपुर पंखोरिया \| राधा कृष्ण ठाकुरवाड़ी \| …` — an SEO title that already names the temple was suffixed with it again | `PageMetadata.compose` and the pre-render tool now skip the suffix when the page title already contains the site name; covered by a test |
| 2 | Admin screens crashed in tests with "No Material widget found" | They are shell children in the app; the test helper now wraps them as `AdminShell` does. Confirmed the screens legitimately depend on an ancestor Scaffold |
| 3 | A localization test asserted the deleted Phase 0 placeholder copy | Rewritten to assert Hindi-first rendering of the real CMS content |

---

## 8. Side task — favicon and app icons

The default Flutter favicon was replaced with a temple mark: a shikhara with a
kalash finial, ivory on a rose tile with a peacock plinth, drawn from the theme
tokens. Generated reproducibly by `frontend_flutter/tool/generate_icons.py`
(committed) into `favicon.png` (128 px), `Icon-192/512.png` and the two maskable
variants. Verified legible at 16 px. `index.html` and `manifest.json` now carry
the matching `theme_color`.

## 9. Theme change (product-owner decision)

The palette moved from "Marigold & Maroon" to **"Rose & Peacock"** at the product
owner's choice: Radha's rose `#B5426B` as primary, Krishna's peacock `#1F6F78`
as secondary, temple gold `#C9971F` as the accent, warm ivory `#FFF7F4` ground.
Only `app_colors.dart` and the web shell changed — no screen references a colour
literal, which is what made the swap a two-file change.

---

## 10. Known issues and technical debt

1. **The `manage-content` gate is a placeholder for the permission matrix.**
   Role-slug based, to be replaced in Phase 2. It is deliberately narrower than
   "any authenticated user", so replacing it can only loosen with intent.
2. **Site settings have no admin UI yet.** `PUT /api/admin/site-settings` is
   implemented, validated, authorized and tested, but the Flutter editor covers
   pages only. The tagline, footer, address and menu are editable by API today.
   This is the one place where the phase's "admin-editable" feature is complete
   at the contract level but not yet at the UI level — worth closing early in
   Phase 2 alongside the admin dashboard.
3. **The address lives in `site_settings`, not `temple_profile`.** Phase 3
   introduces the authoritative profile; these fields must **move**, not be
   duplicated (PHASE_1_PLAN assumption B2).
4. **Content is plain text.** No HTML or rich text, which also means no XSS
   surface and no sanitizer. A richer format needs a stated content type.
5. **The pre-render tool must run after every `flutter build web`.** It is not
   wired into CI yet, so a deploy that skips it ships generic metadata. The
   runtime metadata still works for crawlers that execute JavaScript.
6. **External navigation links are inert.** `url_launcher` is not a dependency;
   an entry pointing at an absolute URL renders disabled rather than opening.
7. **Admin chrome flashes before the guard redirects** (carried over from
   Phase 0, known issue #9).
8. **No end-to-end test crosses the two stacks** (carried over; Phase 12).

---

## 11. Next phase

**Phase 2 — Admin, Users & Role Management.** Planned but **not started**, and
it will not be started without explicit approval.
