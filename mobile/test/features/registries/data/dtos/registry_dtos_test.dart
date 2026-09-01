import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/registries/data/dtos/registry_dtos.dart';

void main() {
  test('maps company and service type contracts', () {
    final company = CompanyDto.fromJson({
      'id': 1,
      'nome': 'Empresa Vida',
      'contato': 'Ana',
      'telefone': '11999990000',
      'email': 'ana@example.com',
    }).toDomain();
    final type = ServiceTypeDto.fromJson({
      'id': 2,
      'nome': 'Fisioterapia Motora',
      'descricao': 'Atendimento domiciliar',
      'valor_padrao': '120.00',
    }).toDomain();

    expect(company.name, 'Empresa Vida');
    expect(type.defaultValue, '120.00');
  });
}
