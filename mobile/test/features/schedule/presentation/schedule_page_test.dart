import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/schedule/application/schedule_providers.dart';
import 'package:physiomanage_mobile/features/schedule/domain/entities/scheduled_session.dart';
import 'package:physiomanage_mobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:physiomanage_mobile/features/schedule/presentation/pages/schedule_page.dart';

void main() {
  testWidgets('renders sessions for the selected day', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(_ScheduleRepository()),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SchedulePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Fisioterapia motora'), findsOneWidget);
  });
}

class _ScheduleRepository implements ScheduleRepository {
  @override
  Future<List<ScheduledSession>> listByDate(DateTime date) async {
    return [
      ScheduledSession(
        id: 1,
        appointmentId: 2,
        patientId: 3,
        patientName: 'Maria Silva',
        address: 'Rua A, 10',
        serviceType: 'Fisioterapia motora',
        dateTime: DateTime(date.year, date.month, date.day, 14, 30),
        durationMinutes: 60,
        value: 'R\$ 120,00',
        attended: false,
        notes: '',
      ),
    ];
  }
}
