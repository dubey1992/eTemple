# Radha Krishna Thakurbari — Implementation Plan (Phases 0–12)

Source of truth: *Phase-wise Flutter Web & Backend Development Specification v1.1* (September 2026).

Frontend: **Flutter Web (Dart 3.x)** · Backend: **Laravel REST/JSON API** · Database: **MySQL 8.x / MariaDB**
Default language: **Hindi (hi)** · Secondary language: **English (en)**

---

## Repository layout

```
/frontend_flutter    Flutter Web app (public site + admin console)
/backend_laravel     Laravel REST/JSON API
/docs                Specification-derived documentation
  /phase-plans       PHASE_<N>_PLAN.md   (written before code)
  /phase-reports     PHASE_<N>_COMPLETION.md (written after the quality gate)
  /api               OpenAPI contract
```

## Working agreement

1. One phase at a time. A phase starts only after the product owner replies
   *"Proceed to Phase &lt;N&gt; using the same phase workflow and completion gate."*
2. Each phase: requirement review → plan doc → migrations → backend logic/authorization →
   API + tests → Flutter models/repositories → state → UI/routes → Flutter tests →
   regression → documentation → completion report → **STOP**.
3. A phase is never marked COMPLETE while tests fail, critical TODOs remain, or acceptance
   criteria are partially implemented.
4. Future-phase features are not implemented early. Only reusable foundation genuinely
   required by the current phase is allowed.

---

## Phase 0 — Foundation & Core Setup

Objective: a stable, secure, maintainable Flutter + Laravel technical foundation.

- [x] `/frontend_flutter`, `/backend_laravel`, `/docs` repository structure
- [x] Flutter Web project, feature-first folder structure, responsive app shell
- [x] Material 3 temple theme + design tokens (colour, typography, spacing, breakpoints)
- [x] Hindi-default / English localization infrastructure (`flutter_localizations` + `intl`, ARB)
- [x] `go_router` foundation with separated public/admin route groups and auth guard
- [x] Riverpod DI/state foundation
- [x] Dio API client, JSON envelope parsing, standardized error mapping
- [x] Environment configuration via `--dart-define`, no secrets in source
- [x] Laravel application skeleton + database configuration
- [x] Migrations, seeders, factories, PHPUnit test framework
- [x] Auth foundation: `login`, `logout`, `me`, `forgot-password`
- [x] Protected admin route foundation (backend middleware + Flutter guard)
- [x] Baseline `roles` model and seed (Super Admin, Admin, Treasurer, Content Manager, Viewer)
- [x] Logging + centralized exception handling standards
- [x] CI workflow with lint/test/build commands
- [x] Green baseline Flutter tests (107/107), `flutter analyze` clean, release web build succeeds
- [x] Green baseline Laravel tests (49/49), Pint clean, migrations verified up/rollback/up
- [x] Migrations verified against MariaDB 12.3.3, with schema/index/FK parity checked

**Phase 0 is COMPLETE.** Every delivery-gate check is green; see
`phase-reports/PHASE_0_COMPLETION.md`.

Explicitly **out** of Phase 0: CMS pages, home/about content, user CRUD screens, permission matrix UI.

## Phase 1 — Public Website & Bilingual CMS

- [x] `pages` entity (`slug`, `title_hi/en`, `content_hi/en`, `meta_title_hi/en`, `meta_description_hi/en`, `status`, `published_at`)
- [x] `site_settings` (navigation menu, footer, contact block) + `navigation_items`
- [x] `GET /api/public/pages/{slug}?lang=hi|en`, `GET /api/public/site-settings`
- [x] `PUT /api/admin/pages/{id}`, `PUT /api/admin/site-settings`
- [x] Home hero, about/mission, address & management sections in Flutter
- [x] Configurable navigation + footer driven by API
- [x] SEO/social preview metadata strategy (runtime `SeoScope` + `tool/generate_static_meta.dart`)
- [x] Hindi-first rendering with documented English→Hindi fallback (`fallback_used`)
- [x] Published-only public visibility; drafts never returned publicly
- [x] Loading / empty / error / offline states for every public API-driven screen
- [x] Deep-link and refresh behaviour verified on production-style hosting

**Phase 1 is COMPLETE.** 167 Flutter tests, 98 Laravel tests; see
`phase-reports/PHASE_1_COMPLETION.md`.

> Carried into Phase 2: the site-settings **admin UI** (the API is complete,
> validated and tested; only the Flutter editor for it is outstanding).

## Phase 2 — Admin, Users & Role Management

- [x] `roles.permissions` populated from a code-defined catalogue; permission matrix by module
- [x] `GET|POST /api/admin/users`, `PUT /api/admin/users/{id}`
- [x] `GET /api/admin/roles`, `PUT /api/admin/roles/{id}/permissions`, `GET /api/admin/permissions`
- [x] Admin dashboard, user create/deactivate, role management, password reset, login history
- [ ] Optional two-factor authentication for Super Admin — **deferred** (`phase-reports/PHASE_2_COMPLETION.md` §7)
- [x] Flutter route guards and permission-aware menus (server-side authorization remains mandatory)
- [x] Carried from Phase 1: the site-settings admin editor

**Phase 2 is COMPLETE** apart from the optional 2FA item. 199 Flutter tests,
164 Laravel tests; see `phase-reports/PHASE_2_COMPLETION.md`.

## Phase 3 — Temple Profile & Committee

- [x] `temple_profile` (name/address/history/mission bilingual, `logo_url`, `map_url`)
- [x] `committee_members` with designation, tenure dates, public/private visibility
- [x] `GET /api/public/temple-profile`, `PUT /api/admin/temple-profile`
- [x] `GET /api/public/committee`, `POST /api/admin/committee-members` (+ show/update/delete)
- [x] Consent-gated publication of member personal details — enforced in three
      independent layers, each tested separately
- [x] Carried from Phase 1: the address **moved** out of `site_settings`, columns dropped
- [x] Carried from Phase 2: the temple name and village **taken over** from the ARB files

**Phase 3 is COMPLETE.** 258 Flutter tests, 216 Laravel tests; see
`phase-reports/PHASE_3_COMPLETION.md`.

## Phase 4 — Puja, Events & Calendar

- [x] `events` (`event_type`, bilingual title/description/venue, `start_at`, `end_at`, `poster_url`, `is_featured`, `status`, `created_by`)
- [x] Public event list/detail + admin CRUD endpoints
- [x] Daily aarti, bhajan-kirtan, festival, one-time and recurring events —
      stored as a **rule** and expanded on read, so the daily aarti is one record
- [x] Past/upcoming views, featured flag, timezone-safe API values (offsets, not bare UTC)
- [x] Rules: `end_at >= start_at`; drafts never public; cancelled retained **and shown**, flagged
- [x] Admin breadcrumbs and equal-height cards (findings raised against Phase 3)

**Phase 4 is COMPLETE.** 318 Flutter tests, 279 Laravel tests; see
`phase-reports/PHASE_4_COMPLETION.md`.

## Phase 5 — Gallery & Video Darshan

- [x] `media` (+ optional `albums`): `media_type`, bilingual titles, `file_url`, `external_url`, `thumbnail_url`, `sort_order`, `status`, `uploaded_by`
- [x] Public gallery/videos endpoints + admin media CRUD
- [x] Server-side MIME/size validation, metadata stripping, optimized responsive variants
- [x] Lazy-loading memory-conscious Flutter gallery
- [x] Deletion guard when media is referenced by a page/event

## Phase 6 — Donations & Receipts

- [x] `donations` (`receipt_number`, `donor_name`, `amount`, `donation_date`, `payment_mode`, `reference_number`, `purpose`, `notes`, `status`, `recorded_by`)
- [x] `donation_settings` (public bank/UPI details)
- [x] Admin donation endpoints + receipt endpoint; printable/PDF receipt
- [x] Rules: amount &gt; 0; receipt number unique and immutable; no hard delete (reversal records); donor privacy

## Phase 7 — Devotee Contact & Enquiries

- [ ] `enquiries` (`name`, `mobile`, `email`, `category`, `message`, `preferred_language`, `status`, `assigned_to`, `resolved_at`)
- [ ] `POST /api/public/enquiries`, admin inbox + status endpoints
- [ ] Spam protection, rate limiting, CAPTCHA-after-threshold, optional acknowledgement email
- [ ] Enquiry content never displayed publicly

## Phase 8 — Announcements & Notifications

- [ ] `announcements` (bilingual title/message, `priority`, `start_at`, `end_at`, `channels`, `status`, `created_by`)
- [ ] Public announcements endpoint + admin create/send endpoints
- [ ] Homepage banner respecting backend schedule/expiry
- [ ] Optional email; SMS/WhatsApp only after provider approval; no sends without explicit admin action

## Phase 9 — Accounts & Transparency

- [ ] `accounting_categories`, `transactions` (`type`, `category_id`, `amount`, `transaction_date`, `payment_mode`, `reference_number`, `description`, `attachment_url`, `approved_by`, `status`, `created_by`)
- [ ] Admin transaction + summary endpoints, `GET /api/public/transparency`
- [ ] Only approved data in public totals; attachments private; reversal preserves audit trail

## Phase 10 — Reports & Analytics

- [ ] Donation, accounts, events, enquiries report endpoints
- [ ] PDF/CSV/Excel export applying exactly the on-screen filters
- [ ] Role-gated access; sensitive donor columns excluded without explicit permission

## Phase 11 — Security, Audit, Backup & Privacy

- [ ] `audit_logs` (`user_id`, `action`, `entity_type`, `entity_id`, `before_data`, `after_data`, `ip_address`)
- [ ] Append-only audit behaviour; permission enforcement on every admin endpoint
- [ ] Database + media backup schedule and rehearsed restore procedure
- [ ] Secure headers, HTTPS-only, CSRF, session timeout, login rate limits
- [ ] No sensitive tokens in insecure browser storage

## Phase 12 — Testing, Deployment & Handover

- [ ] Full backend unit/feature/API/authorization suites
- [ ] Flutter unit/widget/integration suites, localization and responsive regression
- [ ] Donation receipt, accounting and media upload workflow tests; security smoke tests
- [ ] Staging acceptance by committee, production deployment with backup + rollback plan
- [ ] Admin user guide, training, backup/restore handover checklist
- [ ] `flutter analyze`, `flutter test`, `flutter build web --release`, `php artisan test` green

---

## Release grouping

| Release | Phases | Content |
|---|---|---|
| MVP | 0–5 | Bilingual public site, admin login, profile/committee, events, gallery, video darshan |
| Donation | 6–7 | Donation records/receipts, devotee contact and volunteer enquiries |
| Communication & Transparency | 8–10 | Announcements, accounts/transparency, reporting |
| Production Hardening | 11–12 | Audit, backup, security QA, deployment, training, handover |

---

## Standing commands

| Purpose | Command |
|---|---|
| Flutter dependencies | `flutter pub get` (in `frontend_flutter`) |
| Flutter static analysis | `flutter analyze` |
| Flutter tests | `flutter test` |
| Flutter release web build | `flutter build web --release` |
| Backend dependencies | `composer install` (in `backend_laravel`) |
| Backend tests | `php artisan test` |
| Migration verification | `php artisan migrate:fresh --seed` then `php artisan migrate:rollback` |
