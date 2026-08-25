import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/features/product/data/product_repository.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_bloc.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_event.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_state.dart';
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

void main() {
  late _MockProductRepository mockRepository;
  late ProductDetailBloc bloc;

  setUp(() {
    mockRepository = _MockProductRepository();
    bloc = ProductDetailBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ProductDetailBloc', () {
    group('load', () {
      blocTest<ProductDetailBloc, ProductDetailState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getDetail('banana-nanica'))
              .thenAnswer((_) async => tProduct);
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductDetailEvent.load('banana-nanica')),
        expect: () => [
          const ProductDetailState.loading(),
          ProductDetailState.loaded(tProduct),
        ],
      );

      blocTest<ProductDetailBloc, ProductDetailState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(() => mockRepository.getDetail('not-found'))
              .thenThrow(Exception('Not found'));
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductDetailEvent.load('not-found')),
        expect: () => [
          const ProductDetailState.loading(),
          ProductDetailState.error('Exception: Not found'),
        ],
      );

      blocTest<ProductDetailBloc, ProductDetailState>(
        'passes slug to repository',
        build: () {
          when(() => mockRepository.getDetail('maca-fuji'))
              .thenAnswer((_) async => tProduct);
          return bloc;
        },
        act: (bloc) => bloc.add(const ProductDetailEvent.load('maca-fuji')),
        verify: (_) {
          verify(() => mockRepository.getDetail('maca-fuji')).called(1);
        },
      );
    });

    group('refresh', () {
      test('calls repository and does not throw when successful', () async {
        when(() => mockRepository.getDetail('banana-nanica'))
            .thenAnswer((_) async => tProduct);

        bloc = ProductDetailBloc(mockRepository);
        bloc.add(const ProductDetailEvent.load('banana-nanica'));
        await bloc.stream
            .where((s) => s.maybeWhen(loaded: (_) => true, orElse: () => false))
            .first;

        bloc.add(const ProductDetailEvent.refresh('banana-nanica'));
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockRepository.getDetail('banana-nanica')).called(2);
      });

      test('does not throw when refresh fails', () async {
        var callCount = 0;
        when(() => mockRepository.getDetail('banana-nanica')).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future.value(tProduct);
          } else {
            throw Exception('Network error');
          }
        });

        bloc = ProductDetailBloc(mockRepository);
        bloc.add(const ProductDetailEvent.load('banana-nanica'));
        await bloc.stream
            .where((s) => s.maybeWhen(loaded: (_) => true, orElse: () => false))
            .first;

        bloc.add(const ProductDetailEvent.refresh('banana-nanica'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify the repository was called and no exception propagated to crash the test
        verify(() => mockRepository.getDetail('banana-nanica')).called(2);
      });
    });
  });
}
