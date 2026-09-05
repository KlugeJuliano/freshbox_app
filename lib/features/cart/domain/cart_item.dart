import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:freshbox_app/features/product/domain/product.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required int productId,
    required String productName,
    required String productSlug,
    String? productImage,
    required String unitLabel,
    required double price,
    double? promoPrice,
    required double effectivePrice,
    required int quantity,
    required bool hasPromo,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);

  factory CartItem.fromProduct(Product product, {int quantity = 1}) => CartItem(
        productId: product.id,
        productName: product.name,
        productSlug: product.slug,
        productImage: product.images.thumb,
        unitLabel: product.unitLabel,
        price: product.price,
        promoPrice: product.promoPrice,
        effectivePrice: product.effectivePrice,
        quantity: quantity,
        hasPromo: product.hasPromo,
      );
}

extension CartItemExtensions on CartItem {
  double get totalPrice => effectivePrice * quantity;

  CartItem copyWithQuantity(int quantity) => copyWith(quantity: quantity);
}