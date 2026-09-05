import '../../../../core/utils/utils.dart';
import '../entities/saved_report.dart';

/// Domain contract for `organizations/{organizationId}/savedReports`
/// (TASK-145) — the metadata-only persistence of a saved
/// `ReportDefinition` (TASK-144). Never reads/writes `ReportQueryResult`
/// data: re-execution is always a fresh `ExecuteReportQuery` call.
abstract interface class SavedReportRepository {
  /// Every non-deleted [SavedReport] owned by [userId] in [organizationId]/
  /// [companyId], regardless of [SavedReport.visibility].
  Future<AppResult<List<SavedReport>>> listOwned({
    required String organizationId,
    required String companyId,
    required String userId,
  });

  /// Every [SavedReport] in [organizationId]/[companyId] shared with
  /// [userId] by someone else — `visibility == organization`, or
  /// `visibility == team` when [teamIds] overlaps the owner's own teams.
  /// Never includes a [SavedReport] owned by [userId] (use [listOwned] for
  /// those, even when shared).
  Future<AppResult<List<SavedReport>>> listSharedWithMe({
    required String organizationId,
    required String companyId,
    required String userId,
    required List<String> teamIds,
  });

  Future<AppResult<SavedReport>> create(SavedReport report);

  Future<AppResult<SavedReport>> update(SavedReport report);

  Future<AppResult<void>> delete({
    required String organizationId,
    required String reportId,
  });
}
