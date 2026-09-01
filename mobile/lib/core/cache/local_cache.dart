import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

abstract interface class LocalCache {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> deleteByPrefix(String prefix);
  Future<void> clear();
}

class EncryptedLocalCache implements LocalCache {
  EncryptedLocalCache(this.secureStorage);

  static const _boxName = 'encrypted_api_cache';
  static const _keyName = 'cache_encryption_key';
  static Future<void>? _hiveInitialization;

  final FlutterSecureStorage secureStorage;
  Future<Box<String>>? _box;

  Future<Box<String>> get box => _box ??= _openBox();

  Future<Box<String>> _openBox() async {
    _hiveInitialization ??= Hive.initFlutter();
    await _hiveInitialization;
    var encodedKey = await secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      final random = Random.secure();
      encodedKey = base64UrlEncode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      await secureStorage.write(key: _keyName, value: encodedKey);
    }
    return Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(base64Url.decode(encodedKey)),
    );
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final value = (await box).get(key);
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    await (await box).put(key, jsonEncode(value));
  }

  @override
  Future<void> deleteByPrefix(String prefix) async {
    final openedBox = await box;
    final keys = openedBox.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    await openedBox.deleteAll(keys);
  }

  @override
  Future<void> clear() async {
    await (await box).clear();
  }
}
