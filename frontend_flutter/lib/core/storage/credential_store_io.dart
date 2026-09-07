import 'saved_credentials.dart';

/// Non-web implementation: remembers nothing.
///
/// `flutter test` runs on the Dart VM, where there is no browser storage. Doing
/// nothing here keeps the login screen testable without pretending a store
/// exists, and means a future mobile build cannot accidentally start writing
/// passwords to disk.
class CredentialStore {
  const CredentialStore();

  SavedCredentials? read() => null;

  void save(SavedCredentials credentials) {}

  void clear() {}
}
