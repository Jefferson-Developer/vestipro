import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_schedule.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/reportSchedules/{id}` (TASK-149).
///
/// [id] comes from the document id and is never serialized inside [toJson].
/// [organizationId]/[companyId] stay duplicated in the payload so
/// `firestore.rules` and queries never have to trust a client value out of
/// band from the document itself, same convention as [SavedReportDto].
final class ReportScheduleDto {
  const ReportScheduleDto({
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
    required this.locale,
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
    required this.version,
  });

  factory ReportScheduleDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final savedReportId = json['savedReportId'];
    final savedReportName = json['savedReportName'];
    final frequency = json['frequency'];
    final hour = json['hour'];
    final minute = json['minute'];
    final format = json['format'];
    final locale = json['locale'];
    final recipientUserIds = json['recipientUserIds'];
    final status = json['status'];
    final nextRunAt = json['nextRunAt'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];

    if (organizationId is! String ||
        companyId is! String ||
        savedReportId is! String ||
        savedReportName is! String ||
        frequency is! String ||
        hour is! int ||
        minute is! int ||
        format is! String ||
        locale is! String ||
        recipientUserIds is! List ||
        recipientUserIds.any((item) => item is! String) ||
        status is! String ||
        nextRunAt is! Timestamp ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int) {
      throw const ValidationException(
        'Invalid report schedule payload.',
        code: 'invalid_report_schedule_payload',
      );
    }

    final lastRunAt = json['lastRunAt'];
    final lastRunStatus = json['lastRunStatus'];

    return ReportScheduleDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      savedReportId: savedReportId,
      savedReportName: savedReportName,
      frequency: ReportScheduleFrequencyCode.fromCode(frequency),
      weekday: json['weekday'] as int?,
      dayOfMonth: json['dayOfMonth'] as int?,
      hour: hour,
      minute: minute,
      format: ReportExportFormat.values.byName(format),
      locale: _reportExportLocaleFromCode(locale),
      recipientUserIds: List<String>.unmodifiable(
        recipientUserIds.cast<String>(),
      ),
      status: ReportScheduleStatusCode.fromCode(status),
      nextRunAt: nextRunAt.toDate(),
      lastRunAt: lastRunAt is Timestamp ? lastRunAt.toDate() : null,
      lastRunCycleKey: json['lastRunCycleKey'] as String?,
      lastRunStatus: lastRunStatus is String
          ? ReportScheduleRunStatusCode.fromCode(lastRunStatus)
          : null,
      lastRunError: json['lastRunError'] as String?,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      version: version,
    );
  }

  factory ReportScheduleDto.fromEntity(ReportSchedule entity) =>
      ReportScheduleDto(
        id: entity.id,
        organizationId: entity.organizationId,
        companyId: entity.companyId,
        savedReportId: entity.savedReportId,
        savedReportName: entity.savedReportName,
        frequency: entity.frequency,
        weekday: entity.weekday,
        dayOfMonth: entity.dayOfMonth,
        hour: entity.hour,
        minute: entity.minute,
        format: entity.format,
        locale: entity.locale,
        recipientUserIds: entity.recipientUserIds,
        status: entity.status,
        nextRunAt: entity.nextRunAt,
        lastRunAt: entity.lastRunAt,
        lastRunCycleKey: entity.lastRunCycleKey,
        lastRunStatus: entity.lastRunStatus,
        lastRunError: entity.lastRunError,
        createdAt: entity.createdAt,
        createdBy: entity.createdBy,
        updatedAt: entity.updatedAt,
        updatedBy: entity.updatedBy,
        version: entity.version,
      );

  final String id;
  final String organizationId;
  final String companyId;
  final String savedReportId;
  final String savedReportName;
  final ReportScheduleFrequency frequency;
  final int? weekday;
  final int? dayOfMonth;
  final int hour;
  final int minute;
  final ReportExportFormat format;
  final ReportExportLocale locale;
  final List<String> recipientUserIds;
  final ReportScheduleStatus status;
  final DateTime nextRunAt;
  final DateTime? lastRunAt;
  final String? lastRunCycleKey;
  final ReportScheduleRunStatus? lastRunStatus;
  final String? lastRunError;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  ReportSchedule toEntity() => ReportSchedule(
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
    status: status,
    nextRunAt: nextRunAt,
    lastRunAt: lastRunAt,
    lastRunCycleKey: lastRunCycleKey,
    lastRunStatus: lastRunStatus,
    lastRunError: lastRunError,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
    version: version,
  );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'savedReportId': savedReportId,
      'savedReportName': savedReportName,
      'frequency': frequency.code,
      // Always present, even when `null` (weekday/dayOfMonth only apply to
      // one `frequency` each) — `firestore.rules`' `unchanged(field)` reads
      // `data[field]` with bracket notation, which errors on a genuinely
      // *missing* key, not on one whose value is `null`. Every field this
      // document's `update` rule guards with `unchanged(...)` is written
      // unconditionally for that same reason.
      'weekday': weekday,
      'dayOfMonth': dayOfMonth,
      'hour': hour,
      'minute': minute,
      'format': format.name,
      'locale': locale.code,
      'recipientUserIds': recipientUserIds,
      'status': status.code,
      'nextRunAt': Timestamp.fromDate(nextRunAt),
      'lastRunAt': lastRunAt == null ? null : Timestamp.fromDate(lastRunAt!),
      'lastRunCycleKey': lastRunCycleKey,
      'lastRunStatus': lastRunStatus?.code,
      'lastRunError': lastRunError,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
    };
  }
}

ReportExportLocale _reportExportLocaleFromCode(String code) =>
    ReportExportLocale.values.firstWhere(
      (value) => value.code == code,
      orElse: () => ReportExportLocale.ptBr,
    );
