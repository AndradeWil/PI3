import '../../domain/entities/patient.dart';

class PatientDto {
  const PatientDto({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    required this.clinicalCondition,
    required this.dailyFrequency,
    required this.companyName,
  });

  factory PatientDto.fromJson(Map<String, dynamic> json) {
    return PatientDto(
      id: json['id'] as int,
      name: json['nome'] as String? ?? '',
      age: json['idade'] as int?,
      phone: json['telefone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['endereco'] as String? ?? '',
      clinicalCondition: json['quadro_clinico'] as String? ?? '',
      dailyFrequency: json['frequencia_por_dia'] as int? ?? 1,
      companyName: json['empresa_nome'] as String?,
    );
  }

  final int id;
  final String name;
  final int? age;
  final String phone;
  final String email;
  final String address;
  final String clinicalCondition;
  final int dailyFrequency;
  final String? companyName;

  Patient toDomain() {
    return Patient(
      id: id,
      name: name,
      age: age,
      phone: phone,
      email: email,
      address: address,
      clinicalCondition: clinicalCondition,
      dailyFrequency: dailyFrequency,
      companyName: companyName,
    );
  }
}
