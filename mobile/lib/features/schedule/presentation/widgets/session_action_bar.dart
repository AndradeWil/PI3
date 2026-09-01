import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/application/dashboard_providers.dart';
import '../../../finance/application/finance_providers.dart';
import '../../../reports/application/report_providers.dart';
import '../../application/schedule_providers.dart';
import '../../domain/repositories/schedule_repository.dart';

class SessionActionBar extends ConsumerWidget {
  const SessionActionBar({
    required this.sessionId,
    required this.attended,
    super.key,
  });

  final int sessionId;
  final bool attended;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref, {
    required bool delete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(delete ? 'Excluir sessao' : 'Confirmar atendimento'),
        content: Text(
          delete
              ? 'Deseja excluir esta sessao? Esta acao nao pode ser desfeita.'
              : 'Confirma que este atendimento foi realizado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(delete ? 'Excluir' : 'Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final repository = ref.read(scheduleRepositoryProvider);
      if (delete) {
        await repository.deleteSession(sessionId);
      } else {
        await repository.markAttended(sessionId);
      }
      ref.invalidate(scheduleProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(financialSummaryProvider);
      ref.invalidate(sessionReportProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              delete
                  ? 'Sessao excluida com sucesso.'
                  : 'Atendimento marcado como realizado.',
            ),
          ),
        );
      }
    } on ScheduleFailure {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel atualizar a sessao.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!attended)
          FilledButton.tonalIcon(
            onPressed: () => _run(context, ref, delete: false),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Atendimento realizado'),
          ),
        OutlinedButton.icon(
          onPressed: () => _run(context, ref, delete: true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir'),
        ),
      ],
    );
  }
}
