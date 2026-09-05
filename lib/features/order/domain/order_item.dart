import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/cart/domain/cart_item.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required int productId,
    required String productName,
    required String productSlug,
    String? productImage,
    required String unitLabel,
    required double price,
    double? promoPrice,
    required double effectivePrice,
    required int quantity,
    required double subtotal,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

  factory OrderItem.fromCartItem(CartItem cartItem) => OrderItem(
        productId: cartItem.productId,
        productName: cartItem.productName,
        productSlug: cartItem.productSlug,
        productImage: cartItem.productImage,
        unitLabel: cartItem.unitLabel,
        price: cartItem.price,
        promoPrice: cartItem.promoPrice,
        effectivePrice: cartItem.effectivePrice,
        quantity: cartItem.quantity,
        subtotal: cartItem.totalPrice,
      );
}