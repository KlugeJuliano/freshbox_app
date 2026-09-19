import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_product_repository.dart';
import 'admin_product_form_event.dart';
import 'admin_product_form_state.dart';

class AdminProductFormBloc
    extends Bloc<AdminProductFormEvent, AdminProductFormState> {
  AdminProductFormBloc(this._repository)
      : super(const AdminProductFormState.initial()) {
    on<AdminProductFormEvent>((event, emit) {
      event.when(
        create: (data) => _onCreate(data, emit),
        update: (id, data) => _onUpdate(id, data, emit),
        delete: (id) => _onDelete(id, emit),
        reset: () => emit(const AdminProductFormState.initial()),
      );
    });
  }

  final AdminProductRepository _repository;

  Future<void> _onCreate(
    Map<String, dynamic> data,
    Emitter<AdminProductFormState> emit,
  ) async {
    emit(const AdminProductFormState.submitting());
    try {
      final product = await _repository.create(data);
      emit(AdminProductFormState.success(product, 'Produto criado com sucesso'));
    } catch (e) {
      emit(AdminProductFormState.error(e.toString()));
    }
  }

  Future<void> _onUpdate(
    int id,
    Map<String, dynamic> data,
    Emitter<AdminProductFormState> emit,
  ) async {
    emit(const AdminProductFormState.submitting());
    try {
      final product = await _repository.update(id, data);
      emit(AdminProductFormState.success(product, 'Produto atualizado com sucesso'));
    } catch (e) {
      emit(AdminProductFormState.error(e.toString()));
    }
  }

  Future<void> _onDelete(
    int id,
    Emitter<AdminProductFormState> emit,
  ) async {
    emit(const AdminProductFormState.submitting());
    try {
      await _repository.delete(id);
      emit(const AdminProductFormState.success(null, 'Produto excluído com sucesso'));
    } catch (e) {
      emit(AdminProductFormState.error(e.toString()));
    }
  }
}