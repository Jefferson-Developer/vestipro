import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/size_grid_template.dart';
import '../bloc/size_grid_template_bloc.dart';
import '../bloc/size_grid_template_event.dart';
import '../bloc/size_grid_template_state.dart';

class SizeGridTemplatesPage extends StatelessWidget {
  const SizeGridTemplatesPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final SizeGridTemplateBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.catalogManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<SizeGridTemplateBloc>(
          create: (_) => createBloc()
            ..add(
              SizeGridTemplateStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: const _SizeGridTemplatesView(),
        );
      },
    );
  }
}

class _SizeGridTemplatesView extends StatelessWidget {
  const _SizeGridTemplatesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SizeGridTemplateBloc, SizeGridTemplateState>(
        listenWhen: (previous, current) =>
            previous.saveStatus != current.saveStatus,
        listener: (context, state) async {
          if (state.saveStatus == SizeGridTemplateSaveStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Template de grade salvo.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.saveStatus == SizeGridTemplateSaveStatus.failure) {
            AppSnackbar.show(
              context,
              message: state.failure?.message ?? 'Não foi possível salvar.',
              variant: AppSnackbarVariant.error,
            );
          }
          if (state.saveStatus == SizeGridTemplateSaveStatus.impactWarning) {
            final bloc = context.read<SizeGridTemplateBloc>();
            final confirmed = await AppConfirmationDialog.show(
              context: context,
              title: 'Template em uso',
              message:
                  'Produtos publicados usam este template. Confirme para aplicar a nova ordem ou lista de tamanhos a todos eles.',
              confirmLabel: 'Confirmar impacto',
            );
            if (!context.mounted) return;
            if (confirmed) {
              bloc.add(const SizeGridTemplateConfirmationAccepted());
            }
          }
          if (state.saveStatus ==
              SizeGridTemplateSaveStatus.variantUsageWarning) {
            final bloc = context.read<SizeGridTemplateBloc>();
            final confirmed = await AppConfirmationDialog.show(
              context: context,
              title: 'Tamanho com variantes',
              message:
                  'Este tamanho já tem variantes geradas. Confirme apenas se a grade comercial deve parar de oferecer esse tamanho.',
              confirmLabel: 'Confirmar remoção',
            );
            if (!context.mounted) return;
            if (confirmed) {
              bloc.add(const SizeGridTemplateConfirmationAccepted());
            }
          }
        },
        builder: (context, state) {
          final bloc = context.read<SizeGridTemplateBloc>();
          return AppAdminPageLayout(
            title: 'Grades de tamanho',
            actions: <Widget>[
              AppButton(
                label: 'Nova grade',
                leadingIcon: Icons.straighten_outlined,
                onPressed: () async {
                  bloc.add(const SizeGridTemplateCreateRequested());
                  await _showTemplateForm(context);
                },
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por template ou tamanho',
                  onSearch: (query) =>
                      bloc.add(SizeGridTemplateSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(child: _TemplateTable(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTemplateForm(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<SizeGridTemplateBloc>.value(
        value: context.read<SizeGridTemplateBloc>(),
        child: const _TemplateFormDialog(),
      ),
    );
  }
}

class _TemplateTable extends StatelessWidget {
  const _TemplateTable({required this.state});

  final SizeGridTemplateState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SizeGridTemplateBloc>();
    if (state.loadStatus == SizeGridTemplateLoadStatus.ready &&
        state.templates.isEmpty) {
      return AppEmptyState(
        icon: Icons.straighten_outlined,
        title: 'Nenhuma grade cadastrada',
        description:
            'Crie templates reutilizáveis para que produtos compartilhem a mesma ordem comercial de tamanhos.',
        actionLabel: 'Criar primeira grade',
        onAction: () async {
          bloc.add(const SizeGridTemplateCreateRequested());
          await showDialog<void>(
            context: context,
            builder: (_) => BlocProvider<SizeGridTemplateBloc>.value(
              value: bloc,
              child: const _TemplateFormDialog(),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      child: AppDataTable<SizeGridTemplate>(
        status: switch (state.loadStatus) {
          SizeGridTemplateLoadStatus.loading => AppDataTableStatus.loading,
          SizeGridTemplateLoadStatus.failure => AppDataTableStatus.error,
          SizeGridTemplateLoadStatus.ready =>
            state.filteredTemplates.isEmpty
                ? AppDataTableStatus.empty
                : AppDataTableStatus.idle,
        },
        rows: state.filteredTemplates,
        rowIdBuilder: (template) => template.id,
        emptyTitle: 'Nenhuma grade encontrada',
        emptyDescription: 'Ajuste a busca para localizar outro template.',
        errorTitle: 'Não foi possível carregar as grades',
        errorMessage: state.failure?.message ?? 'Tente novamente em breve.',
        mobileCardTitleBuilder: (context, template) => Text(template.name),
        columns: <AppDataColumn<SizeGridTemplate>>[
          AppDataColumn(
            label: 'Template',
            cellBuilder: (context, template) => Text(template.name),
          ),
          AppDataColumn(
            label: 'Tamanhos',
            cellBuilder: (context, template) =>
                _SizeChips(sizes: template.orderedSizes),
          ),
          AppDataColumn(
            label: 'Total',
            numeric: true,
            cellBuilder: (context, template) =>
                Text('${template.sizes.length}'),
          ),
        ],
        rowActions: <AppDataTableAction<SizeGridTemplate>>[
          AppDataTableAction<SizeGridTemplate>(
            icon: Icons.edit_outlined,
            semanticLabel: 'Editar grade',
            onPressed: (template) async {
              bloc.add(SizeGridTemplateEditRequested(template));
              await showDialog<void>(
                context: context,
                builder: (_) => BlocProvider<SizeGridTemplateBloc>.value(
                  value: bloc,
                  child: const _TemplateFormDialog(),
                ),
              );
            },
          ),
          AppDataTableAction<SizeGridTemplate>(
            icon: Icons.copy_all_outlined,
            semanticLabel: 'Duplicar grade',
            onPressed: (template) =>
                bloc.add(SizeGridTemplateDuplicateRequested(template)),
          ),
          AppDataTableAction<SizeGridTemplate>(
            icon: Icons.swap_vert,
            semanticLabel: 'Reordenar tamanhos',
            onPressed: (template) async {
              await showDialog<void>(
                context: context,
                builder: (_) => BlocProvider<SizeGridTemplateBloc>.value(
                  value: bloc,
                  child: _TemplateReorderDialog(template: template),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SizeChips extends StatelessWidget {
  const _SizeChips({required this.sizes});

  final List<SizeGridSize> sizes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.spacing4,
      runSpacing: AppSpacing.spacing4,
      children: <Widget>[
        for (final size in sizes)
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(size.label),
            avatar: Text('${size.orderScore}'),
          ),
      ],
    );
  }
}

class _TemplateFormDialog extends StatefulWidget {
  const _TemplateFormDialog();

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _nameController = TextEditingController();
  final _sizesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _sizesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SizeGridTemplateBloc, SizeGridTemplateState>(
      listenWhen: (previous, current) =>
          previous.name != current.name ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        _sync(_nameController, state.name);
        _sync(_sizesController, state.sizesInput);
        if (state.saveStatus == SizeGridTemplateSaveStatus.success &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        _sync(_nameController, state.name);
        _sync(_sizesController, state.sizesInput);
        final bloc = context.read<SizeGridTemplateBloc>();
        void emit() => bloc.add(
          SizeGridTemplateFormChanged(
            name: _nameController.text,
            sizesInput: _sizesController.text,
          ),
        );

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      state.isEditing ? 'Editar grade' : 'Nova grade',
                      style: AppTypography.titleMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    AppTextField(
                      controller: _nameController,
                      label: 'Nome do template',
                      semanticLabel: 'Nome do template de grade',
                      isRequired: true,
                      errorText: state.fieldErrors['name'],
                      onChanged: (_) => emit(),
                    ),
                    const SizedBox(height: AppSpacing.spacing12),
                    AppTextField(
                      controller: _sizesController,
                      label: 'Tamanhos em ordem comercial',
                      hintText: 'PP / P / M / G / GG / XGG',
                      semanticLabel: 'Tamanhos em ordem comercial',
                      isRequired: true,
                      maxLines: 6,
                      errorText: state.fieldErrors['sizes'],
                      onChanged: (_) => emit(),
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.spacing12,
                      runSpacing: AppSpacing.spacing12,
                      children: <Widget>[
                        AppButton(
                          label: 'Cancelar',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        AppButton(
                          label: 'Salvar grade',
                          leadingIcon: Icons.save_outlined,
                          isLoading: state.isBusy,
                          onPressed: state.isBusy
                              ? null
                              : () =>
                                    bloc.add(const SizeGridTemplateSubmitted()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }
}

class _TemplateReorderDialog extends StatefulWidget {
  const _TemplateReorderDialog({required this.template});

  final SizeGridTemplate template;

  @override
  State<_TemplateReorderDialog> createState() => _TemplateReorderDialogState();
}

class _TemplateReorderDialogState extends State<_TemplateReorderDialog> {
  late final List<SizeGridSize> _sizes;

  @override
  void initState() {
    super.initState();
    _sizes = widget.template.orderedSizes.toList(growable: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SizeGridTemplateBloc, SizeGridTemplateState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (state.saveStatus == SizeGridTemplateSaveStatus.success &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Reordenar ${widget.template.name}',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: _sizes.length,
                    onReorderItem: _move,
                    itemBuilder: (context, index) {
                      final size = _sizes[index];
                      return ListTile(
                        key: ValueKey(size.id),
                        leading: const Icon(Icons.drag_handle),
                        title: Text(size.label),
                        subtitle: Text('Ordem ${index + 1}'),
                        trailing: Wrap(
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Subir tamanho',
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: index == 0
                                  ? null
                                  : () =>
                                        setState(() => _swap(index, index - 1)),
                            ),
                            IconButton(
                              tooltip: 'Descer tamanho',
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: index == _sizes.length - 1
                                  ? null
                                  : () =>
                                        setState(() => _swap(index, index + 1)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                BlocBuilder<SizeGridTemplateBloc, SizeGridTemplateState>(
                  builder: (context, state) {
                    return Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.spacing12,
                      runSpacing: AppSpacing.spacing12,
                      children: <Widget>[
                        AppButton(
                          label: 'Cancelar',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        AppButton(
                          label: 'Salvar ordem',
                          leadingIcon: Icons.save_outlined,
                          isLoading: state.isBusy,
                          onPressed: state.isBusy
                              ? null
                              : () => context.read<SizeGridTemplateBloc>().add(
                                  SizeGridTemplateReordered(
                                    templateId: widget.template.id,
                                    orderedSizeIds: _sizes
                                        .map((size) => size.id)
                                        .toList(growable: false),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _move(int oldIndex, int newIndex) {
    setState(() {
      final item = _sizes.removeAt(oldIndex);
      _sizes.insert(newIndex, item);
    });
  }

  void _swap(int first, int second) {
    final item = _sizes[first];
    _sizes[first] = _sizes[second];
    _sizes[second] = item;
  }
}
