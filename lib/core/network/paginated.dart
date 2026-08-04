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
    final meta = json['meta'] as Map<String, dynamic>;
    return Paginated<T>(
      data: (json['data'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
    );
  }
}