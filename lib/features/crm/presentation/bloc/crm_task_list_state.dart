import '../../../../core/errors/errors.dart';
import '../../domain/entities/crm_task.dart';

enum CrmTaskListLoadStatus { initial, loading, ready, failure }

enum CrmTaskListActionStatus { idle, submitting, success, failure }

final class CrmTaskListState {
  const CrmTaskListState({
    this.status = CrmTaskListLoadStatus.initial,
    this.actionStatus = CrmTaskListActionStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.visibleResponsibleUserIds = const <String>{},
    this.canManageOthers = false,
    this.tasks = const <CrmTask>[],
    this.processingTaskId,
    this.failure,
    this.actionFailure,
  });

  final CrmTaskListLoadStatus status;
  final CrmTaskListActionStatus actionStatus;
  final String organizationId;
  final String userId;
  final Set<String> visibleResponsibleUserIds;
  final bool canManageOthers;
  final List<CrmTask> tasks;
  final String? processingTaskId;
  final Failure? failure;
  final Failure? actionFailure;

  bool get isLoading =>
      status == CrmTaskListLoadStatus.initial ||
      status == CrmTaskListLoadStatus.loading;

  bool isProcessing(String taskId) =>
      actionStatus == CrmTaskListActionStatus.submitting &&
      processingTaskId == taskId;

  CrmTaskListState copyWith({
    CrmTaskListLoadStatus? status,
    CrmTaskListActionStatus? actionStatus,
    String? organizationId,
    String? userId,
    Set<String>? visibleResponsibleUserIds,
    bool? canManageOthers,
    List<CrmTask>? tasks,
    String? processingTaskId,
    bool clearProcessingTaskId = false,
    Failure? failure,
    bool clearFailure = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return CrmTaskListState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibleResponsibleUserIds:
          visibleResponsibleUserIds ?? this.visibleResponsibleUserIds,
      canManageOthers: canManageOthers ?? this.canManageOthers,
      tasks: tasks ?? this.tasks,
      processingTaskId: clearProcessingTaskId
          ? null
          : processingTaskId ?? this.processingTaskId,
      failure: clearFailure ? null : failure ?? this.failure,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }
}
