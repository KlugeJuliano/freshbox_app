import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;

import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/core/utils/currency_formatter.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_state.dart';
import 'package:freshbox_app/features/home/presentation/home_bloc.dart';
import 'package:freshbox_app/features/home/presentation/home_event.dart';
import 'package:freshbox_app/features/home/presentation/home_state.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/presentation/widgets/product_card.dart';
import 'package:freshbox_app/features/product/presentation/widgets/product_shimmer.dart';
import 'package:freshbox_app/features/store/domain/store.dart';
import 'package:freshbox_app/shared/widgets/store_closed_banner.dart';
import 'package:freshbox_app/core/di/injection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return state.when(
          initial: () => const _LoadingView(),
          loading: () => const _LoadingView(),
          loaded: (
            store,
            banners,
            categories,
            featuredProducts,
            promoProducts,
          ) =>
              _LoadedView(
                store: store,
                banners: banners,
                categories: categories,
                featuredProducts: featuredProducts,
                promoProducts: promoProducts,
              ),
          error: (message) => _ErrorView(message: message),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          SliverToBoxAdapter(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionShimmer('Destaques'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => const ProductShimmer(),
                ),
                _buildSectionShimmer('Promoções'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => const ProductShimmer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionShimmer(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 24,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.store,
    required this.banners,
    required this.categories,
    required this.featuredProducts,
    required this.promoProducts,
  });

  final Store store;
  final List<String> banners;
  final List<Category> categories;
  final Paginated<Product> featuredProducts;
  final Paginated<Product> promoProducts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar with Cart Badge
          SliverAppBar(
            title: Text(
              'FreshBox',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            floating: true,
            snap: true,
            actions: [
              _CartBadge(),
            ],
          ),

          // Banner Carousel
          if (banners.isNotEmpty)
            SliverToBoxAdapter(
              child: _BannerCarousel(banners: banners),
            ),

          // Store Closed Banner
          if (!store.isOpen)
            const SliverToBoxAdapter(child: StoreClosedBanner()),

          // Store Info
          SliverToBoxAdapter(
            child: _StoreHeader(store: store),
          ),

          // Categories
          if (categories.isNotEmpty)
            SliverToBoxAdapter(
              child: _CategoriesSection(
                categories: categories,
                onSeeAll: () => context.push('/categories'),
              ),
            ),

          // Featured Products
          if (featuredProducts.data.isNotEmpty)
            SliverToBoxAdapter(
              child: _ProductSection(
                title: 'Destaques',
                products: featuredProducts.data,
                onSeeAll: () =>
                    context.push('/products/featured'),
              ),
            ),

          // Promo Products
          if (promoProducts.data.isNotEmpty)
            SliverToBoxAdapter(
              child: _ProductSection(
                title: 'Promoções',
                products: promoProducts.data,
                onSeeAll: () => context.push('/products/promo'),
              ),
            ),

          // Bottom padding for safe area
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({required this.banners});

  final List<String> banners;

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: banners.map((url) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, size: 48),
          ),
        );
      }).toList(),
      options: CarouselOptions(
        height: 180,
        viewportFraction: 1.0,
        enableInfiniteScroll: banners.length > 1,
        autoPlay: banners.length > 1,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          if (store.logoUrl != null && store.logoUrl!.isNotEmpty)
            CircleAvatar(
              radius: 28,
              backgroundImage: CachedNetworkImageProvider(store.logoUrl!),
              backgroundColor: Colors.grey[200],
            )
          else
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green[100],
              child: Icon(Icons.store, size: 28, color: Colors.green[700]),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      store.isOpen ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: store.isOpen ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      store.isOpen ? 'Aberto agora' : 'Fechado',
                      style: TextStyle(
                        fontSize: 13,
                        color: store.isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (store.deliveryFee > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.local_shipping, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Entrega: ${store.deliveryFee.formatted}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.categories,
    required this.onSeeAll,
  });

  final List<Category> categories;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Ver todas'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryChip(category: category);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/categories/${category.slug}'),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category,
                          size: 32,
                          color: Colors.green[300],
                        ),
                      )
                    : Icon(
                        Icons.category,
                        size: 32,
                        color: Colors.green[300],
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.title,
    required this.products,
    required this.onSeeAll,
  });

  final String title;
  final List<Product> products;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductCard(product: products[index]),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar a vitrine',
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
                onPressed: () => context.read<HomeBloc>().add(const HomeEvent.refreshHome()),
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