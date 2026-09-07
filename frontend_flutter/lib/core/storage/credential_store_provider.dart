import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'credential_store.dart';

/// The sign-in form's credential store.
///
/// A provider so widget tests can substitute an in-memory one: on the Dart VM
/// the real implementation is a no-op, which would make every assertion about
/// remembering pass without proving anything.
final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => const CredentialStore(),
);
