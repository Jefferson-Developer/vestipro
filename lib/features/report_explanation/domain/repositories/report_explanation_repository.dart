import '../../../../core/utils/utils.dart';
import '../../../reports/domain/entities/report_definition.dart';
import '../entities/report_explanation.dart';

/// Contract for TASK-189's "explicação de relatórios" feature (EPIC-28). The
/// only implementation is `CloudFunctionsReportExplanationRepository` —
/// there is deliberately no local/offline datasource: the underlying report
/// rows are already server-computed on demand
/// (`executeReportQuery`/TASK-144), the LLM call itself requires
/// connectivity, and `tasks.md`/TASK-189 never asks for an offline mode
/// here (same reasoning as `WalletSummaryRepository`, TASK-186, and
/// `ApproachSuggestionRepository`, TASK-187).
abstract interface class ReportExplanationRepository {
  /// Requests (or reuses a cached) natural-language explanation of the
  /// report described by [definition] — `explainReport` never trusts a
  /// `ReportQueryResult` computed client-side; it always re-runs the exact
  /// same aggregation server-side under the caller's own role/tenant scope
  /// before narrating anything, exactly like `exportReportToCsv` (TASK-146)
  /// already does for its own export.
  ///
  /// [savedReportId] is only ever used to key the server-side cache more
  /// stably than a definition fingerprint when [definition] belongs to a
  /// `SavedReport` (TASK-145, e.g. explaining it from "Meus relatórios") —
  /// omitted (`null`) for an ad-hoc report still being built in the
  /// construtor (TASK-144). It is never itself a source of authorization:
  /// the server always re-validates access from [definition]'s own
  /// dimensions/metrics/filters and the caller's live role/tenant scope,
  /// regardless of what this id references.
  Future<AppResult<ReportExplanation>> explain({
    required ReportDefinition definition,
    String? savedReportId,
  });
}
