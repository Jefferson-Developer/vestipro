import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/connectivity/connectivity.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  testWidgets('navigates to the Sync Center when the indicator is tapped', (
    tester,
  ) async {
    final connectivity = _FakeConnectivityService();
    final outbox = _FakeOutboxRepository();
    final router = GoRouter(
      initialLocation: const CatalogHomeRoute(
        orgId: 'org-1',
        companyId: 'company-1',
      ).location,
      routes: <RouteBase>[
        GoRoute(
          path: CatalogHomeRoute.pathPattern,
          builder: (context, state) => ConnectivityIndicatorShell(
            organizationId: 'org-1',
            companyId: 'company-1',
            createCubit: () => ConnectivityIndicatorCubit(
              connectivity,
              outbox,
              FakeAnalyticsService(),
            ),
            child: const Scaffold(body: Center(child: Text('Home'))),
          ),
        ),
        GoRoute(
          path: SyncCenterRoute.pathPattern,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Central de Sincronização')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(connectivity.dispose);
    addTearDown(outbox.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Online e sincronizado'), findsOneWidget);

    await tester.tap(find.text('Online e sincronizado'));
    await tester.pumpAndSettle();

    expect(find.text('Central de Sincronização'), findsOneWidget);
  });
}

final class _FakeConnectivityService implements ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> dispose() => _controller.close();
}

final class _FakeOutboxRepository implements OutboxRepository {
  final StreamController<OutboxSummary> _controller =
      StreamController<OutboxSummary>.broadcast();

  @override
  Stream<OutboxSummary> watchSummary({required String organizationId}) =>
      _controller.stream;

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
