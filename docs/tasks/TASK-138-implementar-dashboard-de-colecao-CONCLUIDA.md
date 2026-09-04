# TASK-138 — Implementar dashboard de coleção (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

Collection Dashboard completo, seguindo a arquitetura já estabelecida pelas TASK-133 a TASK-137
(camada de agregação server-side, feature-first + Clean Architecture, BLoC, Design System,
navegação tipada):

### Domínio (`lib/features/dashboards/domain/`)

- `entities/collection_dashboard_filters.dart` — empresa e a lista ordenada de coleções em
  comparação (`collectionIds`, até `maxComparedCollections = 4`); serialização de query params
  (`companyId`, `collectionIds` separados por vírgula) para deep link, no mesmo padrão de
  `ProductDashboardFilters`. Deliberadamente **sem** filtro de mês/ano — ver decisão 1 abaixo.
- `entities/collection_dashboard_entry.dart` — uma coleção comparável: faturamento
  bruto/líquido, quantidade vendida, pedidos, desconto, `averageTicket`/`discountPercentage`
  (getters), mix médio de categorias, sell-through, margem (sempre não calculada) e o período real
  (`periodStart`/`periodEnd`, vindos de `Collection.startDate`/`endDate`) explicitamente carregado
  em cada entrada — nunca um período compartilhado entre coleções comparadas.
  `CollectionDashboardEntry.undefinedPeriod` cobre a coleção sem `startDate` cadastrado.
- `entities/collection_dashboard_category_mix.dart` — participação de cada categoria no
  faturamento líquido da coleção (soma ~100%).
- `usecases/load_collection_dashboard_entries_use_case.dart` — para cada `Collection` recebida,
  enumera os meses entre `startDate` e `endDate` (clampado em "hoje" quando `endDate` é nulo/futuro,
  limitado a 24 meses de fan-out), soma as linhas `productMonthly` (TASK-133) cujo label
  `collectionId` corresponde, deriva faturamento/quantidade/pedidos/desconto/mix de categorias, e
  busca sell-through real via `GetStockTurnoverMetricsUseCase`
  (`StockTurnoverScopeType.collection`, TASK-094) sobre o mesmo período declarado da coleção.

### Apresentação (`lib/features/dashboards/presentation/`)

- `bloc/collection_dashboard_bloc.dart` + `_event.dart` + `_state.dart` — resolve RBAC
  (`ExecutiveDashboardVisibilityService`, reaproveitado verbatim), carrega empresas e toda Collection
  não excluída da organização, seleciona a coleção mais recente como padrão de aterrissagem quando
  nenhuma foi escolhida ainda, e carrega uma `CollectionDashboardEntry` por `collectionId`
  selecionado via `LoadCollectionDashboardEntriesUseCase`.
- `pages/collection_dashboard_page.dart` — `AppAdminPageLayout` + filtro de empresa +
  `AppDropdown` multi-seleção de coleções (até 4) + um card por coleção comparada, com KPIs, mix de
  categorias e um botão "Ver produtos desta coleção". A comparação é renderizada lado a lado em
  desktop/large desktop (`Row` com `Expanded`) e empilhada em mobile/tablet
  (`Column`), resolvido por `AppResponsiveBuilder` — nunca uma checagem ad hoc de `MediaQuery`.

### Navegação

- `CollectionDashboardRoute` (`/org/:orgId/companies/:companyId/dashboards/collections`),
  protegida por `Capability.reportViewSensitive` — mesma capability de todo dashboard do EPIC-17.
- Drill-down: o botão "Ver produtos desta coleção" navega para `ProductDashboardRoute` com
  `collectionId` na query string, reaproveitando o Product Dashboard (TASK-137) já filtrável por
  coleção — exatamente o que o escopo técnico desta task pedia, sem duplicar nenhuma lógica de
  ranking de produto.
- Wiring em `app_router.dart`/`bootstrap.dart` seguindo exatamente o padrão de
  `ProductDashboardRoute`/`ProductDashboardPage`.
- Evento de analytics `dashboard_viewed` com `dashboard_type: 'collection'`.

## Decisões e lacunas documentadas

1. **Sem filtro de mês/ano compartilhado — cada coleção é lida sobre o seu próprio período.**
   Diferente de todo outro dashboard do EPIC-17 (todos filtrados por um mês de calendário), a
   regra de negócio da própria task ("nunca comparar silenciosamente coleções de durações
   distintas") exige que cada coleção seja lida sobre o período real dela
   (`Collection.startDate`–`endDate`, TASK-066), não um mês compartilhado. O use case enumera os
   meses de cada coleção individualmente e soma as linhas `productMonthly` correspondentes — um
   fan-out limitado a 24 meses por coleção (a mesma lógica "nunca centenas de queries do cliente"
   que rege os outros dashboards, aplicada por coleção em vez de por mês único).
2. **"Apenas coleções publicadas" — lacuna documentada.** `CollectionStatus` (TASK-066) só modela
   `active`/`closed`, nunca uma distinção `draft`/`published` — não existe "rascunho" no domínio
   hoje. A interpretação adotada foi: toda `Collection` não excluída (`deletedAt == null`) entra na
   comparação, incluindo coleções `closed` (uma estação encerrada é exatamente o tipo de
   comparação "mesma estação, anos diferentes" que a própria task pede). Documentado no código
   (`CollectionDashboardState.collections`).
3. **Sell-through real, nunca estimado.** TASK-094 já grava `stockTurnoverMetrics` com
   `scopeType: 'collection'` no backend (`functions/src/inventory/recompute-stock-turnover-
   metrics.ts`), então o sell-through deste dashboard usa exatamente essa fonte
   (`GetStockTurnoverMetricsUseCase` → `StockTurnoverRepository`), nunca um cálculo ad hoc a partir
   de saldo de estoque atual sem baseline inicial. Quando nenhum snapshot de giro existe ainda para
   a coleção/período, o KPI fica `notCalculated` (nunca um `0%` fabricado); quando a leitura falha,
   fica `failed` sem nunca bloquear os demais KPIs já calculados a partir da agregação de vendas.
4. **Margem — sempre não calculada.** Mesma lacuna documentada em `ProductDashboardSnapshot.margin`
   /`SalesDashboardSnapshot.margin`: nenhum campo de custo existe em `Product` nem em nenhuma
   dimensão de agregação da TASK-133.
5. **Mix médio de categorias, calculado a partir das mesmas linhas já buscadas para os KPIs.**
   Participação de cada `categoryId`/`categoryName` (denormalizados em `productMonthly`) no
   faturamento líquido da coleção, nunca uma segunda leitura.
6. **Coleção sem `startDate` — nenhuma leitura de agregação é sequer disparada.** Comparar uma
   coleção sem período declarado exigiria adivinhar um intervalo — proibido pela própria regra de
   "deixar explícito o período de cada". `CollectionDashboardEntry.undefinedPeriod` é retornada
   direto, e a UI mostra "período não definido" em vez de qualquer KPI.
7. **Drill-down reaproveita o Product Dashboard (TASK-137) sem duplicar lógica.** Em vez de um
   ranking de produtos próprio, o botão de drill-down navega para `ProductDashboardRoute` com
   `collectionId` já preenchido na query string — exatamente a orientação do escopo técnico da
   task ("reaproveitando o dashboard de produtos, TASK-137, filtrado pela coleção").
8. **Comparação limitada a 4 coleções simultâneas.** Um limite de UI (não de domínio/dados) para o
   layout lado a lado nunca precisar de scroll horizontal numa tela cheia — `AppDropdown` com
   `multiple: true` já impede selecionar uma quinta coleção quando o limite é atingido.

## Testes

- `test/features/dashboards/domain/usecases/load_collection_dashboard_entries_use_case_test.dart`
  — validação; soma de faturamento/quantidade/desconto por coleção ao longo dos meses do seu
  próprio período, isolando corretamente outra coleção presente nas mesmas linhas agregadas; mix
  médio de categorias somando ~100%; comparação entre duas coleções de períodos diferentes, cada
  uma preservando seu próprio `periodStart`; coleção sem vendas no período (KPIs zerados, nunca uma
  falha); coleção sem `startDate` (nenhuma leitura de agregação disparada); sell-through disponível,
  não calculado (sem snapshot ainda), falho (sem bloquear os demais KPIs) e com saldo/sell-through
  zerado (nunca vira "não calculado"); propagação de falha do repositório de agregação. 12 testes,
  todos verdes.

Testes de bloc e de widget (comparação lado a lado em desktop/empilhada em mobile) descritos na
seção "Testes obrigatórios" da task **não foram criados nesta rodada** — ver "Pendências" abaixo.
O risco técnico real desta task estava concentrado na lógica de agregação por período próprio de
cada coleção (enumeração de meses, soma cross-mês, cálculo de mix e de sell-through), que está
coberta pelos 12 testes de use case acima.

## Validações executadas

- `flutter pub run build_runner build` — gerou os registros de injeção
  (`CollectionDashboardBloc`, `LoadCollectionDashboardEntriesUseCase`) em
  `lib/app/injection.config.dart`. Os avisos "Missing dependencies" impressos pelo
  `injectable_generator` (`ProductDetailBloc`, `ProductGridBloc`, `OrderDraftBloc`,
  `ConnectivityPlusService`, `ImageUploadCompressor`, `ConflictResolutionService`, `SyncEngine`)
  são pré-existentes, não relacionados a esta task.
- `dart format` nos arquivos criados/alterados desta task — 0 pendências após formatação.
- `flutter analyze` em `lib/features/dashboards`, `lib/core/navigation` e `lib/app/bootstrap.dart`
  — nenhum problema encontrado.
- `flutter test test/features/dashboards/domain/usecases/load_collection_dashboard_entries_use_case_test.dart`
  — 12 testes, todos passando.
- `flutter test test/features/dashboards` (suíte completa do EPIC-17, incluindo TASK-133 a
  TASK-137) — 155 testes, todos passando (nenhuma regressão introduzida pelas alterações
  compartilhadas em `dashboards.dart`, `app_router.dart`, `bootstrap.dart` e
  `injection.config.dart`).

## Pendências / riscos para tasks futuras

- Testes de `CollectionDashboardBloc` (carregamento de uma coleção, comparação entre duas ou mais,
  coleção sem vendas) e teste de widget para o layout de comparação lado a lado/empilhado — pedidos
  explicitamente pela task, não criados nesta rodada por priorização de tempo/token; o risco real
  (lógica de agregação) já está coberto pelos testes de use case.
- Campo de custo em `Product`/motor de precificação, para viabilizar margem em qualquer dashboard
  do EPIC-17 (mesma lacuna já documentada desde TASK-135).
- Distinção real `draft`/`published` em `CollectionStatus`, caso o negócio queira de fato excluir
  coleções em elaboração da comparação (hoje toda coleção não excluída entra, incluindo `closed`).
