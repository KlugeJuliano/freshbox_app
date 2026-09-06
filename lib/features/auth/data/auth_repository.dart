import 'package:freshbox_app/core/network/api_endpoint.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/auth/data/auth_local_datasource.dart';
import 'package:freshbox_app/features/auth/domain/auth_tokens.dart';
import 'package:freshbox_app/features/auth/domain/login_credentials.dart';
import 'package:freshbox_app/features/auth/domain/user.dart';

class AuthRepository {
  AuthRepository(this._dioClient);

  final DioClient _dioClient;

  Future<AuthTokens> login(LoginCredentials credentials) async {
    final response = await _dioClient.post(
      ApiEndpoint.login,
      data: {
        'email': credentials.email,
        'password': credentials.password,
      },
    );

    final json = response.data as Map<String, dynamic>;
    return AuthTokens.fromJson(json);
  }

  User parseLoginUser(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    return User.fromJson(userJson);
  }

  Future<User> me() async {
    final response = await _dioClient.get(ApiEndpoint.me);
    final json = response.data as Map<String, dynamic>;
    return User.fromJson(json);
  }

  Future<void> logout() async {
    await _dioClient.post(ApiEndpoint.logout);
  }
}