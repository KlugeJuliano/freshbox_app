import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:freshbox_app/features/admin/presentation/admin_layout.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_order_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_order_list_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_order_list_state.dart';
import 'package:freshbox_app/features/admin/domain/admin_order.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';
import 'package:freshbox_app/core/di/injection.dart';
import 'package:freshbox_app/core/utils/currency_formatter.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminOrderListBloc>()..add(const AdminOrderListEvent.load()),
      child: const AdminLayout(
        child: _OrdersView(),
      ),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminOrderListBloc, AdminOrderListState>(
      builder: (context, state) {
        return state.when(
          initial: () => const _LoadingView(),
          loading: () => const _LoadingView(),
          loaded: (orders, hasReachedMax, currentPage, totalPages, totalItems, currentFilter) {
            return _LoadedView(
              orders: orders,
              hasReachedMax: hasReachedMax,
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              currentFilter: currentFilter,
              onLoadMore: () => context.read<AdminOrderListBloc>().add(const AdminOrderListEvent.loadMore()),
              onRefresh: () => context.read<AdminOrderListBloc>().add(const AdminOrderListEvent.refresh()),
              onFilterChanged: (status) => context.read<AdminOrderListBloc>().add(AdminOrderListEvent.filterStatus(status)),
            );
          },
          error: (message) => _ErrorView(
            message: message,
            onRetry: () => context.read<AdminOrderListBloc>().add(const AdminOrderListEvent.refresh()),
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
    return const Center(child: CircularProgressIndicator());
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
              'Erro ao carregar pedidos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.orders,
    required this.hasReachedMax,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.currentFilter,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onFilterChanged,
  });

  final List<AdminOrder> orders;
  final bool hasReachedMax;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final AdminOrderStatus? currentFilter;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;
  final ValueChanged<AdminOrderStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pedidos',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // Filter dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<AdminOrderStatus?>(
                    initialValue: currentFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<AdminOrderStatus?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...adminOrderStatusValuesForUI.map((s) => DropdownMenuItem<AdminOrderStatus?>(
                            value: s,
                            child: Text(s.label),
                          )),
                    ],
                    onChanged: onFilterChanged,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Atualizar',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Table
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: orders.isEmpty
                ? _EmptyState()
                : NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (!hasReachedMax &&
                          scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
                        onLoadMore();
                      }
                      return false;
                    },
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: isDesktop ? 900 : double.infinity,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Cliente')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Data')),
                              DataColumn(label: Text('Ações')),
                            ],
                            rows: orders.map((order) => _buildRow(context, order)).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        // Pagination
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Página $currentPage de $totalPages ($totalItems itens)'),
              ],
            ),
          ),
      ],
    );
  }

  DataRow _buildRow(BuildContext context, AdminOrder order) {
    final theme = Theme.of(context);
    final isDelivery = order.deliveryType == 'delivery';

    return DataRow(
      cells: [
        DataCell(
          Text(
            order.id.substring(0, 8).toUpperCase(),
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.customerName,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (isDelivery && order.deliveryAddress != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${order.deliveryAddress!.street}, ${order.deliveryAddress!.number} - ${order.deliveryAddress!.neighborhood}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        DataCell(
          Text(
            order.total.formatted,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          _StatusBadge(status: order.status),
        ),
        DataCell(
          Text(
            _formatDate(order.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => context.push('/admin/orders/${order.id}'),
                tooltip: 'Ver detalhes',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
      onSelectChanged: (_) => context.push('/admin/orders/${order.id}'),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AdminOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum pedido encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Os pedidos aparecerão aqui quando os clientes finalizarem compras.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}