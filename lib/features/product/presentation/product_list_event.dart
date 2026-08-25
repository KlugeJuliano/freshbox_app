import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_list_type.dart';

part 'product_list_event.freezed.dart';

@freezed
abstract class ProductListEvent with _$ProductListEvent {
  const factory ProductListEvent.loadFeatured({@Default(1) int page}) =
      _LoadFeatured;
  const factory ProductListEvent.loadPromo({@Default(1) int page}) = _LoadPromo;
  const factory ProductListEvent.search(String query, {@Default(1) int page}) =
      _Search;
  const factory ProductListEvent.loadByCategory(String categorySlug,
      {@Default(1) int page}) = _LoadByCategory;
  const factory ProductListEvent.loadMore() = _LoadMore;
  const factory ProductListEvent.refresh() = _Refresh;
  const factory ProductListEvent.changeType(ProductListType type) = _ChangeType;
}
