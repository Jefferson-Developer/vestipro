import '../../../../core/errors/errors.dart';
import '../../domain/entities/audit_log_entry.dart';
import 'audit_log_action_filter.dart';

enum AuditLogLoadStatus { loading, ready, failure }

const int kAuditLogPageSize = 25;

final class AuditLogState {
  const AuditLogState({
    this.loadStatus = AuditLogLoadStatus.loading,
    this.organizationId = '',
    this.userId = '',
    this.entries = const <AuditLogEntry>[],
    this.hasMore = false,
    this.isLoadingNextPage = false,
    this.nextCursor,
    this.loadFailure,
    this.actorUserId = '',
    this.actionFilter,
    this.from,
    this.to,
  });

  final AuditLogLoadStatus loadStatus;
  final String organizationId;
  final String userId;
  final List<AuditLogEntry> entries;
  final bool hasMore;
  final bool isLoadingNextPage;
  final DateTime? nextCursor;
  final Failure? loadFailure;
  final String actorUserId;
  final AuditLogActionFilter? actionFilter;
  final DateTime? from;
  final DateTime? to;

  bool get hasActiveFilters =>
      actorUserId.trim().isNotEmpty ||
      actionFilter != null ||
      from != null ||
      to != null;

  AuditLogState copyWith({
    AuditLogLoadStatus? loadStatus,
    String? organizationId,
    String? userId,
    List<AuditLogEntry>? entries,
    bool? hasMore,
    bool? isLoadingNextPage,
    DateTime? nextCursor,
    Failure? loadFailure,
    String? actorUserId,
    AuditLogActionFilter? actionFilter,
    DateTime? from,
    DateTime? to,
    bool clearNextCursor = false,
    bool clearLoadFailure = false,
    bool clearActionFilter = false,
    bool clearPeriod = false,
  }) {
    return AuditLogState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      entries: entries ?? this.entries,
      hasMore: hasMore ?? this.hasMore,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      actorUserId: actorUserId ?? this.actorUserId,
      actionFilter: clearActionFilter
          ? null
          : actionFilter ?? this.actionFilter,
      from: clearPeriod ? null : from ?? this.from,
      to: clearPeriod ? null : to ?? this.to,
    );
  }
}
