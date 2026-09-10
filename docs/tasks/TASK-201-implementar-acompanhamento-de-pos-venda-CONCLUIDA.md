# TASK-201 — Concluída (2026-09-09)

## Resumo

Implementada a linha do tempo de pós-venda por pedido: modelo `PostSaleEvent` (10 tipos — 6 marcos
manuais registráveis por vendedor/suporte: despachado, em trânsito, entregue, problema reportado, em
resolução, resolvido; 4 marcos de sistema: devolução/troca solicitada/decidida), Cloud Function
`registerPostSaleEvent` (registro manual, idempotente, exigindo descrição obrigatória apenas para
"problema reportado"), notificação automática ao vendedor a cada marco relevante (entregue, problema
reportado, resolvido, devolução/troca solicitada/decidida), vínculo automático das devoluções/trocas
(TASK-199/TASK-200) na mesma timeline (sem duplicar aquela modelagem — as próprias Cloud Functions
`createReturnRequest`/`resolveReturnRequest`/`createExchangeRequest`/`resolveExchangeRequest` passaram
a anexar um `PostSaleEvent` de sistema), feature Flutter completa (domain/data/presentation) e
integração na tela de detalhe do pedido (`OrderHistoryPage`, TASK-102), reaproveitando o componente
visual de timeline já usado pelo CRM (`AppTimeline`, TASK-059).

A notificação ao cliente (WhatsApp, com opt-in de TASK-183) foi deliberadamente **não** automatizada
nesta rodada — ver "Decisões técnicas" e "Pendências" para o motivo e o caminho já existente para o
vendedor notificar o cliente manualmente a partir de um marco de pós-venda.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `functions/src/after_sales/after-sales-shared.ts`
- `functions/src/after_sales/register-post-sale-event.ts`
- `functions/src/after_sales/index.ts`
- `functions/test/after_sales/register-post-sale-event.test.ts`
- `lib/features/after_sales/domain/value_objects/post_sale_event_type.dart`
- `lib/features/after_sales/domain/entities/post_sale_event.dart`
- `lib/features/after_sales/domain/entities/post_sale_event_submission_result.dart`
- `lib/features/after_sales/domain/repositories/post_sale_event_repository.dart`
- `lib/features/after_sales/domain/usecases/register_post_sale_event_use_case.dart`
- `lib/features/after_sales/domain/usecases/watch_post_sale_timeline_for_order_use_case.dart`
- `lib/features/after_sales/data/dtos/post_sale_event_dto.dart`
- `lib/features/after_sales/data/dtos/post_sale_event_submission_result_dto.dart`
- `lib/features/after_sales/data/mappers/post_sale_event_mapper.dart`
- `lib/features/after_sales/data/datasources/post_sale_event_read_data_source.dart`
- `lib/features/after_sales/data/datasources/firestore_post_sale_event_data_source.dart`
- `lib/features/after_sales/data/datasources/post_sale_event_write_data_source.dart`
- `lib/features/after_sales/data/datasources/cloud_functions_post_sale_event_data_source.dart`
- `lib/features/after_sales/data/repositories/post_sale_event_repository_impl.dart`
- `lib/features/after_sales/presentation/cubit/post_sale_timeline_cubit.dart` (+ `..._state.dart`)
- `lib/features/after_sales/presentation/cubit/register_post_sale_event_cubit.dart` (+ `..._state.dart`)
- `lib/features/after_sales/presentation/widgets/post_sale_timeline_section.dart`
- `lib/features/after_sales/presentation/pages/register_post_sale_event_page.dart`
- `lib/features/after_sales/after_sales.dart`
- `test/features/after_sales/domain/usecases/register_post_sale_event_use_case_test.dart`
- `test/features/after_sales/data/mappers/post_sale_event_mapper_test.dart`
- `test/features/after_sales/presentation/widgets/post_sale_timeline_section_test.dart`
- `test/features/after_sales/presentation/pages/register_post_sale_event_page_test.dart`
- `docs/tasks/TASK-201-implementar-acompanhamento-de-pos-venda-CONCLUIDA.md` (este arquivo)

Observação: `lib/features/after_sales/{domain,presentation}` e `functions/src/after_sales` já existiam
como diretórios vazios (sem arquivos, não rastreados pelo git) no início desta task — provavelmente
scaffolding de uma tentativa anterior interrompida. Populados nesta task, nenhum arquivo pré-existente
foi reaproveitado (estavam de fato vazios).

## Arquivos alterados

- `functions/src/index.ts` (registra `registerPostSaleEvent`).
- `functions/src/returns/create-return-request.ts` (anexa um evento `return_requested` na timeline de
  pós-venda do pedido, dentro da mesma transação).
- `functions/src/returns/resolve-return-request.ts` (anexa um evento `return_resolved` — aprovada ou
  recusada — na mesma timeline, dentro da mesma transação).
- `functions/src/exchanges/create-exchange-request.ts` (anexa um evento `exchange_requested`).
- `functions/src/exchanges/resolve-exchange-request.ts` (anexa um evento `exchange_resolved` —
  aprovada ou recusada).
- `firestore.rules` (collection `postSaleEvents`, mirror de `returnRequests`/`exchangeRequests`:
  `canReadPostSaleEvent` reaproveita o mesmo escopo — vendedor dono, gestor da mesma equipe, OWNER/
  ADMIN, portal do cliente — e escrita sempre `false`, só Admin SDK via Cloud Function).
- `firestore.indexes.json` (índice composto `orderId+createdAt` para `postSaleEvents`).
- `firestore-tests/firestore.rules.test.js` (helper `postSaleEventDoc` + describe block
  `postSaleEvents` com casos positivos/negativos de RBAC e isolamento).
- `lib/core/permissions/capability.dart` (`Capability.postSaleEventRegister`).
- `lib/core/permissions/role_permission_matrix.dart` (concede a capability acima a SALES_MANAGER/
  SALES_REP, mesma amplitude de `returnRequestCreate`; OWNER/ADMIN já a recebem via o conjunto
  completo/quase completo).
- `lib/core/analytics/analytics_events.dart` (`postSaleEventRegistered`).
- `lib/app/bootstrap.dart` (wiring dos novos cubits na `OrderHistoryPage`).
- `lib/app/injection.config.dart` (regenerado via `build_runner`).
- `lib/features/orders/presentation/pages/order_history_page.dart` (botão "Registrar evento" gated
  por `Capability.postSaleEventRegister` + janela de elegibilidade de status própria, mais ampla que a
  de devolução/troca; seção `PostSaleTimelineSection` no detalhe do pedido, logo após a linha do tempo
  de status do pedido e antes das seções de devoluções/trocas já existentes).
- `test/core/permissions/role_permission_matrix_test.dart`
- `test/core/analytics/analytics_events_test.dart`
- `docs/tasks/TASKS.md` (checkbox + progresso)

## Arquitetura utilizada

Clean Architecture feature-first, espelhando exatamente `lib/features/returns/`/`exchanges/`
(TASK-199/TASK-200): `domain` (entidade imutável `PostSaleEvent`; repository contract; use case
`RegisterPostSaleEventUseCase` com RBAC de defesa em profundidade e validação de tipo
manual/descrição obrigatória) → `data` (DTOs com parsing defensivo, mapper, datasource Firestore
somente leitura via `watchQuery`, datasource de escrita via `CloudFunctionsService`, repository impl
convertendo exceptions em `AppFailure`) → `presentation` (`PostSaleTimelineCubit` — stream ao vivo —
e `RegisterPostSaleEventCubit` — formulário —, mais o widget `PostSaleTimelineSection` reaproveitando
`AppTimeline`/`AppTimelineEntry`, o mesmo componente visual já usado por `CrmActivityTimeline`,
TASK-059). Nenhuma regra de negócio crítica na UI: tipo permitido, descrição obrigatória para
"problema reportado", RBAC e elegibilidade de status do pedido são sempre revalidados, com
autoridade final, por `registerPostSaleEvent` (Cloud Function, Admin SDK). Escrita no Firestore
exclusivamente via Cloud Function; toda leitura via Firestore Rules (`canReadPostSaleEvent`).

Vínculo de devoluções/trocas na mesma timeline (pedido explícito da task, "para visão única de
pós-venda do pedido") implementado como um *helper* compartilhado
(`appendPostSaleEvent`/`functions/src/after_sales/after-sales-shared.ts`) chamado dentro da mesma
transação Firestore de `createReturnRequest`/`resolveReturnRequest`/`createExchangeRequest`/
`resolveExchangeRequest` — nenhuma modelagem de devolução/troca foi duplicada; o evento de pós-venda
apenas referencia o `returnRequestId`/`exchangeRequestId` original (`sourceRequestId`) e carrega uma
descrição textual curta do que aconteceu.

## Regras de negócio implementadas

- Todo `PostSaleEvent` é imutável uma vez registrado — nenhuma Cloud Function neste codebase jamais
  atualiza um documento `postSaleEvents`, apenas cria novos (histórico é sempre aditivo).
- Registro manual restrito aos 6 marcos "manuais" (despachado, em trânsito, entregue, problema
  reportado, em resolução, resolvido) — os 4 marcos de sistema (devolução/troca solicitada/decidida)
  são revalidados como não-manuais tanto no client (`PostSaleEventType.isManual`) quanto no servidor
  (`requireManualPostSaleEventType`), nunca selecionáveis no formulário nem aceitos pela Function caso
  o cliente tente forçar um.
- "Problema reportado" exige descrição não vazia (nunca um evento vazio de problema) — revalidado em
  três camadas: UI (Cubit bloqueia o submit), use case (`RegisterPostSaleEventUseCase`) e Cloud
  Function (`requirePostSaleDescription`, autoridade final).
- Pedido precisa estar em um status elegível para acompanhamento de pós-venda
  (`POST_SALE_EVENT_ELIGIBLE_ORDER_STATUSES`: `processing`/`invoiced`/`partially_invoiced`/`shipped`/
  `delivered`/`partially_returned`/`returned`) — janela um pouco mais ampla que a de devolução/troca,
  já que "despachado"/"em trânsito" fazem sentido assim que a separação/expedição começa, antes do
  faturamento.
- RBAC do registro manual: `OWNER`/`ADMIN`/`SALES_MANAGER`/`SALES_REP` (vendedor/suporte, conforme o
  texto da task); `CUSTOMER_PORTAL` nunca registra manualmente (ver "Decisões técnicas").
- Reaproveita `ensureRequesterMayActOnOrder` (TASK-199) para decidir quem pode agir sobre um pedido:
  `SALES_REP` só o próprio pedido, `SALES_MANAGER` só pedidos da própria equipe, `OWNER`/`ADMIN`
  qualquer um.
- Notificação automática ao vendedor (central de notificações, TASK-151) a cada marco relevante —
  `delivered`/`problem_reported`/`resolved`/`return_requested`/`return_resolved`/
  `exchange_requested`/`exchange_resolved` — nunca para `dispatched`/`in_transit`/`in_resolution`
  (marcos intermediários, mesmo precedente de "nem toda mudança de status merece um push" já usado
  por outros geradores deste codebase).
- Idempotência: `eventId` é gerado no cliente (Cubit) e usado como chave/documento — um retry (double
  tap, resposta perdida) nunca duplica o evento nem a notificação.

## Regras Firebase implementadas

- `firestore.rules`: `organizations/{organizationId}/postSaleEvents/{postSaleEventId}` — leitura
  escopada por `canReadPostSaleEvent` (espelha `canReadReturnRequest`: vendedor dono, gestor da mesma
  equipe, OWNER/ADMIN, portal do cliente); escrita sempre `false` (só Admin SDK via Cloud Function,
  nunca `update`/`delete`, reforçando a imutabilidade também na camada de Rules).
- `firestore.indexes.json`: 1 índice composto (`orderId+createdAt`) — suficiente para
  `watchByOrder` (a timeline de um pedido específico); não há fila/consulta cross-pedido nesta task.
- Testes de Rules escritos (`firestore-tests/firestore.rules.test.js`) cobrindo casos positivos e
  negativos — ver "Pendências" quanto à execução (bloqueio de ambiente, ver abaixo).

## Analytics implementado

- `AnalyticsEvents.postSaleEventRegistered` — registrado por `RegisterPostSaleEventCubit` ao
  registrar com sucesso um marco manual, carregando `organization_id`/`order_id`/`event_type`, nunca a
  descrição livre.

## Crashlytics implementado

Nenhuma integração nova direta; erros seguem o pipeline padrão (`CloudFunctionsService`/
`AppException` → `AppFailure`) já coberto pelos handlers globais existentes.

## Impacto offline

- Registro manual de evento exige conectividade (Cloud Function) — não há fila de Outbox dedicada
  nesta rodada, mesmo precedente de TASK-199/TASK-200. Leitura da timeline é sempre via `watchQuery`
  (Firestore realtime), refletindo o cache local padrão do SDK quando offline.

## Impacto multi-tenant

- Toda entidade carrega `organizationId`/`companyId`; toda leitura passa por Firestore Rules
  reavaliando a Membership real do usuário (nunca confiando em campo enviado pelo cliente). O evento
  de pós-venda nunca é visível a quem não poderia já ler o pedido/devolução/troca correspondente.

## Testes criados

- Cloud Functions (Jest, não executados neste ambiente — ver Pendências):
  `register-post-sale-event.test.ts` (9 casos: registro manual com notificação ao vendedor, ausência
  de notificação para marco não-relevante, "problema reportado" sem descrição rejeitado, "problema
  reportado" com descrição aceito, tipo de sistema rejeitado, status de pedido inelegível, RBAC
  vendedor/assistente negado, vendedor de outro pedido negado, idempotência de retry).
- Firestore Rules (não executados neste ambiente — ver Pendências): describe block para
  `postSaleEvents` com casos positivos/negativos de RBAC e isolamento (mirror exato de
  `returnRequests`/`exchangeRequests`).
- Flutter: `post_sale_event_mapper_test.dart` (parsing/round-trip do DTO, mapeamento de tipo/origem,
  vínculo com `sourceRequestId` de um evento de sistema, invariantes de `PostSaleEventType`),
  `register_post_sale_event_use_case_test.dart` (RBAC, tipo não-manual rejeitado, descrição
  obrigatória para problema, propagação de falha do repositório), `post_sale_timeline_section_test.dart`
  (widget: timeline vazia, timeline completa com múltiplos eventos, evento de problema em destaque —
  `isHighlighted`), `register_post_sale_event_page_test.dart` (widget: "problema reportado" sem
  descrição rejeitado sem chamar o repositório, marco que não exige descrição submetido com sucesso).
- Atualizados: `role_permission_matrix_test.dart` (nova capability), `analytics_events_test.dart`
  (1 novo evento).

## Comandos executados

- `npm run build` em `functions` (tsc) — sucesso, incluindo os hooks de `appendPostSaleEvent` nos 4
  arquivos de devolução/troca já existentes.
- `npm run lint` em `functions` (eslint) — sucesso (0 erros; 10 warnings pré-existentes de
  `no-explicit-any` em arquivos de teste não relacionados a esta task).
- `npx jest test/after_sales/register-post-sale-event.test.ts --testTimeout=3000` — confirmou que o
  arquivo de teste compila/carrega sob `ts-jest` (falha apenas por falta de credenciais/emulador, ver
  Pendências).
- `dart run build_runner build` — sucesso (regenerou `injection.config.dart` com as novas classes; os
  avisos "Missing dependencies" exibidos são ruído pré-existente do `injectable_generator`, já
  documentado por TASK-199/TASK-200, não relacionado a esta task).
- `flutter analyze` (repositório inteiro) — sucesso, 0 erros (18 infos/deprecations pré-existentes,
  idêntico ao que TASK-199/TASK-200 já documentaram).
- `dart format --set-exit-if-changed .` (repositório inteiro) — sucesso após reverter 4 arquivos fora
  do escopo desta task que o formatter também alteraria (mesmo drift de formatação pré-existente já
  documentado por TASK-199/TASK-200).
- `flutter test` (suíte completa, 3335 testes) — sucesso, exceto 1 falha pré-existente e não
  relacionada (`test/app/bootstrap_test.dart`, `PushDeviceMapper` não registrado no GetIt — mesma
  falha já confirmada pré-existente por TASK-199/TASK-200).
- `flutter test test/features/after_sales ...` — todos os testes novos passaram isoladamente e dentro
  da suíte completa.

## Resultado do formatter

Sucesso: todos os arquivos desta task formatados sem pendências.

## Resultado do analyzer

`flutter analyze` no repositório inteiro: 18 infos/deprecations pré-existentes, nenhum relacionado a
TASK-201; 0 erros.

## Resultado dos testes

- `functions`: `npm run build`/`npm run lint` passaram. O teste Jest
  (`register-post-sale-event.test.ts`) e os testes de Rules (`firestore.rules.test.js`) **não puderam
  ser executados neste ambiente**: o Firebase Emulator Suite exige Java, que não está instalado nesta
  sandbox (mesmo bloqueio já documentado por TASK-199/TASK-200). Confirmei que o arquivo de teste ao
  menos compila/carrega corretamente sob `ts-jest` (falha apenas na primeira chamada real ao
  Firestore, por falta de emulador/credenciais) — não afirmo tê-lo executado com sucesso contra dados
  reais.
- Flutter: `flutter test` completo passou (3335 testes, exceto a falha pré-existente já documentada).
  Os testes novos da feature `after_sales` (mapper, use case, widgets) rodaram e passaram
  individualmente e também dentro da suíte completa.

## Decisões técnicas

- **Nome da feature `after_sales` (inglês) em vez de `post_sale`**: os diretórios
  `lib/features/after_sales/{domain,presentation}` e `functions/src/after_sales` já existiam vazios
  (não rastreados pelo git) no início desta task, sugerindo que essa era a convenção de nomenclatura
  já planejada para esta feature — populei-os em vez de criar um `post_sale`/`postsale` paralelo.
- **`postSaleEvents` como coleção própria, não subcoleção de `orders/{orderId}`**: mantém o mesmo
  padrão de `returnRequests`/`exchangeRequests` (coleção plana sob a organização, filtrada por
  `orderId`) em vez de uma subcoleção do pedido — mais simples de espelhar as Rules/índices já
  existentes e evita duas formas diferentes de modelar "algo vinculado a um pedido" no mesmo
  codebase.
- **`appendPostSaleEvent` como helper compartilhado, não um trigger Firestore separado**: em vez de um
  Cloud Function trigger (`onDocumentWritten`) escutando `returnRequests`/`exchangeRequests` para
  gerar o evento de pós-venda de forma assíncrona/eventual, o vínculo é escrito **dentro da mesma
  transação** que já cria/decide a devolução/troca — mais simples, atômico (nunca um evento de
  devolução aparece sem o evento de pós-venda correspondente, ou vice-versa) e sem custo adicional de
  uma segunda invocação de function. Trade-off: os 4 arquivos de `returns`/`exchanges` (já
  commitados por TASK-199/TASK-200) precisaram de uma pequena alteração cada — avaliado como aceitável
  e de baixo risco (apenas uma chamada adicional no fim de cada transação, sem alterar nenhuma lógica
  existente).
- **"Atualização de status logístico, quando disponível" não implementada como trigger real**: a task
  menciona "Cloud Function/trigger que registra eventos a partir de integrações existentes (ex.:
  atualização de status logístico, quando disponível)" — não existe hoje nenhuma integração de
  transportadora/WMS no codebase (nenhuma task anterior implementou isso), então não há gatilho real
  para conectar. O registro de `dispatched`/`in_transit`/`delivered` fica manual (vendedor/suporte)
  nesta rodada; o "quando disponível" da própria task já antecipa essa lacuna. Fica documentado como
  pendência para quando uma integração logística existir.
- **Notificação ao cliente via WhatsApp não automatizada**: a task pede notificação "quando aplicável,
  para o cliente (se houver canal habilitado, ex.: WhatsApp com opt-in de TASK-183)". A integração
  real de WhatsApp (TASK-183) só envia mensagens por **template aprovado** escolhido manualmente pelo
  vendedor/suporte (`WhatsAppSendSheet`, com variáveis explícitas) — não existe hoje um template
  aprovado genérico para "atualização de pós-venda", e criar um exigiria uma ação administrativa fora
  do alcance deste agente (aprovação de template no Meta Business Manager). Em vez de simular um envio
  automático que na prática falharia (nenhum template aprovado disponível), optei por **não**
  automatizar esse envio nesta rodada: o vendedor pode notificar o cliente manualmente pelo fluxo de
  WhatsApp já existente (TASK-183), a partir do detalhe do pedido, quando julgar necessário — sem
  duplicar/gambiarrar a lógica de opt-in/template já centralizada naquela feature. Documentado como
  pendência abaixo.
- **RBAC do registro manual restrito a vendedor/suporte, sem `CUSTOMER_PORTAL`**: a task fala em
  "registro manual por vendedor/suporte" — o cliente (portal) não registra eventos de pós-venda
  diretamente nesta rodada; um fluxo de auto-relato do cliente ficaria mais bem modelado como uma
  extensão futura (possivelmente com um marco/tipo próprio, ex. `customer_reported_issue`), fora do
  escopo literal desta task.
- **Janela de elegibilidade de status mais ampla que a de devolução/troca**: `processing` foi incluído
  (além de `invoiced`/`partially_invoiced`/`shipped`/`delivered`/`partially_returned`/`returned`)
  porque "despachado"/"em trânsito" fazem sentido assim que a separação do pedido começa, antes do
  faturamento — diferente de devolução/troca, que só fazem sentido após o pedido já ter sido
  efetivamente faturado/expedido/entregue.
- **`PostSaleTimelineSection` adicionada, sem remover `ReturnRequestHistorySection`/
  `ExchangeRequestHistorySection`**: a timeline unificada de pós-venda já inclui os eventos de
  devolução/troca (satisfazendo "visão única de pós-venda do pedido"), mas as duas seções detalhadas
  já existentes (com valor de reembolso, diferença de preço, badge de status) continuam visíveis
  logo abaixo — removê-las estava fora do escopo desta task e reduziria informação hoje disponível ao
  usuário.

## Riscos conhecidos

- Teste de Cloud Function e de Firestore Rules não foram executados neste ambiente (falta de Java
  para o Emulator Suite) — precisam rodar em CI/ambiente com Java antes do próximo deploy real (mesmo
  risco já documentado por TASK-199/TASK-200).
- Nenhuma integração logística real (transportadora/WMS) dispara `dispatched`/`in_transit`/`delivered`
  automaticamente — depende de registro manual até que essa integração exista.
- Notificação ao cliente (WhatsApp) permanece manual — se o vendedor não notificar manualmente, o
  cliente não recebe nenhum aviso automático de marco de pós-venda nesta rodada.
- Não há fluxo de Outbox/offline dedicado para o registro manual de evento; exige conectividade,
  mesmo precedente de devolução/troca.

## Pendências

- Rodar `npm run test:functions` (Jest com Firestore/Auth emulator) e
  `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em um ambiente com
  Java instalado, antes do deploy.
- Conectar `dispatched`/`in_transit`/`delivered` a uma integração logística real (transportadora/WMS)
  assim que ela existir no codebase, substituindo o registro manual por um trigger automático.
- Avaliar, em uma iteração futura, uma automação de notificação ao cliente (WhatsApp) por marco de
  pós-venda — hoje depende de um template aprovado escolhido manualmente pelo vendedor/suporte
  (TASK-183); criar um template dedicado de "atualização de pedido" exige ação administrativa
  (aprovação no Meta Business Manager) fora do alcance deste agente.
- Avaliar um fluxo de auto-relato de problema pelo cliente via portal (`CUSTOMER_PORTAL`), hoje fora
  do escopo desta task (registro manual restrito a vendedor/suporte).

## Evidências

- `functions`: `npm run build` → sucesso; `npm run lint` → sucesso (0 erros, apenas warnings
  pré-existentes em arquivos de teste não relacionados).
- `dart run build_runner build` → sucesso, `injection.config.dart` registrou as novas classes
  (`PostSaleEventRepository`/`Impl`, use cases, cubits, datasources).
- `flutter analyze` (repositório inteiro) → 0 erros.
- `flutter test` (repositório inteiro, 3335 testes) → apenas 1 falha pré-existente e não relacionada a
  esta task (mesma falha já documentada por TASK-199/TASK-200).
- `flutter test test/features/after_sales/...` (22 testes novos) → todos passaram.

## Commit

`feat(after-sales): implementa acompanhamento de pós-venda com timeline unificada (TASK-201)`

## Push

Não autorizado nesta rodada (push não solicitado pelo usuário).

## Hash do commit

`4de01dc200a8aea93f244bedae6395d149e7a58c`

## Branch

`main`
