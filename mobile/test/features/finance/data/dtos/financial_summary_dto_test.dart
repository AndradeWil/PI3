import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/finance/data/dtos/financial_summary_dto.dart';

void main() {
  test('maps financial summary and groups from Django', () {
    final summary = FinancialSummaryDto.fromJson({
      'data_inicio': '2026-09-01',
      'data_fim': '2026-09-30',
      'total_geral': '320.50',
      'total_sessoes': 3,
      'total_horas': '2.50',
      'por_empresa': [
        {'nome': 'Empresa Vida', 'valor': '200.50'},
      ],
      'por_tipo': [
        {'nome': 'Motora', 'valor': '320.50'},
      ],
    }).toDomain();

    expect(summary.total, 320.50);
    expect(summary.sessionCount, 3);
    expect(summary.totalHours, 2.5);
    expect(summary.byCompany.single.name, 'Empresa Vida');
  });
}
