import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/features/admin/data/admin_product_repository.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_state.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminProductRepository extends Mock implements AdminProductRepository {}

const tProduct = Product(
  id: 1,
  name: 'Banana Nanica',
  slug: 'banana-nanica',
  description: null,
  unitRaw: 'kg',
  price: 4.99,
  promoPrice: null,
  promoEndsAtRaw: null,
  isOnPromo: false,
  effectivePrice: 4.99,
  images: ProductImage(thumb: null, card: null, full: null),
  isAvailable: true,
  isFeatured: true,
  isActive: true,
  categoryId: 1,
);

const tProduct2 = Product(
  id: 2,
  name: 'Maçã Fuji',
  slug: 'maca-fuji',
  description: 'Maçã fresca',
  unitRaw: 'kg',
  price: 8.99,
  promoPrice: 6.99,
  promoEndsAtRaw: '2026-04-25T19:38:57+00:00',
  isOnPromo: true,
  effectivePrice: 6.99,
  images: ProductImage(thumb: null, card: null, full: null),
  isAvailable: true,
  isFeatured: false,
  isActive: true,
  categoryId: 1,
);

void main() {
  late _MockAdminProductRepository mockRepository;
  late AdminProductListBloc bloc;

  setUp(() {
    mockRepository = _MockAdminProductRepository();
    bloc = AdminProductListBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AdminProductListBloc', () {
    group('load', () {
      blocTest<AdminProductListBloc, AdminProductListState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => [tProduct, tProduct2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminProductListEvent.load()),
        expect: () => [
          const AdminProductListState.loading(),
          predicate<AdminProductListState>((s) => s.maybeWhen(
                loaded: (products) => products.length == 2 && products.first.name == 'Banana Nanica',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductListBloc, AdminProductListState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(() => mockRepository.getAll()).thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminProductListEvent.load()),
        expect: () => [
          const AdminProductListState.loading(),
          predicate<AdminProductListState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Network error'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductListBloc, AdminProductListState>(
        'emits [loading, loaded] with empty list when no products',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => <Product>[]);
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminProductListEvent.load()),
        expect: () => [
          const AdminProductListState.loading(),
          predicate<AdminProductListState>((s) => s.maybeWhen(
                loaded: (products) => products.isEmpty,
                orElse: () => false,
              )),
        ],
      );
    });

    group('refresh', () {
      blocTest<AdminProductListBloc, AdminProductListState>(
        'emits [loading, loaded] when successful (same as load)',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => [tProduct]);
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminProductListEvent.refresh()),
        expect: () => [
          const AdminProductListState.loading(),
          predicate<AdminProductListState>((s) => s.maybeWhen(
                loaded: (products) => products.length == 1,
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductListBloc, AdminProductListState>(
        'can be called multiple times',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => [tProduct]);
          return bloc;
        },
        act: (bloc) {
          bloc.add(const AdminProductListEvent.load());
          bloc.add(const AdminProductListEvent.refresh());
        },
        expect: () => [
          const AdminProductListState.loading(),
          predicate<AdminProductListState>((s) => s.maybeWhen(loaded: (_) => true, orElse: () => false)),
          const AdminProductListState.loading(),
          predicate<AdminProductListState>((s) => s.maybeWhen(loaded: (_) => true, orElse: () => false)),
        ],
      );
    });
  });
}