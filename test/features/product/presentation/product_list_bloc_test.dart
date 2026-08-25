import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/product/data/product_repository.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:freshbox_app/features/product/presentation/product_list_bloc.dart';
import 'package:freshbox_app/features/product/presentation/product_list_event.dart';
import 'package:freshbox_app/features/product/presentation/product_list_state.dart';
import 'package:freshbox_app/features/product/presentation/product_list_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

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
  description: null,
  unitRaw: 'kg',
  price: 8.99,
  promoPrice: null,
  promoEndsAtRaw: null,
  isOnPromo: false,
  effectivePrice: 8.99,
  images: ProductImage(thumb: null, card: null, full: null),
  isAvailable: true,
  isFeatured: true,
  isActive: true,
  categoryId: 1,
);

const tPaginated = Paginated<Product>(
  data: [tProduct],
  currentPage: 1,
  lastPage: 1,
  total: 1,
);

void main() {
  late _MockProductRepository mockRepository;
  late ProductListBloc bloc;

  setUp(() {
    mockRepository = _MockProductRepository();
    bloc = ProductListBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ProductListBloc', () {
    group('loadFeatured', () {
      blocTest<ProductListBloc, ProductListState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getFeatured(page: 1))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductListEvent.loadFeatured()),
        expect: () => [
          ProductListState.loading(currentType: ProductListType.featured),
          ProductListState.loaded(
            type: ProductListType.featured,
            products: tPaginated,
            hasReachedMax: true,
          ),
        ],
      );

      blocTest<ProductListBloc, ProductListState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(() => mockRepository.getFeatured(page: 1))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductListEvent.loadFeatured()),
        expect: () => [
          ProductListState.loading(currentType: ProductListType.featured),
          ProductListState.error('Exception: Network error',
              failedType: ProductListType.featured),
        ],
      );

      blocTest<ProductListBloc, ProductListState>(
        'passes page parameter to repository',
        build: () {
          when(() => mockRepository.getFeatured(page: 3))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductListEvent.loadFeatured(page: 3)),
        verify: (_) {
          verify(() => mockRepository.getFeatured(page: 3)).called(1);
        },
      );
    });

    group('loadPromo', () {
      blocTest<ProductListBloc, ProductListState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getPromo(page: 1))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductListEvent.loadPromo()),
        expect: () => [
          ProductListState.loading(currentType: ProductListType.promo),
          ProductListState.loaded(
            type: ProductListType.promo,
            products: tPaginated,
            hasReachedMax: true,
          ),
        ],
      );
    });

    group('loadByCategory', () {
      blocTest<ProductListBloc, ProductListState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getByCategory('frutas', page: 1))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const ProductListEvent.loadByCategory('frutas')),
        expect: () => [
          ProductListState.loading(currentType: ProductListType.category),
          ProductListState.loaded(
            type: ProductListType.category,
            products: tPaginated,
            hasReachedMax: true,
          ),
        ],
      );
    });

    group('loadMore', () {
      blocTest<ProductListBloc, ProductListState>(
        'does not load more when hasReachedMax is true',
        build: () {
          when(() => mockRepository.getFeatured(page: 1))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        seed: () => ProductListState.loaded(
          type: ProductListType.featured,
          products: tPaginated,
          hasReachedMax: true,
        ),
        act: (bloc) => bloc.add(const ProductListEvent.loadMore()),
        expect: () => [],
      );

      blocTest<ProductListBloc, ProductListState>(
        'appends new page when hasReachedMax is false',
        build: () {
          when(() => mockRepository.getFeatured(page: 1))
              .thenAnswer((_) async => tPaginated);
          when(() => mockRepository.getFeatured(page: 2))
              .thenAnswer((_) async => tPaginated.copyWith(
                    data: [tProduct2],
                    currentPage: 2,
                    lastPage: 2,
                    total: 2,
                  ));
          return bloc;
        },
        seed: () => ProductListState.loaded(
          type: ProductListType.featured,
          products: tPaginated,
          hasReachedMax: false,
        ),
        act: (bloc) => bloc.add(const ProductListEvent.loadMore()),
        expect: () => [
          ProductListState.loaded(
            type: ProductListType.featured,
            products: tPaginated.copyWith(
              data: [tProduct, tProduct2],
              currentPage: 2,
              lastPage: 2,
              total: 2,
            ),
            hasReachedMax: true,
          ),
        ],
      );
    });

    group('refresh', () {
      blocTest<ProductListBloc, ProductListState>(
        'reloads current type',
        build: () {
          when(() => mockRepository.getFeatured(page: 1))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        seed: () => ProductListState.loaded(
          type: ProductListType.featured,
          products: tPaginated,
          hasReachedMax: true,
        ),
        act: (bloc) => bloc.add(const ProductListEvent.refresh()),
        expect: () => [
          ProductListState.loading(currentType: ProductListType.featured),
          ProductListState.loaded(
            type: ProductListType.featured,
            products: tPaginated,
            hasReachedMax: true,
          ),
        ],
      );
    });

    group('changeType', () {
      blocTest<ProductListBloc, ProductListState>(
        'switches to promo and loads',
        build: () {
          when(() => mockRepository.getPromo(page: 1))
              .thenAnswer((_) async => tPaginated);
          return bloc;
        },
        seed: () => ProductListState.loaded(
          type: ProductListType.featured,
          products: tPaginated,
          hasReachedMax: true,
        ),
        act: (bloc) =>
            bloc.add(const ProductListEvent.changeType(ProductListType.promo)),
        expect: () => [
          ProductListState.loading(currentType: ProductListType.promo),
          ProductListState.loaded(
            type: ProductListType.promo,
            products: tPaginated,
            hasReachedMax: true,
          ),
        ],
      );
    });
  });
}
