import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/catalog_campaign.dart';

enum CampaignFormLoadStatus { loading, ready, failure }

enum CampaignFormSubmissionStatus { idle, submitting, success, failure }

/// State for `CampaignFormBloc` (TASK-080)'s create/edit form.
///
/// [campaignId] is generated once, up front (`_onStarted`), even for a
/// brand-new campaign that has not been persisted yet: unlike
/// `ProductFormPage` (which only unlocks its media section once the
/// product already exists), the campaign form is a single page where
/// cover/editorial images can be uploaded before the first save — a stable id is
/// needed immediately so `StoragePaths.campaignFile` has somewhere to write
/// to, and `CampaignFormSubmitted` later creates the document under this
/// exact same id.
final class CampaignFormState {
  const CampaignFormState({
    this.loadStatus = CampaignFormLoadStatus.loading,
    this.organizationId = '',
    this.userId = '',
    this.campaignId = '',
    this.initialCampaign,
    this.title = '',
    this.subtitle = '',
    this.description = '',
    this.startAt,
    this.endAt,
    this.active = true,
    this.coverImageUrl,
    this.editorialImageUrls = const <String>[],
    this.relatedProducts = const <Product>[],
    this.isUploadingCover = false,
    this.uploadingEditorialCount = 0,
    this.submissionStatus = CampaignFormSubmissionStatus.idle,
    this.savedCampaign,
    this.failure,
    this.fieldErrors = const <String, String>{},
  });

  final CampaignFormLoadStatus loadStatus;
  final String organizationId;
  final String userId;
  final String campaignId;
  final CatalogCampaign? initialCampaign;
  final String title;
  final String subtitle;
  final String description;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool active;
  final String? coverImageUrl;
  final List<String> editorialImageUrls;
  final List<Product> relatedProducts;
  final bool isUploadingCover;
  final int uploadingEditorialCount;
  final CampaignFormSubmissionStatus submissionStatus;
  final CatalogCampaign? savedCampaign;
  final Failure? failure;
  final Map<String, String> fieldErrors;

  bool get isEditing => initialCampaign != null;
  bool get isSubmitting =>
      submissionStatus == CampaignFormSubmissionStatus.submitting;
  List<String> get relatedProductIds =>
      relatedProducts.map((product) => product.id).toList(growable: false);

  CampaignFormState copyWith({
    CampaignFormLoadStatus? loadStatus,
    String? organizationId,
    String? userId,
    String? campaignId,
    CatalogCampaign? initialCampaign,
    String? title,
    String? subtitle,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? active,
    String? coverImageUrl,
    List<String>? editorialImageUrls,
    List<Product>? relatedProducts,
    bool? isUploadingCover,
    int? uploadingEditorialCount,
    CampaignFormSubmissionStatus? submissionStatus,
    CatalogCampaign? savedCampaign,
    Failure? failure,
    Map<String, String>? fieldErrors,
    bool clearStartAt = false,
    bool clearEndAt = false,
    bool clearCoverImageUrl = false,
    bool clearFailure = false,
    bool clearFieldErrors = false,
    bool clearSavedCampaign = false,
  }) {
    return CampaignFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      campaignId: campaignId ?? this.campaignId,
      initialCampaign: initialCampaign ?? this.initialCampaign,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      startAt: clearStartAt ? null : startAt ?? this.startAt,
      endAt: clearEndAt ? null : endAt ?? this.endAt,
      active: active ?? this.active,
      coverImageUrl: clearCoverImageUrl
          ? null
          : coverImageUrl ?? this.coverImageUrl,
      editorialImageUrls: editorialImageUrls ?? this.editorialImageUrls,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      isUploadingCover: isUploadingCover ?? this.isUploadingCover,
      uploadingEditorialCount:
          uploadingEditorialCount ?? this.uploadingEditorialCount,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      savedCampaign: clearSavedCampaign
          ? null
          : savedCampaign ?? this.savedCampaign,
      failure: clearFailure ? null : failure ?? this.failure,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
    );
  }
}
