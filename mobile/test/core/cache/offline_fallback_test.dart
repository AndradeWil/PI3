import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/core/cache/local_cache.dart';
import 'package:physiomanage_mobile/core/network/api_client.dart';
import 'package:physiomanage_mobile/core/security/token_storage.dart';
import 'package:physiomanage_mobile/features/patients/data/repositories/remote_patient_repository.dart';
import 'package:physiomanage_mobile/features/schedule/data/repositories/remote_schedule_repository.dart';

void main() {
  test(
    'returns encrypted-cache patient data when the API is offline',
    () async {
      final cache = _MemoryCache();
      await cache.write('patients:list:', {
        'results': [
          {
            'id': 1,
            'nome': 'Maria Silva',
            'idade': 68,
            'telefone': '',
            'email': '',
            'endereco': '',
            'quadro_clinico': 'Reabilitacao',
            'frequencia_por_dia': 1,
            'empresa_nome': null,
          },
        ],
      });
      var offline = false;
      final repository = RemotePatientRepository(
        _offlineClient(),
        cache,
        (value) => offline = value,
      );

      final patients = await repository.list();

      expect(patients.single.name, 'Maria Silva');
      expect(offline, isTrue);
    },
  );

  test('returns cached schedule for the requested day when offline', () async {
    final cache = _MemoryCache();
    await cache.write('schedule:2026-09-01', {
      'results': [
        {
          'id': 1,
          'atendimento': 2,
          'paciente_id': 3,
          'paciente_nome': 'Maria Silva',
          'endereco': 'Rua A',
          'tipo_atendimento': 'Fisioterapia Motora',
          'data_hora': '2026-09-01T14:30:00-03:00',
          'duracao_minutos': 60,
          'valor_sessao': '120.00',
          'compareceu': false,
          'observacoes': '',
        },
      ],
    });
    var offline = false;
    final repository = RemoteScheduleRepository(
      _offlineClient(),
      cache,
      (value) => offline = value,
    );

    final sessions = await repository.listByDate(DateTime(2026, 9, 1));

    expect(sessions.single.patientName, 'Maria Silva');
    expect(offline, isTrue);
  });
}

ApiClient _offlineClient() {
  final client = ApiClient(_MemoryTokenStorage());
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'offline',
        ),
      ),
    ),
  );
  return client;
}

class _MemoryCache implements LocalCache {
  final values = <String, Map<String, dynamic>>{};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> deleteByPrefix(String prefix) async {
    values.removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    values[key] = value;
  }
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccess() async => null;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> save(TokenPair tokens) async {}
}
