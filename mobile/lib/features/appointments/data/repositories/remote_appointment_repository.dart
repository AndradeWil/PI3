import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../dtos/appointment_dto.dart';

class RemoteAppointmentRepository implements AppointmentRepository {
  const RemoteAppointmentRepository(this.client);

  final ApiClient client;

  @override
  Future<List<Appointment>> list() async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/atendimentos/',
        queryParameters: {'page_size': 100},
      );
      return (response.data?['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppointmentDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
    } on DioException {
      throw const AppointmentFailure();
    }
  }

  @override
  Future<Appointment> getById(int id) async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/atendimentos/$id/',
      );
      return AppointmentDto.fromJson(response.data!).toDomain();
    } on DioException {
      throw const AppointmentFailure();
    }
  }

  @override
  Future<AppointmentOptions> getOptions() async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/atendimentos/opcoes/',
      );
      return AppointmentOptionsDto.fromJson(response.data!).toDomain();
    } on DioException {
      throw const AppointmentFailure();
    }
  }

  @override
  Future<Appointment> save(AppointmentInput input, {int? id}) async {
    try {
      final response = id == null
          ? await client.dio.post<Map<String, dynamic>>(
              '/atendimentos/',
              data: input.toJson(),
            )
          : await client.dio.patch<Map<String, dynamic>>(
              '/atendimentos/$id/',
              data: input.toJson(),
            );
      return AppointmentDto.fromJson(response.data!).toDomain();
    } on DioException {
      throw const AppointmentFailure();
    }
  }
}
