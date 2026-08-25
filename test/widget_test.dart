// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:freshbox_app/app/app.dart';
import 'package:freshbox_app/app/router.dart';
import 'package:freshbox_app/core/di/injection.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/category/data/category_repository.dart';
import 'package:freshbox_app/features/category/presentation/category_bloc.dart';
import 'package:freshbox_app/features/product/data/product_repository.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_bloc.dart';
import 'package:freshbox_app/features/product/presentation/product_list_bloc.dart';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDioClient extends Mock implements DioClient {}
class _MockCategoryRepository extends Mock implements CategoryRepository {}
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetIt getIt;
  late SharedPreferences prefs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    getIt = GetIt.instance;
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<DioClient>(_MockDioClient());
    getIt.registerSingleton<CategoryRepository>(_MockCategoryRepository());
    getIt.registerSingleton<ProductRepository>(_MockProductRepository());
    getIt.registerLazySingleton<GoRouter>(() => buildRouter());
    getIt.registerFactory<CategoryBloc>(() => CategoryBloc(getIt<CategoryRepository>()));
    getIt.registerFactory<ProductListBloc>(() => ProductListBloc(getIt<ProductRepository>()));
    getIt.registerFactory<ProductDetailBloc>(() => ProductDetailBloc(getIt<ProductRepository>()));
  });

  tearDownAll(() {
    getIt.reset();
  });

  testWidgets('App starts and shows home', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HortifrutiApp());

    // Verify that the home page loads
    expect(find.text('Home (Vitrine)'), findsOneWidget);
  });
}