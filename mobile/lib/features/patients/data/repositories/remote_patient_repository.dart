import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';
import '../dtos/patient_dto.dart';

class RemotePatientRepository implements PatientRepository {
  const RemotePatientRepository(this.client);

  final ApiClient client;

  @override
  Future<List<Patient>> list({String search = ''}) async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/pacientes/',
        queryParameters: {
          'page_size': 100,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final results = response.data?['results'] as List<dynamic>? ?? const [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(PatientDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
    } on DioException {
      throw const PatientFailure();
    }
  }

  @override
  Future<Patient> getById(int id) async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/pacientes/$id/',
      );
      final data = response.data;
      if (data == null) throw const PatientFailure();
      return PatientDto.fromJson(data).toDomain();
    } on DioException {
      throw const PatientFailure();
    }
  }

  @override
  Future<Patient> save(PatientInput input, {int? id}) async {
    try {
      final response = id == null
          ? await client.dio.post<Map<String, dynamic>>(
              '/pacientes/',
              data: input.toJson(),
            )
          : await client.dio.patch<Map<String, dynamic>>(
              '/pacientes/$id/',
              data: input.toJson(),
            );
      final data = response.data;
      if (data == null) throw const PatientFailure();
      return PatientDto.fromJson(data).toDomain();
    } on DioException {
      throw const PatientFailure();
    }
  }
}
