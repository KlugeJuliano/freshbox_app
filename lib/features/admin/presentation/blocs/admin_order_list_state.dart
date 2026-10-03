import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/admin/domain/admin_order.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';

part 'admin_order_list_state.freezed.dart';

@freezed
abstract class AdminOrderListState with _$AdminOrderListState {
  const factory AdminOrderListState.initial() = _Initial;
  const factory AdminOrderListState.loading() = _Loading;
  const factory AdminOrderListState.loaded({
    required List<AdminOrder> orders,
    required bool hasReachedMax,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    AdminOrderStatus? currentFilter,
  }) = _Loaded;
  const factory AdminOrderListState.error(String message) = _Error;
}