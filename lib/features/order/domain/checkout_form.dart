import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout_form.freezed.dart';
part 'checkout_form.g.dart';

@freezed
abstract class CheckoutForm with _$CheckoutForm {
  const factory CheckoutForm({
    required String name,
    required String phone,
    required String address,
    required String deliveryType, // 'delivery' or 'pickup'
    String? observations,
    String? cep,
  }) = _CheckoutForm;

  factory CheckoutForm.fromJson(Map<String, dynamic> json) => _$CheckoutFormFromJson(json);
}

extension CheckoutFormX on CheckoutForm {
  Map<String, dynamic> toOrderRequest() => {
        'customer_name': name,
        'customer_phone': phone,
        'customer_address': address,
        'delivery_type': deliveryType,
        'observations': observations,
      };

  Map<String, String> validate() {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Nome é obrigatório';
    } else if (name.trim().length < 3) {
      errors['name'] = 'Nome deve ter pelo menos 3 caracteres';
    }

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isEmpty) {
      errors['phone'] = 'Telefone é obrigatório';
    } else if (phoneDigits.length < 10 || phoneDigits.length > 11) {
      errors['phone'] = 'Telefone inválido';
    }

    if (deliveryType == 'delivery') {
      if (address.trim().isEmpty) {
        errors['address'] = 'Endereço é obrigatório para entrega';
      } else if (address.trim().length < 10) {
        errors['address'] = 'Endereço muito curto';
      }
    }

    if (cep != null && cep!.isNotEmpty) {
      final cepDigits = cep!.replaceAll(RegExp(r'\D'), '');
      if (cepDigits.length != 8) {
        errors['cep'] = 'CEP inválido';
      }
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;
}