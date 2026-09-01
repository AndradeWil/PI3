class Appointment {
  const Appointment({
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
}

class AppointmentOptions {
  const AppointmentOptions({
    required this.patients,
    required this.companies,
    required this.types,
  });

  final List<AppointmentOption> patients;
  final List<AppointmentOption> companies;
  final List<AppointmentTypeOption> types;
}

class AppointmentOption {
  const AppointmentOption({required this.id, required this.name});

  final int id;
  final String name;
}

class AppointmentTypeOption extends AppointmentOption {
  const AppointmentTypeOption({
    required super.id,
    required super.name,
    required this.defaultValue,
  });

  final String? defaultValue;
}
