import '../entities/financial_summary.dart';

abstract interface class FinanceRepository {
  Future<FinancialSummary> getSummary(FinancialPeriod period);
}

class FinanceFailure implements Exception {
  const FinanceFailure();
}
