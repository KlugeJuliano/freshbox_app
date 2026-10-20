import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';

class DioClient {
  Dio _dio;
  Future<String?> Function()? _tokenProvider;
  void Function()? _onUnauthorized;

  DioClient(this._dio) {
    // O adapter pode já ter sido configurado pelo chamador (testes via
    // HttpClientAdapter falso) — preserva; em produção é o adapter padrão.
    final preconfiguredAdapter = _dio.httpClientAdapter;
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          AppConstants.companyHeader: AppConstants.companyId,
        },
      ),
    );
    _dio.httpClientAdapter = preconfiguredAdapter;

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  void setTokenProvider(Future<String?> Function()? provider) {
    _tokenProvider = provider;
    if (provider != null) {
      _addAuthInterceptor();
    }
  }

  /// Disparado quando o servidor responde 401 em qualquer request autenticado
  /// (exceto /auth/login). Limpa a sessão no app e devolve o usuário à tela
  /// de login; não chama /auth/logout pois o token já é inválido no servidor.
  void setUnauthorizedHandler(void Function()? handler) {
    _onUnauthorized = handler;
  }

  void _addAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          final isLoginRequest =
              error.requestOptions.path.contains('/auth/login');
          // Credenciais inválidas no login são erro normal de formulário;
          // 401 em endpoint autenticado significa sessão expirada.
          if (!isLoginRequest) {
            _onUnauthorized?.call();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Helper para Multipart Upload (usado para fotos de produtos e banners)
  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> data,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _sendMultipart('POST', path,
          data: data, options: options, cancelToken: cancelToken);

  // PUT com FormData (necessário para update de banners com nova imagem)
  Future<Response> putMultipart(
    String path, {
    required Map<String, dynamic> data,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _sendMultipart('PUT', path,
          data: data, options: options, cancelToken: cancelToken);

  Future<Response> _sendMultipart(
    String method,
    String path, {
    required Map<String, dynamic> data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap(data);
      final response = await _dio.request(
        path,
        data: formData,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Método legacy - mantido para compatibilidade, mas delega ao provider
  void setToken(String token) {
    _tokenProvider = () async => token;
    _addAuthInterceptor();
  }

  // Método legacy - mantido para compatibilidade
  void removeToken() {
    _tokenProvider = null;
    _dio.options.headers.remove('Authorization');
  }
}
