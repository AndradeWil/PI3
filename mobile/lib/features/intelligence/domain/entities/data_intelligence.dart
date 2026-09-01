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
  final TravelCostAnalysis travelCosts;
  final DenialAnalysis denials;
  final ChurnAnalysis churn;
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

class TravelCostAnalysis {
  const TravelCostAnalysis({
    required this.available,
    required this.reason,
    required this.records,
    required this.totalDistance,
    required this.totalCost,
    required this.averageCost,
  });

  final bool available;
  final String reason;
  final int records;
  final double totalDistance;
  final double totalCost;
  final double averageCost;
}

class DenialAnalysis {
  const DenialAnalysis({
    required this.available,
    required this.reason,
    required this.count,
    required this.pending,
    required this.totalValue,
    required this.rate,
    required this.mainOperator,
  });

  final bool available;
  final String reason;
  final int count;
  final int pending;
  final double totalValue;
  final double rate;
  final String mainOperator;
}

class ChurnAnalysis {
  const ChurnAnalysis({
    required this.available,
    required this.reason,
    required this.warning,
    required this.atRiskCount,
    required this.patients,
  });

  final bool available;
  final String reason;
  final String warning;
  final int atRiskCount;
  final List<PatientChurnRisk> patients;
}

class PatientChurnRisk {
  const PatientChurnRisk({
    required this.patientId,
    required this.patientName,
    required this.risk,
    required this.level,
    required this.mainFactor,
  });

  final int patientId;
  final String patientName;
  final int risk;
  final String level;
  final String mainFactor;
}
