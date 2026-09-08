import '../../../../core/utils/utils.dart';
import '../entities/daily_rep_summary.dart';

/// Contract for TASK-188's "resumo diário do vendedor" feature (EPIC-28). The
/// only implementation is `CloudFunctionsDailyRepSummaryRepository` — there
/// is deliberately no local/offline datasource: the summary is always
/// produced server-side by a daily schedule, and reading it requires
/// connectivity the same way `WalletSummaryRepository`/
/// `ApproachSuggestionRepository` already do.
abstract interface class DailyRepSummaryRepository {
  /// Reads (never generates) [sellerId]'s daily summary for [dateKey]
  /// (defaults to today, server-resolved, when omitted), scoped to
  /// [organizationId]. Never called with a [sellerId] other than the
  /// caller's own uid unless the caller is a gestor (OWNER/ADMIN/
  /// SALES_MANAGER) — the server re-validates this on every call regardless
  /// of what the UI enforces.
  Future<AppResult<DailyRepSummary>> load({
    required String organizationId,
    required String sellerId,
    String? dateKey,
  });
}
