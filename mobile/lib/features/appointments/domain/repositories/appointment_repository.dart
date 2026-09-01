import '../entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> list();
  Future<Appointment> getById(int id);
  Future<AppointmentOptions> getOptions();
  Future<Appointment> save(AppointmentInput input, {int? id});
}

class AppointmentInput {
  const AppointmentInput({
    required this.patientId,
    required this.companyId,
    required this.typeId,
    required this.sessionValue,
    required this.notes,
    required this.active,
  });

  final int patientId;
  final int? companyId;
  final int typeId;
  final String sessionValue;
  final String notes;
  final bool active;

  Map<String, dynamic> toJson() => {
    'paciente': patientId,
    'empresa': companyId,
    'tipo_atendimento': typeId,
    'valor_por_sessao': sessionValue,
    'observacoes': notes,
    'ativo': active,
  };
}

class AppointmentFailure implements Exception {
  const AppointmentFailure();
}
