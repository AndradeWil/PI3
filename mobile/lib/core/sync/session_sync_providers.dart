import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/schedule/application/schedule_providers.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../cache/cache_providers.dart';
import 'session_outbox.dart';

enum SessionRegistrationResult { registered, queued }

final sessionOutboxProvider = Provider<SessionOutbox>((ref) {
  return SessionOutbox(ref.watch(localCacheProvider));
});

final pendingSessionCountProvider = FutureProvider<int>((ref) async {
  return (await ref.watch(sessionOutboxProvider).readAll()).length;
});

final registerSessionProvider = Provider<RegisterSession>((ref) {
  return RegisterSession(
    ref.watch(scheduleRepositoryProvider),
    ref.watch(sessionOutboxProvider),
    () => ref.invalidate(pendingSessionCountProvider),
  );
});

final sessionSynchronizationProvider = FutureProvider<int>((ref) async {
  final synchronized = await SynchronizeSessions(
    ref.watch(scheduleRepositoryProvider),
    ref.watch(sessionOutboxProvider),
  )();
  ref.invalidate(pendingSessionCountProvider);
  return synchronized;
});

class RegisterSession {
  const RegisterSession(this.repository, this.outbox, this.onChanged);

  final ScheduleRepository repository;
  final SessionOutbox outbox;
  final void Function() onChanged;

  Future<SessionRegistrationResult> call({
    required int appointmentId,
    required String idempotencyKey,
  }) async {
    try {
      await repository.quickClockIn(appointmentId, idempotencyKey);
      return SessionRegistrationResult.registered;
    } on ScheduleFailure catch (error) {
      if (!error.retryable) rethrow;
      await outbox.enqueue(
        PendingSessionRegistration(
          appointmentId: appointmentId,
          idempotencyKey: idempotencyKey,
          createdAt: DateTime.now(),
        ),
      );
      onChanged();
      return SessionRegistrationResult.queued;
    }
  }
}

class SynchronizeSessions {
  const SynchronizeSessions(this.repository, this.outbox);

  final ScheduleRepository repository;
  final SessionOutbox outbox;

  Future<int> call() async {
    var synchronized = 0;
    for (final pending in await outbox.readAll()) {
      try {
        await repository.quickClockIn(
          pending.appointmentId,
          pending.idempotencyKey,
        );
        await outbox.remove(pending.idempotencyKey);
        synchronized++;
      } on ScheduleFailure {
        break;
      }
    }
    return synchronized;
  }
}
