import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/dashboard/data/dtos/dashboard_dto.dart';

void main() {
  test('maps API dashboard JSON and formats Brazilian currency', () {
    final summary = DashboardDto.fromJson({
      'monthly_revenue': '8420.50',
      'active_patients': 38,
      'today_sessions': 1,
      'alerts': 0,
      'next_session': null,
      'today_agenda': [
        {
          'time': '14:30',
          'patient_name': 'Maria Silva',
          'location': '',
          'attended': false,
        },
      ],
    }).toDomain();

    expect(summary.monthlyRevenue, contains('8.420,50'));
    expect(summary.activePatients, 38);
    expect(summary.nextSession, isNull);
    expect(summary.todayAgenda.single.patientName, 'Maria Silva');
    expect(summary.todayAgenda.single.location, 'Endereco nao informado');
  });
}
