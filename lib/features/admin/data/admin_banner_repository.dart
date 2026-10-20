import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/admin/domain/banner.dart';

class AdminBannerRepository {
  AdminBannerRepository(this._client);

  final DioClient _client;

  static const _endpoint = '/admin/banners';

  /// Coleção completa (sem paginação), ordenada por priority desc no backend.
  Future<List<Banner>> getAll() async {
    final response = await _client.get(_endpoint);
    final data = response.data['data'] as List;
    return data.map((e) => Banner.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST multipart — o backend exige `image` no create e gera o `image_url`.
  /// Campos de texto vão como strings; `image`/`image_mobile` como arquivos.
  Future<Banner> create(
    Map<String, dynamic> data,
    File imageFile, {
    File? imageMobileFile,
  }) async {
    final response = await _client.postMultipart(_endpoint, data: {
      ...data,
      'image':
          await MultipartFile.fromFile(imageFile.path, filename: 'image.jpg'),
      if (imageMobileFile != null)
        'image_mobile': await MultipartFile.fromFile(imageMobileFile.path,
            filename: 'image_mobile.jpg'),
    });
    return Banner.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Banner> update(
    int id,
    Map<String, dynamic> data, {
    File? imageFile,
    File? imageMobileFile,
  }) async {
    final response = await _client.putMultipart('$_endpoint/$id', data: {
      ...data,
      if (imageFile != null)
        'image':
            await MultipartFile.fromFile(imageFile.path, filename: 'image.jpg'),
      if (imageMobileFile != null)
        'image_mobile': await MultipartFile.fromFile(imageMobileFile.path,
            filename: 'image_mobile.jpg'),
    });
    return Banner.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _client.delete('$_endpoint/$id');
  }

  Future<Banner> toggle(int id) async {
    final response = await _client.patch('$_endpoint/$id/toggle');
    return Banner.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
