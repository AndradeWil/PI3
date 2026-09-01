import '../../domain/entities/data_intelligence.dart';

class DataIntelligenceDto {
  const DataIntelligenceDto(this.data);

  factory DataIntelligenceDto.fromJson(Map<String, dynamic> json) {
    return DataIntelligenceDto(json);
  }

  final Map<String, dynamic> data;

  DataIntelligence toDomain() {
    final executive = data['executivo'] as Map<String, dynamic>;
    final forecastData = data['previsao_financeira'] as Map<String, dynamic>;
    DataAvailability availability(String key) {
      final value = data[key] as Map<String, dynamic>;
      return DataAvailability(
        available: value['status'] == 'disponivel',
        reason: value['motivo'] as String? ?? '',
      );
    }

    return DataIntelligence(
      updatedAt: DateTime.parse(data['atualizado_em'] as String).toLocal(),
      monthRevenue:
          double.tryParse(executive['receita_mes'] as String? ?? '') ?? 0,
      monthSessions: executive['sessoes_mes'] as int? ?? 0,
      activePatients: executive['pacientes_ativos'] as int? ?? 0,
      absenceRate: (executive['taxa_ausencias'] as num?)?.toDouble() ?? 0,
      monthlySeries: (executive['serie_mensal'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => MonthlyDataPoint(
              month: DateTime.parse(item['mes'] as String),
              revenue: double.tryParse(item['receita'] as String? ?? '') ?? 0,
              sessions: item['sessoes'] as int? ?? 0,
              absences: item['ausencias'] as int? ?? 0,
            ),
          )
          .toList(growable: false),
      forecast: FinancialForecast(
        available: forecastData['status'] == 'disponivel',
        reason: forecastData['motivo'] as String? ?? '',
        expectedRevenue: double.tryParse(
          forecastData['receita_proximo_mes'] as String? ?? '',
        ),
        trendPercentage: (forecastData['tendencia_percentual'] as num?)
            ?.toDouble(),
        method: forecastData['metodo'] as String?,
      ),
      travelCosts: availability('custos_deslocamento'),
      denials: availability('glosas'),
      churn: availability('rotatividade'),
    );
  }
}
