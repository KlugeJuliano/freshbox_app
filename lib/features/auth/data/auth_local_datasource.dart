import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:freshbox_app/features/auth/domain/auth_tokens.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'freshbox_auth_token';
  String? _memoryToken;

  Future<void> saveTokens(AuthTokens tokens, {required bool rememberMe}) async {
    if (rememberMe) {
      _memoryToken = null;
      await _storage.write(key: _tokenKey, value: tokens.accessToken);
    } else {
      _memoryToken = tokens.accessToken;
    }
  }

  Future<String?> getToken() async {
    if (_memoryToken != null) {
      return _memoryToken;
    }
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearTokens() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
  }
}