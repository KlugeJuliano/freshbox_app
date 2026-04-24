import 'package:freshbox_app/core/constants/app_constants.dart';

class ApiEndpoint {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Client routes
  static const String clientStore = '/client/store';
  static const String clientBanners = '/client/banners';
  static const String clientCategories = '/client/categories';
  static String clientCategoryProducts(String slug) =>
      '/client/categories/$slug/products';
  static String clientProductDetail(String slug) => '/client/products/$slug';
  static const String clientFeaturedProducts = '/client/products/featured';
  static const String clientPromoProducts = '/client/products/on-promo';
  static const String clientSearchProducts = '/client/products/search';
  static const String clientOrders = '/client/orders';

  // Auth routes
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Admin routes
  static const String adminCategories = '/admin/categories';
  static String adminCategoryDetail(int id) => '/admin/categories/$id';
  static const String adminProducts = '/admin/products';
  static String adminProductImage(int id) => '/admin/products/$id/image';
  static String adminProductToggle(int id) => '/admin/products/$id/toggle';
  static const String adminBanners = '/admin/banners';
  static const String adminOrders = '/admin/orders';
  static String adminOrderDetail(int id) => '/admin/orders/$id';
  static String adminOrderStatus(int id) => '/admin/orders/$id/status';
  static const String adminStore = '/admin/store';
  static const String adminStoreLogo = '/admin/store/logo';
}
