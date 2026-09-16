import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated.freezed.dart';

@Freezed(genericArgumentFactories: true)
abstract class Paginated<T> with _$Paginated<T> {
  const factory Paginated({
    required List<T> data,
    required int currentPage,
    required int lastPage,
    required int total,
  }) = _Paginated<T>;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final dataList = json['data'] as List;
    final items = dataList
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>?;
    if (meta == null) {
      // Endpoint não paginado (ex: /products/featured) — trata como página única
      return Paginated<T>(
        data: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
      );
    }

    return Paginated<T>(
      data: items,
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
    );
  }
}
