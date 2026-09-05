import '../../../../core/utils/utils.dart';
import '../entities/report_schedule.dart';

/// Domain contract for `organizations/{organizationId}/reportSchedules`
/// (TASK-149) — periodic, automated delivery of a `SavedReport`
/// (TASK-145).
abstract interface class ReportScheduleRepository {
  /// Every [ReportSchedule] configured in [organizationId]/[companyId],
  /// regardless of who created it — the management screen this backs
  /// (TASK-149's "tela mínima de gestão de agendamentos") is only reachable
  /// by a holder of [Capability.reportSchedule] in the first place, so no
  /// further per-row ownership filter is applied here.
  Future<AppResult<List<ReportSchedule>>> listByOrganization({
    required String organizationId,
    required String companyId,
  });

  Future<AppResult<ReportSchedule>> create(ReportSchedule schedule);

  Future<AppResult<ReportSchedule>> update(ReportSchedule schedule);

  Future<AppResult<void>> delete({
    required String organizationId,
    required String scheduleId,
  });

  /// Whether at least one [ReportSchedule.status] ==
  /// [ReportScheduleStatus.active] in [organizationId] still references
  /// [savedReportId] — consulted by `DeleteSavedReport` (TASK-145) so
  /// removing a saved view never silently breaks a dependent schedule.
  Future<AppResult<bool>> hasActiveScheduleReferencing({
    required String organizationId,
    required String savedReportId,
  });
}
