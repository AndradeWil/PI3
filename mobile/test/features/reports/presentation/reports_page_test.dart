import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/reports/application/report_providers.dart';
import 'package:physiomanage_mobile/features/reports/domain/entities/session_report.dart';
import 'package:physiomanage_mobile/features/reports/domain/repositories/report_repository.dart';
import 'package:physiomanage_mobile/features/reports/presentation/pages/reports_page.dart';

void main() {
  testWidgets('renders report summary and session rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(_ReportRepository()),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ReportsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receita no periodo'), findsNothing);
    expect(find.text('Sessoes no periodo'), findsOneWidget);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.textContaining('120,00'), findsWidgets);
  });
}

class _ReportRepository implements ReportRepository {
  @override
  Future<String> downloadPdf(ReportPeriod period) async => 'relatorio.pdf';

  @override
  Future<SessionReport> getSessions(ReportPeriod period) async {
    return SessionReport(
      summary: ReportSummary(
        period: period,
        sessionCount: 1,
        totalValue: 120,
        totalHours: 1,
      ),
      sessions: [
        ReportSession(
          id: 1,
          patientName: 'Maria Silva',
          serviceType: 'Fisioterapia Motora',
          dateTime: DateTime(2026, 9, 1, 14, 30),
          durationMinutes: 60,
          value: 120,
          attended: true,
        ),
      ],
    );
  }
}
