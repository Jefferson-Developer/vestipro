import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/saved_report.dart';
import '../../domain/usecases/saved_report_use_cases.dart';
import 'saved_reports_event.dart';
import 'saved_reports_state.dart';

/// Backs the "Meus relatórios"/"Compartilhados comigo" lists (TASK-145) —
/// reused, via [BlocProvider], both by `SavedReportsPage` (list/manage) and
/// by the report builder page (TASK-144) to save the definition currently
/// being built as a new [SavedReport].
@injectable
final class SavedReportsBloc
    extends Bloc<SavedReportsEvent, SavedReportsState> {
  SavedReportsBloc(
    this._listSavedReports,
    this._saveReportView,
    this._updateSavedReport,
    this._deleteSavedReport,
    this._openSavedReportInBuilder,
    this._analytics,
  ) : super(const SavedReportsState()) {
    on<SavedReportsStarted>(_onStarted);
    on<SavedReportsRetried>(_onRetried);
    on<SavedReportCreateRequested>(_onCreateRequested);
    on<SavedReportRenameRequested>(_onRenameRequested);
    on<SavedReportVisibilityChangeRequested>(_onVisibilityChangeRequested);
    on<SavedReportFavoriteToggleRequested>(_onFavoriteToggleRequested);
    on<SavedReportDuplicateRequested>(_onDuplicateRequested);
    on<SavedReportOpenRequested>(_onOpenRequested);
    on<SavedReportOpenedMessageCleared>(_onOpenedMessageCleared);
    on<SavedReportDeleteRequested>(_onDeleteRequested);
    on<SavedReportsMessageCleared>(_onMessageCleared);
  }

  final ListSavedReports _listSavedReports;
  final SaveReportView _saveReportView;
  final UpdateSavedReport _updateSavedReport;
  final DeleteSavedReport _deleteSavedReport;
  final OpenSavedReportInBuilder _openSavedReportInBuilder;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    SavedReportsStarted event,
    Emitter<SavedReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SavedReportsStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
      ),
    );
    await _reload(emit);
  }

  Future<void> _onRetried(
    SavedReportsRetried event,
    Emitter<SavedReportsState> emit,
  ) async {
    emit(
      state.copyWith(status: SavedReportsStatus.loading, clearFailure: true),
    );
    await _reload(emit);
  }

  Future<void> _reload(Emitter<SavedReportsState> emit) async {
    final result = await _listSavedReports(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
    );
    switch (result) {
      case AppSuccess(value: final overview):
        emit(
          state.copyWith(
            status: SavedReportsStatus.ready,
            owned: overview.owned,
            shared: overview.shared,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(status: SavedReportsStatus.failure, failure: failure),
        );
    }
  }

  Future<void> _onCreateRequested(
    SavedReportCreateRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await _saveReportView(
      organizationId: state.organizationId,
      companyId: state.companyId,
      ownerId: state.userId,
      name: event.name,
      definition: event.definition,
      visibility: event.visibility,
    );
    switch (result) {
      case AppSuccess(value: final report):
        emit(
          state.copyWith(
            isMutating: false,
            owned: <SavedReport>[...state.owned, report],
            successMessage: 'Visualização salva com sucesso.',
          ),
        );
        await _analytics.logEvent(
          AnalyticsEvents.reportViewSaved,
          parameters: <String, Object?>{'visibility': report.visibility.code},
        );
      case AppFailure(failure: final failure):
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  Future<void> _onRenameRequested(
    SavedReportRenameRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    await _mutate(
      emit,
      current: event.report,
      call: () => _updateSavedReport(
        requesterId: state.userId,
        current: event.report,
        name: event.newName,
      ),
      successMessage: 'Visualização renomeada.',
    );
  }

  Future<void> _onVisibilityChangeRequested(
    SavedReportVisibilityChangeRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    await _mutate(
      emit,
      current: event.report,
      call: () => _updateSavedReport(
        requesterId: state.userId,
        current: event.report,
        visibility: event.visibility,
      ),
      successMessage: 'Compartilhamento atualizado.',
      onSuccess: (updated) async {
        if (updated.isShared) {
          await _analytics.logEvent(
            AnalyticsEvents.reportViewShared,
            parameters: <String, Object?>{
              'visibility': updated.visibility.code,
            },
          );
        }
      },
    );
  }

  Future<void> _onFavoriteToggleRequested(
    SavedReportFavoriteToggleRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    await _mutate(
      emit,
      current: event.report,
      call: () => _updateSavedReport(
        requesterId: state.userId,
        current: event.report,
        favorite: !event.report.favorite,
      ),
      successMessage: null,
    );
  }

  Future<void> _onDuplicateRequested(
    SavedReportDuplicateRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await _saveReportView(
      organizationId: state.organizationId,
      companyId: state.companyId,
      ownerId: state.userId,
      name: event.newName,
      definition: event.report.definition,
    );
    switch (result) {
      case AppSuccess(value: final report):
        emit(
          state.copyWith(
            isMutating: false,
            owned: <SavedReport>[...state.owned, report],
            successMessage: 'Visualização duplicada.',
          ),
        );
      case AppFailure(failure: final failure):
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  Future<void> _onOpenRequested(
    SavedReportOpenRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    await _openSavedReportInBuilder(
      userId: state.userId,
      definition: event.report.definition,
    );
    emit(state.copyWith(reportToOpen: event.report));
  }

  void _onOpenedMessageCleared(
    SavedReportOpenedMessageCleared event,
    Emitter<SavedReportsState> emit,
  ) {
    emit(state.copyWith(clearReportToOpen: true));
  }

  Future<void> _onDeleteRequested(
    SavedReportDeleteRequested event,
    Emitter<SavedReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await _deleteSavedReport(
      requesterId: state.userId,
      report: event.report,
    );
    switch (result) {
      case AppSuccess():
        emit(
          state.copyWith(
            isMutating: false,
            owned: state.owned
                .where((r) => r.id != event.report.id)
                .toList(growable: false),
            shared: state.shared
                .where((r) => r.id != event.report.id)
                .toList(growable: false),
            successMessage: 'Visualização excluída.',
          ),
        );
        await _analytics.logEvent(AnalyticsEvents.reportViewDeleted);
      case AppFailure(failure: final failure):
        // Never a silent no-op: TASK-145's "não falha silenciosa" rule for a
        // report blocked by an active TASK-149 schedule surfaces the exact
        // same way any other mutation failure does, through `state.failure`.
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  void _onMessageCleared(
    SavedReportsMessageCleared event,
    Emitter<SavedReportsState> emit,
  ) {
    emit(state.copyWith(clearFailure: true, clearSuccessMessage: true));
  }

  Future<void> _mutate(
    Emitter<SavedReportsState> emit, {
    required SavedReport current,
    required Future<AppResult<SavedReport>> Function() call,
    required String? successMessage,
    Future<void> Function(SavedReport updated)? onSuccess,
  }) async {
    emit(
      state.copyWith(
        isMutating: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    final result = await call();
    switch (result) {
      case AppSuccess(value: final updated):
        emit(
          state.copyWith(
            isMutating: false,
            owned: _replace(state.owned, updated),
            shared: _replace(state.shared, updated),
            successMessage: successMessage,
          ),
        );
        if (onSuccess != null) await onSuccess(updated);
      case AppFailure(failure: final failure):
        emit(state.copyWith(isMutating: false, failure: failure));
    }
  }

  List<SavedReport> _replace(List<SavedReport> reports, SavedReport updated) =>
      reports
          .map((report) => report.id == updated.id ? updated : report)
          .toList(growable: false);
}
