import '../../../core/api/api_envelope.dart';
import '../../content/domain/localized_value.dart';

/// The temple's postal address.
///
/// Authoritative since Phase 3. Phase 1 served these fields from site settings
/// as a stopgap; they moved here so there is exactly one source of truth for
/// where the temple is.
class TempleAddress {
  const TempleAddress({
    this.addressLine1,
    this.addressLine2,
    this.village,
    this.panchayat,
    this.policeStation,
    this.district,
    this.state,
    this.postalCode,
    this.country,
    this.mapUrl,
  });

  factory TempleAddress.fromJson(Object? json) {
    final map = ApiEnvelopeParser.asMap(json) ?? const <String, dynamic>{};
    String? read(String key) {
      final value = map[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return TempleAddress(
      addressLine1: read('address_line1'),
      addressLine2: read('address_line2'),
      village: read('village'),
      panchayat: read('panchayat'),
      policeStation: read('police_station'),
      district: read('district'),
      state: read('state'),
      postalCode: read('postal_code'),
      country: read('country'),
      mapUrl: read('map_url'),
    );
  }

  static const TempleAddress empty = TempleAddress();

  final String? addressLine1;
  final String? addressLine2;
  final String? village;
  final String? panchayat;
  final String? policeStation;
  final String? district;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? mapUrl;

  /// The address as display lines, skipping anything not filled in.
  ///
  /// Built here rather than in a widget so the ordering is testable and the
  /// same everywhere the address appears.
  ///
  /// [panchayatLabel] is passed in by the caller so the label follows the
  /// visitor's chosen language instead of being hardcoded in Hindi.
  List<String> lines({required String panchayatLabel}) {
    final locality = [
      village,
      if (panchayat != null) '$panchayatLabel: $panchayat',
    ].whereType<String>().join(', ');

    final region = [
      policeStation,
      district,
      state,
      postalCode,
    ].whereType<String>().join(', ');

    return [
          addressLine1,
          addressLine2,
          locality.isEmpty ? null : locality,
          region.isEmpty ? null : region,
          country,
        ]
        .whereType<String>()
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  bool get isEmpty =>
      addressLine1 == null &&
      addressLine2 == null &&
      village == null &&
      panchayat == null &&
      policeStation == null &&
      district == null &&
      state == null &&
      postalCode == null &&
      country == null;

  /// The locality line on its own, for the site header beneath the name.
  String? get locality {
    final parts = [village, panchayat].whereType<String>();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// The temple's public identity, resolved for the current language.
///
/// [name] is authoritative for the site header, the hero, the footer and page
/// titles. The application shell string is used only while this is loading, so
/// the temple's own name is CMS-managed rather than compiled in.
class TempleProfile {
  const TempleProfile({
    required this.requestedLanguage,
    required this.name,
    required this.history,
    required this.mission,
    required this.address,
    this.logoUrl,
    this.establishedYear,
  });

  factory TempleProfile.fromJson(Map<String, dynamic> json) {
    final logo = json['logo_url'];
    final year = json['established_year'];

    return TempleProfile(
      requestedLanguage: json['requested_language'] as String? ?? 'hi',
      name: LocalizedValue.fromJson(json['name']),
      history: LocalizedValue.fromJson(json['history']),
      mission: LocalizedValue.fromJson(json['mission']),
      address: TempleAddress.fromJson(json['address']),
      logoUrl: logo is String && logo.trim().isNotEmpty ? logo : null,
      establishedYear: year is int ? year : (year is num ? year.toInt() : null),
    );
  }

  /// A never-configured temple. Used as a safe fallback so a profile outage
  /// degrades the header rather than blanking the page.
  static const TempleProfile empty = TempleProfile(
    requestedLanguage: 'hi',
    name: LocalizedValue.empty,
    history: LocalizedValue.empty,
    mission: LocalizedValue.empty,
    address: TempleAddress.empty,
  );

  final String requestedLanguage;
  final LocalizedValue name;
  final LocalizedValue history;
  final LocalizedValue mission;
  final TempleAddress address;
  final String? logoUrl;
  final int? establishedYear;

  bool get hasName => name.isNotEmpty;
}

/// The temple profile as the editor sees it: both languages raw, no fallback.
class EditableTempleProfile {
  const EditableTempleProfile({this.values = const {}});

  factory EditableTempleProfile.fromJson(Map<String, dynamic> json) {
    return EditableTempleProfile(
      values: {
        for (final field in fields)
          field: switch (json[field]) {
            final String v when v.trim().isNotEmpty => v,
            final int v => '$v',
            _ => '',
          },
      },
    );
  }

  /// Every editable field, in the order the form renders them.
  static const List<String> fields = [
    'name_hi',
    'name_en',
    'history_hi',
    'history_en',
    'mission_hi',
    'mission_en',
    'address_line1',
    'address_line2',
    'village',
    'panchayat',
    'police_station',
    'district',
    'state',
    'postal_code',
    'country',
    'logo_url',
    'map_url',
    'established_year',
  ];

  final Map<String, String> values;

  String operator [](String field) => values[field] ?? '';
}

/// The profile an editor is submitting.
///
/// Blank fields are sent as null so the server stores "not configured" rather
/// than an empty string — which is what the public empty states key on.
class TempleProfileDraft {
  const TempleProfileDraft(this.values);

  final Map<String, String> values;

  Map<String, Object?> toJson() => {
    for (final entry in values.entries)
      entry.key: entry.value.trim().isEmpty
          ? null
          : (entry.key == 'established_year'
                ? int.tryParse(entry.value.trim())
                : entry.value.trim()),
  };
}
