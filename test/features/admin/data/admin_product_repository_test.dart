import 'package:dio/dio.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/admin/data/admin_product_repository.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  late _MockDioClient mockClient;
  late AdminProductRepository repository;

  setUp(() {
    mockClient = _MockDioClient();
    repository = AdminProductRepository(mockClient);
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

  const tProductListResponse = {
    'data': [tProductJson],
  };

  const tProductDetailResponse = {'data': tProductJson};

  const tCreatedProductJson = {
    'data': {
      'id': 2,
      'name': 'Maçã Fuji',
      'slug': 'maca-fuji',
      'description': 'Maçã fresca',
      'unit': 'kg',
      'price': 8.99,
      'promo_price': null,
      'promo_ends_at': null,
      'is_on_promo': false,
      'effective_price': 8.99,
      'images': {'thumb': null, 'card': null, 'full': null},
      'is_available': true,
      'is_featured': false,
      'is_active': true,
      'category_id': 1,
    },
  };

  group('AdminProductRepository', () {
    group('getAll', () {
      test('returns List<Product> on success', () async {
        when(() => mockClient.get('/admin/products')).thenAnswer((_) async => Response(
              data: tProductListResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/products'),
            ));

        final result = await repository.getAll();

        expect(result, isA<List<Product>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.name, 'Banana Nanica');
        expect(result.first.slug, 'banana-nanica');
        expect(result.first.unitRaw, 'kg');
        expect(result.first.price, 4.99);
        expect(result.first.isAvailable, true);
        expect(result.first.isFeatured, true);
        expect(result.first.isActive, true);
        expect(result.first.categoryId, 1);
        verify(() => mockClient.get('/admin/products')).called(1);
      });

      test('throws on Dio error', () async {
        when(() => mockClient.get('/admin/products')).thenThrow(Exception('Network error'));

        expect(
          () => repository.getAll(),
          throwsA(isA<Exception>()),
        );
      });

      test('returns empty list when data is empty', () async {
        when(() => mockClient.get('/admin/products')).thenAnswer((_) async => Response(
              data: {'data': []},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/products'),
            ));

        final result = await repository.getAll();

        expect(result, isEmpty);
      });
    });

    group('getById', () {
      test('returns Product on success', () async {
        when(() => mockClient.get('/admin/products/1')).thenAnswer((_) async => Response(
              data: tProductDetailResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/products/1'),
            ));

        final result = await repository.getById(1);

        expect(result, isA<Product>());
        expect(result.id, 1);
        expect(result.name, 'Banana Nanica');
        expect(result.slug, 'banana-nanica');
        expect(result.unitRaw, 'kg');
        expect(result.price, 4.99);
        expect(result.isAvailable, true);
        expect(result.isFeatured, true);
        expect(result.isActive, true);
        expect(result.categoryId, 1);
        verify(() => mockClient.get('/admin/products/1')).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.get('/admin/products/999')).thenThrow(Exception('Not found'));

        expect(
          () => repository.getById(999),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('create', () {
      test('returns created Product on success', () async {
        final createData = {
          'name': 'Maçã Fuji',
          'slug': 'maca-fuji',
          'description': 'Maçã fresca',
          'unit': 'kg',
          'price': 8.99,
          'category_id': 1,
          'is_available': true,
          'is_featured': false,
          'is_active': true,
        };

        when(() => mockClient.post('/admin/products', data: createData)).thenAnswer((_) async => Response(
              data: tCreatedProductJson,
              statusCode: 201,
              requestOptions: RequestOptions(path: '/admin/products'),
            ));

        final result = await repository.create(createData);

        expect(result, isA<Product>());
        expect(result.id, 2);
        expect(result.name, 'Maçã Fuji');
        expect(result.slug, 'maca-fuji');
        expect(result.price, 8.99);
        verify(() => mockClient.post('/admin/products', data: createData)).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.post('/admin/products', data: any(named: 'data')))
            .thenThrow(Exception('Validation error'));

        expect(
          () => repository.create({'name': '', 'price': -1}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('update', () {
      test('returns updated Product on success', () async {
        final updateData = {
          'name': 'Banana Nanica Atualizada',
          'price': 5.49,
        };

        const updatedResponse = {
          'data': {
            'id': 1,
            'name': 'Banana Nanica Atualizada',
            'slug': 'banana-nanica',
            'description': null,
            'unit': 'kg',
            'price': 5.49,
            'promo_price': null,
            'promo_ends_at': null,
            'is_on_promo': false,
            'effective_price': 5.49,
            'images': {'thumb': null, 'card': null, 'full': null},
            'is_available': true,
            'is_featured': true,
            'is_active': true,
            'category_id': 1,
          },
        };

        when(() => mockClient.put('/admin/products/1', data: updateData)).thenAnswer((_) async => Response(
              data: updatedResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/products/1'),
            ));

        final result = await repository.update(1, updateData);

        expect(result, isA<Product>());
        expect(result.id, 1);
        expect(result.name, 'Banana Nanica Atualizada');
        expect(result.price, 5.49);
        verify(() => mockClient.put('/admin/products/1', data: updateData)).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.put('/admin/products/1', data: any(named: 'data')))
            .thenThrow(Exception('Not found'));

        expect(
          () => repository.update(1, {'name': 'Test'}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('delete', () {
      test('completes on success', () async {
        when(() => mockClient.delete('/admin/products/1')).thenAnswer((_) async => Response(
              data: {'message': 'Deleted'},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/products/1'),
            ));

        await expectLater(repository.delete(1), completes);
        verify(() => mockClient.delete('/admin/products/1')).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.delete('/admin/products/999')).thenThrow(Exception('Not found'));

        expect(
          () => repository.delete(999),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}