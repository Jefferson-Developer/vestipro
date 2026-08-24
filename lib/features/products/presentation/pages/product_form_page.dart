import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/product.dart';
import '../../domain/value_objects/product_gender.dart';
import '../../domain/value_objects/product_status.dart';
import '../../domain/value_objects/target_audience.dart';
import '../bloc/product_form_bloc.dart';
import '../bloc/product_form_event.dart';
import '../bloc/product_form_state.dart';

/// Administrative create/edit form for [Product] (TASK-065): six sections
/// (Básico, Categoria, Conteúdo, Características, SEO, Agendamento), a
/// "Salvar rascunho" action that always keeps [ProductStatus.draft], and a
/// "Publicar" action gated by `Capability.catalogManage` that runs
/// `PublishProductUseCase`'s completeness check.
class ProductFormPage extends StatelessWidget {
  const ProductFormPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.actorName,
    required this.permissionService,
    required this.createBloc,
    this.initialProduct,
    this.onSaved,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final PermissionService permissionService;
  final ProductFormBloc Function() createBloc;
  final Product? initialProduct;
  final void Function(Product product)? onSaved;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.catalogManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ProductFormBloc>(
          create: (_) => createBloc()
            ..add(
              ProductFormStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
                actorName: actorName,
                canPublish: granted,
                initialProduct: initialProduct,
              ),
            ),
          child: Scaffold(
            body: AppAdminPageLayout(
              title: initialProduct == null ? 'Novo produto' : 'Editar produto',
              content: _ProductFormView(onSaved: onSaved),
            ),
          ),
        );
      },
    );
  }
}

class _ProductFormView extends StatefulWidget {
  const _ProductFormView({this.onSaved});

  final void Function(Product product)? onSaved;

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  final _nameFocus = FocusNode(debugLabel: 'product.name');
  final _skuFocus = FocusNode(debugLabel: 'product.sku');
  final _referenceFocus = FocusNode(debugLabel: 'product.reference');

  @override
  void dispose() {
    _nameFocus.dispose();
    _skuFocus.dispose();
    _referenceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormBloc, ProductFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus ||
          previous.draftStatus != current.draftStatus ||
          previous.publishStatus != current.publishStatus ||
          previous.hasRestoredDraft != current.hasRestoredDraft,
      listener: (context, state) {
        if (state.hasRestoredDraft) {
          AppSnackbar.show(
            context,
            message: 'Rascunho recuperado.',
            variant: AppSnackbarVariant.info,
          );
        }
        if (state.draftStatus == ProductFormDraftStatus.saved) {
          AppSnackbar.show(
            context,
            message: 'Rascunho salvo.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.draftStatus == ProductFormDraftStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Não foi possível salvar.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == ProductFormSubmissionStatus.failure) {
          _focusFirstError(state);
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos do produto.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == ProductFormSubmissionStatus.success &&
            state.currentProduct != null) {
          widget.onSaved?.call(state.currentProduct!);
          AppSnackbar.show(
            context,
            message: state.wasSavedOffline
                ? 'Produto salvo localmente e pendente de sincronização.'
                : 'Produto salvo.',
            variant: state.wasSavedOffline
                ? AppSnackbarVariant.warning
                : AppSnackbarVariant.success,
          );
        }
        if (state.publishStatus == ProductFormPublishStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Produto publicado.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.publishStatus == ProductFormPublishStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Não foi possível publicar.',
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        return switch (state.loadStatus) {
          ProductFormLoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductFormLoadStatus.failure => AppErrorState(
            title: 'Não foi possível carregar o cadastro',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          ProductFormLoadStatus.ready => _ProductFormContent(
            state: state,
            nameFocus: _nameFocus,
            skuFocus: _skuFocus,
            referenceFocus: _referenceFocus,
          ),
        };
      },
    );
  }

  void _focusFirstError(ProductFormState state) {
    final focusByField = <String, FocusNode>{
      'name': _nameFocus,
      'sku': _skuFocus,
      'reference': _referenceFocus,
    };
    for (final field in const <String>['name', 'sku', 'reference']) {
      if (state.fieldErrors.containsKey(field)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) focusByField[field]?.requestFocus();
        });
        return;
      }
    }
  }
}

class _ProductFormContent extends StatelessWidget {
  const _ProductFormContent({
    required this.state,
    required this.nameFocus,
    required this.skuFocus,
    required this.referenceFocus,
  });

  final ProductFormState state;
  final FocusNode nameFocus;
  final FocusNode skuFocus;
  final FocusNode referenceFocus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ProductStatusBanner(state: state),
              const SizedBox(height: AppSpacing.spacing16),
              _FormSection(
                title: 'Básico',
                initiallyExpanded: true,
                child: _BasicSection(
                  state: state,
                  nameFocus: nameFocus,
                  skuFocus: skuFocus,
                  referenceFocus: referenceFocus,
                ),
              ),
              _FormSection(
                title: 'Categoria',
                child: _CategorySection(state: state),
              ),
              _FormSection(
                title: 'Conteúdo',
                child: _ContentSection(state: state),
              ),
              _FormSection(
                title: 'Características',
                child: _CharacteristicsSection(state: state),
              ),
              _FormSection(
                title: 'SEO',
                child: _SeoSection(state: state),
              ),
              _FormSection(
                title: 'Agendamento',
                child: _ScheduleSection(state: state),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              _ProductFormActions(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStatusBanner extends StatelessWidget {
  const _ProductStatusBanner({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final status = state.currentProduct?.status;
    final (label, variant) = switch (status) {
      null => ('Novo (ainda não salvo)', AppStatusBadgeVariant.neutral),
      ProductStatus.draft => ('Rascunho', AppStatusBadgeVariant.warning),
      ProductStatus.active => ('Ativo', AppStatusBadgeVariant.success),
      ProductStatus.inactive => ('Inativo', AppStatusBadgeVariant.neutral),
      ProductStatus.discontinued => (
        'Descontinuado',
        AppStatusBadgeVariant.error,
      ),
    };
    return Row(
      children: <Widget>[
        AppStatusBadge(label: label, variant: variant),
        if (state.wasSavedOffline) ...<Widget>[
          const SizedBox(width: AppSpacing.spacing8),
          const AppStatusBadge(
            label: 'Pendente de sincronização',
            variant: AppStatusBadgeVariant.warning,
            icon: Icons.sync_problem_outlined,
          ),
        ],
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            title: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing16,
              0,
              AppSpacing.spacing16,
              AppSpacing.spacing16,
            ),
            children: <Widget>[child],
          ),
        ),
      ),
    );
  }
}

class _BasicSection extends StatelessWidget {
  const _BasicSection({
    required this.state,
    required this.nameFocus,
    required this.skuFocus,
    required this.referenceFocus,
  });

  final ProductFormState state;
  final FocusNode nameFocus;
  final FocusNode skuFocus;
  final FocusNode referenceFocus;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    void emitBasic({
      String? name,
      String? sku,
      String? reference,
      String? brand,
    }) {
      bloc.add(
        ProductFormBasicSectionChanged(
          name: name ?? state.name,
          sku: sku ?? state.sku,
          reference: reference ?? state.reference,
          brand: brand ?? state.brand,
        ),
      );
    }

    return _FieldGrid(
      children: <Widget>[
        _SyncedAppTextField(
          value: state.name,
          label: 'Nome do produto',
          semanticLabel: 'Nome do produto',
          isRequired: true,
          isDisabled: state.isBusy,
          textInputAction: TextInputAction.next,
          errorText: state.fieldErrors['name'],
          focusNode: nameFocus,
          onChanged: (value) => emitBasic(name: value),
        ),
        _SyncedAppTextField(
          value: state.sku,
          label: 'SKU',
          hintText: 'Ex.: CAM-001',
          semanticLabel: 'SKU',
          isRequired: true,
          isDisabled: state.isBusy,
          textInputAction: TextInputAction.next,
          errorText: state.fieldErrors['sku'],
          focusNode: skuFocus,
          onChanged: (value) => emitBasic(sku: value),
        ),
        _SyncedAppTextField(
          value: state.reference,
          label: 'Referência',
          semanticLabel: 'Referência',
          isRequired: true,
          isDisabled: state.isBusy,
          textInputAction: TextInputAction.next,
          errorText: state.fieldErrors['reference'],
          focusNode: referenceFocus,
          onChanged: (value) => emitBasic(reference: value),
        ),
        _SyncedAppTextField(
          value: state.brand,
          label: 'Marca',
          semanticLabel: 'Marca',
          isDisabled: state.isBusy,
          textInputAction: TextInputAction.next,
          onChanged: (value) => emitBasic(brand: value),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    void emitCategory({
      String? categoryId,
      bool clearSubcategoryId = false,
      String? subcategoryId,
      String? collectionId,
      String? seasonId,
      String? line,
      ProductGender? gender,
      bool clearGender = false,
      TargetAudience? targetAudience,
      bool clearTargetAudience = false,
    }) {
      bloc.add(
        ProductFormCategorySectionChanged(
          categoryId: categoryId ?? state.categoryId,
          subcategoryId: clearSubcategoryId
              ? ''
              : subcategoryId ?? state.subcategoryId,
          collectionId: collectionId ?? state.collectionId,
          seasonId: seasonId ?? state.seasonId,
          line: line ?? state.line,
          gender: clearGender ? null : gender ?? state.gender,
          targetAudience: clearTargetAudience
              ? null
              : targetAudience ?? state.targetAudience,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FieldGrid(
          children: <Widget>[
            AppDropdown<String>(
              label: 'Categoria',
              hintText: 'Selecione uma categoria',
              semanticLabel: 'Categoria',
              closeSemanticLabel: 'Fechar seleção de categoria',
              isRequired: true,
              isDisabled: state.isBusy,
              options: state.rootCategories
                  .map(
                    (category) => AppDropdownOption<String>(
                      value: category.id,
                      label: category.name,
                    ),
                  )
                  .toList(growable: false),
              selectedValues: state.categoryId.isEmpty
                  ? const <String>{}
                  : <String>{state.categoryId},
              onChanged: (selected) => emitCategory(
                categoryId: selected.isEmpty ? '' : selected.first,
                clearSubcategoryId: true,
              ),
              searchHintText: 'Buscar categoria',
              noResultsLabel: 'Nenhuma categoria encontrada',
              errorText: state.fieldErrors['categoryId'],
            ),
            AppDropdown<String>(
              label: 'Subcategoria',
              hintText: state.categoryId.isEmpty
                  ? 'Selecione uma categoria primeiro'
                  : 'Selecione uma subcategoria',
              semanticLabel: 'Subcategoria',
              closeSemanticLabel: 'Fechar seleção de subcategoria',
              isDisabled: state.isBusy || state.categoryId.isEmpty,
              options: state.subcategoryOptions
                  .map(
                    (category) => AppDropdownOption<String>(
                      value: category.id,
                      label: category.name,
                    ),
                  )
                  .toList(growable: false),
              selectedValues: state.subcategoryId.isEmpty
                  ? const <String>{}
                  : <String>{state.subcategoryId},
              onChanged: (selected) => emitCategory(
                subcategoryId: selected.isEmpty ? '' : selected.first,
              ),
              searchHintText: 'Buscar subcategoria',
              noResultsLabel: 'Nenhuma subcategoria encontrada',
              errorText: state.fieldErrors['subcategoryId'],
            ),
            _SyncedAppTextField(
              value: state.collectionId,
              label: 'Coleção',
              semanticLabel: 'Coleção',
              isDisabled: state.isBusy,
              onChanged: (value) => emitCategory(collectionId: value),
            ),
            _SyncedAppTextField(
              value: state.seasonId,
              label: 'Estação',
              semanticLabel: 'Estação',
              isDisabled: state.isBusy,
              onChanged: (value) => emitCategory(seasonId: value),
            ),
            _SyncedAppTextField(
              value: state.line,
              label: 'Linha',
              semanticLabel: 'Linha',
              isDisabled: state.isBusy,
              onChanged: (value) => emitCategory(line: value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _FieldGrid(
          children: <Widget>[
            AppDropdown<ProductGender>(
              label: 'Gênero',
              hintText: 'Selecione o gênero',
              semanticLabel: 'Gênero',
              closeSemanticLabel: 'Fechar seleção de gênero',
              enableSearch: false,
              isDisabled: state.isBusy,
              options: const <AppDropdownOption<ProductGender>>[
                AppDropdownOption(
                  value: ProductGender.masculine,
                  label: 'Masculino',
                ),
                AppDropdownOption(
                  value: ProductGender.feminine,
                  label: 'Feminino',
                ),
                AppDropdownOption(
                  value: ProductGender.unisex,
                  label: 'Unissex',
                ),
              ],
              selectedValues: state.gender == null
                  ? const <ProductGender>{}
                  : <ProductGender>{state.gender!},
              onChanged: (selected) => emitCategory(
                gender: selected.isEmpty ? null : selected.first,
                clearGender: selected.isEmpty,
              ),
            ),
            AppDropdown<TargetAudience>(
              label: 'Público-alvo',
              hintText: 'Selecione o público',
              semanticLabel: 'Público-alvo',
              closeSemanticLabel: 'Fechar seleção de público-alvo',
              enableSearch: false,
              isDisabled: state.isBusy,
              options: const <AppDropdownOption<TargetAudience>>[
                AppDropdownOption(value: TargetAudience.adult, label: 'Adulto'),
                AppDropdownOption(value: TargetAudience.teen, label: 'Jovem'),
                AppDropdownOption(
                  value: TargetAudience.kids,
                  label: 'Infantil',
                ),
                AppDropdownOption(value: TargetAudience.baby, label: 'Bebê'),
              ],
              selectedValues: state.targetAudience == null
                  ? const <TargetAudience>{}
                  : <TargetAudience>{state.targetAudience!},
              onChanged: (selected) => emitCategory(
                targetAudience: selected.isEmpty ? null : selected.first,
                clearTargetAudience: selected.isEmpty,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    void emitContent({
      String? shortDescription,
      String? fullDescription,
      List<String>? tags,
    }) {
      bloc.add(
        ProductFormContentSectionChanged(
          shortDescription: shortDescription ?? state.shortDescription,
          fullDescription: fullDescription ?? state.fullDescription,
          tags: tags ?? state.tags,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SyncedAppTextField(
          value: state.shortDescription,
          label: 'Descrição curta',
          semanticLabel: 'Descrição curta',
          isDisabled: state.isBusy,
          onChanged: (value) => emitContent(shortDescription: value),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _SyncedAppTextField(
          value: state.fullDescription,
          label: 'Descrição completa',
          semanticLabel: 'Descrição completa',
          isDisabled: state.isBusy,
          maxLines: 4,
          onChanged: (value) => emitContent(fullDescription: value),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _SyncedAppTextField(
          value: state.tags.join(', '),
          label: 'Tags',
          hintText: 'Separe por vírgula',
          semanticLabel: 'Tags',
          helperText: 'Ex.: verão, algodão, básico',
          isDisabled: state.isBusy,
          onChanged: (value) => emitContent(
            tags: value
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _CharacteristicsSection extends StatelessWidget {
  const _CharacteristicsSection({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    void emitCharacteristics({
      String? fabric,
      String? composition,
      String? supplierId,
      String? ncm,
      String? ean,
    }) {
      bloc.add(
        ProductFormCharacteristicsSectionChanged(
          fabric: fabric ?? state.fabric,
          composition: composition ?? state.composition,
          supplierId: supplierId ?? state.supplierId,
          ncm: ncm ?? state.ncm,
          ean: ean ?? state.ean,
        ),
      );
    }

    return _FieldGrid(
      children: <Widget>[
        _SyncedAppTextField(
          value: state.fabric,
          label: 'Tecido',
          semanticLabel: 'Tecido',
          isDisabled: state.isBusy,
          onChanged: (value) => emitCharacteristics(fabric: value),
        ),
        _SyncedAppTextField(
          value: state.composition,
          label: 'Composição',
          semanticLabel: 'Composição',
          isDisabled: state.isBusy,
          onChanged: (value) => emitCharacteristics(composition: value),
        ),
        _SyncedAppTextField(
          value: state.supplierId,
          label: 'Fornecedor',
          semanticLabel: 'Fornecedor',
          isDisabled: state.isBusy,
          onChanged: (value) => emitCharacteristics(supplierId: value),
        ),
        _SyncedAppTextField(
          value: state.ncm,
          label: 'NCM',
          semanticLabel: 'NCM',
          isDisabled: state.isBusy,
          keyboardType: TextInputType.number,
          onChanged: (value) => emitCharacteristics(ncm: value),
        ),
        _SyncedAppTextField(
          value: state.ean,
          label: 'EAN',
          hintText: 'Código de barras (opcional)',
          semanticLabel: 'EAN',
          isDisabled: state.isBusy,
          keyboardType: TextInputType.number,
          errorText: state.fieldErrors['ean'],
          onChanged: (value) => emitCharacteristics(ean: value),
        ),
      ],
    );
  }
}

class _SeoSection extends StatelessWidget {
  const _SeoSection({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    void emitSeo({String? seoTitle, String? seoDescription, String? seoSlug}) {
      bloc.add(
        ProductFormSeoSectionChanged(
          seoTitle: seoTitle ?? state.seoTitle,
          seoDescription: seoDescription ?? state.seoDescription,
          seoSlug: seoSlug ?? state.seoSlug,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Usado apenas quando este produto aparece em um catálogo '
          'compartilhável/white-label.',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _SyncedAppTextField(
          value: state.seoTitle,
          label: 'Título SEO',
          semanticLabel: 'Título SEO',
          isDisabled: state.isBusy,
          onChanged: (value) => emitSeo(seoTitle: value),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _SyncedAppTextField(
          value: state.seoDescription,
          label: 'Descrição SEO',
          semanticLabel: 'Descrição SEO',
          isDisabled: state.isBusy,
          maxLines: 3,
          onChanged: (value) => emitSeo(seoDescription: value),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _SyncedAppTextField(
          value: state.seoSlug,
          label: 'Slug',
          hintText: 'nome-do-produto',
          semanticLabel: 'Slug',
          isDisabled: state.isBusy,
          onChanged: (value) => emitSeo(seoSlug: value),
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    final label = state.launchDate == null
        ? 'Sem data definida'
        : _formatDate(state.launchDate!);

    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Data de lançamento: $label',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: state.isBusy,
            onPressed: state.isBusy
                ? null
                : () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.launchDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) {
                      bloc.add(ProductFormScheduleSectionChanged(picked));
                    }
                  },
          ),
        ),
        if (state.launchDate != null)
          AppIconButton(
            icon: Icons.close,
            semanticLabel: 'Remover data de lançamento',
            isDisabled: state.isBusy,
            onPressed: state.isBusy
                ? null
                : () => bloc.add(const ProductFormScheduleSectionChanged(null)),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ProductFormActions extends StatelessWidget {
  const _ProductFormActions({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        final buttons = <Widget>[
          AppButton(
            label: 'Salvar rascunho',
            leadingIcon: Icons.bookmark_border,
            variant: AppButtonVariant.secondary,
            isLoading: state.isDraftSaving,
            isDisabled: state.isBusy,
            expand: isNarrow,
            onPressed: state.isBusy
                ? null
                : () => bloc.add(const ProductFormDraftSaved()),
          ),
          AppButton(
            label: state.isEditing ? 'Salvar alterações' : 'Salvar produto',
            leadingIcon: Icons.save_outlined,
            isLoading: state.isSubmitting,
            isDisabled: state.isBusy,
            expand: isNarrow,
            onPressed: state.isBusy
                ? null
                : () => bloc.add(const ProductFormSubmitted()),
          ),
          if (state.canRequestPublish)
            AppButton(
              label: 'Publicar produto',
              leadingIcon: Icons.public,
              variant: AppButtonVariant.primary,
              isLoading: state.isPublishing,
              isDisabled: state.isBusy,
              expand: isNarrow,
              onPressed: state.isBusy
                  ? null
                  : () => bloc.add(const ProductFormPublishRequested()),
            ),
        ];

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final button in buttons) ...<Widget>[
                button,
                const SizedBox(height: AppSpacing.spacing12),
              ],
            ],
          );
        }

        return Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.spacing12,
          runSpacing: AppSpacing.spacing12,
          children: buttons,
        );
      },
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
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
          runSpacing: AppSpacing.spacing12,
          spacing: AppSpacing.spacing12,
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

class _SyncedAppTextField extends StatefulWidget {
  const _SyncedAppTextField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.hintText,
    this.helperText,
    this.semanticLabel,
    this.errorText,
    this.isRequired = false,
    this.isDisabled = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
  });

  final String value;
  final String label;
  final String? hintText;
  final String? helperText;
  final String? semanticLabel;
  final String? errorText;
  final bool isRequired;
  final bool isDisabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<_SyncedAppTextField> createState() => _SyncedAppTextFieldState();
}

class _SyncedAppTextFieldState extends State<_SyncedAppTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SyncedAppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
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
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      semanticLabel: widget.semanticLabel,
      errorText: widget.errorText,
      isRequired: widget.isRequired,
      isDisabled: widget.isDisabled,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
    );
  }
}
