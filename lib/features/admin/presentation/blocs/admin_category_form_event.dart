import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_category_form_event.freezed.dart';

@freezed
abstract class AdminCategoryFormEvent with _$AdminCategoryFormEvent {
  const factory AdminCategoryFormEvent.create(Map<String, dynamic> data) = _Create;
  const factory AdminCategoryFormEvent.update(int id, Map<String, dynamic> data) = _Update;
  const factory AdminCategoryFormEvent.delete(int id) = _Delete;
  const factory AdminCategoryFormEvent.reset() = _Reset;
}