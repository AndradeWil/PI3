import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/session_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../dtos/session_report_dto.dart';

class RemoteReportRepository implements ReportRepository {
  const RemoteReportRepository(this.client);

  final ApiClient client;

  Map<String, String> _query(ReportPeriod period) {
    final format = DateFormat('yyyy-MM-dd');
    return {
      'data_inicio': format.format(period.start),
      'data_fim': format.format(period.end),
    };
  }

  @override
  Future<SessionReport> getSessions(ReportPeriod period) async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/relatorios/sessoes/',
        queryParameters: {..._query(period), 'page_size': 100},
      );
      return SessionReportDto.fromJson(response.data!).toDomain();
    } on DioException {
      throw const ReportFailure();
    }
  }

  @override
  Future<String> downloadPdf(ReportPeriod period) async {
    try {
      final response = await client.dio.get<List<int>>(
        '/relatorios/sessoes/pdf/',
        queryParameters: _query(period),
        options: Options(responseType: ResponseType.bytes),
      );
      final directory = await getTemporaryDirectory();
      final format = DateFormat('yyyyMMdd');
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'relatorio-${format.format(period.start)}-${format.format(period.end)}.pdf',
      );
      await file.writeAsBytes(response.data!, flush: true);
      return file.path;
    } on DioException {
      throw const ReportFailure();
    }
  }
}
