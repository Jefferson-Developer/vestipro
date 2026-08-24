import '../../../../core/errors/errors.dart';
import '../../domain/entities/pipeline_stage.dart';

enum PipelineStageAdminLoadStatus { initial, loading, ready, failure }

enum PipelineStageAdminActionStatus { idle, inProgress, failure }

final class PipelineStageAdminState {
  const PipelineStageAdminState({
    this.status = PipelineStageAdminLoadStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.stages = const <PipelineStage>[],
    this.failure,
    this.actionStatus = PipelineStageAdminActionStatus.idle,
    this.actionFailure,
  });

  final PipelineStageAdminLoadStatus status;
  final String organizationId;
  final String userId;
  final List<PipelineStage> stages;
  final Failure? failure;
  final PipelineStageAdminActionStatus actionStatus;
  final Failure? actionFailure;

  bool get isLoading =>
      status == PipelineStageAdminLoadStatus.initial ||
      status == PipelineStageAdminLoadStatus.loading;

  PipelineStageAdminState copyWith({
    PipelineStageAdminLoadStatus? status,
    String? organizationId,
    String? userId,
    List<PipelineStage>? stages,
    Failure? failure,
    bool clearFailure = false,
    PipelineStageAdminActionStatus? actionStatus,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return PipelineStageAdminState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      stages: stages ?? this.stages,
      failure: clearFailure ? null : failure ?? this.failure,
      actionStatus: actionStatus ?? this.actionStatus,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }
}
