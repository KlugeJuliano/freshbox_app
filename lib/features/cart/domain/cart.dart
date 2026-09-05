import 'package:freezed_annotation/freezed_annotation.dart';

import 'cart_item.dart';

part 'cart.freezed.dart';
part 'cart.g.dart';

@freezed
abstract class Cart with _$Cart {
  const factory Cart({required List<CartItem> items}) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);

  factory Cart.empty() => const Cart(items: []);
}

extension CartExtensions on Cart {
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  CartItem? findByProductId(int productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  Cart copyWithItem(CartItem item) {
    final existingIndex = items.indexWhere((i) => i.productId == item.productId);
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(items);
      if (item.quantity <= 0) {
        updatedItems.removeAt(existingIndex);
      } else {
        updatedItems[existingIndex] = item;
      }
      return Cart(items: updatedItems);
    } else if (item.quantity > 0) {
      return Cart(items: [...items, item]);
    }
    return this;
  }

  Cart removeItem(int productId) {
    return Cart(items: items.where((item) => item.productId != productId).toList());
  }

  Cart clear() => Cart.empty();
}