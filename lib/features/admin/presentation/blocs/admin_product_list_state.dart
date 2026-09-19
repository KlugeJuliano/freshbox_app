import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/product/domain/product.dart';

part 'admin_product_list_state.freezed.dart';

@freezed
abstract class AdminProductListState with _$AdminProductListState {
  const factory AdminProductListState.initial() = _Initial;
  const factory AdminProductListState.loading() = _Loading;
  const factory AdminProductListState.loaded(List<Product> products) = _Loaded;
  const factory AdminProductListState.error(String message) = _Error;
}