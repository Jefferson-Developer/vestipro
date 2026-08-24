import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/usecases/complete_crm_task_use_case.dart';
import '../../domain/usecases/list_pending_tasks_for_week_use_case.dart';
import 'crm_task_list_event.dart';
import 'crm_task_list_state.dart';

@injectable
final class CrmTaskListBloc extends Bloc<CrmTaskListEvent, CrmTaskListState> {
  CrmTaskListBloc({
    required this.listPendingTasksForWeek,
    required this.completeTask,
    required this.analyticsService,
  }) : super(const CrmTaskListState()) {
    on<CrmTaskListStarted>(_onStarted);
    on<CrmTaskListRetried>(_onRetried);
    on<CrmTaskListTaskCompleted>(_onTaskCompleted);
    on<CrmTaskListActionDismissed>(_onActionDismissed);
  }

  final ListPendingTasksForWeekUseCase listPendingTasksForWeek;
  final CompleteCrmTaskUseCase completeTask;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    CrmTaskListStarted event,
    Emitter<CrmTaskListState> emit,
  ) async {
    emit(
      const CrmTaskListState().copyWith(
        status: CrmTaskListLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        visibleResponsibleUserIds: event.visibleResponsibleUserIds,
        canManageOthers: event.canManageOthers,
        clearFailure: true,
        clearActionFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    CrmTaskListRetried event,
    Emitter<CrmTaskListState> emit,
  ) async {
    emit(
      state.copyWith(status: CrmTaskListLoadStatus.loading, clearFailure: true),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<CrmTaskListState> emit) async {
    final result = await listPendingTasksForWeek(
      organizationId: state.organizationId,
      responsibleUserIds: state.visibleResponsibleUserIds,
      now: DateTime.now().toUtc(),
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<CrmTask>>(value: final tasks):
        emit(
          state.copyWith(
            status: CrmTaskListLoadStatus.ready,
            tasks: tasks,
            clearFailure: true,
          ),
        );
      case AppFailure<List<CrmTask>>(failure: final failure):
        emit(
          state.copyWith(
            status: CrmTaskListLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onTaskCompleted(
    CrmTaskListTaskCompleted event,
    Emitter<CrmTaskListState> emit,
  ) async {
    if (state.actionStatus == CrmTaskListActionStatus.submitting) return;
    emit(
      state.copyWith(
        actionStatus: CrmTaskListActionStatus.submitting,
        processingTaskId: event.taskId,
        clearActionFailure: true,
      ),
    );
    final result = await completeTask(
      organizationId: state.organizationId,
      id: event.taskId,
      actorUserId: state.userId,
      actorCanManageOthers: state.canManageOthers,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<CrmTask>(value: final task):
        await analyticsService.logEvent(
          AnalyticsEvents.crmFollowupCompleted,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'task_id': task.id,
            'priority': task.priority.name,
            'sync_status': task.syncStatus.name,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            actionStatus: CrmTaskListActionStatus.success,
            tasks: state.tasks
                .where((candidate) => candidate.id != task.id)
                .toList(growable: false),
            clearProcessingTaskId: true,
            clearActionFailure: true,
          ),
        );
      case AppFailure<CrmTask>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: CrmTaskListActionStatus.failure,
            actionFailure: failure,
            clearProcessingTaskId: true,
          ),
        );
    }
  }

  void _onActionDismissed(
    CrmTaskListActionDismissed event,
    Emitter<CrmTaskListState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: CrmTaskListActionStatus.idle,
        clearProcessingTaskId: true,
        clearActionFailure: true,
      ),
    );
  }
}
