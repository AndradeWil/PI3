import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/schedule/data/dtos/scheduled_session_dto.dart';

void main() {
  test('maps the Django session contract to the schedule entity', () {
    final session = ScheduledSessionDto.fromJson({
      'id': 9,
      'atendimento': 4,
      'paciente_id': 7,
      'paciente_nome': 'Maria Silva',
      'endereco': 'Rua A, 10',
      'tipo_atendimento': 'Fisioterapia motora',
      'data_hora': '2026-09-01T14:30:00-03:00',
      'duracao_minutos': 60,
      'valor_sessao': '120.00',
      'compareceu': false,
      'observacoes': '',
    }).toDomain();

    expect(session.patientName, 'Maria Silva');
    expect(session.patientId, 7);
    expect(session.durationMinutes, 60);
    expect(session.value, contains('120,00'));
  });
}
