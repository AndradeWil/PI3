import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_schedule_repository.dart';
import '../domain/entities/scheduled_session.dart';
import '../domain/repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return RemoteScheduleRepository(ref.watch(apiClientProvider));
});

final scheduleProvider =
    FutureProvider.family<List<ScheduledSession>, DateTime>((ref, date) {
      return ref.watch(scheduleRepositoryProvider).listByDate(date);
    });
