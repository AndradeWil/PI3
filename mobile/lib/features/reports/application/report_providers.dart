import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_report_repository.dart';
import '../domain/entities/session_report.dart';
import '../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return RemoteReportRepository(ref.watch(apiClientProvider));
});

final sessionReportProvider =
    FutureProvider.family<SessionReport, ReportPeriod>((ref, period) {
      return ref.watch(reportRepositoryProvider).getSessions(period);
    });
