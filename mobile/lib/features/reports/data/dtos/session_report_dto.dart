import '../../domain/entities/session_report.dart';

class SessionReportDto {
  const SessionReportDto({required this.summary, required this.sessions});

  factory SessionReportDto.fromJson(Map<String, dynamic> json) {
    final summary = json['resumo'] as Map<String, dynamic>;
    return SessionReportDto(
      summary: ReportSummary(
        period: ReportPeriod(
          start: DateTime.parse(summary['data_inicio'] as String),
          end: DateTime.parse(summary['data_fim'] as String),
        ),
        sessionCount: summary['total_sessoes'] as int? ?? 0,
        totalValue:
            double.tryParse(summary['total_valor'] as String? ?? '') ?? 0,
        totalHours:
            double.tryParse(summary['total_horas'] as String? ?? '') ?? 0,
      ),
      sessions: (json['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ReportSession(
              id: item['id'] as int,
              patientName: item['paciente_nome'] as String? ?? '',
              serviceType: item['tipo_atendimento'] as String? ?? '',
              dateTime: DateTime.parse(item['data_hora'] as String).toLocal(),
              durationMinutes: item['duracao_minutos'] as int? ?? 0,
              value:
                  double.tryParse(item['valor_sessao'] as String? ?? '') ?? 0,
              attended: item['compareceu'] as bool? ?? false,
            ),
          )
          .toList(growable: false),
    );
  }

  final ReportSummary summary;
  final List<ReportSession> sessions;

  SessionReport toDomain() =>
      SessionReport(summary: summary, sessions: sessions);
}
