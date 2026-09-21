import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freshbox_app/core/di/injection.dart';
import 'package:freshbox_app/features/auth/presentation/auth_bloc.dart';
import 'package:freshbox_app/features/auth/presentation/auth_event.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            currentRoute: GoRouterState.of(context).uri.toString(),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      width: 260,
      color: sidebarColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: _buildMenuItems(context),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_grocery_store, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'FreshBox Admin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final items = [
      _SidebarItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/admin',
        isActive: currentRoute == '/admin',
      ),
      _SidebarItem(
        icon: Icons.category,
        label: 'Categorias',
        route: '/admin/categories',
        isActive: currentRoute.startsWith('/admin/categories'),
      ),
      _SidebarItem(
        icon: Icons.inventory,
        label: 'Produtos',
        route: '/admin/products',
        isActive: currentRoute.startsWith('/admin/products'),
      ),
      _SidebarItem(
        icon: Icons.image,
        label: 'Banners',
        route: '/admin/banners',
        isActive: currentRoute.startsWith('/admin/banners'),
      ),
      _SidebarItem(
        icon: Icons.receipt_long,
        label: 'Pedidos',
        route: '/admin/orders',
        isActive: currentRoute.startsWith('/admin/orders'),
      ),
      _SidebarItem(
        icon: Icons.settings,
        label: 'Configurações',
        route: '/admin/settings',
        isActive: currentRoute.startsWith('/admin/settings'),
      ),
    ];

    return items.map((item) => _buildMenuItem(context, item)).toList();
  }

  Widget _buildMenuItem(BuildContext context, _SidebarItem item) {
    final isActive = item.isActive;
    final color = isActive ? Colors.green.shade600 : Colors.grey.shade700;
    final bgColor = isActive ? Colors.green.shade50 : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(item.icon, color: color, size: 22),
        title: Text(
          item.label,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => context.go(item.route),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green.shade100,
            child: Text(
              'A',
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin User',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Administrador',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 18, color: Colors.grey.shade600),
            onPressed: () => getIt<AuthBloc>().add(const AuthEvent.logout()),
            tooltip: 'Sair',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getPageTitle(GoRouterState.of(context).uri.toString()),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notificações',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/admin/settings'),
            tooltip: 'Configurações',
          ),
        ],
      ),
    );
  }

  String _getPageTitle(String route) {
    if (route == '/admin') return 'Dashboard';
    if (route.startsWith('/admin/categories')) return 'Categorias';
    if (route.startsWith('/admin/products')) return 'Produtos';
    if (route.startsWith('/admin/banners')) return 'Banners';
    if (route.startsWith('/admin/orders')) return 'Pedidos';
    if (route.startsWith('/admin/settings')) return 'Configurações';
    return 'Admin';
  }
}