import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/intelligence/application/intelligence_providers.dart';
import 'package:physiomanage_mobile/features/intelligence/domain/entities/data_intelligence.dart';
import 'package:physiomanage_mobile/features/intelligence/domain/repositories/intelligence_repository.dart';
import 'package:physiomanage_mobile/features/intelligence/presentation/pages/data_intelligence_page.dart';

void main() {
  testWidgets('renders executive and demonstration analysis metrics', (
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
    expect(find.textContaining('Dados insuficientes'), findsOneWidget);
    expect(find.text('Analise de glosas'), findsOneWidget);
    expect(find.textContaining('85,00'), findsNWidgets(2));
    expect(find.text('Maria Silva'), findsOneWidget);
  });
}

class _IntelligenceRepository implements IntelligenceRepository {
  @override
  Future<DataIntelligence> getSummary() async {
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
      travelCosts: const TravelCostAnalysis(
        available: true,
        reason: '',
        records: 9,
        totalDistance: 116.5,
        totalCost: 85,
        averageCost: 9.44,
      ),
      denials: const DenialAnalysis(
        available: true,
        reason: '',
        count: 2,
        pending: 1,
        totalValue: 85,
        rate: 22.2,
        mainOperator: 'Saude em Casa Demo',
      ),
      churn: const ChurnAnalysis(
        available: true,
        reason: '',
        warning: 'Indicador administrativo demonstrativo.',
        atRiskCount: 1,
        patients: [
          PatientChurnRisk(
            patientId: 1,
            patientName: 'Maria Silva',
            risk: 70,
            level: 'alto',
            mainFactor: 'Ultima sessao ha 20 dias; 1 falta recente.',
          ),
        ],
      ),
    );
  }
}
