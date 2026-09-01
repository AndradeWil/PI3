import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/patient_providers.dart';
import '../../domain/entities/patient.dart';

class PatientDetailPage extends ConsumerWidget {
  const PatientDetailPage({required this.patientId, super.key});

  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(patientDetailProvider(patientId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paciente'),
        actions: [
          IconButton(
            onPressed: () => context.push('/pacientes/$patientId/editar'),
            tooltip: 'Editar paciente',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: patient.when(
        data: (data) => _PatientDetails(patient: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _PatientError(
          onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
        ),
      ),
    );
  }
}

class _PatientDetails extends StatelessWidget {
  const _PatientDetails({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 32, child: Text(patient.initials)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (patient.companyName case final company?)
                            Text(company),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Contato',
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Telefone',
                      value: patient.phone,
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'E-mail',
                      value: patient.email,
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Endereco',
                      value: patient.address,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Tratamento',
                  children: [
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Idade',
                      value: patient.age?.toString() ?? '',
                    ),
                    _InfoRow(
                      icon: Icons.repeat,
                      label: 'Frequencia diaria',
                      value: '${patient.dailyFrequency}',
                    ),
                    _InfoRow(
                      icon: Icons.medical_information_outlined,
                      label: 'Quadro clinico',
                      value: patient.clinicalCondition,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'Nao informado' : value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientError extends StatelessWidget {
  const _PatientError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Nao foi possivel carregar este paciente.'),
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
