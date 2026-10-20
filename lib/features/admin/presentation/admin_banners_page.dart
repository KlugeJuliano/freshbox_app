import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freshbox_app/core/di/injection.dart';
import 'package:freshbox_app/core/utils/image_picker_helper.dart';
import 'package:freshbox_app/features/admin/presentation/admin_layout.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_list_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_list_state.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_form_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_form_state.dart';
import 'package:freshbox_app/features/admin/domain/banner.dart' as banner_model;
import 'package:freshbox_app/shared/widgets/cached_image.dart';

typedef BannerLinkType = banner_model.BannerLinkType;

class AdminBannersPage extends StatelessWidget {
  const AdminBannersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AdminBannerListBloc>()
            ..add(const AdminBannerListEvent.load()),
        ),
        BlocProvider(
          create: (_) => getIt<AdminBannerFormBloc>(),
        ),
      ],
      child: const AdminLayout(
        child: _BannersView(),
      ),
    );
  }
}

class _BannersView extends StatefulWidget {
  const _BannersView();

  @override
  State<_BannersView> createState() => _BannersViewState();
}

class _BannersViewState extends State<_BannersView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBannerFormBloc, AdminBannerFormState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (banner, message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            context
                .read<AdminBannerListBloc>()
                .add(const AdminBannerListEvent.refresh());
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
      child: BlocBuilder<AdminBannerListBloc, AdminBannerListState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Banners',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo banner_model.Banner'),
                    onPressed: state.maybeWhen(
                      loading: () => true,
                      orElse: () => false,
                    )
                        ? null
                        : () => _showCreateDialog(
                            context.read<AdminBannerFormBloc>()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: state.when(
                  initial: () =>
                      const Center(child: CircularProgressIndicator()),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (banners) => _buildTable(context, banners),
                  error: (message) => Center(child: Text('Erro: $message')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<banner_model.Banner> banners) {
    if (banners.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.image, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhum banner cadastrado',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Use "Novo banner_model.Banner" para criar o primeiro',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
          headingRowHeight: 48,
          dataRowMinHeight: 52,
          columnSpacing: 24,
          horizontalMargin: 16,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Imagem')),
            DataColumn(label: Text('Título')),
            DataColumn(label: Text('Link')),
            DataColumn(label: Text('Prioridade')),
            DataColumn(label: Text('Período')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações'), numeric: true),
          ],
          rows: banners.map((banner) {
            return DataRow(
              cells: [
                DataCell(
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: banner.imageUrl != null &&
                            banner.imageUrl!.isNotEmpty
                        ? CachedImage(
                            imageUrl: banner.imageUrl!,
                            width: 64,
                            height: 36,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 64,
                            height: 36,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_outlined, size: 20),
                          ),
                  ),
                ),
                DataCell(
                  Text(
                    banner.title ?? '(sem título)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(Text(_linkDescription(banner))),
                DataCell(Text(banner.priority.toString())),
                DataCell(Text(_periodDescription(banner))),
                DataCell(_buildStatusChip(banner.isActive)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          banner.isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: banner.isActive ? Colors.green : Colors.grey,
                        ),
                        tooltip: banner.isActive ? 'Desativar' : 'Ativar',
                        onPressed: () => context
                            .read<AdminBannerFormBloc>()
                            .add(AdminBannerFormEvent.toggle(banner.id)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: () => _showEditDialog(
                          context.read<AdminBannerFormBloc>(),
                          banner,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        tooltip: 'Excluir',
                        onPressed: () =>
                            _confirmDelete(context, banner.id, banner.title),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _linkDescription(banner_model.Banner banner) {
    switch (banner.linkType) {
      case BannerLinkType.product:
        return 'Produto: ${banner.linkValue ?? '-'}';
      case BannerLinkType.category:
        return 'Categoria: ${banner.linkValue ?? '-'}';
      case BannerLinkType.url:
        return banner.linkValue ?? '-';
      case BannerLinkType.none:
      case BannerLinkType.unknown:
        return '—';
    }
  }

  String _periodDescription(banner_model.Banner banner) {
    final start = banner.periodStart;
    final end = banner.periodEnd;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (start == null && end == null) return 'Sempre';
    if (start == null) return 'Até ${fmt(end!)}';
    if (end == null) return 'A partir de ${fmt(start)}';
    return '${fmt(start)} – ${fmt(end)}';
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
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showCreateDialog(AdminBannerFormBloc formBloc) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final linkValueController = TextEditingController();
    final priorityController = TextEditingController(text: '0');
    DateTime? periodStart;
    DateTime? periodEnd;
    BannerLinkType selectedLinkType = BannerLinkType.none;
    bool isActive = true;
    File? imageFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo banner_model.Banner'),
          content: SizedBox(
            width: 420,
            child: BlocConsumer<AdminBannerFormBloc, AdminBannerFormState>(
              listener: (context, state) {
                state.whenOrNull(success: (banner, message) {
                  Navigator.pop(context);
                });
              },
              builder: (context, state) => Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Título (opcional)',
                          counterText: '',
                        ),
                      ),
                      TextFormField(
                        controller: subtitleController,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          labelText: 'Subtítulo (opcional)',
                          counterText: '',
                        ),
                      ),
                      TextFormField(
                        controller: priorityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Prioridade (maior = primeiro)'),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? 'Prioridade deve ser um número'
                            : null,
                      ),
                      DropdownButtonFormField<BannerLinkType>(
                        initialValue: selectedLinkType,
                        decoration: const InputDecoration(
                            labelText: 'Ao clicar no banner'),
                        items: BannerLinkType.values
                            .where((t) => t != BannerLinkType.unknown)
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (t) => setDialogState(
                            () => selectedLinkType = t ?? BannerLinkType.none),
                      ),
                      if (selectedLinkType != BannerLinkType.none)
                        TextFormField(
                          controller: linkValueController,
                          decoration: InputDecoration(
                            labelText: _linkValueLabel(selectedLinkType),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe o valor do link'
                                  : null,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Início (opcional)'),
                              child: Text(periodStart == null
                                  ? '—'
                                  : _fmtDate(periodStart!)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked =
                                  await _pickDate(context, periodStart);
                              if (picked != null) {
                                setDialogState(() => periodStart = picked);
                              }
                            },
                          ),
                          if (periodStart != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => periodStart = null),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Fim (opcional)'),
                              child: Text(periodEnd == null
                                  ? '—'
                                  : _fmtDate(periodEnd!)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked =
                                  await _pickDate(context, periodEnd);
                              if (picked != null) {
                                setDialogState(() => periodEnd = picked);
                              }
                            },
                          ),
                          if (periodEnd != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => periodEnd = null),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('Ativo'),
                        value: isActive,
                        onChanged: (value) =>
                            setDialogState(() => isActive = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      _buildImageField(
                        context,
                        imageFile: imageFile,
                        onChanged: (picked) =>
                            setDialogState(() => imageFile = picked),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state.maybeWhen(
                          submitting: () => true,
                          orElse: () => false,
                        )
                            ? null
                            : () {
                                if (imageFile == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'A imagem desktop é obrigatória'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (formKey.currentState?.validate() ?? false) {
                                  formBloc.add(AdminBannerFormEvent.create(
                                    _buildPayload(
                                      titleController: titleController,
                                      subtitleController: subtitleController,
                                      linkValueController: linkValueController,
                                      priorityController: priorityController,
                                      linkType: selectedLinkType,
                                      periodStart: periodStart,
                                      periodEnd: periodEnd,
                                      isActive: isActive,
                                    ),
                                    imageFile!,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: state.maybeWhen(
                          submitting: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          orElse: () =>
                              const Text('Salvar banner_model.Banner'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
      AdminBannerFormBloc formBloc, banner_model.Banner banner) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: banner.title);
    final subtitleController = TextEditingController(text: banner.subtitle);
    final linkValueController = TextEditingController(text: banner.linkValue);
    final priorityController =
        TextEditingController(text: banner.priority.toString());
    DateTime? periodStart = banner.periodStart;
    DateTime? periodEnd = banner.periodEnd;
    BannerLinkType selectedLinkType = banner.linkType;
    bool isActive = banner.isActive;
    File? imageFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar banner_model.Banner'),
          content: SizedBox(
            width: 420,
            child: BlocConsumer<AdminBannerFormBloc, AdminBannerFormState>(
              listener: (context, state) {
                state.whenOrNull(success: (updated, message) {
                  Navigator.pop(context);
                });
              },
              builder: (context, state) => Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Título (opcional)',
                          counterText: '',
                        ),
                      ),
                      TextFormField(
                        controller: subtitleController,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          labelText: 'Subtítulo (opcional)',
                          counterText: '',
                        ),
                      ),
                      TextFormField(
                        controller: priorityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Prioridade (maior = primeiro)'),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? 'Prioridade deve ser um número'
                            : null,
                      ),
                      DropdownButtonFormField<BannerLinkType>(
                        initialValue: selectedLinkType,
                        decoration: const InputDecoration(
                            labelText: 'Ao clicar no banner'),
                        items: BannerLinkType.values
                            .where((t) => t != BannerLinkType.unknown)
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (t) => setDialogState(
                            () => selectedLinkType = t ?? BannerLinkType.none),
                      ),
                      if (selectedLinkType != BannerLinkType.none)
                        TextFormField(
                          controller: linkValueController,
                          decoration: InputDecoration(
                            labelText: _linkValueLabel(selectedLinkType),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe o valor do link'
                                  : null,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Início (opcional)'),
                              child: Text(periodStart == null
                                  ? '—'
                                  : _fmtDate(periodStart!)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked =
                                  await _pickDate(context, periodStart);
                              if (picked != null) {
                                setDialogState(() => periodStart = picked);
                              }
                            },
                          ),
                          if (periodStart != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => periodStart = null),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Fim (opcional)'),
                              child: Text(periodEnd == null
                                  ? '—'
                                  : _fmtDate(periodEnd!)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked =
                                  await _pickDate(context, periodEnd);
                              if (picked != null) {
                                setDialogState(() => periodEnd = picked);
                              }
                            },
                          ),
                          if (periodEnd != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => periodEnd = null),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('Ativo'),
                        value: isActive,
                        onChanged: (value) =>
                            setDialogState(() => isActive = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      _buildImageField(
                        context,
                        imageFile: imageFile,
                        fallbackUrl: banner.imageUrl,
                        onChanged: (picked) =>
                            setDialogState(() => imageFile = picked),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state.maybeWhen(
                          submitting: () => true,
                          orElse: () => false,
                        )
                            ? null
                            : () {
                                if (formKey.currentState?.validate() ?? false) {
                                  formBloc.add(AdminBannerFormEvent.update(
                                    banner.id,
                                    _buildPayload(
                                      titleController: titleController,
                                      subtitleController: subtitleController,
                                      linkValueController: linkValueController,
                                      priorityController: priorityController,
                                      linkType: selectedLinkType,
                                      periodStart: periodStart,
                                      periodEnd: periodEnd,
                                      isActive: isActive,
                                    ),
                                    image: imageFile,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: state.maybeWhen(
                          submitting: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          orElse: () => const Text('Salvar Alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildPayload({
    required TextEditingController titleController,
    required TextEditingController subtitleController,
    required TextEditingController linkValueController,
    required TextEditingController priorityController,
    required BannerLinkType linkType,
    DateTime? periodStart,
    DateTime? periodEnd,
    required bool isActive,
  }) {
    final data = <String, dynamic>{
      'is_active': isActive ? 'true' : 'false',
      'priority': priorityController.text.trim(),
    };
    if (titleController.text.trim().isNotEmpty) {
      data['title'] = titleController.text.trim();
    }
    if (subtitleController.text.trim().isNotEmpty) {
      data['subtitle'] = subtitleController.text.trim();
    }
    if (linkType != BannerLinkType.none) {
      data['link_type'] = linkType.apiValue;
      data['link_value'] = linkValueController.text.trim();
    } else {
      data['link_type'] = 'none';
    }
    if (periodStart != null) {
      data['period_start'] = _isoDate(periodStart);
    }
    if (periodEnd != null) {
      data['period_end'] = _isoDate(periodEnd);
    }
    return data;
  }

  Widget _buildImageField(
    BuildContext context, {
    File? imageFile,
    String? fallbackUrl,
    required void Function(File?) onChanged,
  }) {
    final bool isCreate = fallbackUrl == null;
    final hasNew = imageFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCreate
              ? 'Imagem do banner (obrigatória)'
              : 'Imagem do banner (opcional — troca se escolher outra)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasNew
                  ? Image.file(
                      imageFile,
                      width: 96,
                      height: 54,
                      fit: BoxFit.cover,
                    )
                  : (fallbackUrl != null && fallbackUrl.isNotEmpty)
                      ? CachedImage(
                          imageUrl: fallbackUrl,
                          width: 96,
                          height: 54,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 96,
                          height: 54,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_outlined, size: 24),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePickerHelper().pickAndCompress(
                        source: ImageSource.gallery,
                      );
                      onChanged(picked);
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeria'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePickerHelper().pickAndCompress(
                        source: ImageSource.camera,
                      );
                      onChanged(picked);
                    },
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Câmera'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _linkValueLabel(BannerLinkType type) {
    switch (type) {
      case BannerLinkType.product:
        return 'Slug do produto';
      case BannerLinkType.category:
        return 'Slug da categoria';
      case BannerLinkType.url:
        return 'URL (https://...)';
      default:
        return 'Valor do link';
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
  }

  void _confirmDelete(BuildContext context, int id, String? title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir banner_model.Banner'),
        content: Text('Tem certeza que deseja excluir o banner "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AdminBannerFormBloc>()
                  .add(AdminBannerFormEvent.delete(id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
