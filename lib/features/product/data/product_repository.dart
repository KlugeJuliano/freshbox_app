import 'package:freshbox_app/core/network/api_endpoint.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/product/domain/product.dart';

class ProductRepository {
  final DioClient _client;
  ProductRepository(this._client);

  Future<Paginated<Product>> getFeatured({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoint.clientFeaturedProducts,
      queryParameters: {'page': page},
    );
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Paginated<Product>> getPromo({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoint.clientPromoProducts,
      queryParameters: {'page': page},
    );
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Paginated<Product>> search(String query, {int page = 1}) async {
    final response = await _client.get(
      ApiEndpoint.clientSearchProducts,
      queryParameters: {'q': query.trim(), 'page': page},
    );
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Paginated<Product>> getByCategory(String categorySlug,
      {int page = 1}) async {
    final response = await _client.get(
      ApiEndpoint.clientCategoryProducts(categorySlug),
      queryParameters: {'page': page},
    );
    return Paginated.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Product> getDetail(String slug) async {
    final response = await _client.get(ApiEndpoint.clientProductDetail(slug));
    // Backend retorna { "data": { ... } } — desempacotar
    final data = response.data as Map<String, dynamic>;
    final productJson = data['data'] as Map<String, dynamic>;
    return Product.fromJson(productJson);
  }
}
