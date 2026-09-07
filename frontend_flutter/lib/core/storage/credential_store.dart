/// Where "remember me" keeps the sign-in details between visits.
///
/// **This is the one place in the application permitted to write to browser
/// storage, and it holds a password in plain text.** Everything else keeps its
/// state in memory for the life of the tab; the session itself is an HttpOnly
/// cookie that script cannot read. `test/core/browser_storage_test.dart`
/// enforces that, and names this file as the single exception.
///
/// The committee asked for it, knowing the cost, on 2026-09-07: after signing
/// out they want both fields filled in on the next visit. What that means in
/// practice, and what nobody should have to rediscover later:
///
///  * `localStorage` is plain text. Any script running on the site's own origin
///    can read it, so a single cross-site-scripting hole anywhere on the
///    domain hands over a Super Admin password rather than a session that
///    logging out would have ended.
///  * It is per-browser, not per-person. On a shared computer — a temple office
///    machine — the next person to open the site is one click from being signed
///    in as whoever ticked the box.
///  * Signing out does **not** clear it. That is the whole point of the
///    request, and it is also the sharpest edge: "sign out" no longer removes
///    the credentials from the machine. Unticking the box does clear them.
///
/// A browser's own password manager does this job with the credentials
/// encrypted at rest and gated on the device login. If it ever becomes
/// available on this form, prefer it and delete this.
library;

export 'credential_store_io.dart'
    if (dart.library.js_interop) 'credential_store_web.dart';
