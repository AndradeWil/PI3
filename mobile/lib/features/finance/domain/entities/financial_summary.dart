class FinancialPeriod {
  const FinancialPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    return other is FinancialPeriod &&
        _day(other.start) == _day(start) &&
        _day(other.end) == _day(end);
  }

  @override
  int get hashCode => Object.hash(_day(start), _day(end));

  static int _day(DateTime value) =>
      value.year * 10000 + value.month * 100 + value.day;
}

class FinancialSummary {
  const FinancialSummary({
    required this.period,
    required this.total,
    required this.sessionCount,
    required this.totalHours,
    required this.byCompany,
    required this.byServiceType,
  });

  final FinancialPeriod period;
  final double total;
  final int sessionCount;
  final double totalHours;
  final List<FinancialGroup> byCompany;
  final List<FinancialGroup> byServiceType;
}

class FinancialGroup {
  const FinancialGroup({required this.name, required this.value});

  final String name;
  final double value;
}
