import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../../core/sync/session_sync_providers.dart';
import '../../../schedule/application/schedule_providers.dart';
import '../../../schedule/presentation/widgets/quick_session_sheet.dart';
import '../../../schedule/presentation/widgets/session_action_bar.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> registerSession(BuildContext context, WidgetRef ref) async {
    final result = await showQuickSessionSheet(context);
    if (result == null || !context.mounted) return;
    if (result == SessionRegistrationResult.queued) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem conexao. Sessao salva para sincronizar.'),
        ),
      );
      return;
    }
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(activeAppointmentsProvider);
    ref.invalidate(scheduleProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessao registrada com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionSynchronizationProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final profile = ref.watch(therapistProfileProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            title: _Header(name: profile.value?.displayName),
            actions: const [
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
                child: _DashboardContent(
                  summary: data,
                  onRegisterSession: () => registerSession(context, ref),
                ),
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
  const _Header({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: Image(
            image: AssetImage('assets/logo_img.png'),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PhysioManage',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              name == null ? 'Ola' : '${_greeting()}, $name',
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.summary,
    required this.onRegisterSession,
  });

  final DashboardSummary summary;
  final VoidCallback onRegisterSession;

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
            FilledButton.icon(
              onPressed: onRegisterSession,
              icon: const Icon(Icons.punch_clock_outlined),
              label: const Text('Registrar sessao agora'),
            ),
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
                TextButton(
                  onPressed: () => context.go('/agenda'),
                  child: const Text('Ver agenda'),
                ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 14),
            SessionActionBar(
              sessionId: session.id,
              attended: session.status == SessionStatus.confirmed,
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.location),
          const SizedBox(height: 8),
          SessionActionBar(
            sessionId: session.id,
            attended: session.status == SessionStatus.confirmed,
          ),
        ],
      ),
      isThreeLine: true,
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
