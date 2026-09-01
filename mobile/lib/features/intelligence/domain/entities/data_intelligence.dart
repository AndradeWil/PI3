class DataIntelligence {
  const DataIntelligence({
    required this.updatedAt,
    required this.monthRevenue,
    required this.monthSessions,
    required this.activePatients,
    required this.absenceRate,
    required this.monthlySeries,
    required this.forecast,
    required this.travelCosts,
    required this.denials,
    required this.churn,
  });

  final DateTime updatedAt;
  final double monthRevenue;
  final int monthSessions;
  final int activePatients;
  final double absenceRate;
  final List<MonthlyDataPoint> monthlySeries;
  final FinancialForecast forecast;
  final DataAvailability travelCosts;
  final DataAvailability denials;
  final DataAvailability churn;
}

class MonthlyDataPoint {
  const MonthlyDataPoint({
    required this.month,
    required this.revenue,
    required this.sessions,
    required this.absences,
  });

  final DateTime month;
  final double revenue;
  final int sessions;
  final int absences;
}

class FinancialForecast {
  const FinancialForecast({
    required this.available,
    required this.reason,
    required this.expectedRevenue,
    required this.trendPercentage,
    required this.method,
  });

  final bool available;
  final String reason;
  final double? expectedRevenue;
  final double? trendPercentage;
  final String? method;
}

class DataAvailability {
  const DataAvailability({required this.available, required this.reason});

  final bool available;
  final String reason;
}
