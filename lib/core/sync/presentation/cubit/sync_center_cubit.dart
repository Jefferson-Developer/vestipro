import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../analytics/analytics.dart';
import '../../../connectivity/connectivity_service.dart';
import '../../../offline/domain/repositories/offline_package_status_repository.dart';
import '../../../services/services.dart';
import '../../domain/entities/outbox_entity_type.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/outbox_status.dart';
import '../../domain/entities/outbox_summary.dart';
import '../../domain/repositories/conflict_record_repository.dart';
import '../../domain/repositories/outbox_repository.dart';
import '../../domain/sync_engine.dart';
import 'sync_center_state.dart';

/// Aggregates every signal the Central de Sincronização (TASK-112, EPIC-14)
/// shows for one `organizationId`/`companyId` scope: the reactive Outbox
/// summary (TASK-108), the detailed list of `failed` operations with a
/// legible retry action, how many conflicts are open (TASK-110/TASK-111),
/// the "última carga completa" marker per entity (TASK-107) and device
/// connectivity — plus the manual "Sincronizar agora"/"Tentar novamente"
/// actions that drive `SyncEngine` (TASK-109) on demand, independently of
/// `SyncScheduler`'s own automatic/periodic cadence.
@injectable
final class SyncCenterCubit extends Cubit<SyncCenterState> {
  SyncCenterCubit(
    this._outboxRepository,
    this._conflictRecordRepository,
    this._offlinePackageStatusRepository,
    this._connectivityService,
    this._syncEngine,
    this._analyticsService,
    this._crashReporter,
  ) : super(const SyncCenterState());

  final OutboxRepository _outboxRepository;
  final ConflictRecordRepository _conflictRecordRepository;
  final OfflinePackageStatusRepository _offlinePackageStatusRepository;
  final ConnectivityService _connectivityService;
  final SyncEngine _syncEngine;
  final AnalyticsService _analyticsService;
  final CrashReporter _crashReporter;

  StreamSubscription<OutboxSummary>? _outboxSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  /// `OutboxOperation.id`s already reported to Crashlytics as "shown to the
  /// user" (see [_reportNewFailures]) — cleared of any id that stops being
  /// `failed`, so a later new failure of the same operation is reported
  /// again as its own incident.
  final Set<String> _reportedFailureIds = <String>{};

  /// Loads every section of the screen for [organizationId]/[companyId] and
  /// starts watching the Outbox summary and device connectivity for as long
  /// as this cubit is alive. Calling this again (e.g. a pull-to-refresh)
  /// replaces the previous subscriptions instead of stacking new ones.
  Future<void> load({
    required String organizationId,
    required String companyId,
  }) async {
    emit(
      state.copyWith(
        loadStatus: SyncCenterLoadStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        clearFailure: true,
      ),
    );

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.syncCenterOpened,
        parameters: <String, Object?>{
          'organization_id': organizationId,
          'company_id': companyId,
        },
      ),
    );

    unawaited(_outboxSubscription?.cancel());
    _outboxSubscription = _outboxRepository
        .watchSummary(organizationId: organizationId)
        .listen((summary) {
          if (isClosed) return;
          emit(state.copyWith(outboxSummary: summary));
        });

    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isOnline) {
          if (isClosed) return;
          emit(state.copyWith(isOnline: isOnline));
        });
    final isOnlineNow = await _connectivityService.isConnected;
    if (isClosed) return;
    emit(state.copyWith(isOnline: isOnlineNow));

    await _refreshDetails();
  }

  /// Re-fetches every non-reactive section (failed operations, open
  /// conflict count, per-entity last-load marker) without touching the
  /// reactive [SyncCenterState.outboxSummary] subscription — called after
  /// [syncNow]/[retryOperation]/[retryAllFailed] and by a pull-to-refresh.
  Future<void> refresh() => _refreshDetails();

  Future<void> _refreshDetails() async {
    final organizationId = state.organizationId;
    final companyId = state.companyId;

    final failedResult = await _outboxRepository.listByStatus(
      organizationId: organizationId,
      statuses: const <OutboxStatus>[OutboxStatus.failed],
    );
    final conflictsResult = await _conflictRecordRepository.listOpen(
      organizationId: organizationId,
    );
    final entityStatusesResult = await _offlinePackageStatusRepository.getAll(
      organizationId: organizationId,
      companyId: companyId,
    );

    if (isClosed) return;

    final failedOperations = failedResult.fold(
      onSuccess: (value) => value,
      onFailure: (_) => state.failedOperations,
    );
    _reportNewFailures(failedOperations);

    final loadFailure = failedResult.fold(
      onSuccess: (_) => null,
      onFailure: (failure) => failure,
    );

    emit(
      state.copyWith(
        loadStatus: SyncCenterLoadStatus.ready,
        failedOperations: failedOperations,
        openConflictCount: conflictsResult.fold(
          onSuccess: (value) => value.length,
          onFailure: (_) => state.openConflictCount,
        ),
        entityStatuses: entityStatusesResult.fold(
          onSuccess: (value) => value,
          onFailure: (_) => state.entityStatuses,
        ),
        failure: loadFailure,
        clearFailure: loadFailure == null,
      ),
    );
  }

  /// "Sincronizar agora": runs a full push+pull `SyncEngine` cycle on
  /// demand. A no-op while offline (no attempt is ever made until
  /// reconnection — TASK-112's own restriction) or while a cycle is already
  /// running, so this can never be triggered twice concurrently regardless
  /// of how many times the UI calls it.
  Future<void> syncNow() async {
    if (state.isSyncing || !state.isOnline) return;
    if (state.organizationId.isEmpty || state.companyId.isEmpty) return;

    emit(state.copyWith(isSyncing: true));
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.syncManualRetryTriggered,
        parameters: <String, Object?>{'scope': 'full_cycle'},
      ),
    );

    final now = DateTime.now().toUtc();
    final report = await _syncEngine.runFullCycle(
      organizationId: state.organizationId,
      companyId: state.companyId,
    );
    if (isClosed) return;

    emit(
      state.copyWith(
        isSyncing: false,
        lastManualCycleReport: report,
        lastManualCycleAt: now,
      ),
    );
    await _refreshDetails();
  }

  /// "Tentar novamente" for one specific `failed` operation [operationId] —
  /// moves it back to `pending` ([OutboxRepository.retryFailed]) and runs a
  /// push pass so it is attempted immediately, without waiting for the next
  /// scheduled/connectivity-triggered cycle.
  Future<void> retryOperation(String operationId) async {
    if (!state.isOnline) return;
    if (state.retryingOperationIds.contains(operationId)) return;

    emit(
      state.copyWith(
        retryingOperationIds: <String>{
          ...state.retryingOperationIds,
          operationId,
        },
      ),
    );
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.syncManualRetryTriggered,
        parameters: <String, Object?>{'scope': 'single_operation'},
      ),
    );

    await _outboxRepository.retryFailed(
      id: operationId,
      requestedAt: DateTime.now().toUtc(),
    );
    await _syncEngine.runPush(organizationId: state.organizationId);
    if (isClosed) return;

    emit(
      state.copyWith(
        retryingOperationIds: state.retryingOperationIds
            .where((id) => id != operationId)
            .toSet(),
      ),
    );
    await _refreshDetails();
  }

  /// "Tentar novamente todos": retries every currently `failed` operation in
  /// one push pass — a no-op while offline, while a cycle is already
  /// running or when there is nothing `failed` to retry.
  Future<void> retryAllFailed() async {
    if (state.isSyncing || !state.isOnline || !state.hasFailures) return;

    emit(state.copyWith(isSyncing: true));
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.syncManualRetryTriggered,
        parameters: <String, Object?>{
          'scope': 'all_failed',
          'count': state.failedOperations.length,
        },
      ),
    );

    final requestedAt = DateTime.now().toUtc();
    for (final operation in state.failedOperations) {
      await _outboxRepository.retryFailed(
        id: operation.id,
        requestedAt: requestedAt,
      );
    }
    await _syncEngine.runPush(organizationId: state.organizationId);
    if (isClosed) return;

    emit(state.copyWith(isSyncing: false));
    await _refreshDetails();
  }

  /// Enriches Crashlytics with every [failedOperations] row not yet reported
  /// (TASK-112's own restriction: "enriquecer Crashlytics/logs quando uma
  /// falha de sincronização é exibida ao usuário") — never the raw
  /// `lastError` itself, just enough to locate the incident (entity type and
  /// operation id) since the raw error may already have been recorded by
  /// `SyncEngine` when the failure first happened.
  void _reportNewFailures(List<OutboxOperation> failedOperations) {
    final currentIds = failedOperations
        .map((operation) => operation.id)
        .toSet();
    final newIds = currentIds.difference(_reportedFailureIds);

    for (final operation in failedOperations) {
      if (!newIds.contains(operation.id)) continue;
      unawaited(
        _crashReporter.recordError(
          StateError(
            'Outbox operation ${operation.id} '
            '(${operation.entityType.code}) is now shown as failed in the '
            'Central de Sincronização.',
          ),
          StackTrace.current,
          reason: 'SyncCenterCubit: failure surfaced to user',
        ),
      );
    }

    _reportedFailureIds
      ..clear()
      ..addAll(currentIds);
  }

  @override
  Future<void> close() {
    unawaited(_outboxSubscription?.cancel());
    unawaited(_connectivitySubscription?.cancel());
    return super.close();
  }
}
