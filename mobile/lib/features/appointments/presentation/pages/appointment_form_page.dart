import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/application/dashboard_providers.dart';
import '../../../schedule/application/schedule_providers.dart';
import '../../application/appointment_providers.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

class AppointmentFormPage extends ConsumerStatefulWidget {
  const AppointmentFormPage({this.appointmentId, super.key});

  final int? appointmentId;

  @override
  ConsumerState<AppointmentFormPage> createState() =>
      _AppointmentFormPageState();
}

class _AppointmentFormPageState extends ConsumerState<AppointmentFormPage> {
  final formKey = GlobalKey<FormState>();
  final value = TextEditingController();
  final notes = TextEditingController();
  int? patientId;
  int? companyId;
  int? typeId;
  bool active = true;
  bool initialized = false;
  bool saving = false;

  @override
  void dispose() {
    value.dispose();
    notes.dispose();
    super.dispose();
  }

  void initialize(Appointment? item) {
    if (initialized) return;
    initialized = true;
    if (item == null) return;
    patientId = item.patientId;
    companyId = item.companyId;
    typeId = item.typeId;
    value.text = item.sessionValue;
    notes.text = item.notes;
    active = item.active;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref.read(saveAppointmentProvider)(
        AppointmentInput(
          patientId: patientId!,
          companyId: companyId,
          typeId: typeId!,
          sessionValue: value.text.replaceAll(',', '.'),
          notes: notes.text.trim(),
          active: active,
        ),
        id: widget.appointmentId,
      );
      ref.invalidate(appointmentsProvider);
      ref.invalidate(activeAppointmentsProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (widget.appointmentId case final id?) {
        ref.invalidate(appointmentDetailProvider(id));
      }
      if (mounted) Navigator.of(context).pop();
    } on AppointmentFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel salvar o atendimento.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(appointmentOptionsProvider);
    final detail = widget.appointmentId == null
        ? const AsyncValue<Appointment?>.data(null)
        : ref.watch(appointmentDetailProvider(widget.appointmentId!));
    return options.when(
      data: (available) => detail.when(
        data: (item) {
          initialize(item);
          return _form(context, available);
        },
        loading: loading,
        error: (error, stackTrace) => failure(),
      ),
      loading: loading,
      error: (error, stackTrace) => failure(),
    );
  }

  Widget loading() =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));

  Widget failure() => const Scaffold(
    body: Center(child: Text('Nao foi possivel carregar o formulario.')),
  );

  Widget _form(BuildContext context, AppointmentOptions options) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appointmentId == null
              ? 'Novo atendimento'
              : 'Editar atendimento',
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: patientId,
                      decoration: const InputDecoration(
                        labelText: 'Paciente *',
                      ),
                      items: options.patients
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) =>
                          setState(() => patientId = selected),
                      validator: (selected) =>
                          selected == null ? 'Selecione o paciente.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: companyId,
                      decoration: const InputDecoration(labelText: 'Empresa'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Particular'),
                        ),
                        ...options.companies.map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        ),
                      ],
                      onChanged: (selected) =>
                          setState(() => companyId = selected),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: typeId,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de atendimento *',
                      ),
                      items: options.types
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) {
                        setState(() {
                          typeId = selected;
                          final type = options.types
                              .where((item) => item.id == selected)
                              .firstOrNull;
                          if (value.text.isEmpty &&
                              type?.defaultValue != null) {
                            value.text = type!.defaultValue!;
                          }
                        });
                      },
                      validator: (selected) =>
                          selected == null ? 'Selecione o tipo.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor por sessao *',
                      ),
                      validator: (text) {
                        final parsed = num.tryParse(
                          (text ?? '').replaceAll(',', '.'),
                        );
                        return parsed == null || parsed < 0
                            ? 'Informe um valor valido.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Observacoes',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Atendimento ativo'),
                      value: active,
                      onChanged: (selected) =>
                          setState(() => active = selected),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Salvando...' : 'Salvar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
