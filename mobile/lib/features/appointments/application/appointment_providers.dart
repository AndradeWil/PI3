import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_appointment_repository.dart';
import '../domain/entities/appointment.dart';
import '../domain/repositories/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return RemoteAppointmentRepository(ref.watch(apiClientProvider));
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).list();
});

final appointmentDetailProvider = FutureProvider.family<Appointment, int>((
  ref,
  id,
) {
  return ref.watch(appointmentRepositoryProvider).getById(id);
});

final appointmentOptionsProvider = FutureProvider<AppointmentOptions>((ref) {
  return ref.watch(appointmentRepositoryProvider).getOptions();
});

final saveAppointmentProvider = Provider<SaveAppointment>((ref) {
  return SaveAppointment(ref.watch(appointmentRepositoryProvider));
});

class SaveAppointment {
  const SaveAppointment(this.repository);

  final AppointmentRepository repository;

  Future<Appointment> call(AppointmentInput input, {int? id}) {
    return repository.save(input, id: id);
  }
}
