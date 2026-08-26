import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/bloc/product_search_bloc.dart';
import '../../../products/presentation/pages/product_search_page.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../bloc/campaign_form_bloc.dart';
import '../bloc/campaign_form_event.dart';
import '../bloc/campaign_form_state.dart';

/// Create/edit page for `CatalogCampaign` (TASK-080): title/subtitle/
/// description, activation window, cover + editorial images (reordered the
/// same way `ProductMediaGallerySection` already established, TASK-068) and
/// a curated related-products list, picked via the existing
/// `ProductSearchPage` (TASK-064's global search) rather than a bespoke
/// picker.
///
/// A full page (unlike `CollectionFormPage`'s bottom sheet): the image
/// gallery and product picker need real screen space, the same reasoning
/// `ProductFormPage` already applies to `Product`.
class CampaignFormPage extends StatelessWidget {
  const CampaignFormPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.createProductSearchBloc,
    this.initialCampaign,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final CampaignFormBloc Function() createBloc;
  final ProductSearchBloc Function() createProductSearchBloc;
  final CatalogCampaign? initialCampaign;

  static Future<CatalogCampaign?> push({
    required BuildContext context,
    required String organizationId,
    required String userId,
    required PermissionService permissionService,
    required CampaignFormBloc Function() createBloc,
    required ProductSearchBloc Function() createProductSearchBloc,
    CatalogCampaign? initialCampaign,
  }) {
    return Navigator.of(context).push<CatalogCampaign>(
      MaterialPageRoute<CatalogCampaign>(
        builder: (_) => CampaignFormPage(
          organizationId: organizationId,
          userId: userId,
          permissionService: permissionService,
          createBloc: createBloc,
          createProductSearchBloc: createProductSearchBloc,
          initialCampaign: initialCampaign,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.catalogManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CampaignFormBloc>(
          create: (_) => createBloc()
            ..add(
              CampaignFormStarted(
                organizationId: organizationId,
                userId: userId,
                initialCampaign: initialCampaign,
              ),
            ),
          child: Scaffold(
            body: AppAdminPageLayout(
              title: initialCampaign == null
                  ? 'Nova campanha'
                  : 'Editar campanha',
              content: _CampaignFormView(
                createProductSearchBloc: createProductSearchBloc,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CampaignFormView extends StatelessWidget {
  const _CampaignFormView({required this.createProductSearchBloc});

  final ProductSearchBloc Function() createProductSearchBloc;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CampaignFormBloc, CampaignFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == CampaignFormSubmissionStatus.failure &&
            state.fieldErrors.isEmpty) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos da campanha.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == CampaignFormSubmissionStatus.success &&
            state.savedCampaign != null) {
          AppSnackbar.show(
            context,
            message: 'Campanha salva.',
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop(state.savedCampaign);
        }
      },
      builder: (context, state) {
        if (state.loadStatus == CampaignFormLoadStatus.failure) {
          return AppErrorState(
            title: 'Não foi possível carregar a campanha',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          );
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _CampaignTitleField(state: state),
                const SizedBox(height: AppSpacing.spacing16),
                _CampaignSubtitleField(state: state),
                const SizedBox(height: AppSpacing.spacing16),
                _CampaignDescriptionField(state: state),
                const SizedBox(height: AppSpacing.spacing16),
                AppCheckbox(
                  value: state.active,
                  label: 'Campanha ativa',
                  isDisabled: state.isSubmitting,
                  onChanged: (value) => context.read<CampaignFormBloc>().add(
                    CampaignFormActiveChanged(value),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                _CampaignDateRangeRow(state: state),
                if (state.fieldErrors['endAt'] != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    state.fieldErrors['endAt']!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.spacing24),
                Text('Imagem de capa', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spacing8),
                _CampaignCoverImage(state: state),
                const SizedBox(height: AppSpacing.spacing24),
                Text('Imagens editoriais', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spacing8),
                _CampaignEditorialImages(state: state),
                const SizedBox(height: AppSpacing.spacing24),
                Text('Produtos relacionados', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spacing8),
                _CampaignRelatedProducts(
                  state: state,
                  createProductSearchBloc: createProductSearchBloc,
                ),
                const SizedBox(height: AppSpacing.spacing32),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: state.isEditing
                        ? 'Salvar alterações'
                        : 'Criar campanha',
                    leadingIcon: Icons.save_outlined,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting
                        ? null
                        : () => context.read<CampaignFormBloc>().add(
                            const CampaignFormSubmitted(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CampaignTitleField extends StatefulWidget {
  const _CampaignTitleField({required this.state});

  final CampaignFormState state;

  @override
  State<_CampaignTitleField> createState() => _CampaignTitleFieldState();
}

class _CampaignTitleFieldState extends State<_CampaignTitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.title);
  }

  @override
  void didUpdateWidget(covariant _CampaignTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.title != _controller.text) {
      _controller.text = widget.state.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'Título da campanha',
      hintText: 'Ex.: Verão em Movimento',
      isRequired: true,
      isDisabled: widget.state.isSubmitting,
      errorText: widget.state.fieldErrors['title'],
      textInputAction: TextInputAction.next,
      onChanged: (value) =>
          context.read<CampaignFormBloc>().add(CampaignFormTitleChanged(value)),
    );
  }
}

class _CampaignSubtitleField extends StatefulWidget {
  const _CampaignSubtitleField({required this.state});

  final CampaignFormState state;

  @override
  State<_CampaignSubtitleField> createState() => _CampaignSubtitleFieldState();
}

class _CampaignSubtitleFieldState extends State<_CampaignSubtitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.subtitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'Subtítulo',
      hintText: 'Ex.: Nova coleção de verão',
      isDisabled: widget.state.isSubmitting,
      textInputAction: TextInputAction.next,
      onChanged: (value) => context.read<CampaignFormBloc>().add(
        CampaignFormSubtitleChanged(value),
      ),
    );
  }
}

class _CampaignDescriptionField extends StatefulWidget {
  const _CampaignDescriptionField({required this.state});

  final CampaignFormState state;

  @override
  State<_CampaignDescriptionField> createState() =>
      _CampaignDescriptionFieldState();
}

class _CampaignDescriptionFieldState extends State<_CampaignDescriptionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'Texto editorial',
      hintText: 'Descreva a narrativa da campanha para o lookbook.',
      maxLines: 4,
      isDisabled: widget.state.isSubmitting,
      onChanged: (value) => context.read<CampaignFormBloc>().add(
        CampaignFormDescriptionChanged(value),
      ),
    );
  }
}

class _CampaignDateRangeRow extends StatelessWidget {
  const _CampaignDateRangeRow({required this.state});

  final CampaignFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CampaignFormBloc>();
    final isSubmitting = state.isSubmitting;

    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Início: ${_label(state.startAt)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () async {
                    final picked = await _pickDate(context, state.startAt);
                    if (picked != null) {
                      bloc.add(CampaignFormStartAtChanged(picked));
                    }
                  },
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: AppButton(
            label: 'Fim: ${_label(state.endAt)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () async {
                    final picked = await _pickDate(context, state.endAt);
                    if (picked != null) {
                      bloc.add(CampaignFormEndAtChanged(picked));
                    }
                  },
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 5),
    );
  }

  String _label(DateTime? date) {
    if (date == null) return 'sem data';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _CampaignCoverImage extends StatelessWidget {
  const _CampaignCoverImage({required this.state});

  final CampaignFormState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bloc = context.read<CampaignFormBloc>();

    if (state.isUploadingCover) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
        child: LinearProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (state.coverImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radius12),
            child: Image.network(
              state.coverImageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: colors.surfaceContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.outline,
                ),
              ),
            ),
          )
        else
          Text(
            'Nenhuma imagem de capa selecionada.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          children: <Widget>[
            AppButton(
              label: state.coverImageUrl == null
                  ? 'Adicionar capa'
                  : 'Alterar capa',
              leadingIcon: Icons.add_photo_alternate_outlined,
              variant: AppButtonVariant.secondary,
              isDisabled: state.isSubmitting,
              onPressed: () async {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (file == null) return;
                final bytes = await file.readAsBytes();
                bloc.add(CampaignFormCoverImagePicked(bytes));
              },
            ),
            if (state.coverImageUrl != null)
              AppButton(
                label: 'Remover capa',
                leadingIcon: Icons.delete_outline,
                variant: AppButtonVariant.text,
                isDisabled: state.isSubmitting,
                onPressed: () =>
                    bloc.add(const CampaignFormCoverImageRemoved()),
              ),
          ],
        ),
      ],
    );
  }
}

class _CampaignEditorialImages extends StatelessWidget {
  const _CampaignEditorialImages({required this.state});

  final CampaignFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CampaignFormBloc>();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (state.editorialImageUrls.isEmpty &&
            state.uploadingEditorialCount == 0)
          Text(
            'Nenhuma imagem editorial adicionada ainda.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        for (var index = 0; index < state.editorialImageUrls.length; index++)
          _EditorialImageTile(
            key: ValueKey(state.editorialImageUrls[index]),
            url: state.editorialImageUrls[index],
            onMoveUp: index == 0
                ? null
                : () => _reorder(bloc, state, index, index - 1),
            onMoveDown: index == state.editorialImageUrls.length - 1
                ? null
                : () => _reorder(bloc, state, index, index + 1),
            onRemove: () => bloc.add(
              CampaignFormEditorialImageRemoved(
                state.editorialImageUrls[index],
              ),
            ),
            isDisabled: state.isSubmitting,
          ),
        for (var i = 0; i < state.uploadingEditorialCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: AppSpacing.spacing8),
        AppButton(
          label: 'Adicionar imagem editorial',
          leadingIcon: Icons.add_photo_alternate_outlined,
          variant: AppButtonVariant.secondary,
          isDisabled: state.isSubmitting,
          onPressed: () async {
            final file = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
            if (file == null) return;
            final bytes = await file.readAsBytes();
            bloc.add(CampaignFormEditorialImagePicked(bytes));
          },
        ),
      ],
    );
  }

  void _reorder(
    CampaignFormBloc bloc,
    CampaignFormState state,
    int oldIndex,
    int newIndex,
  ) {
    final reordered = List<String>.of(state.editorialImageUrls);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    bloc.add(CampaignFormEditorialImagesReordered(reordered));
  }
}

class _EditorialImageTile extends StatelessWidget {
  const _EditorialImageTile({
    required super.key,
    required this.url,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.isDisabled,
  });

  final String url;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onRemove;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      padding: const EdgeInsets.all(AppSpacing.spacing8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colors.surfaceContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colors.outline,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          AppIconButton(
            icon: Icons.arrow_upward,
            semanticLabel: 'Mover para cima',
            isDisabled: isDisabled,
            onPressed: onMoveUp,
          ),
          AppIconButton(
            icon: Icons.arrow_downward,
            semanticLabel: 'Mover para baixo',
            isDisabled: isDisabled,
            onPressed: onMoveDown,
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            semanticLabel: 'Excluir imagem editorial',
            isDisabled: isDisabled,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _CampaignRelatedProducts extends StatelessWidget {
  const _CampaignRelatedProducts({
    required this.state,
    required this.createProductSearchBloc,
  });

  final CampaignFormState state;
  final ProductSearchBloc Function() createProductSearchBloc;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CampaignFormBloc>();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (state.relatedProducts.isEmpty)
          Text(
            'Nenhum produto relacionado selecionado.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        for (final product in state.relatedProducts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.checkroom_outlined),
            title: Text(product.name),
            subtitle: Text(product.sku.value),
            trailing: AppIconButton(
              icon: Icons.close,
              semanticLabel: 'Remover ${product.name} da campanha',
              onPressed: () =>
                  bloc.add(CampaignFormRelatedProductRemoved(product.id)),
            ),
          ),
        const SizedBox(height: AppSpacing.spacing8),
        AppButton(
          label: 'Adicionar produto',
          leadingIcon: Icons.search,
          variant: AppButtonVariant.secondary,
          isDisabled: state.isSubmitting,
          onPressed: () => _openProductSearch(context, bloc),
        ),
      ],
    );
  }

  Future<void> _openProductSearch(
    BuildContext context,
    CampaignFormBloc bloc,
  ) async {
    final selected = await Navigator.of(context).push<Product>(
      MaterialPageRoute<Product>(
        builder: (routeContext) => ProductSearchPage(
          organizationId: state.organizationId,
          createBloc: createProductSearchBloc,
          onProductSelected: (product) =>
              Navigator.of(routeContext).pop(product),
        ),
      ),
    );
    if (selected != null) {
      bloc.add(CampaignFormRelatedProductAdded(selected));
    }
  }
}
