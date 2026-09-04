# Phase 2 Completion Report — Admin, Users & Role Management

**Date:** 2026-09-06
**Status: COMPLETE**, with one explicitly optional item deferred and reported
(two-factor authentication — see §7).

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 · Composer 2.10.3 ·
Laravel 12.69.1 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 2 requirement | Status | Where |
|---|---|---|---|
| 1 | Admin dashboard | ✅ | `AdminDashboardScreen` — entries appear only for permitted modules |
| 2 | User creation and deactivation | ✅ | `users` endpoints + `AdminUsersScreen` / `AdminUserEditorScreen` |
| 3 | Role management | ✅ | `GET /api/admin/roles` + `AdminRolesScreen` |
| 4 | Permission matrix by module | ✅ | `App\Support\Permission` catalogue + `PUT .../permissions` + matrix UI |
| 5 | Password reset | ✅ | `POST /api/auth/reset-password` + `/reset-password` screen + admin-initiated resend |
| 6 | Login history | ✅ | `login_attempts` table, every outcome recorded, `LoginHistoryView` |
| 7 | Two-factor authentication for Super Admin (**optional**) | ⏸ deferred | §7 |
| 8 | Flutter route guards and permission-aware menus/actions | ✅ | `permissionsProvider`, guarded routes, hidden-but-not-trusted controls |

### Business rules (spec §Phase 2)

| Rule | How it is enforced |
|---|---|
| Super Admin can manage users and roles | `Gate::before` grants Super Admin everything |
| Treasurer manages donations/accounting but not security | Default matrix: `donations.*`, `accounts.*`, `reports.*`; **no** `security.*`, `users.*`, `roles.*` |
| Content Manager manages content but sees no financial detail | Default matrix: `content.*`, `events`, `media`, `announcements`, `temple`; **no** `donations.*` or `accounts.*` |
| **Hiding a Flutter button is never the authorization control** | `PermissionEnforcementTest` calls every endpoint directly with roles that should be refused; a passing UI test could not stand in for it |

---

## 2. Database changes

| Migration | Table |
|---|---|
| `2026_09_06_000000_create_login_attempts_table` | `login_attempts` — `user_id` (nullable, nullOnDelete), `email`, `outcome` enum, `ip_address`, `user_agent`, `created_at`; indexed on `(user_id, created_at)` and `(email, created_at)` |

`roles.permissions` already existed from Phase 0 and is now populated. No other
schema change: an account created without a password gets an unusable random
hash rather than a nullable column, so no code path can authenticate an empty
password.

Verified on **MariaDB 12.3.3**: `migrate` → `rollback` → `migrate` → `db:seed`.

**Seeded matrix:** super-admin 19 (computed), admin 17, treasurer 7,
content-manager 7, viewer 4.

`RoleSeeder` applies defaults **only to roles that have never been configured**.
A routine deploy re-runs seeders, and silently reversing the committee's access
decisions would be worse than leaving them.

---

## 3. API endpoints

| Method | Path | Ability |
|---|---|---|
| GET | `/api/admin/users` | `users.view` |
| POST | `/api/admin/users` | `users.manage` |
| GET/PUT | `/api/admin/users/{id}` | `users.view` / `users.manage` |
| GET | `/api/admin/users/{id}/login-history` | `security.view` |
| POST | `/api/admin/users/{id}/send-password-reset` | `users.manage` |
| GET | `/api/admin/roles` | `roles.view` |
| GET | `/api/admin/permissions` | `roles.view` |
| PUT | `/api/admin/roles/{id}/permissions` | `roles.manage` |
| POST | `/api/auth/reset-password` | public, throttled |
| GET | `/api/auth/me` | **extended** with the caller's `permissions` |

Documented in `docs/api/openapi.yaml` (now v0.3.0 — 20 paths, 15 schemas).

Login history is gated by `security.view` rather than `users.manage` on purpose:
administering accounts and reading who tried to sign in to them are different
rights, and the matrix makes that separable.

---

## 4. Flutter routes and screens

| Path | Screen |
|---|---|
| `/admin` | `AdminDashboardScreen` (replaces the Phase 0 placeholder) |
| `/admin/site-settings` | `AdminSiteSettingsScreen` — **closes the Phase 1 gap** |
| `/admin/users`, `/admin/users/new`, `/admin/users/:id` | list, create, edit + login history |
| `/admin/roles`, `/admin/roles/:id` | role list and permission matrix |
| `/reset-password` | public, completes the Phase 0 flow |

New: `core/auth/permissions.dart` (`Permissions`, `PermissionSet`),
`features/admin/` (models, repository, providers, five screens, `StatusChip`),
`ResetPasswordScreen`, `AdminSiteSettingsScreen`.

---

## 5. Safety guards — the part that matters most

A permission system that lets the last administrator lock themselves out is an
outage waiting for a bad afternoon. Four refusals are enforced server-side and
each is proven to block **and** proven not to over-block:

1. The last active Super Admin cannot be demoted.
2. The last active Super Admin cannot be deactivated or blocked.
3. Nobody can change their own role.
4. Nobody can deactivate or block their own account.

Plus: Super Admin's permission set cannot be edited at all, and
`AdminSafetyGuardsTest` proves that stripping every *other* role to zero leaves
Super Admin working. Guard refusals return 422 against the named field, so the
editor sees the actual reason rather than a generic "invalid".

---

## 6. Tests and command results

```
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  94 files, 0 changed
$ flutter test                                       199/199 passed
$ ./vendor/bin/pint --test                           passed
$ php artisan test                                   164 passed (697 assertions)
$ migrate → rollback → migrate → db:seed (MariaDB)   reversible
```

**Backend, 164 tests** (98 from Phases 0–1 + 66 new). New: `PermissionCatalogueTest`
(key shape, defaults encode the spec's role prose — a Treasurer has no security,
a Content Manager no financial keys); `PermissionEnforcementTest` (every endpoint
× refused roles, guest, blocked Super Admin, stale keys ignored);
`UserManagementTest` (filters, creation mails a link and stores no usable
password, deactivation takes effect on the next request, hash never returned);
`AdminSafetyGuardsTest` (the four guards, both directions);
`RoleMatrixTest` (catalogue exposure, grant/revoke changes access immediately,
unknown keys rejected by name, empty set allowed);
`LoginHistoryAndResetTest` (all four outcomes recorded including unknown
addresses, single-use tokens, `/auth/me` permissions).

**Every Phase 1 authorization test passes unchanged** — the check that replacing
the `manage-content` role gate with the matrix was faithful.

**Flutter, 199 tests** (167 + 32 new): dashboard entries per permission; user
list/editor states, no password field, client validation, e-mail normalisation,
server guard refusal shown on the right field, read-only for `users.view`;
matrix grouping, future-phase labelling, toggle+save, Super Admin read-only,
server refusal by name; login history hidden without `security.view`, failures
shown; reset-password validation, broken link, single submission, expired token;
site-settings load, blank-as-absent, unauthorized, server validation.

---

## 7. Two-factor authentication — deferred, not skipped

The specification lists this as **"Optional two-factor authentication for Super
Admin"**. It is the one Phase 2 item not delivered.

A correct implementation needs a TOTP dependency, recovery codes, an enrollment
flow, a challenge step inserted into login, and its own security tests —
comparable in size to the rest of this phase. Everything else in Phase 2 is
complete, so rather than delivering 2FA half-built I have left it out and am
raising it explicitly. It is a focused follow-up whenever you want it, and
nothing in this phase's design blocks it.

---

## 8. Defects found and fixed during the phase

| # | Defect | Fix |
|---|---|---|
| 1 | **The permission matrix was permanently read-only.** `_canEdit` used `ref.read`, so it evaluated before the session resolved and never re-evaluated — the save button never appeared for a user who *was* allowed to edit | Switched to `ref.watch` inside `build`. Found by a widget test, not by review |
| 2 | Tests that switched actor mid-test failed with 401 | Root cause was **correct production behaviour**: Sanctum's stateful pipeline runs `AuthenticateSession`, which stores the signed-in user's password hash in the session and force-logs-out when a later request's user does not match — the mechanism that ends other sessions on a password change. The test helper now flushes the session and drops resolved guards, because a different person signing in is a different browser |
| 3 | A test assumed `Admin` lacks `security.view` | The premise was wrong, not the code. Rewritten to configure a role holding `users.manage` without `security.view`, which tests the separation properly |

---

## 9. Known issues and technical debt

1. **Two-factor authentication is not implemented** (§7).
2. **The temple's own name and village are still app strings**, not CMS — they
   appear in the header, hero, login screen and footer fallback from the ARB
   files. The specification puts `name_hi`/`name_en`/`village` in **Phase 3's
   `temple_profile`**, which is also where the address moves, so both are wired
   in one change rather than creating a second source of truth now.
3. **The navigation menu has no editor screen.** `PUT /api/admin/site-settings`
   replaces it and is validated and tested, but the settings screen covers the
   tagline, footer and address only — a menu editor needs reorderable rows.
4. **Permission keys for Phases 3–10 are grantable but inert.** Deliberate: the
   matrix is designed once and later phases attach endpoints to keys the
   committee already manages. The UI labels them "Available in phase N".
5. **No self-service profile screen.** A member edits their own details through
   the admin user editor, which requires `users.manage`.
6. **Admin chrome flashes before the guard redirects** (carried from Phase 0).
7. **No end-to-end test crosses the two stacks** (carried; Phase 12).
8. **The pre-render tool is not wired into CI** (carried from Phase 1).

---

## 10. Next phase

**Phase 3 — Temple Profile & Committee Management.** Planned but **not started**.
It must **move** the address out of `site_settings` and take over the temple
name, rather than duplicating either.
