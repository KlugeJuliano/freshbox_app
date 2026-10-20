import 'dart:io';

import 'package:dio/dio.dart';
import 'package:freshbox_app/core/network/api_exception.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/admin/data/admin_banner_repository.dart';
import 'package:freshbox_app/features/admin/domain/banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  late _MockDioClient mockClient;
  late AdminBannerRepository repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockClient = _MockDioClient();
    repository = AdminBannerRepository(mockClient);
  });

  const tBannerJson = {
    'id': 1,
    'title': 'Promo do fim de semana',
    'subtitle': 'Até 50% OFF',
    'image_url': '/storage/banners/1.jpg',
    'image_mobile_url': null,
    'link_type': 'product',
    'link_value': 'banana-nanica',
    'priority': 10,
    'period_start': '2026-10-01T00:00:00.000000Z',
    'period_end': '2026-10-31T23:59:59.000000Z',
    'is_active': true,
  };

  group('AdminBannerRepository', () {
    group('getAll', () {
      test('returns List<Banner> on success', () async {
        when(() => mockClient.get('/admin/banners')).thenAnswer((_) async =>
            Response(
                data: {
                  'data': [tBannerJson]
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/admin/banners')));

        final result = await repository.getAll();

        expect(result, isA<List<Banner>>());
        expect(result.length, 1);
        final banner = result.first;
        expect(banner.id, 1);
        expect(banner.title, 'Promo do fim de semana');
        expect(banner.linkType, BannerLinkType.product);
        expect(banner.linkValue, 'banana-nanica');
        expect(banner.priority, 10);
        expect(banner.isActive, true);
        expect(banner.periodStart, isNotNull);
        expect(banner.periodEnd, isNotNull);
      });

      test('returns empty list', () async {
        when(() => mockClient.get('/admin/banners')).thenAnswer((_) async =>
            Response(
                data: {'data': []},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/admin/banners')));

        expect(await repository.getAll(), isEmpty);
      });

      test('throws ApiException with translated message on 422', () async {
        when(() => mockClient.get('/admin/banners')).thenThrow(
          ApiException(
            message: 'Erro de validação.',
            statusCode: 422,
          ),
        );

        expect(
          () => repository.getAll(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('create / update multipart', () {
      final tempDir = Directory.systemTemp.createTempSync('banner_test');
      late File imageFile;

      setUpAll(() {
        imageFile = File('${tempDir.path}/banner.jpg')
          ..writeAsBytesSync(List.filled(16, 1));
      });

      tearDownAll(() {
        tempDir.deleteSync(recursive: true);
      });

      test('create posts multipart with image and parses wrapped data',
          () async {
        when(() => mockClient.postMultipart(
              '/admin/banners',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {'data': tBannerJson},
              statusCode: 201,
              requestOptions: RequestOptions(path: '/admin/banners'),
            ));

        final banner = await repository.create({
          'title': 'Promo do fim de semana',
          'priority': '10',
          'is_active': 'true',
        }, imageFile);

        expect(banner.id, 1);
        verify(() => mockClient.postMultipart(
              '/admin/banners',
              data: any(named: 'data'),
            )).called(1);
      });

      test('update uses putMultipart and parses wrapped data', () async {
        when(() => mockClient.putMultipart(
              '/admin/banners/1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {'data': tBannerJson},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/admin/banners/1'),
            ));

        final banner = await repository.update(1, {'priority': '20'},
            imageFile: imageFile);

        expect(banner.id, 1);
        verify(() => mockClient.putMultipart(
              '/admin/banners/1',
              data: any(named: 'data'),
            )).called(1);
      });
    });

    group('delete / toggle', () {
      test('delete completes', () async {
        when(() => mockClient.delete('/admin/banners/1')).thenAnswer(
            (_) async => Response(
                data: null,
                statusCode: 204,
                requestOptions: RequestOptions(path: '/admin/banners/1')));

        await expectLater(repository.delete(1), completes);
      });

      test('toggle returns updated Banner', () async {
        final inactiveJson = Map.of(tBannerJson)..['is_active'] = false;
        when(() => mockClient.patch('/admin/banners/1/toggle'))
            .thenAnswer((_) async => Response(
                  data: {'data': inactiveJson},
                  statusCode: 200,
                  requestOptions:
                      RequestOptions(path: '/admin/banners/1/toggle'),
                ));

        final banner = await repository.toggle(1);

        expect(banner.isActive, false);
        verify(() => mockClient.patch('/admin/banners/1/toggle')).called(1);
      });
    });
  });
}
