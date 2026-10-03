import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';

part 'admin_order_detail_event.freezed.dart';

@freezed
abstract class AdminOrderDetailEvent with _$AdminOrderDetailEvent {
  const factory AdminOrderDetailEvent.load(String orderId) = _Load;
  const factory AdminOrderDetailEvent.updateStatus(AdminOrderStatus status) = _UpdateStatus;
}