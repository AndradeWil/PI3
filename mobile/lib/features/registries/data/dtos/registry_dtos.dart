import '../../domain/entities/registry_entities.dart';

class CompanyDto {
  const CompanyDto({
    required this.id,
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
  });

  factory CompanyDto.fromJson(Map<String, dynamic> json) => CompanyDto(
    id: json['id'] as int,
    name: json['nome'] as String? ?? '',
    contact: json['contato'] as String? ?? '',
    phone: json['telefone'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );

  final int id;
  final String name;
  final String contact;
  final String phone;
  final String email;

  Company toDomain() =>
      Company(id: id, name: name, contact: contact, phone: phone, email: email);
}

class ServiceTypeDto {
  const ServiceTypeDto({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultValue,
  });

  factory ServiceTypeDto.fromJson(Map<String, dynamic> json) => ServiceTypeDto(
    id: json['id'] as int,
    name: json['nome'] as String? ?? '',
    description: json['descricao'] as String? ?? '',
    defaultValue: json['valor_padrao'] as String?,
  );

  final int id;
  final String name;
  final String description;
  final String? defaultValue;

  ServiceType toDomain() => ServiceType(
    id: id,
    name: name,
    description: description,
    defaultValue: defaultValue,
  );
}
