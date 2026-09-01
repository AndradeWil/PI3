import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/registry_entities.dart';
import '../../domain/repositories/registry_repository.dart';
import '../dtos/registry_dtos.dart';

class RemoteRegistryRepository implements RegistryRepository {
  const RemoteRegistryRepository(this.client);

  final ApiClient client;

  @override
  Future<List<Company>> listCompanies() =>
      _list('/empresas/', (json) => CompanyDto.fromJson(json).toDomain());

  @override
  Future<List<ServiceType>> listServiceTypes() => _list(
    '/tipos-atendimento/',
    (json) => ServiceTypeDto.fromJson(json).toDomain(),
  );

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) mapper,
  ) async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page_size': 100},
      );
      return (response.data?['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(mapper)
          .toList(growable: false);
    } on DioException {
      throw const RegistryFailure();
    }
  }

  @override
  Future<Company> saveCompany(CompanyInput input, {int? id}) async {
    final data = await _save('/empresas/', input.toJson(), id);
    return CompanyDto.fromJson(data).toDomain();
  }

  @override
  Future<ServiceType> saveServiceType(ServiceTypeInput input, {int? id}) async {
    final data = await _save('/tipos-atendimento/', input.toJson(), id);
    return ServiceTypeDto.fromJson(data).toDomain();
  }

  Future<Map<String, dynamic>> _save(
    String path,
    Map<String, dynamic> data,
    int? id,
  ) async {
    try {
      final response = id == null
          ? await client.dio.post<Map<String, dynamic>>(path, data: data)
          : await client.dio.patch<Map<String, dynamic>>(
              '$path$id/',
              data: data,
            );
      return response.data!;
    } on DioException {
      throw const RegistryFailure();
    }
  }

  @override
  Future<void> deleteCompany(int id) => _delete('/empresas/$id/');

  @override
  Future<void> deleteServiceType(int id) => _delete('/tipos-atendimento/$id/');

  Future<void> _delete(String path) async {
    try {
      await client.dio.delete<void>(path);
    } on DioException catch (error) {
      throw RegistryFailure(protected: error.response?.statusCode == 409);
    }
  }
}
