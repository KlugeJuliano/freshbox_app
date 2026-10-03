import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/admin/domain/admin_order.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';

class AdminOrderRepository {
  AdminOrderRepository(this._client);

  final DioClient _client;

  static const _endpoint = '/admin/orders';

  Future<Paginated<AdminOrder>> getAll({
    int page = 1,
    AdminOrderStatus? status,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (status != null) {
      query['status'] = status.apiValue;
    }
    final response = await _client.get(_endpoint, queryParameters: query);
    return Paginated.fromJson(
      response.data,
      (json) => AdminOrder.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AdminOrder> getById(String id) async {
    final response = await _client.get('$_endpoint/$id');
    return AdminOrder.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AdminOrder> updateStatus(String id, AdminOrderStatus status) async {
    final response = await _client.patch(
      '$_endpoint/$id/status',
      data: {'status': status.apiValue},
    );
    return AdminOrder.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}