import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_state.dart';
import 'package:freshbox_app/features/order/data/order_repository.dart';
import 'package:freshbox_app/features/order/domain/checkout_form.dart';
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
      emit(CheckoutState.error(_mapApiException(e)));
    } catch (e) {
      log('Checkout error: $e');
      emit(CheckoutState.error(_mapGenericError(e)));
    }
  }

  String _mapApiException(ApiException e) {
    // 422 - Validation errors from Laravel
    if (e.statusCode == 422 && e.data != null) {
      final errors = e.data as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        // Pega a primeira mensagem de erro
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first as String;
        }
      }
      return e.message;
    }

    // 401/403 - Auth errors
    if (e.statusCode == 401 || e.statusCode == 403) {
      return 'Sessão expirada. Faça login novamente.';
    }

    // 404 - Not found
    if (e.statusCode == 404) {
      return 'Endereço não encontrado. Tente novamente.';
    }

    // 5xx - Server errors
    if (e.statusCode != null && e.statusCode! >= 500) {
      return 'Erro no servidor. Tente novamente em alguns instantes.';
    }

    // Network/timeout errors
    if (e.message.contains('timeout') || e.message.contains('SocketException') || e.message.contains('Connection refused')) {
      return 'Sem conexão. Verifique sua internet e tente novamente.';
    }

    // Fallback
    return e.message.isNotEmpty ? e.message : 'Erro inesperado. Tente novamente.';
  }

  String _mapGenericError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('sockettexception') || msg.contains('connection refused')) {
      return 'Sem conexão. Verifique sua internet e tente novamente.';
    }
    return 'Erro inesperado. Tente novamente.';
  }
}