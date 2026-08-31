import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../connectivity/connectivity_service.dart';
import 'entities/sync_cycle_report.dart';
import 'sync_engine.dart';

/// Drives [SyncEngine] in the background, without blocking the UI
/// (TASK-109, EPIC-14): a cycle is triggered when connectivity is regained
/// and periodically while [start] is active, plus on demand via
/// [triggerNow].
///
/// ## Wiring (extension point for TASK-112/TASK-113)
///
/// Nothing in `lib/app/bootstrap.dart` calls [start]/[stop] yet — this class
/// does not know what the "currently active organization/company" is on its
/// own (that is session/navigation state, resolved elsewhere, e.g.
/// `ResolveActiveOrganizationIdUseCase`). The intended caller is whatever
/// owns that session lifecycle once it exists as a listenable app-level
/// concern: call [start] right after an organization/company becomes
/// active, [stop] on sign-out or organization switch. The Central de
/// Sincronização (TASK-112) is the most natural place to also expose a
/// manual "sincronizar agora" action backed by [triggerNow], and the
/// connectivity indicator (TASK-113) is expected to reuse the same
/// [ConnectivityService] this class already depends on rather than a second
/// subscription.
///
/// "Foreground" here means "the app process is alive and this scheduler is
/// running" — there is no background-execution plugin
/// (e.g. `workmanager`) wired in this project, so a sync cycle only runs
/// while the app itself is running, exactly like every other Bloc/Cubit in
/// this codebase.
@lazySingleton
final class SyncScheduler {
  SyncScheduler(this._syncEngine, this._connectivityService);

  final SyncEngine _syncEngine;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicTimer;
  bool _isRunning = false;
  bool _wasConnected = true;

  String? _organizationId;
  String? _companyId;

  /// Whether [start] has been called without a matching [stop] yet.
  bool get isActive => _organizationId != null;

  /// Starts driving [SyncEngine] for [organizationId]/[companyId]: triggers
  /// one cycle immediately, then again whenever [ConnectivityService]
  /// reports connectivity was regained, and at least once every
  /// [periodicInterval] while active. Calling this again (e.g. after an
  /// organization switch) replaces the previous scope and its
  /// subscriptions rather than stacking a second set.
  void start({
    required String organizationId,
    required String companyId,
    Duration periodicInterval = const Duration(minutes: 15),
  }) {
    // Cancels the previous subscription/timer, if any, without awaiting
    // them: `stop()` itself is `async` (its first line is already an
    // `await`), so calling it with `unawaited` here would let its body
    // resume on a later microtask and clear the scope this method is about
    // to set below, right out from under it. `Timer.cancel` is synchronous
    // and `StreamSubscription.cancel` is safe to fire-and-forget — a
    // still-in-flight cancellation of the old subscription can never
    // deliver another event once a new one replaces it below.
    final previousSubscription = _connectivitySubscription;
    if (previousSubscription != null) unawaited(previousSubscription.cancel());
    _periodicTimer?.cancel();

    _organizationId = organizationId;
    _companyId = companyId;
    _wasConnected = true;

    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected && !_wasConnected) {
            unawaited(triggerNow());
          }
          _wasConnected = isConnected;
        });

    _periodicTimer = Timer.periodic(
      periodicInterval,
      (_) => unawaited(triggerNow()),
    );

    unawaited(triggerNow());
  }

  /// Stops every subscription/timer started by [start] and clears the
  /// active scope — a subsequent [triggerNow] call becomes a no-op until
  /// [start] is called again.
  Future<void> stop() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _organizationId = null;
    _companyId = null;
  }

  /// Runs one [SyncEngine.runFullCycle] for the scope passed to [start], or
  /// does nothing (`null`) if [start] was never called, [stop] was already
  /// called, or a cycle is already running — a sync cycle from this
  /// scheduler never overlaps itself.
  Future<SyncCycleReport?> triggerNow() async {
    final organizationId = _organizationId;
    final companyId = _companyId;
    if (organizationId == null || companyId == null) return null;
    if (_isRunning) return null;

    _isRunning = true;
    try {
      return await _syncEngine.runFullCycle(
        organizationId: organizationId,
        companyId: companyId,
      );
    } finally {
      _isRunning = false;
    }
  }
}
