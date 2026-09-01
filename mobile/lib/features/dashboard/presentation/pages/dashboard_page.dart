import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/dashboard_providers.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            title: _Header(),
            actions: [
              IconButton(
                onPressed: null,
                tooltip: 'Notificacoes',
                icon: Badge(
                  smallSize: 8,
                  child: Icon(Icons.notifications_outlined),
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
          summary.when(
            data: (data) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverToBoxAdapter(
                child: _DashboardContent(summary: data),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: _ErrorState(
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.accessibility_new, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PhysioManage', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Bom dia, Ana', style: TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RevenuePanel(revenue: summary.monthlyRevenue),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 3 : 2;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      width: width,
                      icon: Icons.event_available_outlined,
                      value: '${summary.todaySessions}',
                      label: 'Sessoes hoje',
                    ),
                    _MetricCard(
                      width: width,
                      icon: Icons.people_outline,
                      value: '${summary.activePatients}',
                      label: 'Pacientes ativos',
                    ),
                    _MetricCard(
                      width: width,
                      icon: Icons.warning_amber_rounded,
                      value: '${summary.alerts}',
                      label: 'Alertas',
                      highlight: true,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Proxima sessao',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (summary.nextSession case final session?)
              _NextSessionCard(session: session)
            else
              const _EmptyCard(message: 'Nenhuma proxima sessao agendada.'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agenda de hoje',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(onPressed: () {}, child: const Text('Ver agenda')),
              ],
            ),
            if (summary.todayAgenda.isEmpty)
              const _EmptyCard(message: 'Nenhuma sessao para hoje.')
            else
              Card(
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < summary.todayAgenda.length;
                      index++
                    ) ...[
                      _AgendaItem(session: summary.todayAgenda[index]),
                      if (index < summary.todayAgenda.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({required this.revenue});

  final String revenue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita no mes',
                  style: TextStyle(color: colors.onPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  revenue,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+7,2% em relacao ao mes anterior',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.trending_up, size: 42, color: colors.onPrimary),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: highlight ? colors.secondary : colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(label, maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.session});

  final ScheduledSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _TimeBadge(time: session.time),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.patientName,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(session.location),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              tooltip: 'Abrir rota',
              icon: const Icon(Icons.directions_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  const _AgendaItem({required this.session});

  final ScheduledSession session;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      leading: _TimeBadge(time: session.time),
      title: Text(session.patientName, overflow: TextOverflow.ellipsis),
      subtitle: Text(session.location),
      trailing: session.status == SessionStatus.next
          ? FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Registrar'),
            )
          : Icon(
              session.status == SessionStatus.confirmed
                  ? Icons.check_circle_outline
                  : Icons.schedule_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          const Text('Nao foi possivel carregar o painel.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
