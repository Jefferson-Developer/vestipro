# TASK-137 — Implementar dashboard de produtos (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

Product Dashboard completo, seguindo a arquitetura já estabelecida pelas TASK-133/134/135/136
(camada de agregação server-side, feature-first + Clean Architecture, BLoC, Design System,
navegação tipada):

### Domínio (`lib/features/dashboards/domain/`)

- `value_objects/product_dashboard_sort_field.dart` — `quantitySold | revenue | mix | discount`.
- `entities/product_dashboard_filters.dart` — empresa, mês, coleção/categoria (opcionais), sort;
  serialização de query params para deep link, no mesmo padrão de `CustomerDashboardFilters`/
  `SalesDashboardFilters`.
- `entities/product_dashboard_ranking_row.dart` — uma linha do ranking por produto: quantidade
  vendida, faturamento bruto/líquido, desconto, `mixPercentage`, `discountPercentage` (getter) e
  `conversionRate` (sempre `null`, documentado — ver "Lacunas" abaixo).
- `entities/product_dashboard_snapshot.dart` — KPIs: quantidade vendida, produtos ativos no mix,
  desconto médio, margem (sempre não calculada).
- `usecases/load_product_dashboard_ranking_use_case.dart` — lê `productMonthly`
  (`AggregationRepository`, TASK-133), aplica a restrição de "apenas produtos vigentes na tabela
  de preço ativa", filtra por coleção/categoria, calcula `mixPercentage` e ordena.
- `usecases/build_product_dashboard_snapshot_use_case.dart` — deriva os 4 KPIs de forma síncrona
  e pura a partir das mesmas linhas já buscadas pelo use case acima (nunca uma segunda leitura, e
  nunca um KPI que possa divergir do ranking exibido).

### Apresentação (`lib/features/dashboards/presentation/`)

- `bloc/product_dashboard_bloc.dart` + `product_dashboard_event.dart` + `product_dashboard_state.dart`
  — resolve RBAC (`ExecutiveDashboardVisibilityService`, reaproveitado verbatim), carrega
  empresas/coleções/categorias para os filtros, carrega ranking + deriva snapshot, pagina o
  ranking (20 por página) e enriquece apenas as linhas visíveis com giro de estoque (TASK-094) e
  imagem do produto (bounded, nunca um fan-out sobre as 500 linhas do read bruto).
- `pages/product_dashboard_page.dart` — `AppAdminPageLayout` + filtros (`AppDropdown` de
  empresa/coleção/categoria + navegação de mês) + KPI cards (`AppKpiCard`) + tabela
  (`AppDataTable`, responsiva mobile/desktop, com miniatura do produto via `CachedNetworkImage`) +
  drill-down por linha.

### Navegação

- `ProductDashboardRoute` (`/org/:orgId/companies/:companyId/dashboards/products`), protegida por
  `Capability.reportViewSensitive` — mesma capability de todo dashboard do EPIC-17.
- `ProductDetailRoute` (`/org/:orgId/products/:productId`) — rota nova, standalone e somente
  leitura, reaproveitando `ProductDetailPage`/`ProductDetailBloc` (TASK-078) fora do fluxo de
  pedido (que hoje só existe amarrado a um `draftId`, via `OrderProductDetailRoute`). Sem gate de
  `Capability` própria, no mesmo precedente de `CatalogHomeRoute`/`CatalogBrowseRoute` (catálogo é
  navegável por qualquer usuário autenticado).
- Wiring em `app_router.dart`/`bootstrap.dart` seguindo exatamente o padrão de
  `CustomerDashboardRoute`/`CustomerDetailRoute`.
- Evento de analytics `dashboard_viewed` com `dashboard_type: 'product'`.

## Decisões e lacunas documentadas

1. **Filtro por cor/tamanho — não implementado.** `productMonthly` (TASK-133) agrega por produto,
   sem dimensão de variante/cor/tamanho. Construir esse filtro exigiria uma nova dimensão de
   agregação server-side, fora do escopo desta task. A UI informa isso explicitamente ao usuário
   em vez de simular um filtro que não filtraria nada.
2. **Ranking por "maior conversão" — não implementado.** Nenhum pipeline de eventos/agregação no
   código-fonte rastreia visualizações de produto ou adições ao pedido por período
   (`AnalyticsEvents` só grava no Firebase Analytics, um sink de exportação que a camada de
   domínio nunca lê de volta). Calcular conversão a partir de um proxy seria "calculado ad-hoc no
   cliente", proibido pelas próprias regras da task. `ProductDashboardRankingRow.conversionRate`
   fica sempre `null`, documentado no código e exposto na UI como indisponível — mesma abordagem já
   aceita em TASK-134/135/136 para `newCustomers`/`reactivatedCustomers`/`margin`/
   `productsPerOrder`.
3. **Margem — sempre não calculada.** Nenhum campo de custo existe em `Product` nem em nenhuma
   dimensão de agregação da TASK-133. Mesma lacuna documentada em `SalesDashboardSnapshot.margin`
   ("Sem dado de custo/margem disponível"), reaproveitada aqui sem reinvenção.
4. **"Mix médio" — duas leituras, ambas honestas e calculáveis:**
   - por linha do ranking: `mixPercentage` = participação do produto no faturamento líquido total
     do período (calculado antes do filtro de coleção/categoria, para nunca se re-normalizar
     silenciosamente para 100% ao aplicar um filtro);
   - no KPI card: "produtos ativos no mix" = quantidade de produtos distintos com venda no
     período (amplitude de sortimento comercializado).
5. **Restrição por tabela de preço ativa (regra de negócio da task) — best-effort.** O ranking e os
   KPIs são restritos aos `productId` presentes em ao menos uma tabela de preço ativa e
   company-wide da empresa (`ResolveApplicablePriceListsUseCase`, sem canal/segmento de cliente —
   o conjunto mais amplo "vigente para a empresa"). Quando nenhuma tabela de preço está
   configurada ainda (organização nova) ou a leitura falha, a restrição é **pulada** em vez de
   zerar o dashboard inteiro — mesmo precedente de leitura secundária "best-effort" já usado pelos
   outros dashboards do EPIC-17 para dados de comparação de período.
6. **Giro de estoque (TASK-094) — mesma fonte da regra de insight TASK-128, com uma lacuna
   pré-existente documentada.** O dashboard lê giro por produto via `GetStockTurnoverMetricsUseCase`
   → `StockTurnoverRepository`, o único ponto de leitura de giro por produto que está realmente
   conectado a um repositório concreto no código-fonte hoje. A regra
   `HighStockLowTurnoverInsightRule` (TASK-128), por sua vez, lê de
   `InsightStockPositionSnapshot.turnoverIndex`, um campo de um `InsightDataset` cujo builder de
   produção (o código que o popularia a partir de `StockTurnoverRepository`) **não existe em
   nenhum lugar do código-fonte** — uma lacuna pré-existente, de fora do escopo desta task, que já
   impede qualquer comparação em runtime entre os dois hoje. Este dashboard documenta
   explicitamente que lê a única fonte canônica de giro (TASK-094) realmente implementada, para
   que os dois leitores nunca precisem divergir quando aquele builder for implementado em uma task
   futura.
7. **Drill-down do ranking (TASK-078).** Não existia nenhuma rota de detalhe de produto fora do
   fluxo de pedido (`OrderProductDetailRoute` exige um `draftId`). Foi criada uma nova rota
   standalone e somente leitura, `ProductDetailRoute`, reaproveitando o mesmo
   `ProductDetailPage`/`ProductDetailBloc` já existentes (sem alterar nada neles), com
   `onAddToOrder: null`.
8. **Enriquecimento de giro/imagem por página, não pelo read bruto.** `AggregationRepository
   .listByPeriod` já traz até 500 linhas por leitura (mesmo limite de outros dashboards). Buscar
   giro/imagem para as 500 seria um fan-out não limitado; o bloc só enriquece a janela atualmente
   visível (20 por página, crescendo em "carregar mais"), preservando o que já foi carregado.

## Testes

- `test/features/dashboards/domain/usecases/load_product_dashboard_ranking_use_case_test.dart` —
  validação, mapeamento de snapshot→linha, mix/desconto, filtro por coleção/categoria (incluindo
  que o mix permanece relativo ao total não filtrado), ordenação, ausência de dados no período,
  propagação de falha, e a restrição por tabela de preço ativa (inclui, exclui produto sem preço
  vigente, nunca zera o ranking quando não há tabela configurada ou a leitura falha).
- `test/features/dashboards/domain/usecases/build_product_dashboard_snapshot_use_case_test.dart` —
  KPIs zerados (nunca "não calculado") em período vazio, margem sempre não calculada, soma de
  quantidade, contagem de produtos ativos, desconto médio ponderado por faturamento (não uma média
  aritmética simples).
- `test/features/dashboards/presentation/bloc/product_dashboard_bloc_test.dart` — bloqueio RBAC
  (forbidden), fluxo completo até `ready` com snapshot+ranking e evento `dashboard_viewed`,
  paginação do ranking preservando linhas já carregadas, falha ao carregar empresas, e
  enriquecimento de giro lendo o `StockTurnoverRepository` com o escopo `product` correto (a
  mesma fonte canônica da TASK-094 documentada acima).

Todos os testes novos passam (`flutter test test/features/dashboards` — 144 testes, incluindo os
já existentes de TASK-133/134/135/136 — todos verdes).

## Validações executadas

- `flutter pub run build_runner build` — gerou os registros de injeção
  (`ProductDashboardBloc`, `LoadProductDashboardRankingUseCase`,
  `BuildProductDashboardSnapshotUseCase`) em `lib/app/injection.config.dart`. Os avisos
  "Missing dependencies" impressos pelo `injectable_generator` (`ProductDetailBloc`,
  `ProductGridBloc`, `OrderDraftBloc`, `ConnectivityPlusService`, `ImageUploadCompressor`,
  `ConflictResolutionService`, `SyncEngine`) são **pré-existentes**, não relacionados a esta task
  (confirmado rodando o mesmo comando na branch antes das alterações, e conferindo que todas essas
  classes já têm factory registrada em `injection.config.dart`) — nenhuma delas foi tocada aqui.
- `dart format` nos arquivos criados/alterados desta task.
- `flutter analyze` (projeto inteiro) — 0 issues (apenas 4 infos estilísticos pré-existentes,
  idênticos ao padrão já aceito em `load_customer_dashboard_ranking_use_case_test.dart`).
- `flutter test test/features/dashboards` — 144 testes, todos passando.

## Pendências / riscos para tasks futuras

- Rastreamento de visualização de produto/adição ao pedido por período, para viabilizar
  "produtos com maior conversão" sem violar a regra de "nunca calculado ad-hoc no cliente".
- Nova dimensão de agregação server-side por variante (cor/tamanho), para viabilizar o filtro que
  a task original pedia.
- Builder de produção do `InsightDataset.stockPositionSnapshots` (lacuna pré-existente, já
  bloqueava qualquer comparação real entre TASK-128 e TASK-094 antes desta task).
- Campo de custo em `Product`/motor de precificação, para viabilizar margem em qualquer dashboard
  do EPIC-17 (mesma lacuna já documentada desde TASK-135).
