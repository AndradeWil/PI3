import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/finance_providers.dart';
import '../../domain/entities/financial_summary.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  late FinancialPeriod period = _currentMonth();

  static FinancialPeriod _currentMonth() {
    final now = DateTime.now();
    return FinancialPeriod(start: DateTime(now.year, now.month), end: now);
  }

  void changeMonth(int offset) {
    final month = DateTime(period.start.year, period.start.month + offset);
    final now = DateTime.now();
    final lastDay = DateTime(month.year, month.month + 1, 0);
    setState(() {
      period = FinancialPeriod(
        start: month,
        end: month.year == now.year && month.month == now.month ? now : lastDay,
      );
    });
  }

  Future<void> choosePeriod() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: period.start, end: period.end),
    );
    if (selected != null) {
      setState(
        () =>
            period = FinancialPeriod(start: selected.start, end: selected.end),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(financialSummaryProvider(period));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(financialSummaryProvider(period).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar.large(title: Text('Financeiro')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PeriodSelector(
                        period: period,
                        onPrevious: () => changeMonth(-1),
                        onNext: () => changeMonth(1),
                        onPick: choosePeriod,
                      ),
                      const SizedBox(height: 16),
                      summary.when(
                        data: (data) => _FinancialContent(summary: data),
                        loading: () => const SizedBox(
                          height: 360,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => _FinanceError(
                          onRetry: () =>
                              ref.invalidate(financialSummaryProvider(period)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final FinancialPeriod period;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final sameMonth =
        period.start.year == period.end.year &&
        period.start.month == period.end.month;
    final label = sameMonth
        ? DateFormat('MMMM yyyy', 'pt_BR').format(period.start)
        : '${DateFormat('dd/MM/yy').format(period.start)} - ${DateFormat('dd/MM/yy').format(period.end)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Mes anterior',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(label, textAlign: TextAlign.center),
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: 'Proximo mes',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialContent extends StatelessWidget {
  const _FinancialContent({required this.summary});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RevenueCard(value: currency.format(summary.total)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.event_available_outlined,
                value: '${summary.sessionCount}',
                label: 'Sessoes',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.schedule_outlined,
                value: NumberFormat('0.##', 'pt_BR').format(summary.totalHours),
                label: 'Horas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (summary.total == 0)
          const _EmptyFinance()
        else ...[
          _BreakdownCard(
            title: 'Receita por empresa',
            groups: summary.byCompany,
            chart: _CompanyChart(groups: summary.byCompany),
          ),
          const SizedBox(height: 16),
          _BreakdownCard(
            title: 'Receita por tipo',
            groups: summary.byServiceType,
            chart: _TypeChart(groups: summary.byServiceType),
          ),
        ],
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receita no periodo', style: TextStyle(color: colors.onPrimary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.groups,
    required this.chart,
  });

  final String title;
  final List<FinancialGroup> groups;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: chart),
            const SizedBox(height: 16),
            for (var index = 0; index < groups.length; index++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 12,
                  height: 12,
                  color: _chartColors[index % _chartColors.length],
                ),
                title: Text(groups[index].name),
                trailing: Text(currency.format(groups[index].value)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompanyChart extends StatelessWidget {
  const _CompanyChart({required this.groups});

  final List<FinancialGroup> groups;

  @override
  Widget build(BuildContext context) {
    final total = groups.fold<double>(0, (sum, item) => sum + item.value);
    return Semantics(
      label: 'Grafico de receita por empresa',
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 46,
          sectionsSpace: 2,
          sections: [
            for (var index = 0; index < groups.length; index++)
              PieChartSectionData(
                value: groups[index].value,
                color: _chartColors[index % _chartColors.length],
                radius: 58,
                title: total == 0
                    ? ''
                    : '${(groups[index].value / total * 100).round()}%',
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeChart extends StatelessWidget {
  const _TypeChart({required this.groups});

  final List<FinancialGroup> groups;

  @override
  Widget build(BuildContext context) {
    final visible = groups.take(6).toList();
    return Semantics(
      label: 'Grafico de receita por tipo de atendimento',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < visible.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: visible[index].value,
                    color: _chartColors[index % _chartColors.length],
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFinance extends StatelessWidget {
  const _EmptyFinance();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.query_stats_outlined, size: 48),
            SizedBox(height: 12),
            Text('Sem dados financeiros no periodo.'),
          ],
        ),
      ),
    );
  }
}

class _FinanceError extends StatelessWidget {
  const _FinanceError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ),
    );
  }
}

const _chartColors = [
  Color(0xFF0C7A9B),
  Color(0xFFF2A54A),
  Color(0xFF3F8F65),
  Color(0xFFC5575B),
  Color(0xFF5673B8),
  Color(0xFF8A6A9E),
];
