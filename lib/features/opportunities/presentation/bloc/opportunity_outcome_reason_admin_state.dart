import '../../../../core/errors/errors.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';

enum OpportunityOutcomeReasonAdminLoadStatus {
  initial,
  loading,
  ready,
  failure,
}

enum OpportunityOutcomeReasonAdminActionStatus { idle, inProgress, failure }

final class OpportunityOutcomeReasonAdminState {
  const OpportunityOutcomeReasonAdminState({
    this.status = OpportunityOutcomeReasonAdminLoadStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.reasons = const <OpportunityOutcomeReason>[],
    this.failure,
    this.actionStatus = OpportunityOutcomeReasonAdminActionStatus.idle,
    this.actionFailure,
  });

  final OpportunityOutcomeReasonAdminLoadStatus status;
  final String organizationId;
  final String userId;
  final List<OpportunityOutcomeReason> reasons;
  final Failure? failure;
  final OpportunityOutcomeReasonAdminActionStatus actionStatus;
  final Failure? actionFailure;

  bool get isLoading =>
      status == OpportunityOutcomeReasonAdminLoadStatus.initial ||
      status == OpportunityOutcomeReasonAdminLoadStatus.loading;

  OpportunityOutcomeReasonAdminState copyWith({
    OpportunityOutcomeReasonAdminLoadStatus? status,
    String? organizationId,
    String? userId,
    List<OpportunityOutcomeReason>? reasons,
    Failure? failure,
    bool clearFailure = false,
    OpportunityOutcomeReasonAdminActionStatus? actionStatus,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return OpportunityOutcomeReasonAdminState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      reasons: reasons ?? this.reasons,
      failure: clearFailure ? null : failure ?? this.failure,
      actionStatus: actionStatus ?? this.actionStatus,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }
}
