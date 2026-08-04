import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,
    @JsonKey(name: 'parent_id') int? parentId,
    required String name,
    required String slug,
    @JsonKey(name: 'icon_url') String? iconUrl,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'products_count') required int productsCount,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}