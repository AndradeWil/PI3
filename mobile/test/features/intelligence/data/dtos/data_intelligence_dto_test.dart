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
}
