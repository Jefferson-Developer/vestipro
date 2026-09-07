import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/usecases/generate_wallet_summary_use_case.dart';
import 'wallet_summary_state.dart';

/// Drives the "Resumo da carteira" card on the representative dashboard
/// (TASK-186, EPIC-28). Starts at [WalletSummaryStatus.idle] and only ever
/// calls the backend when [generate] is invoked explicitly (a button tap) —
/// never on cubit creation, since a wallet summary costs a real LLM call
/// unless already cached.
@injectable
final class WalletSummaryCubit extends Cubit<WalletSummaryState> {
  WalletSummaryCubit(this._generateWalletSummary)
    : super(const WalletSummaryState());

  final GenerateWalletSummaryUseCase _generateWalletSummary;

  Future<void> generate({
    required String organizationId,
    required String companyId,
    required String requesterUserId,
    required String sellerId,
  }) async {
    if (state.status == WalletSummaryStatus.loading) return;
    emit(
      state.copyWith(status: WalletSummaryStatus.loading, clearFailure: true),
    );
    final result = await _generateWalletSummary(
      organizationId: organizationId,
      companyId: companyId,
      requesterUserId: requesterUserId,
      sellerId: sellerId,
    );
    if (isClosed) return;
    switch (result) {
      case AppSuccess(value: final summary):
        emit(
          state.copyWith(
            status: WalletSummaryStatus.ready,
            summary: summary,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(status: WalletSummaryStatus.error, failure: failure),
        );
    }
  }

  /// Returns to [WalletSummaryStatus.idle] without clearing a previously
  /// generated [WalletSummaryState.summary] — used when the card's "Gerar
  /// novamente" action should show the idle call-to-action again while still
  /// letting a `BlocBuilder` fall back to the last known summary if it
  /// chooses to (this cubit never forces that choice on the widget).
  void reset() {
    if (state.status == WalletSummaryStatus.loading) return;
    emit(
      WalletSummaryState(
        status: WalletSummaryStatus.idle,
        summary: state.summary,
      ),
    );
  }
}
