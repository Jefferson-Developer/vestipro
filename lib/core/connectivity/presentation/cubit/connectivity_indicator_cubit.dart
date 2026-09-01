import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../analytics/analytics.dart';
import '../../../connectivity/connectivity_service.dart';
import '../../../sync/domain/entities/outbox_summary.dart';
import '../../../sync/domain/repositories/outbox_repository.dart';
import 'connectivity_indicator_state.dart';

/// Central aggregation for TASK-113: combines the device-level connectivity
/// signal with the tenant-scoped Outbox summary into one UI-ready state.
final class ConnectivityIndicatorCubit
    extends Cubit<ConnectivityIndicatorState> {
  ConnectivityIndicatorCubit(
    this._connectivityService,
    this._outboxRepository,
    this._analyticsService,
  ) : super(const ConnectivityIndicatorState());

  final ConnectivityService _connectivityService;
  final OutboxRepository _outboxRepository;
  final AnalyticsService _analyticsService;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<OutboxSummary>? _outboxSubscription;
  DateTime? _offlineStartedAtUtc;

  Future<void> watch({required String organizationId}) async {
    if (state.organizationId == organizationId) return;

    unawaited(_connectivitySubscription?.cancel());
    unawaited(_outboxSubscription?.cancel());

    emit(state.copyWith(organizationId: organizationId));

    _outboxSubscription = _outboxRepository
        .watchSummary(organizationId: organizationId)
        .listen(_handleOutboxSummaryChanged);

    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChanged);

    final isOnlineNow = await _connectivityService.isConnected;
    if (isClosed) return;
    _handleConnectivityChanged(isOnlineNow);
  }

  void _handleOutboxSummaryChanged(OutboxSummary summary) {
    if (isClosed) return;
    _emitAndTrack(state.copyWith(outboxSummary: summary));
  }

  void _handleConnectivityChanged(bool isOnline) {
    if (isClosed) return;
    _emitAndTrack(state.copyWith(isOnline: isOnline));
  }

  void _emitAndTrack(ConnectivityIndicatorState nextState) {
    final previousStatus = state.status;
    final nextStatus = nextState.status;
    final previousIsOnline = state.isOnline;

    emit(nextState);

    if (previousStatus == nextStatus &&
        previousIsOnline == nextState.isOnline) {
      return;
    }

    final now = DateTime.now().toUtc();
    int? offlineDurationMs;

    if (!previousIsOnline && nextState.isOnline) {
      final offlineStartedAtUtc = _offlineStartedAtUtc;
      if (offlineStartedAtUtc != null) {
        offlineDurationMs = now.difference(offlineStartedAtUtc).inMilliseconds;
      }
      _offlineStartedAtUtc = null;
    } else if (previousIsOnline && !nextState.isOnline) {
      _offlineStartedAtUtc = now;
    }

    final parameters = <String, Object?>{
      'organization_id': nextState.organizationId,
      'status': nextStatus.name,
      'previous_status': previousStatus.name,
      'is_online': nextState.isOnline,
      'pending_count': nextState.outboxSummary.pendingCount,
      'syncing_count': nextState.outboxSummary.syncingCount,
      'failed_count': nextState.outboxSummary.failedCount,
      'conflict_count': nextState.outboxSummary.conflictCount,
      'unsynced_count': nextState.outboxSummary.totalUnsyncedCount,
    };
    if (offlineDurationMs != null) {
      parameters['offline_duration_ms'] = offlineDurationMs;
    }

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.connectivityStatusChanged,
        parameters: parameters,
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_outboxSubscription?.cancel());
    return super.close();
  }
}
