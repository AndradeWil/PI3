import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_patient_repository.dart';
import '../domain/entities/patient.dart';
import '../domain/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return RemotePatientRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
    (offline) => ref
        .read(offlineResourcesProvider.notifier)
        .setOffline('patients', offline: offline),
  );
});

final patientsProvider = FutureProvider.family<List<Patient>, String>((
  ref,
  search,
) {
  return ref.watch(patientRepositoryProvider).list(search: search);
});

final patientDetailProvider = FutureProvider.family<Patient, int>((ref, id) {
  return ref.watch(patientRepositoryProvider).getById(id);
});

final savePatientProvider = Provider<SavePatient>((ref) {
  return SavePatient(ref.watch(patientRepositoryProvider));
});

class SavePatient {
  const SavePatient(this.repository);

  final PatientRepository repository;

  Future<Patient> call(PatientInput input, {int? id}) {
    return repository.save(input, id: id);
  }
}
