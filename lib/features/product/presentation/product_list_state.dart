import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/product.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'product_list_type.dart';

part 'product_list_state.freezed.dart';

@freezed
abstract class ProductListState with _$ProductListState {
  const factory ProductListState.initial() = _Initial;

  const factory ProductListState.loading({ProductListType? currentType}) =
      _Loading;

  const factory ProductListState.loaded({
    required ProductListType type,
    required Paginated<Product> products,
    required bool hasReachedMax,
  }) = _Loaded;

  const factory ProductListState.error(String message,
      {ProductListType? failedType}) = _Error;
}
