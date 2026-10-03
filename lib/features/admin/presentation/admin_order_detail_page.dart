import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freshbox_app/features/admin/presentation/admin_layout.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_order_detail_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_order_detail_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_order_detail_state.dart';
import 'package:freshbox_app/features/admin/domain/admin_order.dart';
import 'package:freshbox_app/features/admin/domain/admin_order_status.dart';
import 'package:freshbox_app/core/di/injection.dart';
import 'package:freshbox_app/core/utils/currency_formatter.dart';

class AdminOrderDetailPage extends StatelessWidget {
  const AdminOrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminOrderDetailBloc>()..add(AdminOrderDetailEvent.load(orderId)),
      child: AdminLayout(
        child: _OrderDetailView(orderId: orderId),
      ),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminOrderDetailBloc, AdminOrderDetailState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const _LoadingView(),
          loading: () => const _LoadingView(),
          loaded: (order) => _LoadedView(order: order),
          updating: () => const _UpdatingOverlay(),
          error: (message) => _ErrorView(
            message: message,
            onRetry: () => context.read<AdminOrderDetailBloc>().add(AdminOrderDetailEvent.load(orderId)),
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

class _UpdatingOverlay extends StatelessWidget {
  const _UpdatingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _LoadingView(),
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Atualizando status...'),
                ],
              ),
            ),
          ),
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
              'Erro ao carregar pedido',
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
  const _LoadedView({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivery = order.deliveryType == 'delivery';
    final validTransitions = order.status.validTransitions(isDelivery: isDelivery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido ${order.id.substring(0, 8).toUpperCase()}',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            _StatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 24),
        // Info cards
        Row(
          children: [
            Expanded(child: _InfoCard(
              title: 'Cliente',
              children: [
                _InfoRow('Nome', order.customerName),
                _InfoRow('Telefone', order.customerPhone),
              ],
            )),
            const SizedBox(width: 16),
            Expanded(child: _InfoCard(
              title: 'Entrega',
              children: [
                _InfoRow('Tipo', isDelivery ? 'Entrega' : 'Retirada'),
                if (isDelivery && order.deliveryAddress != null) ...[
                  _InfoRow('Endereço', '${order.deliveryAddress!.street ?? ''}, ${order.deliveryAddress!.number ?? ''}'),
                  _InfoRow('Bairro', order.deliveryAddress!.neighborhood ?? ''),
                  _InfoRow('Cidade', '${order.deliveryAddress!.city ?? ''} - ${order.deliveryAddress!.zipCode ?? ''}'),
                ],
              ],
            )),
            const SizedBox(width: 16),
            Expanded(child: _InfoCard(
              title: 'Valores',
              children: [
                _InfoRow('Subtotal', order.subtotal.formatted),
                _InfoRow('Taxa entrega', order.deliveryFee.formatted),
                _InfoRow('Total', order.total.formatted, isTotal: true),
              ],
            )),
          ],
        ),
        const SizedBox(height: 24),
        // Items table
        Text('Itens do pedido', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('Produto')),
              DataColumn(label: Text('Qtd')),
              DataColumn(label: Text('Preço unit.'), numeric: true),
              DataColumn(label: Text('Subtotal'), numeric: true),
            ],
            rows: order.items.map((item) => DataRow(cells: [
              DataCell(Text(item.productName)),
              DataCell(Text('${item.quantity} ${item.productUnit}')),
              DataCell(Text(item.unitPrice.formatted, textAlign: TextAlign.right)),
              DataCell(Text(item.subtotal.formatted, textAlign: TextAlign.right)),
            ])).toList(),
          ),
        ),
        if (order.observations != null && order.observations!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _InfoCard(
            title: 'Observações do cliente',
            children: [Text(order.observations!)],
          ),
        ],
        const SizedBox(height: 24),
        // Actions
        if (validTransitions.isNotEmpty) ...[
          Text('Ações', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: validTransitions.map((status) => ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text(status.label),
              style: ElevatedButton.styleFrom(
                backgroundColor: status.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => _confirmStatusChange(context, status),
            )).toList(),
          ),
        ],
        const SizedBox(height: 24),
        // WhatsApp button
        if (order.customerPhone.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.message, size: 24),
              label: const Text('Abrir WhatsApp do cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _openWhatsApp(context, order),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.isTotal = false});

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

Future<void> _confirmStatusChange(BuildContext context, AdminOrderStatus newStatus) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirmar ${newStatus.label}?'),
      content: Text('Deseja alterar o status do pedido para "${newStatus.label}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: newStatus.color),
          child: Text('Confirmar', style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    context.read<AdminOrderDetailBloc>().add(AdminOrderDetailEvent.updateStatus(newStatus));
  }
}

Future<void> _openWhatsApp(BuildContext context, AdminOrder order) async {
  final phone = order.customerPhone.replaceAll(RegExp(r'\D'), '');
  final message = _buildWhatsAppMessage(order);
  final url = 'https://wa.me/55$phone?text=${Uri.encodeComponent(message)}';

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }
}

String _buildWhatsAppMessage(AdminOrder order) {
  final buffer = StringBuffer();
  buffer.writeln('Olá ${order.customerName}!');
  buffer.writeln('');
  buffer.writeln('Seu pedido *${order.id.substring(0, 8).toUpperCase()}* foi *${order.status.label.toLowerCase()}*.');
  buffer.writeln('');
  buffer.writeln('*Itens:*');
  for (final item in order.items) {
    buffer.writeln('- ${item.quantity}x ${item.productName} (${item.productUnit}) - ${item.subtotal.formatted}');
  }
  buffer.writeln('');
  buffer.writeln('*Total: ${order.total.formatted}*');
  buffer.writeln('');
  buffer.writeln('Obrigado pela preferência!');
  return buffer.toString();
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}