import '../../../core/api/api_envelope.dart';
import 'localized_value.dart';

/// One entry in the admin-configured public navigation menu.
class NavigationEntry {
  const NavigationEntry({
    required this.id,
    required this.label,
    required this.route,
    required this.sortOrder,
  });

  factory NavigationEntry.fromJson(Map<String, dynamic> json) =>
      NavigationEntry(
        id: _asInt(json['id']) ?? 0,
        label: LocalizedValue.fromJson(json['label']),
        route: json['route'] as String? ?? '/',
        sortOrder: _asInt(json['sort_order']) ?? 0,
      );

  final int id;
  final LocalizedValue label;

  /// An internal path such as `/about`, or an absolute URL.
  final String route;
  final int sortOrder;

  /// External links must not be pushed onto the in-app router.
  bool get isExternal =>
      route.startsWith('http://') || route.startsWith('https://');

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// How to reach the temple committee.
///
/// The postal address is **not** here: Phase 3 moved it to the authoritative
/// temple profile, so `TempleAddress` is the only place it lives. What remains
/// is the contact block the specification assigns to site settings.
class ContactInfo {
  const ContactInfo({this.phone, this.email});

  factory ContactInfo.fromJson(Object? json) {
    final map = ApiEnvelopeParser.asMap(json) ?? const <String, dynamic>{};
    String? read(String key) {
      final value = map[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return ContactInfo(phone: read('phone'), email: read('email'));
  }

  final String? phone;
  final String? email;

  bool get isEmpty => phone == null && email == null;
}

/// Site-wide content the committee configures: tagline, footer, contact block,
/// navigation and default SEO metadata.
class SiteSettings {
  const SiteSettings({
    required this.requestedLanguage,
    required this.tagline,
    required this.footerText,
    required this.contact,
    required this.navigation,
    required this.socialLinks,
    required this.defaultMetaTitle,
    required this.defaultMetaDescription,
  });

  factory SiteSettings.fromJson(Map<String, dynamic> json) {
    final nav = json['navigation'];
    final entries = nav is List
        ? nav
              .map(ApiEnvelopeParser.asMap)
              .whereType<Map<String, dynamic>>()
              .map(NavigationEntry.fromJson)
              .toList()
        : <NavigationEntry>[];
    entries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final links = ApiEnvelopeParser.asMap(json['social_links']);

    return SiteSettings(
      requestedLanguage: json['requested_language'] as String? ?? 'hi',
      tagline: LocalizedValue.fromJson(json['tagline']),
      footerText: LocalizedValue.fromJson(json['footer_text']),
      contact: ContactInfo.fromJson(json['contact']),
      navigation: List.unmodifiable(entries),
      socialLinks: Map.unmodifiable(<String, String>{
        if (links != null)
          for (final entry in links.entries)
            if (entry.value is String && (entry.value as String).isNotEmpty)
              entry.key: entry.value as String,
      }),
      defaultMetaTitle: LocalizedValue.fromJson(json['default_meta_title']),
      defaultMetaDescription: LocalizedValue.fromJson(
        json['default_meta_description'],
      ),
    );
  }

  /// A never-configured site. Used as a safe shell fallback so navigation and
  /// footer failures never take the whole page down.
  static const SiteSettings empty = SiteSettings(
    requestedLanguage: 'hi',
    tagline: LocalizedValue.empty,
    footerText: LocalizedValue.empty,
    contact: ContactInfo(),
    navigation: [],
    socialLinks: {},
    defaultMetaTitle: LocalizedValue.empty,
    defaultMetaDescription: LocalizedValue.empty,
  );

  final String requestedLanguage;
  final LocalizedValue tagline;
  final LocalizedValue footerText;
  final ContactInfo contact;
  final List<NavigationEntry> navigation;
  final Map<String, String> socialLinks;
  final LocalizedValue defaultMetaTitle;
  final LocalizedValue defaultMetaDescription;

  bool get hasNavigation => navigation.isNotEmpty;
}

/// Site settings as the editor sees them: both languages raw, no fallback.
class EditableSiteSettings {
  const EditableSiteSettings({
    this.taglineHi,
    this.taglineEn,
    this.footerHi,
    this.footerEn,
    this.contactPhone,
    this.contactEmail,
  });

  factory EditableSiteSettings.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return EditableSiteSettings(
      taglineHi: read('tagline_hi'),
      taglineEn: read('tagline_en'),
      footerHi: read('footer_text_hi'),
      footerEn: read('footer_text_en'),
      contactPhone: read('contact_phone'),
      contactEmail: read('contact_email'),
    );
  }

  final String? taglineHi;
  final String? taglineEn;
  final String? footerHi;
  final String? footerEn;
  final String? contactPhone;
  final String? contactEmail;
}

/// The settings an editor is submitting.
///
/// Blank fields are sent as null so the server stores "not configured" rather
/// than an empty string — which is what the public empty states key on.
class SiteSettingsDraft {
  const SiteSettingsDraft(this.values);

  final Map<String, String> values;

  Map<String, Object?> toJson() => {
    for (final entry in values.entries)
      entry.key: entry.value.trim().isEmpty ? null : entry.value.trim(),
  };
}
