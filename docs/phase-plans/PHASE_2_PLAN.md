# Phase 2 Plan — Admin, Users & Role Management

> **Objective (spec §Phase 2):** Give the temple committee controlled access to
> backend features through a protected Flutter Web admin dashboard.

---

## A. Requirement review

### Features required by the specification

| # | Requirement | Where it lands |
|---|---|---|
| 1 | Admin dashboard | `AdminDashboardScreen` — permission-aware entry points |
| 2 | User creation and deactivation | `users` CRUD endpoints + `AdminUsersScreen` / editor |
| 3 | Role management | `GET /api/admin/roles`, role list screen |
| 4 | Permission matrix by module | `Permission` catalogue + `PUT /api/admin/roles/{id}/permissions` + matrix UI |
| 5 | Password reset | Completes the Phase 0 flow: `POST /api/auth/reset-password`, `/reset-password` screen, plus an admin-initiated reset link |
| 6 | Login history | `login_attempts` table, recorded on every attempt, surfaced per user |
| 7 | Optional two-factor authentication for Super Admin | **Deferred — see assumption C7** |
| 8 | Flutter route guards and permission-aware menus/actions | `permissionsProvider`, guarded admin routes, menus that hide what the server would refuse |

### Entity fields (spec §Phase 2 — roles)

`id`, `name`, `description`, `permissions` (permission keys or relation table),
`status` (active/inactive), `created_at`, `updated_at`.

All already exist from the Phase 0 `roles` migration; Phase 2 finally populates
`permissions` and enforces it.

### APIs (spec §Phase 2)

- `GET  /api/admin/users`
- `POST /api/admin/users`
- `PUT  /api/admin/users/{id}`
- `GET  /api/admin/roles`
- `PUT  /api/admin/roles/{id}/permissions`

Added because the phase needs them and they follow the same contract:
`GET /api/admin/users/{id}`, `GET /api/admin/permissions` (the catalogue the
matrix UI renders), `GET /api/admin/users/{id}/login-history`,
`POST /api/admin/users/{id}/send-password-reset`, and
`POST /api/auth/reset-password` (completes Phase 0's forgot-password).

### Business / validation rules (spec §Phase 2)

- Super Admin can manage users and roles.
- Treasurer can manage donation/accounting modules but cannot change security
  settings unless explicitly granted.
- Content Manager can manage pages, events and media but cannot see sensitive
  financial details by default.
- **Hiding a Flutter button is never the authorization control; backend
  authorization remains mandatory.**

### Dependencies from completed phases

**Phase 0**: `users`/`roles` tables, Sanctum session auth, `EnsureUserIsActive`,
the API envelope and error codes, `AuthService`, the admin route group.
**Phase 1**: the `manage-content` gate (replaced by the matrix this phase), the
admin shell and editor patterns, `LocalizedText`, the state-view widgets.

### Ambiguities and the assumptions taken

| # | Ambiguity | Assumption (safest, reversible) |
|---|---|---|
| C1 | "Permission keys or relation table" — which? | **Keys in the existing `roles.permissions` JSON column**, validated against a code-defined catalogue (`App\Support\Permission`). The catalogue is static and belongs in code, so a pivot table would add joins and migrations without adding integrity. `GET /api/admin/permissions` exposes it to the matrix UI. |
| C2 | The matrix must cover modules that do not exist yet (donations, events, media…). | The catalogue defines keys for **every** module in the roadmap so the matrix is designed once and later phases attach endpoints to keys that already exist. Only keys whose modules exist are *enforced* today; the rest are inert until their phase. Documented on each key. |
| C3 | Can a Super Admin be locked out of their own system? | **No.** `Gate::before` grants Super Admin everything, its permission set is not editable, and the server refuses to deactivate, block, demote or delete the **last active Super Admin**. A permission system that can brick the temple's only administrator is a defect, not a feature. |
| C4 | Can an admin edit their own account? | Profile fields yes; **their own role and status, no.** Self-demotion and self-deactivation are the two ways an administrator accidentally locks themselves out, and they are always a mistake rather than an intent. |
| C5 | How are new users given a password? | The creator does **not** set one. The account is created without a usable password and a reset link is mailed, so a plaintext password never travels through the committee over WhatsApp. `POST .../send-password-reset` re-sends it. |
| C6 | Phase 1 left `manage-content` as a role-slug gate. | Replaced by the matrix key `content.manage`. The default role→permission seed reproduces today's behaviour exactly, so Phase 1's authorization tests keep passing unchanged — that is the check that the swap is faithful. |
| C7 | "Optional two-factor authentication for Super Admin". | **Deferred, not skipped.** The specification marks it optional; a correct implementation needs a TOTP dependency, recovery codes, an enrollment flow, a challenge step in login, and its own security tests — comparable in size to the rest of this phase. Everything else in Phase 2 is delivered; 2FA is called out in the completion report as the one optional item outstanding, and is offered as a focused follow-up before Phase 3. |
| C8 | "Sensitive financial details" for Content Manager. | No financial module exists until Phase 6/9. The catalogue defines `donations.*` and `accounts.*` keys and the default seed withholds them from Content Manager, so the rule is already encoded when those phases arrive. |
| C9 | Login history scope. | Records **every** attempt — success and failure, with outcome, IP and user agent — because a failed-attempt trail is what makes the history useful for security. Retained rows are readable only through an authorized endpoint. |

---

## B. Design before code

### B1. Database

**`login_attempts`** (new)

| Column | Type | Notes |
|---|---|---|
| `id` | big increments | |
| `user_id` | FK → `users.id`, nullable, nullOnDelete | Null when the e-mail matched no account |
| `email` | string(191) | What was actually typed, lowercased |
| `outcome` | enum(`success`,`invalid_credentials`,`inactive`,`blocked`) | Mirrors `AuthService` |
| `ip_address` | string(45), nullable | |
| `user_agent` | string(500), nullable | |
| `created_at` | timestamp | Index `(user_id, created_at)` |

**`roles.permissions`** — already exists (json, nullable). Phase 2 populates it.

**`users`** — no schema change. `password` becomes nullable? **No** — instead a
new user is created with an unusable random hash, so the column stays
non-nullable and no code path can accidentally authenticate an empty password.

### B2. Permission catalogue

`App\Support\Permission` — module-grouped keys:

| Module | Keys | Enforced now? |
|---|---|---|
| Content | `content.view`, `content.manage` | ✅ replaces `manage-content` |
| Users | `users.view`, `users.manage` | ✅ |
| Roles | `roles.view`, `roles.manage` | ✅ |
| Security | `security.view` (login history), `security.manage` | ✅ |
| Temple profile | `temple.manage` | Phase 3 |
| Events | `events.manage` | Phase 4 |
| Media | `media.manage` | Phase 5 |
| Donations | `donations.view`, `donations.manage` | Phase 6 |
| Enquiries | `enquiries.manage` | Phase 7 |
| Announcements | `announcements.manage` | Phase 8 |
| Accounts | `accounts.view`, `accounts.manage` | Phase 9 |
| Reports | `reports.view`, `reports.export` | Phase 10 |

Default seed, encoding the specification's role descriptions:

| Role | Permissions |
|---|---|
| Super Admin | **all**, implicitly and non-editably (C3) |
| Admin | everything except `roles.manage` and `security.manage` |
| Treasurer | `donations.*`, `accounts.*`, `reports.*`, `content.view` — no security, no user management |
| Content Manager | `content.*`, `events.manage`, `media.manage`, `announcements.manage`, `temple.manage` — **no** `donations.*` / `accounts.*` |
| Viewer | the `*.view` keys only |

### B3. API contract

| Method | Path | Ability | Notes |
|---|---|---|---|
| GET | `/api/admin/permissions` | `roles.view` | The catalogue, grouped by module, with labels |
| GET | `/api/admin/roles` | `roles.view` | Roles with their permission keys |
| PUT | `/api/admin/roles/{id}/permissions` | `roles.manage` | Replaces the set; rejects unknown keys; refuses to edit Super Admin |
| GET | `/api/admin/users` | `users.view` | Paginated, filterable by role/status/search |
| POST | `/api/admin/users` | `users.manage` | No password accepted; mails a reset link |
| GET | `/api/admin/users/{id}` | `users.view` | |
| PUT | `/api/admin/users/{id}` | `users.manage` | Profile, role, status — with the C3/C4 guards |
| GET | `/api/admin/users/{id}/login-history` | `security.view` | Paginated attempts |
| POST | `/api/admin/users/{id}/send-password-reset` | `users.manage` | |
| POST | `/api/auth/reset-password` | guest, throttled | Completes the Phase 0 flow |
| GET | `/api/auth/me` | — | **Extended** with the caller's effective `permissions` |

### B4. Flutter design

```
lib/features/admin/
  data/        admin_repository(+impl), admin_providers
  domain/      admin_user, role, permission_catalogue, login_attempt
  presentation/ admin_dashboard_screen, admin_users_screen,
                admin_user_editor_screen, admin_roles_screen,
                admin_role_permissions_screen, login_history_view
lib/features/content/presentation/admin_site_settings_screen.dart  (carried from Phase 1)
lib/features/auth/presentation/reset_password_screen.dart
lib/core/auth/permissions.dart  — Permission keys mirrored for the client
```

Routes: `/admin` (dashboard), `/admin/users`, `/admin/users/:id`,
`/admin/roles`, `/admin/roles/:id/permissions`, `/admin/site-settings`,
`/reset-password` (public).

`permissionsProvider` derives the signed-in user's effective keys from
`/api/auth/me`. Menus and actions hide what the server would refuse — **as a
courtesy, never as the control**, which the tests assert by calling the API
directly with an unauthorized role.

### B5. Validation / business rules implemented

- Unknown permission keys rejected (422) rather than silently stored.
- Super Admin's permissions are not editable; the endpoint refuses (422).
- Last active Super Admin cannot be deactivated, blocked or demoted (422).
- A user cannot change their own role or status (422).
- E-mail unique, case-insensitive; role must exist and be active.
- Reset token validated by Laravel's broker; password ≥ 8 chars; reset
  invalidates other sessions.
- Login attempts recorded for every outcome, including unknown e-mails.

### B6. Test plan

Backend: catalogue integrity; permission resolution per role; `Gate::before` for
Super Admin; every endpoint × allowed/denied role; the four safety guards
(C3/C4) each proven to block; user creation mails a link and stores no usable
password; reset completes and is single-use; login history records each outcome;
Phase 1's content tests still pass **unchanged** against the new matrix.

Flutter: permission model parsing; `permissionsProvider` derivation; dashboard
shows only permitted entries; user list/editor states; role matrix toggles and
save; Super Admin matrix read-only; login history empty/loaded; reset-password
screen validation and success; site-settings editor; router guards for
permission-scoped routes.

### B7. Acceptance criteria

1. All gate commands green; migrations reversible on MariaDB.
2. Every Phase 1 authorization test passes **unmodified** (C6 proves the swap).
3. A Treasurer cannot reach user, role or content management — verified by
   direct API call, not by UI absence.
4. The last Super Admin cannot be locked out by any endpoint.
5. A created user receives a reset link and has no usable password until they use it.
6. Login history shows successes and failures.

---

## C. Implementation order

1. `Permission` catalogue + migration + role seed → 2. gates/policies replacing
`manage-content` → 3. user/role/permission services + Form Requests →
4. controllers, routes, backend tests → 5. Flutter permission model + providers
→ 6. dashboard, users, roles, matrix, login history, site settings, reset
password → 7. Flutter tests → 8. regression + docs + showcase.

## D. Quality gate

Recorded in `docs/phase-reports/PHASE_2_COMPLETION.md` with real command output,
followed by a live showcase in a visible browser.

---

## Out of scope for Phase 2

Two-factor authentication (C7, deferred and reported); the audit log and backups
(Phase 11); every business module from Phase 3 onwards — their permission keys
exist but nothing enforces them yet.
