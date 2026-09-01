import '../../domain/entities/appointment.dart';

class AppointmentDto {
  const AppointmentDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.companyId,
    required this.companyName,
    required this.typeId,
    required this.typeName,
    required this.sessionValue,
    required this.notes,
    required this.active,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: json['id'] as int,
      patientId: json['paciente'] as int,
      patientName: json['paciente_nome'] as String? ?? '',
      companyId: json['empresa'] as int?,
      companyName: json['empresa_nome'] as String?,
      typeId: json['tipo_atendimento'] as int,
      typeName: json['tipo_atendimento_nome'] as String? ?? '',
      sessionValue: json['valor_por_sessao'] as String? ?? '0',
      notes: json['observacoes'] as String? ?? '',
      active: json['ativo'] as bool? ?? false,
    );
  }

  final int id;
  final int patientId;
  final String patientName;
  final int? companyId;
  final String? companyName;
  final int typeId;
  final String typeName;
  final String sessionValue;
  final String notes;
  final bool active;

  Appointment toDomain() => Appointment(
    id: id,
    patientId: patientId,
    patientName: patientName,
    companyId: companyId,
    companyName: companyName,
    typeId: typeId,
    typeName: typeName,
    sessionValue: sessionValue,
    notes: notes,
    active: active,
  );
}

class AppointmentOptionsDto {
  const AppointmentOptionsDto({
    required this.patients,
    required this.companies,
    required this.types,
  });

  factory AppointmentOptionsDto.fromJson(Map<String, dynamic> json) {
    AppointmentOption option(dynamic item) {
      final data = item as Map<String, dynamic>;
      return AppointmentOption(
        id: data['id'] as int,
        name: data['nome'] as String,
      );
    }

    return AppointmentOptionsDto(
      patients: (json['pacientes'] as List<dynamic>).map(option).toList(),
      companies: (json['empresas'] as List<dynamic>).map(option).toList(),
      types: (json['tipos_atendimento'] as List<dynamic>).map((item) {
        final data = item as Map<String, dynamic>;
        return AppointmentTypeOption(
          id: data['id'] as int,
          name: data['nome'] as String,
          defaultValue: data['valor_padrao'] as String?,
        );
      }).toList(),
    );
  }

  final List<AppointmentOption> patients;
  final List<AppointmentOption> companies;
  final List<AppointmentTypeOption> types;

  AppointmentOptions toDomain() => AppointmentOptions(
    patients: patients,
    companies: companies,
    types: types,
  );
}
