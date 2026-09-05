import 'package:freshbox_app/core/network/api_endpoint.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/store/domain/store.dart';

class HomeRepository {
  HomeRepository(this._client);

  final DioClient _client;

  Future<Store> getStore() async {
    final response = await _client.get(ApiEndpoint.clientStore);
    return Store.fromJson(response.data['data']);
  }

  Future<List<String>> getBanners() async {
    final response = await _client.get(ApiEndpoint.clientBanners);
    final List<dynamic> data = response.data['data'] ?? [];
    return data
        .map((e) => e['image_url'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.get(ApiEndpoint.clientCategories);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Paginated<Product>> getFeaturedProducts({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoint.clientFeaturedProducts,
      queryParameters: {'page': page},
    );
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Paginated<Product>> getPromoProducts({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoint.clientPromoProducts,
      queryParameters: {'page': page},
    );
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }
}