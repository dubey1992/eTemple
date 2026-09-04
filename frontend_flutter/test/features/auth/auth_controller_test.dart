import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/domain/auth_user.dart';
import 'package:rkt_web/features/auth/presentation/auth_controller.dart';

import '../../support/fake_auth_repository.dart';

ProviderContainer containerWith(FakeAuthRepository repository) {
  return ProviderContainer.test(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
}

void main() {
  test('starts loading and resolves to signed out with no session', () async {
    final container = containerWith(FakeAuthRepository());

    expect(container.read(authControllerProvider).isLoading, isTrue);
    expect(container.read(isAuthenticatedProvider), isFalse);

    await container.read(authControllerProvider.future);

    expect(container.read(authControllerProvider).value, isNull);
    expect(container.read(isAuthenticatedProvider), isFalse);
  });

  test('restores an existing session on start-up', () async {
    final container = containerWith(FakeAuthRepository(session: testUser()));

    final user = await container.read(authControllerProvider.future);

    expect(user?.email, 'committee@thakurbari.in');
    expect(container.read(isAuthenticatedProvider), isTrue);
  });

  test(
    'an inactive restored account is not treated as authenticated',
    () async {
      final container = containerWith(
        FakeAuthRepository(session: testUser(status: AccountStatus.inactive)),
      );

      await container.read(authControllerProvider.future);

      expect(container.read(isAuthenticatedProvider), isFalse);
    },
  );

  test(
    'signIn publishes the user and passes the credentials through',
    () async {
      final repository = FakeAuthRepository();
      final container = containerWith(repository);
      await container.read(authControllerProvider.future);

      final user = await container
          .read(authControllerProvider.notifier)
          .signIn(
            email: 'committee@thakurbari.in',
            password: 'a-valid-password',
            remember: true,
          );

      expect(user.email, 'committee@thakurbari.in');
      expect(repository.signInCalls, 1);
      expect(repository.lastRemember, isTrue);
      expect(container.read(isAuthenticatedProvider), isTrue);
    },
  );

  test('a failed signIn rethrows and leaves the session untouched', () async {
    final repository = FakeAuthRepository(
      signInError: const AppException(code: ErrorCode.invalidCredentials),
    );
    final container = containerWith(repository);
    await container.read(authControllerProvider.future);

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .signIn(email: 'committee@thakurbari.in', password: 'wrong-password'),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          ErrorCode.invalidCredentials,
        ),
      ),
    );

    expect(container.read(authControllerProvider).value, isNull);
    expect(container.read(isAuthenticatedProvider), isFalse);
  });

  test('signOut clears the session', () async {
    final repository = FakeAuthRepository(session: testUser());
    final container = containerWith(repository);
    await container.read(authControllerProvider.future);
    expect(container.read(isAuthenticatedProvider), isTrue);

    await container.read(authControllerProvider.notifier).signOut();

    expect(repository.signOutCalls, 1);
    expect(container.read(authControllerProvider).value, isNull);
    expect(container.read(isAuthenticatedProvider), isFalse);
  });

  test('a failed refresh records the error but keeps the session', () async {
    final repository = FakeAuthRepository(session: testUser());
    final container = containerWith(repository);
    await container.read(authControllerProvider.future);

    repository.currentUserError = const AppException(code: ErrorCode.network);
    await container.read(authControllerProvider.notifier).refresh();

    expect(container.read(authControllerProvider).hasError, isTrue);
    // A transient network failure must not sign a committee member out; the
    // previously restored session is retained until the server actually says
    // the session is gone.
    expect(container.read(isAuthenticatedProvider), isTrue);
  });

  test('refresh picks up a session that ended server-side', () async {
    final repository = FakeAuthRepository(session: testUser());
    final container = containerWith(repository);
    await container.read(authControllerProvider.future);

    repository.session = null;
    await container.read(authControllerProvider.notifier).refresh();

    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(isAuthenticatedProvider), isFalse);
  });
}
