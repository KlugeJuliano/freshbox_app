import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_product_form_event.freezed.dart';

@freezed
abstract class AdminProductFormEvent with _$AdminProductFormEvent {
  const factory AdminProductFormEvent.create(
    Map<String, dynamic> data, {
    File? image,
  }) = _Create;
  const factory AdminProductFormEvent.update(
    int id,
    Map<String, dynamic> data, {
    File? image,
  }) = _Update;
  const factory AdminProductFormEvent.delete(int id) = _Delete;
  const factory AdminProductFormEvent.reset() = _Reset;
}
