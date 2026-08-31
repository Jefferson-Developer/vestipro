# TASK-109 — Implementar motor de sincronização incremental (CONCLUÍDA)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída
**Depende de:** TASK-108 (Outbox implementada)

## Resumo do que foi implementado

Implementado `SyncEngine` (`lib/core/sync/domain/sync_engine.dart`), o motor de sincronização
incremental entre o banco local (Drift) e Firestore/Cloud Functions, com dois fluxos independentes:

- **`runPush`** — drena a Outbox (TASK-108) por `organizationId`: cada operação
  `pending`/`failed`-e-elegível é despachada, na ordem de `sequenceNumber`, para o
  `SyncPushHandler` registrado para o seu `OutboxEntityType`, com retry/backoff exponencial
  (`SyncRetryPolicy`) e idempotência via `OutboxOperation.clientOperationId` +
  `SyncPushAlreadyProcessed`. Recupera automaticamente operações órfãs em `syncing` deixadas por
  uma execução anterior interrompida (crash/queda de conexão), sem nunca duplicar ou corromper a
  fila.
- **`runPull`** — para cada `SyncPullSource` registrado, busca somente os registros remotos
  alterados desde o cursor persistido (`SyncCursorRepository`/`SyncCursorsTable`) e aplica cada um
  localmente via `upsert` — nunca uma carga completa. Nunca sobrescreve uma entidade com operação
  local pendente na Outbox (fica marcada como "skipped" até TASK-110 resolver o conflito) e rejeita
  defensivamente qualquer registro remoto cujo `organizationId` não bata com o escopo solicitado
  (isolamento multi-tenant), mesmo que a query do próprio `SyncPullSource` já devesse ter filtrado
  por tenant.
- **`runFullCycle`** — executa `runPush` e depois `runPull`, nessa ordem (documentado o porquê no
  próprio `SyncEngine`).

`SyncScheduler` (`lib/core/sync/domain/sync_scheduler.dart`) dispara o motor em background, sem
bloquear a UI: uma vez ao chamar `start()`, novamente quando a conectividade volta (usando o novo
`ConnectivityService`/`ConnectivityPlusService` — não havia nenhum serviço de conectividade
existente no projeto antes desta task, apesar de `connectivity_plus` já constar no `pubspec.yaml`) e
periodicamente enquanto ativo. Garante que nunca há dois ciclos sobrepostos.

Métricas básicas de sincronização (`SyncPushReport`/`SyncPullReport`/`SyncCycleReport`: quantidade
sincronizada, falhas, conflitos, registros aplicados/ignorados, duração) são expostas via dois novos
eventos Analytics: `AnalyticsEvents.syncPushCompleted` e `syncPullCompleted`.

## Decisão temporária de resolução de conflito (a revisar na TASK-110)

O motor hoje resolve pull vs. Outbox local pendente apenas "não sobrescrevendo" (skip, refeito no
próximo ciclo assim que a operação local sair da fila) — nunca aplica last-write-wins
automaticamente. Para uma rejeição do backend no push (`SyncPushConflict`), a operação vai para
`OutboxStatus.conflict`, fora do caminho de retry automático. Nenhuma UI foi implementada para isso
(TASK-111/TASK-112). Essa é a estratégia mínima documentada como decisão temporária: TASK-110 pode
substituir/expandir isso (ex.: merge campo a campo, last-write-wins por `version`/`updatedAt`) sem
precisar alterar o contrato do `SyncEngine`.

## O que NÃO foi feito nesta task (fora de escopo, conforme instrução)

- Tela de conflito (TASK-111), central de sincronização (TASK-112) e indicador de conectividade na
  UI (TASK-113) — nenhuma tela nova.
- Nenhum `SyncPushHandler`/`SyncPullSource` concreto foi registrado: `SyncModule`
  (`lib/app/sync_module.dart`) expõe hoje `syncPushHandlers`/`syncPullSources` como listas vazias —
  nenhuma feature (`order`/`orderItem`/`crmActivity`/`customer`) enfileira pela Outbox ainda (pedido
  continua indo direto para `submitOrder`, online-only). O `SyncEngine` em si é validado por dublês
  (fakes) nos próprios testes, mesmo padrão que `DownloadOfflinePackageUseCase` (TASK-107) seguiu no
  mesmo ponto de sua própria história.
- `SyncScheduler.start()`/`stop()` não foi conectado ao ciclo de vida real de sessão/organização
  ativa em `lib/app/bootstrap.dart` — não há hoje um ponto único e óbvio de "organização ativa"
  observável nesse nível sem tocar em código fora do escopo desta task. Documentado no próprio
  `SyncScheduler` como ponto de extensão explícito para quem ligar a primeira feature na Outbox ou
  para a Central de Sincronização (TASK-112).

## Arquivos criados

- `lib/core/database/tables/sync_cursors_table.dart` — nova tabela Drift `SyncCursorsTable`
  (bookmark de pull incremental por `organizationId`/`companyId`/`entityKind`).
- `lib/core/connectivity/connectivity_service.dart`, `connectivity_plus_service.dart`,
  `connectivity.dart` — abstração de conectividade (não existia nenhuma antes desta task) e sua
  implementação sobre `connectivity_plus`.
- `lib/core/sync/domain/entities/sync_cursor.dart`, `sync_push_outcome.dart`,
  `sync_pull_record.dart` (com `SyncPullRecord`/`SyncPullPage`), `sync_push_report.dart`,
  `sync_pull_report.dart`, `sync_cycle_report.dart`.
- `lib/core/sync/domain/repositories/sync_cursor_repository.dart` (contrato) e
  `lib/core/sync/data/repositories/drift_sync_cursor_repository.dart` (implementação Drift).
- `lib/core/sync/domain/sync_push_handler.dart`, `sync_pull_source.dart` (contratos de
  extensão por feature), `sync_retry_policy.dart` (backoff exponencial configurável),
  `sync_engine.dart`, `sync_scheduler.dart`.
- `lib/app/sync_module.dart` — módulo de composição (`@module`) que registra
  `List<SyncPushHandler>`/`List<SyncPullSource>`, hoje vazios, mesmo padrão de
  `OfflinePackageLoadersModule`.
- Testes: `test/core/connectivity/connectivity_plus_service_test.dart`,
  `test/core/sync/data/repositories/drift_sync_cursor_repository_test.dart`,
  `test/core/sync/domain/sync_retry_policy_test.dart`,
  `test/core/sync/domain/sync_engine_test.dart`, `test/core/sync/domain/sync_scheduler_test.dart`.

## Arquivos alterados

- `lib/core/database/app_database.dart` — registra `SyncCursorsTable`, `schemaVersion` 15 → 16,
  migração `from < 16`, e os métodos `upsertSyncCursor`/`getSyncCursor`.
- `lib/core/database/database.dart`, `lib/core/sync/sync.dart` — barrels atualizados.
- `lib/core/analytics/analytics_events.dart` — adiciona `syncPushCompleted`/`syncPullCompleted`.
- `lib/app/injection_module.dart` — registra `Connectivity` (de `connectivity_plus`) e
  `SyncRetryPolicy` (política padrão) como singletons, necessários para o DI resolver
  `ConnectivityPlusService`/`SyncEngine`.
- `pubspec.yaml`/`pubspec.lock` — `fake_async` promovido a dev dependency direta (já existia como
  transitiva; usada nos testes de `SyncScheduler` com tempo simulado).
- `lib/app/injection.config.dart`, `lib/core/database/app_database.g.dart` — regenerados via
  `dart run build_runner build`.
- Testes pré-existentes ajustados por efeito colateral do novo `schemaVersion`/eventos novos:
  `test/core/database/app_database_test.dart`, `app_database_warehouses_test.dart`,
  `app_database_task_106_schema_test.dart` (schemaVersion 15 → 16) e
  `test/core/analytics/analytics_events_test.dart` (lista exaustiva de eventos).
- `docs/tasks/TASKS.md` — checkbox da TASK-109 marcado e progresso atualizado para 109/220.

## Bug encontrado e corrigido durante a implementação

`SyncScheduler.start()` chamava `unawaited(stop())` para limpar uma execução anterior antes de
configurar o novo escopo. Como `stop()` é `async` e sua primeira linha já é um `await`, o corpo de
`stop()` só retomava (e zerava `_organizationId`/`_companyId`) numa microtask *depois* que `start()`
já havia setado o novo escopo — uma corrida que deixava o scheduler inerte (`isActive == false`)
logo após `start()`. Corrigido substituindo por um cancelamento síncrono/"fire-and-forget" da
assinatura/timer anteriores, sem depender do método `stop()` assíncrono. Coberto pelos testes de
`sync_scheduler_test.dart` (que originalmente pegaram o bug).

## Validações executadas (resultados reais)

- `dart format --set-exit-if-changed .` → `Formatted 1765 files (0 changed)` (limpo após um
  primeiro `dart format .` sem a flag ter reformatado 6 arquivos novos).
- `flutter analyze` (repo inteiro) → `3 issues found` — todos pré-existentes, em arquivos não
  tocados por esta task (`cloud_functions_order_approval_data_source.dart`,
  `cloud_functions_order_submission_data_source.dart`,
  `add_items_to_order_draft_use_case_test.dart`). Nenhum issue nos arquivos desta task.
- `flutter test` (suíte completa) → `+2243, All tests passed!`.
- `dart run build_runner build` executado duas vezes (schema Drift + DI) sem erros/avisos residuais
  na segunda rodada (rodada de confirmação "no-op", 0 outputs).

## Riscos e pendências conhecidas

- Nenhum `SyncPushHandler`/`SyncPullSource` real existe ainda — o motor está pronto, mas nenhuma
  feature envia/recebe dados incrementalmente por ele até que (a) alguma feature passe a enfileirar
  pela Outbox em vez de escrever direto no Firestore, e (b) alguém implemente pelo menos um
  `SyncPullSource` real. Sem isso, `SyncScheduler` rodando em produção hoje só executaria ciclos
  vazios (nenhum efeito, nenhum risco, mas também nenhum ganho).
- `SyncScheduler` não está conectado ao app real — precisa ser chamado por quem tratar sessão/
  organização ativa (provavelmente TASK-112, ou uma task dedicada de "startar sync no login").
- O contrato de idempotência do lado servidor (Cloud Function reconhecer `clientOperationId`
  repetido e responder "já processado") ainda não existe/foi implementado nas Functions — está
  documentado como contrato esperado em `SyncPushHandler`, mas depende de trabalho futuro na camada
  de Functions.
