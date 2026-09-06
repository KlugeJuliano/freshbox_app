// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:freshbox_app/app/app.dart';
import 'package:freshbox_app/app/router.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/auth/data/auth_repository.dart';
import 'package:freshbox_app/features/auth/presentation/auth_bloc.dart';
import 'package:freshbox_app/features/auth/presentation/auth_state.dart';
import 'package:freshbox_app/features/auth/domain/user.dart';
import 'package:freshbox_app/features/cart/data/cart_repository.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/category/data/category_repository.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/features/category/presentation/category_bloc.dart';
import 'package:freshbox_app/features/home/data/home_repository.dart';
import 'package:freshbox_app/features/home/presentation/home_bloc.dart';
import 'package:freshbox_app/features/product/data/product_repository.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_bloc.dart';
import 'package:freshbox_app/features/product/presentation/product_list_bloc.dart';
import 'package:freshbox_app/features/store/domain/store.dart';

import 'package:shared_preferences/shared_preferences.dart';

class _MockDioClient extends Mock implements DioClient {}
class _MockCategoryRepository extends Mock implements CategoryRepository {}
class _MockProductRepository extends Mock implements ProductRepository {}
class _MockHomeRepository extends Mock implements HomeRepository {}
class _MockCartRepository extends Mock implements CartRepository {}
class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late GetIt getIt;
  late SharedPreferences prefs;
  late _MockHomeRepository mockHomeRepository;
  late _MockCartRepository mockCartRepository;
  late _MockAuthRepository mockAuthRepository;
  late _MockAuthBloc mockAuthBloc;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    mockHomeRepository = _MockHomeRepository();
    mockCartRepository = _MockCartRepository();
    mockAuthRepository = _MockAuthRepository();
    mockAuthBloc = _MockAuthBloc();
    
    // Mock HomeRepository responses
    when(() => mockHomeRepository.getStore()).thenAnswer((_) async => Store(
      id: 1,
      name: 'Hortifruti Teste',
      slug: 'hortifruti-teste',
      logoUrl: null,
      whatsapp: null,
      isOpen: true,
      deliveryFee: 5.0,
    ));
    when(() => mockHomeRepository.getBanners()).thenAnswer((_) async => <String>[]);
    when(() => mockHomeRepository.getCategories()).thenAnswer((_) async => <Category>[]);
    when(() => mockHomeRepository.getFeaturedProducts()).thenAnswer((_) async => Paginated<Product>(
      data: <Product>[],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    ));
    when(() => mockHomeRepository.getPromoProducts()).thenAnswer((_) async => Paginated<Product>(
      data: <Product>[],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    ));
    
    // Mock CartRepository responses
    when(() => mockCartRepository.getCart()).thenAnswer((_) async => Cart.empty());
    
    // Mock AuthRepository and AuthBloc for unauthenticated state
    when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthState.unauthenticated()));
    when(() => mockAuthRepository.me()).thenAnswer((_) async => User(
      id: 1,
      name: 'Admin',
      email: 'admin@test.com',
      role: 'admin',
      companyId: 1,
    ));

    getIt = GetIt.instance;
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<DioClient>(_MockDioClient());
    getIt.registerSingleton<CategoryRepository>(_MockCategoryRepository());
    getIt.registerSingleton<ProductRepository>(_MockProductRepository());
    getIt.registerSingleton<HomeRepository>(mockHomeRepository);
    getIt.registerSingleton<CartRepository>(mockCartRepository);
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    getIt.registerLazySingleton<GoRouter>(() => buildRouter());
    getIt.registerFactory<CategoryBloc>(() => CategoryBloc(getIt<CategoryRepository>()));
    getIt.registerFactory<ProductListBloc>(() => ProductListBloc(getIt<ProductRepository>()));
    getIt.registerFactory<ProductDetailBloc>(() => ProductDetailBloc(getIt<ProductRepository>()));
    getIt.registerFactory<HomeBloc>(() => HomeBloc(getIt<HomeRepository>()));
    getIt.registerLazySingleton<CartBloc>(() => CartBloc(getIt<CartRepository>()));
    getIt.registerLazySingleton<AuthBloc>(() => mockAuthBloc);
  });

  tearDownAll(() {
    getIt.reset();
  });

  testWidgets('App starts and shows home', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HortifrutiApp());
    
    // Wait for async loading to complete
    await tester.pumpAndSettle();

    // Verify that the home page loads (store name in header)
    expect(find.text('Hortifruti Teste'), findsOneWidget);
  });
}