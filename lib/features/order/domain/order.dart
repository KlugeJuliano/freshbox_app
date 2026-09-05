import 'package:freezed_annotation/freezed_annotation.dart';
import 'order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class Order with _$Order {
  const factory Order({
    required int id,
    required String uuid,
    required String status,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String deliveryType,
    required double deliveryFee,
    required double subtotal,
    required double total,
    required List<OrderItem> items,
    required String whatsappUrl,
    required String createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}