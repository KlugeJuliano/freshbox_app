import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc(this._repository) : super(const CategoryState.initial()) {
    on<CategoryEvent>((event, emit) async {
      await event.when(
        loadCategories: () => _onLoadCategories(emit),
        refreshCategories: () => _onRefreshCategories(emit),
      );
    });
  }

  Future<void> _onLoadCategories(Emitter<CategoryState> emit) async {
    emit(const CategoryState.loading());
    try {
      final result = await _repository.getCategories();
      emit(CategoryState.loaded(result.data));
    } catch (e) {
      emit(CategoryState.error(e.toString()));
    }
  }

  Future<void> _onRefreshCategories(Emitter<CategoryState> emit) async {
    try {
      final result = await _repository.getCategories();
      emit(CategoryState.loaded(result.data));
    } catch (e) {
      emit(CategoryState.error(e.toString()));
    }
  }
}
