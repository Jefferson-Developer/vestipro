import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('OutboxWatcherCubit', () {
    test('emits every summary produced by the repository stream', () async {
      final controller = StreamController<OutboxSummary>();
      addTearDown(controller.close);
      final repository = _FakeOutboxRepository(controller.stream);
      final cubit = OutboxWatcherCubit(repository);
      addTearDown(cubit.close);

      expect(cubit.state.totalUnsyncedCount, 0);

      cubit.watch(organizationId: 'org-1');
      expect(repository.lastWatchedOrganizationId, 'org-1');

      controller.add(const OutboxSummary(pendingCount: 2));
      await pumpEventQueue();
      expect(cubit.state.pendingCount, 2);

      controller.add(const OutboxSummary(failedCount: 1, conflictCount: 1));
      await pumpEventQueue();
      expect(cubit.state.failedCount, 1);
      expect(cubit.state.conflictCount, 1);
      expect(cubit.state.hasFailuresOrConflicts, isTrue);
    });

    test(
      'watch replaces a previous subscription instead of stacking it',
      () async {
        final firstController = StreamController<OutboxSummary>();
        final secondController = StreamController<OutboxSummary>();
        addTearDown(firstController.close);
        addTearDown(secondController.close);
        final repository = _FakeOutboxRepository(firstController.stream);
        final cubit = OutboxWatcherCubit(repository);
        addTearDown(cubit.close);

        cubit.watch(organizationId: 'org-1');
        repository.nextStream = secondController.stream;
        cubit.watch(organizationId: 'org-2');

        // Emitting on the now-abandoned first controller must not reach the
        // cubit anymore.
        firstController.add(const OutboxSummary(pendingCount: 99));
        await pumpEventQueue();
        expect(cubit.state.pendingCount, 0);

        secondController.add(const OutboxSummary(pendingCount: 3));
        await pumpEventQueue();
        expect(cubit.state.pendingCount, 3);
      },
    );
  });
}

class _FakeOutboxRepository implements OutboxRepository {
  _FakeOutboxRepository(this.nextStream);

  Stream<OutboxSummary> nextStream;
  String? lastWatchedOrganizationId;

  @override
  Stream<OutboxSummary> watchSummary({required String organizationId}) {
    lastWatchedOrganizationId = organizationId;
    return nextStream;
  }

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
}
