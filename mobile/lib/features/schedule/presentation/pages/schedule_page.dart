import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/application/dashboard_providers.dart';
import '../../application/schedule_providers.dart';
import '../../domain/entities/scheduled_session.dart';
import '../widgets/quick_session_sheet.dart';
import '../widgets/session_action_bar.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  late DateTime selectedDate = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void changeDay(int days) {
    setState(() => selectedDate = selectedDate.add(Duration(days: days)));
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) setState(() => selectedDate = _dateOnly(date));
  }

  Future<void> registerSession() async {
    final registered = await showQuickSessionSheet(context);
    if (!registered || !mounted) return;
    final today = _dateOnly(DateTime.now());
    setState(() => selectedDate = today);
    ref.invalidate(scheduleProvider(today));
    ref.invalidate(activeAppointmentsProvider);
    ref.invalidate(dashboardSummaryProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessao registrada com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider(selectedDate));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(scheduleProvider(selectedDate).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Agenda'),
            actions: [
              IconButton(
                onPressed: registerSession,
                tooltip: 'Registrar sessao',
                icon: const Icon(Icons.punch_clock_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _DateSelector(
                    date: selectedDate,
                    onPrevious: () => changeDay(-1),
                    onNext: () => changeDay(1),
                    onToday: () => setState(
                      () => selectedDate = _dateOnly(DateTime.now()),
                    ),
                    onPick: pickDate,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: FilledButton.icon(
                    onPressed: registerSession,
                    icon: const Icon(Icons.punch_clock_outlined),
                    label: const Text('Registrar sessao agora'),
                  ),
                ),
              ),
            ),
          ),
          schedule.when(
            data: (sessions) => sessions.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySchedule(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _SessionCard(session: sessions[index]),
                        ),
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _ScheduleError(
                onRetry: () => ref.invalidate(scheduleProvider(selectedDate)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Dia anterior',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        DateFormat("EEEE", 'pt_BR').format(date),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        DateFormat("dd 'de' MMMM", 'pt_BR').format(date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: 'Proximo dia',
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: onToday,
              tooltip: 'Ir para hoje',
              icon: const Icon(Icons.today_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ScheduledSession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push('/pacientes/${session.patientId}'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('HH:mm').format(session.dateTime),
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.patientName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(session.serviceType),
                        if (session.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text('${session.durationMinutes} min'),
                            Text(session.value),
                            Text(session.attended ? 'Realizada' : 'Agendada'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SessionActionBar(sessionId: session.id, attended: session.attended),
          ],
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 48),
            SizedBox(height: 12),
            Text('Nenhuma sessao neste dia.'),
          ],
        ),
      ),
    );
  }
}

class _ScheduleError extends StatelessWidget {
  const _ScheduleError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Nao foi possivel carregar a agenda.'),
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
