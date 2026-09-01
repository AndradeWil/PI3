import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

abstract interface class TokenStorage {
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<void> save(TokenPair tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this.storage);

  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';

  final FlutterSecureStorage storage;

  @override
  Future<String?> readAccess() => storage.read(key: _accessKey);

  @override
  Future<String?> readRefresh() => storage.read(key: _refreshKey);

  @override
  Future<void> save(TokenPair tokens) async {
    await storage.write(key: _accessKey, value: tokens.access);
    await storage.write(key: _refreshKey, value: tokens.refresh);
  }

  @override
  Future<void> clear() async {
    await storage.delete(key: _accessKey);
    await storage.delete(key: _refreshKey);
  }
}
