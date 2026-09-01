import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/network/network_providers.dart';
import '../domain/entities/active_appointment.dart';
import '../data/repositories/remote_schedule_repository.dart';
import '../domain/entities/scheduled_session.dart';
import '../domain/repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return RemoteScheduleRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
    (offline) => ref
        .read(offlineResourcesProvider.notifier)
        .setOffline('schedule', offline: offline),
  );
});

final scheduleProvider =
    FutureProvider.family<List<ScheduledSession>, DateTime>((ref, date) {
      return ref.watch(scheduleRepositoryProvider).listByDate(date);
    });

final activeAppointmentsProvider = FutureProvider<List<ActiveAppointment>>((
  ref,
) {
  return ref.watch(scheduleRepositoryProvider).listActiveAppointments();
});
