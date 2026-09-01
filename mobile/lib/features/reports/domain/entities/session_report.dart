class ReportPeriod {
  const ReportPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    return other is ReportPeriod &&
        _day(other.start) == _day(start) &&
        _day(other.end) == _day(end);
  }

  @override
  int get hashCode => Object.hash(_day(start), _day(end));

  static int _day(DateTime value) =>
      value.year * 10000 + value.month * 100 + value.day;
}

class SessionReport {
  const SessionReport({required this.summary, required this.sessions});

  final ReportSummary summary;
  final List<ReportSession> sessions;
}

class ReportSummary {
  const ReportSummary({
    required this.period,
    required this.sessionCount,
    required this.totalValue,
    required this.totalHours,
  });

  final ReportPeriod period;
  final int sessionCount;
  final double totalValue;
  final double totalHours;
}

class ReportSession {
  const ReportSession({
    required this.id,
    required this.patientName,
    required this.serviceType,
    required this.dateTime,
    required this.durationMinutes,
    required this.value,
    required this.attended,
  });

  final int id;
  final String patientName;
  final String serviceType;
  final DateTime dateTime;
  final int durationMinutes;
  final double value;
  final bool attended;
}
