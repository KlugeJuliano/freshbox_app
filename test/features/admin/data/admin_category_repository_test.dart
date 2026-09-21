import 'package:dio/dio.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/admin/data/admin_category_repository.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  late _MockDioClient mockClient;
  late AdminCategoryRepository repository;

  setUp(() {
    mockClient = _MockDioClient();
    repository = AdminCategoryRepository(mockClient);
  });

  const tCategoryJson = {
    'id': 1,
    'parent_id': null,
    'name': 'Frutas',
    'slug': 'frutas',
    'icon_url': null,
    'image_url': null,
    'sort_order': 1,
    'is_active': true,
    'products_count': 5,
  };

  const tCategoryListResponse = {
    'data': [tCategoryJson],
  };

  const tCategoryDetailResponse = {'data': tCategoryJson};

  const tCreatedCategoryJson = {
    'data': {
      'id': 2,
      'parent_id': null,
      'name': 'Verduras',
      'slug': 'verduras',
      'icon_url': null,
      'image_url': null,
      'sort_order': 2,
      'is_active': true,
      'products_count': 3,
    },
  };

  group('AdminCategoryRepository', () {
    group('getAll', () {
      test('returns List<Category> on success (single page)', () async {
        const tPaginatedResponse = {
          'data': [tCategoryJson],
          'meta': {
            'current_page': 1,
            'last_page': 1,
          },
        };

        when(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 1},
            )).thenAnswer((_) async => Response(
              data: tPaginatedResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories'),
            ));

        final result = await repository.getAll();

        expect(result, isA<List<Category>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.name, 'Frutas');
        expect(result.first.slug, 'frutas');
        expect(result.first.sortOrder, 1);
        expect(result.first.isActive, true);
        expect(result.first.productsCount, 5);
        verify(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 1},
            )).called(1);
      });

      test('returns List<Category> on success (multiple pages)', () async {
        const tPage1Response = {
          'data': [tCategoryJson],
          'meta': {
            'current_page': 1,
            'last_page': 2,
          },
        };

        const tPage2CategoryJson = {
          'id': 2,
          'parent_id': null,
          'name': 'Verduras',
          'slug': 'verduras',
          'icon_url': null,
          'image_url': null,
          'sort_order': 2,
          'is_active': true,
          'products_count': 3,
        };

        const tPage2Response = {
          'data': [tPage2CategoryJson],
          'meta': {
            'current_page': 2,
            'last_page': 2,
          },
        };

        when(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 1},
            )).thenAnswer((_) async => Response(
              data: tPage1Response,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories'),
            ));

        when(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 2},
            )).thenAnswer((_) async => Response(
              data: tPage2Response,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories'),
            ));

        final result = await repository.getAll();

        expect(result, isA<List<Category>>());
        expect(result.length, 2);
        expect(result[0].name, 'Frutas');
        expect(result[1].name, 'Verduras');
        verify(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 1},
            )).called(1);
        verify(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 2},
            )).called(1);
      });

      test('throws on Dio error', () async {
        when(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 1},
            )).thenThrow(Exception('Network error'));

        expect(
          () => repository.getAll(),
          throwsA(isA<Exception>()),
        );
      });

      test('returns empty list when data is empty', () async {
        const tEmptyPaginatedResponse = {
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
          },
        };

        when(() => mockClient.get(
              '/admin/categories',
              queryParameters: {'page': 1},
            )).thenAnswer((_) async => Response(
              data: tEmptyPaginatedResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories'),
            ));

        final result = await repository.getAll();

        expect(result, isEmpty);
      });
    });

    group('getById', () {
      test('returns Category on success', () async {
        when(() => mockClient.get('/admin/categories/1')).thenAnswer((_) async => Response(
              data: tCategoryDetailResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories/1'),
            ));

        final result = await repository.getById(1);

        expect(result, isA<Category>());
        expect(result.id, 1);
        expect(result.name, 'Frutas');
        expect(result.slug, 'frutas');
        expect(result.sortOrder, 1);
        expect(result.isActive, true);
        expect(result.productsCount, 5);
        verify(() => mockClient.get('/admin/categories/1')).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.get('/admin/categories/999')).thenThrow(Exception('Not found'));

        expect(
          () => repository.getById(999),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('create', () {
      test('returns created Category on success', () async {
        final createData = {
          'name': 'Verduras',
          'slug': 'verduras',
          'sort_order': 2,
          'is_active': true,
        };

        when(() => mockClient.post('/admin/categories', data: createData)).thenAnswer((_) async => Response(
              data: tCreatedCategoryJson,
              statusCode: 201,
              requestOptions: RequestOptions(path: '/admin/categories'),
            ));

        final result = await repository.create(createData);

        expect(result, isA<Category>());
        expect(result.id, 2);
        expect(result.name, 'Verduras');
        expect(result.slug, 'verduras');
        expect(result.sortOrder, 2);
        expect(result.isActive, true);
        expect(result.productsCount, 3);
        verify(() => mockClient.post('/admin/categories', data: createData)).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.post('/admin/categories', data: any(named: 'data')))
            .thenThrow(Exception('Validation error'));

        expect(
          () => repository.create({'name': ''}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('update', () {
      test('returns updated Category on success', () async {
        final updateData = {
          'name': 'Frutas Atualizadas',
          'sort_order': 5,
        };

        const updatedResponse = {
          'data': {
            'id': 1,
            'parent_id': null,
            'name': 'Frutas Atualizadas',
            'slug': 'frutas',
            'icon_url': null,
            'image_url': null,
            'sort_order': 5,
            'is_active': true,
            'products_count': 5,
          },
        };

        when(() => mockClient.put('/admin/categories/1', data: updateData)).thenAnswer((_) async => Response(
              data: updatedResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories/1'),
            ));

        final result = await repository.update(1, updateData);

        expect(result, isA<Category>());
        expect(result.id, 1);
        expect(result.name, 'Frutas Atualizadas');
        expect(result.sortOrder, 5);
        verify(() => mockClient.put('/admin/categories/1', data: updateData)).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.put('/admin/categories/1', data: any(named: 'data')))
            .thenThrow(Exception('Not found'));

        expect(
          () => repository.update(1, {'name': 'Test'}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('delete', () {
      test('completes on success', () async {
        when(() => mockClient.delete('/admin/categories/1')).thenAnswer((_) async => Response(
              data: {'message': 'Deleted'},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/categories/1'),
            ));

        await expectLater(repository.delete(1), completes);
        verify(() => mockClient.delete('/admin/categories/1')).called(1);
      });

      test('throws on error', () async {
        when(() => mockClient.delete('/admin/categories/999')).thenThrow(Exception('Not found'));

        expect(
          () => repository.delete(999),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}