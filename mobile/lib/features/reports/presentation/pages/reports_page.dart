import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../application/report_providers.dart';
import '../../domain/entities/session_report.dart';
import '../../domain/repositories/report_repository.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late ReportPeriod period = _currentMonth();
  bool exporting = false;

  static ReportPeriod _currentMonth() {
    final now = DateTime.now();
    return ReportPeriod(start: DateTime(now.year, now.month), end: now);
  }

  void changeMonth(int offset) {
    final start = DateTime(period.start.year, period.start.month + offset);
    final now = DateTime.now();
    final end = start.year == now.year && start.month == now.month
        ? now
        : DateTime(start.year, start.month + 1, 0);
    setState(() => period = ReportPeriod(start: start, end: end));
  }

  Future<void> choosePeriod() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: period.start, end: period.end),
    );
    if (range != null) {
      setState(() => period = ReportPeriod(start: range.start, end: range.end));
    }
  }

  Future<void> exportPdf() async {
    setState(() => exporting = true);
    try {
      final path = await ref.read(reportRepositoryProvider).downloadPdf(period);
      final result = await OpenFilex.open(path, type: 'application/pdf');
      if (result.type != ResultType.done && mounted) {
        _message('PDF salvo, mas nenhum visualizador conseguiu abri-lo.');
      }
    } on ReportFailure {
      if (mounted) _message('Nao foi possivel exportar o relatorio.');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(sessionReportProvider(period));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(sessionReportProvider(period).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Relatorios'),
            actions: [
              IconButton(
                onPressed: exporting ? null : exportPdf,
                tooltip: 'Exportar PDF',
                icon: exporting
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
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
                      report.when(
                        data: (data) => _ReportContent(report: data),
                        loading: () => const SizedBox(
                          height: 360,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => SizedBox(
                          height: 300,
                          child: Center(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  ref.invalidate(sessionReportProvider(period)),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
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

  final ReportPeriod period;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final label =
        '${DateFormat('dd/MM/yy').format(period.start)} - '
        '${DateFormat('dd/MM/yy').format(period.end)}';
    return Card(
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
              label: Text(label),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: 'Proximo mes',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report});

  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Sessoes',
                value: '${report.summary.sessionCount}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Horas',
                value: NumberFormat(
                  '0.##',
                  'pt_BR',
                ).format(report.summary.totalHours),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Total',
                value: currency.format(report.summary.totalValue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Sessoes no periodo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (report.sessions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Nenhuma sessao no periodo.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < report.sessions.length;
                  index++
                ) ...[
                  _SessionTile(session: report.sessions[index]),
                  if (index < report.sessions.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final ReportSession session;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 72,
      leading: Icon(
        session.attended
            ? Icons.check_circle_outline
            : Icons.event_busy_outlined,
        color: session.attended
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
      ),
      title: Text(session.patientName),
      subtitle: Text(
        '${DateFormat('dd/MM/yyyy HH:mm').format(session.dateTime)}\n${session.serviceType}',
      ),
      isThreeLine: true,
      trailing: Text(
        NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        ).format(session.value),
      ),
    );
  }
}
