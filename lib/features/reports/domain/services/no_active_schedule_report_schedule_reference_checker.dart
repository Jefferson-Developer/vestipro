import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import 'report_schedule_reference_checker.dart';

/// Placeholder [ReportScheduleReferenceChecker] until TASK-149 (agendamento
/// de relatórios) ships its own `ReportSchedule` repository — see that
/// interface's docs for why always resolving `false` is correct, not just
/// convenient, while no schedule can exist yet.
@LazySingleton(as: ReportScheduleReferenceChecker)
final class NoActiveScheduleReportScheduleReferenceChecker
    implements ReportScheduleReferenceChecker {
  const NoActiveScheduleReportScheduleReferenceChecker();

  @override
  Future<AppResult<bool>> hasActiveScheduleReferencing(
    String savedReportId,
  ) async => const AppSuccess<bool>(false);
}
