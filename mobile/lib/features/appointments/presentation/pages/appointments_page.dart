import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/appointment_providers.dart';
import '../../domain/entities/appointment.dart';

class AppointmentsPage extends ConsumerWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(appointmentsProvider.future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Atendimentos'),
            actions: [
              IconButton(
                onPressed: () => context.push('/atendimentos/novo'),
                tooltip: 'Novo atendimento',
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 8),
            ],
          ),
          appointments.when(
            data: (items) => items.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyAppointments(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _AppointmentCard(appointment: items[index]),
                        ),
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => ref.invalidate(appointmentsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 80,
        leading: Icon(
          appointment.active
              ? Icons.play_circle_outline
              : Icons.pause_circle_outline,
          color: appointment.active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(appointment.patientName),
        subtitle: Text(
          '${appointment.typeName}\nR\$ ${appointment.sessionValue.replaceAll('.', ',')}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/atendimentos/${appointment.id}'),
      ),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_services_outlined, size: 48),
          SizedBox(height: 12),
          Text('Nenhum atendimento cadastrado.'),
        ],
      ),
    );
  }
}
