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
    final travel = data['custos_deslocamento'] as Map<String, dynamic>;
    final denials = data['glosas'] as Map<String, dynamic>;
    final churn = data['rotatividade'] as Map<String, dynamic>;

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
      travelCosts: TravelCostAnalysis(
        available: travel['status'] == 'disponivel',
        reason: travel['motivo'] as String? ?? '',
        records: travel['registros'] as int? ?? 0,
        totalDistance: _decimal(travel['distancia_total_km']),
        totalCost: _decimal(travel['custo_total']),
        averageCost: _decimal(travel['custo_medio_sessao']),
      ),
      denials: DenialAnalysis(
        available: denials['status'] == 'disponivel',
        reason: denials['motivo'] as String? ?? '',
        count: denials['quantidade'] as int? ?? 0,
        pending: denials['pendentes'] as int? ?? 0,
        totalValue: _decimal(denials['valor_total']),
        rate: (denials['taxa_percentual'] as num?)?.toDouble() ?? 0,
        mainOperator: denials['principal_operadora'] as String? ?? '',
      ),
      churn: ChurnAnalysis(
        available: churn['status'] == 'disponivel',
        reason: churn['motivo'] as String? ?? '',
        warning: churn['aviso'] as String? ?? '',
        atRiskCount: churn['pacientes_em_risco'] as int? ?? 0,
        patients: (churn['ranking'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => PatientChurnRisk(
                patientId: item['paciente_id'] as int,
                patientName: item['paciente_nome'] as String? ?? '',
                risk: item['risco_percentual'] as int? ?? 0,
                level: item['nivel'] as String? ?? 'baixo',
                mainFactor: item['fator_principal'] as String? ?? '',
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  static double _decimal(dynamic value) {
    return double.tryParse(value as String? ?? '') ?? 0;
  }
}
