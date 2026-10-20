import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freshbox_app/core/errors/api_error_mapper.dart';

import '../../data/admin_banner_repository.dart';
import 'admin_banner_list_event.dart';
import 'admin_banner_list_state.dart';

class AdminBannerListBloc
    extends Bloc<AdminBannerListEvent, AdminBannerListState> {
  AdminBannerListBloc(this._repository)
      : super(const AdminBannerListState.initial()) {
    on<AdminBannerListEvent>((event, emit) async {
      await event.when(
        load: () => _onLoad(emit),
        refresh: () => _onLoad(emit),
      );
    });
  }

  final AdminBannerRepository _repository;

  Future<void> _onLoad(Emitter<AdminBannerListState> emit) async {
    emit(const AdminBannerListState.loading());
    try {
      final banners = await _repository.getAll();
      emit(AdminBannerListState.loaded(banners));
    } catch (e) {
      emit(AdminBannerListState.error(describeError(e)));
    }
  }
}
