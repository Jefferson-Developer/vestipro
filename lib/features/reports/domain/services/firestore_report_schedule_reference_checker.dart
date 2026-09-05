import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../repositories/report_schedule_repository.dart';
import 'report_schedule_reference_checker.dart';

/// [ReportScheduleReferenceChecker] backed by the real
/// [ReportScheduleRepository] (TASK-149) — replaces the TASK-145-era
/// placeholder that always resolved `false` before any `ReportSchedule`
/// collection existed.
@LazySingleton(as: ReportScheduleReferenceChecker)
final class FirestoreReportScheduleReferenceChecker
    implements ReportScheduleReferenceChecker {
  const FirestoreReportScheduleReferenceChecker(this._repository);

  final ReportScheduleRepository _repository;

  @override
  Future<AppResult<bool>> hasActiveScheduleReferencing({
    required String organizationId,
    required String savedReportId,
  }) => _repository.hasActiveScheduleReferencing(
    organizationId: organizationId,
    savedReportId: savedReportId,
  );
}
