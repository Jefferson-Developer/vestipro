import '../../../../core/errors/errors.dart';
import '../../domain/entities/report_schedule.dart';

enum ReportSchedulesStatus { initial, loading, ready, failure }

final class ReportSchedulesState {
  const ReportSchedulesState({
    this.status = ReportSchedulesStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.schedules = const <ReportSchedule>[],
    this.isMutating = false,
    this.failure,
    this.successMessage,
  });

  final ReportSchedulesStatus status;
  final String organizationId;
  final String companyId;
  final String userId;
  final List<ReportSchedule> schedules;

  /// `true` while a create/pause/delete call is in flight — the UI disables
  /// the triggering action to avoid a double-submit, never the whole list
  /// (same convention `SavedReportsState.isMutating` already uses).
  final bool isMutating;
  final Failure? failure;
  final String? successMessage;

  bool get isEmpty =>
      status == ReportSchedulesStatus.ready && schedules.isEmpty;

  ReportSchedulesState copyWith({
    ReportSchedulesStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    List<ReportSchedule>? schedules,
    bool? isMutating,
    Failure? failure,
    bool clearFailure = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) => ReportSchedulesState(
    status: status ?? this.status,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId ?? this.companyId,
    userId: userId ?? this.userId,
    schedules: schedules ?? this.schedules,
    isMutating: isMutating ?? this.isMutating,
    failure: clearFailure ? null : failure ?? this.failure,
    successMessage: clearSuccessMessage
        ? null
        : successMessage ?? this.successMessage,
  );
}
