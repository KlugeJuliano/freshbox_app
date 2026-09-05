import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cart_repository.dart';
import '../domain/cart.dart';
import '../domain/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _repository;

  CartBloc(this._repository) : super(const CartState.initial()) {
    on<CartEvent>((event, emit) async {
      await event.when(
        loadCart: () => _onLoadCart(emit),
        addItem: (item) => _onAddItem(item, emit),
        removeItem: (productId) => _onRemoveItem(productId, emit),
        updateQuantity: (productId, quantity) => _onUpdateQuantity(productId, quantity, emit),
        clearCart: () => _onClearCart(emit),
      );
    });
  }

  Future<void> _onLoadCart(Emitter<CartState> emit) async {
    emit(const CartState.loading());
    try {
      final cart = await _repository.getCart();
      emit(CartState.loaded(cart));
    } catch (e) {
      emit(CartState.error(e.toString()));
    }
  }

  Future<void> _onAddItem(CartItem item, Emitter<CartState> emit) async {
    try {
      await _repository.addItem(item);
      final cart = await _repository.getCart();
      emit(CartState.loaded(cart));
    } catch (e) {
      emit(CartState.error(e.toString()));
    }
  }

  Future<void> _onRemoveItem(int productId, Emitter<CartState> emit) async {
    try {
      await _repository.removeItem(productId);
      final cart = await _repository.getCart();
      emit(CartState.loaded(cart));
    } catch (e) {
      emit(CartState.error(e.toString()));
    }
  }

  Future<void> _onUpdateQuantity(int productId, int quantity, Emitter<CartState> emit) async {
    try {
      await _repository.updateQuantity(productId, quantity);
      final cart = await _repository.getCart();
      emit(CartState.loaded(cart));
    } catch (e) {
      emit(CartState.error(e.toString()));
    }
  }

  Future<void> _onClearCart(Emitter<CartState> emit) async {
    try {
      await _repository.clearCart();
      emit(CartState.loaded(Cart.empty()));
    } catch (e) {
      emit(CartState.error(e.toString()));
    }
  }
}