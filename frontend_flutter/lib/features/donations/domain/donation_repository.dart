import 'donation.dart';

/// What the register is being asked for.
class DonationQuery {
  const DonationQuery({
    this.status,
    this.mode,
    this.purpose,
    this.from,
    this.to,
    this.search,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? mode;
  final String? purpose;

  /// `YYYY-MM-DD`, inclusive at both ends.
  final String? from;
  final String? to;

  /// Matches a donor name, a receipt number or a payment reference.
  final String? search;

  final int page;
  final int perPage;

  DonationQuery atPage(int page) => DonationQuery(
    status: status,
    mode: mode,
    purpose: purpose,
    from: from,
    to: to,
    search: search,
    page: page,
    perPage: perPage,
  );

  Map<String, Object?> toQueryParameters() => {
    'status': ?status,
    'mode': ?mode,
    'purpose': ?purpose,
    'from': ?from,
    'to': ?to,
    'q': ?search,
    'page': page,
    'per_page': perPage,
  };

  // Value equality because this is a provider family key: without it every
  // rebuild would ask for a new provider and refetch the same page.
  @override
  bool operator ==(Object other) =>
      other is DonationQuery &&
      other.status == status &&
      other.mode == mode &&
      other.purpose == purpose &&
      other.from == from &&
      other.to == to &&
      other.search == search &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode =>
      Object.hash(status, mode, purpose, from, to, search, page, perPage);
}

/// Contract for the donation register and the published donation details.
///
/// Implementations live in `data/` and are the only place that knows about
/// HTTP.
///
/// There is deliberately **no `delete`**. Nothing is ever deleted; [reverse] —
/// which keeps the row, its receipt number and a stated reason — is the only
/// undo, and the absence of a delete method here is the client half of that
/// rule.
abstract interface class DonationRepository {
  /// Where devotees may send money. Null when the committee has not published
  /// anything yet, which is an empty state rather than an error.
  Future<DonationDetails?> publicDetails({required String language});

  /// One page of the register, with the totals for the whole filter.
  /// Requires `donations.view`.
  Future<DonationPage> donations(DonationQuery query);

  /// One donation, with who recorded, confirmed and reversed it.
  Future<Donation> donation(int id);

  /// Records a donation as pending. Requires `donations.manage`.
  Future<Donation> record(DonationDraft draft);

  /// Corrects a donation. The server refuses everything but the notes once a
  /// receipt has been issued.
  Future<Donation> save(int id, DonationDraft draft);

  /// Verifies a donation, which is the moment its receipt number comes into
  /// existence.
  Future<Donation> confirm(int id);

  /// The only undo. [reason] is required and is what explains, months later,
  /// why an amount still in the books no longer counts.
  Future<Donation> reverse(int id, String reason);

  /// The absolute URL of the printable receipt, for opening in a new tab.
  String receiptUrl(int id);

  Future<AdminDonationSettings> settings();

  Future<AdminDonationSettings> saveSettings(DonationSettingsDraft draft);
}
