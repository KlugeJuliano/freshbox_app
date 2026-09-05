import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:freshbox_app/features/order/domain/order.dart';

part 'checkout_state.freezed.dart';

@freezed
abstract class CheckoutState with _$CheckoutState {
  const factory CheckoutState.initial() = _Initial;
  const factory CheckoutState.loading() = _Loading;
  const factory CheckoutState.success(Order order) = _Success;
  const factory CheckoutState.error(String message) = _Error;
  const factory CheckoutState.validationError(Map<String, String> errors) = _ValidationError;
}