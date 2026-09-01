class DashboardSummary {
  const DashboardSummary({
    required this.monthlyRevenue,
    required this.activePatients,
    required this.todaySessions,
    required this.alerts,
    required this.nextSession,
    required this.todayAgenda,
  });

  final String monthlyRevenue;
  final int activePatients;
  final int todaySessions;
  final int alerts;
  final ScheduledSession? nextSession;
  final List<ScheduledSession> todayAgenda;
}

class ScheduledSession {
  const ScheduledSession({
    required this.id,
    required this.time,
    required this.patientName,
    required this.location,
    required this.status,
  });

  final int id;
  final String time;
  final String patientName;
  final String location;
  final SessionStatus status;
}

enum SessionStatus { next, confirmed, pending }
