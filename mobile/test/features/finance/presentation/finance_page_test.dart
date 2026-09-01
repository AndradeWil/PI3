import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/finance/application/finance_providers.dart';
import 'package:physiomanage_mobile/features/finance/domain/entities/financial_summary.dart';
import 'package:physiomanage_mobile/features/finance/domain/repositories/finance_repository.dart';
import 'package:physiomanage_mobile/features/finance/presentation/pages/finance_page.dart';

void main() {
  testWidgets('renders financial KPIs and breakdowns', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeRepositoryProvider.overrideWithValue(_FinanceRepository()),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: FinancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receita no periodo'), findsOneWidget);
    expect(find.textContaining('320,50'), findsWidgets);
    expect(find.text('Empresa Vida'), findsOneWidget);
    expect(find.text('Fisioterapia Motora'), findsOneWidget);
  });
}

class _FinanceRepository implements FinanceRepository {
  @override
  Future<FinancialSummary> getSummary(FinancialPeriod period) async {
    return FinancialSummary(
      period: period,
      total: 320.50,
      sessionCount: 3,
      totalHours: 2.5,
      byCompany: const [FinancialGroup(name: 'Empresa Vida', value: 320.50)],
      byServiceType: const [
        FinancialGroup(name: 'Fisioterapia Motora', value: 320.50),
      ],
    );
  }
}
