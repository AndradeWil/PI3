import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_registry_repository.dart';
import '../domain/entities/registry_entities.dart';
import '../domain/repositories/registry_repository.dart';

final registryRepositoryProvider = Provider<RegistryRepository>((ref) {
  return RemoteRegistryRepository(ref.watch(apiClientProvider));
});

final companiesProvider = FutureProvider<List<Company>>((ref) {
  return ref.watch(registryRepositoryProvider).listCompanies();
});

final serviceTypesProvider = FutureProvider<List<ServiceType>>((ref) {
  return ref.watch(registryRepositoryProvider).listServiceTypes();
});
