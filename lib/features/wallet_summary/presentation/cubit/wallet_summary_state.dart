import '../../../../core/errors/errors.dart';
import '../../domain/entities/wallet_summary.dart';

enum WalletSummaryStatus {
  /// Before the seller/gestor ever taps "Gerar resumo" — the card shows only
  /// the call-to-action, never auto-generates on screen load (TASK-186:
  /// "sob demanda"; also keeps LLM cost/frequency under the caller's
  /// control, never spent without an explicit request).
  idle,
  loading,
  ready,
  error,
}

/// State for [WalletSummaryCubit] (TASK-186, EPIC-28).
final class WalletSummaryState {
  const WalletSummaryState({
    this.status = WalletSummaryStatus.idle,
    this.summary,
    this.failure,
  });

  final WalletSummaryStatus status;
  final WalletSummary? summary;
  final Failure? failure;

  WalletSummaryState copyWith({
    WalletSummaryStatus? status,
    WalletSummary? summary,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return WalletSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
