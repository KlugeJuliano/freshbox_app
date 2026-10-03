// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_delivery_address.freezed.dart';
part 'admin_delivery_address.g.dart';

@freezed
abstract class AdminDeliveryAddress with _$AdminDeliveryAddress {
  const factory AdminDeliveryAddress({
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    @JsonKey(name: 'zip') String? zipCode,
  }) = _AdminDeliveryAddress;

  factory AdminDeliveryAddress.fromJson(Map<String, dynamic> json) =>
      _$AdminDeliveryAddressFromJson(json);
}