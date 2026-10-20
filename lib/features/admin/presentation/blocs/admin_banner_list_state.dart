import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/admin/domain/banner.dart';

part 'admin_banner_list_state.freezed.dart';

@freezed
abstract class AdminBannerListState with _$AdminBannerListState {
  const factory AdminBannerListState.initial() = _Initial;
  const factory AdminBannerListState.loading() = _Loading;
  const factory AdminBannerListState.loaded(List<Banner> banners) = _Loaded;
  const factory AdminBannerListState.error(String message) = _Error;
}
