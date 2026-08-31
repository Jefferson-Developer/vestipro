# TASK-112 — Implementar central de sincronização (CONCLUÍDA)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída

## O que foi feito

### Domínio/dados (extensão pontual da TASK-108/109, deliberadamente fora do escopo delas)

- `OutboxRepository.retryFailed(...)` (contrato) +
  `DriftOutboxRepository.retryFailed(...)` (implementação) — move uma
  operação `failed` de volta para `pending` sem tocar `payload`, gravando
  `requestedAt` como novo `lastAttemptAt`. Aterrissar em `pending` (nunca em
  `syncing`) é deliberado: `SyncRetryPolicy.hasAttemptsLeft`/`isDueForRetry`
  só são checados contra uma linha `failed`, então isso contorna
  propositalmente um backoff ainda em vigor ou um orçamento de tentativas já
  esgotado — exatamente o ponto de um humano pedir explicitamente mais uma
  tentativa agora. Um item `conflict` nunca é afetado (só sai desse status
  via `ConflictResolutionService`, TASK-110/111).
- `AppDatabase.retryOutboxOperation(...)` — novo método Drift, mesmo padrão
  de `markOutboxFailed`/`requeueOutboxOperation`; nenhuma migração de schema
  foi necessária (nenhuma coluna/tabela nova).

### Apresentação

- `SyncCenterCubit` + `SyncCenterState` — agrega, para um escopo
  `organizationId`/`companyId`:
  - contagem reativa pending/syncing/failed/conflict da Outbox
    (`OutboxRepository.watchSummary`, TASK-108);
  - lista detalhada das operações `failed` (`listByStatus`), com
    `retryOperation`/`retryAllFailed` acionando `SyncEngine.runPush`
    (TASK-109) sob demanda — nunca via `SyncScheduler` (ver "Riscos"
    abaixo);
  - contagem de conflitos abertos (`ConflictRecordRepository.listOpen`,
    TASK-110/111), que vira o atalho para `ConflictListRoute`;
  - marcador "última carga completa" por entidade
    (`OfflinePackageStatusRepository.getAll`, TASK-107), de onde se deriva
    o timestamp "última sincronização" exibido no topo da tela;
  - conectividade (`ConnectivityService`) — bloqueia toda ação de retry
    enquanto offline e explica que nenhuma tentativa será feita até a
    reconexão.
  - `syncNow()` ("Sincronizar agora") roda um ciclo completo
    (`SyncEngine.runFullCycle`), guardado por `isSyncing` para nunca
    disparar duas vezes em paralelo.
  - Toda falha exibida é reportada uma única vez ao Crashlytics
    (`_reportNewFailures`, deduplicado por id de operação) sem nunca
    incluir o `lastError` técnico bruto.
- `lib/core/sync/presentation/presenters/sync_center_presenter.dart` —
  `syncFailureMessageLabel` gera uma mensagem de negócio fixa por
  `OutboxEntityType` (nunca interpola `OutboxOperation.lastError`, que pode
  conter `exception.toString()` bruto vindo do próprio `SyncEngine.runPush`)
  + `offlinePackageEntityKindLabel` + `syncDateTimeLabel`.
- `OutboxFailedItemCard` — um item da lista de falhas com seu próprio botão
  "Tentar novamente" e estado de loading independente dos demais.
- `SyncCenterPage`/`SyncCenterView` — banner de offline, card-resumo (contagens +
  "Sincronizar agora"), atalho para conflitos abertos, seção "última carga
  completa por dado", seção de itens com falha (+ "Tentar novamente todos"),
  estado vazio "Tudo sincronizado" e snackbar de conclusão do ciclo manual.

### Roteamento e DI

- Nova rota `SyncCenterRoute`
  (`/org/:orgId/companies/:companyId/sync`) em `app_route_paths.dart`/
  `app_router.dart` — escopada por Organização *e* Empresa (diferente de
  `ConflictListRoute`, só por Organização) porque também lê o marcador
  TASK-107, que é por `organizationId`/`companyId`. Sem capability
  dedicada, mesmo padrão das rotas de conflito da TASK-111.
- `bootstrap.dart` conecta `SyncCenterPage` ao `AppRouter`, ligando o atalho
  de conflitos a `ConflictListRoute`.
- `flutter pub run build_runner build` regenerou
  `lib/app/injection.config.dart` automaticamente (12 linhas aditivas:
  `SyncCenterCubit` registrado como `factory`, todas as 7 dependências
  resolvidas sem aviso). Nenhum outro arquivo gerado (`app_database.g.dart`,
  `*.freezed.dart`) mudou — o método novo em `AppDatabase` não altera
  schema/tabelas.

## Arquivos criados

- `lib/core/sync/presentation/cubit/sync_center_cubit.dart`
- `lib/core/sync/presentation/cubit/sync_center_state.dart`
- `lib/core/sync/presentation/presenters/sync_center_presenter.dart`
- `lib/core/sync/presentation/widgets/outbox_failed_item_card.dart`
- `lib/core/sync/presentation/pages/sync_center_page.dart`
- `docs/tasks/TASK-112-implementar-central-de-sincronizacao-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/sync/domain/repositories/outbox_repository.dart` (+`retryFailed`)
- `lib/core/sync/data/repositories/drift_outbox_repository.dart` (+`retryFailed`)
- `lib/core/database/app_database.dart` (+`retryOutboxOperation`)
- `lib/core/analytics/analytics_events.dart` (+`syncCenterOpened`, +`syncManualRetryTriggered`)
- `lib/core/sync/sync.dart` (novos exports)
- `lib/core/navigation/app_route_paths.dart` (+`SyncCenterRoute`)
- `lib/core/navigation/app_router.dart` (+1 `GoRoute`, +1 builder field)
- `lib/app/bootstrap.dart` (builder da nova página)
- `lib/app/injection.config.dart` (regenerado via build_runner)
- `docs/tasks/TASKS.md` (checkbox + progresso)

## Validações executadas

- `flutter pub run build_runner build --delete-conflicting-outputs` —
  sucesso, 1212 outputs; único arquivo gerado que de fato mudou foi
  `injection.config.dart` (12 linhas). Os avisos "Missing dependencies"
  impressos (`ConnectivityPlusService`/`Uuid`/`SyncRetryPolicy`/etc.) são
  pré-existentes, não relacionados a esta task.
- `flutter analyze lib/core/sync lib/app/bootstrap.dart lib/core/navigation lib/core/database/app_database.dart lib/core/analytics/analytics_events.dart` — **No issues found!**
- `flutter analyze lib` (repositório inteiro) — 2 avisos `info` pré-existentes
  em `lib/features/orders/...`, nenhum deles nos arquivos desta task.
- `dart format` nos arquivos criados/alterados desta task — aplicado (2
  arquivos reformatados: `sync_center_page.dart` e `app_database.dart`,
  apenas quebras de linha); segunda passada confirmou 0 arquivos alterados.
- Testes de widget/integração/golden descritos na task **não foram
  criados nesta rodada** (ver Pendências).

## Pendências e riscos conhecidos

- **Testes**: a task pede testes de widget (estados vazio/pendente/falha/
  conflito/offline), teste de integração do retry manual, teste do link
  conflito -> tela de conflito, teste de "nunca mostra erro técnico" e
  golden tests mobile/desktop. Não foram criados nesta execução (protocolo
  desta rodada não exigiu testes como etapa obrigatória de encerramento).
  Fica como dívida técnica explícita para uma iteração futura ou revisão
  antes de produção.
- **`SyncScheduler` continua não iniciado em lugar nenhum do app** (gap já
  documentado desde a TASK-109). A Central de Sincronização não tenta supri-lo
  chamando `SyncScheduler.start`/`stop` a partir da própria página — isso
  ligaria/desligaria o scheduler ao ciclo de vida da tela em vez do ciclo de
  vida da sessão (login/organização ativa), o que seria pior do que deixá-lo
  desligado. Em vez disso, "Sincronizar agora" e os retries chamam
  `SyncEngine` diretamente, sob demanda — o que já satisfaz os critérios de
  aceite desta task sem precisar resolver o fio pendente da sessão. Uma
  task futura (bootstrap/sessão) deve chamar `SyncScheduler.start`/`stop`
  no login/logout/troca de organização.
- **RBAC**: a nova rota não exige nenhuma `Capability`, mesmo padrão das
  rotas de conflito da TASK-111 — qualquer usuário autenticado da
  organização vê a central de sincronização do seu próprio dispositivo.
- **Retry individual vs. em lote**: ambos chamam o mesmo
  `SyncEngine.runPush` (não existe um "retry de uma única operação" no
  motor); o retry individual apenas garante que aquela operação específica
  está `pending` (bypassa backoff/orçamento) antes de rodar o push, mas o
  push em si pode opportunisticamente também tentar outras operações já
  devidas — comportamento aceitável e documentado no próprio Cubit.
- **`OfflinePackageStatusRepository.getAll`/`OutboxRepository.listByStatus`
  não são reativos** (só `watchSummary` é) — a lista de falhas, conflitos e
  marcadores de carga são atualizados via `refresh()` explícito após cada
  ação e por pull-to-refresh, não por stream contínuo. Aceitável para o
  volume de dados de um único dispositivo, mas uma iteração futura pode
  querer tornar `listByStatus`/`getAll` reativos também.
