# TASK-108 — Implementar Outbox — CONCLUÍDA

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída
**Agente executor:** flutter-senior-architect

## Resumo

Modelada e implementada a estrutura local do Outbox Pattern (fila de operações offline pendentes
de sincronização), conforme a seção 5.4 de `tasks.md` e o escopo técnico de TASK-108. Esta task
cobre apenas a estrutura/API do Outbox — o motor que efetivamente drena a fila contra
Firestore/Functions é TASK-109, ainda não implementado.

## O que foi implementado

### Schema Drift (`lib/core/database`)

- `lib/core/database/tables/outbox_table.dart` — nova `OutboxTable`: `id` (PK, também usado como
  `clientOperationId`), `organizationId`, `companyId` (nullable), `entityType`, `entityId`,
  `operationType`, `payload` (JSON), `status` (`pending`/`syncing`/`synced`/`failed`/`conflict`,
  default `pending`), `attemptCount`, `lastAttemptAt`, `lastError`, `createdAt`, `createdBy`,
  `sequenceNumber` (ordem de criação local, monotonicamente crescente, independente de
  `entityId`/timestamp). Índices por `(organizationId, status)` e por
  `(organizationId, entityType, entityId, sequenceNumber)`.
- `lib/core/database/app_database.dart` — `OutboxTable` adicionada ao `AppDatabase`
  (`schemaVersion` 14 → **15**, migração `if (from < 15) { await migrator.createTable(outboxTable); }`).
  Novos métodos:
  - `enqueueOutboxOperation(...)` — insere um novo registro `pending` dentro de uma transação
    Drift; se o `id` (clientOperationId) já existir, retorna o registro existente sem alterar
    `sequenceNumber`/`createdAt` (idempotência). Como usa `transaction()`, pode ser chamado dentro
    de uma transação externa maior (Drift aninha via savepoint), permitindo que uma feature futura
    grave a mutação local e o Outbox atomicamente.
  - `markOutboxSyncing` / `markOutboxSynced` / `markOutboxFailed` / `markOutboxConflict` —
    transições de estado; `markOutboxSyncing` incrementa `attemptCount` e grava `lastAttemptAt`.
  - `getOutboxOperationById`, `getOutboxOperationsByStatus`, `getOutboxOperationsByEntity` (sempre
    ordenadas por `sequenceNumber`), `watchOutboxStatusCounts` (stream reativo de contagens por
    status, classe auxiliar `OutboxStatusCounts`).
- `lib/core/database/database.dart` — export de `tables/outbox_table.dart`.

### Domínio e dados (`lib/core/sync`, novo módulo)

- `domain/entities/outbox_entity_type.dart` — enum `OutboxEntityType` (`order`, `orderItem`,
  `crmActivity`, `customer`) com `.code` estável, extensível conforme mais features migrem para o
  Outbox.
- `domain/entities/outbox_operation_type.dart` — enum `OutboxOperationType` (`create`/`update`/`delete`).
- `domain/entities/outbox_status.dart` — enum `OutboxStatus` (`pending`/`syncing`/`synced`/`failed`/`conflict`).
- `domain/entities/outbox_operation.dart` — entidade `OutboxOperation` (payload decodificado como
  `Map<String, dynamic>`, `clientOperationId` como alias de `id`).
- `domain/entities/outbox_summary.dart` — `OutboxSummary` (contagens `pending`/`syncing`/`failed`/`conflict`,
  `totalUnsyncedCount`, `hasFailuresOrConflicts`).
- `domain/repositories/outbox_repository.dart` — contrato `OutboxRepository`: `enqueue`,
  `markSyncing`, `markSynced`, `markFailed`, `markConflict`, `listByStatus`, `listByEntity`,
  `watchSummary`. Sem dependência de Flutter/Drift.
- `data/repositories/drift_outbox_repository.dart` — `DriftOutboxRepository` (`@LazySingleton`),
  serializa/desserializa o payload (`jsonEncode`/`jsonDecode`) e converte `AppDatabase`
  exceptions em `AppResult`/`UnexpectedFailure`.
- `presentation/cubit/outbox_watcher_cubit.dart` — `OutboxWatcherCubit` (`@injectable`,
  `Cubit<OutboxSummary>`), observa `OutboxRepository.watchSummary` por `organizationId`, com
  `watch()` substituindo qualquer inscrição anterior — base para a Central de Sincronização
  (TASK-112).
- `sync.dart` — barrel do módulo.

### DI e codegen

- Rodado `dart run build_runner build` — gerou `app_database.g.dart` (tabela/companion/data class
  do Outbox) e `injection.config.dart` (registro de `DriftOutboxRepository` como
  `OutboxRepository` e `OutboxWatcherCubit` como factory).

### Ajuste em testes pré-existentes

- `test/core/database/app_database_test.dart`, `app_database_warehouses_test.dart`,
  `app_database_task_106_schema_test.dart` — `expect(database.schemaVersion, 14)` atualizado para
  `15`, consequência mecânica da nova migração desta task.

## Decisões de arquitetura

- **`id` = `clientOperationId`**: em vez de duas colunas redundantes, o Outbox usa um único
  identificador gerado client-side pelo chamador (ex.: `Uuid().v4()`), reaproveitado em qualquer
  retentativa da mesma operação lógica. Isso é o que garante a idempotência exigida pelo escopo
  ("reenviar o mesmo `clientOperationId` não gera duplicidade") e é o mesmo valor que o backend/
  Functions (TASK-109) usará para deduplicar.
- **`sequenceNumber` como contador local, não timestamp**: computado como
  `MAX(sequenceNumber) + 1` dentro da mesma transação do `enqueue`, garantindo ordem determinística
  de processamento por entidade mesmo com timestamps colididos/relógio local inconsistente.
- **Atomicidade "mesma transação"**: em vez de expor `select`/`into` brutos do Drift para as
  features (o que quebraria o padrão já usado no restante de `AppDatabase`, que só expõe métodos
  tipados), `enqueueOutboxOperation` roda em sua própria `transaction()`, que o Drift aninha como
  savepoint se o chamador (ex.: um futuro `DriftOrderRepository`) já estiver dentro de uma
  `database.transaction()` própria — assim a gravação local e o registro do Outbox só se
  confirmam juntos, sem precisar de uma segunda API "raw".
- **Motor de sync fora de escopo**: nenhuma feature existente (ex.: `lib/features/orders`) foi
  religada para usar o Outbox nesta task — isso depende do motor de sincronização (TASK-109), que
  decide como/quando drenar a fila. Esta task entrega apenas a fila e sua API.

## Testes

- `test/core/database/app_database_outbox_test.dart` (novo, 8 testes): atomicidade de
  `enqueueOutboxOperation`, idempotência por `id`, ordenação por `sequenceNumber` em
  `getOutboxOperationsByEntity`, transições `pending -> syncing -> synced` e
  `pending -> syncing -> failed -> syncing` (retry), `markOutboxConflict`, filtro por status/escopo,
  stream reativo `watchOutboxStatusCounts`, e persistência sobrevivendo ao fechamento/reabertura do
  banco (arquivo SQLite real, não in-memory).
- `test/core/sync/data/repositories/drift_outbox_repository_test.dart` (novo, 8 testes): `enqueue`
  decodificando payload, idempotência via `AppResult`, ordenação por `listByEntity`, transições de
  estado via repositório, `markConflict`, `watchSummary` reativo.
- `test/core/sync/presentation/cubit/outbox_watcher_cubit_test.dart` (novo, 2 testes): emissão de
  cada `OutboxSummary` do repositório, e `watch()` substituindo a inscrição anterior sem
  vazamento/duplicidade.

## Comandos executados e resultados reais

- `dart run build_runner build` — sucesso (469 outputs escritos); warnings pré-existentes não
  relacionados (`ImageUploadCompressor`, `ProductDetailBloc`, `ProductGridBloc`, `OrderDraftBloc`
  com dependências não registradas) já existiam antes desta task.
- `dart format --set-exit-if-changed .` (nos arquivos tocados) — aplicado sem alterações
  pendentes após a primeira formatação automática.
- `flutter analyze` — `3 issues found` (todos `info`, pré-existentes, fora do escopo desta task:
  `use_null_aware_elements` em `cloud_functions_order_approval_data_source.dart` e
  `cloud_functions_order_submission_data_source.dart`, `prefer_initializing_formals` em
  `add_items_to_order_draft_use_case_test.dart`).
- `flutter test` (suíte completa) — **2218 testes, todos passando** após o ajuste dos 3 testes que
  hardcodavam `schemaVersion == 14`.

## Pendências e riscos conhecidos

- Nenhuma feature existente foi religada ao Outbox ainda — isso é esperado, é escopo de TASK-109
  em diante (motor de sincronização) e das tasks de feature que adotarem o Outbox.
- `OutboxEntityType` cobre hoje apenas `order`, `orderItem`, `crmActivity`, `customer` — deve
  crescer conforme cada feature migrar seu caminho de escrita offline para o Outbox.
- O warning do Drift "database class AppDatabase multiple times" aparece no teste de persistência
  (reabre o mesmo arquivo SQLite) — é o mesmo padrão inofensivo já usado em
  `app_database_task_106_schema_test.dart`, não indica problema real.

## Arquivos criados

- `lib/core/database/tables/outbox_table.dart`
- `lib/core/sync/domain/entities/outbox_entity_type.dart`
- `lib/core/sync/domain/entities/outbox_operation_type.dart`
- `lib/core/sync/domain/entities/outbox_status.dart`
- `lib/core/sync/domain/entities/outbox_operation.dart`
- `lib/core/sync/domain/entities/outbox_summary.dart`
- `lib/core/sync/domain/repositories/outbox_repository.dart`
- `lib/core/sync/data/repositories/drift_outbox_repository.dart`
- `lib/core/sync/presentation/cubit/outbox_watcher_cubit.dart`
- `lib/core/sync/sync.dart`
- `test/core/database/app_database_outbox_test.dart`
- `test/core/sync/data/repositories/drift_outbox_repository_test.dart`
- `test/core/sync/presentation/cubit/outbox_watcher_cubit_test.dart`

## Arquivos alterados

- `lib/core/database/app_database.dart`
- `lib/core/database/database.dart`
- `lib/core/database/app_database.g.dart` (gerado)
- `lib/app/injection.config.dart` (gerado)
- `test/core/database/app_database_test.dart`
- `test/core/database/app_database_warehouses_test.dart`
- `test/core/database/app_database_task_106_schema_test.dart`
- `docs/tasks/TASKS.md` (checkbox + progresso)
