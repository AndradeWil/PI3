import '../entities/patient.dart';

abstract interface class PatientRepository {
  Future<List<Patient>> list({String search = ''});
  Future<Patient> getById(int id);
  Future<Patient> save(PatientInput input, {int? id});
}

class PatientInput {
  const PatientInput({
    required this.name,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    required this.clinicalCondition,
    required this.dailyFrequency,
  });

  final String name;
  final int? age;
  final String phone;
  final String email;
  final String address;
  final String clinicalCondition;
  final int dailyFrequency;

  Map<String, dynamic> toJson() => {
    'nome': name,
    'idade': age,
    'telefone': phone,
    'email': email,
    'endereco': address,
    'quadro_clinico': clinicalCondition,
    'frequencia_por_dia': dailyFrequency,
  };
}

class PatientFailure implements Exception {
  const PatientFailure();
}
