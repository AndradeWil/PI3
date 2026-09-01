import '../entities/registry_entities.dart';

abstract interface class RegistryRepository {
  Future<List<Company>> listCompanies();
  Future<Company> saveCompany(CompanyInput input, {int? id});
  Future<void> deleteCompany(int id);
  Future<List<ServiceType>> listServiceTypes();
  Future<ServiceType> saveServiceType(ServiceTypeInput input, {int? id});
  Future<void> deleteServiceType(int id);
}

class CompanyInput {
  const CompanyInput({
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
  });

  final String name;
  final String contact;
  final String phone;
  final String email;

  Map<String, dynamic> toJson() => {
    'nome': name,
    'contato': contact,
    'telefone': phone,
    'email': email,
  };
}

class ServiceTypeInput {
  const ServiceTypeInput({
    required this.name,
    required this.description,
    required this.defaultValue,
  });

  final String name;
  final String description;
  final String? defaultValue;

  Map<String, dynamic> toJson() => {
    'nome': name,
    'descricao': description,
    'valor_padrao': defaultValue,
  };
}

class RegistryFailure implements Exception {
  const RegistryFailure({this.protected = false});

  final bool protected;
}
