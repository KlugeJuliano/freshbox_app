import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:freshbox_app/core/utils/currency_formatter.dart';
import 'package:freshbox_app/core/utils/whatsapp_helper.dart';
import 'package:freshbox_app/features/cart/domain/cart.dart';
import 'package:freshbox_app/features/cart/domain/cart_item.dart';
import 'package:freshbox_app/features/cart/presentation/cart_bloc.dart';
import 'package:freshbox_app/features/cart/presentation/cart_state.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_bloc.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_event.dart';
import 'package:freshbox_app/features/checkout/presentation/checkout_state.dart';
import 'package:freshbox_app/features/order/domain/checkout_form.dart';
import 'package:freshbox_app/features/order/domain/order.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<CartBloc>()),
        BlocProvider(create: (_) => context.read<CheckoutBloc>()),
      ],
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cepController = TextEditingController();
  final _observationsController = TextEditingController();

  String _deliveryType = 'delivery';

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'\d')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'\d')},
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cepController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (order) => _handleSuccess(context, order),
          error: (message) => _showErrorSnackBar(context, message),
          validationError: (errors) => _showValidationErrors(errors),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finalizar Pedido'),
          centerTitle: true,
        ),
        body: BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, state) {
            final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDeliveryTypeSelector(),
                          const SizedBox(height: 24),
                          _buildNameField(),
                          const SizedBox(height: 16),
                          _buildPhoneField(),
                          const SizedBox(height: 16),
                          if (_deliveryType == 'delivery') ...[
                            _buildCepField(),
                            const SizedBox(height: 16),
                            _buildAddressField(),
                            const SizedBox(height: 16),
                          ],
                          _buildObservationsField(),
                          const SizedBox(height: 24),
                          _buildOrderSummary(context),
                        ],
                      ),
                    ),
                  ),
                  _buildSubmitButton(isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de entrega',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'delivery',
              label: Text('Entrega 🚚'),
              icon: Icon(Icons.local_shipping),
            ),
            ButtonSegment(
              value: 'pickup',
              label: Text('Retirada 🏪'),
              icon: Icon(Icons.store),
            ),
          ],
          selected: {_deliveryType},
          onSelectionChanged: (selection) {
            setState(() => _deliveryType = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nome completo *',
        hintText: 'João da Silva',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nome é obrigatório';
        }
        if (value.trim().length < 3) {
          return 'Nome deve ter pelo menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      inputFormatters: [_phoneMask],
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Telefone *',
        hintText: '(11) 99999-9999',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Telefone é obrigatório';
        }
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 10 || digits.length > 11) {
          return 'Telefone inválido';
        }
        return null;
      },
    );
  }

  Widget _buildCepField() {
    return TextFormField(
      controller: _cepController,
      inputFormatters: [_cepMask],
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'CEP (opcional)',
        hintText: '00000-000',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final digits = value.replaceAll(RegExp(r'\D'), '');
          if (digits.length != 8) {
            return 'CEP inválido';
          }
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Endereço completo *',
        hintText: 'Rua das Flores, 123 - Bairro Centro',
        prefixIcon: Icon(Icons.home_outlined),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (_deliveryType == 'delivery') {
          if (value == null || value.trim().isEmpty) {
            return 'Endereço é obrigatório para entrega';
          }
          if (value.trim().length < 10) {
            return 'Endereço muito curto';
          }
        }
        return null;
      },
    );
  }

  Widget _buildObservationsField() {
    return TextFormField(
      controller: _observationsController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Observações (opcional)',
        hintText: 'Ex: Portão azul, tocar campainha 2x',
        prefixIcon: Icon(Icons.note_outlined),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final cart = cartState?.maybeMap(loaded: (state) => state.cart, orElse: () => null);
        if (cart == null || cart.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo do pedido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.productName}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            item.totalPrice.formatted,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: Theme.of(context).textTheme.bodyLarge),
                    Text(cart.subtotal.formatted, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (_deliveryType == 'delivery') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Taxa de entrega', style: Theme.of(context).textTheme.bodyMedium),
                      Text('5,00', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      (cart.subtotal + (_deliveryType == 'delivery' ? 5.0 : 0.0)).formatted,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: isLoading ? null : _onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Confirmar Pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final form = CheckoutForm(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      deliveryType: _deliveryType,
      observations: _observationsController.text.trim().isEmpty ? null : _observationsController.text.trim(),
      cep: _cepController.text.trim().isEmpty ? null : _cepController.text.trim(),
    );

    final cartState = context.read<CartBloc>().state;
    final cart = cartState.maybeMap(loaded: (state) => state.cart, orElse: () => null);
    if (cart == null || cart.isEmpty) return;

    context.read<CheckoutBloc>().add(CheckoutEvent.submitOrder(form: form, items: cart.items));
  }

  void _handleSuccess(BuildContext context, Order order) async {
    try {
      await WhatsAppHelper.openWhatsAppWithFallback(order);
      if (context.mounted) {
        context.go('/');
      }
    } on WhatsAppNotAvailableException catch (e) {
      if (context.mounted) {
        _showWhatsAppFallbackDialog(context, e);
      }
    }
  }

  void _showWhatsAppFallbackDialog(BuildContext context, WhatsAppNotAvailableException e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('WhatsApp não disponível')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seu pedido foi registrado com sucesso!'),
            const SizedBox(height: 12),
            const Text('Não foi possível abrir o WhatsApp automaticamente.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                e.formattedMessage,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text('Número: ${e.whatsappUrl.replaceAll('https://wa.me/', '').split('?').first}', style: TextStyle(color: Colors.blue[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            icon: const Icon(Icons.home),
            label: const Text('Ir para Home'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showValidationErrors(Map<String, String> errors) {
    // Errors are shown inline via form validation
  }
}