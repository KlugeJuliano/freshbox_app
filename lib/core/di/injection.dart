import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
import '../storage/local_storage.dart';
import '../../features/store/data/store_repository.dart';
import '../../features/category/data/category_repository.dart';
import '../../features/category/presentation/category_bloc.dart';
import '../../features/product/data/product_repository.dart';
import '../../features/product/presentation/product_list_bloc.dart';
import '../../features/product/presentation/product_detail_bloc.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/home_bloc.dart';
import '../../features/cart/data/cart_repository.dart';
import '../../features/cart/presentation/cart_bloc.dart';
import '../../features/order/data/order_repository.dart';
import '../../features/checkout/presentation/checkout_bloc.dart';
import '../../features/auth/data/auth_local_datasource.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_bloc.dart';
import '../../features/auth/presentation/auth_event.dart';
import '../../features/admin/data/admin_category_repository.dart';
import '../../features/admin/data/admin_product_repository.dart';
import '../../features/admin/presentation/blocs/admin_category_list_bloc.dart';
import '../../features/admin/presentation/blocs/admin_category_form_bloc.dart';
import '../../features/admin/presentation/blocs/admin_product_list_bloc.dart';
import '../../features/admin/presentation/blocs/admin_product_form_bloc.dart';

import 'package:go_router/go_router.dart';
import '../../app/router.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Infra externa
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<DioClient>(() => DioClient(Dio()));
  getIt.registerLazySingleton<LocalStorage>(
      () => LocalStorage(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // Repositories
  getIt.registerLazySingleton<StoreRepository>(
      () => StoreRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<CategoryRepository>(
      () => CategoryRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<CartRepository>(
      () => CartRepository(getIt<LocalStorage>()));
  getIt.registerLazySingleton<OrderRepository>(
      () => OrderRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSource(getIt<FlutterSecureStorage>()));
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<AdminCategoryRepository>(
      () => AdminCategoryRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<AdminProductRepository>(
      () => AdminProductRepository(getIt<DioClient>()));

  // Blocs
  getIt.registerFactory<CategoryBloc>(
      () => CategoryBloc(getIt<CategoryRepository>()));
  getIt.registerFactory<ProductListBloc>(
      () => ProductListBloc(getIt<ProductRepository>()));
  getIt.registerFactory<ProductDetailBloc>(
      () => ProductDetailBloc(getIt<ProductRepository>()));
  getIt.registerFactory<HomeBloc>(() => HomeBloc(getIt<HomeRepository>()));
  getIt.registerLazySingleton<CartBloc>(() => CartBloc(getIt<CartRepository>()));
  getIt.registerFactory<CheckoutBloc>(
      () => CheckoutBloc(getIt<OrderRepository>(), getIt<CartBloc>()));
  getIt.registerLazySingleton<AuthBloc>(
      () => AuthBloc(getIt<AuthRepository>(), getIt<AuthLocalDataSource>())
        ..add(const AuthEvent.checkAuthStatus()));
  getIt.registerFactory<AdminCategoryListBloc>(
      () => AdminCategoryListBloc(getIt<AdminCategoryRepository>()));
  getIt.registerFactory<AdminCategoryFormBloc>(
      () => AdminCategoryFormBloc(getIt<AdminCategoryRepository>()));
  getIt.registerFactory<AdminProductListBloc>(
      () => AdminProductListBloc(getIt<AdminProductRepository>()));
  getIt.registerFactory<AdminProductFormBloc>(
      () => AdminProductFormBloc(getIt<AdminProductRepository>()));

  // Configurar token provider no DioClient
  getIt<DioClient>().setTokenProvider(() => getIt<AuthLocalDataSource>().getToken());

  getIt.registerLazySingleton<GoRouter>(() => buildRouter());
}
