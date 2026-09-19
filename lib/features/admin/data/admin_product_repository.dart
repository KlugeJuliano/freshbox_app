import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/product/domain/product.dart';

class AdminProductRepository {
  AdminProductRepository(this._client);

  final DioClient _client;

  static const _endpoint = '/admin/products';

  Future<List<Product>> getAll() async {
    final response = await _client.get(_endpoint);
    final data = response.data['data'] as List;
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getById(int id) async {
    final response = await _client.get('$_endpoint/$id');
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Product> create(Map<String, dynamic> data) async {
    final response = await _client.post(_endpoint, data: data);
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Product> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('$_endpoint/$id', data: data);
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _client.delete('$_endpoint/$id');
  }
}