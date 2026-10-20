import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_banner_list_event.freezed.dart';

@freezed
abstract class AdminBannerListEvent with _$AdminBannerListEvent {
  const factory AdminBannerListEvent.load() = _Load;
  const factory AdminBannerListEvent.refresh() = _Refresh;
}
