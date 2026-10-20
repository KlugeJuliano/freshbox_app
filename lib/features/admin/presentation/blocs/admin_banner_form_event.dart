import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_banner_form_event.freezed.dart';

@freezed
abstract class AdminBannerFormEvent with _$AdminBannerFormEvent {
  const factory AdminBannerFormEvent.create(
    Map<String, dynamic> data,
    File image, {
    File? imageMobile,
  }) = _Create;
  const factory AdminBannerFormEvent.update(
    int id,
    Map<String, dynamic> data, {
    File? image,
    File? imageMobile,
  }) = _Update;
  const factory AdminBannerFormEvent.delete(int id) = _Delete;
  const factory AdminBannerFormEvent.toggle(int id) = _Toggle;
}
