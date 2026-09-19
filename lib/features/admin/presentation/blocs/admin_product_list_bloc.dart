import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_product_repository.dart';
import 'admin_product_list_event.dart';
import 'admin_product_list_state.dart';

class AdminProductListBloc
    extends Bloc<AdminProductListEvent, AdminProductListState> {
  AdminProductListBloc(this._repository)
      : super(const AdminProductListState.initial()) {
    on<AdminProductListEvent>((event, emit) async {
      await event.when(
        load: () => _onLoad(emit),
        refresh: () => _onLoad(emit),
      );
    });
  }

  final AdminProductRepository _repository;

  Future<void> _onLoad(Emitter<AdminProductListState> emit) async {
    emit(const AdminProductListState.loading());
    try {
      final products = await _repository.getAll();
      emit(AdminProductListState.loaded(products));
    } catch (e) {
      emit(AdminProductListState.error(e.toString()));
    }
  }
}