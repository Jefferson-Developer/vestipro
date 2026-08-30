# TASK-098 — Concluída (2026-08-30)

## Resumo

Reutiliza o componente de grade comercial `AppSizeGrid` (Design System, TASK-073/TASK-024) dentro do
fluxo de pedido, sem recriá-lo: cada card de produto na lista de itens do rascunho de pedido agora
renderiza a grade cor x tamanho do produto, com totais por cor, por tamanho e por produto sempre
visíveis durante a digitação, disponibilidade por variante indicada visualmente e navegação
tab/enter entre células preservada. Cada célula preenchida gera ou atualiza o `OrderItem`
correspondente diretamente no `OrderDraftBloc`, sem uma cópia paralela de quantidade — a grade opera
100% sobre o estado local do rascunho (offline-first).

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist` (revisão de reaproveitamento de componente/indicadores visuais)

## Arquivos criados

- `lib/features/orders/presentation/bloc/order_items_grid_cubit.dart` — resolve a "forma"
  catálogo (cores, tamanhos, disponibilidade) de um produto já no rascunho, reaproveitando os
  mesmos use cases de `ProductDetailBloc`/`CommercialSizeGridBloc`
  (`ListProductVariantsByProductUseCase`, `ListProductColorsUseCase`,
  `GetSizeGridTemplateByIdUseCase`, `GetVariantAvailabilityUseCase`).
- `lib/features/orders/presentation/bloc/order_items_grid_state.dart` — estado read-only dessa
  "forma" catálogo; nunca guarda quantidade própria (a quantidade digitada vem sempre de
  `OrderDraftState.order.items`).
- `lib/features/orders/presentation/widgets/order_items_grid.dart` — widget que conecta o
  `AppSizeGrid` (mesma instância do componente já usada por `ProductDetailPage`/
  `CommercialSizeGrid`) aos `OrderItem`s de um produto no rascunho.
- `test/features/orders/presentation/widgets/order_items_grid_test.dart` — os 4 testes obrigatórios
  da task (reaproveitamento do componente, preenchimento com totais ao vivo, perda de conexão sem
  perda de dado digitado, navegação por teclado).

## Arquivos alterados

- `lib/features/orders/presentation/bloc/order_draft_bloc.dart` — novo handler
  `_onItemVariantQuantityChanged`: atualiza a quantidade de um item já existente (casado por
  `variantId`) ou resolve preço (`ResolvePriceForVariantUseCase`, mesmo motor do TASK-097/TASK-088)
  e cria um `OrderItem` novo quando a célula preenchida é de uma variante ainda não presente no
  rascunho; nunca cria item com preço adivinhado — surge falha explícita se o preço não puder ser
  resolvido.
- `lib/features/orders/presentation/bloc/order_draft_event.dart` — novo evento
  `OrderDraftItemVariantQuantityChanged`.
- `lib/features/orders/presentation/pages/order_draft_page.dart` — a seção "Itens do pedido" agora
  agrupa os `OrderItem`s por produto e renderiza `OrderItemsGrid` para produtos já resolvidos
  (`OrderDraftState.productsById`), com fallback para as linhas simples do TASK-097 enquanto o
  produto ainda não foi resolvido (nunca bloqueia a lista nessa consulta).
- `lib/features/orders/orders.dart` — exporta os novos artefatos.
- `lib/app/bootstrap.dart` / `lib/app/injection.config.dart` — injeta `OrderItemsGridCubit` (via
  `build_runner`/`injectable`) e conecta `createOrderItemsGridCubit` ao `OrderDraftPage`.
- `test/features/orders/presentation/bloc/order_draft_bloc_test.dart` — 4 novos testes cobrindo o
  handler `OrderDraftItemVariantQuantityChanged` (atualiza item existente, cria item novo com preço
  resolvido, nunca adivinha preço, no-op ao zerar variante ausente).
- `test/features/orders/presentation/pages/order_draft_page_test.dart` — injeta
  `createOrderItemsGridCubit` no harness de teste da página.

## Arquitetura utilizada

Presentation (`OrderItemsGrid`) → `OrderItemsGridCubit` (dados de catálogo read-only) e
`OrderDraftBloc` (fonte única de verdade da quantidade digitada) → use cases de domínio já
existentes (products/pricing) → repositórios já existentes. Nenhuma regra de negócio ficou na UI;
`OrderItemsGrid`/`AppSizeGrid` apenas exibem e reportam `(variantId, quantity)` — quem decide criar
ou atualizar o `OrderItem` é o `OrderDraftBloc`.

## Regras de negócio implementadas

- Preenchimento de uma célula de variante já presente no rascunho atualiza a quantidade do
  `OrderItem` existente (casado por `variantId`), seguindo a mesma convenção "0 = remover" do
  TASK-097.
- Preenchimento de uma célula de variante ainda ausente resolve o preço via
  `ResolvePriceForVariantUseCase` (mesmo motor de precificação do catálogo) antes de criar o
  `OrderItem`; se não houver preço disponível, surge uma falha explícita (nunca preço zero/adivinhado
  silenciosamente).
- Disponibilidade por variante (pronta entrega/estoque futuro/indisponível) é apenas indicativa
  nesta tela — o bloqueio definitivo de quantidade fica para a TASK-100, conforme escopo da task.

## Regras Firebase implementadas

Nenhuma alteração de Firestore/Storage Rules ou Cloud Functions nesta task — toda a leitura de
catálogo (variantes, cores, template de grade, disponibilidade) e persistência do rascunho já
usavam datasources/regras existentes de tasks anteriores (TASK-072/TASK-090/TASK-091/TASK-096).

## Analytics implementado

Ao criar um novo `OrderItem` a partir da grade, o mesmo evento `AnalyticsEvents.productAddedToOrder`
já usado pela adição via catálogo (TASK-097) é disparado, com `source: 'order_items_grid'` para
diferenciar a origem sem duplicar o evento.

## Crashlytics implementado

Nenhuma alteração — segue o mesmo tratamento de falha (`OrderDraftState.failure`) já usado pelos
demais handlers do `OrderDraftBloc`.

## Impacto offline

A grade opera 100% sobre o estado local do rascunho: cada tecla digitada dispara
`OrderDraftItemVariantQuantityChanged`, que atualiza `OrderDraftState.order.items` em memória e
agenda o autosave (debounce) já existente — nada digitado depende de conectividade para não ser
perdido. Testado explicitamente (perda de conexão simulada mid-digitação).

## Impacto multi-tenant

A grade lê catálogo (variantes, cores, template) e disponibilidade sempre escopados por
`organizationId` do rascunho ativo, através dos mesmos use cases/repositórios já usados pelo
catálogo (nenhuma nova superfície de consulta cross-tenant introduzida).

## Testes criados

`test/features/orders/presentation/widgets/order_items_grid_test.dart`:

1. Reaproveitamento do mesmo componente `AppSizeGrid` (nunca uma grade recriada para pedidos).
2. Preenchimento de múltiplas células cor/tamanho com totais por coluna (tamanho) e total geral
   (produto) atualizados ao vivo, reportando `(variantId, quantity)` corretamente.
3. Perda de conectividade simulada durante a digitação sem perda do valor já digitado.
4. Navegação por teclado (tab/enter) entre células.

`test/features/orders/presentation/bloc/order_draft_bloc_test.dart` (4 novos casos): atualização de
item existente via grade, criação de item novo com preço resolvido, falha explícita quando não há
preço disponível, no-op ao zerar uma variante ainda ausente do rascunho.

## Comandos executados

```bash
dart format --set-exit-if-changed lib/features/orders lib/app/bootstrap.dart lib/app/injection.config.dart test/features/orders
flutter analyze lib/features/orders lib/app/bootstrap.dart lib/app/injection.config.dart test/features/orders
flutter test test/features/orders/presentation/widgets/order_items_grid_test.dart test/features/orders/presentation/bloc/order_draft_bloc_test.dart test/features/orders/presentation/pages/order_draft_page_test.dart
```

## Resultado do formatter

Sem alterações pendentes (`Formatted 58 files (0 changed)`), após corrigir a formatação dos arquivos
tocados nesta task.

## Resultado do analyzer

1 issue (info, `prefer_initializing_formals`) em `test/features/orders/domain/usecases/
add_items_to_order_draft_use_case_test.dart`, arquivo pré-existente fora do escopo desta task — sem
nenhum erro/warning nos arquivos criados/alterados por TASK-098.

## Resultado dos testes

23/23 testes passaram no conjunto combinado (`order_items_grid_test.dart` 4, `order_draft_bloc_test.dart`
14, `order_draft_page_test.dart` 5 — 4+14+5=23, valor batido com o total reportado por
`flutter test`), incluindo os 4 testes obrigatórios da grade e os 4 novos testes do handler do bloc.

## Decisões técnicas

- `OrderItemsGridCubit` é deliberadamente separado do `OrderDraftBloc`: resolve dados de catálogo
  (read-only) por produto, enquanto `OrderDraftBloc` continua sendo a única fonte de verdade da
  quantidade digitada — evita duas cópias paralelas do mesmo dado.
- Corrigido um bug real de teste (não de produção) encontrado durante a validação: o teste original
  chamava `addTearDown(cubit.close)` além do próprio `OrderItemsGrid.dispose()` já fechar o cubit que
  ele mesmo cria — esse fechamento duplicado travava a suíte de teste indefinidamente (10 min de
  timeout) sem nunca lançar um erro claro. Removido o fechamento duplicado do teste; o widget
  continua responsável por fechar seu próprio cubit, como já documentado em seu código.
- O teste de "totais ao vivo" foi ajustado para simular fielmente o contrato de componente
  controlado do `OrderItemsGrid`/`AppSizeGrid` (o total é derivado de `items`, não do texto já
  digitado no campo): um pequeno harness `_ControlledOrderItemsGrid` no próprio arquivo de teste
  realimenta a quantidade alterada em `items` antes de reconstruir a árvore, replicando exatamente o
  que `OrderDraftPage`/`OrderDraftBloc` fazem em produção.
- Testes de `OrderItemsGridCubit`/`OrderItemsGrid` passaram a usar repositórios mockados
  (`mocktail`, mesmo padrão de `order_draft_page_test.dart`) em vez dos repositórios reais baseados
  em `SharedPreferences`: acionar um plugin real dentro do `initState` de um widget, dentro do laço
  de pump fake-async do `testWidgets`, é exatamente o cenário que a própria documentação do Flutter
  reserva para `tester.runAsync()`; mockar a leitura de catálogo manteve o teste determinístico e
  rápido sem alterar o código de produção.

## Riscos conhecidos

- Bloqueio definitivo de quantidade por disponibilidade (estoque) não é feito nesta tela — está
  explicitamente delegado à TASK-100, conforme escopo da própria task.
- `OrderItemsGridCubit` refaz a consulta de catálogo (variantes/cores/template/disponibilidade) uma
  vez por produto exibido no rascunho — aceitável para o volume típico de produtos por pedido, mas
  deve ser revisitado se um rascunho vier a conter dezenas de produtos simultaneamente.

## Pendências

Nenhuma pendência de código within escopo desta task. Resumo comercial do pedido (subtotal/desconto/
frete/total) fica para TASK-099, e a validação/bloqueio de estoque para TASK-100, ambas já previstas
no backlog.

## Evidências

Ver seção "Resultado dos testes" acima; saída completa dos comandos disponível no histórico desta
sessão de execução.

## Commit

Único commit cobrindo implementação + documentação + atualização do backlog (`docs/tasks/TASKS.md`).

## Push

Não realizado nesta rodada (push não autorizado).

## Hash do commit

Ver `git log -1 --oneline` após o commit.

## Branch

main
