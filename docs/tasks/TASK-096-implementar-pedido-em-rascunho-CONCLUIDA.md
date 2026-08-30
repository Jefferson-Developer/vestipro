# TASK-096 — Concluída (2026-08-30)

## Resumo

Implementado o fluxo completo de "novo pedido" (EPIC-13): o vendedor seleciona um cliente da sua
carteira e o sistema cria e persiste imediatamente, 100% offline (Drift), um `Order` em status
`draft`, pré-preenchido com unidade, tabela de preço e condição de pagamento conforme as regras já
vigentes (TASK-027/TASK-083/TASK-084/TASK-085). Toda edição relevante (hoje, a observação/notes)
dispara autosave com debounce, tratando falha como erro recuperável e nunca silencioso. Nenhuma
etapa do fluxo (iniciar ou editar o rascunho) depende de conectividade.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, BLoC, RBAC, offline-first, testes).
- `flutter-ui-design-specialist` (tela "novo pedido": seleção de cliente reaproveitada, resumo do
  pré-preenchimento, indicador de autosave, CTA de avanço).

## Arquivos criados

- `lib/features/orders/domain/entities/order_draft_defaults.dart`
- `lib/features/orders/domain/repositories/order_draft_repository.dart`
- `lib/features/orders/domain/usecases/ensure_customer_in_seller_portfolio_use_case.dart`
- `lib/features/orders/domain/usecases/resolve_order_draft_defaults_use_case.dart`
- `lib/features/orders/domain/usecases/start_order_draft_for_customer_use_case.dart`
- `lib/features/orders/domain/usecases/save_order_draft_use_case.dart`
- `lib/features/orders/domain/usecases/get_order_draft_use_case.dart`
- `lib/features/orders/data/repositories/drift_order_draft_repository.dart`
- `lib/features/orders/presentation/bloc/order_draft_event.dart`
- `lib/features/orders/presentation/bloc/order_draft_state.dart`
- `lib/features/orders/presentation/bloc/order_draft_bloc.dart`
- `lib/features/orders/presentation/pages/order_draft_page.dart`
- `test/features/orders/domain/usecases/ensure_customer_in_seller_portfolio_use_case_test.dart`
- `test/features/orders/domain/usecases/resolve_order_draft_defaults_use_case_test.dart`
- `test/features/orders/domain/usecases/start_order_draft_for_customer_use_case_test.dart`
- `test/features/orders/presentation/bloc/order_draft_bloc_test.dart`
- `test/features/orders/presentation/bloc/order_draft_bloc_offline_test.dart`
- `test/features/orders/presentation/pages/order_draft_page_test.dart`

## Arquivos alterados

- `lib/features/orders/orders.dart` (exporta os novos contratos/use cases/BLoC/página).
- `lib/core/navigation/app_route_paths.dart` (nova `OrderDraftRoute`).
- `lib/core/navigation/app_router.dart` (novo `GoRoute` protegido por `Capability.orderCreate`).
- `lib/app/bootstrap.dart` (wiring de `orderDraftPageBuilder`).
- `lib/app/injection.config.dart` (gerado via `build_runner`: registra os novos
  repositório/use cases/BLoC).
- `docs/tasks/TASKS.md` (checkbox da TASK-096 e progresso 96/220).

## Regras implementadas

- Rascunho (`Order` em `OrderStatus.draft`) só passa a existir depois que um cliente é selecionado;
  antes disso não há nenhuma entidade persistida (`OrderDraftLoadStatus.awaitingCustomer`).
- Cliente selecionado precisa pertencer à carteira do vendedor: a UI já só lista clientes
  RBAC/carteira-escopados (reaproveitando `CustomerPortfolioPage`/`ListCustomerPortfolioUseCase`,
  TASK-051) e o domínio revalida de forma independente via
  `EnsureCustomerInSellerPortfolioUseCase` (defesa em profundidade, nunca confiando só na UI).
- Pré-preenchimento de unidade (primeira `Branch` ativa), tabela de preço (
  `ResolveApplicablePriceListsUseCase`, TASK-083) e condição de pagamento (
  `ListActivePaymentTermsUseCase`, TASK-084) reaproveita regras já existentes — nenhuma regra nova
  de precificação foi inventada. Falta de unidade/tabela/condição configurada falha alto e claro
  (nunca grava um id vazio).
- Endereço de entrega/cobrança copiado do cadastro do cliente (`CustomerAddress` primária do tipo
  shipping/billing, com fallback determinístico), confirmando o ponto de entrada que a doc de
  `OrderAddress` (TASK-095) já previa para uma task futura.
- Persistência 100% local via `OrderDraftRepository` (Drift): nenhuma chamada de rede em nenhum
  passo de criar ou editar o rascunho.
- Autosave com debounce (500ms) da observação do pedido, com estados idle/saving/saved/failure
  visíveis na tela e ação explícita de "Tentar novamente" em caso de falha (nunca silenciosa).
- Rascunho não gera nenhum efeito em estoque/reserva (nenhum código deste escopo toca
  `VariantStockBalancesTable`/reserva comercial).

## Firebase

Nenhuma regra/Cloud Function nova: todo o fluxo é local (Drift). As leituras de
Customer/Branch/PriceList/PaymentTerm/Membership/Team/PortfolioAssignment já passavam pelas mesmas
Rules existentes de outras tasks.

## Offline/Multi-tenant

- Nenhuma chamada de rede em `saveDraft`/`getDraftById`/`StartOrderDraftForCustomerUseCase` (as
  únicas chamadas são a repositórios locais/de leitura já offline-cacheados nas tasks anteriores).
- `organizationId`/`companyId` do `Order` sempre resolvidos do `Customer` real (nunca aceitos como
  string solta vinda da UI) — mesma disciplina de tenant-scoping das demais entidades do
  codebase.

## Analytics

- Reaproveitado `AnalyticsEvents.orderCreated` (já existente), disparado pelo `OrderDraftBloc` ao
  criar com sucesso o rascunho, com parâmetros técnicos apenas (organization_id, company_id,
  order_id, customer_id, status, sync_status) — nenhum dado pessoal.

## Crashlytics

Nenhum ponto de crash novo introduzido; falhas de domínio seguem o padrão `AppResult`/`Failure` já
existente (nunca lançam exceção não tratada para a UI).

## Testes criados

- `EnsureCustomerInSellerPortfolioUseCase`: 9 casos (allOrganization/none/teams/ownCustomers,
  falha de assignment, validação de campos obrigatórios).
- `ResolveOrderDraftDefaultsUseCase`: 5 casos (sucesso + 3 falhas de configuração + propagação de
  falha de branch).
- `StartOrderDraftForCustomerUseCase`: 7 casos (sucesso, fallback de endereço vazio, portfólio
  negado sem nunca carregar o cliente, empresa divergente, propagação de falhas, validação).
- `OrderDraftBloc`: 7 casos (aguardando cliente, retomada de rascunho após "restart", retomada
  rejeitada por vendedor divergente, criação + analytics, falha de permissão nunca silenciosa,
  debounce de autosave, falha de autosave recuperável via retry).
- `OrderDraftBloc` offline: 1 caso, mockando `connectivity_plus` (`ConnectivityResult.none`) e
  exercitando criação + edição do rascunho com sucesso.
- `OrderDraftPage` (widget): 5 casos (seleção de cliente reaproveitando a carteira, estado vazio,
  estado de erro da carteira, falha ao iniciar o rascunho nunca silenciosa, forbidden sem
  `order.create`).

## Comandos executados

```bash
flutter analyze
dart run build_runner build
dart format --set-exit-if-changed .
flutter test
```

## Resultado do formatter

`Formatted 1590 files (0 changed) in 4.64 seconds.` — nenhuma mudança pendente.

## Resultado do analyzer

`No issues found!` (execução completa do projeto, após todas as mudanças e após o build_runner).

## Resultado dos testes

`flutter test` completo: `+2038: All tests passed!` (nenhuma falha, nenhum teste pulado).

## Decisões técnicas

- `GetOrderDraftUseCase`, `SaveOrderDraftUseCase` e `StartOrderDraftForCustomerUseCase` foram
  declarados como `class` (não `final class`), mesmo precedente de `ListCustomerPortfolioUseCase`:
  são as três dependências diretas de `OrderDraftBloc`, e seus próprios testes de unidade já cobrem
  a composição real com repositórios fake — isso evita duplicar em cada teste de BLoC toda a cadeia
  de `MembershipRepository`/`TeamRepository`/`BranchRepository`/`PriceListRepository`/
  `PaymentTermRepository` fake só para fazer o BLoC compilar.
- Unidade (Branch) default: como não existe hoje nenhuma regra de "unidade padrão do cliente/
  vendedor" em nenhuma task anterior, foi usada a primeira `Branch` ativa da empresa (ordenada por
  nome) como fallback determinístico e auditável — documentado explicitamente no código para a
  próxima task que precisar de uma regra mais rica não reimplementar do zero.
- CTA "Adicionar produtos" foi deixado com callback opcional (`onContinueToProducts`), não wireado
  no `bootstrap.dart` ainda, porque a tela de catálogo/adição de produto ao pedido (TASK-097) não
  existe nesta rodada — evita navegação morta sem inventar uma tela provisória fora de escopo.
- Falha ao iniciar o rascunho para um cliente escolhido (ex.: fora da carteira, ou empresa sem
  tabela de preço configurada) é surfaced via `SnackBar` mantendo o seletor de cliente na tela
  (nunca silenciosa, nunca bloqueia tentar outro cliente).

## Riscos conhecidos

- O CTA "Adicionar produtos" ainda não navega para lugar nenhum além do callback opcional — só
  passa a fazer algo quando TASK-097 (adição de produtos ao pedido via catálogo) for implementada e
  o `bootstrap.dart` for atualizado para wireá-lo.
- Regra de unidade padrão (primeira Branch ativa) é um fallback deliberadamente simples; se o
  negócio quiser uma regra mais sofisticada (unidade do vendedor, unidade do cliente etc.), isso é
  um ajuste futuro em `ResolveOrderDraftDefaultsUseCase` apenas.

## Pendências

- Nenhuma pendência bloqueante para esta task. TASK-097 (adição de produtos via catálogo) é o
  próximo passo natural do fluxo e depende desta base.

## Evidências

- Saída completa do `flutter test` (2038 testes, 0 falhas) e do `flutter analyze` (0 issues)
  capturada durante a execução desta task.

## Commit

Commit local criado nesta rodada (ver hash abaixo). Push não realizado.

## Push

Não realizado — não autorizado nesta conversa.

## Hash do commit

`70e4ba5` — feat(orders): implement order draft creation flow

## Branch

main
