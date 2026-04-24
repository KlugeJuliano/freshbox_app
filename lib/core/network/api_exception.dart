import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Tempo de conexão esgotado. Verifique sua internet.');
      case DioExceptionType.badResponse:
        return _handleError(error.response?.statusCode, error.response?.data);
      case DioExceptionType.cancel:
        return ApiException(message: 'Requisição cancelada.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'Sem conexão com a internet.');
      default:
        return ApiException(message: 'Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  static ApiException _handleError(int? statusCode, dynamic error) {
    switch (statusCode) {
      case 400:
        return ApiException(
          message: error?['message'] ?? 'Requisição inválida.',
          statusCode: statusCode,
          data: error,
        );
      case 401:
        return ApiException(
          message: 'Sessão expirada. Por favor, faça login novamente.',
          statusCode: statusCode,
        );
      case 403:
        return ApiException(
          message: 'Você não tem permissão para acessar este recurso.',
          statusCode: statusCode,
        );
      case 404:
        return ApiException(
          message: 'Recurso não encontrado.',
          statusCode: statusCode,
        );
      case 422:
        return ApiException(
          message: error?['message'] ?? 'Erro de validação.',
          statusCode: statusCode,
          data: error?['errors'],
        );
      case 500:
        return ApiException(
          message: 'Erro interno no servidor. Tente novamente mais tarde.',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          message: 'Ocorreu um erro inesperado ($statusCode).',
          statusCode: statusCode,
        );
    }
  }
}
