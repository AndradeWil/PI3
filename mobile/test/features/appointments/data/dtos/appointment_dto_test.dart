import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/appointments/data/dtos/appointment_dto.dart';

void main() {
  test('maps the Django appointment contract', () {
    final appointment = AppointmentDto.fromJson({
      'id': 3,
      'paciente': 7,
      'paciente_nome': 'Maria Silva',
      'empresa': 2,
      'empresa_nome': 'Empresa Vida',
      'tipo_atendimento': 4,
      'tipo_atendimento_nome': 'Fisioterapia Motora',
      'valor_por_sessao': '120.00',
      'observacoes': 'Plano semanal',
      'ativo': true,
    }).toDomain();

    expect(appointment.patientName, 'Maria Silva');
    expect(appointment.typeName, 'Fisioterapia Motora');
    expect(appointment.active, isTrue);
  });
}
