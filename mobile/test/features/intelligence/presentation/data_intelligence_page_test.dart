import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/intelligence/application/intelligence_providers.dart';
import 'package:physiomanage_mobile/features/intelligence/domain/entities/data_intelligence.dart';
import 'package:physiomanage_mobile/features/intelligence/domain/repositories/intelligence_repository.dart';
import 'package:physiomanage_mobile/features/intelligence/presentation/pages/data_intelligence_page.dart';

void main() {
  testWidgets('renders executive metrics and honest unavailable analyses', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          intelligenceRepositoryProvider.overrideWithValue(
            _IntelligenceRepository(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DataIntelligencePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visao executiva'), findsOneWidget);
    expect(find.textContaining('320,00'), findsOneWidget);
    expect(find.text('Previsao financeira'), findsOneWidget);
    expect(find.textContaining('Dados insuficientes'), findsWidgets);
    expect(find.text('Analise de glosas'), findsOneWidget);
  });
}

class _IntelligenceRepository implements IntelligenceRepository {
  @override
  Future<DataIntelligence> getSummary() async {
    const unavailable = DataAvailability(
      available: false,
      reason: 'Historico ainda nao disponivel.',
    );
    return DataIntelligence(
      updatedAt: DateTime(2026, 9, 1, 12),
      monthRevenue: 320,
      monthSessions: 3,
      activePatients: 4,
      absenceRate: 33.3,
      monthlySeries: [
        MonthlyDataPoint(
          month: DateTime(2026, 9),
          revenue: 320,
          sessions: 3,
          absences: 1,
        ),
      ],
      forecast: const FinancialForecast(
        available: false,
        reason: 'Sao necessarios tres meses.',
        expectedRevenue: null,
        trendPercentage: null,
        method: null,
      ),
      travelCosts: unavailable,
      denials: unavailable,
      churn: unavailable,
    );
  }
}
