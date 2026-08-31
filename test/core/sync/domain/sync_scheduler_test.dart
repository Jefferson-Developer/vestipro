import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/connectivity/connectivity_service.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/services/services.dart';
import 'package:vestipro/core/sync/sync.dart';

class _FakeConnectivityService implements ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _connected = true;

  void emit(bool connected) {
    _connected = connected;
    _controller.add(connected);
  }

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void dispose() => _controller.close();
}

class _NoopCrashReporter implements CrashReporter {
  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> setUserIdentifier(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// [SyncScheduler] only orchestrates *when* a cycle runs, never its
/// push/pull logic (covered by `sync_engine_test.dart`) — so these tests use
/// a real [SyncEngine] with no push handlers/pull sources (never touches
/// Firestore) and count completed cycles indirectly through
/// [FakeAnalyticsService.loggedEvents], since [SyncEngine.runPush]/`runPull`
/// unconditionally log a `sync_push_completed`/`sync_pull_completed` event
/// every time they run, even with nothing to do.
void main() {
  group('SyncScheduler', () {
    late AppDatabase database;
    late FakeAnalyticsService analyticsService;
    late SyncEngine engine;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      analyticsService = FakeAnalyticsService();
      engine = SyncEngine(
        DriftOutboxRepository(database),
        DriftSyncCursorRepository(database),
        const [],
        const [],
        analyticsService,
        _NoopCrashReporter(),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('triggerNow is a no-op before start is called', () async {
      final connectivity = _FakeConnectivityService();
      addTearDown(connectivity.dispose);
      final scheduler = SyncScheduler(engine, connectivity);

      final result = await scheduler.triggerNow();

      expect(result, isNull);
      expect(scheduler.isActive, isFalse);
      expect(analyticsService.loggedEvents, isEmpty);
    });

    test(
      'start triggers an immediate cycle and marks the scheduler active',
      () async {
        final connectivity = _FakeConnectivityService();
        addTearDown(connectivity.dispose);
        final scheduler = SyncScheduler(engine, connectivity);
        addTearDown(scheduler.stop);

        scheduler.start(organizationId: 'org-1', companyId: 'company-1');
        expect(scheduler.isActive, isTrue);

        await pumpEventQueue();

        expect(
          analyticsService.loggedEvents.map((event) => event.name),
          containsAll(<String>[
            AnalyticsEvents.syncPushCompleted,
            AnalyticsEvents.syncPullCompleted,
          ]),
        );
      },
    );

    test('reconnecting after being offline triggers a new cycle', () {
      fakeAsync((async) {
        final connectivity = _FakeConnectivityService();
        final scheduler = SyncScheduler(engine, connectivity);

        scheduler.start(
          organizationId: 'org-1',
          companyId: 'company-1',
          // Long enough that only the connectivity edge triggers a second
          // cycle within this test's simulated time window.
          periodicInterval: const Duration(hours: 1),
        );
        async.flushMicrotasks();
        final eventsAfterStart = analyticsService.loggedEvents.length;
        expect(eventsAfterStart, greaterThan(0));

        connectivity.emit(false);
        async.flushMicrotasks();
        connectivity.emit(true);
        async.flushMicrotasks();

        expect(
          analyticsService.loggedEvents.length,
          greaterThan(eventsAfterStart),
        );

        unawaited(scheduler.stop());
        connectivity.dispose();
      });
    });

    test('a periodic tick triggers another cycle without a reconnect edge', () {
      fakeAsync((async) {
        final connectivity = _FakeConnectivityService();
        final scheduler = SyncScheduler(engine, connectivity);

        scheduler.start(
          organizationId: 'org-1',
          companyId: 'company-1',
          periodicInterval: const Duration(minutes: 15),
        );
        async.flushMicrotasks();
        final eventsAfterStart = analyticsService.loggedEvents.length;

        async.elapse(const Duration(minutes: 15));

        expect(
          analyticsService.loggedEvents.length,
          greaterThan(eventsAfterStart),
        );

        unawaited(scheduler.stop());
        connectivity.dispose();
      });
    });

    test(
      'stop cancels the periodic timer and connectivity subscription',
      () async {
        final connectivity = _FakeConnectivityService();
        addTearDown(connectivity.dispose);
        final scheduler = SyncScheduler(engine, connectivity);

        scheduler.start(organizationId: 'org-1', companyId: 'company-1');
        await pumpEventQueue();
        expect(scheduler.isActive, isTrue);

        await scheduler.stop();
        expect(scheduler.isActive, isFalse);

        final result = await scheduler.triggerNow();
        expect(result, isNull);
      },
    );
  });
}
