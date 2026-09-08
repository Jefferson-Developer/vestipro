import 'daily_rep_summary_reference.dart';

/// Result of TASK-188's "resumo diário do vendedor" (EPIC-28) for one seller/
/// day, as read from `getDailyRepSummary`. Always produced server-side by the
/// `generateDailyRepSummary` scheduled Cloud Function from already-computed
/// data; never assembled or mutated client-side, and never generated on
/// demand by this feature — the client only ever reads what the daily
/// schedule already produced.
enum DailyRepSummaryResultStatus {
  /// A summary text was generated and validated — [DailyRepSummary.summaryText]
  /// is non-null.
  ready,

  /// Nothing notable for the seller today (no target risk, no problem order,
  /// no insight, no sales) — a valid, expected state, never an error
  /// (`tasks.md`/TASK-188: "a ausência do resumo é um estado tratado").
  empty,

  /// Generation was attempted but failed (provider unavailable, validation
  /// rejected) — also a handled state, never blocking the home.
  error,

  /// `generateDailyRepSummary` has not (yet, or ever, for this exact day)
  /// produced an entry for this seller — the normal state before the daily
  /// schedule runs.
  notGeneratedYet,
}

/// A read of TASK-188's daily summary for one seller/day.
final class DailyRepSummary {
  const DailyRepSummary({
    required this.status,
    required this.dateKey,
    this.summaryText,
    this.references = const <DailyRepSummaryReference>[],
    this.generatedAt,
  });

  final DailyRepSummaryResultStatus status;

  /// `YYYY-MM-DD` this summary covers.
  final String dateKey;

  /// Non-null only when [status] is [DailyRepSummaryResultStatus.ready].
  final String? summaryText;
  final List<DailyRepSummaryReference> references;

  /// `null` when [status] is not [DailyRepSummaryResultStatus.ready].
  final DateTime? generatedAt;
}
