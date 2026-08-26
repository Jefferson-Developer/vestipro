import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/storage/storage.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../../domain/usecases/create_campaign_use_case.dart';
import '../../domain/usecases/list_campaign_related_products_use_case.dart';
import '../../domain/usecases/update_campaign_use_case.dart';
import 'campaign_form_event.dart';
import 'campaign_form_state.dart';

/// Drives `CampaignFormPage` (TASK-080): create/edit a `CatalogCampaign`,
/// including cover/editorial image upload (same compression pipeline
/// TASK-068 already established for product media) and the curated
/// related-products list.
@injectable
final class CampaignFormBloc
    extends Bloc<CampaignFormEvent, CampaignFormState> {
  CampaignFormBloc({
    required this.storage,
    required this.createCampaign,
    required this.updateCampaign,
    required this.listRelatedProducts,
    this.compressor = const ImageUploadCompressor(),
  }) : super(const CampaignFormState()) {
    on<CampaignFormStarted>(_onStarted, transformer: restartable());
    on<CampaignFormTitleChanged>(_onTitleChanged, transformer: sequential());
    on<CampaignFormSubtitleChanged>(
      _onSubtitleChanged,
      transformer: sequential(),
    );
    on<CampaignFormDescriptionChanged>(
      _onDescriptionChanged,
      transformer: sequential(),
    );
    on<CampaignFormStartAtChanged>(
      _onStartAtChanged,
      transformer: sequential(),
    );
    on<CampaignFormEndAtChanged>(_onEndAtChanged, transformer: sequential());
    on<CampaignFormActiveChanged>(_onActiveChanged, transformer: sequential());
    on<CampaignFormCoverImagePicked>(
      _onCoverImagePicked,
      transformer: sequential(),
    );
    on<CampaignFormCoverImageRemoved>(
      _onCoverImageRemoved,
      transformer: sequential(),
    );
    on<CampaignFormEditorialImagePicked>(
      _onEditorialImagePicked,
      transformer: sequential(),
    );
    on<CampaignFormEditorialImagesReordered>(
      _onEditorialImagesReordered,
      transformer: sequential(),
    );
    on<CampaignFormEditorialImageRemoved>(
      _onEditorialImageRemoved,
      transformer: sequential(),
    );
    on<CampaignFormRelatedProductAdded>(
      _onRelatedProductAdded,
      transformer: sequential(),
    );
    on<CampaignFormRelatedProductRemoved>(
      _onRelatedProductRemoved,
      transformer: sequential(),
    );
    on<CampaignFormSubmitted>(_onSubmitted, transformer: sequential());
  }

  final StorageDataSource storage;
  final CreateCampaignUseCase createCampaign;
  final UpdateCampaignUseCase updateCampaign;
  final ListCampaignRelatedProductsUseCase listRelatedProducts;
  final ImageUploadCompressor compressor;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    CampaignFormStarted event,
    Emitter<CampaignFormState> emit,
  ) async {
    final initial = event.initialCampaign;
    emit(
      CampaignFormState(
        loadStatus: CampaignFormLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        campaignId: initial?.id ?? _uuid.v4(),
        initialCampaign: initial,
        title: initial?.title ?? '',
        subtitle: initial?.subtitle ?? '',
        description: initial?.description ?? '',
        startAt: initial?.startAt,
        endAt: initial?.endAt,
        active: initial?.active ?? true,
        coverImageUrl: initial?.imageUrl,
        editorialImageUrls: initial?.editorialImageUrls ?? const <String>[],
      ),
    );

    final relatedIds = initial?.relatedProductIds ?? const <String>[];
    if (relatedIds.isEmpty) {
      emit(state.copyWith(loadStatus: CampaignFormLoadStatus.ready));
      return;
    }

    final result = await listRelatedProducts(
      organizationId: event.organizationId,
      productIds: relatedIds,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<Product>>(value: final products):
        emit(
          state.copyWith(
            loadStatus: CampaignFormLoadStatus.ready,
            relatedProducts: products,
          ),
        );
      case AppFailure<List<Product>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CampaignFormLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onTitleChanged(
    CampaignFormTitleChanged event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(
      state.copyWith(
        title: event.title,
        submissionStatus: CampaignFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onSubtitleChanged(
    CampaignFormSubtitleChanged event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(state.copyWith(subtitle: event.subtitle));
  }

  void _onDescriptionChanged(
    CampaignFormDescriptionChanged event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onStartAtChanged(
    CampaignFormStartAtChanged event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(
      state.copyWith(
        startAt: event.startAt,
        clearStartAt: event.startAt == null,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onEndAtChanged(
    CampaignFormEndAtChanged event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(
      state.copyWith(
        endAt: event.endAt,
        clearEndAt: event.endAt == null,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onActiveChanged(
    CampaignFormActiveChanged event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(state.copyWith(active: event.active));
  }

  Future<void> _onCoverImagePicked(
    CampaignFormCoverImagePicked event,
    Emitter<CampaignFormState> emit,
  ) async {
    emit(state.copyWith(isUploadingCover: true, clearFailure: true));
    try {
      final previousUrl = state.coverImageUrl;
      final compressed = await compressor.compressForUpload(event.bytes);
      final fileName = '${_uuid.v4()}.jpg';
      final url = await storage.uploadFile(
        path: _campaignFilePath(fileName),
        bytes: compressed,
        contentType: 'image/jpeg',
      );
      if (emit.isDone) return;
      emit(state.copyWith(coverImageUrl: url, isUploadingCover: false));
      if (previousUrl != null) {
        // Best-effort: the source of truth (`coverImageUrl`) is already
        // updated, so a failed cleanup only leaves an orphaned Storage
        // object behind — never a dangling reference (same rationale
        // `ProductMediaBloc._onRemoved` already documents).
        unawaited(storage.deleteFile(path: previousUrl));
      }
    } catch (exception) {
      _handleUploadException(emit, exception: exception, isCover: true);
    }
  }

  void _onCoverImageRemoved(
    CampaignFormCoverImageRemoved event,
    Emitter<CampaignFormState> emit,
  ) {
    final previousUrl = state.coverImageUrl;
    emit(state.copyWith(clearCoverImageUrl: true));
    if (previousUrl != null) {
      unawaited(storage.deleteFile(path: previousUrl));
    }
  }

  Future<void> _onEditorialImagePicked(
    CampaignFormEditorialImagePicked event,
    Emitter<CampaignFormState> emit,
  ) async {
    emit(
      state.copyWith(
        uploadingEditorialCount: state.uploadingEditorialCount + 1,
        clearFailure: true,
      ),
    );
    try {
      final compressed = await compressor.compressForUpload(event.bytes);
      final fileName = '${_uuid.v4()}.jpg';
      final url = await storage.uploadFile(
        path: _campaignFilePath(fileName),
        bytes: compressed,
        contentType: 'image/jpeg',
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          editorialImageUrls: <String>[...state.editorialImageUrls, url],
          uploadingEditorialCount: state.uploadingEditorialCount - 1,
        ),
      );
    } catch (exception) {
      _handleUploadException(emit, exception: exception, isCover: false);
    }
  }

  void _onEditorialImagesReordered(
    CampaignFormEditorialImagesReordered event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(state.copyWith(editorialImageUrls: event.orderedUrls));
  }

  void _onEditorialImageRemoved(
    CampaignFormEditorialImageRemoved event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(
      state.copyWith(
        editorialImageUrls: state.editorialImageUrls
            .where((url) => url != event.url)
            .toList(growable: false),
      ),
    );
    unawaited(storage.deleteFile(path: event.url));
  }

  void _onRelatedProductAdded(
    CampaignFormRelatedProductAdded event,
    Emitter<CampaignFormState> emit,
  ) {
    if (state.relatedProducts.any(
      (product) => product.id == event.product.id,
    )) {
      return;
    }
    emit(
      state.copyWith(
        relatedProducts: <Product>[...state.relatedProducts, event.product],
      ),
    );
  }

  void _onRelatedProductRemoved(
    CampaignFormRelatedProductRemoved event,
    Emitter<CampaignFormState> emit,
  ) {
    emit(
      state.copyWith(
        relatedProducts: state.relatedProducts
            .where((product) => product.id != event.productId)
            .toList(growable: false),
      ),
    );
  }

  Future<void> _onSubmitted(
    CampaignFormSubmitted event,
    Emitter<CampaignFormState> emit,
  ) async {
    if (state.title.trim().isEmpty) {
      emit(
        state.copyWith(
          submissionStatus: CampaignFormSubmissionStatus.failure,
          fieldErrors: const <String, String>{
            'title': 'Informe o título da campanha.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: CampaignFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedCampaign: true,
      ),
    );

    final result = state.isEditing
        ? await updateCampaign(
            organizationId: state.organizationId,
            id: state.campaignId,
            title: state.title,
            subtitle: state.subtitle,
            description: state.description,
            imageUrl: state.coverImageUrl,
            editorialImageUrls: state.editorialImageUrls,
            relatedProductIds: state.relatedProductIds,
            active: state.active,
            startAt: state.startAt,
            endAt: state.endAt,
            updatedBy: state.userId,
          )
        : await createCampaign(
            id: state.campaignId,
            organizationId: state.organizationId,
            title: state.title,
            subtitle: state.subtitle,
            description: state.description,
            imageUrl: state.coverImageUrl,
            editorialImageUrls: state.editorialImageUrls,
            relatedProductIds: state.relatedProductIds,
            active: state.active,
            startAt: state.startAt,
            endAt: state.endAt,
            createdBy: state.userId,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<CatalogCampaign>(value: final campaign):
        emit(
          state.copyWith(
            submissionStatus: CampaignFormSubmissionStatus.success,
            savedCampaign: campaign,
            clearFailure: true,
          ),
        );
      case AppFailure<CatalogCampaign>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: CampaignFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }

  void _handleUploadException(
    Emitter<CampaignFormState> emit, {
    required Object exception,
    required bool isCover,
  }) {
    if (emit.isDone) return;
    emit(
      state.copyWith(
        isUploadingCover: isCover ? false : state.isUploadingCover,
        uploadingEditorialCount: isCover
            ? state.uploadingEditorialCount
            : (state.uploadingEditorialCount - 1).clamp(0, 1 << 30),
        submissionStatus: CampaignFormSubmissionStatus.failure,
        failure: exception is AppException
            ? mapAppExceptionToFailure(exception)
            : UnexpectedFailure(
                'Não foi possível enviar a imagem.',
                code: 'campaign_media_upload_unexpected',
                cause: exception,
              ),
      ),
    );
  }

  String _campaignFilePath(String fileName) {
    return StoragePaths.campaignFile(
      organizationId: state.organizationId,
      campaignId: state.campaignId,
      fileName: fileName,
    );
  }
}
