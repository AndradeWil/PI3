import 'package:intl/intl.dart';

import '../../domain/entities/scheduled_session.dart';

class ScheduledSessionDto {
  const ScheduledSessionDto({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.address,
    required this.serviceType,
    required this.dateTime,
    required this.durationMinutes,
    required this.value,
    required this.attended,
    required this.notes,
  });

  factory ScheduledSessionDto.fromJson(Map<String, dynamic> json) {
    return ScheduledSessionDto(
      id: json['id'] as int,
      appointmentId: json['atendimento'] as int,
      patientId: json['paciente_id'] as int,
      patientName: json['paciente_nome'] as String? ?? 'Paciente',
      address: json['endereco'] as String? ?? '',
      serviceType: json['tipo_atendimento'] as String? ?? '',
      dateTime: DateTime.parse(json['data_hora'] as String),
      durationMinutes: json['duracao_minutos'] as int? ?? 0,
      value: json['valor_sessao'] as String? ?? '0',
      attended: json['compareceu'] as bool? ?? false,
      notes: json['observacoes'] as String? ?? '',
    );
  }

  final int id;
  final int appointmentId;
  final int patientId;
  final String patientName;
  final String address;
  final String serviceType;
  final DateTime dateTime;
  final int durationMinutes;
  final String value;
  final bool attended;
  final String notes;

  ScheduledSession toDomain() {
    return ScheduledSession(
      id: id,
      appointmentId: appointmentId,
      patientId: patientId,
      patientName: patientName,
      address: address,
      serviceType: serviceType,
      dateTime: dateTime.toLocal(),
      durationMinutes: durationMinutes,
      value: NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(num.tryParse(value) ?? 0),
      attended: attended,
      notes: notes,
    );
  }
}
