import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_category_repository.dart';
import 'admin_category_form_event.dart';
import 'admin_category_form_state.dart';

class AdminCategoryFormBloc
    extends Bloc<AdminCategoryFormEvent, AdminCategoryFormState> {
  AdminCategoryFormBloc(this._repository)
      : super(const AdminCategoryFormState.initial()) {
    on<AdminCategoryFormEvent>((event, emit) {
      event.when(
        create: (data) => _onCreate(data, emit),
        update: (id, data) => _onUpdate(id, data, emit),
        delete: (id) => _onDelete(id, emit),
        reset: () => emit(const AdminCategoryFormState.initial()),
      );
    });
  }

  final AdminCategoryRepository _repository;

  Future<void> _onCreate(
    Map<String, dynamic> data,
    Emitter<AdminCategoryFormState> emit,
  ) async {
    emit(const AdminCategoryFormState.submitting());
    try {
      final category = await _repository.create(data);
      emit(AdminCategoryFormState.success(category, 'Categoria criada com sucesso'));
    } catch (e) {
      emit(AdminCategoryFormState.error(e.toString()));
    }
  }

  Future<void> _onUpdate(
    int id,
    Map<String, dynamic> data,
    Emitter<AdminCategoryFormState> emit,
  ) async {
    emit(const AdminCategoryFormState.submitting());
    try {
      final category = await _repository.update(id, data);
      emit(AdminCategoryFormState.success(category, 'Categoria atualizada com sucesso'));
    } catch (e) {
      emit(AdminCategoryFormState.error(e.toString()));
    }
  }

  Future<void> _onDelete(
    int id,
    Emitter<AdminCategoryFormState> emit,
  ) async {
    emit(const AdminCategoryFormState.submitting());
    try {
      await _repository.delete(id);
      emit(const AdminCategoryFormState.success(null, 'Categoria excluída com sucesso'));
    } catch (e) {
      emit(AdminCategoryFormState.error(e.toString()));
    }
  }
}