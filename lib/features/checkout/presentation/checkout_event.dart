import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/order/domain/checkout_form.dart';

part 'checkout_event.freezed.dart';

@freezed
abstract class CheckoutEvent with _$CheckoutEvent {
  const factory CheckoutEvent.submitOrder({
    required CheckoutForm form,
    required List<CartItem> items,
  }) = _SubmitOrder;
}