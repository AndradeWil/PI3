import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_auth_repository.dart';
import '../data/repositories/remote_profile_repository.dart';
import '../domain/entities/therapist_profile.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final sessionRestoreProvider = FutureProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).restoreSession();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return RemoteProfileRepository(ref.watch(apiClientProvider));
});

final therapistProfileProvider = FutureProvider<TherapistProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);

class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .login(username: username, password: password),
    );
    if (!state.hasError) {
      ref.invalidate(therapistProfileProvider);
    }
    return !state.hasError;
  }
}
