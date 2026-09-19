import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:freshbox_app/features/admin/presentation/admin_layout.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_state.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_state.dart';
import 'package:freshbox_app/features/admin/data/admin_category_repository.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/core/di/injection.dart';

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key, this.categoryIdToEdit});

  final int? categoryIdToEdit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AdminCategoryListBloc>()..add(const AdminCategoryListEvent.load()),
        ),
        BlocProvider(
          create: (_) => getIt<AdminCategoryFormBloc>(),
        ),
      ],
      child: AdminLayout(
        child: _CategoriesView(categoryIdToEdit: categoryIdToEdit),
      ),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView({this.categoryIdToEdit});

  final int? categoryIdToEdit;

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  void initState() {
    super.initState();
    if (widget.categoryIdToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditDialog(context.read<AdminCategoryFormBloc>(), widget.categoryIdToEdit!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCategoryFormBloc, AdminCategoryFormState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (category, message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            context.read<AdminCategoryListBloc>().add(const AdminCategoryListEvent.refresh());
            context.go('/admin/categories');
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
      child: BlocBuilder<AdminCategoryListBloc, AdminCategoryListState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (categories) => _buildTable(context, categories),
            error: (message) => Center(child: Text('Erro: $message')),
          );
        },
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categorias',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Categoria'),
              onPressed: () => _showCreateDialog(context.read<AdminCategoryFormBloc>()),
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
          child: categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma categoria encontrada',
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
                      DataColumn(label: Text('Ordem')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Produtos')),
                      DataColumn(label: Text('Ícone')),
                      DataColumn(label: Text('Imagem')),
                      DataColumn(label: Text('Ações'), numeric: true),
                    ],
                    rows: categories.map((category) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          DataCell(Text(category.slug)),
                          DataCell(Text(category.sortOrder.toString())),
                          DataCell(
                            _buildStatusChip(category.isActive),
                          ),
                          DataCell(Text('${category.productsCount}')),
                          DataCell(
                            category.iconUrl != null && category.iconUrl!.isNotEmpty
                                ? Image.network(
                                    category.iconUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                  )
                                : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                          DataCell(
                            category.imageUrl != null && category.imageUrl!.isNotEmpty
                                ? Image.network(
                                    category.imageUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                  )
                                : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Colors.orange.shade600),
                                  onPressed: () => _showEditDialog(
                                    context.read<AdminCategoryFormBloc>(),
                                    category.id,
                                  ),
                                  tooltip: 'Editar',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
                                  onPressed: () => _confirmDelete(context, category.id, category.name),
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
        isActive ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }

  void _showCreateDialog(AdminCategoryFormBloc formBloc) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');
    final iconUrlController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool isActive = true;
    bool isSlugAutoGenerated = true;

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: formBloc,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocConsumer<AdminCategoryFormBloc, AdminCategoryFormState>(
              listener: (context, state) {},
              builder: (context, state) {
                return AlertDialog(
                  title: const Text('Nova Categoria'),
                  content: SizedBox(
                    width: 500,
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
                                hintText: 'Ex: Frutas',
                              ),
                              validator: (value) =>
                                  value?.trim().isEmpty ?? true ? 'Nome é obrigatório' : null,
                              onChanged: (value) {
                                if (slugController.text.isEmpty || isSlugAutoGenerated) {
                                  setDialogState(() {
                                    slugController.text = _generateSlug(value);
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
                              controller: sortOrderController,
                              decoration: const InputDecoration(
                                labelText: 'Ordem',
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Ativo'),
                              value: isActive,
                              onChanged: (value) => setDialogState(() => isActive = value),
                              activeThumbColor: Colors.green.shade600,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: iconUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL do Ícone',
                                hintText: 'https://exemplo.com/icone.png',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL da Imagem',
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
                                formBloc.add(AdminCategoryFormEvent.create({
                                  'name': nameController.text.trim(),
                                  'slug': slugController.text.trim(),
                                  'sort_order': int.tryParse(sortOrderController.text) ?? 0,
                                  'is_active': isActive,
                                  'icon_url': iconUrlController.text.trim().isEmpty
                                      ? null
                                      : iconUrlController.text.trim(),
                                  'image_url': imageUrlController.text.trim().isEmpty
                                      ? null
                                      : imageUrlController.text.trim(),
                                }));
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
        ),
      ),
    );
  }

  void _showEditDialog(AdminCategoryFormBloc formBloc, int id) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final sortOrderController = TextEditingController();
    final iconUrlController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool isActive = true;
    bool isSlugAutoGenerated = true;
    bool isLoading = true;

    // Carregar categoria usando o repositório diretamente via getIt
    getIt<AdminCategoryRepository>().getById(id).then((category) {
      nameController.text = category.name;
      slugController.text = category.slug;
      sortOrderController.text = category.sortOrder.toString();
      iconUrlController.text = category.iconUrl ?? '';
      imageUrlController.text = category.imageUrl ?? '';
      isActive = category.isActive;
      isLoading = false;
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar categoria: $e'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    });

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: formBloc,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocConsumer<AdminCategoryFormBloc, AdminCategoryFormState>(
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

                return AlertDialog(
                  title: const Text('Editar Categoria'),
                  content: SizedBox(
                    width: 500,
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
                                hintText: 'Ex: Frutas',
                              ),
                              validator: (value) =>
                                  value?.trim().isEmpty ?? true ? 'Nome é obrigatório' : null,
                              onChanged: (value) {
                                if (slugController.text.isEmpty || isSlugAutoGenerated) {
                                  setDialogState(() {
                                    slugController.text = _generateSlug(value);
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
                              controller: sortOrderController,
                              decoration: const InputDecoration(
                                labelText: 'Ordem',
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Ativo'),
                              value: isActive,
                              onChanged: (value) => setDialogState(() => isActive = value),
                              activeThumbColor: Colors.green.shade600,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: iconUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL do Ícone',
                                hintText: 'https://exemplo.com/icone.png',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL da Imagem',
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
                                  formBloc.add(AdminCategoryFormEvent.update(id, {
                                    'name': nameController.text.trim(),
                                    'slug': slugController.text.trim(),
                                    'sort_order': int.tryParse(sortOrderController.text) ?? 0,
                                    'is_active': isActive,
                                    'icon_url': iconUrlController.text.trim().isEmpty
                                        ? null
                                        : iconUrlController.text.trim(),
                                    'image_url': imageUrlController.text.trim().isEmpty
                                        ? null
                                        : imageUrlController.text.trim(),
                                  }));
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
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Tem certeza que deseja excluir a categoria "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCategoryFormBloc>().add(AdminCategoryFormEvent.delete(id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}