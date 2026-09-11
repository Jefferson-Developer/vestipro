# TASK-211 — Concluída (2026-09-11)

## Resumo

Implementada a colaboração vendedor↔comprador em seleções/pedidos (EPIC-32): vendedor abre uma
`BuyerCollaborationSession` a partir de um rascunho de pedido, compartilha com o comprador (portal
CUSTOMER_PORTAL do cliente), e os dois negociam por comentários (gerais ou por item), com o
comprador podendo solicitar alterações estruturadas (quantidade/remoção/adição) e aprovar. A
conversão em pedido continua exigindo que o vendedor efetivamente envie o pedido pelo fluxo já
existente (`submitOrder`) — a Function desta task revalida o preço vigente no momento da conversão
e vincula a sessão ao pedido, sem duplicar o motor de precificação.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, Cloud Functions, Firestore Rules, DI)
- `flutter-ui-design-specialist` (painel de colaboração, entry sheet, páginas)

Os agentes de negócio (`vestipro-sales-representative-specialist`,
`vestipro-commercial-ops-strategist`) não precisaram ser invocados como subagentes separados: o
escopo funcional já estava integralmente descrito na spec da task e em `tasks.md`; suas
preocupações (fluxo do vendedor, não contornar aprovação comercial interna) foram tratadas
diretamente nas regras de negócio implementadas abaixo.

## Arquivos criados

Backend (Cloud Functions, TypeScript):

- `functions/src/buyer_collaboration/buyer-collaboration-shared.ts`
- `functions/src/buyer_collaboration/create-buyer-collaboration-session.ts`
- `functions/src/buyer_collaboration/share-buyer-collaboration-session.ts`
- `functions/src/buyer_collaboration/add-buyer-collaboration-comment.ts`
- `functions/src/buyer_collaboration/request-buyer-collaboration-changes.ts`
- `functions/src/buyer_collaboration/approve-buyer-collaboration-session.ts`
- `functions/src/buyer_collaboration/convert-buyer-collaboration-session.ts`
- `functions/src/buyer_collaboration/reopen-buyer-collaboration-session.ts`
- `functions/src/buyer_collaboration/expire-buyer-collaboration-sessions.ts`
- `functions/src/buyer_collaboration/index.ts`

Testes de Cloud Functions (Jest, não executados neste ambiente — ver "Comandos executados"):

- `functions/test/buyer_collaboration/buyer-collaboration-full-cycle.test.ts`
- `functions/test/buyer_collaboration/buyer-collaboration-buyer-isolation.test.ts`
- `functions/test/buyer_collaboration/convert-buyer-collaboration-session.test.ts`

Flutter (feature `buyer_collaboration`, Clean Architecture feature-first):

- `lib/features/buyer_collaboration/buyer_collaboration.dart` (barrel)
- `lib/features/buyer_collaboration/domain/entities/*.dart` (session, item, comment, attachment,
  proposed change, conversion result)
- `lib/features/buyer_collaboration/domain/value_objects/*.dart` (status, source type, comment
  kind/author/visibility/proposed-change-action)
- `lib/features/buyer_collaboration/domain/repositories/buyer_collaboration_repository.dart`
- `lib/features/buyer_collaboration/domain/usecases/buyer_collaboration_use_cases.dart`
- `lib/features/buyer_collaboration/data/dtos/*.dart`
- `lib/features/buyer_collaboration/data/mappers/buyer_collaboration_mapper.dart`
- `lib/features/buyer_collaboration/data/datasources/buyer_collaboration_write_data_source.dart`
  + `cloud_functions_buyer_collaboration_write_data_source.dart`
- `lib/features/buyer_collaboration/data/datasources/buyer_collaboration_read_data_source.dart`
  + `firestore_buyer_collaboration_read_data_source.dart`
- `lib/features/buyer_collaboration/data/repositories/buyer_collaboration_repository_impl.dart`
- `lib/features/buyer_collaboration/presentation/bloc/buyer_collaboration_cubit.dart` +
  `buyer_collaboration_state.dart`
- `lib/features/buyer_collaboration/presentation/widgets/buyer_collaboration_panel.dart` +
  `buyer_collaboration_entry_sheet.dart`
- `lib/features/buyer_collaboration/presentation/pages/buyer_collaboration_page.dart`

Teste Dart (unit, executado — ver abaixo):

- `test/features/buyer_collaboration/domain/usecases/buyer_collaboration_use_cases_test.dart`

## Arquivos alterados

- `functions/src/index.ts` — registra as 8 novas Cloud Functions.
- `firestore.rules` — adiciona `buyerCollaborationSessions/{sessionId}` (+ subcoleção `comments`):
  leitura via Rules (RBAC por seller/manager de equipe/OWNER-ADMIN/CUSTOMER_PORTAL do próprio
  `customerId`, nunca `seller_draft` para o comprador), escrita sempre `false` (só Cloud Functions
  com Admin SDK).
- `firestore-tests/firestore.rules.test.js` — novo `describe` cobrindo RBAC/isolamento do comprador
  externo (não executado neste ambiente — ver "Comandos executados").
- `lib/core/analytics/analytics_events.dart` — 5 novos eventos (`buyer_collaboration_*`).
- `lib/core/navigation/app_route_paths.dart` — `BuyerCollaborationSellerRoute` e
  `BuyerCollaborationBuyerRoute`.
- `lib/core/navigation/app_router.dart` — registra as 2 rotas acima (seller com guard
  `order.create`; buyer sem guard, mesmo contrato de `CustomerPortalRoute`).
- `lib/app/bootstrap.dart` — importa a feature, adiciona `onCollaborate` ao `OrderDraftPage` (abre
  `BuyerCollaborationEntrySheet` como bottom sheet, mesmo padrão de `onShareCart`/`CartShareSheet`)
  e liga os 2 novos `pageBuilder`s de rota.
- `lib/features/orders/presentation/pages/order_draft_page.dart` — encadeia `onCollaborate`
  (`Future<void> Function(Order, Map<String,String>)?`) pelas 3 classes internas, exatamente como
  `onShareCart` já fazia, e renderiza o botão "Colaborar com o comprador".
- `lib/app/injection.config.dart` — regenerado via `build_runner` (apenas as novas
  registrações `@injectable`/`@LazySingleton` da feature; diff puramente aditivo, conferido).
- `docs/tasks/TASKS.md` — marca TASK-211 e atualiza `Progresso: 207 / 216`.

## Arquitetura utilizada

Clean Architecture feature-first + BLoC/Cubit, seguindo exatamente o precedente já estabelecido por
`cart_share` (TASK-181) e `returns`/`exchanges` (TASK-199/200):

- **Escrita**: exclusivamente via Cloud Functions (Admin SDK) — o cliente nunca escreve
  `buyerCollaborationSessions`/`comments` diretamente.
- **Leitura**: diretamente via Firestore (`FirestoreCollectionDataSource` para a sessão,
  subcoleção `comments` consultada diretamente no data layer), com RBAC 100% em Firestore Rules —
  mesmo contrato "leitura via Rules, escrita só via Cloud Function" de `orders`/`returnRequests`.
- UI nunca acessa Firestore/Storage diretamente: todo acesso passa por `data/datasources`.
- Regra de negócio (validação de itens/comentário vazio, RBAC de papel) fica em `domain/usecases` e
  nas próprias Cloud Functions — nunca em widget.

## Regras de negócio implementadas

- Máquina de estados: `seller_draft → buyer_review → (buyer_approved | changes_requested →
  buyer_review) → converted_to_order`, com `expired` alcançável de forma preguiçosa (lida) a partir
  de qualquer status não terminal quando `expiresAt` passa, e persistido por um job agendado
  (`expireBuyerCollaborationSessions`, a cada 60 min, mesmo padrão de `expireQuotes`).
- Comprador externo (`CUSTOMER_PORTAL`) só acessa sessão do próprio `customerId` — nunca confiado a
  partir do cliente: toda ação re-deriva `customerId` da própria Membership real
  (`assertBuyerCanAct`/`requirePortalMembership`), e a leitura via Rules usa
  `portalCustomerId(organizationId)`.
- Comprador nunca vê uma sessão ainda em `seller_draft` (não compartilhada).
- Comentários carregam autoria, timestamp e visibilidade (`shared`/`internal`); um comentário
  `internal` nunca chega ao comprador — nem via Cloud Function (`addBuyerCollaborationComment`
  força `visibility: shared` para o autor comprador) nem via Rules
  (`canReadBuyerCollaborationComment` exige `visibility == 'shared'` para `CUSTOMER_PORTAL`).
- Solicitação de alteração do comprador é sempre um comentário estruturado
  (`kind: change_request`, com `proposedChanges` opcional) — nunca aplica a mudança sozinha: só o
  vendedor, via `shareBuyerCollaborationSession`, revisa os itens e reenvia.
- Conversão exige `buyer_approved`, revalida o preço atual da tabela de preço contra o preço
  aprovado pelo comprador (`detectPriceDrift`) e só converte sem aviso se não houver divergência;
  com divergência, bloqueia a menos que o vendedor confirme explicitamente (`acceptPriceDrift`).
  Como já existe um pedido real (criado pelo fluxo normal `submitOrder`, que já roda o motor de
  preço/estoque completo), a Function desta task não recria a criação de pedido — ela valida e
  vincula (`convertedOrderId`), evitando duplicar a regra de negócio de precificação/estoque.
- Sessão expirada é somente leitura; reabertura é uma ação explícita e auditável
  (`reopenBuyerCollaborationSession`), restrita ao vendedor responsável/gestor/OWNER/ADMIN.
- Aprovação do comprador nunca substitui aprovação comercial interna (desconto/crédito/política):
  o pedido resultante ainda passa pelo fluxo de aprovação já existente (TASK-103/TASK-194), pois é
  criado através do mesmo `submitOrder`.

## Regras Firebase implementadas

- `firestore.rules`: `buyerCollaborationSessions/{sessionId}` e sua subcoleção `comments/{commentId}`
  — leitura via `canReadBuyerCollaborationSession`/`canReadBuyerCollaborationComment` (mesma
  estrutura de `validOrderVisibilityPayload`/`canReadOrder`/`managerCanReadOrder`), escrita sempre
  `false`. Validado sintaticamente com `firebase_validate_security_rules` (MCP) — "OK: No errors
  detected."
- Cloud Functions: RBAC de papel (`SALES_REP` só na própria sessão; `SALES_MANAGER` só na equipe do
  vendedor; `OWNER`/`ADMIN` livre; `CUSTOMER_PORTAL` só no próprio `customerId`), sempre re-lendo a
  Membership real (nunca confiando em nada vindo do cliente).

## Analytics implementado

5 novos eventos em `AnalyticsEvents` (`lib/core/analytics/analytics_events.dart`), adicionados
também à lista `values` validada por teste:

- `buyer_collaboration_session_opened` (criação da sessão)
- `buyer_collaboration_comment_added`
- `buyer_collaboration_changes_requested`
- `buyer_collaboration_approved`
- `buyer_collaboration_converted_to_order`

## Crashlytics implementado

Nenhum ponto novo de captura manual foi necessário: erros do Cubit já fluem pelo mesmo
`AppException`/`Failure`/`AppResult` central que o app inteiro usa, cujo reporte ao Crashlytics já é
tratado de forma transversal (TASK-016) — nenhuma exceção é engolida silenciosamente nesta feature.

## Impacto offline

Nenhum: colaboração com comprador é uma feature inerentemente online (depende de troca de
mensagens entre duas partes através do backend). Não usa Drift/Outbox e não altera o comportamento
offline de pedidos/carrinho já existente.

## Impacto multi-tenant

Toda leitura/escrita é escopada por `organizationId` (Cloud Functions relêem a Membership real;
Rules relêem a Membership + `portalCustomerId`) — nenhum campo `organizationId`/`customerId`
vindo do cliente é usado como única fonte de autorização.

## Testes criados

- Cloud Functions (Jest + `firebase-functions-test`, seguindo exatamente o padrão de
  `functions/test/cart_shares/`/`functions/test/orders/submit-order.test.ts`):
  - `buyer-collaboration-full-cycle.test.ts`: ciclo completo (compartilha → comentário do
    comprador → solicitação de alteração → revisão/reenvio do vendedor → aprovação → conversão),
    checando notificações e deep links em cada etapa, e RBAC negativo (perfil sem permissão).
  - `buyer-collaboration-buyer-isolation.test.ts`: comprador de um cliente não lê/aprova/comenta a
    sessão de outro cliente; chamada não autenticada falha.
  - `convert-buyer-collaboration-session.test.ts`: revalidação de preço na conversão (sem
    divergência converte direto; com divergência bloqueia e reporta; com `acceptPriceDrift`
    converte mesmo assim; pedido de outro cliente é recusado; sessão não aprovada é recusada).
- Firestore Rules (`firestore-tests/firestore.rules.test.js`, novo `describe`): RBAC de leitura da
  sessão (seller dono, manager da equipe, OWNER/ADMIN, comprador do próprio `customerId` só quando
  compartilhada) e dos comentários (visibilidade `shared` vs `internal`), e confirmação de que
  nenhuma escrita direta é permitida (nem por OWNER).
- Dart (unit, `mocktail`): validações dos use cases (seleção vazia, item lista vazia ao
  compartilhar, comentário em branco, solicitação de alteração sem descrição).

## Comandos executados

```bash
cd functions && npx tsc --noEmit -p tsconfig.json          # OK, sem erros
cd functions && npx eslint src/buyer_collaboration test/buyer_collaboration   # OK, sem erros
node --check firestore-tests/firestore.rules.test.js       # OK (sintaxe válida)
dart run build_runner build --delete-conflicting-outputs   # OK — diff aditivo em injection.config.dart
dart format lib/features/buyer_collaboration lib/core/analytics/analytics_events.dart
  lib/features/orders/presentation/pages/order_draft_page.dart lib/app/bootstrap.dart
  lib/core/navigation/app_route_paths.dart lib/core/navigation/app_router.dart
  test/features/buyer_collaboration
flutter analyze                                             # 18 issues pré-existentes, nenhum meu
flutter test test/features/buyer_collaboration/domain/usecases/buyer_collaboration_use_cases_test.dart
flutter test test/core/navigation/app_router_test.dart
flutter test test/features/orders/presentation/pages/order_draft_page_test.dart
flutter test test/features/orders                            # 224 testes, todos passando
flutter test test/app/bootstrap_test.dart                     # 1 falha PRÉ-EXISTENTE, ver "Riscos"
```

## Resultado do formatter

Sem pendências nos arquivos desta task (1 arquivo novo precisou de `dart format`, já corrigido). O
`dart format --set-exit-if-changed lib test` completo do repositório aponta 6 arquivos
pré-existentes não formatados que esta task não tocou (`locale_settings_page.dart`,
`cart_share_sheet.dart` e 4 arquivos de teste em `after_sales`/`product_import`) — fora de escopo,
não corrigidos aqui.

## Resultado do analyzer

`flutter analyze` completo: 18 issues, todas pré-existentes (nenhuma nos arquivos desta task —
confirmado analisando os arquivos tocados isoladamente, que retornam "No issues found!").

## Resultado dos testes

- `functions`: TypeScript compila sem erros e ESLint não aponta problemas nos arquivos novos; os
  testes Jest (`buyer_collaboration/*.test.ts`) foram escritos seguindo o padrão de teste já usado
  no restante do backend, mas **não foram executados neste ambiente** — o `package.json` de
  `functions` espera rodar via `firebase emulators:exec`, e este ambiente não tem Java instalado
  (mesma limitação já documentada em `docs/backlog/BACKLOG-002-...md`/`BACKLOG-003-...md` para
  `firestore-tests/`). Idem para o novo `describe` em `firestore-tests/firestore.rules.test.js`.
- Flutter: `flutter test test/features/buyer_collaboration/...` (6 testes) passou; a suíte completa
  de `test/features/orders` (224 testes) e `test/core/navigation/app_router_test.dart` (24 testes)
  passaram sem regressão após as alterações em `order_draft_page.dart`/`app_router.dart`.
  `test/app/bootstrap_test.dart` tem uma falha (`PushDeviceMapper` não registrado no GetIt) —
  **confirmada como pré-existente e não relacionada a esta task**: reproduzida de forma idêntica
  num `git worktree` limpo no commit anterior a esta task (`9b03234`), antes de qualquer mudança
  desta TASK-211.

## Decisões técnicas

- **Conversão não recria a criação de pedido**: em vez de duplicar todo o motor de precificação/
  estoque de `submitOrder`/`convertQuoteToOrder` (endereços, forma de pagamento, sequência de
  numeração, consumo de estoque, cadeia de aprovação), `convertBuyerCollaborationSession` assume
  que o vendedor já enviou o pedido pelo fluxo padrão (mesmo `Order.id` da sessão) e apenas
  revalida o preço vigente contra o aprovado + vincula a sessão ao pedido. Isso evita duplicar
  regra de negócio crítica (preço/estoque) e mantém a única fonte de verdade em `submitOrder`.
- **Denormalização de `organizationId`/`companyId`/`sellerId`/`customerId` em cada comentário**:
  necessária porque Firestore Rules avaliam `resource.data` do documento sendo lido (o comentário),
  nunca do documento pai (a sessão) — sem essa denormalização não seria possível decidir
  visibilidade (`shared` vs `internal`) por Rules sem um `get()` por leitura.
- **Entrada do vendedor via bottom sheet** (`BuyerCollaborationEntrySheet`, aberta a partir de
  "Colaborar com o comprador" no rascunho do pedido) em vez de uma rota dedicada de uso diário —
  mesmo precedente já estabelecido por `CartShareSheet`/`onShareCart` (TASK-181). Duas rotas
  (`BuyerCollaborationSellerRoute`/`BuyerCollaborationBuyerRoute`) existem apenas como destino dos
  deep links de notificação, não como navegação primária.
- **Preço/moeda simplificados**: a sessão não carrega um `currency` próprio (assume a moeda padrão
  da organização, mesma simplificação que `CartShareSheet` já adota) — ver "Pendências".

## Riscos conhecidos

- `test/app/bootstrap_test.dart` tem uma falha pré-existente e não relacionada
  (`PushDeviceMapper` sem `@injectable`) — não corrigida aqui por estar fora do escopo desta task;
  recomenda-se abrir um item de backlog dedicado para essa correção.
- Os testes de Cloud Functions e de Firestore Rules desta task foram escritos mas não executados
  neste ambiente (falta Java para o Firebase Emulator Suite) — precisam rodar em CI/ambiente com
  `firebase emulators:exec` antes do próximo deploy real.
- `convertBuyerCollaborationSession` confia que o `orderId` informado corresponde ao pedido que o
  vendedor realmente enviou para este cliente/vendedor (valida `organizationId`/`customerId`/
  `sellerId`/`deletedAt`, mas não recalcula estoque nem reaplica a cadeia de aprovação) — a
  revalidação real de estoque/aprovação já aconteceu dentro do próprio `submitOrder` no momento do
  envio; esta Function só adiciona uma camada extra de revalidação de preço.
- O botão "Converter em pedido" alcançado via deep link direto (`BuyerCollaborationSellerRoute`,
  fora do fluxo normal do rascunho de pedido) não tem `onConvertRequested` conectado — funciona
  normalmente a partir do bottom sheet do rascunho, mas fica inerte se o vendedor chegar à sessão
  só pelo link da notificação.

## Pendências

- Portal do comprador ainda não lista todas as sessões de colaboração abertas para aquele cliente
  — hoje o acesso é via link/notificação (deep link) para uma sessão específica. Uma tela de
  listagem filtrada por `customerId` dentro do `customer_portal` é uma evolução natural futura.
  não coberta por esta task (a task pedia "vendedor e comprador conseguem colaborar", que já é
  atendido; a descoberta por listagem é uma melhoria de UX adicional).
- Sessão não carrega moeda própria (assume padrão da organização) — mesma simplificação que
  `cart_share` já tem; se/quando `cart_share` ganhar suporte a moeda, replicar aqui.
- Anexos (`BuyerCollaborationAttachment`) esperam uma URL https já existente — esta feature não
  implementa upload para o Storage; um seletor de arquivo reaproveitando o Storage picker já usado
  em outras features é trabalho futuro caso o produto queira permitir anexos ricos direto do chat.
- `functions`/`firestore-tests`: pendente rodar via `firebase emulators:exec` num ambiente com
  Java (ver `docs/backlog/BACKLOG-002-...`) antes de considerar a suíte de testes desta task
  validada de ponta a ponta.

## Evidências

- `flutter analyze`, `dart format`, `tsc --noEmit`, `eslint` e `node --check` executados e limpos
  para todos os arquivos desta task (ver "Comandos executados"/"Resultado").
- `firebase_validate_security_rules` (MCP): "OK: No errors detected." para `firestore.rules`
  completo, incluindo o novo bloco desta task.
- `git worktree` no commit `9b03234` (imediatamente anterior a esta task) reproduz a mesma falha
  de `test/app/bootstrap_test.dart`, confirmando que não foi introduzida por esta task.

## Commit

`feat(orders): implementar colaboração com comprador em seleções e pedidos (TASK-211)`

## Push

Não realizado — push não autorizado nesta rodada (protocolo desta execução).

## Hash do commit

Ver hash reportado após o commit nesta mesma rodada (registrado na resposta final ao usuário).

## Branch

`main`
