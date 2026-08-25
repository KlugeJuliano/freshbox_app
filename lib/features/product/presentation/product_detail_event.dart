import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_detail_event.freezed.dart';

@freezed
abstract class ProductDetailEvent with _$ProductDetailEvent {
  const factory ProductDetailEvent.load(String slug) = _Load;
  const factory ProductDetailEvent.refresh(String slug) = _Refresh;
}
