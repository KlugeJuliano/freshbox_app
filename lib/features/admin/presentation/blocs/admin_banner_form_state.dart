import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/admin/domain/banner.dart';

part 'admin_banner_form_state.freezed.dart';

@freezed
abstract class AdminBannerFormState with _$AdminBannerFormState {
  const factory AdminBannerFormState.initial() = _Initial;
  const factory AdminBannerFormState.submitting() = _Submitting;
  // `banner` vem null no caso de delete bem-sucedido.
  const factory AdminBannerFormState.success(
    Banner? banner,
    String message,
  ) = _Success;
  const factory AdminBannerFormState.error(String message) = _Error;
}
