import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_bloc.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_state.dart';
import 'package:freshbox_app/features/order/data/order_repository.dart';
import 'package:freshbox_app/features/order/domain/checkout_form.dart';
import 'package:freshbox_app/features/order/domain/order.dart';
import 'package:freshbox_app/features/order/domain/order_item.dart';
import 'package:freshbox_app/core/network/api_exception.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}
class _MockCartBloc extends Mock implements CartBloc {}

void main() {
  late _MockOrderRepository mockOrderRepository;
  late _MockCartBloc mockCartBloc;
  late CheckoutBloc checkoutBloc;

  final tItems = [
    CartItem(
      productId: 1,
      productName: 'Banana Nanica',
      productSlug: 'banana-nanica',
      productImage: null,
      unitLabel: 'kg',
      price: 4.99,
      promoPrice: null,
      effectivePrice: 4.99,
      quantity: 2,
      hasPromo: false,
    ),
    CartItem(
      productId: 2,
      productName: 'Maçã Fuji',
      productSlug: 'maca-fuji',
      productImage: null,
      unitLabel: 'kg',
      price: 8.99,
      promoPrice: 6.99,
      effectivePrice: 6.99,
      quantity: 1,
      hasPromo: true,
    ),
  ];

  const tValidDeliveryForm = CheckoutForm(
    name: 'João Silva',
    phone: '11999998888',
    address: 'Rua das Flores, 123, Apto 45 - Centro, São Paulo - SP',
    deliveryType: 'delivery',
    observations: 'Interfone 45',
    cep: '01000000',
  );

  const tValidPickupForm = CheckoutForm(
    name: 'Maria Santos',
    phone: '11988887777',
    address: '',
    deliveryType: 'pickup',
    observations: 'Retirar às 18h',
    cep: null,
  );

  const tInvalidDeliveryFormNoAddress = CheckoutForm(
    name: 'João Silva',
    phone: '11999998888',
    address: '',
    deliveryType: 'delivery',
  );

  const tInvalidDeliveryFormShortAddress = CheckoutForm(
    name: 'João Silva',
    phone: '11999998888',
    address: 'Rua A, 1',
    deliveryType: 'delivery',
  );

  const tInvalidDeliveryFormInvalidCep = CheckoutForm(
    name: 'João Silva',
    phone: '11999998888',
    address: 'Rua das Flores, 123',
    deliveryType: 'delivery',
    cep: '12345',
  );

  const tInvalidDeliveryFormInvalidPhone = CheckoutForm(
    name: 'João Silva',
    phone: '123',
    address: 'Rua das Flores, 123',
    deliveryType: 'delivery',
  );

  const tInvalidDeliveryFormShortName = CheckoutForm(
    name: 'Jo',
    phone: '11999998888',
    address: 'Rua das Flores, 123',
    deliveryType: 'delivery',
  );

  const tPickupFormNoAddress = CheckoutForm(
    name: 'Maria Santos',
    phone: '11988887777',
    address: '',
    deliveryType: 'pickup',
  );

  final tOrder = Order(
    id: 123,
    uuid: 'ORD-123',
    status: 'pending',
    customerName: 'João Silva',
    customerPhone: '11999998888',
    customerAddress: 'Rua das Flores, 123, Apto 45 - Centro, São Paulo - SP',
    deliveryType: 'delivery',
    deliveryFee: 5.00,
    subtotal: 16.97,
    total: 21.97,
    items: [
      OrderItem.fromCartItem(tItems[0]),
      OrderItem.fromCartItem(tItems[1]),
    ],
    whatsappUrl: 'https://wa.me/5511999998888?text=Pedido%20ORD-123',
    createdAt: '2026-01-15T10:30:00Z',
  );

  setUp(() {
    mockOrderRepository = _MockOrderRepository();
    mockCartBloc = _MockCartBloc();
    checkoutBloc = CheckoutBloc(mockOrderRepository, mockCartBloc);
  });

  tearDown(() {
    checkoutBloc.close();
  });

  group('CheckoutBloc', () {
    group('submitOrder - delivery with full address', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [loading, success] when delivery form is valid and backend succeeds',
        build: () {
          when(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems))
              .thenAnswer((_) async => tOrder);
          when(() => mockCartBloc.add(const CartEvent.clearCart())).thenReturn(null);
          when(() => mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tValidDeliveryForm, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          CheckoutState.success(tOrder),
        ],
        verify: (_) {
          verify(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems))
              .called(1);
          verify(() => mockCartBloc.add(const CartEvent.clearCart())).called(1);
        },
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [validationError] when delivery form missing address',
        build: () => checkoutBloc,
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tInvalidDeliveryFormNoAddress, items: tItems),
        ),
        expect: () => [
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(validationError: (e) => e, orElse: () => null),
            'validationError',
            isA<Map<String, String>>()
                .having((e) => e['address'], 'address', 'Endereço é obrigatório para entrega'),
          ),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [validationError] when delivery form has short address',
        build: () => checkoutBloc,
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tInvalidDeliveryFormShortAddress, items: tItems),
        ),
        expect: () => [
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(validationError: (e) => e, orElse: () => null),
            'validationError',
            isA<Map<String, String>>()
                .having((e) => e['address'], 'address', 'Endereço muito curto'),
          ),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [validationError] when CEP is invalid',
        build: () => checkoutBloc,
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tInvalidDeliveryFormInvalidCep, items: tItems),
        ),
        expect: () => [
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(validationError: (e) => e, orElse: () => null),
            'validationError',
            isA<Map<String, String>>()
                .having((e) => e['cep'], 'cep', 'CEP inválido'),
          ),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [validationError] when phone is invalid',
        build: () => checkoutBloc,
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tInvalidDeliveryFormInvalidPhone, items: tItems),
        ),
        expect: () => [
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(validationError: (e) => e, orElse: () => null),
            'validationError',
            isA<Map<String, String>>()
                .having((e) => e['phone'], 'phone', 'Telefone inválido'),
          ),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [validationError] when name is too short',
        build: () => checkoutBloc,
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tInvalidDeliveryFormShortName, items: tItems),
        ),
        expect: () => [
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(validationError: (e) => e, orElse: () => null),
            'validationError',
            isA<Map<String, String>>()
                .having((e) => e['name'], 'name', 'Nome deve ter pelo menos 3 caracteres'),
          ),
        ],
      );
    });

    group('submitOrder - pickup (no address required)', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [loading, success] when pickup form is valid',
        build: () {
          when(() => mockOrderRepository.createOrder(tValidPickupForm, tItems))
              .thenAnswer((_) async => tOrder.copyWith(
                deliveryType: 'pickup',
                deliveryFee: 0,
                customerAddress: '',
              ));
          when(() => mockCartBloc.add(const CartEvent.clearCart())).thenReturn(null);
          when(() => mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tValidPickupForm, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(success: (o) => o, orElse: () => null),
            'success order',
            isA<Order>().having((o) => o.deliveryType, 'deliveryType', 'pickup'),
          ),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'does not require address for pickup',
        build: () {
          when(() => mockOrderRepository.createOrder(tPickupFormNoAddress, tItems))
              .thenAnswer((_) async => tOrder.copyWith(deliveryType: 'pickup', customerAddress: ''));
          when(() => mockCartBloc.add(const CartEvent.clearCart())).thenReturn(null);
          when(() => mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tPickupFormNoAddress, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          isA<CheckoutState>().having(
            (s) => s.maybeWhen(success: (o) => o, orElse: () => null),
            'success',
            isNotNull,
          ),
        ],
      );
    });

    group('submitOrder - error handling', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [loading, error] when ApiException thrown',
        build: () {
          when(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems))
              .thenThrow(ApiException(message: 'Produto fora de estoque', statusCode: 400));
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tValidDeliveryForm, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          CheckoutState.error('Produto fora de estoque'),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [loading, error] when DioException thrown',
        build: () {
          when(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems))
              .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/orders'),
            response: Response(
              data: {'message': 'Erro interno do servidor'},
              statusCode: 500,
              requestOptions: RequestOptions(path: '/orders'),
            ),
          ));
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tValidDeliveryForm, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          CheckoutState.error('Erro no servidor. Tente novamente em alguns instantes.'),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [loading, error] when generic exception thrown',
        build: () {
          when(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems))
              .thenThrow(Exception('Unexpected error'));
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tValidDeliveryForm, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          CheckoutState.error('Erro inesperado. Tente novamente.'),
        ],
      );
    });

    group('submitOrder - duplicate prevention', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'includes duplicate prevention guard in handler',
        build: () {
          when(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems))
              .thenAnswer((_) async => tOrder);
          when(() => mockCartBloc.add(const CartEvent.clearCart())).thenReturn(null);
          when(() => mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(
          CheckoutEvent.submitOrder(form: tValidDeliveryForm, items: tItems),
        ),
        expect: () => [
          const CheckoutState.loading(),
          CheckoutState.success(tOrder),
        ],
        verify: (_) {
          verify(() => mockOrderRepository.createOrder(tValidDeliveryForm, tItems)).called(1);
        },
      );
    });
  });
}