import 'package:intl/intl.dart';

import '../../domain/entities/active_appointment.dart';

class ActiveAppointmentDto {
  const ActiveAppointmentDto({
    required this.id,
    required this.patientName,
    required this.serviceType,
    required this.sessionValue,
  });

  factory ActiveAppointmentDto.fromJson(Map<String, dynamic> json) {
    return ActiveAppointmentDto(
      id: json['id'] as int,
      patientName: json['paciente_nome'] as String? ?? 'Paciente',
      serviceType: json['tipo_atendimento_nome'] as String? ?? '',
      sessionValue: json['valor_por_sessao'] as String? ?? '0',
    );
  }

  final int id;
  final String patientName;
  final String serviceType;
  final String sessionValue;

  ActiveAppointment toDomain() {
    return ActiveAppointment(
      id: id,
      patientName: patientName,
      serviceType: serviceType,
      sessionValue: NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(num.tryParse(sessionValue) ?? 0),
    );
  }
}
