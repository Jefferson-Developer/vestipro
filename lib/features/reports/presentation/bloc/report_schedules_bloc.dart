import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/report_schedule.dart';
import '../../domain/usecases/report_schedule_use_cases.dart';
import 'report_schedules_event.dart';
import 'report_schedules_state.dart';

/// Backs the "tela mínima de gestão de agendamentos" (TASK-149) — list,
/// create, pause and delete a [ReportSchedule], mirroring `SavedReportsBloc`
/// (TASK-145)'s own shape field-for-field.
@injectable
final class ReportSchedulesBloc
    extends Bloc<ReportSchedulesEvent, ReportSchedulesState> {
  ReportSchedulesBloc(
    this._listReportSchedules,
    this._createReportSchedule,
    this._pauseReportSchedule,
    this._deleteReportSchedule,
    this._analytics,
  ) : super(const ReportSchedulesState()) {
    on<ReportSchedulesStarted>(_onStarted);
    on<ReportSchedulesRetried>(_onRetried);
    on<ReportScheduleCreateRequested>(_onCreateRequested);
    on<ReportSchedulePauseRequested>(_onPauseRequested);
    on<ReportScheduleDeleteRequested>(_onDeleteRequested);
    on<ReportSchedulesMessageCleared>(_onMessageCleared);
  }

  final ListReportSchedules _listReportSchedules;
  final CreateReportSchedule _createReportSchedule;
  final PauseReportSchedule _pauseReportSchedule;
  final DeleteReportSchedule _deleteReportSchedule;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    ReportSchedulesStarted event,
    Emitter<ReportSchedulesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReportSchedulesStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
      ),
    );
    await _reload(emit);
  }

  Future<void> _onRetried(
    ReportSchedulesRetried event,
    Emitter<ReportSchedulesState> emit,
  ) async {
    emit(
      state.copyWith(status: ReportSchedulesStatus.loading, clearFailure: true),
    );
    await _reload(emit);
  }

  Future<void> _reload(Emitter<ReportSchedulesState> emit) async {
    final result = await _listReportSchedules(
      organizationId: state.organizationId,
      companyId: state.companyId,
      requesterId: state.userId,
    );
    switch (result) {
      case AppSuccess(value: final schedules):
        emit(
          state.copyWith(
            status: ReportSchedulesStatus.ready,
            schedules: schedules,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: ReportSchedulesStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onCreateRequested(
    ReportScheduleCreateRequested event,
    Emitter<ReportSchedulesState> emit,
  ) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await _createReportSchedule(
      requesterId: state.userId,
      savedReport: event.savedReport,
      frequency: event.frequency,
      weekday: event.weekday,
      dayOfMonth: event.dayOfMonth,
      hour: event.hour,
      minute: event.minute,
      format: event.format,
      locale: event.locale,
      recipientUserIds: event.recipientUserIds,
    );
    switch (result) {
      case AppSuccess(value: final schedule):
        emit(
          state.copyWith(
            isMutating: false,
            schedules: <ReportSchedule>[...state.schedules, schedule],
            successMessage: 'Agendamento criado com sucesso.',
          ),
        );
        await _analytics.logEvent(
          AnalyticsEvents.reportScheduleCreated,
          parameters: <String, Object?>{
            'frequency': schedule.frequency.code,
            'format': schedule.format.name,
          },
        );
      case AppFailure(failure: final failure):
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  Future<void> _onPauseRequested(
    ReportSchedulePauseRequested event,
    Emitter<ReportSchedulesState> emit,
  ) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await _pauseReportSchedule(
      requesterId: state.userId,
      schedule: event.schedule,
    );
    switch (result) {
      case AppSuccess(value: final updated):
        emit(
          state.copyWith(
            isMutating: false,
            schedules: state.schedules
                .map((item) => item.id == updated.id ? updated : item)
                .toList(growable: false),
            successMessage: 'Agendamento pausado.',
          ),
        );
        await _analytics.logEvent(AnalyticsEvents.reportSchedulePaused);
      case AppFailure(failure: final failure):
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  Future<void> _onDeleteRequested(
    ReportScheduleDeleteRequested event,
    Emitter<ReportSchedulesState> emit,
  ) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await _deleteReportSchedule(
      requesterId: state.userId,
      schedule: event.schedule,
    );
    switch (result) {
      case AppSuccess():
        emit(
          state.copyWith(
            isMutating: false,
            schedules: state.schedules
                .where((item) => item.id != event.schedule.id)
                .toList(growable: false),
            successMessage: 'Agendamento excluído.',
          ),
        );
        await _analytics.logEvent(AnalyticsEvents.reportScheduleDeleted);
      case AppFailure(failure: final failure):
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  void _onMessageCleared(
    ReportSchedulesMessageCleared event,
    Emitter<ReportSchedulesState> emit,
  ) {
    emit(state.copyWith(clearFailure: true, clearSuccessMessage: true));
  }
}
