import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/committee_member.dart';
import '../domain/temple_profile.dart';
import '../domain/temple_repository.dart';
import 'temple_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final templeRepositoryProvider = Provider<TempleRepository>(
  (ref) => TempleRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The temple's public identity for the current language.
///
/// Feeds the site header, the hero, the footer and page titles, so this is the
/// provider that makes the temple's own name CMS-managed rather than compiled
/// into the app.
final templeProfileProvider = FutureProvider<TempleProfile>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(templeRepositoryProvider).profile(language: language);
});

/// The temple's name for chrome that must render before the profile resolves.
///
/// Returns null while loading or on failure; callers fall back to the
/// application shell string, so a slow API degrades the header instead of
/// blanking it.
final templeNameProvider = Provider<String?>((ref) {
  return ref.watch(templeProfileProvider).value?.name.value;
});

/// The temple's locality line ("village, panchayat") for the header subtitle.
///
/// No fallback string: a village name is temple content, so when the profile is
/// unconfigured the line simply does not appear.
final templeLocalityProvider = Provider<String?>((ref) {
  return ref.watch(templeProfileProvider).value?.address.locality;
});

/// Published, currently-serving committee members for the public page.
final committeeProvider = FutureProvider<List<CommitteeMember>>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(templeRepositoryProvider).committee(language: language);
});

/// The profile loaded raw for the editor.
final adminTempleProfileProvider = FutureProvider<EditableTempleProfile>(
  (ref) => ref.watch(templeRepositoryProvider).adminProfile(),
);

/// Every committee member, including unpublished and past ones. Admin-only;
/// the server enforces that.
final adminCommitteeProvider = FutureProvider<List<AdminCommitteeMember>>(
  (ref) => ref.watch(templeRepositoryProvider).adminCommittee(),
);

/// One member loaded raw for editing.
final adminCommitteeMemberProvider =
    FutureProvider.family<AdminCommitteeMember, int>(
      (ref, id) => ref.watch(templeRepositoryProvider).adminMember(id),
    );
