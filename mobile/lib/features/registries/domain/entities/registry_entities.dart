class Company {
  const Company({
    required this.id,
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
  });

  final int id;
  final String name;
  final String contact;
  final String phone;
  final String email;
}

class ServiceType {
  const ServiceType({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultValue,
  });

  final int id;
  final String name;
  final String description;
  final String? defaultValue;
}
