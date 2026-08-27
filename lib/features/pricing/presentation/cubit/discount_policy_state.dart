import '../../domain/entities/discount_policy.dart';
import '../../domain/value_objects/discount_policy_status.dart';

enum DiscountPolicyLoadStatus { idle, loading, ready, failure }

enum DiscountPolicySaveStatus { idle, editing, submitting, success, failure }

final class DiscountPolicyState {
  const DiscountPolicyState({
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.actorName = '',
    this.loadStatus = DiscountPolicyLoadStatus.idle,
    this.saveStatus = DiscountPolicySaveStatus.idle,
    this.policies = const <DiscountPolicy>[],
    this.editingId,
    this.role = '',
    this.maxDiscountPercentInput = '',
    this.requiresApprovalAbovePercentInput = '',
    this.priceListIdsInput = '',
    this.status = DiscountPolicyStatus.active,
    this.fieldErrors = const <String, String>{},
    this.failureMessage,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final DiscountPolicyLoadStatus loadStatus;
  final DiscountPolicySaveStatus saveStatus;
  final List<DiscountPolicy> policies;
  final String? editingId;
  final String role;
  final String maxDiscountPercentInput;
  final String requiresApprovalAbovePercentInput;
  final String priceListIdsInput;
  final DiscountPolicyStatus status;
  final Map<String, String> fieldErrors;
  final String? failureMessage;

  bool get isBusy =>
      loadStatus == DiscountPolicyLoadStatus.loading ||
      saveStatus == DiscountPolicySaveStatus.submitting;
  bool get isEditing => editingId != null;

  DiscountPolicyState copyWith({
    String? organizationId,
    String? companyId,
    String? userId,
    String? actorName,
    DiscountPolicyLoadStatus? loadStatus,
    DiscountPolicySaveStatus? saveStatus,
    List<DiscountPolicy>? policies,
    String? editingId,
    bool clearEditingId = false,
    String? role,
    String? maxDiscountPercentInput,
    String? requiresApprovalAbovePercentInput,
    String? priceListIdsInput,
    DiscountPolicyStatus? status,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return DiscountPolicyState(
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      policies: policies ?? this.policies,
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
      role: role ?? this.role,
      maxDiscountPercentInput:
          maxDiscountPercentInput ?? this.maxDiscountPercentInput,
      requiresApprovalAbovePercentInput:
          requiresApprovalAbovePercentInput ??
          this.requiresApprovalAbovePercentInput,
      priceListIdsInput: priceListIdsInput ?? this.priceListIdsInput,
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
