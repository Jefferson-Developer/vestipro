import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/connectivity/connectivity.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('ConnectivityIndicatorCubit', () {
    test(
      'reports online synced when connected and without Outbox pendencies',
      () async {
        final connectivity = _FakeConnectivityService(initialIsConnected: true);
        final outbox = _FakeOutboxRepository();
        final analytics = FakeAnalyticsService();
        final cubit = ConnectivityIndicatorCubit(
          connectivity,
          outbox,
          analytics,
        );
        addTearDown(cubit.close);
        addTearDown(connectivity.dispose);
        addTearDown(outbox.dispose);

        await cubit.watch(organizationId: 'org-1');
        await pumpEventQueue();

        expect(cubit.state.status, ConnectivityIndicatorStatus.onlineSynced);
      },
    );

    test(
      'reports online syncing when connected and the Outbox has pendencies',
      () async {
        final connectivity = _FakeConnectivityService(initialIsConnected: true);
        final outbox = _FakeOutboxRepository();
        final analytics = FakeAnalyticsService();
        final cubit = ConnectivityIndicatorCubit(
          connectivity,
          outbox,
          analytics,
        );
        addTearDown(cubit.close);
        addTearDown(connectivity.dispose);
        addTearDown(outbox.dispose);

        await cubit.watch(organizationId: 'org-1');
        outbox.emit(const OutboxSummary(pendingCount: 2, syncingCount: 1));
        await pumpEventQueue();

        expect(cubit.state.status, ConnectivityIndicatorStatus.onlineSyncing);
        expect(cubit.state.outboxSummary.totalUnsyncedCount, 3);
      },
    );

    test(
      'reports offline pending when disconnected and the Outbox has pendencies',
      () async {
        final connectivity = _FakeConnectivityService(initialIsConnected: true);
        final outbox = _FakeOutboxRepository();
        final analytics = FakeAnalyticsService();
        final cubit = ConnectivityIndicatorCubit(
          connectivity,
          outbox,
          analytics,
        );
        addTearDown(cubit.close);
        addTearDown(connectivity.dispose);
        addTearDown(outbox.dispose);

        await cubit.watch(organizationId: 'org-1');
        outbox.emit(const OutboxSummary(failedCount: 1));
        connectivity.emit(false);
        await pumpEventQueue();

        expect(cubit.state.status, ConnectivityIndicatorStatus.offlinePending);
      },
    );

    test(
      'reports offline without pendencies when disconnected and Outbox is empty',
      () async {
        final connectivity = _FakeConnectivityService(
          initialIsConnected: false,
        );
        final outbox = _FakeOutboxRepository();
        final analytics = FakeAnalyticsService();
        final cubit = ConnectivityIndicatorCubit(
          connectivity,
          outbox,
          analytics,
        );
        addTearDown(cubit.close);
        addTearDown(connectivity.dispose);
        addTearDown(outbox.dispose);

        await cubit.watch(organizationId: 'org-1');
        await pumpEventQueue();

        expect(
          cubit.state.status,
          ConnectivityIndicatorStatus.offlineNoPending,
        );
      },
    );

    test(
      'logs connectivity_status_changed with offline duration when coming back online',
      () async {
        final connectivity = _FakeConnectivityService(initialIsConnected: true);
        final outbox = _FakeOutboxRepository();
        final analytics = FakeAnalyticsService();
        final cubit = ConnectivityIndicatorCubit(
          connectivity,
          outbox,
          analytics,
        );
        addTearDown(cubit.close);
        addTearDown(connectivity.dispose);
        addTearDown(outbox.dispose);

        await cubit.watch(organizationId: 'org-1');
        connectivity.emit(false);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        connectivity.emit(true);
        await pumpEventQueue();

        final logged = analytics.loggedEvents
            .where(
              (event) =>
                  event.name == AnalyticsEvents.connectivityStatusChanged,
            )
            .toList(growable: false);

        expect(logged, isNotEmpty);
        expect(
          logged.last.parameters?['status'],
          ConnectivityIndicatorStatus.onlineSynced.name,
        );
        expect(logged.last.parameters?['offline_duration_ms'], isA<int>());
      },
    );
  });
}

final class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({required this.initialIsConnected});

  final bool initialIsConnected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => initialIsConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void emit(bool isConnected) => _controller.add(isConnected);

  Future<void> dispose() => _controller.close();
}

final class _FakeOutboxRepository implements OutboxRepository {
  final StreamController<OutboxSummary> _controller =
      StreamController<OutboxSummary>.broadcast();

  @override
  Stream<OutboxSummary> watchSummary({required String organizationId}) {
    return _controller.stream;
  }

  void emit(OutboxSummary summary) => _controller.add(summary);

  Future<void> dispose() => _controller.close();

  @override
  Future<AppResult<OutboxOperation>> enqueue({
    required String id,
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required OutboxOperationType operationType,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<OutboxOperation>>> listByEntity({
    required String organizationId,
    required OutboxEntityType entityType,
    required String entityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<OutboxOperation>>> listByStatus({
    required String organizationId,
    required List<OutboxStatus> statuses,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> markConflict({
    required String id,
    required String error,
    required DateTime attemptedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> markFailed({
    required String id,
    required String error,
    required DateTime attemptedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> markSynced({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> markSyncing({
    required String id,
    required DateTime attemptedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> requeue({
    required String id,
    required Map<String, dynamic> payload,
    required DateTime attemptedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> retryFailed({
    required String id,
    required DateTime requestedAt,
  }) {
    throw UnimplementedError();
  }
}
