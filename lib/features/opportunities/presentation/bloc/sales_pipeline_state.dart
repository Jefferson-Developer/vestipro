import '../../../../core/errors/errors.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/entities/pipeline_column.dart';
import '../../domain/entities/pipeline_stage.dart';

enum SalesPipelineLoadStatus { initial, loading, ready, failure }

enum SalesPipelineActionStatus { idle, inProgress, failure }

final class SalesPipelineState {
  const SalesPipelineState({
    this.status = SalesPipelineLoadStatus.initial,
    this.organizationId = '',
    this.companyId,
    this.userId = '',
    this.responsibleUserIds = const <String>{},
    this.stages = const <PipelineStage>[],
    this.opportunities = const <Opportunity>[],
    this.columns = const <PipelineColumn>[],
    this.failure,
    this.actionStatus = SalesPipelineActionStatus.idle,
    this.pendingActionOpportunityId,
    this.actionFailure,
  });

  final SalesPipelineLoadStatus status;
  final String organizationId;
  final String? companyId;
  final String userId;
  final Set<String> responsibleUserIds;
  final List<PipelineStage> stages;
  final List<Opportunity> opportunities;
  final List<PipelineColumn> columns;
  final Failure? failure;
  final SalesPipelineActionStatus actionStatus;
  final String? pendingActionOpportunityId;
  final Failure? actionFailure;

  bool get isLoading =>
      status == SalesPipelineLoadStatus.initial ||
      status == SalesPipelineLoadStatus.loading;

  bool isActionPending(String opportunityId) =>
      actionStatus == SalesPipelineActionStatus.inProgress &&
      pendingActionOpportunityId == opportunityId;

  SalesPipelineState copyWith({
    SalesPipelineLoadStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    Set<String>? responsibleUserIds,
    List<PipelineStage>? stages,
    List<Opportunity>? opportunities,
    List<PipelineColumn>? columns,
    Failure? failure,
    bool clearFailure = false,
    SalesPipelineActionStatus? actionStatus,
    String? pendingActionOpportunityId,
    bool clearPendingActionOpportunityId = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return SalesPipelineState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      responsibleUserIds: responsibleUserIds ?? this.responsibleUserIds,
      stages: stages ?? this.stages,
      opportunities: opportunities ?? this.opportunities,
      columns: columns ?? this.columns,
      failure: clearFailure ? null : failure ?? this.failure,
      actionStatus: actionStatus ?? this.actionStatus,
      pendingActionOpportunityId: clearPendingActionOpportunityId
          ? null
          : pendingActionOpportunityId ?? this.pendingActionOpportunityId,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }
}
