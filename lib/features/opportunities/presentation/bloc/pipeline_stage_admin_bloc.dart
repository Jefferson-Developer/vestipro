import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/pipeline_stage.dart';
import '../../domain/usecases/create_pipeline_stage_use_case.dart';
import '../../domain/usecases/list_pipeline_stages_use_case.dart';
import '../../domain/usecases/rename_pipeline_stage_use_case.dart';
import '../../domain/usecases/reorder_pipeline_stages_use_case.dart';
import 'pipeline_stage_admin_event.dart';
import 'pipeline_stage_admin_state.dart';

/// Drives `PipelineStageAdminPage` (TASK-058): create, rename and reorder
/// the organization's [PipelineStage]s. Administrative-only — gated in the
/// UI by `Capability.pipelineStageManage`.
@injectable
final class PipelineStageAdminBloc
    extends Bloc<PipelineStageAdminEvent, PipelineStageAdminState> {
  PipelineStageAdminBloc({
    required this.listStages,
    required this.createStage,
    required this.renameStage,
    required this.reorderStages,
  }) : super(const PipelineStageAdminState()) {
    on<PipelineStageAdminStarted>(_onStarted);
    on<PipelineStageAdminRetried>(_onRetried);
    on<PipelineStageAdminStageCreated>(_onStageCreated);
    on<PipelineStageAdminStageRenamed>(_onStageRenamed);
    on<PipelineStageAdminStagesReordered>(_onStagesReordered);
    on<PipelineStageAdminActionDismissed>(_onActionDismissed);
  }

  final ListPipelineStagesUseCase listStages;
  final CreatePipelineStageUseCase createStage;
  final RenamePipelineStageUseCase renameStage;
  final ReorderPipelineStagesUseCase reorderStages;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    PipelineStageAdminStarted event,
    Emitter<PipelineStageAdminState> emit,
  ) async {
    emit(
      const PipelineStageAdminState().copyWith(
        status: PipelineStageAdminLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    PipelineStageAdminRetried event,
    Emitter<PipelineStageAdminState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PipelineStageAdminLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<PipelineStageAdminState> emit) async {
    final result = await listStages(organizationId: state.organizationId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<PipelineStage>>(value: final stages):
        emit(
          state.copyWith(
            status: PipelineStageAdminLoadStatus.ready,
            stages: stages,
            clearFailure: true,
          ),
        );
      case AppFailure<List<PipelineStage>>(failure: final failure):
        emit(
          state.copyWith(
            status: PipelineStageAdminLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onStageCreated(
    PipelineStageAdminStageCreated event,
    Emitter<PipelineStageAdminState> emit,
  ) async {
    if (state.actionStatus == PipelineStageAdminActionStatus.inProgress) {
      return;
    }
    emit(
      state.copyWith(
        actionStatus: PipelineStageAdminActionStatus.inProgress,
        clearActionFailure: true,
      ),
    );

    final result = await createStage(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      name: event.name,
      colorHex: event.colorHex,
      terminalType: event.terminalType,
      createdBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<PipelineStage>(value: final created):
        emit(
          state.copyWith(
            stages: <PipelineStage>[...state.stages, created],
            actionStatus: PipelineStageAdminActionStatus.idle,
            clearActionFailure: true,
          ),
        );
      case AppFailure<PipelineStage>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: PipelineStageAdminActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  Future<void> _onStageRenamed(
    PipelineStageAdminStageRenamed event,
    Emitter<PipelineStageAdminState> emit,
  ) async {
    if (state.actionStatus == PipelineStageAdminActionStatus.inProgress) {
      return;
    }
    emit(
      state.copyWith(
        actionStatus: PipelineStageAdminActionStatus.inProgress,
        clearActionFailure: true,
      ),
    );

    final result = await renameStage(
      organizationId: state.organizationId,
      id: event.stageId,
      name: event.name,
      colorHex: event.colorHex,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<PipelineStage>(value: final updated):
        emit(
          state.copyWith(
            stages: <PipelineStage>[
              for (final stage in state.stages)
                stage.id == updated.id ? updated : stage,
            ],
            actionStatus: PipelineStageAdminActionStatus.idle,
            clearActionFailure: true,
          ),
        );
      case AppFailure<PipelineStage>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: PipelineStageAdminActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  Future<void> _onStagesReordered(
    PipelineStageAdminStagesReordered event,
    Emitter<PipelineStageAdminState> emit,
  ) async {
    if (state.actionStatus == PipelineStageAdminActionStatus.inProgress) {
      return;
    }
    emit(
      state.copyWith(
        actionStatus: PipelineStageAdminActionStatus.inProgress,
        clearActionFailure: true,
      ),
    );

    final result = await reorderStages(
      organizationId: state.organizationId,
      orderedStageIds: event.orderedStageIds,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<PipelineStage>>(value: final stages):
        emit(
          state.copyWith(
            stages: stages,
            actionStatus: PipelineStageAdminActionStatus.idle,
            clearActionFailure: true,
          ),
        );
      case AppFailure<List<PipelineStage>>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: PipelineStageAdminActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  void _onActionDismissed(
    PipelineStageAdminActionDismissed event,
    Emitter<PipelineStageAdminState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: PipelineStageAdminActionStatus.idle,
        clearActionFailure: true,
      ),
    );
  }
}
