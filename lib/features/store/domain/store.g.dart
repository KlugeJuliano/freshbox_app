// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreImpl _$$StoreImplFromJson(Map<String, dynamic> json) => _$StoreImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String?,
      logoUrl: json['logo_url'] as String?,
      whatsapp: json['whatsapp'] as String?,
      isOpen: json['open_now'] as bool,
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
    );

Map<String, dynamic> _$$StoreImplToJson(_$StoreImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'logo_url': instance.logoUrl,
      'whatsapp': instance.whatsapp,
      'open_now': instance.isOpen,
      'delivery_fee': instance.deliveryFee,
    };
