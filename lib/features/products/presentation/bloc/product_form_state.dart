import '../../../../core/errors/errors.dart';
import '../../domain/entities/product.dart';
import '../../domain/value_objects/product_gender.dart';
import '../../domain/value_objects/product_status.dart';
import '../../domain/value_objects/product_sync_status.dart';
import '../../domain/value_objects/target_audience.dart';

enum ProductFormLoadStatus { loading, ready, failure }

enum ProductFormSubmissionStatus { idle, submitting, success, failure }

enum ProductFormDraftStatus { idle, saving, saved, failure }

enum ProductFormPublishStatus { idle, publishing, success, failure }

final class ProductFormState {
  const ProductFormState({
    this.loadStatus = ProductFormLoadStatus.loading,
    this.submissionStatus = ProductFormSubmissionStatus.idle,
    this.draftStatus = ProductFormDraftStatus.idle,
    this.publishStatus = ProductFormPublishStatus.idle,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.actorName = '',
    this.canPublish = false,
    this.currentProduct,
    this.name = '',
    this.sku = '',
    this.reference = '',
    this.brand = '',
    this.categoryId = '',
    this.subcategoryId = '',
    this.collectionId = '',
    this.seasonId = '',
    this.line = '',
    this.gender,
    this.targetAudience,
    this.shortDescription = '',
    this.fullDescription = '',
    this.tags = const <String>[],
    this.fabric = '',
    this.composition = '',
    this.supplierId = '',
    this.ncm = '',
    this.ean = '',
    this.seoTitle = '',
    this.seoDescription = '',
    this.seoSlug = '',
    this.launchDate,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.hasRestoredDraft = false,
  });

  final ProductFormLoadStatus loadStatus;
  final ProductFormSubmissionStatus submissionStatus;
  final ProductFormDraftStatus draftStatus;
  final ProductFormPublishStatus publishStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final bool canPublish;

  /// The already-persisted Product this form edits, once it exists: either
  /// the one it was opened with, or the one `CreateProductUseCase` just
  /// returned. `null` only while drafting a brand-new product that has
  /// never been saved yet.
  final Product? currentProduct;

  final String name;
  final String sku;
  final String reference;
  final String brand;
  final String categoryId;
  final String subcategoryId;
  final String collectionId;
  final String seasonId;
  final String line;
  final ProductGender? gender;
  final TargetAudience? targetAudience;
  final String shortDescription;
  final String fullDescription;
  final List<String> tags;
  final String fabric;
  final String composition;
  final String supplierId;
  final String ncm;
  final String ean;
  final String seoTitle;
  final String seoDescription;
  final String seoSlug;
  final DateTime? launchDate;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final bool hasRestoredDraft;

  bool get isEditing => currentProduct != null;
  bool get isSubmitting =>
      submissionStatus == ProductFormSubmissionStatus.submitting;
  bool get isDraftSaving => draftStatus == ProductFormDraftStatus.saving;
  bool get isPublishing => publishStatus == ProductFormPublishStatus.publishing;
  bool get isBusy => isSubmitting || isDraftSaving || isPublishing;
  bool get wasSavedOffline =>
      currentProduct?.syncStatus == ProductSyncStatus.pending;

  /// Only a saved draft product can be published, and only while it has
  /// never left [ProductStatus.draft].
  bool get canRequestPublish =>
      canPublish && currentProduct?.status == ProductStatus.draft;

  ProductFormState copyWith({
    ProductFormLoadStatus? loadStatus,
    ProductFormSubmissionStatus? submissionStatus,
    ProductFormDraftStatus? draftStatus,
    ProductFormPublishStatus? publishStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    String? actorName,
    bool? canPublish,
    Product? currentProduct,
    String? name,
    String? sku,
    String? reference,
    String? brand,
    String? categoryId,
    String? subcategoryId,
    String? collectionId,
    String? seasonId,
    String? line,
    ProductGender? gender,
    TargetAudience? targetAudience,
    String? shortDescription,
    String? fullDescription,
    List<String>? tags,
    String? fabric,
    String? composition,
    String? supplierId,
    String? ncm,
    String? ean,
    String? seoTitle,
    String? seoDescription,
    String? seoSlug,
    DateTime? launchDate,
    Map<String, String>? fieldErrors,
    Failure? failure,
    bool? hasRestoredDraft,
    bool clearGender = false,
    bool clearTargetAudience = false,
    bool clearLaunchDate = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
  }) {
    return ProductFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      draftStatus: draftStatus ?? this.draftStatus,
      publishStatus: publishStatus ?? this.publishStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      canPublish: canPublish ?? this.canPublish,
      currentProduct: currentProduct ?? this.currentProduct,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      reference: reference ?? this.reference,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      collectionId: collectionId ?? this.collectionId,
      seasonId: seasonId ?? this.seasonId,
      line: line ?? this.line,
      gender: clearGender ? null : gender ?? this.gender,
      targetAudience: clearTargetAudience
          ? null
          : targetAudience ?? this.targetAudience,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      tags: tags ?? this.tags,
      fabric: fabric ?? this.fabric,
      composition: composition ?? this.composition,
      supplierId: supplierId ?? this.supplierId,
      ncm: ncm ?? this.ncm,
      ean: ean ?? this.ean,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      seoSlug: seoSlug ?? this.seoSlug,
      launchDate: clearLaunchDate ? null : launchDate ?? this.launchDate,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      hasRestoredDraft: hasRestoredDraft ?? this.hasRestoredDraft,
    );
  }
}
