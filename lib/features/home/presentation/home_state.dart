import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/store/domain/store.dart';
import 'package:freshbox_app/core/network/paginated.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded({
    required Store store,
    required List<String> banners,
    required List<Category> categories,
    required Paginated<Product> featuredProducts,
    required Paginated<Product> promoProducts,
  }) = _Loaded;
  const factory HomeState.error(String message) = _Error;
}