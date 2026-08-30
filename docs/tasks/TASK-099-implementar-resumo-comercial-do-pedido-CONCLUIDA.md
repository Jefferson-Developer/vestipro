# TASK-099 — Concluída (2026-08-30)

## Resumo

Implementado o resumo comercial oficial do pedido em elaboração (EPIC-13): subtotal, desconto,
acréscimo, frete e total sempre resolvidos pelo motor de precificação server-side (`calculatePricing`,
Cloud Function idempotente da TASK-088), nunca recalculados na interface. O rascunho de pedido
(`OrderDraftPage`, TASK-096/097/098) ganhou um card "Resumo comercial" novo, que trata os estados de
recalculando (sem travar a edição do restante do pedido), sucesso, offline (estimativa local
claramente não confirmada) e erro, e sinaliza — nunca esconde — um desconto acima do limite do perfil
do vendedor (`approvalRequired`) ou bloqueado (`blocked`).

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/features/orders/domain/entities/order_pricing_summary.dart` — `OrderPricingSummary`,
  `OrderPricingItemSummary`, `OrderPricingAppliedDiscount`, `OrderPricingDiscountOrigin`,
  `OrderPricingItemValidationStatus`.
- `lib/features/orders/domain/entities/order_pricing_item_request.dart` — `OrderPricingItemRequest`
  (item traduzido para o payload do `calculatePricing`).
- `lib/features/orders/domain/repositories/order_pricing_repository.dart` — contrato
  `OrderPricingRepository`.
- `lib/features/orders/domain/usecases/get_order_pricing_summary_use_case.dart` —
  `GetOrderPricingSummaryUseCase` (resolve o segmento do cliente via `GetCustomerByIdUseCase`, monta o
  payload a partir de `Order`/`OrderItem` e chama o motor de precificação).
- `lib/features/orders/data/dtos/order_pricing_summary_dto.dart` — DTOs de resposta do callable
  (`OrderPricingSummaryDto`, `OrderPricingSummaryItemDto`, `OrderPricingAppliedDiscountDto`).
- `lib/features/orders/data/mappers/order_pricing_mapper.dart` — `OrderPricingMapper` (DTO → entidade).
- `lib/features/orders/data/datasources/order_pricing_data_source.dart` — contrato
  `OrderPricingDataSource`.
- `lib/features/orders/data/datasources/cloud_functions_order_pricing_data_source.dart` —
  `CloudFunctionsOrderPricingDataSource` (chama `calculatePricing` via `CloudFunctionsService`).
- `lib/features/orders/data/repositories/order_pricing_repository_impl.dart` —
  `OrderPricingRepositoryImpl` (converte exceções em `AppResult`/`Failure`).
- `lib/features/orders/presentation/bloc/order_pricing_summary_state.dart` —
  `OrderPricingSummaryState`/`OrderPricingSummaryStatus`.
- `lib/features/orders/presentation/bloc/order_pricing_summary_cubit.dart` —
  `OrderPricingSummaryCubit`.
- `lib/features/orders/presentation/widgets/order_pricing_summary_section.dart` —
  `OrderPricingSummarySection` (debounce, estados de UI, mensagens de offline/erro/aprovação).
- `lib/core/design_system/components/cards/app_commercial_summary_card.dart` — novo componente de
  Design System `AppCommercialSummaryCard`/`AppCommercialSummaryLine`.
- `test/features/orders/domain/usecases/get_order_pricing_summary_use_case_test.dart`.
- `test/features/orders/presentation/widgets/order_pricing_summary_section_test.dart`.
- `docs/tasks/TASK-099-implementar-resumo-comercial-do-pedido-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `lib/features/orders/presentation/pages/order_draft_page.dart` — nova seção
  `OrderPricingSummarySection` renderizada abaixo da lista de itens, novo parâmetro obrigatório
  `createOrderPricingSummaryCubit`.
- `lib/features/orders/orders.dart` — exporta as novas entidades/contratos/casos de uso/bloc/widget/DTO
  do resumo comercial.
- `lib/core/design_system/components/components.dart` — exporta `AppCommercialSummaryCard`.
- `lib/app/bootstrap.dart` — injeta `createOrderPricingSummaryCubit` na rota do rascunho de pedido.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registro DI das novas classes
  `@injectable`/`@LazySingleton`).
- `test/features/orders/presentation/pages/order_draft_page_test.dart` — adiciona o novo parâmetro
  obrigatório `createOrderPricingSummaryCubit` às pumps existentes (mocks/fakes; nenhum item no
  pedido dos testes existentes, então o card nunca chega a chamar o motor de precificação neles).
- `docs/tasks/TASKS.md` — marca TASK-099 como concluída e atualiza progresso para 99/220.

## Arquitetura utilizada

Clean Architecture feature-first, seguindo exatamente o precedente já usado por
`CatalogShareLookupRepositoryImpl`/`CloudFunctionsCatalogShareLookupDataSource`:
`OrderPricingSummarySection` (presentation) → `OrderPricingSummaryCubit` (BLoC/Cubit) →
`GetOrderPricingSummaryUseCase` (domain) → `OrderPricingRepository` (contrato) →
`OrderPricingRepositoryImpl` (data) → `CloudFunctionsOrderPricingDataSource` → `CloudFunctionsService`
→ Cloud Function `calculatePricing` (TASK-088, já existente, não alterada). A UI nunca acessa
Firestore/Cloud Functions diretamente; todo cálculo comercial (desconto, acréscimo, total) vem
exclusivamente da resposta do motor de precificação — a `Order.itemsSubtotal` que a lista de itens já
mostrava (TASK-097/098) continua sendo apenas uma estimativa local provisória, nunca o valor oficial.

## Regras de negócio implementadas

- O resumo comercial nunca calcula desconto/acréscimo/frete/total por conta própria: todo valor vem
  exatamente do que `calculatePricing` retornou (`OrderPricingSummary`), sem arredondamento nem lógica
  divergente client-side.
- `GetOrderPricingSummaryUseCase` resolve o segmento do cliente (`Customer.segment`) via
  `GetCustomerByIdUseCase` a cada chamada (nunca reaproveita um segmento potencialmente desatualizado),
  falha explicitamente (sem calcular nada) quando o pedido não tem itens, e propaga qualquer falha de
  resolução do cliente sem tentar adivinhar um segmento padrão.
- A chave de idempotência enviada ao `calculatePricing` é derivada do conteúdo da requisição
  (tabela de preço, condição de pagamento, frete, segmento e cada item) — determinística para o mesmo
  conteúdo (reaproveita o cache do lado servidor) e sempre diferente quando qualquer item muda,
  evitando o conflito `already-exists` que uma chave fixa por pedido causaria a cada edição.
- Desconto por item manual sempre enviado como `0%` por enquanto: o rascunho de pedido ainda não tem
  entrada de desconto manual por item (nenhuma task anterior implementou isso) — documentado
  explicitamente no código, nunca inferido de `OrderItem.discountAmount` (unidade diferente).
- `approvalRequired`/`blocked` retornados pelo motor de precificação são sempre sinalizados no resumo
  (badge de status), nunca escondidos.
- Estado offline mostra um total estimado puramente local (`Order.itemsSubtotal` + `shippingAmount`,
  sem desconto/acréscimo) e deixa explícito, em texto, que ele ainda não foi confirmado pelo motor de
  precificação.

## Regras Firebase implementadas

Nenhuma nova regra/Function criada nesta task — reaproveita integralmente a Cloud Function
`calculatePricing` já existente (TASK-088, `functions/src/pricing/calculate-pricing.ts`), incluindo seu
próprio controle de idempotência, RBAC (leitura de `roleName` do membership do usuário autenticado no
servidor) e escopo por `companyId`/`organizationId` — nenhuma autorização nova depende do cliente.

## Analytics implementado

Nenhum evento de analytics novo nesta task (fora do escopo explícito de TASK-099; os eventos de
pedido/adição de produto já existentes — TASK-096/097 — não foram alterados).

## Crashlytics implementado

Nenhuma instrumentação nova de Crashlytics nesta task — falhas seguem o mesmo caminho já padronizado
(`AppException` → `Failure` → `OrderPricingSummaryState.failure`, nunca engolida silenciosamente).

## Impacto offline

Quando o motor de precificação não pode ser alcançado (`ConnectivityFailure`), o card mostra um total
estimado local (subtotal + frete, sem desconto/acréscimo) com um badge "Estimativa não confirmada" e
uma nota explícita de que o valor pode mudar quando o pedido sincronizar — nunca apresentado como valor
definitivo. O rascunho em si continua 100% funcional offline (edição de itens/quantidades não depende
desta chamada, que roda em um Cubit isolado e nunca bloqueia o restante da tela).

## Impacto multi-tenant

Toda chamada ao `calculatePricing` inclui `organizationId`/`companyId` do próprio `Order` (nunca de um
campo de formulário), e a Cloud Function já existente revalida `organizationId`/`companyId`/`roleName`
no servidor (membership do usuário autenticado) antes de calcular qualquer preço — nada de novo
confiado ao cliente como autorização.

## Testes criados

- `test/features/orders/domain/usecases/get_order_pricing_summary_use_case_test.dart`: sucesso com o
  payload correto enviado ao repositório, reaproveitamento/variação determinística da chave de
  idempotência, falha de rede/conectividade propagada, resposta com `approvalRequired: true` nunca
  escondida, guarda de pedido sem itens (sem chamar o repositório), e propagação de falha ao resolver o
  cliente.
- `test/features/orders/presentation/widgets/order_pricing_summary_section_test.dart`: os valores
  exibidos batem exatamente com o mock do motor de precificação (sem cálculo divergente), desconto
  acima do limite sinalizado, o card mantém o último resumo confirmado visível enquanto uma nova
  chamada está pendente ("recalculando" nunca bloqueia/zera a tela), o estado offline cai para a
  estimativa local claramente rotulada, e um teste de acessibilidade confirma que os valores/status são
  anunciados por leitor de tela (via `Semantics`/`bySemanticsLabel`).
- `test/features/orders/presentation/pages/order_draft_page_test.dart` foi atualizado (não criado) para
  o novo parâmetro obrigatório.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/orders/domain/usecases/get_order_pricing_summary_use_case_test.dart
flutter test test/features/orders/presentation/widgets/order_pricing_summary_section_test.dart
flutter test test/features/orders/presentation/pages/order_draft_page_test.dart
flutter test test/features/orders test/core/design_system
flutter test
```

## Resultado do formatter

`Formatted 1622 files (0 changed) in 4.23 seconds.` — sem alterações pendentes de formatação (o
comando anterior formatou 4 arquivos novos automaticamente; a segunda execução confirmou 0 mudanças).

## Resultado do analyzer

`1 issue found` — apenas um `info` pré-existente e não relacionado (`prefer_initializing_formals` em
`test/features/orders/domain/usecases/add_items_to_order_draft_use_case_test.dart:193:8`, arquivo não
tocado nesta task). Nenhum erro/warning nos arquivos criados/alterados.

## Resultado dos testes

- `get_order_pricing_summary_use_case_test.dart`: 6/6 passaram.
- `order_pricing_summary_section_test.dart`: 5/5 passaram.
- `order_draft_page_test.dart`: 5/5 passaram (sem regressão).
- `test/features/orders` + `test/core/design_system` (suíte combinada): 334/334 passaram.
- `flutter test` (suíte completa do projeto): 2078/2078 passaram — `All tests passed!`.

## Decisões técnicas

- O segmento do cliente (`customerSegment`, exigido pelo `calculatePricing` para casar campanhas) é
  resolvido dentro do próprio `GetOrderPricingSummaryUseCase` via `GetCustomerByIdUseCase`, em vez de
  exigir que quem chama o caso de uso já carregue um `Customer` em memória — evita depender de um
  segmento potencialmente desatualizado guardado em algum estado de tela.
- `categoryId` por item é deliberadamente sempre `null` no payload enviado (campanhas por categoria
  simplesmente não casam com estes itens ainda): buscar o `Product` de cada item só para esse campo
  ficou fora do escopo desta task — documentado no código e listado abaixo em "Pendências".
- Chave de idempotência derivada do conteúdo (não do `order.id` isolado), para nunca colidir
  (`already-exists`) quando o vendedor edita quantidades entre uma recalculação e outra.
- `AppCommercialSummaryCard` foi criado como componente novo do Design System (não havia um
  equivalente): os componentes existentes (`PricingAdjustmentOriginCard`/`DiscountValidationBanner`,
  ambos em `features/pricing`) operam sobre entidades client-side de validação de desconto (TASK-086),
  não sobre a resposta real do `calculatePricing` para um pedido — reaproveitá-los teria acoplado o
  resumo do pedido a um modelo de dados errado.
- `excludeSemantics: true` adicionado em cada linha do `AppCommercialSummaryCard` para que o leitor de
  tela anuncie um único texto combinado ("Subtotal: R$ 100,00") em vez de duplicar rótulo e valor como
  nós de semântica separados.

## Riscos conhecidos

- `taxAmount`/impostos: o motor de precificação (`calculatePricingEngine`,
  `functions/src/pricing/pricing-engine.ts`) ainda não calcula impostos — o resumo comercial
  simplesmente não exibe uma linha de imposto até uma task futura estender o motor de precificação.
  Isso é uma limitação do backend já existente (TASK-088), não introduzida por esta task.
- Desconto manual por item ainda não é editável na tela de rascunho de pedido — todo item é enviado com
  `manualDiscountPercent: 0`. Quando uma task futura adicionar essa edição, ela precisa alimentar esse
  campo real (nunca inferir de `OrderItem.discountAmount`).
- Campanhas restritas por categoria de produto não casam com os itens deste resumo (apenas
  produto/coleção): `categoryId` por item não é resolvido aqui (ver "Decisões técnicas").

## Pendências

- Resolver `categoryId` por item (via `Product` já cacheado em `OrderDraftState.productsById` ou
  equivalente) para permitir que campanhas restritas por categoria também sejam consideradas no resumo.
- Adicionar uma linha de imposto ao resumo assim que o motor de precificação server-side suportar
  cálculo de impostos.
- Wiring de desconto manual por item na tela de rascunho (fora do escopo de TASK-099).

## Evidências

- `flutter test` completo: `2078` testes, `All tests passed!`.
- `flutter analyze`: `1 issue found` (pré-existente, não relacionado).
- `dart format --set-exit-if-changed .`: `0 changed`.

## Commit

Commit único cobrindo implementação + documentação (`docs/tasks/TASKS.md` atualizado no mesmo commit).

## Push

Não realizado — push não autorizado nesta rodada (instrução explícita da tarefa).

## Hash do commit

Ver saída de `git log -1 --oneline` reportada na resposta final ao usuário.

## Branch

`main`
