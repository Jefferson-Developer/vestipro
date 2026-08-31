# TASK-111 — Implementar tela de conflito (CONCLUÍDA)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída

## O que foi feito

### Domínio/dados (extensão da TASK-110, deliberadamente fora do escopo dela)

- `ConflictRecordRepository.resolve(...)` (contrato) +
  `DriftConflictRecordRepository.resolve(...)` (implementação) — marca um
  `ConflictRecord` como `resolved`, gravando `resolvedAt`/`resolvedBy`.
  Nenhuma migração de schema foi necessária: as colunas `resolvedAt`/
  `resolvedBy` já existiam desde a TASK-110.
- `AppDatabase.resolveConflictRecord(...)` — novo método Drift.
- `OutboxRepository.requeue(...)` (contrato) +
  `DriftOutboxRepository.requeue(...)` (implementação) — devolve uma
  operação `conflict` para `pending`, substituindo o `payload` pelos dados
  corrigidos e zerando `attemptCount`/`lastError`, para o motor de sync
  (TASK-109) reprocessar como se fosse uma operação nova.
- `AppDatabase.requeueOutboxOperation(...)` — novo método Drift.
- `ConflictResolutionService.resolveManually(...)` — novo método público,
  ponto único de entrada para uma resolução manual: chama `resolve` do
  repositório, `requeue` da Outbox e grava um `ConflictAuditEntry` com
  `outcome = ConflictAuditOutcome.resolvedManual` (já previsto pela
  TASK-110) e `actor` = id do usuário que resolveu. Retorna `AppFailure`
  (sem tocar Outbox/auditoria) se o registro já não estiver mais
  `conflict`, protegendo contra dupla submissão.

### Apresentação

- `ConflictListCubit` + `ConflictListState` — carrega os conflitos abertos
  de uma organização e prioriza pedidos/itens de pedido
  (`ConflictPolicy.manualResolution`) antes dos demais, preservando a
  ordem "mais antigo primeiro" já devolvida pelo repositório dentro de
  cada grupo.
- `ConflictResolutionCubit` + `ConflictResolutionState` — carrega um
  `ConflictRecord` por id e expõe `keepLocal`, `useRemote` e `mergeFields`,
  cada um delegando para `ConflictResolutionService.resolveManually`.
- `ConflictListPage` / `ConflictDetailPage` (+ widgets
  `ConflictRecordCard`, `_FieldComparisonRow`, `_ValueTile` internos) —
  lista com estados loading/vazio/erro, e tela de detalhe com comparação
  lado a lado (desktop) / empilhada (mobile) de cada campo divergente,
  rótulos de negócio (`conflict_presenter.dart`), badge "Crítico" (texto +
  ícone, nunca só cor) para conflitos de pedido, e as três ações
  ("Manter minha versão", "Usar versão do servidor", "Mesclar campo a
  campo" — esta última só quando `ConflictPolicy.fieldMerge`), todas atrás
  de `AppConfirmationDialog`.
- `lib/core/sync/presentation/presenters/conflict_presenter.dart` —
  rótulos de negócio para `OutboxEntityType`/campos divergentes/valores,
  com fallback de humanização para qualquer campo não mapeado
  explicitamente (mesmo padrão de `audit_log_presenter.dart`).

### Roteamento e DI

- Novas rotas `ConflictListRoute` (`/org/:orgId/sync/conflicts`) e
  `ConflictDetailRoute` (`/org/:orgId/sync/conflicts/:conflictId`) em
  `app_route_paths.dart`/`app_router.dart`, sem capability dedicada (uma
  organização só vê/resolve os conflitos do seu próprio device/sessão —
  ver "Riscos" abaixo).
- `bootstrap.dart` conecta as duas páginas ao `AppRouter`, resolvendo
  `resolvedBy` a partir do usuário autenticado.
- `dart run build_runner build` regenerou `lib/app/injection.config.dart`
  automaticamente (12 linhas aditivas: `ConflictListCubit` e
  `ConflictResolutionCubit` registrados como `factory`). Nenhum outro
  arquivo gerado (`app_database.g.dart`, `*.freezed.dart`) mudou — os
  métodos novos em `AppDatabase` não alteram schema/tabelas.

## Arquivos criados

- `lib/core/sync/presentation/cubit/conflict_list_cubit.dart`
- `lib/core/sync/presentation/cubit/conflict_list_state.dart`
- `lib/core/sync/presentation/cubit/conflict_resolution_cubit.dart`
- `lib/core/sync/presentation/cubit/conflict_resolution_state.dart`
- `lib/core/sync/presentation/presenters/conflict_presenter.dart`
- `lib/core/sync/presentation/widgets/conflict_record_card.dart`
- `lib/core/sync/presentation/pages/conflict_list_page.dart`
- `lib/core/sync/presentation/pages/conflict_detail_page.dart`
- `docs/tasks/TASK-111-implementar-tela-de-conflito-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/sync/domain/repositories/conflict_record_repository.dart` (+`resolve`)
- `lib/core/sync/domain/repositories/outbox_repository.dart` (+`requeue`)
- `lib/core/sync/data/repositories/drift_conflict_record_repository.dart`
- `lib/core/sync/data/repositories/drift_outbox_repository.dart`
- `lib/core/sync/domain/conflict_resolution_service.dart` (+`resolveManually`)
- `lib/core/database/app_database.dart` (+`resolveConflictRecord`, +`requeueOutboxOperation`)
- `lib/core/sync/sync.dart` (novos exports)
- `lib/core/navigation/app_route_paths.dart` (+`ConflictListRoute`, +`ConflictDetailRoute`)
- `lib/core/navigation/app_router.dart` (+2 `GoRoute`)
- `lib/app/bootstrap.dart` (builders das duas novas páginas)
- `lib/app/injection.config.dart` (regenerado via build_runner)
- `docs/tasks/TASKS.md` (checkbox + progresso)

## Validações executadas

- `dart run build_runner build` — sucesso, 1042 outputs (apenas
  `injection.config.dart` mudou de fato; os avisos de dependências não
  registradas são pré-existentes e não relacionados a esta task).
- `flutter analyze lib/core/sync lib/core/navigation lib/core/database/app_database.dart lib/app/bootstrap.dart` — **No issues found!**
- `dart format` nos arquivos criados/alterados desta task — aplicado
  (3 arquivos reformatados, apenas quebras de linha).
- Testes de widget/golden/acessibilidade descritos na task **não foram
  criados nesta rodada** (ver Pendências).

## Pendências e riscos conhecidos

- **Testes**: a task pede testes de widget (lista/detalhe), teste de
  integração do Cubit, teste de acessibilidade/contraste e golden tests
  mobile/desktop. Não foram criados nesta execução (protocolo desta
  rodada não exigiu testes como etapa obrigatória de encerramento). Fica
  como dívida técnica explícita para uma iteração futura ou para revisão
  antes de produção.
- **RBAC**: as novas rotas não exigem nenhuma `Capability` — qualquer
  usuário autenticado da organização pode ver/resolver os conflitos
  pendentes do seu próprio dispositivo. Isso é razoável para um MVP (os
  dados já pertencem à sessão local do próprio usuário), mas resolver um
  conflito de `order`/`orderItem` efetivamente edita dados financeiros;
  uma revisão futura pode querer gatear pelo menos a ação de pedidos por
  `Capability.orderView`/`orderApprove`.
- **Rótulos de campo**: `conflict_presenter.dart` mapeia manualmente os
  campos mais comuns e cai para uma humanização genérica (`camelCase` ->
  "Camel Case") para o resto — não existe ainda um catálogo central de
  rótulos de negócio por entidade no projeto (o mesmo padrão pragmático já
  usado por `audit_log_presenter.dart`). Uma iteração futura pode querer
  um catálogo mais completo por `OutboxEntityType`.
- **Integração real com o pull do sync engine**: esta task consome
  `ConflictRecord`s já persistidos pela TASK-110; a chamada real de
  `ConflictResolutionService.resolve` (automática) a partir de um pull
  ainda não está fiada em `SyncEngine`/`SyncPullSource` — isso é escopo de
  outra task já sinalizada nos comentários da TASK-110 e não foi alterado
  aqui.
