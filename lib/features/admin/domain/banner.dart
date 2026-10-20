// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner.freezed.dart';
part 'banner.g.dart';

enum BannerLinkType {
  product,
  category,
  url,
  none,
  unknown;

  static BannerLinkType fromString(String? value) {
    switch (value) {
      case 'product':
        return product;
      case 'category':
        return category;
      case 'url':
        return url;
      case 'none':
        return none;
      default:
        return none;
    }
  }

  /// Valor aceito pelo backend ('product','category','url','none').
  String? get apiValue => this == unknown ? null : name;

  String get label {
    switch (this) {
      case product:
        return 'Produto';
      case category:
        return 'Categoria';
      case url:
        return 'URL externa';
      case none:
        return 'Sem link';
      default:
        return 'Sem link';
    }
  }
}

@freezed
abstract class Banner with _$Banner {
  const factory Banner({
    required int id,
    String? title,
    String? subtitle,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'image_mobile_url') String? imageMobileUrl,
    @JsonKey(name: 'link_type') @Default('none') String linkTypeRaw,
    @JsonKey(name: 'link_value') String? linkValue,
    @JsonKey(name: 'priority') @Default(0) int priority,
    @JsonKey(name: 'period_start') String? periodStartRaw,
    @JsonKey(name: 'period_end') String? periodEndRaw,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Banner;

  factory Banner.fromJson(Map<String, dynamic> json) => _$BannerFromJson(json);
}

extension BannerX on Banner {
  BannerLinkType get linkType => BannerLinkType.fromString(linkTypeRaw);

  DateTime? get periodStart =>
      periodStartRaw == null ? null : DateTime.tryParse(periodStartRaw!);

  DateTime? get periodEnd =>
      periodEndRaw == null ? null : DateTime.tryParse(periodEndRaw!);
}
