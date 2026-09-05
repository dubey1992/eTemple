import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/donation.dart';
import '../domain/donation_repository.dart';
import 'donation_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final donationRepositoryProvider = Provider<DonationRepository>(
  (ref) => DonationRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(appConfigProvider),
  ),
);

/// Where devotees may send money, in the visitor's language.
///
/// Null is a value, not a failure: it is what a site whose committee has not
/// published bank details answers, and the page shows an empty state for it.
final donationDetailsProvider = FutureProvider<DonationDetails?>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref
      .watch(donationRepositoryProvider)
      .publicDetails(language: language);
});

/// One page of the register, with the totals for the whole filter.
final donationsProvider = FutureProvider.family<DonationPage, DonationQuery>(
  (ref, query) => ref.watch(donationRepositoryProvider).donations(query),
);

/// One donation, with who recorded, confirmed and reversed it.
final donationProvider = FutureProvider.family<Donation, int>(
  (ref, id) => ref.watch(donationRepositoryProvider).donation(id),
);

/// The published donation details as the editor sees them.
final donationSettingsProvider = FutureProvider<AdminDonationSettings>(
  (ref) => ref.watch(donationRepositoryProvider).settings(),
);

/// The register's filters, held in a provider rather than in the screen so the
/// treasurer's choice survives a rebuild — switching language must not throw
/// them back to page one of everything.
class DonationRegisterView {
  const DonationRegisterView({
    this.status,
    this.mode,
    this.purpose,
    this.search,
    this.page = 1,
  });

  final String? status;
  final String? mode;
  final String? purpose;
  final String? search;
  final int page;

  /// Every filter change resets to the first page: page four of a filter that
  /// now matches two rows is an empty screen with no explanation.
  DonationRegisterView withStatus(String? status) => DonationRegisterView(
    status: status,
    mode: mode,
    purpose: purpose,
    search: search,
  );

  DonationRegisterView withMode(String? mode) => DonationRegisterView(
    status: status,
    mode: mode,
    purpose: purpose,
    search: search,
  );

  DonationRegisterView withSearch(String? search) => DonationRegisterView(
    status: status,
    mode: mode,
    purpose: purpose,
    search: (search == null || search.trim().isEmpty) ? null : search.trim(),
  );

  DonationRegisterView atPage(int page) => DonationRegisterView(
    status: status,
    mode: mode,
    purpose: purpose,
    search: search,
    page: page,
  );

  DonationQuery get query => DonationQuery(
    status: status,
    mode: mode,
    purpose: purpose,
    search: search,
    page: page,
  );

  @override
  bool operator ==(Object other) =>
      other is DonationRegisterView &&
      other.status == status &&
      other.mode == mode &&
      other.purpose == purpose &&
      other.search == search &&
      other.page == page;

  @override
  int get hashCode => Object.hash(status, mode, purpose, search, page);
}

class DonationRegisterController extends Notifier<DonationRegisterView> {
  @override
  DonationRegisterView build() => const DonationRegisterView();

  void selectStatus(String? status) => state = state.withStatus(status);

  void selectMode(String? mode) => state = state.withMode(mode);

  void search(String? term) => state = state.withSearch(term);

  void goToPage(int page) => state = state.atPage(page);
}

final donationRegisterProvider =
    NotifierProvider<DonationRegisterController, DonationRegisterView>(
      DonationRegisterController.new,
    );
