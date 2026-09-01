class ActiveAppointment {
  const ActiveAppointment({
    required this.id,
    required this.patientName,
    required this.serviceType,
    required this.sessionValue,
  });

  final int id;
  final String patientName;
  final String serviceType;
  final String sessionValue;
}
