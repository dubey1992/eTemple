import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../domain/auth_user.dart';

/// Owns the session for the whole application.
///
/// `null` data means "signed out"; the loading state means the session is still
/// being restored, which the router treats as "not yet decided" so a refresh on
/// a protected URL does not bounce the user to the sign-in screen.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    // Restores an existing HttpOnly-cookie session on first load or page refresh.
    return ref.watch(authRepositoryProvider).currentUser();
  }

  /// Signs in. Throws `AppException` on failure; the caller renders the message.
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password, remember: remember);

    state = AsyncData(user);
    return user;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  /// Re-reads the session from the server, e.g. after a 401 elsewhere.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).currentUser(),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

/// True only for a signed-in, active account.
///
/// A convenience for the UI. It is never the access control: the server checks
/// authentication and account status on every protected request.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return user != null && user.isActive;
});
