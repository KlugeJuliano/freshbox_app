import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freshbox_app/features/admin/presentation/admin_layout.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      child: _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Visão geral da loja',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Pedidos Hoje',
              value: '0',
              icon: Icons.receipt_long,
              color: Colors.blue,
              onTap: () => context.go('/admin/orders'),
            ),
            _StatCard(
              title: 'Faturamento Hoje',
              value: 'R\$ 0,00',
              icon: Icons.attach_money,
              color: Colors.green,
              onTap: () => context.go('/admin/orders'),
            ),
            _StatCard(
              title: 'Produtos Ativos',
              value: '0',
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () => context.go('/admin/products'),
            ),
            _StatCard(
              title: 'Categorias',
              value: '0',
              icon: Icons.category,
              color: Colors.purple,
              onTap: () => context.go('/admin/categories'),
            ),
            _StatCard(
              title: 'Banners Ativos',
              value: '0',
              icon: Icons.image,
              color: Colors.teal,
              onTap: () => context.go('/admin/banners'),
            ),
            _StatCard(
              title: 'Clientes Novos',
              value: '0',
              icon: Icons.person_add,
              color: Colors.indigo,
              onTap: () {},
            ),
            _StatCard(
              title: 'Taxa de Conversão',
              value: '0%',
              icon: Icons.trending_up,
              color: Colors.pink,
              onTap: () {},
            ),
            _StatCard(
              title: 'Ticket Médio',
              value: 'R\$ 0,00',
              icon: Icons.analytics,
              color: Colors.cyan,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildRecentOrders(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActions(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedidos Recentes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/orders'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum pedido recente',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _QuickActionButton(
              icon: Icons.category,
              label: 'Nova Categoria',
              onTap: () => context.go('/admin/categories'),
            ),
            _QuickActionButton(
              icon: Icons.add_box,
              label: 'Novo Produto',
              onTap: () => context.go('/admin/products'),
            ),
            _QuickActionButton(
              icon: Icons.add_photo_alternate,
              label: 'Novo Banner',
              onTap: () => context.go('/admin/banners'),
            ),
            _QuickActionButton(
              icon: Icons.settings,
              label: 'Configurações',
              onTap: () => context.go('/admin/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}