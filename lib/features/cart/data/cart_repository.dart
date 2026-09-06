import 'dart:convert';

import 'package:freshbox_app/core/constants/app_constants.dart';
import 'package:freshbox_app/core/storage/local_storage.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/domain/cart_item.dart';

class CartRepository {
  CartRepository(this._localStorage);

  final LocalStorage _localStorage;

  String _getCartKey(String companyId) => '${AppConstants.cartKey}_$companyId';

  Future<String> _getCompanyId() async {
    final savedCompanyId = _localStorage.getString(AppConstants.companyIdKey);
    return savedCompanyId ?? AppConstants.companyId;
  }

  Future<Cart> getCart() async {
    final companyId = await _getCompanyId();
    final cartKey = _getCartKey(companyId);
    final jsonString = _localStorage.getString(cartKey);

    if (jsonString == null || jsonString.isEmpty) {
      return Cart.empty();
    }

    try {
      return Cart.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      return Cart.empty();
    }
  }

  Future<void> saveCart(Cart cart) async {
    final companyId = await _getCompanyId();
    final cartKey = _getCartKey(companyId);
    await _localStorage.setString(cartKey, jsonEncode(cart.toJson()));
  }

  Future<void> clearCart() async {
    final companyId = await _getCompanyId();
    final cartKey = _getCartKey(companyId);
    await _localStorage.remove(cartKey);
  }

  Future<void> addItem(CartItem item) async {
    final cart = await getCart();
    final existingItem = cart.findByProductId(item.productId);

    Cart updatedCart;
    if (existingItem != null) {
      updatedCart = cart.copyWithItem(
        existingItem.copyWithQuantity(existingItem.quantity + item.quantity),
      );
    } else {
      updatedCart = cart.copyWithItem(item);
    }

    await saveCart(updatedCart);
  }

  Future<void> removeItem(int productId) async {
    final cart = await getCart();
    final updatedCart = cart.removeItem(productId);
    await saveCart(updatedCart);
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    final cart = await getCart();
    final item = cart.findByProductId(productId);

    if (item != null) {
      final updatedCart = cart.copyWithItem(item.copyWithQuantity(quantity));
      await saveCart(updatedCart);
    }
  }

  Future<void> setCompanyId(String companyId) async {
    await _localStorage.setString(AppConstants.companyIdKey, companyId);
  }
}