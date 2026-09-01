import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../dtos/dashboard_dto.dart';

class RemoteDashboardRepository implements DashboardRepository {
  const RemoteDashboardRepository(this.client);

  final ApiClient client;

  @override
  Future<DashboardSummary> fetchSummary() async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/dashboard/',
      );
      final data = response.data;
      if (data == null) throw const DashboardFailure();
      return DashboardDto.fromJson(data).toDomain();
    } on DioException {
      throw const DashboardFailure();
    }
  }
}

class DashboardFailure implements Exception {
  const DashboardFailure();
}
