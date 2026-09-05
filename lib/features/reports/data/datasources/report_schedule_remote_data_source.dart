import '../dtos/report_schedule_dto.dart';

/// Raw Firestore access for `organizations/{organizationId}/reportSchedules`
/// (TASK-149) — never exposed outside `data/`; `ReportScheduleRepositoryImpl`
/// is the only caller.
abstract interface class ReportScheduleRemoteDataSource {
  Future<List<ReportScheduleDto>> listByOrganization({
    required String organizationId,
    required String companyId,
  });

  /// Every [ReportScheduleDto] in [organizationId] whose `status == active`
  /// and `savedReportId == savedReportId` — used only to answer "does at
  /// least one active schedule still reference this saved report",
  /// deliberately unbounded by [companyId] since a `SavedReportId` is only
  /// ever referenced within the single company it was created for anyway.
  Future<List<ReportScheduleDto>> listActiveBySavedReportId({
    required String organizationId,
    required String savedReportId,
  });

  Future<void> create(ReportScheduleDto dto);

  Future<void> update(ReportScheduleDto dto);

  Future<void> delete({required String organizationId, required String id});
}
