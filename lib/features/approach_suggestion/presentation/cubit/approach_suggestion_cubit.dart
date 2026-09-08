import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/usecases/generate_approach_suggestion_use_case.dart';
import 'approach_suggestion_state.dart';

/// Drives the "Sugerir abordagem" sheet (TASK-187, EPIC-28), reachable from
/// the customer 360 (`CustomerDetailPage`, TASK-052) and from the central de
/// oportunidades (`OpportunityCenterPage`, TASK-132). Starts at
/// [ApproachSuggestionStatus.idle] and only ever calls the backend when
/// [generate] is invoked explicitly (a button tap) — never on cubit
/// creation, since a suggestion costs a real LLM call unless already
/// cached. Mirrors `WalletSummaryCubit` (TASK-186).
@injectable
final class ApproachSuggestionCubit extends Cubit<ApproachSuggestionState> {
  ApproachSuggestionCubit(this._generateApproachSuggestion)
    : super(const ApproachSuggestionState());

  final GenerateApproachSuggestionUseCase _generateApproachSuggestion;

  Future<void> generate({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    if (state.status == ApproachSuggestionStatus.loading) return;
    emit(
      state.copyWith(
        status: ApproachSuggestionStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _generateApproachSuggestion(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
    );
    if (isClosed) return;
    switch (result) {
      case AppSuccess(value: final suggestion):
        emit(
          state.copyWith(
            status: ApproachSuggestionStatus.ready,
            suggestion: suggestion,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: ApproachSuggestionStatus.error,
            failure: failure,
          ),
        );
    }
  }

  /// Returns to [ApproachSuggestionStatus.idle] without clearing a
  /// previously generated [ApproachSuggestionState.suggestion] — used when
  /// the sheet's "Gerar novamente" action should show the idle
  /// call-to-action again.
  void reset() {
    if (state.status == ApproachSuggestionStatus.loading) return;
    emit(
      ApproachSuggestionState(
        status: ApproachSuggestionStatus.idle,
        suggestion: state.suggestion,
      ),
    );
  }
}
