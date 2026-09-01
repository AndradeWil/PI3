import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/schedule_providers.dart';
import '../../domain/entities/active_appointment.dart';
import '../../domain/repositories/schedule_repository.dart';

class QuickSessionSheet extends ConsumerStatefulWidget {
  const QuickSessionSheet({super.key});

  @override
  ConsumerState<QuickSessionSheet> createState() => _QuickSessionSheetState();
}

class _QuickSessionSheetState extends ConsumerState<QuickSessionSheet> {
  int? savingAppointmentId;

  Future<void> register(ActiveAppointment appointment) async {
    setState(() => savingAppointmentId = appointment.id);
    try {
      await ref
          .read(scheduleRepositoryProvider)
          .quickClockIn(appointment.id, const Uuid().v4());
      if (mounted) Navigator.of(context).pop(true);
    } on ScheduleFailure {
      if (mounted) {
        setState(() => savingAppointmentId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel registrar a sessao.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(activeAppointmentsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Registrar sessao',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: appointments.when(
                data: (items) => items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Nenhum atendimento ativo disponivel.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final appointment = items[index];
                          final saving = savingAppointmentId == appointment.id;
                          return ListTile(
                            enabled: savingAppointmentId == null,
                            minTileHeight: 64,
                            leading: const Icon(Icons.person_outline),
                            title: Text(appointment.patientName),
                            subtitle: Text(
                              '${appointment.serviceType} | ${appointment.sessionValue}',
                            ),
                            trailing: saving
                                ? const SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_circle_outline),
                            onTap: () => register(appointment),
                          );
                        },
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: FilledButton.icon(
                    onPressed: () => ref.invalidate(activeAppointmentsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
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
