import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_category_list_event.freezed.dart';

@freezed
abstract class AdminCategoryListEvent with _$AdminCategoryListEvent {
  const factory AdminCategoryListEvent.load() = _Load;
  const factory AdminCategoryListEvent.refresh() = _Refresh;
}