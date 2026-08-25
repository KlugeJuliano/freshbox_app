import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_event.freezed.dart';

@freezed
abstract class CategoryEvent with _$CategoryEvent {
  const factory CategoryEvent.loadCategories() = _LoadCategories;

  const factory CategoryEvent.refreshCategories() = _RefreshCategories;
}
