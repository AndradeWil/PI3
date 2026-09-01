import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_intelligence_repository.dart';
import '../domain/entities/data_intelligence.dart';
import '../domain/repositories/intelligence_repository.dart';

final intelligenceRepositoryProvider = Provider<IntelligenceRepository>((ref) {
  return RemoteIntelligenceRepository(ref.watch(apiClientProvider));
});

final dataIntelligenceProvider = FutureProvider<DataIntelligence>((ref) {
  return ref.watch(intelligenceRepositoryProvider).getSummary();
});
