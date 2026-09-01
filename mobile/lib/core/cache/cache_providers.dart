import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';
import 'local_cache.dart';

final localCacheProvider = Provider<LocalCache>((ref) {
  return EncryptedLocalCache(ref.watch(secureStorageProvider));
});

final offlineResourcesProvider =
    NotifierProvider<OfflineResources, Set<String>>(OfflineResources.new);

class OfflineResources extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void setOffline(String resource, {required bool offline}) {
    if (offline) {
      state = {...state, resource};
    } else {
      state = state.where((item) => item != resource).toSet();
    }
  }
}
