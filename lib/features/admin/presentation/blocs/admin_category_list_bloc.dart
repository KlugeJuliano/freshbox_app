import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_category_repository.dart';
import 'admin_category_list_event.dart';
import 'admin_category_list_state.dart';

class AdminCategoryListBloc
    extends Bloc<AdminCategoryListEvent, AdminCategoryListState> {
  AdminCategoryListBloc(this._repository)
      : super(const AdminCategoryListState.initial()) {
    on<AdminCategoryListEvent>((event, emit) async {
      await event.when(
        load: () => _onLoad(emit),
        refresh: () => _onLoad(emit),
      );
    });
  }

  final AdminCategoryRepository _repository;

  Future<void> _onLoad(Emitter<AdminCategoryListState> emit) async {
    emit(const AdminCategoryListState.loading());
    try {
      final categories = await _repository.getAll();
      emit(AdminCategoryListState.loaded(categories));
    } catch (e) {
      emit(AdminCategoryListState.error(e.toString()));
    }
  }
}