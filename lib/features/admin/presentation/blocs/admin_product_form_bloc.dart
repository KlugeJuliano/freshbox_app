import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_product_repository.dart';
import 'admin_product_form_event.dart';
import 'admin_product_form_state.dart';
import 'package:freshbox_app/core/errors/api_error_mapper.dart';

class AdminProductFormBloc
    extends Bloc<AdminProductFormEvent, AdminProductFormState> {
  AdminProductFormBloc(this._repository)
      : super(const AdminProductFormState.initial()) {
    on<AdminProductFormEvent>((event, emit) async {
      await event.when(
        create: (data, image) => _onCreate(data, image, emit),
        update: (id, data, image) => _onUpdate(id, data, image, emit),
        delete: (id) => _onDelete(id, emit),
        reset: () async => emit(const AdminProductFormState.initial()),
      );
    });
  }

  final AdminProductRepository _repository;

  /// Cria o produto e, se houver imagem, envia o multipart para
  /// /admin/products/{id}/image (o servidor gera thumb/card/full).
  Future<void> _onCreate(
    Map<String, dynamic> data,
    File? image,
    Emitter<AdminProductFormState> emit,
  ) async {
    emit(const AdminProductFormState.submitting());
    try {
      final product = await _repository.create(data);
      if (image != null) {
        try {
          final saved = await _repository.uploadImage(product.id, image);
          emit(AdminProductFormState.success(
              saved, 'Produto criado com sucesso'));
        } catch (e) {
          emit(AdminProductFormState.error(
              'Produto criado, mas o upload da imagem falhou: $e'));
        }
      } else {
        emit(AdminProductFormState.success(
            product, 'Produto criado com sucesso'));
      }
    } catch (e) {
      emit(AdminProductFormState.error(describeError(e)));
    }
  }

  Future<void> _onUpdate(
    int id,
    Map<String, dynamic> data,
    File? image,
    Emitter<AdminProductFormState> emit,
  ) async {
    emit(const AdminProductFormState.submitting());
    try {
      final product = await _repository.update(id, data);
      if (image != null) {
        try {
          final saved = await _repository.uploadImage(id, image);
          emit(AdminProductFormState.success(
              saved, 'Produto atualizado com sucesso'));
        } catch (e) {
          emit(AdminProductFormState.error(
              'Produto atualizado, mas o upload da imagem falhou: $e'));
        }
      } else {
        emit(AdminProductFormState.success(
            product, 'Produto atualizado com sucesso'));
      }
    } catch (e) {
      emit(AdminProductFormState.error(describeError(e)));
    }
  }

  Future<void> _onDelete(
    int id,
    Emitter<AdminProductFormState> emit,
  ) async {
    emit(const AdminProductFormState.submitting());
    try {
      await _repository.delete(id);
      emit(const AdminProductFormState.success(
          null, 'Produto excluído com sucesso'));
    } catch (e) {
      emit(AdminProductFormState.error(describeError(e)));
    }
  }
}
