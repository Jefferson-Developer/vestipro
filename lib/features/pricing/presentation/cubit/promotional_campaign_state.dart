import '../../domain/entities/promotional_campaign.dart';
import '../../domain/value_objects/promotional_campaign_status.dart';
import '../../domain/value_objects/promotional_discount_type.dart';

enum PromotionalCampaignLoadStatus { idle, loading, ready, failure }

enum PromotionalCampaignSaveStatus {
  idle,
  editing,
  submitting,
  success,
  failure,
}

final class PromotionalCampaignState {
  const PromotionalCampaignState({
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.actorName = '',
    this.loadStatus = PromotionalCampaignLoadStatus.idle,
    this.saveStatus = PromotionalCampaignSaveStatus.idle,
    this.campaigns = const <PromotionalCampaign>[],
    this.editingId,
    this.name = '',
    this.customerSegment = '',
    this.productIdsInput = '',
    this.collectionIdsInput = '',
    this.categoryIdsInput = '',
    this.discountValueInput = '',
    this.priorityInput = '0',
    this.validFrom,
    this.validTo,
    this.stackableWithOtherCampaigns = false,
    this.discountType = PromotionalDiscountType.percentage,
    this.status = PromotionalCampaignStatus.active,
    this.fieldErrors = const <String, String>{},
    this.failureMessage,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final PromotionalCampaignLoadStatus loadStatus;
  final PromotionalCampaignSaveStatus saveStatus;
  final List<PromotionalCampaign> campaigns;
  final String? editingId;
  final String name;
  final String customerSegment;
  final String productIdsInput;
  final String collectionIdsInput;
  final String categoryIdsInput;
  final String discountValueInput;
  final String priorityInput;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool stackableWithOtherCampaigns;
  final PromotionalDiscountType discountType;
  final PromotionalCampaignStatus status;
  final Map<String, String> fieldErrors;
  final String? failureMessage;

  bool get isBusy =>
      loadStatus == PromotionalCampaignLoadStatus.loading ||
      saveStatus == PromotionalCampaignSaveStatus.submitting;
  bool get isEditing => editingId != null;

  PromotionalCampaignState copyWith({
    String? organizationId,
    String? companyId,
    String? userId,
    String? actorName,
    PromotionalCampaignLoadStatus? loadStatus,
    PromotionalCampaignSaveStatus? saveStatus,
    List<PromotionalCampaign>? campaigns,
    String? editingId,
    bool clearEditingId = false,
    String? name,
    String? customerSegment,
    String? productIdsInput,
    String? collectionIdsInput,
    String? categoryIdsInput,
    String? discountValueInput,
    String? priorityInput,
    DateTime? validFrom,
    DateTime? validTo,
    bool clearValidFrom = false,
    bool clearValidTo = false,
    bool? stackableWithOtherCampaigns,
    PromotionalDiscountType? discountType,
    PromotionalCampaignStatus? status,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return PromotionalCampaignState(
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      campaigns: campaigns ?? this.campaigns,
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
      name: name ?? this.name,
      customerSegment: customerSegment ?? this.customerSegment,
      productIdsInput: productIdsInput ?? this.productIdsInput,
      collectionIdsInput: collectionIdsInput ?? this.collectionIdsInput,
      categoryIdsInput: categoryIdsInput ?? this.categoryIdsInput,
      discountValueInput: discountValueInput ?? this.discountValueInput,
      priorityInput: priorityInput ?? this.priorityInput,
      validFrom: clearValidFrom ? null : (validFrom ?? this.validFrom),
      validTo: clearValidTo ? null : (validTo ?? this.validTo),
      stackableWithOtherCampaigns:
          stackableWithOtherCampaigns ?? this.stackableWithOtherCampaigns,
      discountType: discountType ?? this.discountType,
      status: status ?? this.status,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : (fieldErrors ?? this.fieldErrors),
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
