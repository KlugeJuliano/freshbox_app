import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_image.freezed.dart';
part 'product_image.g.dart';

@freezed
abstract class ProductImage with _$ProductImage {
  const factory ProductImage({
    String? thumb,
    String? card,
    String? full,
  }) = _ProductImage;

  factory ProductImage.fromJson(Map<String, dynamic> json) =>
      _$ProductImageFromJson(json);
}
