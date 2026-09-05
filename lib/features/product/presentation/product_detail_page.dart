import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:freshbox_app/core/utils/currency_formatter.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_state.dart';
import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/cart/presentation/cart_event.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_bloc.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_event.dart';
import 'package:freshbox_app/features/product/presentation/product_detail_state.dart';
import 'package:freshbox_app/core/di/injection.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        return state.when(
          initial: () => const _LoadingView(),
          loading: () => const _LoadingView(),
          loaded: (product) => _LoadedView(product: product),
          error: (message) => _ErrorView(
            message: message,
            onRetry: () => context
                .read<ProductDetailBloc>()
                .add(ProductDetailEvent.refresh(slug)),
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produto')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPromo = product.hasPromo;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        actions: [
          _CartBadge(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Imagens do produto
          SliverToBoxAdapter(
            child: _ProductImageCarousel(images: product.images),
          ),
          // Info do produto
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (product.hasPromo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PROMOÇÃO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (product.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'DESTAQUE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Preço
                  if (hasPromo) ...[
                    Text(
                      'De ${product.price.formatted}/${product.unitLabel}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      'Por ${product.effectivePrice.formatted}/${product.unitLabel}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${product.effectivePrice.formatted}/${product.unitLabel}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Descrição
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    Text(
                      'Descrição',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Disponibilidade
                  Row(
                    children: [
                      Icon(
                        product.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: product.isAvailable ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.isAvailable ? 'Disponível' : 'Indisponível',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              product.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Botão de adicionar ao carrinho
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: product.isAvailable
                    ? () {
                        final cartItem = CartItem.fromProduct(product);
                        context.read<CartBloc>().add(CartEvent.addItem(cartItem));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} adicionado ao carrinho'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Adicionar ao carrinho'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageCarousel extends StatelessWidget {
  const _ProductImageCarousel({required this.images});

  final ProductImage images;

  List<String> get _imageUrls {
    final urls = <String>[];
    if (images.full != null && images.full!.isNotEmpty) urls.add(images.full!);
    if (images.card != null && images.card!.isNotEmpty) urls.add(images.card!);
    if (images.thumb != null && images.thumb!.isNotEmpty) {
      urls.add(images.thumb!);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _imageUrls;
    if (urls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.green[50],
        child: const Center(
          child:
              Icon(Icons.local_grocery_store, size: 100, color: Colors.green),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          CarouselSlider(
            items: urls.map((url) {
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey),
              );
            }).toList(),
            options: CarouselOptions(
              height: 300,
              viewportFraction: 1.0,
              enableInfiniteScroll: urls.length > 1,
              autoPlay: urls.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produto')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar produto',
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
