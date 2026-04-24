  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'store.freezed.dart';
  part 'store.g.dart';

  @freezed
  class Store with _$Store {
    const factory Store({
      required int id,
      required String name,
      String? slug,
      @JsonKey(name: 'logo_url') String? logoUrl,
      String? whatsapp,
      @JsonKey(name:'open_now') required bool isOpen,
      @JsonKey(name:'delivery_fee') required double deliveryFee,

      //String? address, ->será implementado em outro momento

    }) = _Store;

    factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
  }
