import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_product_list_event.freezed.dart';

@freezed
abstract class AdminProductListEvent with _$AdminProductListEvent {
  const factory AdminProductListEvent.load() = _Load;
  const factory AdminProductListEvent.refresh() = _Refresh;
}