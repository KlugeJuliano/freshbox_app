import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshbox_app/features/product/domain/product.dart';

part 'admin_product_form_state.freezed.dart';

@freezed
abstract class AdminProductFormState with _$AdminProductFormState {
  const factory AdminProductFormState.initial() = _Initial;
  const factory AdminProductFormState.submitting() = _Submitting;
  // `product` vem null no caso de delete bem-sucedido.
  const factory AdminProductFormState.success(Product? product, String message) = _Success;
  const factory AdminProductFormState.error(String message) = _Error;
}