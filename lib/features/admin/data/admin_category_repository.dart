import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/category/domain/category.dart';

class AdminCategoryRepository {
  AdminCategoryRepository(this._client);

  final DioClient _client;

  static const _endpoint = '/admin/categories';

  Future<List<Category>> getAll() async {
    final List<Category> all = [];
    int page = 1;
    bool hasNext = true;

    while (hasNext) {
      final response = await _client.get(_endpoint, queryParameters: {'page': page});
      final data = response.data['data'] as List;
      all.addAll(data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList());

      final meta = response.data['meta'] as Map<String, dynamic>;
      hasNext = (meta['current_page'] as int) < (meta['last_page'] as int);
      page++;
    }
    return all;
  }

  Future<Category> getById(int id) async {
    final response = await _client.get('$_endpoint/$id');
    return Category.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Category> create(Map<String, dynamic> data) async {
    final response = await _client.post(_endpoint, data: data);
    return Category.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Category> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('$_endpoint/$id', data: data);
    return Category.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _client.delete('$_endpoint/$id');
  }
}