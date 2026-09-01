abstract interface class AuthRepository {
  Future<bool> restoreSession();
  Future<void> login({required String username, required String password});
  Future<void> logout();
}

class AuthenticationFailure implements Exception {
  const AuthenticationFailure(this.message);

  final String message;
}
