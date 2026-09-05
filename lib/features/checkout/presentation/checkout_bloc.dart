import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_state.dart';
import 'package:freshbox_app/features/order/data/order_repository.dart';
import 'package:freshbox_app/features/order/domain/checkout_form.dart';
import 'package:freshbox_app/core/errors/api_error_mapper.dart';
import 'package:freshbox_app/core/network/api_exception.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final OrderRepository _repository;
  final CartBloc _cartBloc;

  CheckoutBloc(this._repository, this._cartBloc) : super(const CheckoutState.initial()) {
    on<CheckoutEvent>((event, emit) async {
      await event.when(
        submitOrder: (form, items) => _onSubmitOrder(form, items, emit),
      );
    });
  }

  Future<void> _onSubmitOrder(
    CheckoutForm form,
    List<CartItem> items,
    Emitter<CheckoutState> emit,
  ) async {
    // Guarda contra duplo envio
    if (state.maybeWhen(loading: () => true, orElse: () => false)) return;

    final validationErrors = form.validate();
    if (validationErrors.isNotEmpty) {
      emit(CheckoutState.validationError(validationErrors));
      return;
    }

    emit(const CheckoutState.loading());

    try {
      final order = await _repository.createOrder(form, items);
      // Limpa o carrinho após sucesso do backend
      _cartBloc.add(const CartEvent.clearCart());
      emit(CheckoutState.success(order));
    } on ApiException catch (e) {
      emit(CheckoutState.error(e.message.isNotEmpty ? e.message : 'Erro inesperado. Tente novamente.'));
    } on DioException catch (e) {
      emit(CheckoutState.error(mapApiException(e)));
    } catch (e) {
      log('Checkout error: $e');
      emit(CheckoutState.error('Erro inesperado. Tente novamente.'));
    }
  }
}