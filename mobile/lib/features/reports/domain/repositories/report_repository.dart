import '../entities/session_report.dart';

abstract interface class ReportRepository {
  Future<SessionReport> getSessions(ReportPeriod period);
  Future<String> downloadPdf(ReportPeriod period);
}

class ReportFailure implements Exception {
  const ReportFailure();
}
