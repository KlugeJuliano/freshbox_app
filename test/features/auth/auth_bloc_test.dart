import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';

import 'package:freshbox_app/features/auth/presentation/auth_bloc.dart';
import 'package:freshbox_app/features/auth/presentation/auth_event.dart';
import 'package:freshbox_app/features/auth/presentation/auth_state.dart';
import 'package:freshbox_app/features/auth/data/auth_repository.dart';
import 'package:freshbox_app/features/auth/data/auth_local_datasource.dart';
import 'package:freshbox_app/features/auth/domain/user.dart';
import 'package:freshbox_app/features/auth/domain/auth_tokens.dart';
import 'package:freshbox_app/features/auth/domain/login_credentials.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(LoginCredentials(
      email: 'test@test.com',
      password: 'password',
      rememberMe: false,
    ));
    registerFallbackValue(AuthTokens(accessToken: 'test-token'));
  });
  setUpAll(() {
    registerFallbackValue(LoginCredentials(
      email: 'test@test.com',
      password: 'password',
      rememberMe: false,
    ));
  });

  late AuthBloc authBloc;
  late _MockAuthRepository mockAuthRepository;
  late _MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockAuthRepository = _MockAuthRepository();
    mockLocalDataSource = _MockAuthLocalDataSource();
    authBloc = AuthBloc(mockAuthRepository, mockLocalDataSource);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    group('CheckAuthStatus', () {
      blocTest<AuthBloc, AuthState>(
        'emits [checking, unauthenticated] when no token stored',
        build: () {
          when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.checkAuthStatus()),
        expect: () => [
          const AuthState.checking(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [checking, authenticated] when valid token and me() succeeds',
        build: () {
          when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => 'valid-token');
          when(() => mockAuthRepository.me()).thenAnswer((_) async => User(
            id: 1,
            name: 'Admin',
            email: 'admin@test.com',
            role: 'admin',
            companyId: 1,
          ));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.checkAuthStatus()),
        expect: () => [
          const AuthState.checking(),
          predicate<AuthState>((s) => s.maybeWhen(authenticated: (_) => true, orElse: () => false)),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [checking, unauthenticated] when me() throws 401',
        build: () {
          when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => 'expired-token');
          when(() => mockAuthRepository.me()).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/auth/me'),
              response: Response(
                requestOptions: RequestOptions(path: '/auth/me'),
                statusCode: 401,
                data: {'message': 'Unauthorized'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.checkAuthStatus()),
        expect: () => [
          const AuthState.checking(),
          const AuthState.unauthenticated(),
        ],
      );
    });

    group('Login', () {
      const email = 'admin@test.com';
      const password = 'password123';
      const rememberMe = true;

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] on successful login',
        build: () {
          when(() => mockAuthRepository.login(any())).thenAnswer((_) async => AuthTokens(
            accessToken: 'new-token',
          ));
          when(() => mockLocalDataSource.saveTokens(any(), rememberMe: true)).thenAnswer((_) async {});
          when(() => mockAuthRepository.parseLoginUser(any())).thenReturn(User(
            id: 1,
            name: 'Admin',
            email: email,
            role: 'admin',
            companyId: 1,
          ));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEvent.login(
          email: email,
          password: password,
          rememberMe: rememberMe,
        )),
        expect: () => [
          const AuthState.loading(),
          predicate<AuthState>((s) => s.maybeWhen(authenticated: (_) => true, orElse: () => false)),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on 422 validation error',
        build: () {
          when(() => mockAuthRepository.login(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              response: Response(
                requestOptions: RequestOptions(path: '/auth/login'),
                statusCode: 422,
                data: {
                  'message': 'Validation error',
                  'errors': {'email': ['Invalid email format']},
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEvent.login(
          email: 'invalid-email',
          password: '123',
          rememberMe: false,
        )),
        expect: () => [
          const AuthState.loading(),
          predicate<AuthState>((s) => s.maybeWhen(error: (_) => true, orElse: () => false)),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on network error',
        build: () {
          when(() => mockAuthRepository.login(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              type: DioExceptionType.connectionTimeout,
              message: 'Connection timeout',
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEvent.login(
          email: email,
          password: password,
          rememberMe: rememberMe,
        )),
        expect: () => [
          const AuthState.loading(),
          predicate<AuthState>((s) => s.maybeWhen(error: (_) => true, orElse: () => false)),
        ],
      );
    });

    group('Logout', () {
      blocTest<AuthBloc, AuthState>(
        'calls logout, clears tokens, emits unauthenticated',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.logout()),
        expect: () => [
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits unauthenticated even if logout fails',
        build: () {
          when(() => mockAuthRepository.logout()).thenThrow(Exception('Network error'));
          when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.logout()),
        expect: () => [
          const AuthState.unauthenticated(),
        ],
      );
    });

    group('Admin Login', () {
      const adminEmail = 'admin@freshbox.com';
      const adminPassword = 'admin123';

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with admin role on successful admin login',
        build: () {
          when(() => mockAuthRepository.login(any())).thenAnswer((_) async => AuthTokens(
            accessToken: 'admin-token',
          ));
          when(() => mockLocalDataSource.saveTokens(any(), rememberMe: true)).thenAnswer((_) async {});
          when(() => mockAuthRepository.parseLoginUser(any())).thenReturn(User(
            id: 1,
            name: 'Admin User',
            email: adminEmail,
            role: 'admin',
            companyId: 1,
          ));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEvent.login(
          email: adminEmail,
          password: adminPassword,
          rememberMe: true,
        )),
        expect: () => [
          const AuthState.loading(),
          predicate<AuthState>((s) => s.maybeWhen(
            authenticated: (user) => user.role == 'admin',
            orElse: () => false,
          )),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.login(any())).called(1);
          verify(() => mockLocalDataSource.saveTokens(any(), rememberMe: true)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on 401 invalid credentials',
        build: () {
          when(() => mockAuthRepository.login(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              response: Response(
                requestOptions: RequestOptions(path: '/auth/login'),
                statusCode: 401,
                data: {'message': 'Credenciais inválidas'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEvent.login(
          email: adminEmail,
          password: 'wrong-password',
          rememberMe: false,
        )),
        expect: () => [
          const AuthState.loading(),
          predicate<AuthState>((s) => s.maybeWhen(
            error: (msg) => msg == 'Sessão expirada. Faça login novamente.',
            orElse: () => false,
          )),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on 403 forbidden (non-admin trying admin)',
        build: () {
          when(() => mockAuthRepository.login(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              response: Response(
                requestOptions: RequestOptions(path: '/auth/login'),
                statusCode: 403,
                data: {'message': 'Acesso negado. Apenas administradores.'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEvent.login(
          email: 'client@test.com',
          password: 'client123',
          rememberMe: false,
        )),
        expect: () => [
          const AuthState.loading(),
          predicate<AuthState>((s) => s.maybeWhen(
            error: (msg) => msg == 'Sessão expirada. Faça login novamente.',
            orElse: () => false,
          )),
        ],
      );
    });

    group('Token Expiry Handling', () {
      blocTest<AuthBloc, AuthState>(
        'emits unauthenticated when token expires during checkAuthStatus',
        build: () {
          when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => 'expired-token');
          when(() => mockAuthRepository.me()).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/auth/me'),
              response: Response(
                requestOptions: RequestOptions(path: '/auth/me'),
                statusCode: 401,
                data: {'message': 'Token expirado'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.checkAuthStatus()),
        expect: () => [
          const AuthState.checking(),
          const AuthState.unauthenticated(),
        ],
      );
    });
  });
}