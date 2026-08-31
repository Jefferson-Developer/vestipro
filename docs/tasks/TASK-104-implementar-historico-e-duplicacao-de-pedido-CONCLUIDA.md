# TASK-104 — Concluída (2026-08-31)

## Resumo

Implementado o histórico detalhado de um pedido (linha do tempo somente leitura, a
partir de `Order.statusHistory`) e a ação "Repetir pedido" (duplicação), que cria um
novo rascunho `OrderDraft` a partir de um pedido já submetido, sempre revalidando
preço e disponibilidade atuais de cada item — nunca copiando valores antigos como se
ainda fossem válidos. Esta é a última task do EPIC-13 — Pedidos, que fica
completamente concluído com esta entrega.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domínio, dados, RBAC, offline, DI, testes).
- Perspectiva de `flutter-ui-design-specialist` coberta diretamente pelo agente
  executor (Design System existente reaproveitado: `AppTimeline`, `AppAdminPageLayout`,
  `AppDataTable`, `AppSnackbar`, badges de status), sem necessidade de subagente
  separado.

## Arquivos criados

- `lib/features/orders/domain/entities/order_duplication_item_issue.dart`
- `lib/features/orders/domain/entities/order_duplication_price_change.dart`
- `lib/features/orders/domain/entities/order_duplication_result.dart`
- `lib/features/orders/domain/usecases/get_order_by_id_use_case.dart`
- `lib/features/orders/domain/usecases/duplicate_order_use_case.dart`
- `lib/features/orders/presentation/bloc/order_history_event.dart`
- `lib/features/orders/presentation/bloc/order_history_state.dart`
- `lib/features/orders/presentation/bloc/order_history_bloc.dart`
- `lib/features/orders/presentation/bloc/order_duplication_state.dart`
- `lib/features/orders/presentation/bloc/order_duplication_cubit.dart`
- `lib/features/orders/presentation/widgets/order_status_history_timeline.dart`
- `lib/features/orders/presentation/pages/order_history_page.dart`
- `test/features/orders/domain/usecases/get_order_by_id_use_case_test.dart`
- `test/features/orders/domain/usecases/duplicate_order_use_case_test.dart`
- `test/features/orders/presentation/bloc/order_history_bloc_test.dart`
- `test/features/orders/presentation/widgets/order_status_history_timeline_test.dart`

## Arquivos alterados

- `lib/features/orders/domain/entities/order.dart` (+ `order.freezed.dart` regenerado):
  campos informativos `duplicatedFromOrderId`/`duplicatedFromOrderNumber`.
- `lib/features/orders/domain/repositories/order_list_repository.dart`,
  `lib/features/orders/data/datasources/order_list_data_source.dart`,
  `lib/features/orders/data/datasources/firestore_order_list_data_source.dart`,
  `lib/features/orders/data/repositories/order_list_repository_impl.dart`: novo
  método `getById` (single-doc read).
- `lib/core/database/tables/orders_table.dart`,
  `lib/core/database/app_database.dart` (+ `app_database.g.dart` regenerado):
  colunas `duplicatedFromOrderId`/`duplicatedFromOrderNumber`, `schemaVersion` 11→12,
  migração `addColumn`.
- `lib/features/orders/data/mappers/order_local_mapper.dart`: mapeamento dos novos
  campos local (Drift).
- `lib/features/orders/presentation/pages/order_list_page.dart`: `OrderStatusBadge`,
  `orderStatusVariant`, `orderStatusIcon` tornados públicos (reuso pelo timeline);
  nova ação de linha "Ver histórico" (`onOrderHistorySelected`).
- `lib/core/navigation/app_route_paths.dart`, `lib/core/navigation/app_router.dart`:
  nova rota `OrderHistoryRoute`/`orderHistoryPageBuilder`.
- `lib/app/bootstrap.dart`: wiring de `orderHistoryPageBuilder`,
  `onOrderHistorySelected` e `onDuplicated`.
- `lib/features/orders/orders.dart`: exports dos novos arquivos.
- `lib/core/analytics/analytics_events.dart` (+
  `test/core/analytics/analytics_events_test.dart`): eventos `order_history_viewed`,
  `order_duplicated`.
- `test/features/orders/presentation/bloc/order_list_bloc_test.dart`,
  `test/features/orders/presentation/pages/order_approval_queue_page_test.dart`,
  `test/features/orders/presentation/pages/order_list_page_test.dart`: fakes de
  `OrderListRepository` atualizados com o novo método `getById`.
- `test/core/database/app_database_test.dart`,
  `test/core/database/app_database_warehouses_test.dart`: `schemaVersion` esperado
  atualizado de 11 para 12.
- `docs/tasks/TASKS.md`: checkbox da TASK-104 marcado e progresso incrementado.

## Arquitetura utilizada

Clean Architecture feature-first mantida: `OrderHistoryPage`/`OrderStatusHistoryTimeline`
(presentation) → `OrderHistoryBloc`/`OrderDuplicationCubit` → `GetOrderByIdUseCase`/
`DuplicateOrderUseCase` (domain) → `OrderListRepository`/`OrderDraftRepository`
(contratos) → `OrderListRepositoryImpl`/`DriftOrderDraftRepository` (impl). A UI nunca
acessa Firestore/Drift diretamente. `DuplicateOrderUseCase` não reimplementa nenhuma
regra já existente: reaproveita `GetOrderByIdUseCase` (leitura RBAC-scoped),
`StartOrderDraftForCustomerUseCase` (criação de rascunho, TASK-096 — garante que o
novo rascunho usa unidade/tabela de preço/condição de pagamento *atuais*, nunca as do
pedido de origem), `AddItemsToOrderDraftUseCase`/`OrderItemEditor` (persistência de
itens, TASK-097) e os motores existentes de preço/disponibilidade
(`ResolvePriceForVariantUseCase`, TASK-088; `GetVariantAvailabilityUseCase`,
`ProductVariantRepository`, TASK-090/091).

## Regras de negócio implementadas

- Histórico (`Order.statusHistory`) renderizado cronologicamente e somente leitura —
  nenhuma ação de edição/remoção existe na UI.
- "Repetir pedido" cria sempre um novo rascunho em `OrderStatus.draft`, nunca herdando
  status ou histórico do pedido de origem (`Order.duplicatedFromOrderId`/
  `duplicatedFromOrderNumber` são apenas informativos).
- Por item do pedido de origem: variante inexistente/inativa →
  `OrderDuplicationItemIssueType.discontinued`; indisponível
  (`VariantAvailability.acceptsQuantity == false`) → `.unavailable`; sem preço vigente
  (`ResolvePriceForVariantUseCase` sem `hasPrice`) → `.priceUnavailable`. Em qualquer
  um desses casos o item **não** é copiado para o novo rascunho.
- Item revalidado com sucesso é adicionado com o preço **atual** (nunca o antigo);
  quando o preço mudou em relação ao capturado no pedido original, é reportado em
  `OrderDuplicationResult.priceChanges` para o vendedor decidir com clareza.
- Quantidade excedente ao estoque disponível não é bloqueada aqui — permanece
  responsabilidade do `OrderSubmissionValidator` (TASK-100), já reexecutado ao tentar
  enviar o novo rascunho, evitando duplicar essa regra.

## Regras Firebase implementadas

Nenhuma alteração em `firestore.rules`/Cloud Functions: a leitura de documento único
(`OrderListRepository.getById`) já é coberta pela regra existente `canReadOrder`
(`allow get, list: if canReadOrder(organizationId)`, já validada por
`firestore.rules` da TASK-102). Os dois novos campos informativos de duplicação vivem
apenas no cache local (Drift) — `submitOrder` (Cloud Function, TASK-101) constrói o
documento definitivo do pedido a partir de uma lista explícita de campos e não
persiste/propaga esses dois campos no servidor, então nenhuma alteração era
necessária ali (decisão registrada abaixo).

## Analytics implementado

- `order_history_viewed` (organização, empresa, pedido, status, quantidade de
  entradas do histórico) — disparado ao carregar o histórico com sucesso.
- `order_duplicated` (organização, empresa, pedido de origem, novo pedido, itens,
  quantidade de mudanças de preço, quantidade de itens excluídos) — disparado ao
  concluir a duplicação com sucesso.

## Crashlytics implementado

Nenhum ponto novo de captura explícita de exceção foi necessário: os fluxos usam o
padrão `AppResult`/`Failure` já estabelecido (erros tratados e propagados como estado,
nunca exceções não capturadas).

## Impacto offline

O novo rascunho criado por "Repetir pedido" segue exatamente o mesmo fluxo 100% local
já usado pela criação de rascunho (TASK-096/097): persistido via `OrderDraftRepository`
(Drift), sem qualquer chamada de rede na criação do rascunho em si (as chamadas de
rede envolvidas — `GetOrderByIdUseCase`, `ResolvePriceForVariantUseCase`,
`GetVariantAvailabilityUseCase` — são apenas leituras de revalidação; uma falha nelas
apenas impede a duplicação daquele item específico ou do fluxo, nunca deixa um
rascunho inconsistente).

## Impacto multi-tenant

Leitura do pedido de origem (histórico e duplicação) reaproveita integralmente
`OrderVisibilityService`/`Capability.orderView` (mesma decisão de RBAC já usada pela
listagem de pedidos, TASK-102) — nenhuma nova capability foi criada. A criação do novo
rascunho continua exigindo passagem por
`EnsureCustomerInSellerPortfolioUseCase` (dentro de
`StartOrderDraftForCustomerUseCase`), então mesmo um gestor que possa *ver* o pedido de
outro vendedor só consegue duplicá-lo para si se o cliente estiver dentro de sua
própria carteira/permissão.

## Testes criados

- `get_order_by_id_use_case_test.dart`: SALES_REP só lê o próprio pedido; negado para
  pedido de outro vendedor; OWNER lê qualquer pedido da empresa; perfil sem
  `order.view` é negado sem tocar o repositório; `NotFoundFailure` para pedido
  inexistente; `ValidationFailure` para payload em branco.
- `duplicate_order_use_case_test.dart`: cria rascunho em `draft` nunca herdando
  status/histórico do original; revalida preço (mudança reportada) e disponibilidade
  (item descontinuado, indisponível e sem preço todos excluídos e reportados);
  falha de validação sem pedido com itens; propagação de falha de RBAC na leitura do
  pedido de origem.
- `order_history_bloc_test.dart`: carrega pedido com histórico contendo apenas a
  entrada de criação (estado "vazio" — sem nenhuma transição além da criação) e
  loga analytics; estado de falha ao não conseguir carregar, sem logar analytics.
- `order_status_history_timeline_test.dart`: múltiplas transições renderizadas em
  ordem cronológica, incluindo aprovação/rejeição; estado vazio.

## Comandos executados

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze --no-fatal-infos`
- `dart format --set-exit-if-changed .`
- `flutter test` (suíte completa) e reexecuções focadas em
  `test/features/orders`, `test/core/database`, `test/core/analytics`.

## Resultado do formatter

`Formatted 1696 files (0 changed)` na execução final — sem pendências de formatação.

## Resultado do analyzer

`3 issues found` — todos `info`, pré-existentes e não relacionados a esta task
(`use_null_aware_elements` em dois datasources de orders já existentes e
`prefer_initializing_formals` em um teste já existente de TASK-097). Nenhum erro.

## Resultado dos testes

- Suíte completa (`flutter test`): `+2165: All tests passed!`
- Reexecução focada (`test/features/orders`, `test/core/database`,
  `test/core/analytics`): `+221: All tests passed!` (após corrigir os dois testes de
  `schemaVersion` que passaram a esperar 12).

## Decisões técnicas

- `duplicatedFromOrderId`/`duplicatedFromOrderNumber` foram adicionados apenas ao
  `Order` (domínio) e ao cache local Drift, **não** ao `OrderDto`/Firestore: são
  puramente informativos para a tela de rascunho local, e `submitOrder` (Cloud
  Function) já constrói o documento final a partir de uma lista explícita e fechada
  de campos — adicioná-los lá seria fora do escopo desta task e sem necessidade real
  (uma vez submetido, o pedido deixa de ser "rascunho duplicado" para virar um pedido
  definitivo, e a referência informativa já cumpriu seu papel na tela de rascunho).
- `GetOrderByIdUseCase`/`DuplicateOrderUseCase` foram deliberadamente declarados como
  `class` (não `final class`), seguindo o mesmo precedente de
  `StartOrderDraftForCustomerUseCase`/`AddItemsToOrderDraftUseCase`: casos de uso que
  compõem outro caso de uso/bloc e cujos próprios testes de consumidor precisam
  fake-implementá-los diretamente.
- `OrderStatusBadge`, `orderStatusVariant` e `orderStatusIcon` (antes privados em
  `order_list_page.dart`) foram tornados públicos para reuso exato pelo
  `OrderStatusHistoryTimeline`, evitando duplicar o mapeamento status→label/ícone/cor.
- Duplicação reutiliza os motores de preço/disponibilidade do lado cliente
  (`ResolvePriceForVariantUseCase`/`GetVariantAvailabilityUseCase`) — os mesmos já
  usados no fluxo de catálogo (TASK-097/098) — como sinal client-side; o preço/estoque
  definitivo continua sendo revalidado por `submitOrder` no envio do novo rascunho,
  sem duplicar essa autoridade aqui.
- Excesso de quantidade sobre o estoque disponível não é tratado como "issue" de
  duplicação: fica a cargo do `OrderSubmissionValidator` (TASK-100) já existente,
  evitando duplicar essa regra de negócio.

## Riscos conhecidos

- `duplicatedFromOrderId`/`duplicatedFromOrderNumber` não sobrevivem à submissão do
  pedido (não são persistidos por `submitOrder`) — a referência "duplicado de #X" só
  é visível enquanto o pedido ainda é um rascunho local. Comportamento intencional e
  documentado no código; se o negócio quiser essa referência também no pedido já
  submetido no futuro, será uma alteração adicional em `functions/src/orders/
  submit-order.ts` (fora do escopo desta task).
- A ação "Repetir pedido" não bloqueia sobre item com quantidade acima do estoque
  disponível (delega ao TASK-100); se o produto quiser um aviso *nesse momento*
  específico da duplicação, é uma extensão futura pontual.

## Pendências

Nenhuma pendência bloqueante identificada para esta task.

## Evidências

- `flutter analyze --no-fatal-infos`: 3 issues (info, pré-existentes).
- `dart format --set-exit-if-changed .`: 0 changed.
- `flutter test`: +2165 all tests passed (suíte completa, incluindo os novos
  arquivos de teste desta task).

## Commit

feat(orders): implement order history and duplication

## Push

Não realizado (autorização apenas para commit local nesta rodada).

## Hash do commit

Ver seção "Branch"/retorno da execução — preenchido após o commit real.

## Branch

main
