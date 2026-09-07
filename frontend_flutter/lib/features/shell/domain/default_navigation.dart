import '../../../app/routing/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../content/domain/localized_value.dart';
import '../../content/domain/site_settings.dart';

/// The menu a visitor gets before the committee has configured one.
///
/// The header menu, the phone drawer and the footer's quick links are all fed
/// from site settings, and site settings start empty. That left a brand-new
/// site with no menu at all — and, because the drawer is only built when there
/// is something to put in it, **no hamburger button on a phone either**. Every
/// section the app already has (events, gallery, committee, accounts, donate,
/// contact) was reachable only by typing its URL.
///
/// These are not temple content, so writing them here breaks no rule: they are
/// the application's own sections, named with strings the app already ships in
/// both languages, pointing at routes that exist in the router. Nothing here
/// asserts anything about this temple.
///
/// The moment the committee saves a menu of their own, theirs replaces this
/// entirely — see [effectiveNavigation].
List<NavigationEntry> defaultNavigation(AppLocalizations l10n) {
  // Negative ids: a configured entry always has a positive one from the
  // database, so nothing here can ever collide with a real row's key.
  var id = 0;
  NavigationEntry entry(String label, String route) => NavigationEntry(
    id: --id,
    label: LocalizedValue(value: label, language: 'hi', fallbackUsed: false),
    route: route,
    sortOrder: -id,
  );

  return [
    entry(l10n.navHome, RoutePaths.home),
    entry(l10n.navEvents, RoutePaths.events),
    entry(l10n.navGallery, RoutePaths.gallery),
    entry(l10n.navCommittee, RoutePaths.committee),
    entry(l10n.navAccounts, RoutePaths.transparency),
    entry(l10n.navDonate, RoutePaths.donate),
    entry(l10n.navContact, RoutePaths.contact),
  ];
}

/// The menu to actually show: the committee's, or the built-in one.
///
/// Deliberately all-or-nothing rather than a merge. A committee that has
/// written three entries meant those three — quietly appending four more would
/// be the app overruling them.
List<NavigationEntry> effectiveNavigation(
  AppLocalizations l10n,
  List<NavigationEntry> configured,
) => configured.isEmpty ? defaultNavigation(l10n) : configured;
