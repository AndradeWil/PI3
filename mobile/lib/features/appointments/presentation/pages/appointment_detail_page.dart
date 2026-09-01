import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/appointment_providers.dart';

class AppointmentDetailPage extends ConsumerWidget {
  const AppointmentDetailPage({required this.appointmentId, super.key});

  final int appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointment = ref.watch(appointmentDetailProvider(appointmentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimento'),
        actions: [
          IconButton(
            onPressed: () =>
                context.push('/atendimentos/$appointmentId/editar'),
            tooltip: 'Editar atendimento',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: appointment.when(
        data: (item) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.patientName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(item.typeName),
                        const Divider(height: 32),
                        _DetailRow(
                          label: 'Empresa',
                          value: item.companyName ?? 'Particular',
                        ),
                        _DetailRow(
                          label: 'Valor por sessao',
                          value:
                              'R\$ ${item.sessionValue.replaceAll('.', ',')}',
                        ),
                        _DetailRow(
                          label: 'Status',
                          value: item.active ? 'Ativo' : 'Inativo',
                        ),
                        _DetailRow(label: 'Observacoes', value: item.notes),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('Nao foi possivel carregar o atendimento.'),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value.isEmpty ? 'Nao informado' : value),
        ],
      ),
    );
  }
}
