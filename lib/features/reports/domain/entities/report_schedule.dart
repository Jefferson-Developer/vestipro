import 'report_definition.dart';
import 'report_export_result.dart';

/// How often a [ReportSchedule] (TASK-149) re-executes and delivers its
/// referenced [ReportDefinition] (via its `SavedReport`, TASK-145).
enum ReportScheduleFrequency { daily, weekly, monthly }

extension ReportScheduleFrequencyCode on ReportScheduleFrequency {
  String get code => name;

  static ReportScheduleFrequency fromCode(String code) =>
      ReportScheduleFrequency.values.byName(code);
}

/// Whether a [ReportSchedule] currently fires ([active]) or is temporarily
/// suspended without losing its configuration ([paused]) — the two states
/// the "tela mínima de gestão de agendamentos" (TASK-149) toggles between.
enum ReportScheduleStatus { active, paused }

extension ReportScheduleStatusCode on ReportScheduleStatus {
  String get code => name;

  static ReportScheduleStatus fromCode(String code) =>
      ReportScheduleStatus.values.byName(code);
}

/// Outcome of the most recent `runReportSchedules` Cloud Function cycle for
/// one [ReportSchedule] — always visible to [ReportSchedule.createdBy], never
/// only logged server-side (TASK-149's "Falha de execução é visível ao
/// responsável, nunca silenciosa").
enum ReportScheduleRunStatus { success, partialFailure, failure }

extension ReportScheduleRunStatusCode on ReportScheduleRunStatus {
  String get code => name;

  static ReportScheduleRunStatus fromCode(String code) =>
      ReportScheduleRunStatus.values.byName(code);
}

/// Periodic, automated delivery of a `SavedReport` (TASK-145) — modeled at
/// `organizations/{organizationId}/reportSchedules/{scheduleId}` (TASK-149).
///
/// Only ever references a `SavedReport` by [savedReportId]/[savedReportName]
/// (the latter a denormalized label so the management screen never needs an
/// extra read per row) — never a copy of its `ReportDefinition`: every cycle
/// the `runReportSchedules` Cloud Function re-reads the `SavedReport` and
/// re-executes the aggregation, exactly like every other report surface in
/// this feature (TASK-144/TASK-145/TASK-146/TASK-147/TASK-148) never trusts a
/// cached query result.
///
/// [recipientUserIds] are always members of [organizationId] — the Cloud
/// Function independently re-validates each recipient's own current role at
/// send time ("Agendamento com dado financeiro sensível respeita o RBAC do
/// destinatário no momento do envio, não o RBAC de quem criou o
/// agendamento", TASK-149), so a role downgrade after this schedule was
/// created silently and safely narrows what a recipient receives on the
/// very next cycle, with no separate reconciliation step required.
final class ReportSchedule {
  const ReportSchedule({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.savedReportId,
    required this.savedReportName,
    required this.frequency,
    this.weekday,
    this.dayOfMonth,
    required this.hour,
    required this.minute,
    required this.format,
    this.locale = ReportExportLocale.ptBr,
    required this.recipientUserIds,
    required this.status,
    required this.nextRunAt,
    this.lastRunAt,
    this.lastRunCycleKey,
    this.lastRunStatus,
    this.lastRunError,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.version = 1,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String savedReportId;
  final String savedReportName;
  final ReportScheduleFrequency frequency;

  /// ISO weekday (1 = segunda-feira .. 7 = domingo). Only meaningful — and
  /// always non-null — when [frequency] is [ReportScheduleFrequency.weekly].
  final int? weekday;

  /// Day of the month (1-28 — capped so every month, including fevereiro,
  /// always has a matching day; TASK-149 has no requirement for
  /// "último dia do mês" semantics yet). Only meaningful — and always
  /// non-null — when [frequency] is [ReportScheduleFrequency.monthly].
  final int? dayOfMonth;

  /// Hour/minute of day (0-23 / 0-59), always interpreted in
  /// `America/Sao_Paulo` wall-clock time (fixed UTC-3 — Brazil has not
  /// observed daylight saving time since 2019), same timezone every other
  /// scheduled Cloud Function in this codebase already runs in.
  final int hour;
  final int minute;

  final ReportExportFormat format;
  final ReportExportLocale locale;
  final List<String> recipientUserIds;
  final ReportScheduleStatus status;

  /// The next instant (UTC) `runReportSchedules` is due to execute this
  /// schedule — always strictly in the future once a cycle has been
  /// claimed; see `ReportScheduleNextRunCalculator`.
  final DateTime nextRunAt;

  final DateTime? lastRunAt;

  /// Identifies which scheduled cycle [lastRunAt]/[lastRunStatus] refer to
  /// (`nextRunAt.toIso8601String()` at the moment it was claimed) — the
  /// idempotency guard a Cloud Scheduler retry checks before ever generating
  /// a second delivery for the same cycle.
  final String? lastRunCycleKey;
  final ReportScheduleRunStatus? lastRunStatus;
  final String? lastRunError;

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  bool get isActive => status == ReportScheduleStatus.active;

  ReportSchedule copyWith({
    ReportScheduleStatus? status,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    String? lastRunCycleKey,
    ReportScheduleRunStatus? lastRunStatus,
    String? lastRunError,
    bool clearLastRunError = false,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
  }) => ReportSchedule(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    savedReportId: savedReportId,
    savedReportName: savedReportName,
    frequency: frequency,
    weekday: weekday,
    dayOfMonth: dayOfMonth,
    hour: hour,
    minute: minute,
    format: format,
    locale: locale,
    recipientUserIds: recipientUserIds,
    status: status ?? this.status,
    nextRunAt: nextRunAt ?? this.nextRunAt,
    lastRunAt: lastRunAt ?? this.lastRunAt,
    lastRunCycleKey: lastRunCycleKey ?? this.lastRunCycleKey,
    lastRunStatus: lastRunStatus ?? this.lastRunStatus,
    lastRunError: clearLastRunError ? null : lastRunError ?? this.lastRunError,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    version: version ?? this.version,
  );
}
