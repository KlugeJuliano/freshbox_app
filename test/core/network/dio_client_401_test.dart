import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshbox_app/core/network/dio_client.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message": "Unauthenticated."}',
      statusCode,
      headers: {
        'content-type': [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DioClient 401 -> unauthorized handler', () {
    test('invokes handler on 401 for authenticated endpoint', () async {
      final dio = Dio()..httpClientAdapter = _StubAdapter(401);
      final client = DioClient(dio);
      var calls = 0;
      client.setTokenProvider(() async => 'abc');
      client.setUnauthorizedHandler(() => calls++);

      final future = client.get('/admin/products');
      await expectLater(future, throwsA(isA<Exception>()));
      expect(calls, 1);
    });

    test('does NOT invoke handler on 401 from /auth/login', () async {
      final dio = Dio()..httpClientAdapter = _StubAdapter(401);
      final client = DioClient(dio);
      var calls = 0;
      client.setTokenProvider(() async => 'abc');
      client.setUnauthorizedHandler(() => calls++);

      final future = client.post(
        '/auth/login',
        data: {'email': 'x', 'password': 'x'},
      );
      await expectLater(future, throwsA(isA<Exception>()));
      expect(calls, 0);
    });

    test('invokes handler only on 401 (other statuses ignored)', () async {
      final dio = Dio()..httpClientAdapter = _StubAdapter(500);
      final client = DioClient(dio);
      var calls = 0;
      client.setTokenProvider(() async => 'abc');
      client.setUnauthorizedHandler(() => calls++);

      final future = client.get('/admin/products');
      await expectLater(future, throwsA(isA<Exception>()));
      expect(calls, 0);
    });
  });
}
