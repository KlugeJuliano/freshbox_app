import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/category/domain/category.dart';

part 'admin_category_list_state.freezed.dart';

@freezed
abstract class AdminCategoryListState with _$AdminCategoryListState {
  const factory AdminCategoryListState.initial() = _Initial;
  const factory AdminCategoryListState.loading() = _Loading;
  const factory AdminCategoryListState.loaded(List<Category> categories) = _Loaded;
  const factory AdminCategoryListState.error(String message) = _Error;
}