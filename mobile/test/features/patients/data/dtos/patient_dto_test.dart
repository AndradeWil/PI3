import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/patients/data/dtos/patient_dto.dart';

void main() {
  test('maps the Django patient contract to the domain entity', () {
    final patient = PatientDto.fromJson({
      'id': 7,
      'nome': 'Maria Silva',
      'idade': 68,
      'telefone': '11999990000',
      'email': 'maria@example.com',
      'endereco': 'Rua A, 10',
      'quadro_clinico': 'Pos-operatorio',
      'frequencia_por_dia': 2,
      'empresa': 3,
      'empresa_nome': 'Empresa Vida',
    }).toDomain();

    expect(patient.id, 7);
    expect(patient.name, 'Maria Silva');
    expect(patient.companyName, 'Empresa Vida');
    expect(patient.initials, 'MS');
  });
}
