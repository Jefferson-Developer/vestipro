# TASK-132 — Implementar central de oportunidades (CONCLUIDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** Concluída

## Resumo

Implementada a Central de Oportunidades: a tela única que agrega todos os 10 tipos de insight já
implementados (TASK-122 a TASK-131) em uma listagem só, priorizada por impacto estimado, com
filtros por tipo/faixa de impacto/período, ordenação alternativa, ação rápida direto do
card/linha, descarte/resolução com undo, e RBAC de visibilidade (vendedor vê a própria carteira,
gestor vê a equipe, admin vê a organização) — reaproveitando o `InsightRepository`/`InsightEngine`
já existentes (TASK-121), sem duplicar nenhuma lógica de navegação/ação das tasks de origem de
cada insight.

Esta task retomou trabalho já iniciado em uma sessão anterior: o domínio (entidades, serviço de
visibilidade, use cases), a camada de dados (`listPageByVisibility`/`updateStatus` no
datasource/repositório) e os eventos/estado do Bloc já existiam no working tree antes desta
execução. O que faltava — e foi implementado agora — foi o `OpportunityCenterBloc` em si, a
`OpportunityCenterPage`, o roteamento (`OpportunityCenterRoute` + guard de `Capability.insightView`
+ wiring em `bootstrap.dart`), a resolução de navegação da ação rápida (`_navigateForInsightAction`)
e os testes correspondentes.

## O que já existia (sessão anterior, mantido e integrado)

- `lib/core/permissions/capability.dart` / `role_permission_matrix.dart` — `Capability.insightView`,
  concedida a OWNER/ADMIN/SALES_MANAGER/SALES_REP.
- `lib/features/insights/domain/entities/insight_visibility_filter.dart` —
  `InsightVisibilityFilter`/`InsightVisibilityMode` (allOrganization/teams/ownOnly/none).
- `lib/features/insights/domain/entities/opportunity_center_filters.dart` —
  `OpportunityCenterFilters` (tipo/severidade/período/ordenação), com
  `toQueryParameters`/`fromQueryParameters` para preservar o estado na URL (Flutter Web).
- `lib/features/insights/domain/services/insight_visibility_service.dart` — resolve o filtro de
  visibilidade reaproveitando `PortfolioVisibilityService` (mesmo precedente de
  `TargetVisibilityService`).
- `lib/features/insights/domain/value_objects/insight_sort_by.dart` — `InsightSortBy`
  (estimatedImpact/generatedAt/relatedEntity), com `estimatedImpact` como padrão obrigatório.
- `lib/features/insights/domain/usecases/list_opportunity_center_insights_use_case.dart` e
  `update_insight_status_use_case.dart`.
- `lib/features/insights/data/datasources/{insight_data_source.dart,firestore_insight_data_source.dart}`
  — `listPageByVisibility` (com chunking de `whereIn` a cada 30 ids) e `updateStatus`.
- `lib/features/insights/data/repositories/insight_repository_impl.dart` /
  `domain/repositories/insight_repository.dart` — `listPageByVisibility`/`updateStatus`, sempre
  excluindo `dismissed`/`resolved`.
- `lib/features/insights/presentation/bloc/{opportunity_center_event.dart,opportunity_center_state.dart}`
  — eventos e o `OpportunityCenterState.visibleInsights` (derivação pura de filtro+ordenação sobre
  a lista já carregada).
- Testes já existentes: `test/core/permissions/role_permission_matrix_test.dart` (RBAC de
  `insight.view`) e `test/features/insights/data/repositories/insight_repository_impl_test.dart`
  (escopo por visibilidade + undo no repositório).

## O que foi implementado nesta execução

### Bloc

- `lib/features/insights/presentation/bloc/opportunity_center_bloc.dart` —
  `OpportunityCenterBloc`, cobrindo:
  - `OpportunityCenterStarted`/`Retried`: carga da primeira página via
    `ListOpportunityCenterInsightsUseCase` (que resolve visibilidade e nunca deixa a UI decidir
    escopo sozinha).
  - `OpportunityCenterFiltersChanged`: puramente síncrono — filtro/ordenação são derivados sobre
    `state.insights` já carregado (`OpportunityCenterState.visibleInsights`), nunca disparam nova
    leitura ao Firestore.
  - `OpportunityCenterNextPageRequested`: paginação por cursor (`generatedAt`), com token de
    requisição para não perder itens já carregados nem sobrepor respostas fora de ordem (mesmo
    padrão de `CustomerPortfolioBloc`/`OrderListBloc`).
  - `OpportunityCenterInsightOpened`/`ActionExecuted`: disparam `insight_opened`/
    `insight_action_clicked` (`AnalyticsEvents`, já existentes) com tipo do insight e tipo da ação.
  - `OpportunityCenterInsightDismissed`/`Resolved`: aplicação **otimista** — remove o insight da
    lista imediatamente e guarda `OpportunityCenterPendingUndo` (insight + status anterior + status
    aplicado) antes mesmo do `UpdateInsightStatusUseCase` responder; se a escrita falhar, desfaz a
    remoção sozinho e expõe a falha.
  - `OpportunityCenterUndoRequested`: reaplica o status anterior e reinsere o insight.

### Página

- `lib/features/insights/presentation/pages/opportunity_center_page.dart` — `OpportunityCenterPage`:
  - Gate por `Capability.insightView` via `PermissionBuilder` (mesmo formato de duas camadas de
    `TargetDashboardPage`/`Capability.targetView` — a UI só decide alcançabilidade da tela; o
    escopo real de quais insights aparecem é do `InsightVisibilityService`/Bloc).
  - Reaproveita `AppDataTable<Insight>` (já responsivo: linhas em tabela densa no desktop, cards no
    mobile — nenhum layout mobile/desktop bespoke foi criado) com colunas Tipo/Oportunidade/Impacto
    estimado/Recomendação, e 4 ações por linha: executar ação rápida, ver evidência completa
    (abre `AppModal` com descrição/evidência/recomendação — a "evidência expansível"), marcar como
    resolvido, descartar.
  - Filtros (`AppAdminPageLayout.filtersBuilder`, painel fixo no desktop / bottom sheet no
    mobile): ordenação (`AppDropdown` single-select), tipo de insight e faixa de impacto
    (`AppDropdown` `multiple: true` — trocado de `Wrap`+`AppFilterChip` porque os rótulos de
    `InsightType` são longos demais para o painel de 280px e estouravam o `Row` do chip; ver
    "Decisões/riscos" abaixo).
  - Descarte/resolução disparam `AppSnackbar` com ação "Desfazer", que dispara
    `OpportunityCenterUndoRequested`.
  - `onActionExecuted(insight, action)`: única forma de navegação — a página nunca chama
    `context.go` diretamente; delega para o composition root, mesmo contrato de
    `OrderListPage.onOrderDraftSelected`/`CustomerPortfolioPage.onCustomerSelected`.

### Roteamento

- `lib/core/navigation/app_route_paths.dart` — `OpportunityCenterRoute`
  (`/org/:orgId/companies/:companyId/insights/opportunities`), com `queryParameters` espelhando
  `OpportunityCenterFilters` (deep link/reload no Flutter Web).
- `lib/core/navigation/app_router.dart` — `opportunityCenterPageBuilder` + `GoRoute` protegida por
  `authorizationGuard.redirect(requiredCapability: Capability.insightView)`.

### Composição (bootstrap.dart)

- `opportunityCenterPageBuilder` registrado, injetando `OpportunityCenterBloc` via `getIt`,
  `initialFilters`/`onUrlStateChanged` espelhando filtros na URL (mesmo padrão de
  `OrderListPage`/`CustomerPortfolioPage`).
- `_navigateForInsightAction(...)`: resolve a navegação de cada `InsightAction` sem a Central
  conhecer rotas de outras features:
  - Toda ação com `customerId` (abrir cliente, agendar contato, iniciar pedido, ver
    histórico/oportunidades do cliente, ...) → `CustomerDetailRoute` (cliente 360, TASK-052) — o
    hub existente que já hospeda atividades CRM/follow-ups (TASK-059/060) e histórico de pedidos
    para aquele cliente.
  - `resumeOrder` (com `orderId` no `payload`) → `OrderDraftRoute` retomando o rascunho exato.
  - Ações sem `customerId` (puramente produto/vendedor: `suggestCampaign`, `notifyReplenishment`,
    `viewSellerDetail`) → sem rota dedicada ainda registrada em `AppRouter` (gap real, documentado
    abaixo); a Central mostra um `AppSnackbar` informativo em vez de navegar silenciosamente para o
    lugar errado ou travar.

### DI

- `dart run build_runner build` — regenerou `lib/app/injection.config.dart` com os bindings de
  `InsightVisibilityService`, `ListOpportunityCenterInsightsUseCase`, `UpdateInsightStatusUseCase`
  e `OpportunityCenterBloc` (nenhum já existia; os warnings de dependências não registradas
  reportados pelo `injectable_generator` são pré-existentes e não relacionados a esta task).

### Testes

- `test/features/insights/domain/services/insight_visibility_service_test.dart` — 4 casos
  (OWNER/ADMIN → `allOrganization`; SALES_REP → `ownOnly`; SALES_MANAGER → `teams` com
  teammates corretos e sem vazamento de outra equipe; sem Membership → `none`).
- `test/features/insights/domain/usecases/list_opportunity_center_insights_use_case_test.dart` — 3
  casos (validação de campos obrigatórios; `PermissionFailure` sem consultar o repositório quando
  `canViewAny` é falso; delega ao repositório com a visibilidade resolvida).
- `test/features/insights/domain/usecases/update_insight_status_use_case_test.dart` — 2 casos
  (validação; delega com ids `trim`ados).
- `test/features/insights/presentation/bloc/opportunity_center_bloc_test.dart` — 7 `blocTest`s:
  lista vazia; múltiplos tipos agregados e ordenados por impacto por padrão; filtro por tipo sem
  nova busca; paginação sem perder itens já carregados; RBAC (SALES_REP só carrega a própria
  carteira); descarte com undo funcional (incluindo rollback caso a escrita falhe — via mock);
  analytics (`insight_opened`/`insight_action_clicked` com os parâmetros corretos).
- `test/features/insights/presentation/pages/opportunity_center_page_test.dart` — 4 `testWidgets`:
  tabela densa no desktop; cards no mobile; página oculta para papel sem `insight.view`; descarte +
  undo end-to-end via UI.

## Decisões e riscos

- **Chips → `AppDropdown` nos filtros de tipo/severidade**: os rótulos de `InsightType` (ex.:
  "Estoque alto/giro baixo", "Sugestão de reposição") estouravam o `Row` interno de
  `AppFilterChip` dentro do painel de filtros de 280px (`AppAdminPageLayout`), mesmo em telas
  desktop largas — o painel lateral tem largura fixa, não a largura da janela. Corrigido trocando
  para `AppDropdown<InsightType>`/`AppDropdown<InsightSeverity>` com `multiple: true` (mesmo
  componente já usado para seleção múltipla em outras telas), que abre um diálogo pesquisável em
  vez de estourar o layout. Nenhuma alteração foi feita no `AppFilterChip` compartilhado.
- **Navegação da ação rápida por tipo sem `customerId` (`suggestCampaign`, `notifyReplenishment`,
  `viewSellerDetail`)**: não existe hoje, em `AppRouter`, uma rota dedicada de detalhe de
  produto/vendedor nem de criação de campanha alcançável fora do fluxo de um pedido em rascunho —
  gap real, já sinalizado como pendência nas conclusões de TASK-131 e no `route` placeholder de
  `high_stock_low_turnover_insight_rule.dart`/`replenishment_suggestion_insight_rule.dart`/
  `sales_rep_below_target_insight_rule.dart`. A Central de Oportunidades não inventa uma tela nova
  para isso (fora do escopo desta task) — mostra um aviso e a evidência completa do insight
  continua acessível via "Ver evidência completa", então nenhuma ação fica impossível de entender,
  apenas sem atalho de navegação direta ainda.
- **Filtro de tipo/severidade/período é só client-side** sobre a página já carregada (sem refazer a
  consulta ao Firestore) — mesma decisão de `CustomerPortfolioBloc`. Consequência aceita: se o
  usuário aplicar um filtro estreito antes de paginar o suficiente, pode não ver ainda insights
  que já existem em páginas seguintes até pedir "carregar mais". Não há paginação server-side por
  tipo/severidade nesta task (fora do escopo — poderia ser revisitado por TASK-133).

## Validações executadas

- `dart run build_runner build --delete-conflicting-outputs` — sucesso (flag removida/ignorada pela
  versão atual do `build_runner`, sem impacto); `injection.config.dart` regenerado com os 4 novos
  bindings.
- `flutter analyze` (projeto inteiro) — nenhum problema encontrado.
- `dart format` nos arquivos criados/alterados desta task.
- `flutter test test/features/insights` — 81 testes, todos passando.
- `flutter test test/core/permissions test/core/navigation test/app` — todos passando (RBAC, rotas
  e bootstrap não quebraram).
- `flutter test` (suíte completa do projeto) — 2525 testes, todos passando.

## Pendências / próximos passos

- Rota/tela dedicada de detalhe de vendedor, criação assistida de campanha e ação de "notificar
  reposição" ainda não existem no `AppRouter` — quando essas telas forem criadas (fora do escopo
  desta task), `_navigateForInsightAction` em `lib/app/bootstrap.dart` deve ganhar os `case`s
  correspondentes no lugar do `AppSnackbar` informativo atual.
- TASK-133 (camada de agregação server-side) pode, no futuro, permitir filtrar/paginar por
  tipo/severidade diretamente no backend em vez de só client-side.
