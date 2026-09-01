import '../entities/active_appointment.dart';
import '../entities/scheduled_session.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduledSession>> listByDate(DateTime date);
  Future<List<ActiveAppointment>> listActiveAppointments();
  Future<ScheduledSession> quickClockIn(
    int appointmentId,
    String idempotencyKey,
  );
}

class ScheduleFailure implements Exception {
  const ScheduleFailure();
}
