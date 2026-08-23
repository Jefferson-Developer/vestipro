import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/audit_log_entry_page.dart';
import '../../domain/usecases/list_audit_log_entries_use_case.dart';
import 'audit_log_action_filter.dart';
import 'audit_log_event.dart';
import 'audit_log_state.dart';

final class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  AuditLogBloc({required this.listAuditLogEntries})
    : super(const AuditLogState()) {
    on<AuditLogStarted>(_onStarted, transformer: restartable());
    on<AuditLogRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<AuditLogLoadMoreRequested>(
      _onLoadMoreRequested,
      transformer: droppable(),
    );
    on<AuditLogActorFilterChanged>(
      _onActorFilterChanged,
      transformer: restartable(),
    );
    on<AuditLogActionFilterChanged>(
      _onActionFilterChanged,
      transformer: restartable(),
    );
    on<AuditLogPeriodFilterChanged>(
      _onPeriodFilterChanged,
      transformer: restartable(),
    );
    on<AuditLogTextFiltersApplied>(
      _onTextFiltersApplied,
      transformer: restartable(),
    );
    on<AuditLogFiltersCleared>(_onFiltersCleared, transformer: restartable());
  }

  final ListAuditLogEntriesUseCase listAuditLogEntries;

  Future<void> _onStarted(
    AuditLogStarted event,
    Emitter<AuditLogState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      organizationId: event.organizationId,
      userId: event.userId,
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _onRefreshRequested(
    AuditLogRefreshRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.userId.isEmpty) return;
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _onLoadMoreRequested(
    AuditLogLoadMoreRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    if (!state.hasMore ||
        state.isLoadingNextPage ||
        state.nextCursor == null ||
        state.organizationId.isEmpty ||
        state.userId.isEmpty) {
      return;
    }

    final request = state.copyWith(
      isLoadingNextPage: true,
      clearLoadFailure: true,
    );
    emit(request);

    final result = await _fetchPage(request, before: request.nextCursor);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<AuditLogEntryPage>(value: final page):
        final seenIds = state.entries.map((entry) => entry.id).toSet();
        final mergedEntries = [
          ...state.entries,
          for (final entry in page.entries)
            if (seenIds.add(entry.id)) entry,
        ];
        emit(
          state.copyWith(
            loadStatus: AuditLogLoadStatus.ready,
            entries: mergedEntries,
            hasMore: page.hasMore,
            isLoadingNextPage: false,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<AuditLogEntryPage>(failure: final failure):
        emit(state.copyWith(isLoadingNextPage: false, loadFailure: failure));
    }
  }

  Future<void> _onActorFilterChanged(
    AuditLogActorFilterChanged event,
    Emitter<AuditLogState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      actorUserId: event.actorUserId.trim(),
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _onActionFilterChanged(
    AuditLogActionFilterChanged event,
    Emitter<AuditLogState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      actionFilter: event.filter,
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearActionFilter: event.filter == null,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _onPeriodFilterChanged(
    AuditLogPeriodFilterChanged event,
    Emitter<AuditLogState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      from: event.from,
      to: event.to,
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearPeriod: event.from == null && event.to == null,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _onTextFiltersApplied(
    AuditLogTextFiltersApplied event,
    Emitter<AuditLogState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      actorUserId: event.actorUserId.trim(),
      from: event.from,
      to: event.to,
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearPeriod: event.from == null && event.to == null,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _onFiltersCleared(
    AuditLogFiltersCleared event,
    Emitter<AuditLogState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: AuditLogLoadStatus.loading,
      actorUserId: '',
      entries: const [],
      hasMore: false,
      isLoadingNextPage: false,
      clearActionFilter: true,
      clearPeriod: true,
      clearNextCursor: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadFirstPage(next, emit);
  }

  Future<void> _loadFirstPage(
    AuditLogState request,
    Emitter<AuditLogState> emit,
  ) async {
    final result = await _fetchPage(request);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<AuditLogEntryPage>(value: final page):
        emit(
          state.copyWith(
            loadStatus: AuditLogLoadStatus.ready,
            entries: page.entries,
            hasMore: page.hasMore,
            isLoadingNextPage: false,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<AuditLogEntryPage>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: AuditLogLoadStatus.failure,
            entries: const [],
            hasMore: false,
            isLoadingNextPage: false,
            loadFailure: failure,
            clearNextCursor: true,
          ),
        );
    }
  }

  Future<AppResult<AuditLogEntryPage>> _fetchPage(
    AuditLogState request, {
    DateTime? before,
  }) {
    return listAuditLogEntries(
      organizationId: request.organizationId,
      requestedByUserId: request.userId,
      limit: kAuditLogPageSize,
      before: before,
      from: request.from,
      to: request.to,
      actions: request.actionFilter?.actions ?? const {},
      actorUserId: request.actorUserId,
    );
  }
}
