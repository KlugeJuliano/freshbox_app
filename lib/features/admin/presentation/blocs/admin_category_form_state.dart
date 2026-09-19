import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/category/domain/category.dart';

part 'admin_category_form_state.freezed.dart';

@freezed
abstract class AdminCategoryFormState with _$AdminCategoryFormState {
  const factory AdminCategoryFormState.initial() = _Initial;
  const factory AdminCategoryFormState.submitting() = _Submitting;
  // `category` vem null no caso de delete bem-sucedido.
  const factory AdminCategoryFormState.success(Category? category, String message) = _Success;
  const factory AdminCategoryFormState.error(String message) = _Error;
}