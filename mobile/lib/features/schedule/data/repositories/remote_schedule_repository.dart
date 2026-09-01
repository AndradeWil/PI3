import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/scheduled_session.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../dtos/scheduled_session_dto.dart';

class RemoteScheduleRepository implements ScheduleRepository {
  const RemoteScheduleRepository(this.client);

  final ApiClient client;

  @override
  Future<List<ScheduledSession>> listByDate(DateTime date) async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/sessoes/',
        queryParameters: {
          'data': DateFormat('yyyy-MM-dd').format(date),
          'page_size': 100,
        },
      );
      final results = response.data?['results'] as List<dynamic>? ?? const [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(ScheduledSessionDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
    } on DioException {
      throw const ScheduleFailure();
    }
  }
}
