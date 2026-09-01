import 'package:intl/intl.dart';

import '../../domain/entities/dashboard_summary.dart';

class DashboardDto {
  const DashboardDto({
    required this.monthlyRevenue,
    required this.activePatients,
    required this.todaySessions,
    required this.alerts,
    required this.nextSession,
    required this.todayAgenda,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      monthlyRevenue: json['monthly_revenue'] as String? ?? '0',
      activePatients: json['active_patients'] as int? ?? 0,
      todaySessions: json['today_sessions'] as int? ?? 0,
      alerts: json['alerts'] as int? ?? 0,
      nextSession: json['next_session'] is Map<String, dynamic>
          ? SessionDto.fromJson(json['next_session'] as Map<String, dynamic>)
          : null,
      todayAgenda: (json['today_agenda'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SessionDto.fromJson)
          .toList(growable: false),
    );
  }

  final String monthlyRevenue;
  final int activePatients;
  final int todaySessions;
  final int alerts;
  final SessionDto? nextSession;
  final List<SessionDto> todayAgenda;

  DashboardSummary toDomain() {
    final currency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return DashboardSummary(
      monthlyRevenue: currency.format(num.tryParse(monthlyRevenue) ?? 0),
      activePatients: activePatients,
      todaySessions: todaySessions,
      alerts: alerts,
      nextSession: nextSession?.toDomain(SessionStatus.next),
      todayAgenda: todayAgenda
          .map((session) => session.toDomain(SessionStatus.confirmed))
          .toList(growable: false),
    );
  }
}

class SessionDto {
  const SessionDto({
    required this.time,
    required this.patientName,
    required this.location,
    required this.attended,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      time: json['time'] as String? ?? '--:--',
      patientName: json['patient_name'] as String? ?? 'Paciente',
      location: json['location'] as String? ?? '',
      attended: json['attended'] as bool? ?? false,
    );
  }

  final String time;
  final String patientName;
  final String location;
  final bool attended;

  ScheduledSession toDomain(SessionStatus defaultStatus) {
    return ScheduledSession(
      time: time,
      patientName: patientName,
      location: location.isEmpty ? 'Endereco nao informado' : location,
      status: attended ? SessionStatus.confirmed : defaultStatus,
    );
  }
}
