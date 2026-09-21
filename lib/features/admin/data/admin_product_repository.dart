import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/product/domain/product.dart';

class AdminProductRepository {
  AdminProductRepository(this._client);

  final DioClient _client;

  static const _endpoint = '/admin/products';

  Future<List<Product>> getAll() async {
    final List<Product> all = [];
    int page = 1;
    bool hasNext = true;

    while (hasNext) {
      final response = await _client.get(_endpoint, queryParameters: {'page': page});
      final data = response.data['data'] as List;
      all.addAll(data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList());

      final meta = response.data['meta'] as Map<String, dynamic>;
      hasNext = (meta['current_page'] as int) < (meta['last_page'] as int);
      page++;
    }
    return all;
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