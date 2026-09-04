import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../domain/auth_repository.dart';
import 'auth_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this provider with a
/// fake so no widget test needs a network.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(apiClientProvider)),
);
