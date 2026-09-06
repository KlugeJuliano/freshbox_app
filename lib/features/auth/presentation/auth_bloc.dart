import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:freshbox_app/core/errors/api_error_mapper.dart';
import 'package:freshbox_app/features/auth/data/auth_local_datasource.dart';
import 'package:freshbox_app/features/auth/data/auth_repository.dart';
import 'package:freshbox_app/features/auth/domain/login_credentials.dart';
import 'package:freshbox_app/features/auth/presentation/auth_event.dart';
import 'package:freshbox_app/features/auth/presentation/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final AuthLocalDataSource _localDataSource;

  AuthBloc(this._repository, this._localDataSource) : super(const AuthState.checking()) {
    on<AuthEvent>((event, emit) async {
      await event.when(
        checkAuthStatus: () => _onCheckAuthStatus(emit),
        login: (email, password, rememberMe) => _onLogin(email, password, rememberMe, emit),
        logout: () => _onLogout(emit),
      );
    });
  }

  Future<void> _onCheckAuthStatus(Emitter<AuthState> emit) async {
    emit(const AuthState.checking());
    try {
      final token = await _localDataSource.getToken();
      if (token == null) {
        emit(const AuthState.unauthenticated());
        return;
      }
      final user = await _repository.me();
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogin(String email, String password, bool rememberMe, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final credentials = LoginCredentials(email: email, password: password, rememberMe: rememberMe);
      final tokens = await _repository.login(credentials);
      await _localDataSource.saveTokens(tokens, rememberMe: rememberMe);
      final user = _repository.parseLoginUser(tokens.toJson());
      emit(AuthState.authenticated(user));
    } on DioException catch (e) {
      emit(AuthState.error(mapApiException(e)));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onLogout(Emitter<AuthState> emit) async {
    try {
      await _repository.logout();
    } catch (_) {
      // Ignore logout errors
    }
    await _localDataSource.clearTokens();
    emit(const AuthState.unauthenticated());
  }
}