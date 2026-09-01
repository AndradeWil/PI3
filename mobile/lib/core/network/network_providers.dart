import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../security/token_storage.dart';
import 'api_client.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const SecureTokenStorage(FlutterSecureStorage()),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStorageProvider)),
);
