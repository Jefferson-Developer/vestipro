# TASK-113 — Implementar indicador de conectividade (CONCLUÍDA)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### Estado de conectividade e observabilidade

- `ConnectivityIndicatorState` define os 4 estados exigidos pela task:
  `onlineSynced`, `onlineSyncing`, `offlinePending` e `offlineNoPending`.
- `ConnectivityIndicatorCubit` combina `ConnectivityService` com
  `OutboxRepository.watchSummary(...)` para produzir um estado único e reativo
  do banner de conectividade por `organizationId`/`companyId`.
- O Cubit registra o evento de Analytics
  `connectivity_status_changed`, incluindo status anterior/atual, contagens da
  Outbox e `offline_duration_ms` quando há reconexão.

### UI do indicador

- `AppConnectivityIndicator` foi criado no Design System como um banner de
  feedback no topo da tela, com ícone, texto e cor sem depender apenas de cor
  para transmitir estado.
- `ConnectivityIndicatorShell` encapsula páginas elegíveis em um `Column`,
  renderiza o banner acima do conteúdo principal e navega para
  `SyncCenterRoute` ao toque, transformando o indicador em um atalho útil para
  diagnóstico de sincronização.
- Foram gerados goldens mobile, tablet e desktop para os 4 estados visuais do
  componente.

### Integração no app

- `bootstrap.dart` passou a envolver as principais rotas autenticadas e
  escopadas por empresa com `_withConnectivityIndicator(...)`, cobrindo
  catálogo, clientes, produtos, pedidos, histórico, aprovação e central de
  sincronização.
- `lib/core/connectivity/connectivity.dart`,
  `lib/core/design_system/components/components.dart` e
  `lib/features/orders/orders.dart` agora exportam os novos blocos para uso no
  restante do app.

### Fluxo de submissão de pedido offline

- Foi extraído `submitOrderFromDraft(...)` para
  `lib/features/orders/presentation/order_submission_flow.dart`, isolando a
  regra de submissão do pedido para reuso e teste.
- A submissão em `bootstrap.dart` agora usa esse fluxo e trata
  `ConnectivityFailure` com uma mensagem honesta via `AppSnackbar`:
  o pedido permanece salvo localmente no dispositivo e pode ser enviado quando
  a conexão voltar.
- Deliberadamente não foi prometido envio automático, porque o codebase ainda
  não possui handlers reais de Outbox para submissão de pedidos.

## Arquivos criados

- `lib/core/connectivity/presentation/cubit/connectivity_indicator_state.dart`
- `lib/core/connectivity/presentation/cubit/connectivity_indicator_cubit.dart`
- `lib/core/connectivity/presentation/widgets/connectivity_indicator_shell.dart`
- `lib/core/design_system/components/feedback/app_connectivity_indicator.dart`
- `lib/features/orders/presentation/order_submission_flow.dart`
- `test/core/connectivity/presentation/cubit/connectivity_indicator_cubit_test.dart`
- `test/core/connectivity/presentation/widgets/connectivity_indicator_shell_test.dart`
- `test/core/design_system/components/app_connectivity_indicator_test.dart`
- `test/core/design_system/components/goldens/design_system_connectivity_indicator_golden_test.dart`
- `test/features/orders/presentation/order_submission_flow_test.dart`
- `docs/tasks/TASK-113-implementar-indicador-de-conectividade-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/app/bootstrap.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/core/connectivity/connectivity.dart`
- `lib/core/design_system/components/components.dart`
- `lib/features/orders/data/datasources/cloud_functions_order_approval_data_source.dart`
- `lib/features/orders/data/datasources/cloud_functions_order_submission_data_source.dart`
- `lib/features/orders/orders.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/core/sync/presentation/cubit/outbox_watcher_cubit_test.dart`
- `test/features/orders/domain/usecases/add_items_to_order_draft_use_case_test.dart`
- `docs/tasks/TASKS.md`

## Validações executadas

- `flutter analyze` — sucesso, sem issues.
- `flutter test test/core/connectivity/presentation/cubit/connectivity_indicator_cubit_test.dart test/core/design_system/components/app_connectivity_indicator_test.dart test/core/connectivity/presentation/widgets/connectivity_indicator_shell_test.dart test/features/orders/presentation/order_submission_flow_test.dart` — sucesso.
- `flutter test --update-goldens test/core/design_system/components/goldens/design_system_connectivity_indicator_golden_test.dart` — sucesso.
- `dart format --set-exit-if-changed .` — sucesso.
- `flutter test` — sucesso, com todos os testes passando.

## Decisões e riscos conhecidos

- O indicador usa texto + ícone + cor para manter acessibilidade básica e não
  depender apenas de cor para diferenciar estados.
- O clique no banner leva para a Central de Sincronização em vez de abrir um
  detalhe inline, reaproveitando a UI já existente para diagnóstico e retry.
- A submissão offline de pedido ainda **não entra automaticamente na Outbox**;
  por isso o feedback ao usuário foi ajustado para refletir o comportamento
  real do produto neste momento.
- Durante `flutter test` apareceram avisos já existentes do Drift sobre
  múltiplas instâncias de banco em alguns testes; não houve falha associada.
