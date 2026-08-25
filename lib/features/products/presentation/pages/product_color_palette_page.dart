import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/product_color.dart';
import '../../domain/value_objects/product_color_status.dart';
import '../bloc/product_color_palette_bloc.dart';
import '../bloc/product_color_palette_event.dart';
import '../bloc/product_color_palette_state.dart';

class ProductColorPalettePage extends StatelessWidget {
  const ProductColorPalettePage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ProductColorPaletteBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.catalogManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ProductColorPaletteBloc>(
          create: (_) => createBloc()
            ..add(
              ProductColorPaletteStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: const _ProductColorPaletteView(),
        );
      },
    );
  }
}

class _ProductColorPaletteView extends StatelessWidget {
  const _ProductColorPaletteView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ProductColorPaletteBloc, ProductColorPaletteState>(
        listenWhen: (previous, current) =>
            previous.saveStatus != current.saveStatus,
        listener: (context, state) async {
          if (state.saveStatus == ProductColorPaletteSaveStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Cor salva na paleta.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.saveStatus == ProductColorPaletteSaveStatus.failure) {
            AppSnackbar.show(
              context,
              message: state.failure?.message ?? 'Não foi possível salvar.',
              variant: AppSnackbarVariant.error,
            );
          }
          if (state.saveStatus ==
              ProductColorPaletteSaveStatus.similarityWarning) {
            final similar = state.similarColor;
            final confirmed = await AppConfirmationDialog.show(
              context: context,
              title: 'Cor semelhante encontrada',
              message: similar == null
                  ? 'Já existe uma cor parecida nesta organização. Confirma mesmo assim?'
                  : 'A cor "${similar.name}" (${similar.hex.value}) parece equivalente. Confirma mesmo assim?',
              confirmLabel: 'Confirmar duplicidade',
            );
            if (confirmed && context.mounted) {
              context.read<ProductColorPaletteBloc>().add(
                const ProductColorPaletteSubmitted(confirmSimilarColor: true),
              );
            }
          }
        },
        builder: (context, state) {
          final bloc = context.read<ProductColorPaletteBloc>();
          return AppAdminPageLayout(
            title: 'Cores',
            actions: <Widget>[
              AppButton(
                label: 'Nova cor',
                leadingIcon: Icons.palette_outlined,
                onPressed: () async {
                  bloc.add(const ProductColorPaletteCreateRequested());
                  await _showColorForm(context);
                },
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por nome, código ou hex',
                  onSearch: (query) =>
                      bloc.add(ProductColorPaletteSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(child: _ColorTable(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showColorForm(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<ProductColorPaletteBloc>.value(
        value: context.read<ProductColorPaletteBloc>(),
        child: const _ColorFormDialog(),
      ),
    );
  }
}

class _ColorTable extends StatelessWidget {
  const _ColorTable({required this.state});

  final ProductColorPaletteState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductColorPaletteBloc>();
    if (state.loadStatus == ProductColorPaletteLoadStatus.ready &&
        state.colors.isEmpty) {
      return AppEmptyState(
        icon: Icons.palette_outlined,
        title: 'Nenhuma cor cadastrada',
        description:
            'Crie a paleta reutilizável da organização para associar cores aos produtos sem duplicidade.',
        actionLabel: 'Criar primeira cor',
        onAction: () async {
          bloc.add(const ProductColorPaletteCreateRequested());
          await showDialog<void>(
            context: context,
            builder: (_) => BlocProvider<ProductColorPaletteBloc>.value(
              value: bloc,
              child: const _ColorFormDialog(),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      child: AppDataTable<ProductColor>(
        status: switch (state.loadStatus) {
          ProductColorPaletteLoadStatus.loading => AppDataTableStatus.loading,
          ProductColorPaletteLoadStatus.failure => AppDataTableStatus.error,
          ProductColorPaletteLoadStatus.ready =>
            state.filteredColors.isEmpty
                ? AppDataTableStatus.empty
                : AppDataTableStatus.idle,
        },
        rows: state.filteredColors,
        rowIdBuilder: (color) => color.id,
        emptyTitle: 'Nenhuma cor encontrada',
        emptyDescription: 'Ajuste a busca para localizar outra cor.',
        errorTitle: 'Não foi possível carregar as cores',
        errorMessage: state.failure?.message ?? 'Tente novamente em breve.',
        mobileCardTitleBuilder: (context, color) => Text(color.name),
        columns: <AppDataColumn<ProductColor>>[
          AppDataColumn(
            label: 'Cor',
            cellBuilder: (context, color) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Swatch(color: color),
                const SizedBox(width: AppSpacing.spacing8),
                Flexible(child: Text(color.name)),
              ],
            ),
          ),
          AppDataColumn(
            label: 'Código',
            cellBuilder: (context, color) => Text(color.code),
          ),
          AppDataColumn(
            label: 'Hex',
            cellBuilder: (context, color) => Text(color.hex.value),
          ),
          AppDataColumn(
            label: 'Status',
            cellBuilder: (context, color) => Text(
              color.status == ProductColorStatus.available
                  ? 'Disponível'
                  : 'Indisponível',
            ),
          ),
        ],
        rowActions: <AppDataTableAction<ProductColor>>[
          AppDataTableAction<ProductColor>(
            icon: Icons.edit_outlined,
            semanticLabel: 'Editar cor',
            onPressed: (color) async {
              bloc.add(ProductColorPaletteEditRequested(color));
              await showDialog<void>(
                context: context,
                builder: (_) => BlocProvider<ProductColorPaletteBloc>.value(
                  value: bloc,
                  child: const _ColorFormDialog(),
                ),
              );
            },
          ),
          AppDataTableAction<ProductColor>(
            icon: Icons.block,
            semanticLabel: 'Marcar cor como indisponível',
            onPressed: (color) =>
                bloc.add(ProductColorPaletteUnavailableRequested(color)),
          ),
        ],
      ),
    );
  }
}

class _ColorFormDialog extends StatefulWidget {
  const _ColorFormDialog();

  @override
  State<_ColorFormDialog> createState() => _ColorFormDialogState();
}

class _ColorFormDialogState extends State<_ColorFormDialog> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _hexController = TextEditingController();
  final _mainImageController = TextEditingController();
  final _additionalImagesController = TextEditingController();
  final _eansController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _hexController.dispose();
    _mainImageController.dispose();
    _additionalImagesController.dispose();
    _eansController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductColorPaletteBloc, ProductColorPaletteState>(
      listenWhen: (previous, current) =>
          previous.code != current.code ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        _sync(_codeController, state.code);
        _sync(_nameController, state.name);
        _sync(_hexController, state.hex);
        _sync(_mainImageController, state.mainImageUrl);
        _sync(_additionalImagesController, state.additionalImageUrls);
        _sync(_eansController, state.eans);
        if (state.saveStatus == ProductColorPaletteSaveStatus.success &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        _sync(_codeController, state.code);
        _sync(_nameController, state.name);
        _sync(_hexController, state.hex);
        _sync(_mainImageController, state.mainImageUrl);
        _sync(_additionalImagesController, state.additionalImageUrls);
        _sync(_eansController, state.eans);
        final bloc = context.read<ProductColorPaletteBloc>();
        void emit() => bloc.add(
          ProductColorPaletteFormChanged(
            code: _codeController.text,
            name: _nameController.text,
            hex: _hexController.text,
            mainImageUrl: _mainImageController.text,
            additionalImageUrls: _additionalImagesController.text,
            eans: _eansController.text,
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            state.isEditing ? 'Editar cor' : 'Nova cor',
                            style: AppTypography.titleMedium.copyWith(
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                        _SwatchFromHex(hex: state.hex),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    _FieldGrid(
                      children: <Widget>[
                        AppTextField(
                          controller: _codeController,
                          label: 'Código',
                          semanticLabel: 'Código da cor',
                          isRequired: true,
                          errorText: state.fieldErrors['code'],
                          onChanged: (_) => emit(),
                        ),
                        AppTextField(
                          controller: _nameController,
                          label: 'Nome',
                          semanticLabel: 'Nome da cor',
                          isRequired: true,
                          errorText: state.fieldErrors['name'],
                          onChanged: (_) => emit(),
                        ),
                        AppTextField(
                          controller: _hexController,
                          label: 'Hex',
                          hintText: '#1F3A5F',
                          semanticLabel: 'Hexadecimal da cor',
                          isRequired: true,
                          errorText: state.fieldErrors['hex'],
                          onChanged: (_) => emit(),
                        ),
                        AppTextField(
                          controller: _eansController,
                          label: 'EANs da cor',
                          hintText: 'Separados por vírgula',
                          semanticLabel: 'EANs da cor',
                          errorText: state.fieldErrors['eans'],
                          onChanged: (_) => emit(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing12),
                    AppTextField(
                      controller: _mainImageController,
                      label: 'Imagem principal',
                      hintText: 'URL da imagem',
                      semanticLabel: 'Imagem principal da cor',
                      onChanged: (_) => emit(),
                    ),
                    const SizedBox(height: AppSpacing.spacing12),
                    AppTextField(
                      controller: _additionalImagesController,
                      label: 'Imagens adicionais',
                      hintText: 'Uma URL por linha',
                      semanticLabel: 'Imagens adicionais da cor',
                      maxLines: 3,
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
                          label: 'Salvar cor',
                          leadingIcon: Icons.save_outlined,
                          isLoading: state.isBusy,
                          onPressed: state.isBusy
                              ? null
                              : () => bloc.add(
                                  const ProductColorPaletteSubmitted(),
                                ),
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

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: <Widget>[
              for (final child in children) ...<Widget>[
                child,
                const SizedBox(height: AppSpacing.spacing12),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.spacing12,
          runSpacing: AppSpacing.spacing12,
          children: <Widget>[
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.spacing12) / 2,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final ProductColor color;

  @override
  Widget build(BuildContext context) => _SwatchFromHex(hex: color.hex.value);
}

class _SwatchFromHex extends StatelessWidget {
  const _SwatchFromHex({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return Container(
      width: AppSpacing.spacing32,
      height: AppSpacing.spacing32,
      decoration: BoxDecoration(
        color: parsed == null ? Colors.transparent : Color(parsed | 0xFF000000),
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.outline),
      ),
    );
  }
}
