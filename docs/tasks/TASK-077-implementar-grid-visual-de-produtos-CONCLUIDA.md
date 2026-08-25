# TASK-077 — Concluída (2026-08-25)

## Resumo

Implementado o grid visual completo do catálogo (EPIC-10): um novo `ProductGridBloc` com
paginação por cursor sobre `ProductRepository.listCatalog` (novo método, cursor-based, nunca
carrega o catálogo inteiro em memória) e uma nova `ProductGridPage` que renderiza esse estado
através do `AppProductGrid`/`AppProductCard` do Design System já entregues pela TASK-024 —
nenhum card ou grid alternativo foi criado, exatamente como a própria TASK-076 (home do
catálogo) já havia decidido ao reaproveitar o mesmo componente para seus carrosséis.

A investigação inicial (documentada na conclusão da TASK-076) já apontava que a peça visual
central — `AppProductGrid`/`AppProductCard`/`AppProductCardSkeleton`, com aspect ratio fixo,
skeleton/fallback de imagem, swatches de cor, badges, preço "de/por" opcional, disponibilidade
e paginação "carregar mais" via `AppPagination` — já existia (TASK-024). O que faltava, e é o
que esta task entrega, é a orquestração de dados por trás dela: a query de catálogo paginada
por cursor no repositório, o BLoC que acumula páginas sem duplicar/perder itens (inclusive ao
voltar de uma tela de detalhe) e a tela que fecha esse ciclo.

Preço não é exibido nesta entrega: não existe ainda motor de precificação/tabela de preço real
(EPIC-11) e a task proíbe explicitamente valor calculado/cacheado na UI — `AppProductCardData
.priceLabel` fica `null` (sem linha de preço), o mesmo caminho que `ProductSearchPage` já usa
hoje. Disponibilidade reaproveita o mesmo `GetVariantAvailabilityUseCase`/`VariantAvailability`
que `ProductSearchPage` já usa, com o mesmo fallback (indisponibilidade desconhecida = "pronta
entrega", decisão já tomada em código existente, não uma decisão nova desta task).

## Agentes utilizados

- `flutter-senior-architect` (contrato/implementação de `ProductRepository.listCatalog` com
  cursor, entidade `ProductCatalogPage`, `ListCatalogProductsUseCase`, `ProductGridBloc` com
  `bloc_concurrency` (`restartable`/`droppable`), DI, testes de bloc/repositório/use case).
- `flutter-ui-design-specialist` (verificação de que `AppProductGrid`/`AppProductCard`
  já cobriam o escopo visual da TASK-024/TASK-076 sem necessidade de novo componente,
  `ProductGridPage` reaproveitando o mesmo grid, mapeamento de disponibilidade para o card).

## Arquivos criados

Domínio (`lib/features/products/domain`):
- `entities/product_catalog_page.dart` (+ `.freezed.dart`, gerado)

Domínio (`lib/features/catalog/domain`):
- `usecases/list_catalog_products_use_case.dart` (inclui `kProductGridPageSize`)

Apresentação (`lib/features/catalog/presentation`):
- `bloc/product_grid_event.dart`
- `bloc/product_grid_state.dart`
- `bloc/product_grid_bloc.dart`
- `pages/product_grid_page.dart`

Testes novos:
- `test/features/catalog/domain/usecases/list_catalog_products_use_case_test.dart`
- `test/features/catalog/presentation/bloc/product_grid_bloc_test.dart`
- `test/features/catalog/presentation/pages/product_grid_page_test.dart`

## Arquivos alterados

- `lib/features/products/domain/repositories/product_repository.dart`: novo método
  `listCatalog` (aditivo, cursor-based) no contrato.
- `lib/features/products/data/repositories/shared_preferences_product_repository.dart`:
  implementação de `listCatalog` (ordenação por `createdAt` desc + `id` como desempate,
  cursor por id do último item da página anterior, restart seguro se o cursor não existir
  mais, `hasMore`/`nextCursor` sempre consistentes — `nextCursor` só é preenchido quando
  `hasMore` é `true`).
- `lib/features/products/products.dart` / `lib/features/catalog/catalog.dart`: exports dos
  novos tipos/BLoC/página.
- `lib/core/analytics/analytics_events.dart`: nova constante `catalogGridViewed`
  (`catalog_grid_viewed`) — impressão do grid, disparada uma única vez por sessão de tela
  quando a primeira página tem conteúdo, mesmo padrão de `catalogHomeViewed`.
- `lib/app/injection.config.dart`: gerado por `build_runner` (DI dos novos tipos).
- 13 arquivos de teste que implementam `ProductRepository` como fake (11 em
  `test/features/products/...`, mais `test/features/catalog/catalog_test_fakes.dart` e
  `test/features/catalog/domain/usecases/get_new_arrivals_section_use_case_test.dart`):
  adicionado o novo método `listCatalog` (retorno vazio/coerente com o fake existente) para
  manter compilação após a extensão do contrato — mesmo precedente da TASK-076 com
  `listRecentlyLaunched`.
- `test/features/products/data/repositories/shared_preferences_product_repository_test.dart`:
  novo grupo `listCatalog` (ordenação, filtro de status/soft-delete, paginação por cursor sem
  duplicar/pular itens, restart com cursor inválido, escopo por empresa, lista vazia).
- `test/core/analytics/analytics_events_test.dart`: taxonomia atualizada com o novo evento.
- `docs/tasks/TASKS.md`: checkbox da TASK-077 marcado e progresso atualizado para 77/220.

## Arquitetura utilizada

Clean Architecture feature-first + BLoC, igual ao restante do projeto: `ProductGridPage` (UI)
→ `ProductGridBloc` → `ListCatalogProductsUseCase` + `GetVariantAvailabilityUseCase`
(já existente, reaproveitado de `ProductSearchBloc`) → `ProductRepository.listCatalog`
(contrato) → `SharedPreferencesProductRepository` (implementação local-first, mesmo padrão já
usado por todo o resto do `Product`). UI nunca acessa Firestore/Storage/Drift diretamente;
`ProductGridBloc` nunca decide preço/disponibilidade — apenas repassa o que a camada de
domínio retorna. `AppProductGrid`/`AppProductCard`/`AppPagination` (Design System, TASK-024)
são reaproveitados sem alteração de comportamento/visual.

## Regras de negócio implementadas

- Rolagem contínua sem duplicar ou perder produtos: cada página é *anexada* ao estado
  (`ProductGridState.products`), nunca substituída; uma segurança extra deduplica por id caso
  uma página concorrente/duplicada chegue a ser processada.
- `ProductGridNextPageRequested` usa o transformer `droppable()` do `bloc_concurrency` mais um
  guard explícito (`isLoadingMore`/`hasMore`/`status`), então uma segunda requisição de
  "carregar mais" disparada enquanto a primeira ainda está em voo é descartada, nunca refeita.
- Uma página intermediária falhando nunca apaga os produtos já exibidos: `ProductGridState
  .products` permanece intacto, só o spinner de "carregar mais" para (o usuário pode tentar de
  novo tocando no botão) — só a *primeira* página falhando leva ao estado de erro de tela
  cheia (com nada para mostrar).
- O estado (incluindo produtos já carregados) sobrevive a uma navegação para o detalhe e volta,
  desde que `ProductGridBloc` não seja recriado (é responsabilidade de quem hospeda
  `ProductGridPage`, um nível acima da rota de detalhe, mesma convenção já usada por
  `CatalogHomeBloc`/`ProductSearchBloc`).
- Preço nunca é calculado/cacheado no cliente: como a tabela de preço/motor de precificação
  (EPIC-11) ainda não existe, `priceLabel` fica sempre `null` — nenhuma linha de preço é
  exibida, em vez de simular um valor.
- Disponibilidade vem sempre de `VariantAvailability` (via `GetVariantAvailabilityUseCase`),
  nunca hardcoded; um produto sem disponibilidade resolvida cai no mesmo fallback "pronta
  entrega" que `ProductSearchPage` já usa (decisão pré-existente, não introduzida aqui).
  Nenhuma urgência falsa (ex.: "restam poucas peças") é exibida.
- `product_viewed` é disparado ao abrir o detalhe a partir do card (evento
  `ProductGridProductOpened`, com `organization_id`, `product_id` e `source: catalog_grid`); a
  navegação real continua sendo decidida por quem instancia `ProductGridPage` (TASK-078 ainda
  não existe).
- `catalog_grid_viewed` (impressão do grid) é disparado uma única vez por sessão de tela quando
  a primeira página tem conteúdo — interpretação escolhida para "evento de impressão de grid
  quando aplicável" sem depender de rastreamento de viewport por item, que exigiria escopo bem
  maior (ver "Pendências").
- RBAC/escopo: toda consulta passa `organizationId` (e `companyId` quando aplicável);
  `listCatalog` filtra por empresa ativa (produto da própria empresa ou organização-wide) e
  nunca lista produto de outra organização, mesmo padrão de `listRecentlyLaunched`.

## Regras Firebase implementadas

Nenhuma regra nova de Firestore/Storage — a nova query (`listCatalog`) usa o mesmo
`SharedPreferencesProductRepository` local-first que todo o resto do `Product` já usa (a
implementação real via Firestore/outbox ainda não existe para este agregado). Nenhuma regra
existente foi enfraquecida.

## Analytics implementado

- `catalog_grid_viewed`: uma vez por sessão de tela, quando a primeira página do grid tem
  conteúdo, com `organization_id` e `products_count`.
- `product_viewed` (evento já existente na taxonomia, reaproveitado): ao abrir o detalhe a
  partir de um card do grid, com `organization_id`, `product_id` e `source: catalog_grid`.

## Crashlytics implementado

Nenhuma instrumentação nova — falhas de repositório já convertem para `Failure`/`AppResult`
pelo fluxo central existente; nenhum `print`/exceção não tratada foi introduzido.

## Impacto offline

`SharedPreferencesProductRepository` é, por natureza, um armazenamento local (documentado no
próprio arquivo como "local store até o outbox/sync real existir" — TASK-065). Isso significa
que `ProductGridBloc`/`ProductGridPage` já funcionam sem depender de conectividade, sem
nenhuma plumbing adicional: os dados vêm sempre do armazenamento local do dispositivo. Uma
duplicidade "fonte remota vs. fonte offline" (como `ProductSearchRepository` tem, com
Firestore + índice Drift) não existe aqui porque não existe ainda uma fonte remota real para
`Product` fora dessa — construir uma dualidade online/offline simulada seria fabricar uma
infraestrutura que ainda não existe, o que a task proíbe. Quando o outbox/sync real para
`Product` existir, um indicador "dado pode estar desatualizado" (mesmo padrão de
`CatalogHomeState.isStale`) pode ser adicionado sem mudar a arquitetura do BLoC.

## Impacto multi-tenant

Toda chamada passa `organizationId` (e `companyId`, quando informado); `listCatalog` nunca
retorna produto de outra organização e aplica o mesmo filtro de escopo por empresa que
`listRecentlyLaunched` já usa (produto da empresa ativa ou compartilhado entre empresas da
mesma organização).

## Testes criados

- Repositório (`SharedPreferencesProductRepository.listCatalog`): ordenação por `createdAt`
  desc, exclusão de rascunho/inativo/soft-deleted, paginação por cursor em 3 páginas sem
  duplicar/pular itens, restart seguro quando o cursor não existe mais, escopo por
  empresa/organização, página vazia com `hasMore=false`.
- Use case (`ListCatalogProductsUseCase`): delega para o repositório com organizationId
  aparado, usa `kProductGridPageSize` como limite padrão, propaga falha do repositório.
- BLoC (`ProductGridBloc`, via `bloc_test`): primeira página com sucesso (+ `catalog_grid_viewed`
  disparado uma vez), próxima página anexada sem perder a primeira, próxima página
  duplicada/concorrente descartada (só uma chamada real ao repositório), página intermediária
  falhando preservando os itens já exibidos, lista vazia (`catalog_grid_viewed` **não**
  disparado), `product_viewed` disparado ao abrir um card.
- Página (`ProductGridPage`, widget test): primeira página renderizada + "carregar mais"
  anexando a segunda sem perder a primeira, tap em card chama `onProductSelected` e loga
  `product_viewed`, estado vazio.
- Regressão: taxonomia de `AnalyticsEvents` atualizada (novo evento, sem duplicatas); 13 fakes
  de `ProductRepository` continuam compilando com o novo método do contrato.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 1236 files (0 changed)` na execução final (formatação já havia sido aplicada aos
arquivos novos/alterados em passos anteriores).

## Resultado do analyzer

`No issues found! (ran in 12.6s)`.

## Resultado dos testes

`flutter test` (suíte completa): `All tests passed!` — `+1622` (1622 testes, 0 falhas, sem
`skip`) — 18 testes novos em relação à baseline da TASK-076 (1604).

Durante o desenvolvimento, `flutter test` pegou dois bugs reais antes do commit: (1)
`listCatalog` preenchia `nextCursor` mesmo quando `hasMore` era `false` (corrigido: `nextCursor`
só é definido quando há de fato próxima página); (2) o teste de widget tentava tocar o botão
"Carregar mais" fora da viewport de teste (corrigido com `tester.ensureVisible` antes do tap).

## Decisões técnicas

- `ProductCatalogPage` foi modelada em `lib/features/products/domain/entities/` (não em
  `catalog/`) porque é o tipo de retorno do método do `ProductRepository`
  (`features/products/domain/repositories`) — colocá-la em `catalog/` inverteria a direção de
  dependência entre as duas features (mesmo raciocínio já aplicado a `Product`/
  `VariantAvailability`, que também vivem em `products` e são reaproveitados por `catalog`).
- Cursor implementado como o `id` do último produto da página anterior, resolvido buscando sua
  posição na mesma lista ordenada (não um cursor opaco codificado): simples o suficiente para
  o armazenamento local atual, documentado como reversível/substituível quando o backend real
  existir, e com fallback seguro (reinicia da primeira página) se o cursor não for encontrado
  — nunca lança exceção para o chamador.
- Optou-se por **não** duplicar os testes visuais/responsivos/golden de `AppProductGrid`/
  `AppProductCard` (columns por breakpoint, skeleton sem layout shift, golden do card) porque
  já existem integralmente desde a TASK-024
  (`test/core/design_system/components/catalog/app_product_grid_test.dart` e
  `test/core/design_system/components/goldens/design_system_catalog_golden_test.dart`) e esta
  task não alterou esse componente — duplicá-los violaria a regra "não duplicar" do `AGENTS.md`
  sem agregar cobertura real.
- `catalog_grid_viewed` foi a interpretação escolhida para "evento de impressão de grid quando
  aplicável": uma impressão de tela (mesmo padrão de `catalogHomeViewed`), não uma impressão
  por card individual com rastreamento de viewport — que exigiria infraestrutura de
  visibilidade por item fora do escopo desta task e não pedida explicitamente no "Escopo
  técnico" da task (que só menciona "evento de impressão de grid quando aplicável", sem
  detalhar granularidade).
- Nenhuma rota foi registrada em `AppRouter`: mesmo precedente de `CatalogHomePage`/
  `ProductSearchPage` (nenhuma página de catálogo/produto está integrada ainda); fica para uma
  task de shell/navegação dedicada.

## Riscos conhecidos

- Sem preço na UI até o motor de precificação/tabela de preço (EPIC-11) existir — comportamento
  intencional, não uma lacuna de implementação.
- `catalog_grid_viewed` é uma impressão por tela, não por item — se uma métrica de impressão
  por card vier a ser exigida no futuro, é um evento adicional, não uma migração deste.
- `ProductGridPage` não está registrada no `AppRouter`, mesmo padrão de outras páginas de
  catálogo/produto já concluídas; precisa de uma task de navegação para ficar acessível fim a
  fim no app.

## Pendências

- Implementar preço no card quando EPIC-11 (tabela de preço/motor de precificação) existir —
  plugar o valor formatado em `AppProductCardData.priceLabel`/`previousPriceLabel`, sem mudar o
  Design System.
- Indicador "dado pode estar desatualizado" (mesmo padrão de `CatalogHomeState.isStale`) quando
  um outbox/sync real para `Product` existir (hoje o repositório é puramente local, então não
  há "dado desatualizado" para sinalizar).
- Golden tests de `ProductGridPage` (tela completa, não o `AppProductCard` isolado, já coberto
  desde a TASK-024) podem ser adicionados quando a suíte de goldens do projeto crescer para
  telas inteiras — hoje os goldens do projeto cobrem apenas componentes do Design System.
- Integração de `ProductGridPage` ao `AppRouter` (nenhuma página de catálogo/produto está
  integrada ainda) e ligação real com home (TASK-076, link "ver tudo"), busca, coleção,
  campanha e favoritos (TASK-079) — esta task entrega o BLoC/tela reutilizável, mas cada
  chamador concreto ainda precisa ser fiado.

## Evidências

- `flutter analyze`: `No issues found!`
- `flutter test`: `All tests passed!` (1622 testes).
- `dart format --set-exit-if-changed .`: `Formatted 1236 files (0 changed)`.

## Commit

Ver seção "Commit" da resposta final — mensagem real do `git commit`, nunca inventada.

## Push

Não realizado nesta rodada (não autorizado).

## Hash do commit

Ver seção "Commit" da resposta final — hash real do `git commit`, nunca inventado.

## Branch

main
