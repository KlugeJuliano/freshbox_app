import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_image.dart';
import 'product_unit.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required int id,
    required String name,
    required String slug,
    String? description,
    @JsonKey(name: 'unit') required String unitRaw,
    required double price,
    @JsonKey(name: 'promo_price') double? promoPrice,
    @JsonKey(name: 'promo_ends_at') String? promoEndsAtRaw,
    @JsonKey(name: 'is_on_promo') required bool isOnPromo,
    @JsonKey(name: 'effective_price') required double effectivePrice,
    required ProductImage images,
    @JsonKey(name: 'is_available') required bool isAvailable,
    @JsonKey(name: 'is_featured') required bool isFeatured,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'category_id') required int categoryId,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

extension ProductExtensions on Product {
  ProductUnit get unit => ProductUnit.fromString(unitRaw);

  DateTime? get promoEndsAt =>
      promoEndsAtRaw != null ? DateTime.tryParse(promoEndsAtRaw!) : null;

  bool get hasPromo => isOnPromo && promoPrice != null && promoPrice! < price;

  String get unitLabel => unit.label;
}
