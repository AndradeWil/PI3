import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/patient_providers.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';

class PatientFormPage extends ConsumerStatefulWidget {
  const PatientFormPage({this.patientId, super.key});

  final int? patientId;

  @override
  ConsumerState<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends ConsumerState<PatientFormPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final clinicalCondition = TextEditingController();
  final dailyFrequency = TextEditingController(text: '1');
  bool initialized = false;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    clinicalCondition.dispose();
    dailyFrequency.dispose();
    super.dispose();
  }

  void initialize(Patient patient) {
    if (initialized) return;
    initialized = true;
    name.text = patient.name;
    age.text = patient.age?.toString() ?? '';
    phone.text = patient.phone;
    email.text = patient.email;
    address.text = patient.address;
    clinicalCondition.text = patient.clinicalCondition;
    dailyFrequency.text = patient.dailyFrequency.toString();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref.read(savePatientProvider)(
        PatientInput(
          name: name.text.trim(),
          age: int.tryParse(age.text),
          phone: phone.text.trim(),
          email: email.text.trim(),
          address: address.text.trim(),
          clinicalCondition: clinicalCondition.text.trim(),
          dailyFrequency: int.parse(dailyFrequency.text),
        ),
        id: widget.patientId,
      );
      ref.invalidate(patientsProvider);
      if (widget.patientId case final id?) {
        ref.invalidate(patientDetailProvider(id));
      }
      if (mounted) Navigator.of(context).pop();
    } on PatientFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel salvar o paciente.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientId = widget.patientId;
    if (patientId == null) return _buildForm(context);

    return ref
        .watch(patientDetailProvider(patientId))
        .when(
          data: (patient) {
            initialize(patient);
            return _buildForm(context);
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Nao foi possivel carregar o paciente.'),
            ),
          ),
        );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientId == null ? 'Novo paciente' : 'Editar paciente',
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
                    TextFormField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nome *'),
                      validator: requiredField,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: age,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Idade',
                            ),
                            validator: optionalPositiveNumber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: dailyFrequency,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Frequencia por dia *',
                            ),
                            validator: positiveNumber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Endereco'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: clinicalCondition,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Quadro clinico *',
                      ),
                      validator: requiredField,
                    ),
                    const SizedBox(height: 24),
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

  String? requiredField(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatorio.' : null;
  }

  String? optionalPositiveNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    return positiveNumber(value);
  }

  String? positiveNumber(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 1 ? 'Informe um numero positivo.' : null;
  }
}
