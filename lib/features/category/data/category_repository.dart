import '../../../core/network/api_endpoint.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated.dart';
import '../domain/category.dart';

class CategoryRepository {
  final DioClient _client;
  CategoryRepository(this._client);

  Future<Paginated<Category>> getCategories() async {
    final response = await _client.get(ApiEndpoint.clientCategories);
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Category.fromJson(json as Map<String, dynamic>),
    );
  }
}