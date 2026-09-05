import '../../../../core/utils/utils.dart';

/// Whether a [SavedReport] (TASK-145) is still referenced by at least one
/// active `ReportSchedule` (TASK-149) — consulted by `DeleteSavedReport` so
/// removing a saved view never silently breaks a schedule that depends on
/// it (`tasks.md`, seção "Regras de negócio e restrições" da TASK-145).
///
/// [FirestoreReportScheduleReferenceChecker] is the only implementation
/// registered today, delegating to [ReportScheduleRepository
/// .hasActiveScheduleReferencing]. [organizationId] is accepted explicitly
/// (rather than resolved from [savedReportId] alone) because
/// `DeleteSavedReport`'s caller always already has it on hand
/// (`SavedReport.organizationId`) and a tenant-scoped subcollection query is
/// simpler and safer than a cross-tenant `collectionGroup` lookup.
abstract interface class ReportScheduleReferenceChecker {
  Future<AppResult<bool>> hasActiveScheduleReferencing({
    required String organizationId,
    required String savedReportId,
  });
}
