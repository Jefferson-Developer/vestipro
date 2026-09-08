import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/usecases/load_daily_rep_summary_use_case.dart';
import 'daily_rep_summary_state.dart';

/// Drives the "resumo do dia" card fixed at the top of the representative
/// dashboard home (TASK-188, EPIC-28). Unlike `WalletSummaryCubit`
/// (TASK-186), which only ever calls the backend on an explicit "Gerar
/// resumo" tap (a real LLM call, cost the caller controls), this cubit loads
/// automatically when created: the daily summary was already produced by the
/// `generateDailyRepSummary` schedule earlier that morning, so reading it
/// costs nothing more than any other dashboard widget's own load.
@injectable
final class DailyRepSummaryCubit extends Cubit<DailyRepSummaryState> {
  DailyRepSummaryCubit(this._loadDailyRepSummary)
    : super(const DailyRepSummaryState());

  final LoadDailyRepSummaryUseCase _loadDailyRepSummary;

  Future<void> load({
    required String organizationId,
    required String requesterUserId,
    required String sellerId,
  }) async {
    emit(
      state.copyWith(
        status: DailyRepSummaryCardStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _loadDailyRepSummary(
      organizationId: organizationId,
      requesterUserId: requesterUserId,
      sellerId: sellerId,
    );
    if (isClosed) return;
    switch (result) {
      case AppSuccess(value: final summary):
        emit(
          state.copyWith(
            status: DailyRepSummaryCardStatus.loaded,
            summary: summary,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: DailyRepSummaryCardStatus.error,
            failure: failure,
          ),
        );
    }
  }
}
