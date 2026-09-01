import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/target.dart';
import '../../domain/repositories/target_repository.dart';
import '../../domain/usecases/create_target_use_case.dart';
import '../../domain/usecases/update_target_use_case.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../../domain/value_objects/target_period_granularity.dart';
import '../../domain/value_objects/target_status.dart';
import 'target_form_state.dart';

/// Drives the cadastro de metas form (TASK-115): dimension + período +
/// métrica + valor + moeda, with real-time period-overlap validation
/// surfaced by `CreateTargetUseCase`/`UpdateTargetUseCase` (never
/// recalculated client-side) and RBAC re-validated by those same use cases,
/// never only by this Cubit or the page that hides the "criar meta" action
/// for a role without `Capability.targetManage`.
///
/// [TargetRepository.listByDimension] — the only listing query the
/// repository contract exposes — doubles as this form's "metas já
/// cadastradas" table source: [search] (re)loads every Target for whatever
/// dimension the draft currently targets, so switching the dimension picker
/// and searching again is how a gestor moves between "metas do vendedor X"
/// and "metas da equipe Y", exactly the queries `TargetRepository`'s own
/// docs describe.
@injectable
final class TargetFormCubit extends Cubit<TargetFormState> {
  TargetFormCubit(this._repository, this._createTarget, this._updateTarget)
    : super(const TargetFormState());

  final TargetRepository _repository;
  final CreateTargetUseCase _createTarget;
  final UpdateTargetUseCase _updateTarget;
  final Uuid _uuid = const Uuid();

  void init({
    required String organizationId,
    required String companyId,
    required String userId,
    required String actorName,
  }) {
    emit(
      state.copyWith(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        actorName: actorName,
      ),
    );
  }

  Future<void> search() async {
    if (state.dimensionId.trim().isEmpty) {
      emit(
        state.copyWith(
          loadStatus: TargetFormLoadStatus.failure,
          failureMessage: 'Informe o identificador da dimensão para buscar.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loadStatus: TargetFormLoadStatus.loading,
        clearFailureMessage: true,
      ),
    );

    final result = await _repository.listByDimension(
      organizationId: state.organizationId,
      companyId: state.companyId,
      dimensionType: state.dimensionType,
      dimensionId: state.dimensionId.trim(),
    );

    switch (result) {
      case AppSuccess<List<Target>>(value: final items):
        final sorted = List<Target>.of(items)
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
        emit(
          state.copyWith(
            loadStatus: TargetFormLoadStatus.ready,
            targets: sorted,
          ),
        );
      case AppFailure<List<Target>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: TargetFormLoadStatus.failure,
            failureMessage: failure.message,
          ),
        );
    }
  }

  void updateDraft({
    TargetDimensionType? dimensionType,
    String? dimensionId,
    TargetPeriodGranularity? periodGranularity,
    DateTime? startDate,
    DateTime? endDate,
    TargetMetricType? metricType,
    String? targetValueInput,
    String? currency,
    TargetStatus? status,
  }) {
    emit(
      state.copyWith(
        saveStatus: TargetFormSaveStatus.editing,
        dimensionType: dimensionType ?? state.dimensionType,
        dimensionId: dimensionId ?? state.dimensionId,
        periodGranularity: periodGranularity ?? state.periodGranularity,
        startDate: startDate ?? state.startDate,
        endDate: endDate ?? state.endDate,
        metricType: metricType ?? state.metricType,
        targetValueInput: targetValueInput ?? state.targetValueInput,
        currency: currency ?? state.currency,
        status: status ?? state.status,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startCreate() {
    emit(
      state.copyWith(
        saveStatus: TargetFormSaveStatus.idle,
        clearEditingId: true,
        periodGranularity: TargetPeriodGranularity.monthly,
        clearStartDate: true,
        clearEndDate: true,
        metricType: TargetMetricType.revenue,
        targetValueInput: '',
        currency: 'BRL',
        status: TargetStatus.active,
        clearCurrentAchievedValue: true,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startEdit(Target target, {double? currentAchievedValue}) {
    emit(
      state.copyWith(
        editingId: target.id,
        saveStatus: TargetFormSaveStatus.editing,
        dimensionType: target.dimensionType,
        dimensionId: target.dimensionId,
        periodGranularity: target.periodGranularity,
        startDate: target.startDate,
        endDate: target.endDate,
        metricType: target.metricType,
        targetValueInput: _formatNumber(target.targetValue),
        currency: target.currency,
        status: target.status,
        currentAchievedValue: currentAchievedValue,
        clearCurrentAchievedValue: currentAchievedValue == null,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  Future<void> submit({bool confirmReduceBelowAchieved = false}) async {
    emit(
      state.copyWith(
        saveStatus: TargetFormSaveStatus.submitting,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );

    final targetValue = _parseDecimal(state.targetValueInput) ?? double.nan;
    final startDate = state.startDate;
    final endDate = state.endDate;
    if (startDate == null || endDate == null) {
      emit(
        state.copyWith(
          saveStatus: TargetFormSaveStatus.failure,
          fieldErrors: <String, String>{
            if (startDate == null) 'startDate': 'Informe a data de início.',
            if (endDate == null) 'endDate': 'Informe a data de fim.',
          },
          failureMessage: 'Informe o período completo da meta.',
        ),
      );
      return;
    }

    final result = state.isEditing
        ? await _updateTarget(
            organizationId: state.organizationId,
            id: state.editingId!,
            periodGranularity: state.periodGranularity,
            startDate: startDate,
            endDate: endDate,
            metricType: state.metricType,
            targetValue: targetValue,
            currency: state.currency,
            status: state.status,
            updatedBy: state.userId,
            actorName: state.actorName,
            currentAchievedValue: state.currentAchievedValue,
            confirmReduceBelowAchieved: confirmReduceBelowAchieved,
          )
        : await _createTarget(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            companyId: state.companyId,
            dimensionType: state.dimensionType,
            dimensionId: state.dimensionId,
            periodGranularity: state.periodGranularity,
            startDate: startDate,
            endDate: endDate,
            metricType: state.metricType,
            targetValue: targetValue,
            currency: state.currency,
            status: state.status,
            createdBy: state.userId,
          );

    switch (result) {
      case AppSuccess<Target>():
        await search();
        emit(
          state.copyWith(
            saveStatus: TargetFormSaveStatus.success,
            clearEditingId: true,
            targetValueInput: '',
            clearStartDate: true,
            clearEndDate: true,
            clearCurrentAchievedValue: true,
            clearFieldErrors: true,
            clearFailureMessage: true,
          ),
        );
      case AppFailure<Target>(failure: final failure):
        final isReduceConfirmation =
            failure is ValidationFailure &&
            failure.code == 'target_value_below_achieved';
        emit(
          state.copyWith(
            saveStatus: isReduceConfirmation
                ? TargetFormSaveStatus.needsReduceConfirmation
                : TargetFormSaveStatus.failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
            failureMessage: failure.message,
          ),
        );
    }
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
