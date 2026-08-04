import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        builder: (context, state) => const Scaffold(body: Center(child: Text('Home (Vitrine)'))),
        routes: [
          GoRoute(
            path: 'search',
            name: 'search',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Busca de Produtos'))),
          ),
          GoRoute(
            path: 'categories',
            name: 'categories',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Categorias'))),
            routes: [
              GoRoute(
                path: ':slug',
                name: 'category_products',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  return Scaffold(body: Center(child: Text('Produtos da Categoria: $slug')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'products/:slug',
            name: 'product_detail',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return Scaffold(body: Center(child: Text('Detalhe do Produto: $slug')));
            },
          ),
          GoRoute(
            path: 'cart',
            name: 'cart',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Carrinho'))),
            routes: [
              GoRoute(
                path: 'checkout',
                name: 'checkout',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Checkout (Finalizar Pedido)'))),
              ),
            ],
          ),
        ],
      ),

      // ─── AUTH ROUTES ───────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Login Admin'))),
      ),

      // ─── ADMIN ROUTES ──────────────────────────────────────────
      // Usaremos ShellRoute futuramente para um menu lateral/bottom bar fixo no admin
      GoRoute(
        path: '/admin',
        name: 'admin_dashboard',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Admin Dashboard'))),
        routes: [
          GoRoute(
            path: 'categories',
            name: 'admin_categories',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Gestão de Categorias'))),
            routes: [
              GoRoute(
                path: 'create',
                name: 'admin_category_create',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Nova Categoria'))),
              ),
              GoRoute(
                path: ':id',
                name: 'admin_category_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(body: Center(child: Text('Editar Categoria ID: $id')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'products',
            name: 'admin_products',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Gestão de Produtos'))),
            routes: [
              GoRoute(
                path: 'create',
                name: 'admin_product_create',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Novo Produto'))),
              ),
              GoRoute(
                path: ':id',
                name: 'admin_product_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(body: Center(child: Text('Editar Produto ID: $id')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'banners',
            name: 'admin_banners',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Gestão de Banners'))),
          ),
          GoRoute(
            path: 'orders',
            name: 'admin_orders',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Gestão de Pedidos'))),
            routes: [
              GoRoute(
                path: ':id',
                name: 'admin_order_detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(body: Center(child: Text('Detalhe do Pedido ID: $id')));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            name: 'admin_settings',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Configurações da Loja'))),
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
