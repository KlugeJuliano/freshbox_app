// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_order_item.freezed.dart';
part 'admin_order_item.g.dart';

@freezed
abstract class AdminOrderItem with _$AdminOrderItem {
  const factory AdminOrderItem({
    required int id,
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'product_unit') required String productUnit,
    @JsonKey(name: 'unit_price') required double unitPrice,
    required int quantity,
    required double subtotal,
    String? observation,
  }) = _AdminOrderItem;

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) =>
      _$AdminOrderItemFromJson(json);
}