import '../../domain/entities/financial_summary.dart';

class FinancialSummaryDto {
  const FinancialSummaryDto({
    required this.start,
    required this.end,
    required this.total,
    required this.sessionCount,
    required this.totalHours,
    required this.byCompany,
    required this.byServiceType,
  });

  factory FinancialSummaryDto.fromJson(Map<String, dynamic> json) {
    List<FinancialGroup> groups(String key) {
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => FinancialGroup(
              name: item['nome'] as String? ?? '',
              value: double.tryParse(item['valor'] as String? ?? '') ?? 0,
            ),
          )
          .toList(growable: false);
    }

    return FinancialSummaryDto(
      start: DateTime.parse(json['data_inicio'] as String),
      end: DateTime.parse(json['data_fim'] as String),
      total: double.tryParse(json['total_geral'] as String? ?? '') ?? 0,
      sessionCount: json['total_sessoes'] as int? ?? 0,
      totalHours: double.tryParse(json['total_horas'] as String? ?? '') ?? 0,
      byCompany: groups('por_empresa'),
      byServiceType: groups('por_tipo'),
    );
  }

  final DateTime start;
  final DateTime end;
  final double total;
  final int sessionCount;
  final double totalHours;
  final List<FinancialGroup> byCompany;
  final List<FinancialGroup> byServiceType;

  FinancialSummary toDomain() => FinancialSummary(
    period: FinancialPeriod(start: start, end: end),
    total: total,
    sessionCount: sessionCount,
    totalHours: totalHours,
    byCompany: byCompany,
    byServiceType: byServiceType,
  );
}
