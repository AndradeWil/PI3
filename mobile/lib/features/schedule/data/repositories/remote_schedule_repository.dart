import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/cache/local_cache.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/active_appointment.dart';
import '../../domain/entities/scheduled_session.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../dtos/active_appointment_dto.dart';
import '../dtos/scheduled_session_dto.dart';

class RemoteScheduleRepository implements ScheduleRepository {
  const RemoteScheduleRepository(this.client, this.cache, this.setOffline);

  final ApiClient client;
  final LocalCache cache;
  final void Function(bool offline) setOffline;

  @override
  Future<List<ScheduledSession>> listByDate(DateTime date) async {
    final dateValue = DateFormat('yyyy-MM-dd').format(date);
    final cacheKey = 'schedule:$dateValue';
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/sessoes/',
        queryParameters: {'data': dateValue, 'page_size': 100},
      );
      final data = response.data!;
      await cache.write(cacheKey, data);
      setOffline(false);
      return _sessions(data);
    } on DioException {
      final cached = await cache.read(cacheKey);
      if (cached != null) {
        setOffline(true);
        return _sessions(cached);
      }
      throw const ScheduleFailure();
    }
  }

  List<ScheduledSession> _sessions(Map<String, dynamic> data) {
    final results = data['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(ScheduledSessionDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<ActiveAppointment>> listActiveAppointments() async {
    try {
      final response = await client.dio.get<List<dynamic>>(
        '/atendimentos/ativos/',
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActiveAppointmentDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
    } on DioException {
      throw const ScheduleFailure();
    }
  }

  @override
  Future<ScheduledSession> quickClockIn(
    int appointmentId,
    String idempotencyKey,
  ) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/atendimentos/$appointmentId/bater-ponto/',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      final data = response.data;
      if (data == null) throw const ScheduleFailure();
      await cache.deleteByPrefix('schedule:');
      setOffline(false);
      return ScheduledSessionDto.fromJson(data).toDomain();
    } on DioException {
      throw const ScheduleFailure();
    }
  }

  @override
  Future<void> markAttended(int sessionId) async {
    try {
      await client.dio.patch<void>(
        '/sessoes/$sessionId/',
        data: {'compareceu': true},
      );
      await cache.deleteByPrefix('schedule:');
      setOffline(false);
    } on DioException {
      throw const ScheduleFailure();
    }
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    try {
      await client.dio.delete<void>('/sessoes/$sessionId/');
      await cache.deleteByPrefix('schedule:');
      setOffline(false);
    } on DioException {
      throw const ScheduleFailure();
    }
  }
}
