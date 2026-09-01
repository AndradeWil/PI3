import 'dart:async';

import 'package:dio/dio.dart';

import '../config/environment.dart';
import '../security/token_storage.dart';

class ApiClient {
  ApiClient(this.tokenStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: Environment.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _authorize,
        onError: _refreshAfterUnauthorized,
      ),
    );
  }

  final TokenStorage tokenStorage;
  final Dio dio;
  Future<TokenPair?>? _refreshing;

  Future<void> _authorize(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await tokenStorage.readAccess();
    if (access != null && !options.path.contains('/auth/token/')) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  Future<void> _refreshAfterUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra['retried'] == true ||
        request.path.contains('/auth/token/')) {
      handler.next(error);
      return;
    }

    _refreshing ??= _refreshTokens();
    final tokens = await _refreshing;
    _refreshing = null;
    if (tokens == null) {
      handler.next(error);
      return;
    }

    request.extra['retried'] = true;
    request.headers['Authorization'] = 'Bearer ${tokens.access}';
    try {
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<TokenPair?> _refreshTokens() async {
    final refresh = await tokenStorage.readRefresh();
    if (refresh == null) return null;

    try {
      final refreshDio = Dio(BaseOptions(baseUrl: Environment.apiBaseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final data = response.data;
      if (data == null || data['access'] is! String) return null;
      final tokens = TokenPair(
        access: data['access'] as String,
        refresh: data['refresh'] as String? ?? refresh,
      );
      await tokenStorage.save(tokens);
      return tokens;
    } on DioException {
      await tokenStorage.clear();
      return null;
    }
  }
}
