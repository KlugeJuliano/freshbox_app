import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshbox_app/features/order/domain/order.dart';

class WhatsAppNotAvailableException implements Exception {
  final String whatsappUrl;
  final String formattedMessage;

  WhatsAppNotAvailableException(this.whatsappUrl, this.formattedMessage);

  @override
  String toString() => 'WhatsAppNotAvailableException: $whatsappUrl';
}

class WhatsAppHelper {
  static Future<void> openWhatsAppWithFallback(Order order) async {
    final url = Uri.parse(order.whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw WhatsAppNotAvailableException(order.whatsappUrl, _formatOrderMessage(order));
    }
  }

  static String _formatOrderMessage(Order order) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *Novo Pedido - ${order.uuid.substring(0, 8).toUpperCase()}*');
    buffer.writeln('');
    buffer.writeln('👤 *Cliente:* ${order.customerName}');
    buffer.writeln('📞 *Telefone:* ${order.customerPhone}');
    buffer.writeln('🚚 *Tipo:* ${order.deliveryType == 'delivery' ? 'Entrega' : 'Retirada'}');
    if (order.deliveryType == 'delivery') {
      buffer.writeln('📍 *Endereço:* ${order.customerAddress}');
    }
    buffer.writeln('');
    buffer.writeln('📦 *Itens:*');
    for (final item in order.items) {
      buffer.write('• ${item.quantity}x ${item.productName}');
      if (item.unitLabel.isNotEmpty) {
        buffer.write(' (${item.unitLabel})');
      }
      buffer.writeln(' - ${item.subtotal.formatted}');
    }
    buffer.writeln('');
    buffer.writeln('💰 *Subtotal:* ${order.subtotal.formatted}');
    if (order.deliveryFee > 0) {
      buffer.writeln('🚚 *Taxa entrega:* ${order.deliveryFee.formatted}');
    }
    buffer.writeln('✅ *Total:* ${order.total.formatted}');
    buffer.writeln('');
    buffer.writeln('Obrigado pela preferência! 🌱');

    return buffer.toString();
  }
}

extension _CurrencyFormat on double {
  String get formatted {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }
}