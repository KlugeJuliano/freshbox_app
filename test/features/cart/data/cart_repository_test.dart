import 'dart:convert';

import 'package:freshbox_app/core/constants/app_constants.dart';
import 'package:freshbox_app/core/storage/local_storage.dart';
import 'package:freshbox_app/features/cart/data/cart_repository.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late _MockLocalStorage mockLocalStorage;
  late CartRepository repository;

  const tCompanyId = 'test-company';
  const tDefaultCompanyId = AppConstants.companyId;
  const tCartKey = '${AppConstants.cartKey}_$tCompanyId';
  const tDefaultCartKey = '${AppConstants.cartKey}_$tDefaultCompanyId';

  final tCartItem = CartItem(
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
  );

  final tCartItem2 = CartItem(
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
  );

  final tCart = Cart(items: [tCartItem]);
  final tCartWithTwoItems = Cart(items: [tCartItem, tCartItem2]);

  setUp(() {
    mockLocalStorage = _MockLocalStorage();
    repository = CartRepository(mockLocalStorage);
  });

  group('CartRepository', () {
    group('getCart', () {
      test('returns empty cart when no data stored (uses default companyId)', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey)).thenReturn(null);

        final result = await repository.getCart();

        expect(result, equals(Cart.empty()));
        verify(() => mockLocalStorage.getString(AppConstants.companyIdKey)).called(1);
        verify(() => mockLocalStorage.getString(tDefaultCartKey)).called(1);
      });

      test('returns empty cart when stored string is empty', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey)).thenReturn('');

        final result = await repository.getCart();

        expect(result, equals(Cart.empty()));
      });

      test('returns parsed cart from valid JSON', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey))
            .thenReturn(jsonEncode(tCart.toJson()));

        final result = await repository.getCart();

        expect(result.items.length, 1);
        expect(result.items.first.productId, 1);
        expect(result.items.first.quantity, 2);
        expect(result.items.first.productName, 'Banana Nanica');
      });

      test('returns empty cart when JSON is corrupted', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey)).thenReturn('invalid json');

        final result = await repository.getCart();

        expect(result, equals(Cart.empty()));
      });
    });

    group('saveCart', () {
      test('saves cart as JSON with company-specific key (default companyId)', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey))
            .thenReturn(null);
        when(() => mockLocalStorage.setString(any(), any()))
            .thenAnswer((_) async {});

        await repository.saveCart(tCart);

        verify(() => mockLocalStorage.setString(tDefaultCartKey, jsonEncode(tCart.toJson())))
            .called(1);
      });

      test('saves cart with custom companyId', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey))
            .thenReturn(tCompanyId);
        when(() => mockLocalStorage.setString(any(), any()))
            .thenAnswer((_) async {});

        await repository.saveCart(tCart);

        verify(() => mockLocalStorage.setString(tCartKey, jsonEncode(tCart.toJson())))
            .called(1);
      });
    });

    group('clearCart', () {
      test('removes cart data for current company (default)', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey))
            .thenReturn(null);
        when(() => mockLocalStorage.remove(tDefaultCartKey)).thenAnswer((_) async {});

        await repository.clearCart();

        verify(() => mockLocalStorage.remove(tDefaultCartKey)).called(1);
      });

      test('removes cart data for custom company', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey))
            .thenReturn(tCompanyId);
        when(() => mockLocalStorage.remove(tCartKey)).thenAnswer((_) async {});

        await repository.clearCart();

        verify(() => mockLocalStorage.remove(tCartKey)).called(1);
      });
    });

    group('addItem', () {
      test('adds new item to empty cart', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey)).thenReturn(null);
        when(() => mockLocalStorage.setString(any(), any()))
            .thenAnswer((_) async {});

        await repository.addItem(tCartItem);

        verify(() => mockLocalStorage.setString(any(), any())).called(1);
      });

      test('increments quantity when item already exists', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey))
            .thenReturn(jsonEncode(tCart.toJson()));
        when(() => mockLocalStorage.setString(any(), any()))
            .thenAnswer((_) async {});

        final newItem = tCartItem.copyWithQuantity(3);

        await repository.addItem(newItem);

        verify(() => mockLocalStorage.setString(any(), any())).called(1);
      });
    });

    group('removeItem', () {
      test('removes item from cart', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey))
            .thenReturn(jsonEncode(tCartWithTwoItems.toJson()));
        when(() => mockLocalStorage.setString(any(), any()))
            .thenAnswer((_) async {});

        await repository.removeItem(1);

        verify(() => mockLocalStorage.setString(any(), any())).called(1);
      });
    });

    group('updateQuantity', () {
      test('updates item quantity', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey))
            .thenReturn(jsonEncode(tCart.toJson()));
        when(() => mockLocalStorage.setString(any(), any()))
            .thenAnswer((_) async {});

        await repository.updateQuantity(1, 5);

        verify(() => mockLocalStorage.setString(any(), any())).called(1);
      });

      test('does nothing when item not found', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey)).thenReturn(null);
        when(() => mockLocalStorage.getString(tDefaultCartKey))
            .thenReturn(jsonEncode(tCart.toJson()));

        await repository.updateQuantity(999, 5);

        verifyNever(() => mockLocalStorage.setString(any(), any()));
      });
    });

    group('setCompanyId', () {
      test('saves company ID to local storage', () async {
        when(() => mockLocalStorage.setString(AppConstants.companyIdKey, 'new-company'))
            .thenAnswer((_) async {});

        await repository.setCompanyId('new-company');

        verify(() => mockLocalStorage.setString(AppConstants.companyIdKey, 'new-company'))
            .called(1);
      });
    });

    group('company isolation', () {
      test('uses different cart keys for different companies', () async {
        when(() => mockLocalStorage.getString(AppConstants.companyIdKey))
            .thenReturn('company-a');
        when(() => mockLocalStorage.getString('${AppConstants.cartKey}_company-a'))
            .thenReturn(null);

        await repository.getCart();

        when(() => mockLocalStorage.getString(AppConstants.companyIdKey))
            .thenReturn('company-b');
        when(() => mockLocalStorage.getString('${AppConstants.cartKey}_company-b'))
            .thenReturn(null);

        await repository.getCart();

        verify(() => mockLocalStorage.getString('${AppConstants.cartKey}_company-a'))
            .called(1);
        verify(() => mockLocalStorage.getString('${AppConstants.cartKey}_company-b'))
            .called(1);
      });
    });
  });
}