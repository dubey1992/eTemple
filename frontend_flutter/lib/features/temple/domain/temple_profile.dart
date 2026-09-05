import '../../../core/api/api_envelope.dart';
import '../../content/domain/localized_value.dart';

/// The words in front of each address line, in the visitor's language.
///
/// A plain data holder so the domain stays free of `AppLocalizations`: the
/// screen reads the four strings out of the ARB files and hands them over.
class AddressLabels {
  const AddressLabels({
    required this.village,
    required this.panchayat,
    required this.policeStation,
    required this.district,
  });

  final String village;
  final String panchayat;
  final String policeStation;
  final String district;
}

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
  /// The approved design labels each line — `ग्राम - अमरपुर पंखोरिया`, `थाना -
  /// रसूलपुर एकचारी` — because that is how a village address is written and
  /// read here, and because `Rasulpur Ekchari` on its own line says nothing
  /// about what it is. The labels are passed in by the caller so they follow
  /// the visitor's chosen language instead of being hardcoded in Hindi.
  List<String> lines({required AddressLabels labels}) {
    String? labelled(String label, String? value) =>
        value == null ? null : '$label - $value';

    // The district line carries the state and the pin code with it: the
    // prototype writes `जिला - भागलपुर, बिहार - 813204` as one line, and a
    // reader looking for the pin code expects to find it beside the district.
    final region = [district, state].whereType<String>().join(', ');
    final withPin = [if (region.isNotEmpty) region, ?postalCode].join(' - ');

    return [
          addressLine1,
          addressLine2,
          labelled(labels.village, village),
          labelled(labels.panchayat, panchayat),
          labelled(labels.policeStation, policeStation),
          withPin.isEmpty ? null : '${labels.district} - $withPin',
          country,
        ]
        .whereType<String>()
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  /// The address on one line, for the strip above the header.
  ///
  /// The village, the district, the state and the pin code — what the approved
  /// design puts there, and as much as fits beside the tagline. Deliberately
  /// not the labelled lines: labels help when they are stacked and only cost
  /// room when they are not.
  String? get shortLine {
    final region = [district, state].whereType<String>().join(', ');
    final parts = [?village, if (region.isNotEmpty) region].join(', ');

    if (parts.isEmpty) return postalCode;

    return postalCode == null ? parts : '$parts - $postalCode';
  }

  /// Where "view on map" should go.
  ///
  /// The configured link when the committee has set one. Otherwise a map search
  /// for the temple's own address, which is not invented content — it is the
  /// address above, handed to a map. A temple with no address at all gets no
  /// link, rather than a search for nothing.
  String? mapDestination(String? templeName) {
    if (mapUrl != null) return mapUrl;

    final query = [
      templeName,
      village,
      district,
      state,
      postalCode,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

    if (query.isEmpty) return null;

    return 'https://www.google.com/maps/search/?api=1'
        '&query=${Uri.encodeComponent(query)}';
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
    'address_line1_hi',
    'address_line1_en',
    'address_line2_hi',
    'address_line2_en',
    'village_hi',
    'village_en',
    'panchayat_hi',
    'panchayat_en',
    'police_station_hi',
    'police_station_en',
    'district_hi',
    'district_en',
    'state_hi',
    'state_en',
    // One postal code: 813204 is 813204 in either language.
    'postal_code',
    'country_hi',
    'country_en',
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
