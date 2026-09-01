import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/security/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this.client, this.tokenStorage);

  final ApiClient client;
  final TokenStorage tokenStorage;

  @override
  Future<bool> restoreSession() async {
    if (await tokenStorage.readRefresh() == null) return false;
    try {
      await client.dio.get<Map<String, dynamic>>('/me/');
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await tokenStorage.clear();
        return false;
      }
      return true;
    }
  }

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/auth/token/',
        data: {'username': username, 'password': password},
      );
      final data = response.data;
      if (data == null ||
          data['access'] is! String ||
          data['refresh'] is! String) {
        throw const AuthenticationFailure('Resposta de autenticacao invalida.');
      }
      await tokenStorage.save(
        TokenPair(
          access: data['access'] as String,
          refresh: data['refresh'] as String,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const AuthenticationFailure('Usuario ou senha invalidos.');
      }
      throw const AuthenticationFailure(
        'Nao foi possivel conectar ao PhysioManage.',
      );
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await tokenStorage.readRefresh();
    try {
      if (refresh != null) {
        await client.dio.post<void>(
          '/auth/logout/',
          data: {'refresh': refresh},
        );
      }
    } finally {
      await tokenStorage.clear();
    }
  }
}
