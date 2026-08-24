import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_form_draft.dart';
import '../../domain/usecases/clear_product_form_draft_use_case.dart';
import '../../domain/usecases/create_product_use_case.dart';
import '../../domain/usecases/get_product_form_draft_use_case.dart';
import '../../domain/usecases/publish_product_use_case.dart';
import '../../domain/usecases/save_product_form_draft_use_case.dart';
import '../../domain/usecases/update_product_use_case.dart';
import 'product_form_event.dart';
import 'product_form_state.dart';

/// Drives `ProductFormPage` (TASK-065): one BLoC with events grouped by
/// section (Básico, Categoria, Conteúdo, Características, SEO,
/// Agendamento), never a single monolithic event for the whole form.
///
/// Never computes completeness or RBAC itself — [ProductFormSubmitted] only
/// ever creates/updates a [ProductStatus.draft]-compatible payload, and
/// [ProductFormPublishRequested] only ever calls [publishProduct], which
/// centralizes the publish rule; this BLoC just relays whichever
/// [ValidationFailure.fieldErrors] that use case returns straight into
/// [ProductFormState.fieldErrors].
@injectable
final class ProductFormBloc extends Bloc<ProductFormEvent, ProductFormState> {
  ProductFormBloc({
    required this.getDraft,
    required this.saveDraft,
    required this.clearDraft,
    required this.createProduct,
    required this.updateProduct,
    required this.publishProduct,
    required this.analyticsService,
  }) : super(const ProductFormState()) {
    on<ProductFormStarted>(_onStarted, transformer: restartable());
    on<ProductFormBasicSectionChanged>(
      _onBasicSectionChanged,
      transformer: sequential(),
    );
    on<ProductFormCategorySectionChanged>(
      _onCategorySectionChanged,
      transformer: sequential(),
    );
    on<ProductFormContentSectionChanged>(
      _onContentSectionChanged,
      transformer: sequential(),
    );
    on<ProductFormCharacteristicsSectionChanged>(
      _onCharacteristicsSectionChanged,
      transformer: sequential(),
    );
    on<ProductFormSeoSectionChanged>(
      _onSeoSectionChanged,
      transformer: sequential(),
    );
    on<ProductFormScheduleSectionChanged>(
      _onScheduleSectionChanged,
      transformer: sequential(),
    );
    on<ProductFormDraftSaved>(_onDraftSaved, transformer: droppable());
    on<ProductFormSubmitted>(_onSubmitted, transformer: droppable());
    on<ProductFormPublishRequested>(
      _onPublishRequested,
      transformer: droppable(),
    );
  }

  final GetProductFormDraftUseCase getDraft;
  final SaveProductFormDraftUseCase saveDraft;
  final ClearProductFormDraftUseCase clearDraft;
  final CreateProductUseCase createProduct;
  final UpdateProductUseCase updateProduct;
  final PublishProductUseCase publishProduct;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    ProductFormStarted event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(
      const ProductFormState().copyWith(
        loadStatus: ProductFormLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        actorName: event.actorName,
        canPublish: event.canPublish,
      ),
    );

    final initial = event.initialProduct;
    if (initial != null) {
      emit(_readyStateFrom(product: initial));
      return;
    }

    final draftResult = await getDraft(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (emit.isDone) return;
    final draft = draftResult.fold(
      onSuccess: (value) =>
          value?.companyId == event.companyId && value?.productId == null
          ? value
          : null,
      onFailure: (_) => null,
    );

    emit(
      state.copyWith(
        loadStatus: ProductFormLoadStatus.ready,
        name: draft?.name ?? '',
        sku: draft?.sku ?? '',
        reference: draft?.reference ?? '',
        brand: draft?.brand ?? '',
        categoryId: draft?.categoryId ?? '',
        subcategoryId: draft?.subcategoryId ?? '',
        collectionId: draft?.collectionId ?? '',
        seasonId: draft?.seasonId ?? '',
        line: draft?.line ?? '',
        shortDescription: draft?.shortDescription ?? '',
        fullDescription: draft?.fullDescription ?? '',
        tags: draft?.tags ?? const <String>[],
        fabric: draft?.fabric ?? '',
        composition: draft?.composition ?? '',
        supplierId: draft?.supplierId ?? '',
        ncm: draft?.ncm ?? '',
        ean: draft?.ean ?? '',
        seoTitle: draft?.seoTitle ?? '',
        seoDescription: draft?.seoDescription ?? '',
        seoSlug: draft?.seoSlug ?? '',
        launchDate: draft?.launchDate,
        hasRestoredDraft: draft != null,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onBasicSectionChanged(
    ProductFormBasicSectionChanged event,
    Emitter<ProductFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('name')
      ..remove('sku')
      ..remove('reference');
    emit(
      _resetTransientStatus(
        state.copyWith(
          name: event.name,
          sku: event.sku,
          reference: event.reference,
          brand: event.brand,
          fieldErrors: fieldErrors,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onCategorySectionChanged(
    ProductFormCategorySectionChanged event,
    Emitter<ProductFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('categoryId');
    emit(
      _resetTransientStatus(
        state.copyWith(
          categoryId: event.categoryId,
          subcategoryId: event.subcategoryId,
          collectionId: event.collectionId,
          seasonId: event.seasonId,
          line: event.line,
          gender: event.gender,
          clearGender: event.gender == null,
          targetAudience: event.targetAudience,
          clearTargetAudience: event.targetAudience == null,
          fieldErrors: fieldErrors,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onContentSectionChanged(
    ProductFormContentSectionChanged event,
    Emitter<ProductFormState> emit,
  ) {
    emit(
      _resetTransientStatus(
        state.copyWith(
          shortDescription: event.shortDescription,
          fullDescription: event.fullDescription,
          tags: event.tags,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onCharacteristicsSectionChanged(
    ProductFormCharacteristicsSectionChanged event,
    Emitter<ProductFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('ean');
    emit(
      _resetTransientStatus(
        state.copyWith(
          fabric: event.fabric,
          composition: event.composition,
          supplierId: event.supplierId,
          ncm: event.ncm,
          ean: event.ean,
          fieldErrors: fieldErrors,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onSeoSectionChanged(
    ProductFormSeoSectionChanged event,
    Emitter<ProductFormState> emit,
  ) {
    emit(
      _resetTransientStatus(
        state.copyWith(
          seoTitle: event.seoTitle,
          seoDescription: event.seoDescription,
          seoSlug: event.seoSlug,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onScheduleSectionChanged(
    ProductFormScheduleSectionChanged event,
    Emitter<ProductFormState> emit,
  ) {
    emit(
      _resetTransientStatus(
        state.copyWith(
          launchDate: event.launchDate,
          clearLaunchDate: event.launchDate == null,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onDraftSaved(
    ProductFormDraftSaved event,
    Emitter<ProductFormState> emit,
  ) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        draftStatus: ProductFormDraftStatus.saving,
        clearFailure: true,
      ),
    );

    final result = await saveDraft(_draftFromState());
    if (emit.isDone) return;
    result.fold(
      onSuccess: (_) => emit(
        state.copyWith(
          draftStatus: ProductFormDraftStatus.saved,
          clearFailure: true,
        ),
      ),
      onFailure: (failure) => emit(
        state.copyWith(
          draftStatus: ProductFormDraftStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> _onSubmitted(
    ProductFormSubmitted event,
    Emitter<ProductFormState> emit,
  ) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        submissionStatus: ProductFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );

    final wasNew = state.currentProduct == null;
    final result = state.currentProduct == null
        ? await createProduct(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            companyId: state.companyId,
            sku: state.sku,
            reference: state.reference,
            name: state.name,
            shortDescription: state.shortDescription,
            fullDescription: state.fullDescription,
            brand: state.brand,
            collectionId: state.collectionId,
            seasonId: state.seasonId,
            line: state.line,
            categoryId: state.categoryId,
            subcategoryId: state.subcategoryId,
            gender: state.gender,
            targetAudience: state.targetAudience,
            fabric: state.fabric,
            composition: state.composition,
            supplierId: state.supplierId,
            ncm: state.ncm,
            ean: state.ean,
            tags: state.tags,
            launchDate: state.launchDate,
            seoTitle: state.seoTitle,
            seoDescription: state.seoDescription,
            seoSlug: state.seoSlug,
            createdBy: state.userId,
          )
        : await updateProduct(
            organizationId: state.organizationId,
            id: state.currentProduct!.id,
            sku: state.sku,
            reference: state.reference,
            name: state.name,
            shortDescription: state.shortDescription,
            fullDescription: state.fullDescription,
            brand: state.brand,
            collectionId: state.collectionId,
            seasonId: state.seasonId,
            line: state.line,
            categoryId: state.categoryId,
            subcategoryId: state.subcategoryId,
            gender: state.gender,
            targetAudience: state.targetAudience,
            fabric: state.fabric,
            composition: state.composition,
            supplierId: state.supplierId,
            ncm: state.ncm,
            ean: state.ean,
            tags: state.tags,
            launchDate: state.launchDate,
            seoTitle: state.seoTitle,
            seoDescription: state.seoDescription,
            seoSlug: state.seoSlug,
            updatedBy: state.userId,
            actorName: state.actorName,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Product>(value: final product):
        if (wasNew) {
          await clearDraft(
            organizationId: state.organizationId,
            userId: state.userId,
          );
        }
        if (emit.isDone) return;
        await analyticsService.logEvent(
          wasNew
              ? AnalyticsEvents.productCreated
              : AnalyticsEvents.productUpdated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'product_id': product.id,
            'sync_status': product.syncStatus.name,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            submissionStatus: ProductFormSubmissionStatus.success,
            draftStatus: ProductFormDraftStatus.idle,
            currentProduct: product,
            hasRestoredDraft: false,
            clearFailure: true,
          ),
        );
      case AppFailure<Product>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: ProductFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: _fieldErrorsFromFailure(failure),
          ),
        );
    }
  }

  Future<void> _onPublishRequested(
    ProductFormPublishRequested event,
    Emitter<ProductFormState> emit,
  ) async {
    if (state.isBusy) return;

    final current = state.currentProduct;
    if (current == null) {
      emit(
        state.copyWith(
          publishStatus: ProductFormPublishStatus.failure,
          failure: const ValidationFailure(
            'Save the product before publishing it.',
            code: 'product_not_saved_yet',
          ),
        ),
      );
      return;
    }
    if (!state.canPublish) {
      emit(
        state.copyWith(
          publishStatus: ProductFormPublishStatus.failure,
          failure: const PermissionFailure(
            'You are not allowed to publish this product.',
            code: 'product_publish_not_allowed',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        publishStatus: ProductFormPublishStatus.publishing,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );

    final result = await publishProduct(
      organizationId: state.organizationId,
      id: current.id,
      publishedBy: state.userId,
      actorName: state.actorName,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Product>(value: final product):
        await analyticsService.logEvent(
          AnalyticsEvents.productPublished,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'product_id': product.id,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            publishStatus: ProductFormPublishStatus.success,
            currentProduct: product,
            clearFailure: true,
          ),
        );
      case AppFailure<Product>(failure: final failure):
        emit(
          state.copyWith(
            publishStatus: ProductFormPublishStatus.failure,
            failure: failure,
            fieldErrors: _fieldErrorsFromFailure(failure),
          ),
        );
    }
  }

  ProductFormState _readyStateFrom({required Product product}) {
    return state.copyWith(
      loadStatus: ProductFormLoadStatus.ready,
      currentProduct: product,
      name: product.name,
      sku: product.sku.value,
      reference: product.reference,
      brand: product.brand ?? '',
      categoryId: product.categoryId ?? '',
      subcategoryId: product.subcategoryId ?? '',
      collectionId: product.collectionId ?? '',
      seasonId: product.seasonId ?? '',
      line: product.line ?? '',
      gender: product.gender,
      clearGender: product.gender == null,
      targetAudience: product.targetAudience,
      clearTargetAudience: product.targetAudience == null,
      shortDescription: product.shortDescription ?? '',
      fullDescription: product.fullDescription ?? '',
      tags: product.tags,
      fabric: product.fabric ?? '',
      composition: product.composition ?? '',
      supplierId: product.supplierId ?? '',
      ncm: product.ncm ?? '',
      ean: product.ean?.digits ?? '',
      seoTitle: product.seoTitle ?? '',
      seoDescription: product.seoDescription ?? '',
      seoSlug: product.seoSlug ?? '',
      launchDate: product.launchDate,
      clearLaunchDate: product.launchDate == null,
      clearFieldErrors: true,
      clearFailure: true,
    );
  }

  ProductFormState _resetTransientStatus(ProductFormState next) {
    return next.copyWith(
      submissionStatus: ProductFormSubmissionStatus.idle,
      draftStatus: ProductFormDraftStatus.idle,
      publishStatus: ProductFormPublishStatus.idle,
    );
  }

  ProductFormDraft _draftFromState() {
    return ProductFormDraft(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      productId: state.currentProduct?.id,
      name: _blankToNull(state.name),
      sku: _blankToNull(state.sku),
      reference: _blankToNull(state.reference),
      brand: _blankToNull(state.brand),
      categoryId: _blankToNull(state.categoryId),
      subcategoryId: _blankToNull(state.subcategoryId),
      collectionId: _blankToNull(state.collectionId),
      seasonId: _blankToNull(state.seasonId),
      line: _blankToNull(state.line),
      gender: state.gender?.name,
      targetAudience: state.targetAudience?.name,
      shortDescription: _blankToNull(state.shortDescription),
      fullDescription: _blankToNull(state.fullDescription),
      tags: state.tags,
      fabric: _blankToNull(state.fabric),
      composition: _blankToNull(state.composition),
      supplierId: _blankToNull(state.supplierId),
      ncm: _blankToNull(state.ncm),
      ean: _blankToNull(state.ean),
      seoTitle: _blankToNull(state.seoTitle),
      seoDescription: _blankToNull(state.seoDescription),
      seoSlug: _blankToNull(state.seoSlug),
      launchDate: state.launchDate,
      savedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, String> _fieldErrorsFromFailure(Failure failure) {
    if (failure is ConflictFailure &&
        failure.code == 'product_sku_already_exists') {
      return const <String, String>{
        'sku': 'Já existe um produto com este SKU.',
      };
    }
    if (failure is ValidationFailure) {
      return failure.fieldErrors.isEmpty
          ? const <String, String>{}
          : Map<String, String>.of(failure.fieldErrors);
    }
    return const <String, String>{};
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
