import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/financial_summary.dart';
import '../../domain/repositories/finance_repository.dart';
import '../dtos/financial_summary_dto.dart';

class RemoteFinanceRepository implements FinanceRepository {
  const RemoteFinanceRepository(this.client);

  final ApiClient client;

  @override
  Future<FinancialSummary> getSummary(FinancialPeriod period) async {
    try {
      final format = DateFormat('yyyy-MM-dd');
      final response = await client.dio.get<Map<String, dynamic>>(
        '/financeiro/resumo/',
        queryParameters: {
          'data_inicio': format.format(period.start),
          'data_fim': format.format(period.end),
        },
      );
      return FinancialSummaryDto.fromJson(response.data!).toDomain();
    } on DioException {
      throw const FinanceFailure();
    }
  }
}
