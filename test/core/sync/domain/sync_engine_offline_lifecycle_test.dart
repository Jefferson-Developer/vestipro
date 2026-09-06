import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/services/services.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

/// TASK-163 (EPIC-21) — testes de ciclo de vida offline/sincronização que
/// complementam `sync_engine_test.dart`, `sync_scheduler_test.dart` e
/// `conflict_resolution_service_test.dart`: aqueles cobrem o motor de
/// sincronização (TASK-109) e a resolução de conflitos (TASK-110) dentro de
/// uma única instância de processo/banco em memória; este arquivo cobre
/// especificamente o cenário "o app foi fechado e reaberto" — fechando o
/// [AppDatabase] em disco e reabrindo-o em uma nova instância, com novos
/// repositórios e um novo [SyncEngine], exatamente como aconteceria em uma
/// nova sessão do app — provando que nada do que a Outbox precisa (o próprio
/// registro pendente, o `attemptCount`/backoff de retry e o cursor de
/// sincronização incremental) depende de estado em memória perdido no
/// fechamento.
class _RecordingCrashReporter implements CrashReporter {
  final List<Object> recordedErrors = [];

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedErrors.add(exception);
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// Como em `sync_engine_test.dart`: cada chamada registra a operação
/// recebida e, por padrão, simula um backend que reconhece o
/// `clientOperationId` repetido como já processado — [behavior] permite a um
/// teste roteirizar uma falha específica (ex.: timeout percebido pelo
/// cliente) antes de deixar o handler suceder.
class _FakePushHandler implements SyncPushHandler {
  _FakePushHandler(this.entityType);

  @override
  final OutboxEntityType entityType;

  final List<OutboxOperation> pushCalls = [];
  final Set<String> remoteProcessedIds = {};
  SyncPushOutcome Function(OutboxOperation operation)? behavior;

  @override
  Future<SyncPushOutcome> push(OutboxOperation operation) async {
    pushCalls.add(operation);
    if (behavior != null) return behavior!(operation);

    if (remoteProcessedIds.contains(operation.clientOperationId)) {
      return const SyncPushAlreadyProcessed();
    }
    remoteProcessedIds.add(operation.clientOperationId);
    return const SyncPushSynced();
  }
}

class _FakeSyncPullSource implements SyncPullSource {
  _FakeSyncPullSource(this.kind);

  @override
  final OfflinePackageEntityKind kind;

  final List<SyncPullRecord> applied = [];
  final List<String?> fetchCursors = [];
  AppResult<SyncPullPage> Function(String? cursor)? script;

  @override
  Future<AppResult<SyncPullPage>> fetchChanges({
    required String organizationId,
    required String companyId,
    String? cursor,
  }) async {
    fetchCursors.add(cursor);
    if (script != null) return script!(cursor);
    return const AppSuccess<SyncPullPage>(SyncPullPage(records: []));
  }

  @override
  Future<AppResult<void>> apply(SyncPullRecord record) async {
    applied.add(record);
    return const AppSuccess<void>(null);
  }
}

void main() {
  group('Ciclo de vida offline: app fechado e reaberto (TASK-163)', () {
    late File dbFile;
    var fileCounter = 0;

    setUp(() {
      fileCounter++;
      dbFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task163_sync_${DateTime.now().microsecondsSinceEpoch}_'
        '$fileCounter.sqlite',
      );
    });

    tearDown(() async {
      if (dbFile.existsSync()) dbFile.deleteSync();
    });

    test('um pedido criado offline sobrevive ao fechamento do app e é '
        'sincronizado corretamente ao reconectar, sem duplicação', () async {
      final createdAt = DateTime.utc(2026, 1, 1, 9);

      // --- Sessão 1: usuário cria o pedido sem internet. ---
      final session1Db = AppDatabase(NativeDatabase(dbFile));
      final session1Outbox = DriftOutboxRepository(session1Db);
      await session1Outbox.enqueue(
        id: 'op-order-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: const <String, dynamic>{'total': 150.0, 'items': 3},
        createdAt: createdAt,
        createdBy: 'seller-1',
      );
      // App fechado (processo encerrado) antes de qualquer tentativa de
      // sincronização — nada chega a rodar `SyncEngine.runPush` ainda.
      await session1Db.close();

      // --- Sessão 2: app reaberto, agora com conexão. ---
      final session2Db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(session2Db.close);
      final session2Outbox = DriftOutboxRepository(session2Db);
      final session2Cursor = DriftSyncCursorRepository(session2Db);

      // A operação pendente precisa estar visível para a nova instância,
      // lida do disco, não de memória.
      final pendingAfterReopen = await session2Outbox.listByStatus(
        organizationId: 'org-1',
        statuses: const <OutboxStatus>[OutboxStatus.pending],
      );
      expect(
        (pendingAfterReopen as AppSuccess<List<OutboxOperation>>)
            .value
            .single
            .id,
        'op-order-1',
      );

      final handler = _FakePushHandler(OutboxEntityType.order);
      final engine = SyncEngine(
        session2Outbox,
        session2Cursor,
        [handler],
        const [],
        FakeAnalyticsService(),
        _RecordingCrashReporter(),
      );

      final report = await engine.runPush(
        organizationId: 'org-1',
        now: createdAt.add(const Duration(minutes: 5)),
      );

      expect(report.attempted, 1);
      expect(report.synced, 1);
      expect(handler.pushCalls, hasLength(1));

      final syncedResult = await session2Outbox.listByStatus(
        organizationId: 'org-1',
        statuses: const <OutboxStatus>[OutboxStatus.synced],
      );
      expect(
        (syncedResult as AppSuccess<List<OutboxOperation>>).value.single.id,
        'op-order-1',
      );

      // Uma nova reconexão (ex.: reconexão espúria detectada pelo
      // `SyncScheduler`) nunca reenvia um item já `synced`.
      final secondReport = await engine.runPush(
        organizationId: 'org-1',
        now: createdAt.add(const Duration(minutes: 10)),
      );
      expect(secondReport.attempted, 0);
      expect(handler.pushCalls, hasLength(1));
    });

    test('o backoff exponencial de uma operação com falha sobrevive ao '
        'fechamento do app: reabrir não reseta attemptCount nem ignora a '
        'janela de espera ainda pendente', () async {
      const retryPolicy = SyncRetryPolicy(
        maxAttempts: 5,
        baseDelay: Duration(seconds: 2),
      );
      var now = DateTime.utc(2026, 1, 1, 8);

      // --- Sessão 1: cria o pedido e sofre uma falha de rede na primeira
      // tentativa (ex.: o app perde conexão no meio da sincronização). ---
      final session1Db = AppDatabase(NativeDatabase(dbFile));
      final session1Outbox = DriftOutboxRepository(session1Db);
      await session1Outbox.enqueue(
        id: 'op-order-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: const <String, dynamic>{'total': 90.0},
        createdAt: now,
        createdBy: 'seller-1',
      );

      final failingHandler = _FakePushHandler(OutboxEntityType.order)
        ..behavior = (_) => const SyncPushRetryableFailure('sem conexão');
      final session1Engine = SyncEngine(
        session1Outbox,
        DriftSyncCursorRepository(session1Db),
        [failingHandler],
        const [],
        FakeAnalyticsService(),
        _RecordingCrashReporter(),
        retryPolicy: retryPolicy,
      );

      final firstReport = await session1Engine.runPush(
        organizationId: 'org-1',
        now: now,
      );
      expect(firstReport.failed, 1);

      // App é fechado logo após a falha, antes do backoff de 2s expirar.
      await session1Db.close();

      // --- Sessão 2: app reaberto quase imediatamente, ainda dentro da
      // janela de backoff — não deve tentar de novo. ---
      final session2Db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(session2Db.close);
      final session2Outbox = DriftOutboxRepository(session2Db);
      final succeedingHandler = _FakePushHandler(OutboxEntityType.order);
      final session2Engine = SyncEngine(
        session2Outbox,
        DriftSyncCursorRepository(session2Db),
        [succeedingHandler],
        const [],
        FakeAnalyticsService(),
        _RecordingCrashReporter(),
        retryPolicy: retryPolicy,
      );

      now = now.add(const Duration(seconds: 1));
      final tooSoonReport = await session2Engine.runPush(
        organizationId: 'org-1',
        now: now,
      );
      expect(tooSoonReport.attempted, 0);
      expect(succeedingHandler.pushCalls, isEmpty);

      // Passado o backoff (mais 1s, completando os 2s desde a 1ª
      // tentativa, cujo `lastAttemptAt` veio do disco, não da memória).
      now = now.add(const Duration(seconds: 1));
      final retryReport = await session2Engine.runPush(
        organizationId: 'org-1',
        now: now,
      );
      expect(retryReport.attempted, 1);
      expect(retryReport.synced, 1);
      expect(succeedingHandler.pushCalls, hasLength(1));

      final finalState = await session2Outbox.listByStatus(
        organizationId: 'org-1',
        statuses: const <OutboxStatus>[OutboxStatus.synced],
      );
      final operations =
          (finalState as AppSuccess<List<OutboxOperation>>).value;
      expect(operations, hasLength(1));
      // attemptCount continuou a partir de 1 (persistido), nunca reiniciou
      // do zero após reabrir — a 2ª tentativa some é a 2ª no total.
      expect(operations.single.attemptCount, 2);
    });

    test(
      'o cursor de sincronização incremental sobrevive ao fechamento do '
      'app: reconexões subsequentes nunca reprocessam páginas já aplicadas',
      () async {
        final firstRecordUpdatedAt = DateTime.utc(2026, 1, 1, 10);
        const persistedCursor = '2026-01-01T10:00:00.000Z';

        // --- Sessão 1: primeira sincronização, aplica um registro remoto e
        // persiste o cursor. ---
        final session1Db = AppDatabase(NativeDatabase(dbFile));
        final session1Source = _FakeSyncPullSource(
          OfflinePackageEntityKind.customers,
        );
        session1Source.script = (cursor) {
          expect(cursor, isNull); // primeira sincronização, sem cursor ainda.
          return AppSuccess<SyncPullPage>(
            SyncPullPage(
              records: [
                SyncPullRecord(
                  entityId: 'customer-1',
                  organizationId: 'org-1',
                  companyId: 'company-1',
                  updatedAt: firstRecordUpdatedAt,
                  data: const <String, dynamic>{'name': 'Loja A'},
                ),
              ],
              nextCursor: persistedCursor,
            ),
          );
        };
        final session1Engine = SyncEngine(
          DriftOutboxRepository(session1Db),
          DriftSyncCursorRepository(session1Db),
          const [],
          [session1Source],
          FakeAnalyticsService(),
          _RecordingCrashReporter(),
        );

        final firstReport = await session1Engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        expect(firstReport.applied, 1);
        await session1Db.close();

        // --- Sessão 2: app reaberto (nova reconexão) — a nova fonte
        // simulando o mesmo backend só deve ser consultada a partir do
        // cursor persistido, nunca do início. ---
        final session2Db = AppDatabase(NativeDatabase(dbFile));
        addTearDown(session2Db.close);
        final session2Source = _FakeSyncPullSource(
          OfflinePackageEntityKind.customers,
        );
        session2Source.script = (cursor) {
          expect(cursor, persistedCursor);
          // Nada novo desde o cursor persistido.
          return const AppSuccess<SyncPullPage>(SyncPullPage(records: []));
        };
        final session2Engine = SyncEngine(
          DriftOutboxRepository(session2Db),
          DriftSyncCursorRepository(session2Db),
          const [],
          [session2Source],
          FakeAnalyticsService(),
          _RecordingCrashReporter(),
        );

        final secondReport = await session2Engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        expect(secondReport.applied, 0);
        expect(session2Source.applied, isEmpty);
        expect(session2Source.fetchCursors.single, persistedCursor);

        // Uma terceira reconexão, ainda na sessão 2, confirma que o cursor
        // continua estável (não regrediu) mesmo após um ciclo sem novidades.
        final thirdReport = await session2Engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        expect(thirdReport.applied, 0);
        expect(session2Source.fetchCursors.last, persistedCursor);
      },
    );
  });

  group(
    'Conflito de pedido detectado após reconexão do app fechado (TASK-163)',
    () {
      test('uma edição de pedido feita offline, ao reconectar após o app ser '
          'reaberto, sinaliza o conflito financeiro para resolução manual — '
          'nunca resolvido automaticamente como last-write-wins', () async {
        final dbFile = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}'
          'vestipro_task163_conflict_'
          '${DateTime.now().microsecondsSinceEpoch}.sqlite',
        );
        addTearDown(() {
          if (dbFile.existsSync()) dbFile.deleteSync();
        });

        final createdAt = DateTime.utc(2026, 1, 1, 8);

        // --- Sessão 1: vendedor edita o desconto do pedido offline. ---
        final session1Db = AppDatabase(NativeDatabase(dbFile));
        final session1Outbox = DriftOutboxRepository(session1Db);
        await session1Outbox.enqueue(
          id: 'op-order-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          operationType: OutboxOperationType.update,
          payload: const <String, dynamic>{'discount': 0.1},
          createdAt: createdAt,
          createdBy: 'seller-1',
        );
        await session1Db.close();

        // --- Sessão 2: app reaberto; ao reconectar, uma outra sessão já
        // havia alterado o mesmo pedido no servidor (ex.: gestor aprovou
        // um desconto diferente). ---
        final session2Db = AppDatabase(NativeDatabase(dbFile));
        addTearDown(session2Db.close);
        final session2Outbox = DriftOutboxRepository(session2Db);
        final conflictRecordRepository = DriftConflictRecordRepository(
          session2Db,
        );
        final conflictAuditLogRepository = DriftConflictAuditLogRepository(
          session2Db,
        );
        final conflictService = ConflictResolutionService(
          conflictRecordRepository,
          conflictAuditLogRepository,
          session2Outbox,
        );

        final outcome = await conflictService.resolve(
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          outboxOperationId: 'op-order-1',
          local: ConflictSnapshot(
            data: const <String, Object?>{'discount': 0.1},
            updatedAt: createdAt,
          ),
          remote: ConflictSnapshot(
            data: const <String, Object?>{'discount': 0.2},
            updatedAt: createdAt.add(const Duration(hours: 1)),
          ),
        );

        expect(outcome, isA<ConflictResolutionBlockedManual>());
        final blocked = outcome as ConflictResolutionBlockedManual;
        expect(blocked.conflictingFields, {'discount'});

        final conflictOps = await session2Outbox.listByStatus(
          organizationId: 'org-1',
          statuses: const <OutboxStatus>[OutboxStatus.conflict],
        );
        expect(
          (conflictOps as AppSuccess<List<OutboxOperation>>).value.map(
            (operation) => operation.id,
          ),
          contains('op-order-1'),
        );

        final openConflicts = await conflictRecordRepository.listOpen(
          organizationId: 'org-1',
        );
        final records =
            (openConflicts as AppSuccess<List<ConflictRecord>>).value;
        expect(records, hasLength(1));
        expect(records.single.policy, ConflictPolicy.manualResolution);
        expect(records.single.status, ConflictRecordStatus.conflict);
      });
    },
  );
}
