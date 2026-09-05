import '../../../../core/utils/utils.dart';

/// Whether a [SavedReport] (TASK-145) is still referenced by at least one
/// active scheduled export (TASK-149, not implemented yet) — consulted by
/// `DeleteSavedReport` so removing a saved view never silently breaks a
/// schedule that depends on it (`tasks.md`, seção "Regras de negócio e
/// restrições" da TASK-145).
///
/// [NoActiveScheduleReportScheduleReferenceChecker] is the only
/// implementation registered today: since TASK-149 does not exist yet, no
/// `ReportSchedule` collection exists for any saved report to be referenced
/// by, so it always resolves `false`. TASK-149 must replace this binding
/// with a real check against its own repository — `DeleteSavedReport`
/// itself never needs to change once that happens.
abstract interface class ReportScheduleReferenceChecker {
  Future<AppResult<bool>> hasActiveScheduleReferencing(String savedReportId);
}
