import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_order_repository.dart';
import 'admin_order_detail_event.dart';
import 'admin_order_detail_state.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';

class AdminOrderDetailBloc
    extends Bloc<AdminOrderDetailEvent, AdminOrderDetailState> {
  AdminOrderDetailBloc(this._repository) : super(const AdminOrderDetailState.initial()) {
    on<AdminOrderDetailEvent>((event, emit) async {
      await event.when(
        load: (orderId) => _onLoad(emit, orderId),
        updateStatus: (status) => _onUpdateStatus(emit, status),
      );
    });
  }

  final AdminOrderRepository _repository;

  Future<void> _onLoad(Emitter<AdminOrderDetailState> emit, String orderId) async {
    emit(const AdminOrderDetailState.loading());
    try {
      final order = await _repository.getById(orderId);
      emit(AdminOrderDetailState.loaded(order));
    } catch (e) {
      emit(AdminOrderDetailState.error(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(Emitter<AdminOrderDetailState> emit, AdminOrderStatus status) async {
    final currentOrder = state.maybeWhen(
      loaded: (order) => order,
      orElse: () => null,
    );
    if (currentOrder == null) return;

    // Validate transition
    final isDelivery = currentOrder.deliveryType == 'delivery';
    final validTransitions = currentOrder.status.validTransitions(isDelivery: isDelivery);
    if (!validTransitions.contains(status)) {
      emit(AdminOrderDetailState.error('Transição inválida: ${currentOrder.status.label} → ${status.label}'));
      return;
    }

    emit(const AdminOrderDetailState.updating());
    try {
      final updatedOrder = await _repository.updateStatus(currentOrder.id, status);
      emit(AdminOrderDetailState.loaded(updatedOrder));
    } catch (e) {
      emit(AdminOrderDetailState.error(e.toString()));
    }
  }
}