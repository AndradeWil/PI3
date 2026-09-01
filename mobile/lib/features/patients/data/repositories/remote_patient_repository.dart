import 'package:dio/dio.dart';

import '../../../../core/cache/local_cache.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';
import '../dtos/patient_dto.dart';

class RemotePatientRepository implements PatientRepository {
  const RemotePatientRepository(this.client, this.cache, this.setOffline);

  final ApiClient client;
  final LocalCache cache;
  final void Function(bool offline) setOffline;

  @override
  Future<List<Patient>> list({String search = ''}) async {
    final normalizedSearch = search.trim();
    final cacheKey = 'patients:list:${normalizedSearch.toLowerCase()}';
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/pacientes/',
        queryParameters: {
          'page_size': 100,
          if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
        },
      );
      final data = response.data!;
      await cache.write(cacheKey, data);
      setOffline(false);
      return _patients(data);
    } on DioException {
      final cached = await cache.read(cacheKey);
      if (cached != null) {
        setOffline(true);
        return _patients(cached);
      }
      throw const PatientFailure();
    }
  }

  List<Patient> _patients(Map<String, dynamic> data) {
    final results = data['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(PatientDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<Patient> getById(int id) async {
    final cacheKey = 'patients:detail:$id';
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/pacientes/$id/',
      );
      final data = response.data;
      if (data == null) throw const PatientFailure();
      await cache.write(cacheKey, data);
      setOffline(false);
      return PatientDto.fromJson(data).toDomain();
    } on DioException {
      final cached = await cache.read(cacheKey);
      if (cached != null) {
        setOffline(true);
        return PatientDto.fromJson(cached).toDomain();
      }
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
      await cache.deleteByPrefix('patients:');
      setOffline(false);
      return PatientDto.fromJson(data).toDomain();
    } on DioException {
      throw const PatientFailure();
    }
  }
}
