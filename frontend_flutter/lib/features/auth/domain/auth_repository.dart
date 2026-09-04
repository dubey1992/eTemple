import 'auth_user.dart';

/// Contract the presentation layer depends on.
///
/// Implementations live in `data/` and are the only place that knows about HTTP.
abstract interface class AuthRepository {
  /// Signs in and establishes the server session.
  ///
  /// Throws an `AppException` for invalid credentials, an inactive or blocked
  /// account, throttling, or a transport failure.
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  });

  /// Ends the server session. Never throws for an already-ended session.
  Future<void> signOut();

  /// The currently signed-in user, or `null` when there is no valid session.
  ///
  /// Used to restore a session on page load or refresh.
  Future<AuthUser?> currentUser();

  /// Requests a password reset link.
  ///
  /// Completes normally whether or not the address is registered — the server
  /// deliberately gives the same answer either way.
  Future<void> requestPasswordReset(String email);
}
