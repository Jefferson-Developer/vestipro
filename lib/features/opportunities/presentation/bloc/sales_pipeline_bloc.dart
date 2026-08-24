import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';
import '../../domain/entities/pipeline_stage.dart';
import '../../domain/pipeline_board_builder.dart';
import '../../domain/usecases/list_opportunity_outcome_reasons_use_case.dart';
import '../../domain/usecases/list_pipeline_opportunities_use_case.dart';
import '../../domain/usecases/list_pipeline_stages_use_case.dart';
import '../../domain/usecases/mark_opportunity_lost_use_case.dart';
import '../../domain/usecases/mark_opportunity_won_use_case.dart';
import '../../domain/usecases/update_opportunity_stage_use_case.dart';
import '../../domain/value_objects/pipeline_stage_terminal_type.dart';
import 'sales_pipeline_event.dart';
import 'sales_pipeline_state.dart';

/// Drives `SalesPipelinePage` (TASK-058): loads the organization's stages
/// and opportunities, groups them into board columns, and moves an
/// Opportunity between stages — the single code path both the Web
/// drag-and-drop board and the mobile explicit "Mover" action funnel
/// through, so the two platforms never duplicate the move logic.
@injectable
final class SalesPipelineBloc
    extends Bloc<SalesPipelineEvent, SalesPipelineState> {
  SalesPipelineBloc({
    required this.listStages,
    required this.listOutcomeReasons,
    required this.listOpportunities,
    required this.updateStage,
    required this.markWon,
    required this.markLost,
  }) : super(const SalesPipelineState()) {
    on<SalesPipelineStarted>(_onStarted);
    on<SalesPipelineRetried>(_onRetried);
    on<SalesPipelineOpportunityMoveRequested>(_onMoveRequested);
    on<SalesPipelineOpportunityClosedWithReason>(_onClosedWithReason);
    on<SalesPipelineActionDismissed>(_onActionDismissed);
  }

  final ListPipelineStagesUseCase listStages;
  final ListOpportunityOutcomeReasonsUseCase listOutcomeReasons;
  final ListPipelineOpportunitiesUseCase listOpportunities;
  final UpdateOpportunityStageUseCase updateStage;
  final MarkOpportunityWonUseCase markWon;
  final MarkOpportunityLostUseCase markLost;

  Future<void> _onStarted(
    SalesPipelineStarted event,
    Emitter<SalesPipelineState> emit,
  ) async {
    emit(
      const SalesPipelineState().copyWith(
        status: SalesPipelineLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        responsibleUserIds: event.responsibleUserIds,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    SalesPipelineRetried event,
    Emitter<SalesPipelineState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SalesPipelineLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<SalesPipelineState> emit) async {
    final results =
        await Future.wait<AppResult<Object>>(<Future<AppResult<Object>>>[
          listStages(organizationId: state.organizationId),
          listOutcomeReasons(organizationId: state.organizationId),
          listOpportunities(
            organizationId: state.organizationId,
            companyId: state.companyId,
            responsibleUserIds: state.responsibleUserIds,
          ),
        ]);
    if (emit.isDone) return;

    final stagesResult = results[0];
    if (stagesResult is AppFailure<Object>) {
      emit(
        state.copyWith(
          status: SalesPipelineLoadStatus.failure,
          failure: stagesResult.failure,
        ),
      );
      return;
    }
    final reasonsResult = results[1];
    if (reasonsResult is AppFailure<Object>) {
      emit(
        state.copyWith(
          status: SalesPipelineLoadStatus.failure,
          failure: reasonsResult.failure,
        ),
      );
      return;
    }
    final opportunitiesResult = results[2];
    if (opportunitiesResult is AppFailure<Object>) {
      emit(
        state.copyWith(
          status: SalesPipelineLoadStatus.failure,
          failure: opportunitiesResult.failure,
        ),
      );
      return;
    }

    final stages =
        (stagesResult as AppSuccess<Object>).value as List<PipelineStage>;
    final outcomeReasons =
        (reasonsResult as AppSuccess<Object>).value
            as List<OpportunityOutcomeReason>;
    final opportunities =
        (opportunitiesResult as AppSuccess<Object>).value as List<Opportunity>;

    emit(
      state.copyWith(
        status: SalesPipelineLoadStatus.ready,
        stages: stages,
        outcomeReasons: outcomeReasons,
        opportunities: opportunities,
        columns: buildPipelineColumns(
          stages: stages,
          opportunities: opportunities,
        ),
        clearFailure: true,
      ),
    );
  }

  Future<void> _onMoveRequested(
    SalesPipelineOpportunityMoveRequested event,
    Emitter<SalesPipelineState> emit,
  ) async {
    if (state.actionStatus == SalesPipelineActionStatus.inProgress) return;

    final targetStage = state.stages.firstWhereOrNull(
      (stage) => stage.id == event.targetStageId,
    );
    if (targetStage == null) {
      emit(
        state.copyWith(
          actionStatus: SalesPipelineActionStatus.failure,
          actionFailure: const NotFoundFailure(
            'Pipeline stage not found.',
            code: 'pipeline_stage_not_found',
          ),
        ),
      );
      return;
    }
    if (targetStage.isTerminal) {
      // A direct move onto a terminal stage is always rejected here: closing
      // an Opportunity requires a mandatory reason
      // (TASK-058/TASK-061), which only
      // `SalesPipelineOpportunityClosedWithReason` carries.
      emit(
        state.copyWith(
          actionStatus: SalesPipelineActionStatus.failure,
          pendingActionOpportunityId: event.opportunityId,
          actionFailure: const ValidationFailure(
            'Moving an opportunity onto a terminal stage requires a reason.',
            fieldErrors: <String, String>{
              'targetStageId': 'Terminal stage move requires a reason.',
            },
            code: 'opportunity_move_requires_reason',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        actionStatus: SalesPipelineActionStatus.inProgress,
        pendingActionOpportunityId: event.opportunityId,
        clearActionFailure: true,
      ),
    );

    final result = await updateStage(
      organizationId: state.organizationId,
      id: event.opportunityId,
      stageId: event.targetStageId,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    _emitActionResult(emit, result);
  }

  Future<void> _onClosedWithReason(
    SalesPipelineOpportunityClosedWithReason event,
    Emitter<SalesPipelineState> emit,
  ) async {
    if (state.actionStatus == SalesPipelineActionStatus.inProgress) return;

    final targetStage = state.stages.firstWhereOrNull(
      (stage) => stage.id == event.targetStageId,
    );
    if (targetStage == null || !targetStage.isTerminal) {
      emit(
        state.copyWith(
          actionStatus: SalesPipelineActionStatus.failure,
          actionFailure: const ValidationFailure(
            'Target stage must be a terminal (won/lost) stage.',
            fieldErrors: <String, String>{
              'targetStageId': 'Invalid terminal stage.',
            },
            code: 'invalid_opportunity_close_target_stage',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        actionStatus: SalesPipelineActionStatus.inProgress,
        pendingActionOpportunityId: event.opportunityId,
        clearActionFailure: true,
      ),
    );

    final result = switch (targetStage.terminalType) {
      PipelineStageTerminalType.won => await markWon(
        organizationId: state.organizationId,
        id: event.opportunityId,
        reasonId: event.reasonId,
        note: event.note,
        updatedBy: state.userId,
        stageId: event.targetStageId,
      ),
      PipelineStageTerminalType.lost => await markLost(
        organizationId: state.organizationId,
        id: event.opportunityId,
        reasonId: event.reasonId,
        note: event.note,
        updatedBy: state.userId,
        stageId: event.targetStageId,
      ),
      PipelineStageTerminalType.none => throw StateError(
        'Unreachable: targetStage.isTerminal was already checked.',
      ),
    };
    if (emit.isDone) return;
    _emitActionResult(emit, result);
  }

  void _emitActionResult(
    Emitter<SalesPipelineState> emit,
    AppResult<Opportunity> result,
  ) {
    switch (result) {
      case AppSuccess<Opportunity>(value: final updated):
        final opportunities = <Opportunity>[
          for (final opportunity in state.opportunities)
            opportunity.id == updated.id ? updated : opportunity,
        ];
        emit(
          state.copyWith(
            opportunities: opportunities,
            columns: buildPipelineColumns(
              stages: state.stages,
              opportunities: opportunities,
            ),
            actionStatus: SalesPipelineActionStatus.idle,
            clearPendingActionOpportunityId: true,
            clearActionFailure: true,
          ),
        );
      case AppFailure<Opportunity>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: SalesPipelineActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  void _onActionDismissed(
    SalesPipelineActionDismissed event,
    Emitter<SalesPipelineState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: SalesPipelineActionStatus.idle,
        clearPendingActionOpportunityId: true,
        clearActionFailure: true,
      ),
    );
  }
}
