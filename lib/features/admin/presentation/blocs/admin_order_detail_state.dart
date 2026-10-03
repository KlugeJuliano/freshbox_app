import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/admin/domain/admin_order.dart';

part 'admin_order_detail_state.freezed.dart';

@freezed
abstract class AdminOrderDetailState with _$AdminOrderDetailState {
  const factory AdminOrderDetailState.initial() = _Initial;
  const factory AdminOrderDetailState.loading() = _Loading;
  const factory AdminOrderDetailState.loaded(AdminOrder order) = _Loaded;
  const factory AdminOrderDetailState.updating() = _Updating;
  const factory AdminOrderDetailState.error(String message) = _Error;
}