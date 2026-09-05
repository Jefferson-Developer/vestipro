import '../dtos/saved_report_dto.dart';

abstract interface class SavedReportRemoteDataSource {
  Future<List<SavedReportDto>> listOwned({
    required String organizationId,
    required String companyId,
    required String userId,
  });

  /// Every non-`private` [SavedReportDto] in [organizationId]/[companyId] —
  /// filtering out [userId]'s own reports and the `team`-scoped ones that
  /// don't overlap [teamIds] is the caller's (`SavedReportRepositoryImpl`)
  /// responsibility, since Firestore cannot express that join client-side.
  Future<List<SavedReportDto>> listNonPrivate({
    required String organizationId,
    required String companyId,
  });

  Future<void> create(SavedReportDto dto);

  Future<void> update(SavedReportDto dto);

  Future<void> delete({required String organizationId, required String id});
}
