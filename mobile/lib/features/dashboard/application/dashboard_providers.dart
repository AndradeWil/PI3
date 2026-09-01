import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_dashboard_repository.dart';
import '../domain/entities/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => RemoteDashboardRepository(ref.watch(apiClientProvider)),
);

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchSummary();
});
