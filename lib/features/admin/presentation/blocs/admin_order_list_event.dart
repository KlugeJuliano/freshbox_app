import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';

part 'admin_order_list_event.freezed.dart';

@freezed
abstract class AdminOrderListEvent with _$AdminOrderListEvent {
  const factory AdminOrderListEvent.load({
    @Default(1) int page,
    AdminOrderStatus? status,
  }) = _Load;

  const factory AdminOrderListEvent.refresh() = _Refresh;

  const factory AdminOrderListEvent.filterStatus(AdminOrderStatus? status) = _FilterStatus;

  const factory AdminOrderListEvent.loadMore() = _LoadMore;
}