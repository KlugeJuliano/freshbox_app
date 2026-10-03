// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'admin_order_status.dart';
import 'admin_delivery_address.dart';
import 'admin_order_item.dart';

part 'admin_order.freezed.dart';
part 'admin_order.g.dart';

@freezed
abstract class AdminOrder with _$AdminOrder {
  const factory AdminOrder({
    required String id,
    @JsonKey(name: 'status') @AdminOrderStatusConverter() required AdminOrderStatus status,
    @JsonKey(name: 'customer_name') required String customerName,
    @JsonKey(name: 'customer_phone') required String customerPhone,
    @JsonKey(name: 'delivery_type') required String deliveryType,
    @JsonKey(name: 'delivery_address') AdminDeliveryAddress? deliveryAddress,
    @JsonKey(name: 'subtotal') required double subtotal,
    @JsonKey(name: 'delivery_fee') required double deliveryFee,
    required double total,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'observations') String? observations,
    @JsonKey(name: 'confirmed_at') DateTime? confirmedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required List<AdminOrderItem> items,
  }) = _AdminOrder;

  factory AdminOrder.fromJson(Map<String, dynamic> json) =>
      _$AdminOrderFromJson(json);
}