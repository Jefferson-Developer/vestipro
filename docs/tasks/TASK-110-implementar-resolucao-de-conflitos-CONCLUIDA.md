# TASK-110 — Implementar resolução de conflitos — CONCLUÍDA

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída

## O que foi feito

Implementado `ConflictResolutionService`: o serviço central que aplica a política de resolução de
conflitos por entidade descrita na seção 5.5 de `tasks.md` (last-write-wins quando seguro, merge por
campo quando possível, bloqueio com resolução manual para pedidos/dados financeiros), com persistência
local (Drift) de `ConflictRecord` e de uma trilha de auditoria local (`ConflictAuditEntry`) para toda
resolução, automática ou manual.

### Arquivos criados

Domínio (`lib/core/sync/domain/`):
- `entities/conflict_policy.dart` — enum `ConflictPolicy` (`lastWriteWins`, `fieldMerge`,
  `manualResolution`) com código estável persistido.
- `entities/conflict_snapshot.dart` — `ConflictSnapshot` (dados planos + `updatedAt`/`version`
  opcional) para o lado local ou remoto de um conflito.
- `entities/conflict_record_status.dart` — enum `ConflictRecordStatus` (`conflict`/`resolved`).
- `entities/conflict_record.dart` — entidade `ConflictRecord` persistida quando a resolução é
  bloqueada para decisão manual (consumida pela TASK-111).
- `entities/conflict_audit_outcome.dart` — enum `ConflictAuditOutcome` (`noop`, `appliedRemote`,
  `appliedLocal`, `merged`, `blockedManual`, `resolvedManual`).
- `entities/conflict_audit_entry.dart` — entidade `ConflictAuditEntry`, a trilha de auditoria local
  (quem, quando, qual política, qual resultado).
- `entities/conflict_resolution_outcome.dart` — `sealed class ConflictResolutionOutcome` com as
  variantes `ConflictResolutionNoop`, `ConflictResolutionAppliedRemote`,
  `ConflictResolutionAppliedLocal`, `ConflictResolutionMerged`, `ConflictResolutionBlockedManual`.
- `conflict_policy_catalog.dart` — `ConflictPolicyCatalog`, o único ponto que mapeia
  `OutboxEntityType → ConflictPolicy` (switch exaustivo, sem `default`, para forçar decisão explícita
  em qualquer entidade nova). Mapeamento atual: `order`/`orderItem` → `manualResolution`; `customer` →
  `fieldMerge`; `crmActivity` → `lastWriteWins`.
- `conflict_field_merge.dart` — `ConflictFieldMerge.compute`, função pura de merge por campo a partir
  de um snapshot-base comum, detectando conflito real (mesmo campo alterado nos dois lados para
  valores diferentes) sem depender de persistência.
- `conflict_resolution_service.dart` — `ConflictResolutionService` (`@lazySingleton`), o ponto único
  de entrada: detecta divergência real (campo a campo, não apenas diferença de timestamp), aplica a
  política do catálogo, persiste `ConflictRecord` + marca a operação da Outbox como `conflict` quando
  bloqueado manualmente, e grava exatamente uma entrada de auditoria por chamada, independentemente do
  resultado.
- `repositories/conflict_record_repository.dart` e `repositories/conflict_audit_log_repository.dart`
  — contratos de domínio.

Dados (`lib/core/sync/data/repositories/`):
- `drift_conflict_record_repository.dart` — implementação Drift de `ConflictRecordRepository`.
- `drift_conflict_audit_log_repository.dart` — implementação Drift de `ConflictAuditLogRepository`.

Banco local (`lib/core/database/`):
- `tables/conflict_records_table.dart` — `ConflictRecordsTable`.
- `tables/conflict_audit_log_table.dart` — `ConflictAuditLogTable`.
- `app_database.dart` — ambas as tabelas adicionadas ao `AppDatabase`, `schemaVersion` `16 → 17`,
  migração `if (from < 17)` criando as duas tabelas, e novos métodos:
  `insertConflictRecord` (idempotente por `outboxOperationId`, retorna o registro já existente em vez
  de duplicar), `getOpenConflictRecords`, `getConflictRecordById`, `insertConflictAuditEntry`,
  `getConflictAuditLog`.
- `database.dart` — exports das duas novas tabelas.
- `sync.dart` — exports de todo o novo domínio/dados de conflito.

Testes (`test/core/sync/...`, `test/core/database/...`):
- `domain/conflict_policy_catalog_test.dart` — isolamento por `entityType` (nenhuma entidade
  financeira cai em `lastWriteWins`).
- `domain/conflict_field_merge_test.dart` — merge de campos distintos, conflito no mesmo campo (valor
  diferente vs. valor igual), campo novo só remoto, nenhuma mudança em nenhum lado.
- `domain/conflict_resolution_service_test.dart` — divergência real vs. diferença de timestamp
  irrelevante (`noop`, mas ainda auditado); `lastWriteWins` (remoto vence, local vence, empate
  determinístico, `version` preferido sobre `updatedAt`); `fieldMerge` (merge automático, conflito no
  mesmo campo bloqueia, ausência de snapshot-base bloqueia por segurança); `manualResolution` para
  pedidos (bloqueio sempre, `ConflictRecord` com os dois snapshots completos, Outbox marcada
  `conflict`, nunca aplica nada automaticamente; segunda tentativa sobre o mesmo conflito aberto não
  duplica o registro).
- `data/repositories/drift_conflict_record_repository_test.dart` e
  `data/repositories/drift_conflict_audit_log_repository_test.dart` — persistência/serialização,
  idempotência, isolamento por `organizationId`, ordenação.
- `test/core/database/app_database_test.dart`,
  `test/core/database/app_database_task_106_schema_test.dart`,
  `test/core/database/app_database_warehouses_test.dart` — `schemaVersion` atualizado de `16` para
  `17` (as únicas asserções afetadas pela nova migração).

## Decisões técnicas

- **`ConflictResolutionService` não foi ligado ao `SyncEngine.runPull`/`runPush` nesta task.** O
  `SyncEngine` hoje sempre *pula* (skip) um registro remoto cuja entidade tem uma operação de Outbox
  pendente — comportamento coberto por teste existente (`sync_engine_test.dart`, "skips a record whose
  entity has a pending Outbox operation") que este trabalho não altera. Nenhum `SyncPushHandler`/
  `SyncPullSource` concreto está registrado ainda (`SyncModule` em `lib/app/` continua com as duas
  listas vazias — TASK-108/109 seguiram o mesmo padrão de "primitiva pronta e testada, integração
  concreta adiada para quando uma feature adotar a Outbox/pull incremental"). Este serviço foi
  construído como uma primitiva completa, testada isoladamente, pronta para ser chamada tanto por uma
  futura integração no `SyncEngine` quanto pela TASK-111 (tela de conflito, ao resolver manualmente um
  `ConflictRecord` já bloqueado). Risco identificado e documentado — ver "Pendências" abaixo.
- **`ConflictPolicyCatalog`** usa `switch` exaustivo sem `default`: adicionar um novo
  `OutboxEntityType` sem estender esse switch é erro de compilação, forçando decisão explícita de
  política (nunca herdar um `lastWriteWins` por omissão).
- **Merge por campo exige um snapshot-base explícito** (`ConflictSnapshot? base` em
  `ConflictResolutionService.resolve`). Sem ele, o serviço nunca arrisca um merge automático — trata
  como bloqueio manual, mesmo para uma entidade cuja política é `fieldMerge`. É o comportamento mais
  seguro possível dado que a Outbox (TASK-108) hoje não armazena um snapshot "antes da edição local".
- **Auditoria local, não a `AuditLogEntry` administrativa** (`lib/features/audit_log/`, Firestore).
  Optou-se por uma tabela Drift própria (`ConflictAuditLogTable`) porque: (1) a auditoria de conflito
  é per-resolução, potencialmente volumosa, e não deve depender de round-trip ao Firestore para ser
  registrada; (2) `core/sync` não pode depender de `features/audit_log` (regra de camadas —
  `core` nunca depende de `features`).
- **Idempotência por `outboxOperationId`** em `AppDatabase.insertConflictRecord`: uma segunda chamada
  de `resolve()` para uma operação já bloqueada (`status == 'conflict'`) retorna o `ConflictRecord` já
  existente em vez de criar um duplicado — coberto por teste dedicado.
- **Regra de desempate determinística do `lastWriteWins`**: quando `version` não distingue um vencedor
  (ausente ou igual nos dois lados) e `updatedAt` também empata, o remoto vence — é a versão que o
  backend já persistiu de forma durável e para a qual todo outro dispositivo converge.

## Validações executadas

- `dart pub run build_runner build` (Drift + Injectable) — gerado com sucesso; `ConflictResolutionService`,
  `DriftConflictRecordRepository` e `DriftConflictAuditLogRepository` registrados corretamente em
  `lib/app/injection.config.dart`.
- `flutter analyze` (projeto inteiro) — nenhum erro; apenas 3 avisos `info` pré-existentes em arquivos
  não relacionados a esta task.
- `flutter test test/core` — 589 testes, todos passando (inclui os 46 testes novos desta task).
- `flutter test test/app/injection_test.dart` — grafo de DI resolve sem dependência faltando.
- `dart format` nos arquivos criados/alterados — sem mudanças pendentes.

## Pendências ou riscos identificados

- **Integração real no `SyncEngine`** (chamar `ConflictResolutionService.resolve` no lugar do simples
  "skip" atual de `runPull` quando há operação de Outbox pendente) ainda não existe — é o próximo passo
  natural, mas depende de decidir de onde viria o `ConflictSnapshot.base` (snapshot antes da edição
  local) para viabilizar `fieldMerge` com segurança, e nenhuma feature ainda enfileira operações reais
  na Outbox para exercitar esse caminho de ponta a ponta. Recomendado revisitar ao integrar a primeira
  feature real (ex.: `customer`) ao Outbox/pull incremental, ou como parte da TASK-112 (Central de
  Sincronização).
- TASK-111 (tela de conflito) depende diretamente desta task para consumir `ConflictRecordRepository`
  e, futuramente, para acionar `ConflictResolutionService`/gravar `ConflictAuditOutcome.resolvedManual`
  quando o usuário decidir manualmente — nenhum método de "resolver" (`markResolved`) foi adicionado ao
  repositório nesta task, por ser escopo explícito da TASK-111.
