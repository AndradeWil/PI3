class ScheduledSession {
  const ScheduledSession({
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
}
