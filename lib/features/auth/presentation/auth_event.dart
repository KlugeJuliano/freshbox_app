import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
abstract class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkAuthStatus() = _CheckAuthStatus;
  const factory AuthEvent.login({
    required String email,
    required String password,
    required bool rememberMe,
  }) = _Login;
  const factory AuthEvent.logout() = _Logout;
}