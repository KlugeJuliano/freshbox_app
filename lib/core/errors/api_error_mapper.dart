import 'package:dio/dio.dart';

String mapApiException(DioException e) {
  // 422 Laravel: { message, errors: { campo: [msg] } } -> extrai primeira msg
  if (e.response?.statusCode == 422 && e.response?.data != null) {
    final data = e.response!.data as Map<String, dynamic>;
    final errors = data['errors'] as Map<String, dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      // Pega a primeira mensagem de erro
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first as String;
      }
    }
    return data['message'] as String? ?? 'Dados inválidos. Verifique os campos.';
  }

  // 401/403 - Auth errors
  if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
    return 'Sessão expirada. Faça login novamente.';
  }

  // 404 - Not found
  if (e.response?.statusCode == 404) {
    return 'Endereço não encontrado. Tente novamente.';
  }

  // 5xx - Server errors
  if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
    return 'Erro no servidor. Tente novamente em alguns instantes.';
  }

  // Network/timeout errors
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.message?.contains('SocketException') == true ||
      e.message?.contains('Connection refused') == true) {
    return 'Sem conexão. Verifique sua internet e tente novamente.';
  }

  // Fallback
  return e.message?.isNotEmpty == true ? e.message! : 'Erro inesperado. Tente novamente.';
}