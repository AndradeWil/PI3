import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/active_appointment.dart';
import '../../domain/entities/scheduled_session.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../dtos/active_appointment_dto.dart';
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
    } on DioException {
      throw const ScheduleFailure();
    }
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    try {
      await client.dio.delete<void>('/sessoes/$sessionId/');
    } on DioException {
      throw const ScheduleFailure();
    }
  }
}
