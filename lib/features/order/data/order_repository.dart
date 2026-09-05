import 'package:freshbox_app/core/network/api_endpoint.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/order/domain/checkout_form.dart';
import 'package:freshbox_app/features/order/domain/order.dart';

class OrderRepository {
  OrderRepository(this._client);

  final DioClient _client;

  Future<Order> createOrder(CheckoutForm form, List<CartItem> items) async {
    final response = await _client.post(
      ApiEndpoint.clientOrders,
      data: {
        ...form.toOrderRequest(),
        'items': items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'unit_price': item.effectivePrice,
                })
            .toList(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final orderJson = data['data'] as Map<String, dynamic>;
    return Order.fromJson(orderJson);
  }
}