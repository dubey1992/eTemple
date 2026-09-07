import 'package:rkt_web/core/storage/credential_store.dart';
import 'package:rkt_web/core/storage/saved_credentials.dart';

/// In-memory stand-in for the browser credential store.
///
/// Necessary rather than convenient: on the Dart VM the real [CredentialStore]
/// is a deliberate no-op, so every assertion about remembering would pass
/// against it without proving anything at all.
class FakeCredentialStore implements CredentialStore {
  FakeCredentialStore({this.stored});

  SavedCredentials? stored;
  int saves = 0;
  int clears = 0;

  @override
  SavedCredentials? read() => stored;

  @override
  void save(SavedCredentials credentials) {
    stored = credentials;
    saves++;
  }

  @override
  void clear() {
    stored = null;
    clears++;
  }
}
