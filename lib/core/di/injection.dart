import 'package:dio/dio.dart';
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

  // Repositories
  getIt.registerLazySingleton<StoreRepository>(
      () => StoreRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<CategoryRepository>(
      () => CategoryRepository(getIt<DioClient>()));
  getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepository(getIt<DioClient>()));

  // Blocs
  getIt.registerFactory<CategoryBloc>(
      () => CategoryBloc(getIt<CategoryRepository>()));
  getIt.registerFactory<ProductListBloc>(
      () => ProductListBloc(getIt<ProductRepository>()));
  getIt.registerFactory<ProductDetailBloc>(
      () => ProductDetailBloc(getIt<ProductRepository>()));

  getIt.registerLazySingleton<GoRouter>(() => buildRouter());
}
