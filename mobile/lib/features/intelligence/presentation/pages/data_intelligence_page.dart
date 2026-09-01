import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/intelligence_providers.dart';
import '../../domain/entities/data_intelligence.dart';

class DataIntelligencePage extends ConsumerWidget {
  const DataIntelligencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intelligence = ref.watch(dataIntelligenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Inteligencia de Dados')),
      body: intelligence.when(
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(dataIntelligenceProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: _Content(data: data),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(dataIntelligenceProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final DataIntelligence data;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Visao executiva',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Atualizado em ${DateFormat('dd/MM/yyyy HH:mm').format(data.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _Kpi(
              label: 'Receita no mes',
              value: currency.format(data.monthRevenue),
            ),
            _Kpi(label: 'Sessoes no mes', value: '${data.monthSessions}'),
            _Kpi(label: 'Pacientes ativos', value: '${data.activePatients}'),
            _Kpi(
              label: 'Ausencias registradas',
              value:
                  '${NumberFormat('0.#', 'pt_BR').format(data.absenceRate)}%',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MonthlyChart(points: data.monthlySeries),
        const SizedBox(height: 16),
        _ForecastCard(forecast: data.forecast),
        const SizedBox(height: 16),
        Text(
          'Analises avancadas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _TravelCard(analysis: data.travelCosts),
        _DenialCard(analysis: data.denials),
        _ChurnCard(analysis: data.churn),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.points});

  final List<MonthlyDataPoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Evolucao da receita',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Semantics(
                label: 'Grafico da receita mensal dos ultimos seis meses',
                child: LineChart(
                  LineChartData(
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
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat(
                                'MMM',
                                'pt_BR',
                              ).format(points[index].month),
                              style: const TextStyle(fontSize: 11),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var index = 0; index < points.length; index++)
                            FlSpot(index.toDouble(), points[index].revenue),
                        ],
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});

  final FinancialForecast forecast;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Previsao financeira',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (forecast.available) ...[
              Text(
                currency.format(forecast.expectedRevenue),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Proximo mes | Tendencia: '
                '${NumberFormat('0.#', 'pt_BR').format(forecast.trendPercentage)}%',
              ),
              const SizedBox(height: 6),
              const Text('Baseline: media movel dos ultimos 3 meses.'),
            ] else
              _InsufficientData(reason: forecast.reason),
          ],
        ),
      ),
    );
  }
}

class _TravelCard extends StatelessWidget {
  const _TravelCard({required this.analysis});

  final TravelCostAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AnalysisHeader(
              icon: Icons.route_outlined,
              title: 'Custos de deslocamento',
              badge: 'Demonstracao',
            ),
            const SizedBox(height: 12),
            if (!analysis.available)
              _InsufficientData(reason: analysis.reason)
            else ...[
              Text(
                currency.format(analysis.totalCost),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text('Custo total estimado'),
              const Divider(height: 24),
              _ValueLine(
                label: 'Distancia total',
                value:
                    '${NumberFormat('0.0', 'pt_BR').format(analysis.totalDistance)} km',
              ),
              _ValueLine(
                label: 'Media por sessao',
                value: currency.format(analysis.averageCost),
              ),
              _ValueLine(label: 'Deslocamentos', value: '${analysis.records}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _DenialCard extends StatelessWidget {
  const _DenialCard({required this.analysis});

  final DenialAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AnalysisHeader(
              icon: Icons.receipt_long_outlined,
              title: 'Analise de glosas',
              badge: 'Demonstracao',
            ),
            const SizedBox(height: 12),
            if (!analysis.available)
              _InsufficientData(reason: analysis.reason)
            else ...[
              Text(
                currency.format(analysis.totalValue),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text('Valor glosado em aberto/confirmado'),
              const Divider(height: 24),
              _ValueLine(label: 'Ocorrencias', value: '${analysis.count}'),
              _ValueLine(label: 'Pendentes', value: '${analysis.pending}'),
              _ValueLine(
                label: 'Taxa sobre sessoes',
                value: '${NumberFormat('0.0', 'pt_BR').format(analysis.rate)}%',
              ),
              _ValueLine(
                label: 'Principal operadora',
                value: analysis.mainOperator,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChurnCard extends StatelessWidget {
  const _ChurnCard({required this.analysis});

  final ChurnAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AnalysisHeader(
              icon: Icons.person_off_outlined,
              title: 'Risco de evasao',
              badge: 'Heuristica',
            ),
            const SizedBox(height: 12),
            if (!analysis.available)
              _InsufficientData(reason: analysis.reason)
            else ...[
              Text(
                '${analysis.atRiskCount} paciente(s) pedem atencao',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                analysis.warning,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              for (final patient in analysis.patients)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _riskColor(patient.level)
                        .withValues(alpha: 0.16),
                    child: Text(
                      '${patient.risk}%',
                      style: TextStyle(
                        color: _riskColor(patient.level),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(patient.patientName),
                  subtitle: Text(patient.mainFactor),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/pacientes/${patient.patientId}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _riskColor(String level) {
    return switch (level) {
      'alto' => const Color(0xFFC43B43),
      'moderado' => const Color(0xFFB5640F),
      _ => const Color(0xFF287A4D),
    };
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({
    required this.icon,
    required this.title,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge, style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InsufficientData extends StatelessWidget {
  const _InsufficientData({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Text('Dados insuficientes. $reason');
  }
}
