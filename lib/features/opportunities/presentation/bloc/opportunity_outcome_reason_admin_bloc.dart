import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';
import '../../domain/usecases/create_opportunity_outcome_reason_use_case.dart';
import '../../domain/usecases/deactivate_opportunity_outcome_reason_use_case.dart';
import '../../domain/usecases/list_opportunity_outcome_reasons_use_case.dart';
import '../../domain/usecases/update_opportunity_outcome_reason_use_case.dart';
import 'opportunity_outcome_reason_admin_event.dart';
import 'opportunity_outcome_reason_admin_state.dart';

@injectable
final class OpportunityOutcomeReasonAdminBloc
    extends
        Bloc<
          OpportunityOutcomeReasonAdminEvent,
          OpportunityOutcomeReasonAdminState
        > {
  OpportunityOutcomeReasonAdminBloc({
    required this.listReasons,
    required this.createReason,
    required this.updateReason,
    required this.deactivateReason,
  }) : super(const OpportunityOutcomeReasonAdminState()) {
    on<OpportunityOutcomeReasonAdminStarted>(_onStarted);
    on<OpportunityOutcomeReasonAdminRetried>(_onRetried);
    on<OpportunityOutcomeReasonAdminReasonCreated>(_onReasonCreated);
    on<OpportunityOutcomeReasonAdminReasonRenamed>(_onReasonRenamed);
    on<OpportunityOutcomeReasonAdminReasonDeactivated>(_onReasonDeactivated);
    on<OpportunityOutcomeReasonAdminActionDismissed>(_onActionDismissed);
  }

  final ListOpportunityOutcomeReasonsUseCase listReasons;
  final CreateOpportunityOutcomeReasonUseCase createReason;
  final UpdateOpportunityOutcomeReasonUseCase updateReason;
  final DeactivateOpportunityOutcomeReasonUseCase deactivateReason;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    OpportunityOutcomeReasonAdminStarted event,
    Emitter<OpportunityOutcomeReasonAdminState> emit,
  ) async {
    emit(
      const OpportunityOutcomeReasonAdminState().copyWith(
        status: OpportunityOutcomeReasonAdminLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    OpportunityOutcomeReasonAdminRetried event,
    Emitter<OpportunityOutcomeReasonAdminState> emit,
  ) async {
    emit(
      state.copyWith(
        status: OpportunityOutcomeReasonAdminLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<OpportunityOutcomeReasonAdminState> emit) async {
    final result = await listReasons(
      organizationId: state.organizationId,
      includeInactive: true,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<OpportunityOutcomeReason>>(value: final reasons):
        emit(
          state.copyWith(
            status: OpportunityOutcomeReasonAdminLoadStatus.ready,
            reasons: reasons,
            clearFailure: true,
          ),
        );
      case AppFailure<List<OpportunityOutcomeReason>>(failure: final failure):
        emit(
          state.copyWith(
            status: OpportunityOutcomeReasonAdminLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onReasonCreated(
    OpportunityOutcomeReasonAdminReasonCreated event,
    Emitter<OpportunityOutcomeReasonAdminState> emit,
  ) async {
    if (state.actionStatus ==
        OpportunityOutcomeReasonAdminActionStatus.inProgress) {
      return;
    }
    emit(
      state.copyWith(
        actionStatus: OpportunityOutcomeReasonAdminActionStatus.inProgress,
        clearActionFailure: true,
      ),
    );

    final result = await createReason(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      type: event.type,
      description: event.description,
      createdBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<OpportunityOutcomeReason>(value: final created):
        emit(
          state.copyWith(
            reasons: _sorted(<OpportunityOutcomeReason>[
              ...state.reasons,
              created,
            ]),
            actionStatus: OpportunityOutcomeReasonAdminActionStatus.idle,
            clearActionFailure: true,
          ),
        );
      case AppFailure<OpportunityOutcomeReason>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: OpportunityOutcomeReasonAdminActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  Future<void> _onReasonRenamed(
    OpportunityOutcomeReasonAdminReasonRenamed event,
    Emitter<OpportunityOutcomeReasonAdminState> emit,
  ) async {
    if (state.actionStatus ==
        OpportunityOutcomeReasonAdminActionStatus.inProgress) {
      return;
    }
    emit(
      state.copyWith(
        actionStatus: OpportunityOutcomeReasonAdminActionStatus.inProgress,
        clearActionFailure: true,
      ),
    );

    final result = await updateReason(
      organizationId: state.organizationId,
      id: event.reasonId,
      description: event.description,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    _emitUpdated(emit, result);
  }

  Future<void> _onReasonDeactivated(
    OpportunityOutcomeReasonAdminReasonDeactivated event,
    Emitter<OpportunityOutcomeReasonAdminState> emit,
  ) async {
    if (state.actionStatus ==
        OpportunityOutcomeReasonAdminActionStatus.inProgress) {
      return;
    }
    emit(
      state.copyWith(
        actionStatus: OpportunityOutcomeReasonAdminActionStatus.inProgress,
        clearActionFailure: true,
      ),
    );

    final result = await deactivateReason(
      organizationId: state.organizationId,
      id: event.reasonId,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    _emitUpdated(emit, result);
  }

  void _emitUpdated(
    Emitter<OpportunityOutcomeReasonAdminState> emit,
    AppResult<OpportunityOutcomeReason> result,
  ) {
    switch (result) {
      case AppSuccess<OpportunityOutcomeReason>(value: final updated):
        emit(
          state.copyWith(
            reasons: _sorted(<OpportunityOutcomeReason>[
              for (final reason in state.reasons)
                reason.id == updated.id ? updated : reason,
            ]),
            actionStatus: OpportunityOutcomeReasonAdminActionStatus.idle,
            clearActionFailure: true,
          ),
        );
      case AppFailure<OpportunityOutcomeReason>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: OpportunityOutcomeReasonAdminActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  void _onActionDismissed(
    OpportunityOutcomeReasonAdminActionDismissed event,
    Emitter<OpportunityOutcomeReasonAdminState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: OpportunityOutcomeReasonAdminActionStatus.idle,
        clearActionFailure: true,
      ),
    );
  }

  List<OpportunityOutcomeReason> _sorted(
    List<OpportunityOutcomeReason> reasons,
  ) {
    return reasons..sort((a, b) {
      final typeComparison = a.type.index.compareTo(b.type.index);
      if (typeComparison != 0) return typeComparison;
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.description.compareTo(b.description);
    });
  }
}
