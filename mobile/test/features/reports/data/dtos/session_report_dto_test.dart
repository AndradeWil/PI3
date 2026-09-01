import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/reports/data/dtos/session_report_dto.dart';

void main() {
  test('maps report summary and session rows', () {
    final report = SessionReportDto.fromJson({
      'count': 1,
      'results': [
        {
          'id': 4,
          'paciente_nome': 'Maria Silva',
          'tipo_atendimento': 'Fisioterapia Motora',
          'data_hora': '2026-09-01T14:30:00-03:00',
          'duracao_minutos': 60,
          'valor_sessao': '120.00',
          'compareceu': true,
        },
      ],
      'resumo': {
        'data_inicio': '2026-09-01',
        'data_fim': '2026-09-30',
        'total_sessoes': 1,
        'total_valor': '120.00',
        'total_horas': '1.00',
      },
    }).toDomain();

    expect(report.summary.totalValue, 120);
    expect(report.sessions.single.patientName, 'Maria Silva');
    expect(report.sessions.single.attended, isTrue);
  });
}
