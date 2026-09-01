import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/core/cache/local_cache.dart';
import 'package:physiomanage_mobile/core/sync/session_outbox.dart';
import 'package:physiomanage_mobile/core/sync/session_sync_providers.dart';
import 'package:physiomanage_mobile/features/schedule/domain/entities/active_appointment.dart';
import 'package:physiomanage_mobile/features/schedule/domain/entities/scheduled_session.dart';
import 'package:physiomanage_mobile/features/schedule/domain/repositories/schedule_repository.dart';

void main() {
  test('queues a failed registration once with its idempotency key', () async {
    final outbox = SessionOutbox(_MemoryCache());
    final repository = _ScheduleRepository(online: false);
    final register = RegisterSession(repository, outbox, () {});

    final first = await register(appointmentId: 7, idempotencyKey: 'same-uuid');
    await register(appointmentId: 7, idempotencyKey: 'same-uuid');

    expect(first, SessionRegistrationResult.queued);
    expect(await outbox.readAll(), hasLength(1));
    expect((await outbox.readAll()).single.idempotencyKey, 'same-uuid');
  });

  test('synchronizes queued registration with the original key', () async {
    final outbox = SessionOutbox(_MemoryCache());
    await outbox.enqueue(
      PendingSessionRegistration(
        appointmentId: 7,
        idempotencyKey: 'original-uuid',
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    final repository = _ScheduleRepository(online: true);

    final count = await SynchronizeSessions(repository, outbox)();

    expect(count, 1);
    expect(repository.lastIdempotencyKey, 'original-uuid');
    expect(await outbox.readAll(), isEmpty);
  });

  test('does not queue a permanent server rejection', () async {
    final outbox = SessionOutbox(_MemoryCache());
    final register = RegisterSession(
      _ScheduleRepository(online: false, retryable: false),
      outbox,
      () {},
    );

    await expectLater(
      register(appointmentId: 7, idempotencyKey: 'invalid-request'),
      throwsA(isA<ScheduleFailure>()),
    );
    expect(await outbox.readAll(), isEmpty);
  });
}

class _ScheduleRepository implements ScheduleRepository {
  _ScheduleRepository({required this.online, this.retryable = true});

  final bool online;
  final bool retryable;
  String? lastIdempotencyKey;

  @override
  Future<ScheduledSession> quickClockIn(
    int appointmentId,
    String idempotencyKey,
  ) async {
    if (!online) throw ScheduleFailure(retryable: retryable);
    lastIdempotencyKey = idempotencyKey;
    return ScheduledSession(
      id: 1,
      appointmentId: appointmentId,
      patientId: 2,
      patientName: 'Maria',
      address: '',
      serviceType: 'Motora',
      dateTime: DateTime(2026, 9, 1),
      durationMinutes: 60,
      value: 'R\$ 120,00',
      attended: true,
      notes: '',
    );
  }

  @override
  Future<void> deleteSession(int sessionId) async {}

  @override
  Future<List<ActiveAppointment>> listActiveAppointments() async => const [];

  @override
  Future<List<ScheduledSession>> listByDate(DateTime date) async => const [];

  @override
  Future<void> markAttended(int sessionId) async {}
}

class _MemoryCache implements LocalCache {
  final values = <String, Map<String, dynamic>>{};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> deleteByPrefix(String prefix) async {
    values.removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    values[key] = value;
  }
}
