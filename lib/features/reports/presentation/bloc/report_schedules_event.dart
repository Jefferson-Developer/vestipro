import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_schedule.dart';
import '../../domain/entities/saved_report.dart';

sealed class ReportSchedulesEvent {
  const ReportSchedulesEvent();
}

final class ReportSchedulesStarted extends ReportSchedulesEvent {
  const ReportSchedulesStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class ReportSchedulesRetried extends ReportSchedulesEvent {
  const ReportSchedulesRetried();
}

/// Creates a new [ReportSchedule] for [savedReport] (TASK-149).
final class ReportScheduleCreateRequested extends ReportSchedulesEvent {
  const ReportScheduleCreateRequested({
    required this.savedReport,
    required this.frequency,
    this.weekday,
    this.dayOfMonth,
    required this.hour,
    required this.minute,
    required this.format,
    this.locale = ReportExportLocale.ptBr,
    required this.recipientUserIds,
  });

  final SavedReport savedReport;
  final ReportScheduleFrequency frequency;
  final int? weekday;
  final int? dayOfMonth;
  final int hour;
  final int minute;
  final ReportExportFormat format;
  final ReportExportLocale locale;
  final List<String> recipientUserIds;
}

final class ReportSchedulePauseRequested extends ReportSchedulesEvent {
  const ReportSchedulePauseRequested(this.schedule);

  final ReportSchedule schedule;
}

final class ReportScheduleDeleteRequested extends ReportSchedulesEvent {
  const ReportScheduleDeleteRequested(this.schedule);

  final ReportSchedule schedule;
}

final class ReportSchedulesMessageCleared extends ReportSchedulesEvent {
  const ReportSchedulesMessageCleared();
}
