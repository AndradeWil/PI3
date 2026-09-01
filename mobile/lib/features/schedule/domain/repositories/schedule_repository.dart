import '../entities/scheduled_session.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduledSession>> listByDate(DateTime date);
}

class ScheduleFailure implements Exception {
  const ScheduleFailure();
}
