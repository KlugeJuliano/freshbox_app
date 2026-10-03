import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_order_repository.dart';
import 'admin_order_list_event.dart';
import 'admin_order_list_state.dart';
import 'package:freshbox_app/features/admin/domain/admin_order.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';

class AdminOrderListBloc
    extends Bloc<AdminOrderListEvent, AdminOrderListState> {
  AdminOrderListBloc(this._repository) : super(const AdminOrderListState.initial()) {
    on<AdminOrderListEvent>((event, emit) async {
      await event.when(
        load: (page, status) => _onLoad(emit, page: page, status: status),
        refresh: () => _onRefresh(emit),
        filterStatus: (status) => _onFilterStatus(emit, status),
        loadMore: () => _onLoadMore(emit),
      );
    });
  }

  final AdminOrderRepository _repository;

  Future<void> _onLoad(
    Emitter<AdminOrderListState> emit, {
    int page = 1,
    AdminOrderStatus? status,
  }) async {
    emit(const AdminOrderListState.loading());
    try {
      final result = await _repository.getAll(page: page, status: status);
      emit(AdminOrderListState.loaded(
        orders: result.data,
        hasReachedMax: result.currentPage >= result.lastPage,
        currentPage: result.currentPage,
        totalPages: result.lastPage,
        totalItems: result.total,
        currentFilter: status,
      ));
    } catch (e) {
      emit(AdminOrderListState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<AdminOrderListState> emit) async {
    final currentFilter = _getCurrentFilter(state);
    await _onLoad(emit, page: 1, status: currentFilter);
  }

  Future<void> _onFilterStatus(
    Emitter<AdminOrderListState> emit,
    AdminOrderStatus? status,
  ) async {
    await _onLoad(emit, page: 1, status: status);
  }

  Future<void> _onLoadMore(Emitter<AdminOrderListState> emit) async {
    final loadedData = _getLoadedData(state);
    if (loadedData == null) return;

    if (loadedData.hasReachedMax) return;

    final nextPage = loadedData.currentPage + 1;
    final currentFilter = loadedData.currentFilter;

    try {
      final result = await _repository.getAll(page: nextPage, status: currentFilter);
      final combinedOrders = [
        ...loadedData.orders,
        ...result.data,
      ];
      emit(AdminOrderListState.loaded(
        orders: combinedOrders,
        hasReachedMax: result.currentPage >= result.lastPage,
        currentPage: result.currentPage,
        totalPages: result.lastPage,
        totalItems: result.total,
        currentFilter: currentFilter,
      ));
    } catch (e) {
      emit(AdminOrderListState.error(e.toString()));
    }
  }

  AdminOrderStatus? _getCurrentFilter(AdminOrderListState state) {
    return state.whenOrNull<AdminOrderStatus?>(
      loaded: (_, __, ___, ____, _____, filter) => filter,
    );
  }

  _LoadedData? _getLoadedData(AdminOrderListState state) {
    return state.whenOrNull<_LoadedData>(
      loaded: (orders, hasReachedMax, currentPage, totalPages, totalItems, currentFilter) {
        return _LoadedData(
          orders: orders,
          hasReachedMax: hasReachedMax,
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          currentFilter: currentFilter,
        );
      },
    );
  }
}

class _LoadedData {
  final List<AdminOrder> orders;
  final bool hasReachedMax;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final AdminOrderStatus? currentFilter;

  _LoadedData({
    required this.orders,
    required this.hasReachedMax,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.currentFilter,
  });
}