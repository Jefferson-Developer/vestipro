import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../reports/domain/entities/report_definition.dart';
import '../../domain/usecases/explain_report_use_case.dart';
import 'report_explanation_state.dart';

/// Drives the "Explicar este relatório" panel shown next to a report's
/// chart/table, both in the construtor de relatórios (TASK-144) and in
/// existing dashboards (TASK-189, EPIC-28). Starts at
/// [ReportExplanationStatus.idle] and only ever calls the backend when
/// [explain] is invoked explicitly (a button tap) — never on cubit
/// creation, since an explanation costs a real LLM call unless already
/// cached.
@injectable
final class ReportExplanationCubit extends Cubit<ReportExplanationState> {
  ReportExplanationCubit(this._explainReport)
    : super(const ReportExplanationState());

  final ExplainReportUseCase _explainReport;

  Future<void> explain({
    required ReportDefinition definition,
    String? savedReportId,
  }) async {
    if (state.status == ReportExplanationStatus.loading) return;
    emit(
      state.copyWith(
        status: ReportExplanationStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _explainReport(
      definition: definition,
      savedReportId: savedReportId,
    );
    if (isClosed) return;
    switch (result) {
      case AppSuccess(value: final explanation):
        emit(
          state.copyWith(
            status: ReportExplanationStatus.ready,
            explanation: explanation,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: ReportExplanationStatus.error,
            failure: failure,
          ),
        );
    }
  }

  /// Returns to [ReportExplanationStatus.idle] without clearing a previously
  /// generated [ReportExplanationState.explanation] — used when the panel's
  /// "Fechar" action should show the idle call-to-action again while a new
  /// query is being built, without discarding the last explanation in case
  /// the user reopens it for the same result.
  void reset() {
    if (state.status == ReportExplanationStatus.loading) return;
    emit(
      ReportExplanationState(
        status: ReportExplanationStatus.idle,
        explanation: state.explanation,
      ),
    );
  }
}
