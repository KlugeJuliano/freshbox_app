import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:freshbox_app/features/admin/presentation/admin_layout.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_state.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_state.dart';
import 'package:freshbox_app/features/admin/data/admin_product_repository.dart';
import 'package:freshbox_app/features/admin/data/admin_category_repository.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_unit.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/core/di/injection.dart';
import 'package:freshbox_app/core/utils/slug_generator.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key, this.productIdToEdit});

  final int? productIdToEdit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AdminProductListBloc>()..add(const AdminProductListEvent.load()),
        ),
        BlocProvider(
          create: (_) => getIt<AdminProductFormBloc>(),
        ),
      ],
      child: AdminLayout(
        child: _ProductsView(productIdToEdit: productIdToEdit),
      ),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView({this.productIdToEdit});

  final int? productIdToEdit;

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  @override
  void initState() {
    super.initState();
    if (widget.productIdToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditDialog(context.read<AdminProductFormBloc>(), widget.productIdToEdit!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminProductFormBloc, AdminProductFormState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (product, message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            context.read<AdminProductListBloc>().add(const AdminProductListEvent.refresh());
            context.go('/admin/products');
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
      child: BlocBuilder<AdminProductListBloc, AdminProductListState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (products) => _buildTable(context, products),
            error: (message) => Center(child: Text('Erro: $message')),
          );
        },
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Produtos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Produto'),
              onPressed: () => _showCreateDialog(context.read<AdminProductFormBloc>()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: products.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum produto encontrado',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
                    headingRowHeight: 48,
                    dataRowMinHeight: 52,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('Slug')),
                      DataColumn(label: Text('Preço')),
                      DataColumn(label: Text('Promo')),
                      DataColumn(label: Text('Unidade')),
                      DataColumn(label: Text('Categoria')),
                      DataColumn(label: Text('Disponível')),
                      DataColumn(label: Text('Destaque')),
                      DataColumn(label: Text('Promo')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Ações'), numeric: true),
                    ],
                    rows: products.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          DataCell(Text(product.slug)),
                          DataCell(Text('R\$ ${product.price.toStringAsFixed(2)}')),
                          DataCell(
                            product.promoPrice != null
                                ? Text(
                                    'R\$ ${product.promoPrice!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Text('-'),
                          ),
                          DataCell(Text(product.unitLabel)),
                          DataCell(Text(product.categoryId.toString())), // Category name would need join
                          DataCell(_buildStatusChip(product.isAvailable)),
                          DataCell(_buildStatusChip(product.isFeatured)),
                          DataCell(_buildStatusChip(product.isOnPromo)),
                          DataCell(_buildStatusChip(product.isActive)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Colors.orange.shade600),
                                  onPressed: () => _showEditDialog(
                                    context.read<AdminProductFormBloc>(),
                                    product.id,
                                  ),
                                  tooltip: 'Editar',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
                                  onPressed: () => _confirmDelete(context, product.id, product.name),
                                  tooltip: 'Excluir',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isActive ? 'Sim' : 'Não',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(AdminProductFormBloc formBloc) async {
    // Carregar categorias para o dropdown
    final categories = await getIt<AdminCategoryRepository>().getAll();

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final promoPriceController = TextEditingController();
    final mainImageUrlController = TextEditingController();
    DateTime? promoEndsAt;
    ProductUnit selectedUnit = ProductUnit.kg;
    int? selectedCategoryId;
    bool isAvailable = true;
    bool isFeatured = false;
    bool isOnPromo = false;
    bool isActive = true;
    bool isSlugAutoGenerated = true;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: formBloc,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocConsumer<AdminProductFormBloc, AdminProductFormState>(
              listener: (context, state) {},
              builder: (context, state) {
                // Carregar categorias
                return FutureBuilder<List<Category>>(
                  future: getIt<AdminCategoryRepository>().getAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AlertDialog(
                        content: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final categories = snapshot.data ?? [];

                    final Widget promoEndsAtField = isOnPromo
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: TextEditingController(text: promoEndsAt != null
                                    ? '${promoEndsAt!.day.toString().padLeft(2, '0')}/${promoEndsAt!.month.toString().padLeft(2, '0')}/${promoEndsAt!.year}'
                                    : ''),
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Fim da Promoção',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: promoEndsAt ?? DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null && mounted) {
                                    setDialogState(() => promoEndsAt = date);
                                  }
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink();

                    return AlertDialog(
                      title: const Text('Novo Produto'),
                      content: SizedBox(
                        width: 600,
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome *',
                                    hintText: 'Ex: Banana Nanica',
                                  ),
                                  validator: (value) =>
                                      value?.trim().isEmpty ?? true ? 'Nome é obrigatório' : null,
                                  onChanged: (value) {
                                    if (slugController.text.isEmpty || isSlugAutoGenerated) {
                                      setDialogState(() {
                                        slugController.text = generateSlug(value);
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: slugController,
                                  decoration: const InputDecoration(
                                    labelText: 'Slug *',
                                    hintText: 'gerado automaticamente',
                                  ),
                                  validator: (value) =>
                                      value?.trim().isEmpty ?? true ? 'Slug é obrigatório' : null,
                                  onChanged: (_) => setDialogState(() => isSlugAutoGenerated = false),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descrição',
                                    hintText: 'Descrição do produto...',
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: priceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Preço *',
                                          hintText: '0,00',
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value?.trim().isEmpty ?? true) return 'Preço é obrigatório';
                                          final price = double.tryParse(value!.replaceAll(',', '.'));
                                          if (price == null || price <= 0) return 'Preço deve ser maior que zero';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: promoPriceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Preço Promo',
                                          hintText: '0,00',
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (value) {
                                          final price = double.tryParse(value.replaceAll(',', '.'));
                                          setDialogState(() {
                                            isOnPromo = price != null && price > 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<ProductUnit>(
                                        initialValue: selectedUnit,
                                        decoration: const InputDecoration(
                                          labelText: 'Unidade *',
                                        ),
                                        items: ProductUnit.values.map((unit) {
                                          return DropdownMenuItem<ProductUnit>(
                                            value: unit,
                                            child: Text(unit.label),
                                          );
                                        }).toList(),
                                        onChanged: (value) => setDialogState(() => selectedUnit = value!),
                                        validator: (value) => value == null ? 'Unidade é obrigatória' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: selectedCategoryId,
                                        decoration: const InputDecoration(
                                          labelText: 'Categoria *',
                                        ),
                                        items: categories.map((c) {
                                          return DropdownMenuItem<int>(
                                            value: c.id,
                                            child: Text(c.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) => setDialogState(() => selectedCategoryId = value),
                                        validator: (value) => value == null ? 'Categoria é obrigatória' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Dispon\u00edvel'),
                                  value: isAvailable,
                                  onChanged: (value) => setDialogState(() => isAvailable = value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Destaque'),
                                  value: isFeatured,
                                  onChanged: (value) => setDialogState(() => isFeatured = value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Em Promo\u00e7\u00e3o'),
                                  value: isOnPromo,
                                  onChanged: (value) => setDialogState(() {
                                    isOnPromo = value;
                                    if (!value) {
                                      promoPriceController.clear();
                                      promoEndsAt = null;
                                    }
                                  }),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Ativo'),
                                  value: isActive,
                                  onChanged: (value) => setDialogState(() => isActive = value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                promoEndsAtField,
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: mainImageUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'URL da Imagem Principal',
                                    hintText: 'https://exemplo.com/imagem.png',
                                  ),
                                ),
],
                            ),
                          ),
                        ),
                        ),
                        actions: [
                        TextButton(
                          onPressed: state.maybeWhen(submitting: () => true, orElse: () => false)
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: state.maybeWhen(submitting: () => true, orElse: () => false)
                              ? null
                              : () {
                                  if (formKey.currentState?.validate() ?? false) {
                                    final data = <String, dynamic>{
                                      'name': nameController.text.trim(),
                                      'slug': slugController.text.trim(),
                                      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                                      'price': double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
                                      'unit': selectedUnit.name,
                                      'category_id': selectedCategoryId,
                                      'is_available': isAvailable,
                                      'is_featured': isFeatured,
                                      'is_on_promo': isOnPromo,
                                      'is_active': isActive,
                                    };
                                    if (promoPriceController.text.isNotEmpty) {
                                      final promoPrice = double.tryParse(promoPriceController.text.replaceAll(',', '.'));
                                      if (promoPrice != null && promoPrice > 0) {
                                        data['promo_price'] = promoPrice;
                                      }
                                    }
                                    if (promoEndsAt != null) {
                                      data['promo_ends_at'] = promoEndsAt!.toIso8601String();
                                    }
                                    // Preencher as 3 variantes de imagem com a mesma URL
                                    if (mainImageUrlController.text.trim().isNotEmpty == true) {
                                      data['thumb_url'] = mainImageUrlController.text.trim();
                                      data['card_url'] = mainImageUrlController.text.trim();
                                      data['full_url'] = mainImageUrlController.text.trim();
                                    }
                                    formBloc.add(AdminProductFormEvent.create(data));
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: state.maybeWhen(
                            submitting: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            orElse: () => const Text('Criar'),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showEditDialog(AdminProductFormBloc formBloc, int id) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final promoPriceController = TextEditingController();
    final mainImageUrlController = TextEditingController();
    DateTime? promoEndsAt;
    ProductUnit selectedUnit = ProductUnit.kg;
    int? selectedCategoryId;
    bool isAvailable = true;
    bool isFeatured = false;
    bool isOnPromo = false;
    bool isActive = true;
    bool isSlugAutoGenerated = true;
    bool isLoading = true;

    // Carregar produto e categorias
    Future.wait([
      getIt<AdminProductRepository>().getById(id),
      getIt<AdminCategoryRepository>().getAll(),
    ]).then((results) {
      final product = results[0] as Product;
      final categories = results[1] as List<Category>;

      nameController.text = product.name;
      slugController.text = product.slug;
      descriptionController.text = product.description ?? '';
      priceController.text = product.price.toStringAsFixed(2).replaceAll('.', ',');
      if (product.promoPrice != null) {
        promoPriceController.text = product.promoPrice!.toStringAsFixed(2).replaceAll('.', ',');
      }
      if (product.promoEndsAt != null) {
        promoEndsAt = product.promoEndsAt!;
      }
      selectedUnit = product.unit;
      selectedCategoryId = product.categoryId;
      isAvailable = product.isAvailable;
      isFeatured = product.isFeatured;
      isOnPromo = product.isOnPromo;
      isActive = product.isActive;
      final fullImage = product.images.full;
      if (fullImage != null && fullImage.isNotEmpty) {
        mainImageUrlController.text = fullImage;
      }
      isLoading = false;
      if (mounted) setState(() {});
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produto: $e'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    });

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: formBloc,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocConsumer<AdminProductFormBloc, AdminProductFormState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (isLoading) {
                  return const AlertDialog(
                    content: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                return FutureBuilder<List<Category>>(
                  future: getIt<AdminCategoryRepository>().getAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AlertDialog(
                        content: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final categories = snapshot.data ?? [];

                    final Widget promoEndsAtField = isOnPromo
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: TextEditingController(text: promoEndsAt != null
                                    ? '${promoEndsAt!.day.toString().padLeft(2, '0')}/${promoEndsAt!.month.toString().padLeft(2, '0')}/${promoEndsAt!.year}'
                                    : ''),
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Fim da Promoção',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: promoEndsAt ?? DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null && mounted) {
                                    setDialogState(() => promoEndsAt = date);
                                  }
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink();

                    return AlertDialog(
                      title: const Text('Editar Produto'),
                      content: SizedBox(
                        width: 600,
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome *',
                                    hintText: 'Ex: Banana Nanica',
                                  ),
                                  validator: (value) =>
                                      value?.trim().isEmpty ?? true ? 'Nome é obrigatório' : null,
                                  onChanged: (value) {
                                    if (slugController.text.isEmpty || isSlugAutoGenerated) {
                                      setDialogState(() {
                                        slugController.text = generateSlug(value);
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: slugController,
                                  decoration: const InputDecoration(
                                    labelText: 'Slug *',
                                    hintText: 'gerado automaticamente',
                                  ),
                                  validator: (value) =>
                                      value?.trim().isEmpty ?? true ? 'Slug é obrigatório' : null,
                                  onChanged: (_) => setDialogState(() => isSlugAutoGenerated = false),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descrição',
                                    hintText: 'Descrição do produto...',
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: priceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Preço *',
                                          hintText: '0,00',
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value?.trim().isEmpty ?? true) return 'Preço é obrigatório';
                                          final price = double.tryParse(value!.replaceAll(',', '.'));
                                          if (price == null || price <= 0) return 'Preço deve ser maior que zero';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: promoPriceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Preço Promo',
                                          hintText: '0,00',
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (value) {
                                          final price = double.tryParse(value.replaceAll(',', '.'));
                                          setDialogState(() {
                                            isOnPromo = price != null && price > 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<ProductUnit>(
                                        initialValue: selectedUnit,
                                        decoration: const InputDecoration(
                                          labelText: 'Unidade *',
                                        ),
                                        items: ProductUnit.values.map((unit) {
                                          return DropdownMenuItem<ProductUnit>(
                                            value: unit,
                                            child: Text(unit.label),
                                          );
                                        }).toList(),
                                        onChanged: (value) => setDialogState(() => selectedUnit = value!),
                                        validator: (value) => value == null ? 'Unidade é obrigatória' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: selectedCategoryId,
                                        decoration: const InputDecoration(
                                          labelText: 'Categoria *',
                                        ),
                                        items: categories.map((c) {
                                          return DropdownMenuItem<int>(
                                            value: c.id,
                                            child: Text(c.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) => setDialogState(() => selectedCategoryId = value),
                                        validator: (value) => value == null ? 'Categoria é obrigatória' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Dispon\u00edvel'),
                                  value: isAvailable,
                                  onChanged: (value) => setDialogState(() => isAvailable = value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Destaque'),
                                  value: isFeatured,
                                  onChanged: (value) => setDialogState(() => isFeatured = value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Em Promo\u00e7\u00e3o'),
                                  value: isOnPromo,
                                  onChanged: (value) => setDialogState(() {
                                    isOnPromo = value;
                                    if (!value) {
                                      promoPriceController.clear();
                                      promoEndsAt = null;
                                    }
                                  }),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Ativo'),
                                  value: isActive,
                                  onChanged: (value) => setDialogState(() => isActive = value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                promoEndsAtField,
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: mainImageUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'URL da Imagem Principal',
                                    hintText: 'https://exemplo.com/imagem.png',
                                  ),
                                ),
],
                            ),
                          ),
                        ),
                        ),
                        actions: [
                        TextButton(
                          onPressed: state.maybeWhen(submitting: () => true, orElse: () => false)
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: state.maybeWhen(submitting: () => true, orElse: () => false)
                              ? null
                              : () {
                                  if (formKey.currentState?.validate() ?? false) {
                                    final data = <String, dynamic>{
                                      'name': nameController.text.trim(),
                                      'slug': slugController.text.trim(),
                                      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                                      'price': double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
                                      'unit': selectedUnit.name,
                                      'category_id': selectedCategoryId,
                                      'is_available': isAvailable,
                                      'is_featured': isFeatured,
                                      'is_on_promo': isOnPromo,
                                      'is_active': isActive,
                                    };
                                    if (promoPriceController.text.isNotEmpty) {
                                      final promoPrice = double.tryParse(promoPriceController.text.replaceAll(',', '.'));
                                      if (promoPrice != null && promoPrice > 0) {
                                        data['promo_price'] = promoPrice;
                                      }
                                    }
                                    if (promoEndsAt != null) {
                                      data['promo_ends_at'] = promoEndsAt!.toIso8601String();
                                    }
                                    // Preencher as 3 variantes de imagem com a mesma URL
                                    if (mainImageUrlController.text.trim().isNotEmpty == true) {
                                      data['thumb_url'] = mainImageUrlController.text.trim();
                                      data['card_url'] = mainImageUrlController.text.trim();
                                      data['full_url'] = mainImageUrlController.text.trim();
                                    }
                                    formBloc.add(AdminProductFormEvent.update(id, data));
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: state.maybeWhen(
                            submitting: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            orElse: () => const Text('Salvar'),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Tem certeza que deseja excluir o produto "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminProductFormBloc>().add(AdminProductFormEvent.delete(id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}