import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/router/go_router_refresh_stream.dart';
import '../features/auth/presentation/auth_bloc.dart';
import '../features/auth/presentation/auth_state.dart';
import '../features/auth/presentation/login_page.dart';
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
import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/admin/presentation/admin_categories_page.dart';
import '../features/admin/presentation/admin_products_page.dart';
import '../features/admin/presentation/admin_banners_page.dart';
import '../features/admin/presentation/admin_orders_page.dart';
import '../features/admin/presentation/admin_settings_page.dart';

// Provider para o roteador (facilita acesso e testes)
GoRouter buildRouter() {
  final authBloc = getIt<AuthBloc>();
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isChecking = authState.maybeWhen(checking: () => true, orElse: () => false);
      if (isChecking) return null; // splash decide, router não interfere ainda
      final isAuth = authState.maybeWhen(authenticated: (_) => true, orElse: () => false);
      final goingToLogin = state.uri.path == '/login';

      if (!isAuth && state.uri.path.startsWith('/admin')) {
        return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (isAuth && goingToLogin) return '/admin';
      return null;
    },
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
        builder: (context, state) => BlocProvider.value(
          value: getIt<AuthBloc>(),
          child: const LoginPage(),
        ),
      ),

      // ─── ADMIN ROUTES ──────────────────────────────────────────
      // Usamos ShellRoute para manter o AdminLayout (sidebar) persistente
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin_dashboard',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/categories',
            name: 'admin_categories',
            builder: (context, state) => const AdminCategoriesPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'admin_category_create',
                builder: (context, state) => const AdminCategoriesPage(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'admin_category_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AdminCategoriesPage(categoryIdToEdit: int.parse(id));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/products',
            name: 'admin_products',
            builder: (context, state) => const AdminProductsPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'admin_product_create',
                builder: (context, state) => const AdminProductsPage(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'admin_product_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AdminProductsPage(productIdToEdit: int.parse(id));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/banners',
            name: 'admin_banners',
            builder: (context, state) => const AdminBannersPage(),
          ),
          GoRoute(
            path: '/admin/orders',
            name: 'admin_orders',
            builder: (context, state) => const AdminOrdersPage(),
          ),
          GoRoute(
            path: '/admin/orders/:id',
            name: 'admin_order_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return Scaffold(
                body: Center(child: Text('Detalhe do Pedido ID: $id')),
              );
            },
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin_settings',
            builder: (context, state) => const AdminSettingsPage(),
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