# TASK-102 — Concluída (2026-08-31)

## Resumo
Implementada a listagem e o acompanhamento de pedidos (EPIC-13): tela com filtros
combináveis (status, período, cliente, vendedor), busca rápida com debounce, paginação
por cursor server-side, RBAC de visibilidade (vendedor vê só os próprios pedidos, gestor
vê os da própria equipe, OWNER/ADMIN vê tudo da company) e uma seção dedicada para
pedidos ainda pendentes de sincronização (só existem localmente no dispositivo). Também
foi modelado `orderNumber` (gerado pela Cloud Function `submitOrder`, TASK-101) na
entidade/DTO/Drift do client, que ainda não existia, e foram criadas as Firestore
Security Rules de leitura para `orders` (não existiam até esta task).

## Agentes utilizados
- `flutter-senior-architect` (arquitetura, domínio, dados, RBAC, Firestore Rules, Drift).
- `flutter-ui-design-specialist` (perspectiva de UI/Design System coberta diretamente pelo
  agente arquiteto nesta execução — reuso de `AppDataTable`, `AppAdminPageLayout`,
  `AppPagination`, `AppStatusBadge`, responsividade card/tabela, acessibilidade
  ícone+texto).

## Arquivos criados
- `lib/features/orders/domain/entities/order_list_filters.dart`
- `lib/features/orders/domain/entities/order_list_page_result.dart`
- `lib/features/orders/domain/entities/order_visibility_filter.dart`
- `lib/features/orders/domain/repositories/order_list_repository.dart`
- `lib/features/orders/domain/services/order_visibility_service.dart`
- `lib/features/orders/domain/usecases/list_orders_use_case.dart`
- `lib/features/orders/domain/usecases/list_local_pending_orders_use_case.dart`
- `lib/features/orders/data/dtos/order_list_page_dto.dart`
- `lib/features/orders/data/datasources/order_list_data_source.dart`
- `lib/features/orders/data/datasources/firestore_order_list_data_source.dart`
- `lib/features/orders/data/repositories/order_list_repository_impl.dart`
- `lib/features/orders/presentation/bloc/order_list_bloc.dart`
- `lib/features/orders/presentation/bloc/order_list_event.dart`
- `lib/features/orders/presentation/bloc/order_list_state.dart`
- `lib/features/orders/presentation/pages/order_list_page.dart`
- `test/features/orders/domain/entities/order_list_filters_test.dart`
- `test/features/orders/domain/services/order_visibility_service_test.dart`
- `test/features/orders/domain/usecases/list_orders_use_case_test.dart`
- `test/features/orders/presentation/bloc/order_list_bloc_test.dart`
- `test/features/orders/presentation/pages/order_list_page_test.dart`
- `test/core/database/app_database_orders_test.dart`
- `docs/tasks/TASK-102-implementar-listagem-de-pedidos-CONCLUIDA.md` (este arquivo)

## Arquivos alterados
- `lib/features/orders/domain/entities/order.dart` (+`order.freezed.dart`, gerado): novo
  campo `orderNumber` (`String?`).
- `lib/features/orders/data/dtos/order_dto.dart`, `data/mappers/order_mapper.dart`,
  `data/mappers/order_local_mapper.dart`: `orderNumber` serializado/mapeado.
- `lib/core/database/tables/orders_table.dart`, `lib/core/database/app_database.dart`
  (+`app_database.g.dart`, gerado): coluna `orderNumber` nullable; `schemaVersion` 10 → 11
  com migração `addColumn`.
- `lib/features/orders/domain/repositories/order_draft_repository.dart` +
  `data/repositories/drift_order_draft_repository.dart`: novo método
  `getLocalOrdersForCompany` (lê o cache local completo do device, base da seção de
  pendentes de sincronização).
- `lib/app/bootstrap.dart`: `_submitOrder` agora persiste `submission.orderNumber` no
  pedido local reconciliado; `orderListPageBuilder` registrado no `AppRouter` com
  deep-link de filtros.
- `lib/core/navigation/app_route_paths.dart`, `app_router.dart`: nova rota
  `OrderListRoute` (`/org/:orgId/companies/:companyId/orders`), protegida por
  `order.view`.
- `lib/core/permissions/capability.dart`, `role_permission_matrix.dart`: nova
  `Capability.orderView` (`order.view`), concedida a SALES_MANAGER e SALES_REP.
- `firestore.rules`: `roleHasCapability` ganha `order.view` para SALES_MANAGER/SALES_REP;
  novo bloco `organizations/{organizationId}/orders/{orderId}` com
  `canReadOrder`/`managerCanReadOrder` (get/list), escrita sempre negada (exclusiva da
  Cloud Function `submitOrder`, Admin SDK).
- `firestore.indexes.json`: índices compostos para as combinações de filtro suportadas
  (`companyId`+`deletedAt`+`createdAt`, e variações com `status`/`customerId`/`sellerId`/
  `orderNumber`).
- `firestore-tests/firestore.rules.test.js`: fixture `orderDoc` + suíte
  `organizations/{organizationId}/orders/{orderId}` (positivos/negativos).
- `lib/features/orders/orders.dart`: exports dos novos arquivos.
- `test/core/database/app_database_test.dart`,
  `test/core/database/app_database_warehouses_test.dart`: `schemaVersion` esperado
  atualizado de 10 para 11 (efeito colateral necessário da migração).
- `test/core/permissions/role_permission_matrix_test.dart`: teste cobrindo
  `Capability.orderView` por role.
- `test/features/orders/data/mappers/order_mapper_test.dart`: `fullOrder()` passou a
  popular `orderNumber` para exercitar o round-trip do novo campo.
- `test/features/orders/domain/usecases/add_items_to_order_draft_use_case_test.dart`,
  `start_order_draft_for_customer_use_case_test.dart`: fake `OrderDraftRepository`
  atualizado com o novo método da interface.

## Arquitetura utilizada
Clean Architecture feature-first, seguindo precedentes já existentes no repositório
(`AuditLogBloc`/`LeadListBloc` para paginação+filtros+debounce;
`FirestoreCollectionDataSource<T>` para o datasource paginado;
`PortfolioVisibilityService`/TASK-051 reaproveitado para a resolução de modo de
visibilidade OWNER/ADMIN/SALES_MANAGER/SALES_REP, sem duplicar essa lógica).
`OrderListRepository` é um contrato novo e deliberadamente separado de
`OrderDraftRepository` (100% local) e `OrderSubmissionRepository` (envio pontual) — cobre
apenas a leitura paginada remota. UI nunca acessa Firestore/Drift diretamente; toda regra
de RBAC/seller-scoping vive em `ListOrdersUseCase`/`OrderVisibilityService`.

## Regras de negócio implementadas
- Vendedor (`SALES_REP`) só vê os próprios pedidos, mesmo manipulando o filtro de
  vendedor no client (`ListOrdersUseCase._resolveSellerIds` força `sellerIds` para o
  próprio usuário).
- `SALES_MANAGER` só vê pedidos dos vendedores das equipes que gerencia (resolvido via
  `Team.memberIds`, nunca via `Membership.listByOrganization`, que exige `user.changeRole`
  — ver "Decisões técnicas"); uma escolha explícita de vendedor fora do próprio time
  resulta em lista vazia, nunca em fallback para todos os pedidos.
- `OWNER`/`ADMIN` veem todos os pedidos da company.
- Pedido local (`draft`/`pendingSync`/`syncing`/`failed`/`conflict`, ou seja
  `syncStatus != synced`) aparece em seção separada "Pendentes de sincronização",
  distinta visualmente do pedido confirmado no servidor por texto + ícone (nunca só por
  cor, via `AppStatusBadge`).
- Paginação sempre por cursor (`createdAt` do último item), nunca carrega o histórico
  inteiro.

## Regras Firebase implementadas
- `firestore.rules`: leitura de `organizations/{organizationId}/orders/{orderId}` restrita
  por `canReadOrder` (OWNER/ADMIN, ou SALES_REP dono do pedido, ou SALES_MANAGER cujo
  time inclui o vendedor do pedido via `get()` no Membership do vendedor). Escrita sempre
  negada — `submitOrder` (Admin SDK) continua o único caminho de escrita.
- `firestore.indexes.json`: índices compostos para as combinações de filtro suportadas.

## Analytics implementado
Nenhum evento novo adicionado nesta task — a listagem é somente leitura e reaproveita o
evento `orderSubmitted` já existente (TASK-101). Ficou como pendência um evento de
analytics dedicado a "pedido visualizado/filtro aplicado" (ver Pendências).

## Crashlytics implementado
Nenhuma mudança — os fluxos usam o mesmo padrão `AppResult`/`Failure` já monitorado pela
infraestrutura existente; nenhum novo ponto de falha silenciosa foi introduzido.

## Impacto offline
- Pedidos pendentes de sincronização (criados/editados offline) continuam
  exclusivamente no Drift local (`OrdersTable`) até `submitOrder` confirmar; a listagem
  os exibe via `ListLocalPendingOrdersUseCase`/`OrderDraftRepository.getLocalOrdersForCompany`,
  nunca dependendo de rede para essa seção.
- Uma falha ao ler o cache local nunca bloqueia a página remota (fail-soft, mesmo
  precedente de `ListOrganizationUsersUseCase`).
- A listagem remota (server-side) não tem cache offline nesta task — sem sync engine
  ainda (EPIC-14/TASK-105+), um gestor/OWNER offline não vê pedidos de outros vendedores
  enquanto sem rede. Documentado como risco conhecido.

## Impacto multi-tenant
- Toda query é escopada por `organizationId` (path da subcoleção) e `companyId`
  (`where` explícito) + `deletedAt == null`.
- `organizationId`/`companyId` nunca são a única autorização: RBAC é revalidado
  independentemente pelas Firestore Rules (`canReadOrder`), que releem o Membership real
  do chamador e, para gestores, o Membership real do vendedor do pedido — nunca confiam
  em nenhum valor vindo do client/query.

## Testes criados
- `order_list_filters_test.dart`: normalização, `copyWith`, round-trip de
  `toQueryParameters`/`fromQueryParameters` (deep link), exclusão deliberada de
  `sellerIds` da URL.
- `order_visibility_service_test.dart`: resolução de modo por role
  (allCompany/ownOnly/sellerSubset/none), incluindo que SALES_MANAGER nunca dispara
  `MembershipRepository.listByOrganization`.
- `list_orders_use_case_test.dart`: RBAC de seller-scoping (SALES_REP forçado a si mesmo;
  SALES_MANAGER restrito ao próprio time, com pick fora do time retornando lista vazia
  sem chamar o repositório; OWNER sem restrição; FINANCE negado sem tocar o repositório;
  validação de payload).
- `order_list_bloc_test.dart`: carregamento inicial (pendentes locais + primeira página),
  filtros combinados (status+período+cliente+vendedor), paginação preservando itens já
  carregados, debounce da busca com cancelamento de edição obsoleta.
- `order_list_page_test.dart` (widget): gate `Forbidden` sem `order.view`; diferenciação
  visual (texto + ícone, não só cor) entre pedido pendente de sincronização e confirmado;
  estado vazio.
- `app_database_orders_test.dart`: round-trip da coluna `orderNumber` (com valor e nulo) e
  `getOrdersForCompany` expondo o campo.
- `role_permission_matrix_test.dart`: `Capability.orderView` por role.
- `firestore.rules.test.js`: suíte `organizations/{organizationId}/orders/{orderId}`
  (SALES_REP lê o próprio pedido / não lê de outro vendedor mesmo manipulando query;
  SALES_MANAGER lê do próprio time e não de outro; OWNER/ADMIN leem tudo; FINANCE negado;
  cross-tenant negado; escrita sempre negada mesmo para OWNER).
- Testes existentes ajustados por efeito colateral: `order_mapper_test.dart` (orderNumber
  no round-trip), `app_database_test.dart`/`app_database_warehouses_test.dart`
  (`schemaVersion` 11), fakes de `OrderDraftRepository` em dois testes de use case.

## Comandos executados
- `dart run build_runner build` (regeração de freezed/injectable/drift após adicionar
  `orderNumber`, `Capability.orderView` e os novos `@injectable`/`@LazySingleton`).
- `flutter analyze --no-fatal-infos`
- `dart format --output=none --set-exit-if-changed .` e `dart format <arquivos novos>`
- `flutter test` (suíte completa) e execuções focadas em
  `test/features/orders`, `test/core/database`, `test/core/permissions`,
  `test/core/navigation`.
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` — **não
  executado com sucesso**: o ambiente não tem Java instalado (`java -version` falha com
  "command not found"), pré-requisito do Firestore Emulator. Ver Pendências.

## Resultado do formatter
`dart format --output=none --set-exit-if-changed .` → `Formatted 1662 files (0 changed)`
(limpo, sem pendências) após formatar os arquivos novos/alterados.

## Resultado do analyzer
`flutter analyze --no-fatal-infos` → **2 issues** (ambos infos pré-existentes, não
relacionados a esta task: `use_null_aware_elements` em
`cloud_functions_order_submission_data_source.dart` — arquivo não tocado nesta task — e
`prefer_initializing_formals` em um teste de use case pré-existente). Nenhum erro.

## Resultado dos testes
`flutter test` completo: **2133 testes, todos passando** (0 falhas) após todos os ajustes
descritos acima. Execuções focadas em `test/features/orders` +
`test/core/database`/`permissions`/`navigation` também 100% verdes.

Testes de Firestore Rules (`firestore-tests/firestore.rules.test.js`): escritos
(descrevendo o contrato positivo/negativo completo para `orders`), mas **não executados**
neste ambiente por falta de Java (pré-requisito do Firebase Emulator Suite). Recomendo
rodar `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em
CI/ambiente com Java antes do deploy das novas Rules.

## Decisões técnicas
- **Visibilidade de vendedor via `Team.memberIds`, não via `MembershipRepository.listByOrganization`**:
  `firestore.rules` restringe a leitura em lote (`list`) de `members` a quem tem
  `user.changeRole` (hoje só OWNER/ADMIN) — um SALES_MANAGER nunca teria essa permissão.
  Como `Team` já é livremente legível por qualquer membro ativo e já denormaliza
  `memberIds`, `OrderVisibilityService` resolve o conjunto de vendedores visíveis a partir
  dos times do próprio gestor, sem precisar de nenhuma mudança na regra sensível de
  `members`.
- **Regra de leitura de pedido usa `get()` no Membership do vendedor, não `teamId`
  denormalizado no pedido**: ao contrário de `Customer` (que carrega `teamId` denormalizado
  para a regra `managerCanReadCustomer`), `Order` não tem esse campo (um vendedor pode
  pertencer a mais de um time) e adicioná-lo exigiria alterar a Cloud Function
  `submitOrder` (TASK-101, já commitada/testada) — decisão deliberada de não tocar nela.
  Em vez disso, `managerCanReadOrder` faz um `get()` no `members/{sellerId}` do próprio
  pedido (mesmo custo de leitura extra que `managerCanReadCustomer` já paga para resolver
  `teamId`).
- **Busca rápida por número do pedido OU cliente via heurística**: como o pedido não
  guarda nome do cliente (só `customerId`) e adicionar isso exigiria mudar a Function de
  submissão, a busca por texto único aplica um filtro de igualdade em `orderNumber`
  (quando o texto é só dígitos) ou em `customerId` (caso contrário) — documentado como
  simplificação deliberada, não uma busca textual por nome.
- **Filtro "vendedor" é um campo de texto livre (ID), não dropdown com nomes**: resolver
  nomes exigiria ou uma leitura em lote de `members` (bloqueada por RBAC para
  SALES_MANAGER, ver acima) ou N leituras individuais — mesma convenção já usada em
  filtros de ID cru no restante do código (`productId`/`warehouseId` em
  `StockAlertFilters`).
- **`sellerIds` do filtro nunca é persistido/lido da URL** (`toQueryParameters` o exclui
  deliberadamente): sempre recomputado a partir de `OrderVisibilityService`, para que um
  link manipulado nunca amplie a visibilidade real do usuário.

## Riscos conhecidos
- Sem sync engine (EPIC-14/TASK-105+), a listagem remota não tem cache offline: um
  gestor/OWNER sem conexão não vê pedidos de outros vendedores enquanto offline (só os
  próprios, se já tiverem sido criados neste device).
- `whereIn` do Firestore aceita no máximo 30 valores: uma equipe com mais de 30 vendedores
  visíveis é truncada às primeiras 30 (nunca é uma falha de segurança — `firestore.rules`
  continua negando qualquer documento fora da visibilidade real — apenas um limite de
  cobertura de resultado documentado em `kOrderSellerIdsQueryLimit`).
- Índices compostos em `firestore.indexes.json` cobrem as combinações mais prováveis de
  filtro, mas combinações adicionais não previstas podem exigir criação de índice sob
  demanda (o próprio Firestore reporta o link de criação no erro em produção/emulador).
- Testes de Firestore Rules não executados neste ambiente (falta de Java) — ver
  Pendências.

## Pendências
- Rodar `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`
  em um ambiente com Java instalado (CI) antes do deploy de `firestore.rules`.
- "Cancelamento local" de um pedido pendente de sincronização (mencionado em
  `tasks.md`/na task como regra) não foi implementado nesta task — só "edição" (via
  `OrderDraftRoute` existente) foi wired. Não existe ainda um caso de uso de
  cancelamento/exclusão de rascunho local no repositório; construir isso é uma unidade de
  trabalho separada, fora do escopo central de "listagem e acompanhamento".
- Nenhum item de menu/navegação global aponta para `OrderListRoute` ainda — mesma
  situação de `CustomerPortfolioRoute`/`AuditLogRoute`, que também não têm entrada em
  nenhum shell de navegação hoje (não existe esse shell ainda no repositório). A rota é
  acessível via `context.go`/deep link.
- Nomes de cliente/vendedor não são resolvidos na listagem (mostra IDs crus) — resolver
  nomes é UX futura, não bloqueante para a função de acompanhamento.
- Nenhum evento de analytics dedicado para "listagem de pedidos visualizada"/"filtro
  aplicado" foi adicionado (fora do escopo mínimo de eventos já definidos).

## Evidências
- `flutter test`: 2133 testes, 0 falhas (última execução completa desta rodada).
- `flutter analyze --no-fatal-infos`: 2 infos pré-existentes, 0 erros.
- `dart format --output=none --set-exit-if-changed .`: 0 arquivos pendentes de formatação.

## Commit
Único commit local cobrindo implementação + documentação + atualização do
`docs/tasks/TASKS.md`.

## Push
Não realizado — autorização desta rodada é apenas para commit local, conforme instrução
explícita do usuário.

## Hash do commit
Preenchido após a criação do commit (ver mensagem final da execução).

## Branch
`main` (mesma branch corrente do repositório; nenhuma branch nova foi criada).
