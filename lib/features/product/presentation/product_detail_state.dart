import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/product.dart';

part 'product_detail_state.freezed.dart';

@freezed
abstract class ProductDetailState with _$ProductDetailState {
  const factory ProductDetailState.initial() = _Initial;
  const factory ProductDetailState.loading() = _Loading;
  const factory ProductDetailState.loaded(Product product) = _Loaded;
  const factory ProductDetailState.error(String message) = _Error;
}
