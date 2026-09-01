import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/data_intelligence.dart';
import '../../domain/repositories/intelligence_repository.dart';
import '../dtos/data_intelligence_dto.dart';

class RemoteIntelligenceRepository implements IntelligenceRepository {
  const RemoteIntelligenceRepository(this.client);

  final ApiClient client;

  @override
  Future<DataIntelligence> getSummary() async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/inteligencia/resumo/',
      );
      return DataIntelligenceDto.fromJson(response.data!).toDomain();
    } on DioException {
      throw const IntelligenceFailure();
    }
  }
}
