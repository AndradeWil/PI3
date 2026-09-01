import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/repositories/remote_finance_repository.dart';
import '../domain/entities/financial_summary.dart';
import '../domain/repositories/finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return RemoteFinanceRepository(ref.watch(apiClientProvider));
});

final financialSummaryProvider =
    FutureProvider.family<FinancialSummary, FinancialPeriod>((ref, period) {
      return ref.watch(financeRepositoryProvider).getSummary(period);
    });
