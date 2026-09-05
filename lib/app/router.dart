import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../features/category/presentation/categories_page.dart';
import '../features/home/presentation/home_bloc.dart';
import '../features/home/presentation/home_event.dart';
import '../features/home/home_page.dart';
import '../features/product/presentation/product_detail_bloc.dart';
import '../features/product/presentation/product_detail_page.dart';
import '../features/product/presentation/product_list_bloc.dart';
import '../features/product/presentation/product_list_page.dart';
import '../features/product/presentation/product_list_event.dart';
import '../features/product/presentation/product_detail_event.dart';
import '../features/product/presentation/product_list_type.dart';
import '../features/cart/presentation/cart_bloc.dart';
import '../features/cart/presentation/cart_event.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_bloc.dart';
import '../features/checkout/presentation/checkout_page.dart';

// Provider para o roteador (facilita acesso e testes)
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ─── CLIENT ROUTES ──────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<HomeBloc>()..add(const HomeEvent.loadHome()),
          child: const HomePage(),
        ),
        routes: [
          GoRoute(
            path: 'products/featured',
            name: 'featured_products',
            builder: (context, state) => BlocProvider(
              create: (context) => getIt<ProductListBloc>()
                ..add(const ProductListEvent.loadFeatured()),
              child: const ProductListPage(type: ProductListType.featured),
            ),
          ),
          GoRoute(
            path: 'products/promo',
            name: 'promo_products',
            builder: (context, state) => BlocProvider(
              create: (context) => getIt<ProductListBloc>()
                ..add(const ProductListEvent.loadPromo()),
              child: const ProductListPage(type: ProductListType.promo),
            ),
          ),
          GoRoute(
            path: 'search',
            name: 'search',
            builder: (context, state) => BlocProvider(
              create: (context) => getIt<ProductListBloc>()
                ..add(ProductListEvent.search(
                  state.uri.queryParameters['q'] ?? '',
                )),
              child: ProductListPage(
                type: ProductListType.search,
                searchQuery: state.uri.queryParameters['q'],
              ),
            ),
          ),
          GoRoute(
            path: 'categories',
            name: 'categories',
            builder: (context, state) => const CategoriesPage(),
            routes: [
              GoRoute(
                path: ':slug',
                name: 'category_products',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  return BlocProvider(
                    create: (context) => getIt<ProductListBloc>()
                      ..add(ProductListEvent.loadByCategory(slug)),
                    child: ProductListPage(
                      type: ProductListType.category,
                      categorySlug: slug,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'products/:slug',
            name: 'product_detail',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return BlocProvider(
                create: (context) => getIt<ProductDetailBloc>()
                  ..add(ProductDetailEvent.load(slug)),
                child: ProductDetailPage(slug: slug),
              );
            },
          ),
          GoRoute(
            path: 'cart',
            name: 'cart',
            builder: (context, state) => BlocProvider.value(
              value: getIt<CartBloc>()..add(const CartEvent.loadCart()),
              child: const CartPage(),
            ),
            routes: [
GoRoute(
            path: 'checkout',
            name: 'checkout',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: getIt<CartBloc>()),
                BlocProvider(create: (_) => getIt<CheckoutBloc>()),
              ],
              child: const CheckoutPage(),
            ),
          ),
            ],
          ),
        ],
      ),

      // ─── AUTH ROUTES ───────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Login Admin'))),
      ),

      // ─── ADMIN ROUTES ──────────────────────────────────────────
      // Usaremos ShellRoute futuramente para um menu lateral/bottom bar fixo no admin
      GoRoute(
        path: '/admin',
        name: 'admin_dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Admin Dashboard'))),
        routes: [
          GoRoute(
            path: 'categories',
            name: 'admin_categories',
            builder: (context, state) => const Scaffold(
                body: Center(child: Text('Gestão de Categorias'))),
            routes: [
              GoRoute(
                path: 'create',
                name: 'admin_category_create',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Nova Categoria'))),
              ),
              GoRoute(
                path: ':id',
                name: 'admin_category_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                      body: Center(child: Text('Editar Categoria ID: $id')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'products',
            name: 'admin_products',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Gestão de Produtos'))),
            routes: [
              GoRoute(
                path: 'create',
                name: 'admin_product_create',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Novo Produto'))),
              ),
              GoRoute(
                path: ':id',
                name: 'admin_product_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                      body: Center(child: Text('Editar Produto ID: $id')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'banners',
            name: 'admin_banners',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Gestão de Banners'))),
          ),
          GoRoute(
            path: 'orders',
            name: 'admin_orders',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Gestão de Pedidos'))),
            routes: [
              GoRoute(
                path: ':id',
                name: 'admin_order_detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                      body: Center(child: Text('Detalhe do Pedido ID: $id')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            name: 'admin_settings',
            builder: (context, state) => const Scaffold(
                body: Center(child: Text('Configurações da Loja'))),
          ),
        ],
      ),
    ],
    // Redirecionamento básico (exemplo de guard futuramente)
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página não encontrada: ${state.uri}')),
    ),
  );
}
