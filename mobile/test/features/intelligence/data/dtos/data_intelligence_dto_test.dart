import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/intelligence/data/dtos/data_intelligence_dto.dart';

void main() {
  test('maps executive data and honest availability states', () {
    final intelligence = DataIntelligenceDto.fromJson({
      'atualizado_em': '2026-09-01T12:00:00Z',
      'executivo': {
        'receita_mes': '320.00',
        'sessoes_mes': 3,
        'pacientes_ativos': 4,
        'taxa_ausencias': 33.3,
        'serie_mensal': [
          {
            'mes': '2026-09-01',
            'receita': '320.00',
            'sessoes': 3,
            'ausencias': 1,
          },
        ],
      },
      'previsao_financeira': {
        'status': 'dados_insuficientes',
        'motivo': 'Sao necessarios tres meses.',
      },
      'custos_deslocamento': {
        'status': 'dados_insuficientes',
        'motivo': 'Sem custos.',
      },
      'glosas': {'status': 'dados_insuficientes', 'motivo': 'Sem glosas.'},
      'rotatividade': {
        'status': 'dados_insuficientes',
        'motivo': 'Sem historico.',
      },
    }).toDomain();

    expect(intelligence.monthRevenue, 320);
    expect(intelligence.monthlySeries.single.absences, 1);
    expect(intelligence.forecast.available, isFalse);
    expect(intelligence.denials.reason, 'Sem glosas.');
  });

  test('maps available travel, denial and churn demonstration data', () {
    final intelligence = DataIntelligenceDto.fromJson({
      'atualizado_em': '2026-09-01T12:00:00Z',
      'executivo': {
        'receita_mes': '0.00',
        'sessoes_mes': 0,
        'pacientes_ativos': 1,
        'taxa_ausencias': 0,
        'serie_mensal': <dynamic>[],
      },
      'previsao_financeira': {
        'status': 'dados_insuficientes',
        'motivo': 'Sem historico.',
      },
      'custos_deslocamento': {
        'status': 'disponivel',
        'registros': 9,
        'distancia_total_km': '116.50',
        'custo_total': '85.00',
        'custo_medio_sessao': '9.44',
      },
      'glosas': {
        'status': 'disponivel',
        'quantidade': 2,
        'pendentes': 1,
        'valor_total': '85.00',
        'taxa_percentual': 22.2,
        'principal_operadora': 'Saude em Casa Demo',
      },
      'rotatividade': {
        'status': 'disponivel',
        'aviso': 'Heuristica demonstrativa.',
        'pacientes_em_risco': 1,
        'ranking': [
          {
            'paciente_id': 1,
            'paciente_nome': 'Maria Silva',
            'risco_percentual': 70,
            'nivel': 'alto',
            'fator_principal': 'Uma falta recente.',
          },
        ],
      },
    }).toDomain();

    expect(intelligence.travelCosts.totalCost, 85);
    expect(intelligence.denials.pending, 1);
    expect(intelligence.churn.patients.single.risk, 70);
  });
}
