import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:freshbox_app/features/cart/domain/cart_item.dart';

part 'cart_event.freezed.dart';

@freezed
abstract class CartEvent with _$CartEvent {
  const factory CartEvent.loadCart() = _LoadCart;
  const factory CartEvent.addItem(CartItem item) = _AddItem;
  const factory CartEvent.removeItem(int productId) = _RemoveItem;
  const factory CartEvent.updateQuantity(int productId, int quantity) = _UpdateQuantity;
  const factory CartEvent.clearCart() = _ClearCart;
}