import 'package:dio/dio.dart';
import 'package:freshbox_app/core/network/api_endpoint.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/product/data/product_repository.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  late _MockDioClient mockClient;
  late ProductRepository repository;

  setUp(() {
    mockClient = _MockDioClient();
    repository = ProductRepository(mockClient);
  });

  const tProductJson = {
    'id': 1,
    'name': 'Banana Nanica',
    'slug': 'banana-nanica',
    'description': null,
    'unit': 'kg',
    'price': 4.99,
    'promo_price': null,
    'promo_ends_at': null,
    'is_on_promo': false,
    'effective_price': 4.99,
    'images': {'thumb': null, 'card': null, 'full': null},
    'is_available': true,
    'is_featured': true,
    'is_active': true,
    'category_id': 1,
  };

  const tPaginatedResponse = {
    'data': [tProductJson],
    'links': {
      'first': 'http://localhost?page=1',
      'last': 'http://localhost?page=1',
      'prev': null,
      'next': null,
    },
    'meta': {
      'current_page': 1,
      'from': 1,
      'last_page': 1,
      'links': [
        {'url': null, 'label': 'Previous', 'page': null, 'active': false},
        {
          'url': 'http://localhost?page=1',
          'label': '1',
          'page': 1,
          'active': true
        },
        {'url': null, 'label': 'Next', 'page': null, 'active': false},
      ],
      'path': 'http://localhost',
      'per_page': 10,
      'to': 1,
      'total': 1,
    },
  };

  const tDetailResponse = {'data': tProductJson};

  group('ProductRepository', () {
    group('getFeatured', () {
      test('returns Paginated<Product> on success', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientFeaturedProducts,
              queryParameters: {'page': 1},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiEndpoint.clientFeaturedProducts),
            ));

        final result = await repository.getFeatured(page: 1);

        expect(result, isA<Paginated<Product>>());
        expect(result.data.length, 1);
        expect(result.data.first.name, 'Banana Nanica');
        expect(result.currentPage, 1);
        expect(result.lastPage, 1);
        expect(result.total, 1);
        verify(() => mockClient.get(
              ApiEndpoint.clientFeaturedProducts,
              queryParameters: {'page': 1},
            )).called(1);
      });

      test('passes page parameter correctly', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientFeaturedProducts,
              queryParameters: {'page': 3},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiEndpoint.clientFeaturedProducts),
            ));

        await repository.getFeatured(page: 3);

        verify(() => mockClient.get(
              ApiEndpoint.clientFeaturedProducts,
              queryParameters: {'page': 3},
            )).called(1);
      });

      test('throws on Dio error', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientFeaturedProducts,
              queryParameters: {'page': 1},
            )).thenThrow(Exception('Network error'));

        expect(
          () => repository.getFeatured(page: 1),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPromo', () {
      test('returns Paginated<Product> on success', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientPromoProducts,
              queryParameters: {'page': 1},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiEndpoint.clientPromoProducts),
            ));

        final result = await repository.getPromo(page: 1);

        expect(result, isA<Paginated<Product>>());
        expect(result.data.length, 1);
      });
    });

    group('search', () {
      test('returns Paginated<Product> with trimmed query', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientSearchProducts,
              queryParameters: {'q': 'banana', 'page': 1},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiEndpoint.clientSearchProducts),
            ));

        final result = await repository.search('  banana  ', page: 1);

        expect(result, isA<Paginated<Product>>());
        verify(() => mockClient.get(
              ApiEndpoint.clientSearchProducts,
              queryParameters: {'q': 'banana', 'page': 1},
            )).called(1);
      });

      test('passes page parameter', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientSearchProducts,
              queryParameters: {'q': 'maçã', 'page': 2},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiEndpoint.clientSearchProducts),
            ));

        await repository.search('maçã', page: 2);

        verify(() => mockClient.get(
              ApiEndpoint.clientSearchProducts,
              queryParameters: {'q': 'maçã', 'page': 2},
            )).called(1);
      });
    });

    group('getByCategory', () {
      test('returns Paginated<Product> for category slug', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientCategoryProducts('frutas'),
              queryParameters: {'page': 1},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions: RequestOptions(
                  path: ApiEndpoint.clientCategoryProducts('frutas')),
            ));

        final result = await repository.getByCategory('frutas', page: 1);

        expect(result, isA<Paginated<Product>>());
        verify(() => mockClient.get(
              ApiEndpoint.clientCategoryProducts('frutas'),
              queryParameters: {'page': 1},
            )).called(1);
      });
    });

    group('getDetail', () {
      test('returns Product unwrapped from data key', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientProductDetail('banana-nanica'),
            )).thenAnswer((_) async => Response(
              data: tDetailResponse,
              statusCode: 200,
              requestOptions: RequestOptions(
                  path: ApiEndpoint.clientProductDetail('banana-nanica')),
            ));

        final result = await repository.getDetail('banana-nanica');

        expect(result, isA<Product>());
        expect(result.id, 1);
        expect(result.name, 'Banana Nanica');
        expect(result.slug, 'banana-nanica');
        expect(result.unitRaw, 'kg');
        expect(result.price, 4.99);
        expect(result.effectivePrice, 4.99);
        expect(result.isOnPromo, false);
        expect(result.isAvailable, true);
        expect(result.isFeatured, true);
        expect(result.isActive, true);
        expect(result.categoryId, 1);
        expect(result.images, isA<ProductImage>());
      });

      test('parses promo fields correctly', () async {
        const promoJson = {
          'data': {
            'id': 2,
            'name': 'Maçã Fuji',
            'slug': 'maca-fuji',
            'description': null,
            'unit': 'kg',
            'price': 8.99,
            'promo_price': 6.99,
            'promo_ends_at': '2026-04-25T19:38:57+00:00',
            'is_on_promo': false,
            'effective_price': 8.99,
            'images': {'thumb': null, 'card': null, 'full': null},
            'is_available': true,
            'is_featured': true,
            'is_active': true,
            'category_id': 1,
          },
        };

        when(() => mockClient.get(
              ApiEndpoint.clientProductDetail('maca-fuji'),
            )).thenAnswer((_) async => Response(
              data: promoJson,
              statusCode: 200,
              requestOptions: RequestOptions(
                  path: ApiEndpoint.clientProductDetail('maca-fuji')),
            ));

        final result = await repository.getDetail('maca-fuji');

        expect(result.id, 2);
        expect(result.name, 'Maçã Fuji');
        expect(result.promoPrice, 6.99);
        expect(result.promoEndsAtRaw, '2026-04-25T19:38:57+00:00');
        expect(result.isOnPromo, false);
        expect(result.effectivePrice, 8.99);
      });

      test('throws on error', () async {
        when(() => mockClient.get(
              ApiEndpoint.clientProductDetail('not-found'),
            )).thenThrow(Exception('Not found'));

        expect(
          () => repository.getDetail('not-found'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
