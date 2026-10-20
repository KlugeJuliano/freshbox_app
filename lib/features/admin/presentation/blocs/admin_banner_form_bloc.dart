import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freshbox_app/core/errors/api_error_mapper.dart';

import '../../data/admin_banner_repository.dart';
import 'admin_banner_form_event.dart';
import 'admin_banner_form_state.dart';

class AdminBannerFormBloc
    extends Bloc<AdminBannerFormEvent, AdminBannerFormState> {
  AdminBannerFormBloc(this._repository)
      : super(const AdminBannerFormState.initial()) {
    on<AdminBannerFormEvent>((event, emit) async {
      await event.when(
        create: (data, image, imageMobile) =>
            _onCreate(data, image, imageMobile, emit),
        update: (id, data, image, imageMobile) =>
            _onUpdate(id, data, image, imageMobile, emit),
        delete: (id) => _onDelete(id, emit),
        toggle: (id) => _onToggle(id, emit),
      );
    });
  }

  final AdminBannerRepository _repository;

  Future<void> _onCreate(
    Map<String, dynamic> data,
    File image,
    File? imageMobile,
    Emitter<AdminBannerFormState> emit,
  ) async {
    emit(const AdminBannerFormState.submitting());
    try {
      final banner =
          await _repository.create(data, image, imageMobileFile: imageMobile);
      emit(AdminBannerFormState.success(banner, 'Banner criado com sucesso'));
    } catch (e) {
      emit(AdminBannerFormState.error(describeError(e)));
    }
  }

  Future<void> _onUpdate(
    int id,
    Map<String, dynamic> data,
    File? image,
    File? imageMobile,
    Emitter<AdminBannerFormState> emit,
  ) async {
    emit(const AdminBannerFormState.submitting());
    try {
      final banner = await _repository.update(
        id,
        data,
        imageFile: image,
        imageMobileFile: imageMobile,
      );
      emit(AdminBannerFormState.success(
          banner, 'Banner atualizado com sucesso'));
    } catch (e) {
      emit(AdminBannerFormState.error(describeError(e)));
    }
  }

  Future<void> _onDelete(
    int id,
    Emitter<AdminBannerFormState> emit,
  ) async {
    emit(const AdminBannerFormState.submitting());
    try {
      await _repository.delete(id);
      emit(const AdminBannerFormState.success(
          null, 'Banner excluído com sucesso'));
    } catch (e) {
      emit(AdminBannerFormState.error(describeError(e)));
    }
  }

  Future<void> _onToggle(
    int id,
    Emitter<AdminBannerFormState> emit,
  ) async {
    emit(const AdminBannerFormState.submitting());
    try {
      final banner = await _repository.toggle(id);
      emit(AdminBannerFormState.success(
        banner,
        banner.isActive ? 'Banner ativado' : 'Banner desativado',
      ));
    } catch (e) {
      emit(AdminBannerFormState.error(describeError(e)));
    }
  }
}
