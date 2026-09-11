# TASK-214 — Concluída (2026-09-11)

## Resumo

Implementado o ciclo pós-faturamento de expedição, romaneio, tracking e ocorrências (EPIC-32):
`Shipment`/romaneio (volumes/itens congelados no momento da criação), `TrackingEvent` (histórico
append-only de marcos — separação, embalagem, expedição, trânsito, saiu para entrega, entrega
total/parcial, devolução à transportadora, ajuste/correção) e `LogisticsIssue` (ocorrência com tipo,
responsável e próxima ação obrigatórios). Pela primeira vez neste código, um evento de tracking
avança de fato o `Order.status` para `shipped`/`delivered` (mirror exato das arestas relevantes de
`OrderStatusTransitionValidator`), fechando a lacuna que existia desde a TASK-095/TASK-201 (que só
tinha uma timeline informal de pós-venda, sem nunca tocar o status real do pedido). Toda atualização
de tracking passa por um único caminho idempotente (`applyTrackingEvent`), reaproveitado tanto pelo
lançamento manual/administrativo (`registerTrackingEvent`, callable autenticado) quanto pela
integração externa (`handleShipmentTrackingWebhook`, HTTP assinado por HMAC, idempotente por
`externalEventId`). Entrega parcial é resolvida server-side a partir de um ledger acumulado por
item/volume, nunca confiando no rótulo que o chamador/webhook atribuiu ao evento. Ocorrências geram
notificação ao vendedor (via bridge com `postSaleEvents`, TASK-201) e, quando o responsável é outra
pessoa (ex.: gestor logístico), uma notificação direta adicional. Um scan diário
(`detectShipmentDelays`) abre automaticamente uma ocorrência de atraso quando o prazo estimado de
entrega é ultrapassado. O portal B2B do cliente passou a exibir o status de rastreio da expedição
mais recente de cada pedido, sempre escopado ao próprio cliente (Admin SDK), nunca expondo dado de
outro cliente.

## Agentes utilizados

- `flutter-senior-architect` (modelagem de domínio, Cloud Functions, idempotência, bridge com
  `Order.status`, RBAC, Firestore Rules/Indexes, integração com o webhook e com o portal B2B).
- `flutter-ui-design-specialist` (seção "Rastreio da entrega" no histórico do pedido, estados de
  loading/vazio/erro, timeline de tracking, cartão de ocorrência e formulário de registro).
- `vestipro-commercial-ops-strategist` (definição de quando o pedido pode avançar para expedição,
  amplitude do RBAC de expedição, integração com a timeline de pós-venda já existente).
- `vestipro-sales-representative-specialist` (garantir que vendedor/gestor consigam reportar e
  resolver uma ocorrência sem sair do histórico do pedido).

## Arquivos criados

Backend (Cloud Functions), `functions/src/fulfillment/`:

- `fulfillment-shared.ts` — enums/tipos (`ShipmentStatus`, `TrackingEventType`,
  `TrackingEventSource`, `LogisticsIssueType`/`Status`), `isShipmentEligibleOrderStatus`,
  `resolveOrderStatusForTrackingEvent` (bridge para `Order.status`), `shipmentStatusForMilestone`,
  `buildShipmentPackages`/`sumShippedQuantities` (validação de volumes contra o pedido e contra
  expedições anteriores), `totalQuantityByOrderItem`/`applyDeliveredItems`/`resolveDeliveryStatus`
  (ledger de entrega parcial/total), `computeTrackingEventId` (id determinístico para idempotência
  de webhook), `ROLES_ALLOWED_TO_MANAGE_SHIPMENT`. Reaproveita `ensureRequesterMayActOnOrder`/
  `mapReturnRequestOrder` de `returns/return-shared.ts` em vez de duplicar a lógica de "quem pode
  agir neste pedido".
- `create-shipment.ts` — callable `createShipment` (idempotente por `shipmentId`, exige pedido
  `invoiced`/`partially_invoiced`).
- `register-tracking-event.ts` — callable `registerTrackingEvent` (lançamento manual/administrativo)
  + `applyTrackingEvent`, o núcleo transacional único reaproveitado pelo webhook.
- `handle-shipment-tracking-webhook.ts` — `handleShipmentTrackingWebhook` (HTTP, assinatura HMAC via
  `webhooks/webhook-shared.ts`, idempotente por `externalEventId`).
- `provision-shipment-webhook-secret.ts` — callable `provisionShipmentWebhookSecret` (OWNER/ADMIN).
- `register-logistics-issue.ts` — callable `registerLogisticsIssue` (ocorrência com responsável e
  próxima ação obrigatórios; notifica vendedor via `postSaleEvents` e o responsável quando distinto).
- `resolve-logistics-issue.ts` — callable `resolveLogisticsIssue` (recomputa `hasOpenIssue` a partir
  do ledger real de ocorrências abertas).
- `detect-shipment-delays.ts` — scheduled `detectShipmentDelays` (diária, abre ocorrência `delay`
  automática por expedição em atraso, uma vez por expedição).
- `index.ts` — barrel.
- `functions/test/fulfillment/fulfillment-shared.test.ts` — 29 testes unitários (elegibilidade,
  transições de status do pedido válidas/inválidas, mapeamento de marco → status da expedição,
  validação de volumes, ledger de entrega parcial/total, idempotência determinística do id de
  webhook).
- `functions/test/fulfillment/fulfillment-integration.emulator.test.ts` — 7 testes de integração
  (Firestore Emulator): elegibilidade de criação, idempotência de `createShipment`, bridge real
  `invoiced -> shipped -> delivered`, idempotência de `registerTrackingEvent` por `trackingEventId`,
  acumulação de duas entregas parciais com itens distintos até entrega total, notificação ao
  responsável de uma ocorrência e limpeza de `hasOpenIssue` após resolução.

Frontend (Flutter), feature `lib/features/fulfillment/`:

- `fulfillment.dart` (barrel).
- `domain/value_objects/shipment_status.dart`, `tracking_event_type.dart` (+ `TrackingEventSource`),
  `logistics_issue_type.dart` (+ `LogisticsIssueStatus`).
- `domain/entities/shipment_package_item.dart` (+ `DeliveredItem`), `shipment_package.dart`,
  `shipment.dart`, `tracking_event.dart`, `logistics_issue.dart`.
- `domain/repositories/fulfillment_repository.dart`.
- `domain/usecases/fulfillment_use_cases.dart` (Watch Shipments/TrackingEvents/LogisticsIssues,
  Register/Resolve LogisticsIssue).
- `data/dtos/shipment_dto.dart`, `tracking_event_dto.dart`, `logistics_issue_dto.dart`.
- `data/mappers/fulfillment_mapper.dart`.
- `data/datasources/fulfillment_read_data_source.dart` +
  `firestore_fulfillment_read_data_source.dart`.
- `data/datasources/fulfillment_write_data_source.dart` +
  `cloud_functions_fulfillment_write_data_source.dart`.
- `data/repositories/fulfillment_repository_impl.dart`.
- `presentation/cubit/order_fulfillment_cubit.dart` + `order_fulfillment_state.dart`.
- `presentation/widgets/order_fulfillment_panel.dart` (painel completo: cartão de status da
  expedição mais recente, ocorrências com ação "Marcar como resolvida", formulário "Reportar
  ocorrência", timeline de tracking).
- `test/features/fulfillment/domain/value_objects/shipment_status_test.dart`,
  `tracking_event_type_test.dart`, `logistics_issue_type_test.dart` — round-trip de código.
- `test/features/fulfillment/domain/entities/shipment_test.dart` — `totalQuantity`/
  `totalDeliveredQuantity`/`isFullyDelivered`.
- `test/features/fulfillment/presentation/cubit/order_fulfillment_cubit_test.dart` — 8 testes
  (seleção da expedição mais recente, falha de stream, reportar/resolver ocorrência com e sem
  sucesso, analytics).
- `test/features/fulfillment/presentation/widgets/order_fulfillment_panel_test.dart` — 2 testes de
  widget (estado vazio; resumo da expedição + ação "Reportar ocorrência" visível para SALES_REP).

## Arquivos alterados

- `functions/src/index.ts` — exporta `createShipment`, `registerTrackingEvent`,
  `handleShipmentTrackingWebhook`, `provisionShipmentWebhookSecret`, `registerLogisticsIssue`,
  `resolveLogisticsIssue`, `detectShipmentDelays`.
- `functions/src/customer_portal/load-customer-portal.ts` — `loadCustomerPortal` agora busca as
  expedições do próprio cliente (`where('customerId', '==', customerId)`, mesmo escopo já aplicado a
  `orders`) e anexa `shipmentStatus`/`hasOpenLogisticsIssue`/`estimatedDeliveryDate` da expedição mais
  recente de cada pedido retornado.
- `firestore.rules` — novos blocos `shipments`, `trackingEvents`, `logisticsIssues` (visibilidade
  espelha `canReadOrder`/`canReadPostSaleEvent`: OWNER/ADMIN, SALES_REP dono, SALES_MANAGER da mesma
  equipe, CUSTOMER_PORTAL do próprio cliente; escrita sempre `false`) e `shipmentWebhookSecrets` (sem
  leitura/escrita client-side).
- `firestore.indexes.json` — índices compostos para `shipments` (`orderId+createdAt`,
  `customerId+lastEventAt`, `status+estimatedDeliveryDate`), `trackingEvents`
  (`shipmentId+occurredAt`) e `logisticsIssues` (`shipmentId+createdAt`, `shipmentId+status`).
- `firestore-tests/firestore.rules.test.js` — novos helpers `shipmentDoc`/`trackingEventDoc`/
  `logisticsIssueDoc` e um novo `describe` cobrindo leitura por SALES_REP/SALES_MANAGER/OWNER/ADMIN/
  FINANCE, isolamento cross-tenant, visibilidade do portal B2B (só o próprio cliente),
  impossibilidade de escrita direta e sigilo do `shipmentWebhookSecrets`.
- `lib/core/permissions/capability.dart` / `role_permission_matrix.dart` — nova capability
  `Capability.shipmentManage` (`shipment.manage`), concedida a OWNER/ADMIN (conjunto completo/quase
  completo) e explicitamente a SALES_MANAGER/SALES_REP, mesma amplitude de
  `Capability.postSaleEventRegister`.
- `lib/core/analytics/analytics_events.dart` — novos eventos `logisticsIssueRegistered`
  (`logistics_issue_registered`) e `logisticsIssueResolved` (`logistics_issue_resolved`).
- `lib/features/orders/presentation/pages/order_history_page.dart` — nova seção "Rastreio da
  entrega" com `OrderFulfillmentPanel`, logo após a "Situação financeira" (TASK-213);
  `createFulfillmentPanelCubit` roteado por toda a cadeia de widgets já existente
  (`OrderHistoryPage` → `_OrderHistoryPermissionsGate` → `_OrderHistoryScaffold` →
  `_OrderHistoryContent`).
- `lib/features/customer_portal/domain/entities/customer_portal_models.dart` —
  `CustomerPortalOrder` ganha `shipmentStatus`/`hasOpenLogisticsIssue`/`estimatedDeliveryDate`
  (todos opcionais, sem quebrar o construtor existente).
- `lib/features/customer_portal/data/cloud_functions_customer_portal_repository.dart` — parseia os
  novos campos, reaproveitando `ShipmentStatus.fromCode(...).label` (fulfillment) em vez de duplicar
  a lista de rótulos.
- `lib/features/customer_portal/presentation/pages/customer_portal_page.dart` — subtítulo do pedido
  no portal passa a mostrar o rastreio e um aviso de ocorrência em aberto, quando existentes.
- `lib/app/bootstrap.dart` — importa `features/fulfillment/fulfillment.dart` e registra
  `createFulfillmentPanelCubit` na rota do histórico do pedido.
- `lib/app/injection.config.dart` — regenerado via `build_runner` para as novas classes
  `@injectable`/`@LazySingleton` da feature `fulfillment`.
- `test/core/permissions/role_permission_matrix_test.dart` — novo teste cobrindo a amplitude de
  `Capability.shipmentManage`.
- `docs/tasks/TASKS.md` — checkbox da TASK-214 marcado e `Progresso` atualizado para 210/216.

## Arquitetura utilizada

Clean Architecture + feature-first, idêntica ao padrão já usado por `returns`/`after_sales`/
`receivables`: `Presentation (Cubit) → Use case → Repository contract → Repository impl →
Datasource`. Domain sem Flutter/Firebase. `OrderFulfillmentPanel` nunca acessa Firestore/Cloud
Functions diretamente — sempre via `FulfillmentRepository`/casos de uso injetados por construtor
(`@injectable`), registrados em `injection.config.dart` (regenerado via `build_runner`), nunca
`GetIt.instance` espalhado pela UI. Regra de negócio crítica (elegibilidade de expedição, transição
de `Order.status`, ledger de entrega parcial, idempotência) vive inteiramente nas Cloud Functions —
o Flutter só lê o resultado já resolvido pelo servidor.

## Regras de negócio implementadas

- Um `Shipment` só pode ser criado (`createShipment`) para um pedido em `invoiced`/
  `partially_invoiced` — "Pedido só pode avançar para expedição quando estiver em estado
  comercial/financeiro permitido".
- `TrackingEvent` é sempre append-only: um `adjustment` exige `correctionOfEventId` e nunca move o
  status agregado da expedição — "correção cria novo evento de ajuste, não sobrescreve histórico".
- `registerTrackingEvent`/`handleShipmentTrackingWebhook` reaproveitam o mesmo núcleo transacional
  (`applyTrackingEvent`): o evento `shipped` avança `Order.status` de `invoiced`/`partially_invoiced`
  para `shipped`; o evento `delivered` avança de `shipped` para `delivered` — mirror exato das
  arestas relevantes de `OrderStatusTransitionValidator` (Dart). Nenhuma outra combinação
  evento/status atual jamais força uma transição.
- Entrega parcial/total é resolvida a partir de um ledger acumulado por `orderItemId`
  (`Shipment.deliveredQuantities`), nunca do rótulo (`delivered`/`partially_delivered`) que o
  chamador/webhook atribuiu ao evento — a quantidade entregue nunca pode exceder a quantidade
  expedida por volume.
- Volumes de um romaneio são validados contra os itens reais do pedido e contra a soma já expedida
  em romaneios anteriores do mesmo pedido — nunca é possível expedir mais do que o pedido contém.
- Webhook de transportadora é idempotente por `externalEventId` (id determinístico via hash
  `carrierId+shipmentId+externalEventId`); lançamento manual/administrativo é idempotente pelo
  `trackingEventId` gerado pelo cliente.
- `LogisticsIssue` sempre carrega responsável e próxima ação obrigatórios; resolução recomputa
  `Shipment.hasOpenIssue` a partir do ledger real de ocorrências ainda abertas, nunca um flip
  isolado.
- Ocorrência e marcos relevantes (`shipped`→despachado, `in_transit`/`out_for_delivery`→em trânsito,
  `delivered`/`partially_delivered`→entregue, ocorrência→problema reportado, resolução→resolvido) são
  espelhados na timeline de pós-venda já existente (`postSaleEvents`, TASK-201), reaproveitando a
  notificação ao vendedor que `appendPostSaleEvent` já dispara — sem duplicar essa lógica.
- Detecção automática de atraso (`detectShipmentDelays`, diária) abre no máximo uma ocorrência
  `delay` por expedição (id determinístico `delay_${shipmentId}`) quando `estimatedDeliveryDate` é
  ultrapassado e a expedição ainda está aberta.
- Cliente externo (portal) só enxerga o rastreio dos próprios pedidos — o snapshot do portal é
  montado inteiramente pelo Admin SDK (`loadCustomerPortal`), nunca por leitura direta do Firestore
  pelo cliente.

## Regras Firebase implementadas

- `firestore.rules`: `shipments`, `trackingEvents`, `logisticsIssues` — leitura só para quem já
  poderia ler o pedido correspondente (OWNER/ADMIN, SALES_REP dono, SALES_MANAGER da mesma equipe,
  CUSTOMER_PORTAL do próprio cliente); toda escrita `false` (mediada exclusivamente pelas Cloud
  Functions). `shipmentWebhookSecrets` — sem leitura/escrita client-side (mesmo padrão de
  `paymentWebhookSecrets`, TASK-193).
- Cloud Functions sempre revalidam a Membership real do chamador (`loadActiveMembership`) e a
  amplitude de "quem pode agir neste pedido" (`ensureRequesterMayActOnOrder`, reaproveitado de
  `returns/return-shared.ts`) — nunca confiam em `organizationId`/role vindos do cliente.
- `firestore.indexes.json` — seis índices compostos novos cobrindo as consultas do painel
  (`shipments` por pedido/cliente/status+prazo, `trackingEvents`/`logisticsIssues` por expedição).

## Analytics implementado

- `logistics_issue_registered` (`AnalyticsEvents.logisticsIssueRegistered`) — `order_id`/
  `issue_type` como parâmetros, nunca a descrição livre.
- `logistics_issue_resolved` (`AnalyticsEvents.logisticsIssueResolved`) — `order_id`/`issue_type`
  como parâmetros, nunca a nota de resolução.
- Nenhum evento novo para criação de expedição/lançamento de tracking manual: essas ações ainda não
  têm uma tela dedicada nesta rodada (ver "Pendências"); quando existir, deve reaproveitar este mesmo
  padrão de parâmetros não sensíveis.

## Crashlytics implementado

Sem mudança dedicada — os fluxos novos reutilizam o tratamento de erro genérico já existente
(`AppResult`/`AppFailure`, `mapAppExceptionToFailure`) que já alimenta Crashlytics/logging
centralizados do app, mesmo padrão de TASK-212/TASK-213.

## Impacto offline

Leitura (`watchShipmentsForOrder`/`watchTrackingEvents`/`watchLogisticsIssues`) depende de streams
em tempo real do Firestore (mesmo padrão de `ReturnRequestHistoryCubit`/`PostSaleTimelineCubit`) —
sem cache offline dedicado nesta rodada: o SDK do Firestore já mantém cache local para leitura
recente, mas não há fila de escrita offline para "reportar ocorrência"/"resolver ocorrência" (essas
ações exigem conectividade, mesma limitação já aceita para devoluções/trocas/pós-venda). O painel
mostra corretamente o estado de carregamento/erro quando a leitura falha, nunca trava a tela do
pedido.

## Impacto multi-tenant

Toda leitura/escrita de expedição/tracking/ocorrência é escopada por `organizationId`, revalidada
server-side a partir da Membership real do chamador — nunca a partir de campos enviados pelo
cliente. O scan de atraso (`detectShipmentDelays`) itera por organização
(`organizations/{organizationId}/shipments`), nunca cruza dados entre tenants. O snapshot do portal
B2B filtra expedições exclusivamente pelo `customerId` do próprio vínculo `CUSTOMER_PORTAL`.

## Testes criados

- `functions/test/fulfillment/fulfillment-shared.test.ts` — 29 testes: elegibilidade de status do
  pedido, validação/rejeição de tipos de evento e ocorrência, transições válidas/inválidas de
  `Order.status`, mapeamento marco→status de expedição, validação de volumes (item pertence ao
  pedido, número de volume único, saldo entre expedições), ledger de entrega parcial/total
  (acumulação, nunca excede o total, item não pertencente rejeitado, mapa de entrada nunca mutado) e
  determinismo do id de webhook.
- `functions/test/fulfillment/fulfillment-integration.emulator.test.ts` — 7 testes contra o
  Firestore Emulator (não executável neste ambiente, ver "Comandos executados"): elegibilidade e
  idempotência de `createShipment`, bridge real de `Order.status` (`invoiced -> shipped ->
  delivered`), idempotência de `registerTrackingEvent`, acumulação de duas entregas parciais
  distintas até entrega total, notificação ao responsável de uma ocorrência e limpeza de
  `hasOpenIssue` após resolução.
- `test/features/fulfillment/domain/value_objects/*_test.dart` — round-trip `fromCode`/`code` de
  `ShipmentStatus`, `TrackingEventType`/`TrackingEventSource`, `LogisticsIssueType`/
  `LogisticsIssueStatus`, incluindo rejeição de código desconhecido.
- `test/features/fulfillment/domain/entities/shipment_test.dart` — `totalQuantity`,
  `totalDeliveredQuantity`, `isFullyDelivered` (inclusive nunca `true` para `partially_delivered`).
- `test/features/fulfillment/presentation/cubit/order_fulfillment_cubit_test.dart` — 8 testes:
  estado vazio, seleção da expedição mais recente, falha de stream, `reportIssue` sem expedição
  selecionada (no-op), sucesso/falha de `reportIssue`/`resolveIssue` e disparo de analytics.
- `test/features/fulfillment/presentation/widgets/order_fulfillment_panel_test.dart` — 2 testes de
  widget: estado vazio e resumo da expedição com ação "Reportar ocorrência" visível para SALES_REP.
- `firestore-tests/firestore.rules.test.js` — novo `describe` com 8 testes: leitura pelo próprio
  vendedor, negação para vendedor de outro pedido, gestor da mesma equipe x outra equipe, OWNER/ADMIN
  leem tudo, FINANCE não lê, isolamento cross-tenant, portal só vê o próprio cliente e nenhuma escrita
  direta é permitida (incluindo o segredo do webhook) — não executável neste ambiente (sem Java para
  `firebase emulators:exec`, mesma limitação documentada em BACKLOG-002/TASK-165).
- `test/core/permissions/role_permission_matrix_test.dart` — novo teste cobrindo a amplitude exata
  de `Capability.shipmentManage`.

## Comandos executados

```bash
cd functions && npx tsc --noEmit -p .                                 # sem erros
cd functions && npx eslint src/fulfillment test/fulfillment src/index.ts src/customer_portal/load-customer-portal.ts   # limpo
cd functions && npx jest test/fulfillment/fulfillment-shared.test.ts  # 29/29 passou
cd functions && npx jest test/fulfillment test/receivables test/after_sales test/customer_portal test/returns
  # fulfillment-shared/receivables/customer_portal passaram (58/58); fulfillment-integration.emulator.test.ts,
  # after_sales/register-post-sale-event.test.ts e returns/create-return-request.test.ts falham por falta de
  # Firestore Emulator/Java neste ambiente — mesma limitação pré-existente já documentada em
  # TASK-094/TASK-133/TASK-176, não uma regressão desta task.
node --check firestore-tests/firestore.rules.test.js                  # sintaxe OK
node -e "JSON.parse(require('fs').readFileSync('firestore.indexes.json','utf8'))"   # JSON válido
node -e "brace-balance check em firestore.rules"                      # balanceado
flutter analyze                                                       # projeto inteiro
dart format lib/features/fulfillment lib/core/permissions/... lib/core/analytics/analytics_events.dart
  lib/features/orders/presentation/pages/order_history_page.dart lib/app/bootstrap.dart
  lib/features/customer_portal test/features/fulfillment test/core/permissions/role_permission_matrix_test.dart
dart format --output=none --set-exit-if-changed <mesmos arquivos>     # 0 alterações na segunda passada
dart run build_runner build                                           # regenerou lib/app/injection.config.dart
flutter test test/features/fulfillment test/features/customer_portal test/core/permissions  # 73/73
flutter test test/features/orders                                     # 228/228
```

## Resultado do formatter

`dart format` aplicado sem pendências nos arquivos tocados (12 arquivos reformatados na primeira
passada — reflow padrão pós-edição —, 0 na segunda).

## Resultado do analyzer

`flutter analyze` no projeto inteiro: 0 erros. 19 infos pré-existentes/estilo (idênticas às já
existentes antes desta task — nenhuma nova).

## Resultado dos testes

- Cloud Functions (Jest, lógica pura de fulfillment): 29/29 passaram.
- Cloud Functions (Jest, receivables/customer_portal — regressão de `load-customer-portal.ts`):
  58/58 passaram no total combinado.
- Cloud Functions (typecheck `tsc --noEmit`): sem erros.
- Cloud Functions (ESLint): limpo.
- Cloud Functions (emulador — `fulfillment-integration.emulator.test.ts`, 7 testes): não executado
  neste ambiente (sem Java/Firestore Emulator); mesma limitação pré-existente de
  `after_sales/register-post-sale-event.test.ts`/`returns/create-return-request.test.ts`, confirmada
  ao rodar a suíte completa (ambos falham pelo mesmo motivo, não introduzido por esta task).
- Firestore Rules (`firestore-tests`, novo `describe` de `shipments`/`trackingEvents`/
  `logisticsIssues`): não executado neste ambiente (mesma limitação, ver BACKLOG-002); sintaxe JS
  validada (`node --check`).
- Flutter (`test/features/fulfillment`): 27/27 passaram.
- Flutter (`test/core/permissions`): 31/31 passaram (inclui o novo teste de `shipmentManage`).
- Flutter (`test/features/customer_portal`): 2/2 passaram (sem regressão do novo campo opcional).
- Flutter (`test/features/orders`, regressão da nova seção/threading no histórico do pedido):
  228/228 passaram.

## Decisões técnicas

- `Shipment`/`TrackingEvent`/`LogisticsIssue` modelados como três coleções top-level distintas (não
  aninhadas em `shipments/{id}/trackingEvents`), para que as Firestore Rules de visibilidade
  (`canReadShipment`) e as consultas por `shipmentId` funcionem de forma idêntica à já usada por
  `postSaleEvents`/`returnRequests` — mesmo "padrão de consultas" documentado em `tasks.md` seção 20.
- `registerTrackingEvent` (autenticado) e `handleShipmentTrackingWebhook` (HTTP assinado)
  compartilham o mesmo núcleo transacional (`applyTrackingEvent`), evitando duas implementações
  independentes do bridge de `Order.status`/ledger de entrega — só a fonte de autenticação e o
  `source` gravado (`manual`/`admin` vs `webhook`) diferem.
- O resultado de uma entrega (`delivered` vs `partially_delivered`) é sempre recomputado
  server-side a partir do ledger acumulado (`Shipment.deliveredQuantities`), nunca aceito como o
  rótulo que o evento chegou com — protege contra um webhook mal-configurado que rotule "entregue"
  um evento que na verdade só cobre parte dos itens.
- Reaproveitado `ensureRequesterMayActOnOrder`/`mapReturnRequestOrder`
  (`returns/return-shared.ts`) e `appendPostSaleEvent` (`after_sales/after-sales-shared.ts`) em vez
  de reimplementar "quem pode agir neste pedido" e "como notificar o vendedor" pela terceira vez
  neste código — mesma disciplina de reuso que `create-return-request.ts` já estabelece ao importar
  de `after_sales`.
- Segredo do webhook de transportadora reaproveita `generateWebhookSecret`/`verifyWebhookSignature`
  de `webhooks/webhook-shared.ts` (infra outbound da TASK-170) em vez de uma terceira implementação
  HMAC própria (a de `payments/handle-payment-webhook.ts` já seria a segunda) — só a persistência do
  segredo (`shipmentWebhookSecrets`, por `carrierId`) é nova, pois é um segredo *inbound*
  independente do outbound.
- `OrderFulfillmentCubit` só observa em detalhe a expedição mais recente de um pedido
  (`state.selectedShipment`), listando as demais apenas por contagem — decisão deliberada de escopo:
  entregas parciais expedidas em mais de um romaneio separado são um caso raro em moda B2B; abrir N
  subscriptions simultâneas por pedido não se justificou para esta rodada (documentado como
  possível evolução em "Pendências").
- Nenhuma tela de criação de expedição (`createShipment`)/lançamento manual de evento
  (`registerTrackingEvent`) foi construída no Flutter nesta rodada — ambas as Cloud Functions estão
  completas, testadas e prontas para uma futura tela de "Expedição"/integração com WMS/ERP; o
  Flutter cobre integralmente o lado de leitura (rastreio no pedido e no portal) e o de ocorrência
  (reportar/resolver), que são os dois itens presentes nos "Critérios de aceite" da task.
- Customer 360º não recebeu uma seção agregada de expedições entre todos os pedidos do cliente —
  mesma decisão de escopo já aceita em TASK-213 para a "carteira de recebíveis" agregada: o
  vendedor/gestor já alcança o rastreio completo ao abrir o pedido a partir do 360º
  (`_OrderHistorySection` já existente), e construir um segundo painel agregado (com o custo de
  N leituras por pedido listado) não se justificou para o escopo desta task.

## Riscos conhecidos

- `detectShipmentDelays` abre no máximo uma ocorrência `delay` por expedição (id determinístico
  `delay_${shipmentId}`): se essa ocorrência for resolvida e a expedição continuar em atraso depois,
  nenhum novo alerta automático é gerado — um humano ainda pode registrar uma ocorrência manual a
  qualquer momento via `registerLogisticsIssue`.
- `provisionShipmentWebhookSecret` não tem hoje uma tela de configuração dedicada (nem uma
  `Capability` própria — a checagem é direta por `roleName === 'OWNER' || 'ADMIN'`, mesmo padrão de
  outros callables de infraestrutura que ainda não ganharam uma capability formal). A integração real
  com uma transportadora específica (mapeamento de payload, retry) está fora do escopo desta task,
  assim como `erpIntegrationManage` (TASK-169) já documenta para ERPs.
- A suíte de Firestore Rules (`firestore-tests`) e o teste de integração de Cloud Functions
  (`fulfillment-integration.emulator.test.ts`) não puderam ser executados neste ambiente por falta de
  Java/Firestore Emulator — mesma limitação pré-existente de outras suítes já documentada em
  BACKLOG-002/TASK-165; devem rodar no pipeline de CI (`test:integration`) antes do deploy.

## Pendências

Nenhuma pendência bloqueante para os critérios de aceite desta task. Evolução futura possível (fora
do escopo aprovado): tela dedicada de criação/edição de romaneio (hoje só via Cloud Function/futura
integração de WMS), painel agregado de expedições no cliente 360º, e reabertura automática de
ocorrência de atraso após resolução caso o prazo continue ultrapassado.

## Evidências

- `functions/test/fulfillment/fulfillment-shared.test.ts` (29/29 passou).
- `test/features/fulfillment/**` (27/27 passou).
- `test/core/permissions/role_permission_matrix_test.dart` (31/31 passou).
- `test/features/customer_portal/customer_portal_test.dart` (2/2 passou).
- `flutter test test/features/orders` (228/228 passou).
- `flutter analyze` limpo (0 erros) no projeto inteiro.
- `cd functions && npx tsc --noEmit -p .` e `npx eslint` limpos.

## Commit

Local, sem push (não autorizado nesta rodada).

## Push

Não realizado (proibido nesta rodada).

## Hash do commit

Ver commit da task no histórico do Git (mensagem `feat(fulfillment): implementar expedição,
romaneio, tracking e ocorrências`).

## Branch

`main`
