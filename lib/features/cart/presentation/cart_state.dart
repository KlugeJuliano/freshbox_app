import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:freshbox_app/features/cart/domain/cart.dart';

part 'cart_state.freezed.dart';

@freezed
abstract class CartState with _$CartState {
  const factory CartState.initial() = _Initial;
  const factory CartState.loading() = _Loading;
  const factory CartState.loaded(Cart cart) = _Loaded;
  const factory CartState.error(String message) = _Error;
}