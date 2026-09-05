# TASK-153 — Implementar notificações comerciais (CONCLUÍDA)

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ✅ Concluída

## Resumo

Reaproveitou a infraestrutura já existente da central de notificações internas (TASK-151) e
adicionou dois novos geradores de notificação comercial — pedido com problema (rejeitado ou com
falha crítica de sincronização) e oportunidade comercial "quente" identificada pela engine de
insights (EPIC-16) — além de uma prioridade visual (crítico vs. informativo) explícita para toda
notificação comercial, incluindo o alerta de meta (TASK-149/120) já existente.

## O que já existia (reaproveitado, não recriado)

- `lib/core/notifications/**` (TASK-151): entidade `AppNotification`, `NotificationInboxRepository`
  (Firestore + cache local, offline-first), `NotificationCenterBloc`/`NotificationCenterPage`.
- `ProcessTargetAlertUseCase` (TASK-149/120, `lib/features/targets/domain/usecases/`): já gerava
  notificação categoria `commercial` para meta em risco/oportunidade — reaproveitado e estendido
  (ver abaixo), não reescrito.
- `ProcessCrmTaskReminderUseCase`/`GenerateCrmTaskRemindersUseCase` (TASK-152): padrão de
  "use case single-item + orquestrador batch, disparado client-side quando a lista já carregada
  soma o RBAC do chamador" — mesmo padrão replicado para pedidos e insights.
- `Insight`/`InsightSeverity`/`InsightType`/`ListOpportunityCenterInsightsUseCase`/
  `InsightVisibilityService` (EPIC-16): fonte das "oportunidades quentes", já com RBAC/carteira
  resolvidos.
- `Order`/`OrderStatus.rejected`/`OrderSyncStatus.failed`/`OrderListBloc` (EPIC-13/14): fonte dos
  "pedidos com problema", já com RBAC/visibilidade resolvidos via `Capability.orderView`/
  `OrderVisibilityService`.
- `OrderHistoryRoute`/`OpportunityCenterRoute`/`TargetDashboardRoute` (navegação tipada existente):
  usadas como deep link, sem criar nenhuma rota nova.

## O que foi adicionado

### 1. Prioridade visual (crítico vs. informativo) — acessível, não só por cor

- `AppNotificationPriority { critical, informative }` em
  `lib/core/notifications/domain/entities/app_notification.dart` (campo `priority`, default
  `informative` para não quebrar nenhum chamador pré-TASK-153).
- `NotificationDto`/`NotificationMapper`/`NotificationInboxLocalCache` (todos em
  `lib/core/notifications/data/`) persistem/lêem `priority`, com fallback para `informative` quando
  o campo está ausente (documento gravado antes desta task) — nunca lança exceção por causa disso.
- `firestore.rules`: `priority` adicionado à lista de campos imutáveis no `update` do match
  `organizations/{organizationId}/notifications/{notificationId}` (`unchanged('priority')`), mesmo
  padrão de `category`/`title`/`body`/`deepLink`/`createdAt` já existentes.
- `AppNotificationListTile` (`lib/core/design_system/components/notifications/`): novo parâmetro
  `isCritical` — quando `true`, renderiza `AppStatusBadge(label: 'Crítico', icon: Icons.priority_high)`
  (ícone + texto, nunca só cor) e inclui "crítico" no `Semantics.label`. `NotificationCenterPage`
  já passa `isCritical: notification.priority == AppNotificationPriority.critical`.
- `ProcessTargetAlertUseCase` (TASK-149) atualizado: `highRisk` → `critical`; `moderateRisk`/
  `opportunity` → `informative`.

### 2. Notificação de pedido com problema

- `OrderCommercialAlertClassification { rejected, criticalSyncFailure }`
  (`lib/features/orders/domain/value_objects/`).
- `OrderCommercialAlertDispatchRepository` (dedup permanente por
  organização+pedido+classificação+destinatário — um pedido só transiciona para `rejected`/sync
  `failed` uma vez, não há cooldown) +
  `SharedPreferencesOrderCommercialAlertDispatchRepository` (`lib/features/orders/data/repositories/`).
- `ProcessOrderCommercialAlertUseCase` (`lib/features/orders/domain/usecases/`): classifica o pedido,
  verifica `Capability.financeView` via `PermissionService` para decidir se inclui o valor dos itens
  no corpo da notificação (RBAC: `SALES_REP` sempre é notificado, nunca vê o valor; `FINANCE`/
  `OWNER`/`ADMIN` veem), monta o deep link (`OrderHistoryRoute`), cria a notificação
  (`category: commercial`, `priority: critical`) e loga `AnalyticsEvents.commercialOrderAlertTriggered`
  (sem nenhum dado financeiro no evento).
- `GenerateOrderCommercialAlertsUseCase`: orquestra o use case acima para uma lista de pedidos.
- `OrderListBloc` (`lib/features/orders/presentation/bloc/`): novo parâmetro construtor opcional
  `generateOrderCommercialAlerts` (default `null`, não quebra nenhum chamador/teste existente),
  disparado uma vez por carregamento completo (`_onStarted`/`_onRefreshRequested`/`_onRetried`),
  sobre `[...localPendingOrders, ...orders]` — exatamente o mesmo recorte de RBAC/visibilidade que já
  restringe a própria listagem.

### 3. Notificação de oportunidade comercial "quente" (engine de insights, EPIC-16)

- `kHotOpportunityInsightTypes` (`crossSell`, `upSell`, `customerGrowth`,
  `replenishmentSuggestion`) — os tipos de insight "de alta" (não os de risco, que já têm sua
  própria superfície na Central de Oportunidades) — e severidade `high`/`critical` definem o que
  conta como "quente".
- `InsightAlertDispatchRepository` (dedup por `Insight.deduplicationKey`, com cooldown de 24h — a
  mesma oportunidade pode legitimamente continuar "quente" depois da primeira notificação, ao
  contrário de um pedido) + `SharedPreferencesInsightAlertDispatchRepository`
  (`lib/features/insights/data/repositories/`).
- `ProcessInsightCommercialAlertUseCase` (`lib/features/insights/domain/usecases/`): monta a
  notificação a partir do próprio `title`/`recommendation` do insight, prioridade `critical` apenas
  quando `severity == critical`, deep link para `InsightAction.route` (fallback para
  `OpportunityCenterRoute`), loga `AnalyticsEvents.commercialOpportunityAlertTriggered`.
- `GenerateInsightCommercialAlertsUseCase`: orquestra para uma lista de insights.
- `OpportunityCenterBloc` (`lib/features/insights/presentation/bloc/`): novo parâmetro nomeado
  opcional `generateInsightCommercialAlerts`, disparado uma vez por primeira página carregada
  (nunca em paginação/scroll).

### 4. Analytics

`AnalyticsEvents.commercialOrderAlertTriggered` e
`AnalyticsEvents.commercialOpportunityAlertTriggered` adicionados ao catálogo
(`lib/core/analytics/analytics_events.dart`), nenhum carregando dado financeiro/pessoal.

## Decisões e simplificações documentadas

- Recorte de destinatário sempre é o próprio usuário autenticado que carregou a lista (nunca
  resolvido a partir de `Order.sellerId`/`Insight.recipientUserId` diretamente) — mesma razão dupla
  já documentada em `ProcessCrmTaskReminderUseCase`: (1) `firestore.rules` só permite
  `create` de notificação com `userId == request.auth.uid`; (2) o pedido/insight só chega a este use
  case porque o RBAC/visibilidade de quem carregou a lista já autorizou vê-lo — logo "só quem pode
  ver, é notificado" vale por construção.
- Dedup de pedido é permanente (sem cooldown) porque `rejected`/sync `failed` é um estado terminal
  por ocorrência real; dedup de insight usa cooldown de 24h porque uma oportunidade pode continuar
  válida por dias.
- Cooldown do alerta de insight é uma constante fixa (`kInsightCommercialAlertCooldown`), não uma
  configuração por organização — TASK-120 já tem essa configuração para metas; estendê-la para
  insights ficou fora do escopo desta task por proporcionalidade de esforço.

## Riscos/pendências conhecidos (documentados no código, não bloqueiam a task)

- Não há testes de Firestore Rules (positivo/negativo) dedicados à collection `notifications` —
  gap pré-existente desde TASK-151/152 (nenhum teste de rules foi criado para essa collection até
  hoje); a única mudança de rule desta task (`unchanged('priority')`) segue exatamente o mesmo
  padrão já usado para os demais campos imutáveis do mesmo `match`, então o risco de regressão é
  baixo, mas fica registrado como débito herdado.
- `SharedPreferences...DispatchRepository` (pedido e insight, como os já existentes de meta/CRM) é
  local-only: reinstalar o app ou agir de um segundo dispositivo pode re-exibir um alerta já visto
  uma vez — aceito, mesmo trade-off já assumido pelas TASK-149/152.
- Valor monetário incluído no corpo da notificação de pedido usa `Order.itemsSubtotal` (soma dos
  itens já capturados), não um total definitivo pós-descontos/frete/impostos (que é concern de
  pricing server-side fora do escopo desta task) — é só texto informativo, nunca uma fonte de
  verdade de preço.

## Arquivos criados

- `lib/features/orders/domain/value_objects/order_commercial_alert_classification.dart`
- `lib/features/orders/domain/repositories/order_commercial_alert_dispatch_repository.dart`
- `lib/features/orders/data/repositories/shared_preferences_order_commercial_alert_dispatch_repository.dart`
- `lib/features/orders/domain/usecases/process_order_commercial_alert_use_case.dart`
- `lib/features/orders/domain/usecases/generate_order_commercial_alerts_use_case.dart`
- `lib/features/insights/domain/repositories/insight_alert_dispatch_repository.dart`
- `lib/features/insights/data/repositories/shared_preferences_insight_alert_dispatch_repository.dart`
- `lib/features/insights/domain/usecases/process_insight_commercial_alert_use_case.dart`
- `lib/features/insights/domain/usecases/generate_insight_commercial_alerts_use_case.dart`
- `test/features/orders/domain/usecases/process_order_commercial_alert_use_case_test.dart`
- `test/features/insights/domain/usecases/process_insight_commercial_alert_use_case_test.dart`
- `test/core/design_system/components/notifications/app_notification_list_tile_test.dart`
- `test/core/notifications/data/mappers/notification_mapper_test.dart`
- `docs/tasks/TASK-153-implementar-notificacoes-comerciais-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/notifications/domain/entities/app_notification.dart`
- `lib/core/notifications/data/dtos/notification_dto.dart`
- `lib/core/notifications/data/mappers/notification_mapper.dart`
- `lib/core/notifications/data/local/notification_inbox_local_cache.dart`
- `lib/core/notifications/data/repositories/notification_inbox_repository_impl.dart`
- `lib/core/notifications/presentation/pages/notification_center_page.dart`
- `lib/core/design_system/components/notifications/app_notification_list_tile.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/features/targets/domain/usecases/process_target_alert_use_case.dart`
- `lib/features/orders/presentation/bloc/order_list_bloc.dart`
- `lib/features/orders/orders.dart`
- `lib/features/insights/presentation/bloc/opportunity_center_bloc.dart`
- `lib/features/insights/insights.dart`
- `firestore.rules`
- `lib/app/injection.config.dart` (regenerado via `dart run build_runner build`)
- `test/features/targets/domain/usecases/process_target_alert_use_case_test.dart`
- `docs/tasks/TASKS.md` (checkbox + progresso)

## Validações executadas (reais, com resultado)

- `dart run build_runner build` — sucesso; `OrderCommercialAlertDispatchRepository`,
  `InsightAlertDispatchRepository`, `ProcessOrderCommercialAlertUseCase`,
  `ProcessInsightCommercialAlertUseCase`, `GenerateOrderCommercialAlertsUseCase`,
  `GenerateInsightCommercialAlertsUseCase` registrados corretamente em `injection.config.dart`, e
  `OrderListBloc`/`OpportunityCenterBloc` passaram a resolver os novos parâmetros opcionais via DI.
- `flutter analyze` (projeto inteiro) — apenas os 12 avisos `info` pré-existentes (deprecações do
  Flutter em `report_builder_page.dart` e lints de estilo em testes de dashboards não relacionados),
  nenhum erro novo.
- `flutter test` nos diretórios afetados (`test/features/orders`, `test/features/insights`,
  `test/features/targets`, `test/features/crm`, `test/core/notifications`,
  `test/core/design_system/components/notifications`,
  `test/core/design_system/components/badges`) — **441 testes, todos passando**, incluindo os
  novos arquivos desta task.
- `dart format` nos arquivos criados/alterados desta task — aplicado (5 arquivos reformatados,
  conteúdo já revisado após a formatação).

## Push

Não realizado (fora do escopo desta rodada) — apenas commit local.
