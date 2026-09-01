import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/schedule/application/schedule_providers.dart';
import 'package:physiomanage_mobile/features/schedule/domain/entities/active_appointment.dart';
import 'package:physiomanage_mobile/features/schedule/domain/entities/scheduled_session.dart';
import 'package:physiomanage_mobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:physiomanage_mobile/features/schedule/presentation/pages/schedule_page.dart';
import 'package:physiomanage_mobile/features/schedule/presentation/widgets/session_action_bar.dart';

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
          home: Scaffold(body: SchedulePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Fisioterapia motora'), findsOneWidget);
    expect(find.text('Registrar sessao agora'), findsOneWidget);

    await tester.tap(find.text('Registrar sessao agora'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar sessao'), findsOneWidget);
    expect(find.text('Nenhum atendimento ativo disponivel.'), findsOneWidget);
  });

  testWidgets('confirms attendance and deletion from the session card', (
    tester,
  ) async {
    final repository = _ScheduleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: SchedulePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcar como realizado'), findsOneWidget);
    expect(find.text('Realizado'), findsNothing);
    await tester.tap(find.text('Marcar como realizado'));
    await tester.pumpAndSettle();
    expect(
      find.text('Confirma que este atendimento foi realizado?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(repository.markedSessionId, 1);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Esta acao nao pode ser desfeita'),
      findsOneWidget,
    );
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(repository.deletedSessionId, 1);
  });

  testWidgets(
    'shows a green completed state instead of the attendance action',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SessionActionBar(sessionId: 1, attended: true),
            ),
          ),
        ),
      );

      expect(find.text('Realizado'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Marcar como realizado'), findsNothing);
      expect(find.text('Excluir'), findsOneWidget);
    },
  );
}

class _ScheduleRepository implements ScheduleRepository {
  int? markedSessionId;
  int? deletedSessionId;

  @override
  Future<void> deleteSession(int sessionId) async {
    deletedSessionId = sessionId;
  }

  @override
  Future<List<ActiveAppointment>> listActiveAppointments() async => const [];

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

  @override
  Future<void> markAttended(int sessionId) async {
    markedSessionId = sessionId;
  }

  @override
  Future<ScheduledSession> quickClockIn(
    int appointmentId,
    String idempotencyKey,
  ) async {
    return (await listByDate(DateTime.now())).first;
  }
}
