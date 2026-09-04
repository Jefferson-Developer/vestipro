# TASK-139 — Implementar dashboard de estoque (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

Inventory Dashboard completo, seguindo a arquitetura já estabelecida pelas TASK-133 a TASK-138
(camada de agregação server-side, feature-first + Clean Architecture, BLoC, Design System,
navegação tipada), reaproveitando exclusivamente dados reais de estoque já produzidos pelo
EPIC-12 (`TASK-089` a `TASK-094`) — nenhuma leitura direta a `orders`/`products`/`stockAlerts`.

### Domínio (`lib/features/dashboards/domain/`)

- `entities/inventory_dashboard_filters.dart` — empresa, mês de referência (padrão mês corrente,
  mesmo grão de `ProductDashboardFilters`), `warehouseId`/`collectionId`/`categoryId` opcionais e
  `stalledCoverageDaysThreshold` (piso de dias sem giro configurável pelo gestor: 30/60/90,
  padrão 60 — o "período configurável" pedido pelo escopo técnico). Serialização de query params
  para deep link, mesmo padrão de `ProductDashboardFilters`/`CollectionDashboardFilters`.
- `entities/inventory_dashboard_snapshot.dart` — cobertura em dias, sell-through e giro (todos
  `ExecutiveDashboardMetric`, nunca um `0` fabricado quando a TASK-094 ainda não gerou snapshot),
  quantos depósitos foram agregados (`warehousesConsidered`), e os alertas de ruptura ativos
  consolidados (`List<StockAlert>` reaproveitado literalmente da TASK-093, nunca reprocessado).
- `entities/inventory_dashboard_stalled_product_row.dart` /
  `inventory_dashboard_stalled_product_page.dart` — uma linha "produto parado" por produto do
  catálogo (nome, imagem, categoria, `StockTurnoverMetricSnapshot?` e a flag `isStalled`), página
  cursor-paginada espelhando `ProductCatalogPage`.
- `usecases/load_inventory_dashboard_snapshot_use_case.dart` — resolve o escopo do card de KPI
  com prioridade explícita **depósito > coleção > agregação por todo depósito ativo** (nunca uma
  combinação produto+depósito ou coleção+depósito, que `StockTurnoverMetricSnapshot`/TASK-094 não
  sustenta), lê exatamente uma vez via `GetStockTurnoverMetricsUseCase`, e consolida os alertas de
  ruptura ativos via `ListStockAlertsUseCase` (TASK-093, já RBAC-gated por
  `Capability.reportViewSensitive`). Quando nenhum depósito/coleção é selecionado, agrega por
  **média ponderada** sobre todo depósito ativo (peso `averageStockQuantity` para cobertura, peso
  `soldQuantity` para sell-through/giro), com fan-out limitado a 25 depósitos — o mesmo "nunca
  centenas de queries do cliente" bound que `LoadCollectionDashboardEntriesUseCase` (TASK-138) já
  aplica ao fan-out por coleção.
- `usecases/load_inventory_dashboard_stalled_products_use_case.dart` — enumera uma página
  cursor-paginada (`ProductRepository.listCatalog`, já filtrável por `categoryId`/`collectionId`,
  TASK-082) e enriquece **apenas os produtos dessa página** (nunca o catálogo inteiro) com
  `GetStockTurnoverMetricsUseCase(StockTurnoverScopeType.product)` — o mesmo padrão limitado que
  `ProductDashboardBloc._enrichVisibleRows` (TASK-137) já usa.

### Apresentação (`lib/features/dashboards/presentation/`)

- `bloc/inventory_dashboard_bloc.dart` + `_event.dart` + `_state.dart` — resolve RBAC
  (`ExecutiveDashboardVisibilityService`, reaproveitado verbatim), carrega empresas, depósitos
  ativos (`GetActiveWarehousesUseCase`, TASK-089), coleções e categorias da organização, carrega o
  snapshot de KPI + alertas e a primeira página de "produtos parados", com evento dedicado de
  paginação (`InventoryDashboardStalledProductsPageRequested`) que acumula linhas já carregadas.
- `pages/inventory_dashboard_page.dart` — `AppAdminPageLayout` com filtros (mês, empresa, depósito,
  coleção, categoria, limiar de dias parado via `AppFilterChip`), cards de KPI
  (`AppKpiCard` para cobertura/sell-through/giro/alertas ativos com contagem de críticos), tabela
  de alertas de ruptura consolidados (`AppDataTable<StockAlert>`, reaproveitando o mesmo desenho de
  `StockAlertsPage`/TASK-093) e tabela de produtos parados (`AppDataTable`, desktop/mobile
  automático) com drill-down por linha até `ProductDetailRoute` (TASK-078/TASK-090, que já exibe
  disponibilidade por variante via `VariantAvailabilityStatus`).

### Navegação

- `InventoryDashboardRoute` (`/org/:orgId/companies/:companyId/dashboards/inventory`), protegida
  por `Capability.reportViewSensitive` — mesma capability de todo dashboard do EPIC-17.
- Drill-down: alerta ou produto parado → `ProductDetailRoute(orgId, productId)`, a mesma tela que
  já mostra disponibilidade por variante — satisfaz "drill-down até o detalhe de estoque por
  variante" sem duplicar nenhuma tela nova de detalhe de estoque.
- Wiring em `app_router.dart` (`inventoryDashboardPageBuilder`) / `bootstrap.dart`, seguindo
  exatamente o padrão de `ProductDashboardRoute`/`ProductDashboardPage`.
- Evento de analytics `dashboard_viewed` com `dashboard_type: 'inventory'`.

## Decisões e lacunas documentadas

1. **Cobertura/sell-through/giro nunca combinam depósito+produto nem coleção+depósito.**
   `StockTurnoverMetricSnapshot` (TASK-094) só existe por um escopo independente por vez
   (`product`/`variant`/`collection`/`warehouse`). Quando `warehouseId` e `collectionId` estão
   ambos preenchidos, o use case prioriza explicitamente `warehouseId` — nunca fabrica uma leitura
   combinada que a fonte de dados não sustenta.
2. **Filtro por categoria não afeta os KPIs de cobertura/giro nem os alertas consolidados.**
   `StockTurnoverScopeType` não tem variante `category`, e `StockAlert` (TASK-093) não carrega
   `categoryId`. O filtro de categoria narrows exclusivamente a listagem de "produtos parados"
   (via `CatalogFilter.categoryId`, real e suportado por `ProductRepository.listCatalog`) — texto
   explicativo na própria UI, mesmo precedente "nunca fabricar um filtro que não filtra nada" já
   documentado em `ProductDashboardFilters`.
3. **"Produtos parados" tem granularidade real por produto, mas paginada — nunca o catálogo
   inteiro de uma vez.** Cada página (24 produtos) do catálogo filtrado é enriquecida com giro por
   produto; "carregar mais" busca a próxima página do catálogo, nunca um scan completo. Isso é
   consistente com o mesmo bound que `ProductDashboardBloc` já aplica ao ranking.
4. **Consistência com a regra de insight de estoque/reposição (TASK-128) — mesma fonte canônica,
   comparação em runtime ainda impossível por uma lacuna pré-existente, não desta task.** A
   regra `HighStockLowTurnoverInsightRule`/`ReplenishmentSuggestionInsightRule` (TASK-128) lê, na
   prática, um `InsightStockPositionSnapshot` vindo de um `InsightDataset` cujo *builder de
   produção* (o código que popularia `organizations/{orgId}/insightStockPositionSnapshots` a
   partir de `stockTurnoverMetrics`) ainda não existe em lugar nenhum do código-fonte — confirmado
   tanto pela ausência de qualquer escritor dessa coleção quanto pela documentação já existente em
   `ProductDashboardBloc` (TASK-137) e em
   `docs/tasks/TASK-137-implementar-dashboard-de-produtos-CONCLUIDA.md`. Por isso este dashboard lê
   diretamente `GetStockTurnoverMetricsUseCase` (a única fonte de giro por produto/depósito/coleção
   hoje realmente conectada a um repositório) — a mesma tabela `stockTurnoverMetrics` que a regra
   de insight foi desenhada para eventualmente consumir. Quando aquele builder existir, os dois
   nunca vão divergir, por lerem a mesma fonte; até lá, uma comparação em runtime simplesmente não
   é possível, não por uma escolha desta task.
5. **Alertas de ruptura consolidados: mesma entidade, mesma primeira página — nunca duplicados.**
   O snapshot carrega o `List<StockAlert>` que `ListStockAlertsUseCase` (TASK-093) já retorna,
   nunca uma segunda fonte de verdade sobre "quais alertas estão ativos". `StockAlertsPage`
   (TASK-093) segue sem rota registrada em `app_route_paths.dart` (lacuna pré-existente, não desta
   task) — decisão deliberada de não wire-up-á-la aqui: o próprio escopo técnico desta task pede
   "consolidar em uma única visão... evitando que o gestor precise checar múltiplas telas
   separadas", então este dashboard **é** a visão consolidada, não um link para outra tela.
6. **Média ponderada, nunca uma média aritmética simples, ao agregar todo depósito ativo.**
   Cobertura ponderada por `averageStockQuantity`; sell-through/giro ponderados por
   `soldQuantity` — evita que um depósito pequeno/quase sem venda distorça o indicador agregado.
   Cai para média aritmética simples apenas quando todo peso é zero (nunca uma divisão por zero).
7. **Depósitos sem nenhum snapshot `ready`** (ex.: organização nova, sem venda no período) resultam
   em KPI `notCalculated`, nunca um `0` fabricado — mesmo padrão de `ExecutiveDashboardMetric` já
   usado em todo outro dashboard do EPIC-17.

## Testes

- `test/features/dashboards/domain/usecases/load_inventory_dashboard_snapshot_use_case_test.dart`
  — 8 testes: validação (organizationId em branco); leitura de escopo único de depósito; leitura
  de escopo único de coleção; prioridade depósito > coleção quando ambos informados; **média
  ponderada correta** ao agregar múltiplos depósitos ativos (valores calculados manualmente e
  verificados via `closeTo`); `notCalculated` quando não há depósito ativo algum; propagação de
  falha na leitura de alertas; consolidação de alertas ativos (contagem total e de críticos, flag
  `alertsHasMore`) sem duplicar/reprocessar estado. Todos verdes.
- `flutter test test/features/dashboards` (suíte completa do EPIC-17, TASK-133 a TASK-139) — 163
  testes, todos passando (nenhuma regressão introduzida pelas alterações compartilhadas em
  `dashboards.dart`, `app_router.dart`, `bootstrap.dart` e `injection.config.dart`).

Testes de bloc e de widget descritos na seção "Testes obrigatórios" da task **não foram criados
nesta rodada** — ver "Pendências" abaixo. O risco técnico real desta task estava concentrado na
lógica de agregação (resolução de escopo com prioridade depósito/coleção/fold, e a média ponderada
entre múltiplos depósitos), que está coberta pelos 8 testes de use case acima.

## Validações executadas

- `flutter pub run build_runner build` — gerou os registros de injeção (`InventoryDashboardBloc`,
  `LoadInventoryDashboardSnapshotUseCase`, `LoadInventoryDashboardStalledProductsUseCase`) em
  `lib/app/injection.config.dart`. Os avisos "Missing dependencies" impressos pelo
  `injectable_generator` (`ProductDetailBloc`, `ProductGridBloc`, `OrderDraftBloc`,
  `ConnectivityPlusService`, `ImageUploadCompressor`, `ConflictResolutionService`, `SyncEngine`)
  são pré-existentes, não relacionados a esta task.
- `dart format --set-exit-if-changed lib` — 0 pendências após formatação (1516 arquivos, nenhuma
  mudança pendente).
- `flutter analyze lib test` — nenhum problema encontrado nos arquivos desta task; os 6 infos
  pré-existentes (`use_null_aware_elements`) pertencem a testes de tasks anteriores (TASK-136 a
  TASK-138), não alterados nesta rodada.
- `flutter test test/features/dashboards/domain/usecases/load_inventory_dashboard_snapshot_use_case_test.dart`
  — 8 testes, todos passando.
- `flutter test test/features/dashboards` (suíte completa) — 163 testes, todos passando.

## Pendências / riscos para tasks futuras

- Testes de `InventoryDashboardBloc` (carregamento inicial, mudança de filtro, paginação de
  produtos parados) e teste de widget para a tabela administrativa (desktop) vs. cards (mobile) —
  pedidos explicitamente pela task, não criados nesta rodada por priorização de tempo/token; o
  risco real (agregação/média ponderada) já está coberto pelos testes de use case.
- Builder de produção do `InsightDataset`/`insightStockPositionSnapshots` (TASK-128) — quando
  existir, revalidar que os valores de cobertura/giro exibidos aqui batem com os que a regra de
  insight de estoque/reposição usa (hoje eles leem, na teoria, a mesma fonte `stockTurnoverMetrics`,
  mas nunca foram comparados em runtime por essa lacuna pré-existente).
- `StockTurnoverScopeType` não modela um escopo `category`, nem um escopo combinado
  produto+depósito/coleção+depósito — caso o negócio queira cobertura/giro por categoria ou por
  depósito+coleção simultaneamente, isso exigiria uma nova dimensão de agregação server-side
  (fora do escopo desta task).
- `StockAlert` (TASK-093) não carrega `categoryId` — se o negócio precisar filtrar alertas de
  ruptura por categoria, isso exigiria denormalizar esse campo na origem (Cloud Function que grava
  `stockAlerts`), fora do escopo desta task.
- `StockAlertsPage` (TASK-093) continua sem rota própria registrada — decisão deliberada nesta
  rodada (ver decisão 5 acima), não uma lacuna introduzida por esta task.

## Commit

Realizado nesta rodada (ver hash abaixo).

## Push

Não realizado nesta rodada — apenas commit local, conforme instrução explícita de não fazer
`git push`.
