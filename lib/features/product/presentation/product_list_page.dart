import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_state.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/presentation/product_list_bloc.dart';
import 'package:freshbox_app/features/product/presentation/product_list_event.dart';
import 'package:freshbox_app/features/product/presentation/product_list_state.dart';
import 'package:freshbox_app/features/product/presentation/product_list_type.dart';
import 'package:freshbox_app/features/product/presentation/widgets/product_card.dart';
import 'package:freshbox_app/features/product/presentation/widgets/product_shimmer.dart';
import 'package:freshbox_app/core/di/injection.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({
    super.key,
    required this.type,
    this.categorySlug,
    this.searchQuery,
  });

  final ProductListType type;
  final String? categorySlug;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        centerTitle: true,
        actions: [
          _CartBadge(),
        ],
      ),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          return state.when(
            initial: () => const _LoadingView(),
            loading: (currentType) => const _LoadingView(),
            loaded: (type, products, hasReachedMax) =>
                _LoadedView(products: products, hasReachedMax: hasReachedMax),
            error: (message, failedType) => _ErrorView(
              message: message,
              onRetry: () => context
                  .read<ProductListBloc>()
                  .add(const ProductListEvent.refresh()),
            ),
          );
        },
      ),
    );
  }

  String get _appBarTitle {
    return switch (type) {
      ProductListType.featured => 'Destaques',
      ProductListType.promo => 'Promoções',
      ProductListType.search => 'Busca: ${searchQuery ?? ''}',
      ProductListType.category => 'Produtos',
    };
  }

  void _onRetry() {
    // O Bloc já está no contexto, podemos acessar via context.read
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ProductShimmer(),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.products,
    required this.hasReachedMax,
  });

  final Paginated<Product> products;
  final bool hasReachedMax;

  @override
  Widget build(BuildContext context) {
    if (products.data.isEmpty) {
      return const _EmptyView();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (!hasReachedMax &&
            scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
          context
              .read<ProductListBloc>()
              .add(const ProductListEvent.loadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<ProductListBloc>().add(const ProductListEvent.refresh());
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.data.length + (hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= products.data.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return ProductCard(product: products.data[index]);
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar sua busca ou filtro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

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
              'Erro ao carregar produtos',
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
              onPressed: () => context.read<ProductListBloc>().add(
                    const ProductListEvent.refresh(),
                  ),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CartState>(
      stream: getIt<CartBloc>().stream,
      initialData: getIt<CartBloc>().state,
      builder: (context, snapshot) {
        final count = snapshot.data?.maybeWhen(
          loaded: (cart) => cart.itemsCount,
          orElse: () => 0,
        ) ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: badges.Badge(
            badgeContent: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      },
    );
  }
}
