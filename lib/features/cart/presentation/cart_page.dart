import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_event.dart';
import 'package:freshbox_app/features/cart/presentation/cart_state.dart';
import 'package:freshbox_app/features/cart/presentation/widgets/cart_empty_widget.dart';
import 'package:freshbox_app/features/cart/presentation/widgets/cart_item_widget.dart';
import 'package:freshbox_app/features/cart/presentation/widgets/cart_summary_widget.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<CartBloc>()..add(const CartEvent.loadCart()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carrinho'),
          centerTitle: true,
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            return state.when(
              initial: () => const _LoadingView(),
              loading: () => const _LoadingView(),
              loaded: (cart) => _LoadedView(cart: cart),
              error: (message) => _ErrorView(
                message: message,
                onRetry: () => context.read<CartBloc>().add(const CartEvent.loadCart()),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) {
      return const CartEmptyWidget();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return CartItemWidget(
                item: item,
                onQuantityChanged: (quantity) => context.read<CartBloc>().add(
                      CartEvent.updateQuantity(item.productId, quantity),
                    ),
                onRemove: () => context.read<CartBloc>().add(
                      CartEvent.removeItem(item.productId),
                    ),
              );
            },
          ),
        ),
        CartSummaryWidget(
          subtotal: cart.subtotal,
          onCheckout: () => context.push('/cart/checkout'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar carrinho',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}