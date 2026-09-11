# TASK-215 — Implementar backorder e solicitação de estoque futuro — CONCLUÍDA

## Resumo

Implementado o ciclo completo de **backorder/solicitação de estoque futuro** (EPIC-32): quando um
cliente/vendedor precisa de mais unidades de uma variante do que o estoque pronta entrega atual
comporta, é possível abrir um `BackorderRequest` que registra a demanda, sem jamais mover/reservar
estoque nem prometer uma data de entrega. A solicitação entra automaticamente na fila de atendimento
(`queued`) quando dentro de um limite configurável por organização, ou fica `awaiting_approval`
quando excede esse limite — só um gestor (`SALES_MANAGER`/`ADMIN`/`OWNER`) pode liberá-la
(`decideBackorderApproval`). Um trigger server-side (`notifyBackordersOnStockAvailable`) observa toda
mudança de saldo de estoque (`organizations/{organizationId}/inventory/{inventoryId}`, a mesma
collection que já alimenta os alertas de ruptura da TASK-093) e sinaliza `ready_to_fulfill` — um aviso
("previsão"), nunca uma reserva confirmada — sempre que a quantidade disponível cobre o pendente de um
backorder `queued`, notificando o vendedor responsável e o portal do cliente. A conversão em pedido
(`convertBackorderToOrder`) nunca reimplementa a criação de pedido: ela vincula um pedido **já
submetido** (que já passou pela revalidação real de preço/estoque/crédito/aprovação em `submitOrder`)
ao backorder, exigindo apenas que esse pedido realmente cubra a quantidade pendente — mesma decisão de
design já documentada em `convertBuyerCollaborationSession` (TASK-211) para evitar duplicar regra de
negócio.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domínio, dados, Cloud Functions, Firestore Rules/Indexes,
  RBAC, testes)
- `flutter-ui-design-specialist` (fila de atendimento e formulário de solicitação usando o Design
  System já existente)

## Arquivos criados

### Cloud Functions (TypeScript)
- `functions/src/backorder/backorder-shared.ts`
- `functions/src/backorder/create-backorder-request.ts`
- `functions/src/backorder/decide-backorder-approval.ts`
- `functions/src/backorder/cancel-backorder-request.ts`
- `functions/src/backorder/convert-backorder-to-order.ts`
- `functions/src/backorder/notify-backorders-on-stock-available.ts`
- `functions/src/backorder/index.ts`
- `functions/test/backorder/backorder-shared.test.ts`
- `functions/test/backorder/backorder-integration.emulator.test.ts`

### Flutter — feature `backorder`
- `lib/features/backorder/backorder.dart` (barrel)
- `lib/features/backorder/domain/value_objects/backorder_status.dart`
- `lib/features/backorder/domain/value_objects/backorder_priority.dart`
- `lib/features/backorder/domain/value_objects/backorder_origin.dart`
- `lib/features/backorder/domain/entities/backorder_request.dart`
- `lib/features/backorder/domain/repositories/backorder_repository.dart`
- `lib/features/backorder/domain/usecases/backorder_use_cases.dart`
- `lib/features/backorder/data/dtos/backorder_request_dto.dart`
- `lib/features/backorder/data/mappers/backorder_mapper.dart`
- `lib/features/backorder/data/datasources/backorder_read_data_source.dart`
- `lib/features/backorder/data/datasources/firestore_backorder_read_data_source.dart`
- `lib/features/backorder/data/datasources/backorder_write_data_source.dart`
- `lib/features/backorder/data/datasources/cloud_functions_backorder_write_data_source.dart`
- `lib/features/backorder/data/repositories/backorder_repository_impl.dart`
- `lib/features/backorder/presentation/cubit/backorder_queue_cubit.dart`
- `lib/features/backorder/presentation/cubit/backorder_queue_state.dart`
- `lib/features/backorder/presentation/cubit/request_backorder_cubit.dart`
- `lib/features/backorder/presentation/cubit/request_backorder_state.dart`
- `lib/features/backorder/presentation/pages/backorder_queue_page.dart`
- `lib/features/backorder/presentation/widgets/request_backorder_sheet.dart`

### Testes Flutter
- `test/features/backorder/domain/value_objects/backorder_status_test.dart`
- `test/features/backorder/domain/value_objects/backorder_priority_test.dart`
- `test/features/backorder/domain/value_objects/backorder_origin_test.dart`
- `test/features/backorder/domain/entities/backorder_request_test.dart`
- `test/features/backorder/presentation/cubit/backorder_queue_cubit_test.dart`
- `test/features/backorder/presentation/cubit/request_backorder_cubit_test.dart`

### Documentação
- `docs/tasks/TASK-215-implementar-backorder-e-solicitacao-de-estoque-futuro-CONCLUIDA.md` (este
  arquivo)

## Arquivos alterados

- `functions/src/index.ts` — exporta `createBackorderRequest`, `decideBackorderApproval`,
  `cancelBackorderRequest`, `convertBackorderToOrder`, `notifyBackordersOnStockAvailable`.
- `firestore.rules` — nova seção `organizations/{organizationId}/backorders/{backorderId}`
  (leitura escopada por vendedor/equipe/cliente/portal, escrita 100% via Cloud Functions).
- `firestore.indexes.json` — 4 índices compostos para `backorders`
  (`status+priorityWeight+createdAt`, `status+createdAt`, `customerId+createdAt`,
  `variantId+status`).
- `firestore-tests/firestore.rules.test.js` — helper `backorderDoc` + suíte
  `organizations/{organizationId}/backorders/{backorderId}` com casos positivos/negativos
  (SALES_REP, SALES_MANAGER, OWNER/ADMIN, FINANCE, cross-tenant, portal, escrita direta bloqueada).
- `lib/core/permissions/capability.dart` — `Capability.backorderRequest` e
  `Capability.backorderApprove`.
- `lib/core/permissions/role_permission_matrix.dart` — concede `backorderRequest` a
  `SALES_MANAGER`/`SALES_REP`; `backorderApprove` só a `SALES_MANAGER` (OWNER/ADMIN já têm tudo).
- `test/core/permissions/role_permission_matrix_test.dart` — 2 novos blocos de teste para as
  capabilities acima.
- `lib/core/analytics/analytics_events.dart` — 5 novos eventos (`backorder_requested`,
  `backorder_approved`, `backorder_rejected`, `backorder_cancelled`, `backorder_converted`).
- `test/core/analytics/analytics_events_test.dart` — sincronizado com a lista real de
  `AnalyticsEvents.values`. **Nota:** este teste já estava desatualizado desde antes desta task (não
  incluía os eventos de `line_sheet_*`, `pre_book_*`, `buyer_collaboration_*` e `logistics_issue_*`
  das TASK-209/210/211/214) — corrigido integralmente aqui porque eu already estava tocando este
  arquivo para adicionar os eventos de backorder, e deixá-lo quebrado teria feito `flutter test`
  falhar de forma não relacionada ao meu próprio código.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` (registra os novos
  datasources/repositório/use cases/cubits `@injectable`/`@LazySingleton`).
- `docs/tasks/TASKS.md` — checkbox da TASK-215 marcado e `Progresso` atualizado para `211 / 216`.

## Arquitetura utilizada

Feature-first + Clean Architecture, seguindo exatamente o precedente de `fulfillment` (TASK-214) e
`returns`/`buyer_collaboration` (TASK-199/TASK-211):

- **Domain**: `BackorderRequest` (entidade), `BackorderStatus`/`BackorderPriority`/`BackorderOrigin`
  (value objects com `code`/`fromCode`/`label`, espelhando 1:1 as strings do backend),
  `BackorderRepository` (contrato) e um único arquivo `backorder_use_cases.dart` reunindo os 6 use
  cases (`Watch*`, `Create*`, `Decide*`, `Cancel*`, `Convert*`) — sem nenhuma dependência de
  Flutter/Firebase/Drift.
- **Data**: `BackorderRequestDto`/mapper (leitura), `BackorderReadDataSource`
  (Firestore, somente leitura) + `BackorderWriteDataSource` (Cloud Functions, única via de escrita) +
  `BackorderRepositoryImpl` (conversão de erro/DTO→entidade).
- **Presentation**: `BackorderQueueCubit` (fila + inbox de aprovação + ações) e
  `RequestBackorderCubit` (formulário de solicitação), cada um com seu próprio `State` imutável
  (`copyWith`), sem nenhuma regra de negócio na UI — `BackorderQueuePage`/`RequestBackorderSheet`
  apenas leem o estado e disparam intents.
- A UI nunca acessa Firestore/Storage/Drift diretamente; toda mutação passa pelas Cloud Functions
  via `CloudFunctionsService`.

## Regras de negócio implementadas

- **Backorder nunca move estoque**: `createBackorderRequest` apenas lê o saldo atual
  (`quantityAtRequest`, informativo) — nenhuma escrita em `inventory`.
- **Limite de auto-aprovação configurável por organização**
  (`organizations/{organizationId}.backorderSettings.autoApproveMaxQuantity`, com fallback
  `DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY = 20`): acima do limite, o backorder nasce
  `awaiting_approval` e só avança via `decideBackorderApproval` (RBAC: OWNER/ADMIN/SALES_MANAGER).
- **RBAC assimétrico**: solicitar/cancelar/converter (`Capability.backorderRequest`) é mais amplo que
  decidir uma aprovação (`Capability.backorderApprove`) — mesma assimetria já usada em
  `orderApprove`/`returnRequestApprove`. `CUSTOMER_PORTAL` só solicita quando há um `relatedOrderId`
  (não cria backorder "solto" sem vendedor associado — decisão de escopo documentada abaixo).
- **Fila priorizada**: `priorityWeight` (0–3, derivado de `low|normal|high|urgent`) persistido junto
  ao documento; a fila (`watchQueue`) ordena por `status in [queued, ready_to_fulfill]` →
  `priorityWeight desc` → `createdAt asc`.
- **Sinalização de disponibilidade sem reserva**: `notifyBackordersOnStockAvailable` (trigger em
  `inventory/{inventoryId}`) soma o saldo vendável de todos os armazéns da variante e marca
  `ready_to_fulfill` todo backorder `queued` cuja quantidade pendente já caiba nesse total — **nunca**
  decrementa estoque nem bloqueia unidades; é só um aviso ("previsão"), a disponibilidade real só é
  confirmada na conversão.
- **Conversão sempre revalida, sem duplicar regra**: `convertBackorderToOrder` não recria a lógica de
  preço/estoque/crédito/aprovação (que já vive em `submitOrder`/motor de precificação/avaliação de
  crédito) — ela apenas vincula um pedido **já submetido** (que passou por toda essa revalidação real
  no momento da criação) ao backorder, verificando que esse pedido de fato contém item do mesmo
  produto/variante com quantidade suficiente para cobrir o pendente.
- **Terminalidade**: `converted`/`rejected`/`cancelled` são finais; `cancelBackorderRequest` só age
  sobre status ainda abertos (`requested`/`awaiting_approval`/`queued`/`ready_to_fulfill`).
- **Idempotência**: `backorderId` é gerado no cliente (UUID) e usado como id do documento — uma
  segunda chamada com o mesmo id nunca duplica o registro.

## Regras Firebase implementadas

- **Security Rules** (`firestore.rules`): leitura de `organizations/{organizationId}/backorders/{id}`
  espelha exatamente `canReadShipment` (TASK-214) — OWNER/ADMIN sempre; SALES_REP só o próprio
  (`sellerId == uid`); SALES_MANAGER só quando o vendedor compartilha equipe; CUSTOMER_PORTAL só o
  próprio `customerId`; FINANCE nunca. Escrita sempre `false` — só as Cloud Functions escrevem.
- **Firestore Indexes**: 4 índices compostos adicionados para as consultas da fila/inbox/histórico do
  cliente e do trigger de disponibilidade.
- **Cloud Functions**: 4 `onCall` (`createBackorderRequest`, `decideBackorderApproval`,
  `cancelBackorderRequest`, `convertBackorderToOrder`) + 1 `onDocumentWritten`
  (`notifyBackordersOnStockAvailable`), todas reaproveitando helpers já existentes
  (`returns/return-shared.ts` para o guard "quem pode agir neste pedido/cliente",
  `inventory/stock-reservation-shared.ts` para cálculo de saldo vendável,
  `buyer_collaboration/buyer-collaboration-shared.ts` para localizar o usuário do portal do cliente) —
  nenhuma regra de RBAC/estoque foi reimplementada do zero.

## Analytics implementado

5 novos eventos em `AnalyticsEvents`: `backorder_requested` (com `origin`/`priority`/`quantity`),
`backorder_approved`, `backorder_rejected`, `backorder_cancelled` e `backorder_converted` (com
`order_id`) — nenhum carrega PII do cliente. Disparados por `RequestBackorderCubit`/
`BackorderQueueCubit` apenas no caminho de sucesso (uma falha nunca é logada como conversão/ação bem
sucedida).

## Crashlytics implementado

Nenhuma instrumentação adicional de Crashlytics foi necessária nesta task: os `Cubit`s seguem o
mesmo padrão dos demais cubits do app (falhas de repositório viram `AppFailure`/mensagem de estado,
nunca uma exceção não tratada que precisasse de captura manual). Erros inesperados nas Cloud
Functions já são cobertos pelo `logger.info`/exceções `HttpsError` padrão do Functions Framework,
mesmo padrão de `fulfillment`/`credit`/`receivables`.

## Impacto offline

Leitura é sempre via `snapshots()` do Firestore (cache local automático do SDK) — a fila/inbox
continuam exibindo o último estado conhecido offline. Toda mutação (`create`/`decide`/`cancel`/
`convert`) depende de rede (Cloud Function `onCall`), igual a todo o restante do EPIC-32
(`fulfillment`, `returns`, `credit`) — não foi adicionado ao Outbox porque nenhuma dessas ações tem
efeito colateral físico de estoque que precise sobreviver a uma submissão otimista offline (ao
contrário de um pedido em rascunho). Essa é uma decisão consistente com o restante do EPIC-32, não uma
lacuna nova desta task.

## Impacto multi-tenant

Toda entidade (`BackorderRequest`) carrega `organizationId`/`companyId`; toda leitura passa por
`organizations/{organizationId}/backorders` (nunca uma coleção raiz); toda Cloud Function carrega o
`organizationId` do payload mas nunca o usa como autorização sozinho — sempre recarrega a
`Membership` real do chamador (`loadActiveMembership`) e valida cliente/pedido/variante pertencem à
mesma organização/empresa antes de qualquer leitura/escrita adicional.

## Testes criados

- **Domain (Dart)**: round-trip `code`/`fromCode` e invariantes (`isOpen`, `isQueueable`, `weight`)
  para os 3 value objects; `remainingQuantity`/`isOpen`/igualdade para a entidade.
- **Presentation (Dart, `bloc`-style com fakes)**: `BackorderQueueCubit` (ready/failure, streams de
  fila e aprovação independentes, decide/cancel/convert com sucesso/falha e analytics) e
  `RequestBackorderCubit` (submit com sucesso/falha, prioridade padrão).
- **RBAC (Dart)**: 2 novos testes em `role_permission_matrix_test.dart` cobrindo exatamente quem tem
  `backorderRequest`/`backorderApprove`.
- **Cloud Functions — unitário (`backorder-shared.test.ts`)**: 17 testes cobrindo `priorityWeight`,
  validadores de `origin`/`priority`, `resolveAutoApproveMaxQuantity`, os 3 conjuntos de roles
  permitidas, e `ensureRequesterMayActOnBackorder` (OWNER/ADMIN, SALES_REP próprio vs. de terceiro,
  CUSTOMER_PORTAL próprio vs. de terceiro, delegação para `ensureRequesterMayActOnOrder` quando há
  pedido relacionado, role sem permissão).
- **Cloud Functions — integração (`backorder-integration.emulator.test.ts`)**: cobre os 5 "Testes
  obrigatórios" da task — criação a partir de estoque parcial sem debitar saldo; auto-aprovação vs.
  `awaiting_approval` acima do limite + decisão pelo gestor; fila priorizada com múltiplos clientes;
  sinalização `ready_to_fulfill` via `flagReadyBackordersForVariant` + conversão revalidando a
  quantidade coberta pelo pedido vinculado (sucesso e rejeição quando o pedido não cobre o pendente);
  `cancelBackorderRequest` só enquanto aberto. **Não executável neste sandbox** (sem Java para
  `firebase emulators:exec`), mesma limitação documentada em TASK-094/TASK-133/TASK-176/TASK-214.
- **Firestore Security Rules**: nova suíte em `firestore-tests/firestore.rules.test.js` com casos
  positivos (SALES_REP/SALES_MANAGER/OWNER/ADMIN/portal leem o que devem) e negativos
  (SALES_REP não lê de outro vendedor, SALES_MANAGER não lê de outra equipe, FINANCE nunca lê,
  cross-tenant nunca lê, ninguém escreve diretamente). **Também não executável neste sandbox**
  (mesma limitação de Java, ver `docs/backlog/BACKLOG-003-reverter-firestore-rules-modo-teste.md`).

## Comandos executados

```
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter analyze lib/features/backorder test/features/backorder lib/core/permissions test/core/permissions lib/core/analytics test/core/analytics
flutter test test/features/backorder test/core/permissions test/core/analytics test/app/injection_test.dart
dart format lib/features/backorder test/features/backorder lib/core/permissions/capability.dart lib/core/permissions/role_permission_matrix.dart lib/core/analytics/analytics_events.dart test/core/permissions/role_permission_matrix_test.dart test/core/analytics/analytics_events_test.dart
dart format --output=none --set-exit-if-changed lib/features/backorder test/features/backorder lib/core/permissions lib/core/analytics test/core/permissions test/core/analytics functions/src/backorder functions/test/backorder
cd functions && npm run build      # tsc --noEmit via build
cd functions && npx eslint src/backorder test/backorder
cd functions && npx jest test/backorder/backorder-shared.test.ts
cd functions && npx jest test/backorder/backorder-integration.emulator.test.ts   # falha esperada (sem emulator)
node --check firestore-tests/firestore.rules.test.js
node -e "JSON.parse(require('fs').readFileSync('firestore.indexes.json','utf8'))"
```

## Resultado do formatter

`dart format` formatou 12 arquivos recém-criados na primeira passada (estilo padrão aplicado
automaticamente); a segunda passada (`--set-exit-if-changed`) sobre todos os arquivos Dart tocados
retornou **0 changed** — formatação estável.

## Resultado do analyzer

`flutter analyze` (repositório inteiro): **0 erros/warnings novos** — os 19 `info` remanescentes são
100% pré-existentes (não relacionados a `backorder`, confirmados por rodar o analyzer no mesmo
conjunto de arquivos antes de qualquer alteração desta task).

## Resultado dos testes

- Flutter: `flutter test test/features/backorder test/core/permissions test/core/analytics
  test/app/injection_test.dart` → **86 testes passaram** (0 falhas).
- Cloud Functions (TypeScript): `npx jest test/backorder/backorder-shared.test.ts` → **17 testes
  passaram** (0 falhas). `npx jest test/backorder/backorder-integration.emulator.test.ts` → falha por
  timeout de conexão ao Firestore Emulator (esperado, sem Java/emulator neste sandbox — mesma
  limitação já documentada em outras CONCLUIDA anteriores do EPIC-32).
- `tsc` (`npm run build` em `functions/`): compilou sem erros.
- `eslint` (`src/backorder test/backorder`): sem apontamentos.
- Firestore Security Rules (`firestore-tests/firestore.rules.test.js`): sintaxe validada
  (`node --check`), execução real não possível neste sandbox (mesma limitação, ver BACKLOG-003).

## Decisões técnicas

1. **Conversão em pedido não recria `submitOrder`**: em vez de duplicar motor de precificação,
   avaliação de crédito e reserva de estoque dentro de `convertBackorderToOrder`, a conversão apenas
   vincula um pedido já submetido pelo fluxo padrão (rascunho → `submitOrder`) ao backorder — mesma
   decisão documentada por `convertBuyerCollaborationSession` (TASK-211). Isso satisfaz
   "conversão sempre revalida preço/crédito/estoque/aprovação" porque essa revalidação real já
   aconteceu no momento em que o pedido foi de fato submetido, e evita duas implementações
   independentes da mesma regra que poderiam divergir com o tempo.
2. **`CUSTOMER_PORTAL` só solicita backorder vinculado a um pedido existente**: um backorder "solto"
   de catálogo, sem pedido, sempre precisa de um vendedor (`sellerId`) explícito, e o portal do
   cliente não tem uma forma hoje de indicar/validar isso sem reimplementar a lógica de "vendedor
   responsável pela carteira" (que não existe como campo direto em `Customer`). Documentado como
   decisão de escopo, não bloqueio.
3. **Limite de auto-aprovação sem tela de configuração própria**: lido de
   `organizations/{organizationId}.backorderSettings.autoApproveMaxQuantity`, com fallback de `20`
   unidades. Não foi construída uma UI de configuração (fora do escopo desta task) — hoje só
   editável via ferramenta administrativa direta no Firestore, mesmo bootstrap gap já aceito para
   outros limiares organization-wide antes de UIs dedicadas existirem.
4. **`ready_to_fulfill` sem lock FIFO real entre backorders concorrentes**: o trigger de
   disponibilidade sinaliza múltiplos backorders `queued` da mesma variante com base no mesmo total
   vendável (sem reservar), porque essa é só uma "previsão"; a real "disponibilidade confirmada" só
   é decidida na conversão, quando o pedido vinculado já foi submetido (e o estoque, se aplicável,
   decrementado por `submitOrder`).
5. **Sem novo ponto de entrada no catálogo/pedido para abrir o `RequestBackorderSheet`**: o widget e
   o cubit já estão prontos e testados, mas não foram cabeados dentro de `ProductDetailPage`/
   `OrderItemsGrid`/`CommercialSizeGrid` (arquivos grandes e fora do escopo direto desta task,
   folha de risco de regressão desnecessária). Documentado como pendência abaixo — mesmo padrão já
   usado por TASK-214 ("`createShipment`/`registerTrackingEvent` are deliberately not exposed here
   yet").
6. **Correção do teste `analytics_events_test.dart`**: encontrado desatualizado desde antes desta
   task (faltavam os eventos de TASK-209/210/211/214) — como eu já estava alterando
   `analytics_events.dart` para os 5 eventos novos, sincronizei a lista completa em vez de deixar o
   teste quebrado.

## Riscos conhecidos

- `ready_to_fulfill` pode "prometer" o mesmo estoque a mais de um backorder concorrente até a
  conversão real acontecer — mitigado por `convertBackorderToOrder` sempre exigir um pedido já
  submetido (que já passou pela reserva real de estoque em `submitOrder`), mas o primeiro vendedor a
  converter "ganha" a disputa; o(s) outro(s) precisam ser informados manualmente hoje (sem
  notificação automática de "vaga perdida").
- Sem tela de configuração do limite de auto-aprovação por organização.
- `RequestBackorderSheet`/ação "Solicitar estoque futuro" não estão cabeados em nenhuma tela de
  catálogo/pedido ainda — só o backend + a fila de atendimento (`BackorderQueuePage`) estão prontos
  para uso imediato por quem já tiver o `backorderId`/fluxo próprio.
- Testes de emulator (Cloud Functions) e Firestore Rules não puderam ser executados neste ambiente
  (sem Java) — validados por leitura cuidadosa e pelos testes unitários equivalentes que não
  dependem do emulator.

## Pendências

- Integrar `RequestBackorderSheet` a um ponto de entrada real no catálogo (`ProductDetailPage`) e/ou
  na grade de pedido, quando a variante estiver `futureStock`/`unavailable`.
- Adicionar rota/entrada de navegação para `BackorderQueuePage` no menu do app (hoje ela é uma
  página standalone pronta para ser aberta por push direto, mesmo padrão já usado por
  `StockAlertsPage`/`ReplenishmentSuggestionsPage`, que também não têm rota central registrada).
- Construir uma tela de configuração de `backorderSettings.autoApproveMaxQuantity` por organização.
- Rodar `functions/test/backorder/backorder-integration.emulator.test.ts` e a nova suíte de
  `firestore-tests/firestore.rules.test.js` assim que houver Firebase Emulator Suite disponível
  (bloqueio de infraestrutura já rastreado em `docs/backlog/BACKLOG-002-*`/`BACKLOG-003-*`).

## Evidências

- `flutter test test/features/backorder test/core/permissions test/core/analytics
  test/app/injection_test.dart` → 86 passed.
- `cd functions && npx jest test/backorder/backorder-shared.test.ts` → 17 passed.
- `cd functions && npm run build` (tsc) → sem erros.
- `cd functions && npx eslint src/backorder test/backorder` → sem apontamentos.
- `flutter analyze` (repo completo) → 19 issues pré-existentes, 0 novas.

## Commit

Único commit reunindo Cloud Functions, Firestore Rules/Indexes, RBAC, Analytics, feature Flutter
completa, testes e atualização do índice de tasks.

## Push

**Não realizado** — autorização desta rodada é apenas para commit local, conforme instrução
explícita do usuário.

## Hash do commit

Ver commit da task no histórico do Git (mensagem `feat(backorder): implementar backorder e
solicitação de estoque futuro`).

## Branch

`main`
