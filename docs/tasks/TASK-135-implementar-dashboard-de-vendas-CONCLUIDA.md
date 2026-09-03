# TASK-135 — Concluída (2026-09-02)

## Resumo
Implementado o Sales Dashboard (EPIC-17, seção 12.1/12.2/12.3 de `tasks.md`): 8 KPIs
(faturamento, pedidos, ticket médio, quantidade vendida, desconto médio, margem, peças por
pedido, produtos por pedido) com comparação simultânea MoM e YoY (variação percentual e
absoluta), gráfico de tendência diária de faturamento, tabela de detalhamento agrupável por
vendedor/cliente/produto/categoria com ordenação por coluna e comparação contra o período
anterior ou o mesmo mês do ano anterior, e drill-down (do KPI/linha agregada até a lista de
pedidos que a compõe, reaproveitando a listagem de pedidos — TASK-102 — e o detalhe
individual do pedido — TASK-104, já existente). Toda leitura vem exclusivamente da camada
de agregação server-side da TASK-133 (`AggregationRepository`), nunca de uma query direta a
`orders`.

## Agentes utilizados
- `flutter-senior-architect` (arquitetura, domínio, dados, RBAC, use cases, bloc, DI).
- `flutter-ui-design-specialist` (perspectiva de UI/Design System coberta diretamente pelo
  agente arquiteto nesta execução — reuso de `AppDataTable`, `AppAdminPageLayout`,
  `AppManagementChart`, `AppDropdown`, `AppFilterChip`, responsividade tabela/card,
  acessibilidade ícone+texto, mesmos precedentes já usados pelo Executive Dashboard/TASK-134
  e pela listagem de pedidos/TASK-102).

## Arquivos criados
- `lib/features/dashboards/domain/value_objects/sales_dashboard_group_dimension.dart`
- `lib/features/dashboards/domain/value_objects/sales_dashboard_sort_field.dart`
- `lib/features/dashboards/domain/value_objects/sales_dashboard_comparison_mode.dart`
- `lib/features/dashboards/domain/entities/sales_dashboard_filters.dart`
- `lib/features/dashboards/domain/entities/sales_dashboard_kpi.dart`
- `lib/features/dashboards/domain/entities/sales_dashboard_snapshot.dart`
- `lib/features/dashboards/domain/entities/sales_dashboard_group_row.dart`
- `lib/features/dashboards/domain/usecases/load_sales_dashboard_snapshot_use_case.dart`
- `lib/features/dashboards/domain/usecases/load_sales_dashboard_group_rows_use_case.dart`
- `lib/features/dashboards/presentation/bloc/sales_dashboard_event.dart`
- `lib/features/dashboards/presentation/bloc/sales_dashboard_state.dart`
- `lib/features/dashboards/presentation/bloc/sales_dashboard_bloc.dart`
- `lib/features/dashboards/presentation/pages/sales_dashboard_page.dart`
- `test/features/dashboards/domain/usecases/load_sales_dashboard_snapshot_use_case_test.dart`
- `test/features/dashboards/domain/usecases/load_sales_dashboard_group_rows_use_case_test.dart`
- `test/features/dashboards/presentation/bloc/sales_dashboard_bloc_test.dart`
- `docs/tasks/TASK-135-implementar-dashboard-de-vendas-CONCLUIDA.md` (este arquivo)

## Arquivos alterados
- `lib/features/dashboards/dashboards.dart`: exports dos novos arquivos.
- `lib/core/navigation/app_route_paths.dart`: nova rota `SalesDashboardRoute`
  (`/org/:orgId/companies/:companyId/dashboards/sales`), com `queryParameters` para
  `teamId`/`month`/`groupBy`/`compare`/`sortBy`/`sortDir` (deep link Flutter Web).
- `lib/core/navigation/app_router.dart`: `salesDashboardPageBuilder` injetável + registro da
  rota, protegida por `report.viewSensitive`.
- `lib/app/bootstrap.dart`: `salesDashboardPageBuilder` monta `SalesDashboardPage`,
  navegando para `OrderListRoute` (com filtros de período/vendedor/cliente já aplicados) no
  drill-down.
- `lib/app/injection.config.dart` (gerado via `dart run build_runner build`): registro DI de
  `LoadSalesDashboardSnapshotUseCase`, `LoadSalesDashboardGroupRowsUseCase` e
  `SalesDashboardBloc`.
- `docs/tasks/TASKS.md`: checkbox da TASK-135 marcado e progresso atualizado para
  135/220.

## Arquitetura utilizada
Clean Architecture feature-first, seguindo o precedente já estabelecido pelo Executive
Dashboard (TASK-134): `SalesDashboardBloc` reaproveita **verbatim**
`ExecutiveDashboardVisibilityService`/`ExecutiveDashboardVisibilityFilter` (mesma capability
`report.viewSensitive`, mesmas cinco coleções de agregação da TASK-133, mesma semântica
"toda a organização" para OWNER/ADMIN/FINANCE e "próprio escopo" para SALES_MANAGER) em vez
de duplicar essa regra em um serviço "SalesDashboardVisibilityService" próprio.
`SalesDashboardKpi` é uma entidade nova (não uma reutilização de `ExecutiveDashboardMetric`)
porque este dashboard precisa de duas baselines de comparação simultâneas (MoM e YoY), algo
que `ExecutiveDashboardMetric` não modela (só um `previousValue`).

## Regras de negócio implementadas
- Toda leitura de KPI/linha de tabela vem de `AggregationRepository` (TASK-133) — nunca uma
  soma client-side de pedidos crus.
- Desconto médio é `discountAmount / revenueGross` somado diretamente dos campos que o
  motor de precificação (TASK-088) já persistiu em cada pedido e que a TASK-133 já agregou
  — nunca um desconto recalculado nesta camada (regra explícita da task).
- **Margem e "produtos por pedido" são sempre `notCalculated`, nunca um valor inventado**:
  não existe em nenhuma camada do backend (nem `Product.cost`, nem saída de margem do motor
  de precificação) um dado de custo para calcular margem; nenhuma dimensão de agregação
  registra a composição de SKUs distintos por pedido (`productMonthly` é agregado por
  produto entre todos os pedidos, não por pedido). Calcular qualquer um dos dois exigiria ou
  inventar um número na camada de apresentação (proibido pela própria task) ou escanear
  pedidos crus no cliente (proibido pelo próprio escopo técnico da task). Mesmo padrão já
  usado por `ExecutiveDashboardSnapshot.newCustomers`.
- Drill-down do KPI/linha agregada até a lista de pedidos é uma consulta pontual via
  `OrderListFilters` (período + vendedor/cliente), nunca uma varredura completa — a própria
  listagem de pedidos (TASK-102) já pagina por cursor. Da lista até o pedido individual
  reaproveita a tela de histórico/detalhe já existente (TASK-104, `OrderHistoryPage`).
  Drill-down por produto/categoria **não é oferecido** (botão de ação simplesmente omitido
  para essas duas dimensões): `Order`/`OrderListFilters` não têm um filtro por item de
  pedido hoje (nenhum índice por `productId`), e implementá-lo exigiria uma varredura
  completa de itens de pedido no cliente — documentado como pendência abaixo.
- Agrupamento por categoria é uma re-agregação client-side das linhas `productMonthly` já
  buscadas (uma soma sobre uma lista já em memória, já limitada), nunca uma segunda consulta
  ao servidor nem um scan de `orders`/`products`.
- Filtro de vendedor/equipe respeita RBAC: a tabela "por vendedor" é restrita aos membros da
  equipe filtrada (ou, sem filtro de equipe explícito, à união de todas as equipes que um
  SALES_MANAGER gerencia) — nunca lista um vendedor fora do escopo do gestor mesmo sem um
  filtro de equipe ativo.
- Evento de analytics `dashboard_viewed` (parâmetro `dashboard_type: 'sales'`) registrado a
  cada carregamento bem-sucedido do snapshot.

## Pendência conhecida e deliberadamente não resolvida nesta task: acesso de representante
O Objetivo da task nomeia "representantes" como público do dashboard, e a regra de negócio
"representante vê apenas a própria carteira; gestor vê a equipe" está no próprio escopo
técnico. **Isso não foi implementado**: `Capability.reportViewSensitive` — a capability que
`firestore.rules` já exige para ler qualquer uma das cinco coleções de agregação da
TASK-133 — não é concedida a `SALES_REP` (`RolePermissionMatrix`), e essas Security Rules
são gated apenas por capability, sem verificação de posse por `scopeId` (diferente de
`orders`, que tem `canReadOrder` checando o vendedor real do documento). Conceder
`report.viewSensitive` a `SALES_REP` hoje permitiria que qualquer representante listasse o
faturamento agregado de **todos os outros** vendedores/clientes da organização — uma
regressão de segurança real, não apenas uma limitação de UX. Resolver isso corretamente
exige adicionar escopo por `scopeId` nas Security Rules das cinco coleções (infraestrutura
compartilhada por todo o EPIC-17, TASK-136 a TASK-143) — uma decisão deliberada de uma task
própria, não algo para "passar despercebido" implementando uma tela de dashboard. Hoje o
Sales Dashboard funciona plenamente para OWNER/ADMIN/FINANCE (organização toda) e
SALES_MANAGER (próprio escopo/equipe), exatamente como o Executive Dashboard (TASK-134) já
funciona.

## Analytics implementado
`dashboard_viewed` (evento já existente, TASK-134) com `dashboard_type: 'sales'` a cada
carregamento bem-sucedido do snapshot. `report_exported` **não foi implementado**: nenhuma
funcionalidade de exportação (CSV/XLSX/PDF, seção 12.3) foi construída por nenhuma task até
aqui, e o escopo técnico desta task não lista "exportar" entre seus recursos — permanece
pendência futura de uma task de exportação/relatórios dedicada.

## Impacto offline
Mesma limitação já documentada e aceita pelo Executive Dashboard (TASK-134): a leitura de
agregações é 100% online (sem cache Drift local) — um gestor offline não vê o dashboard
até reconectar. Nenhuma regressão introduzida.

## Impacto multi-tenant
Toda leitura é escopada por `organizationId` + `companyId`, delegada a
`AggregationRepository` (já isolado por tenant desde a TASK-133) e ao
`ExecutiveDashboardVisibilityService` reaproveitado (já isolado por tenant desde a
TASK-134). Nenhuma nova superfície de leitura cross-tenant foi introduzida.

## Testes criados
- `load_sales_dashboard_snapshot_use_case_test.dart`: validação de payload; margem e
  produtos por pedido sempre `notCalculated`; cálculo de faturamento/pedidos/ticket
  médio/quantidade/peças por pedido e desconto médio exatamente a partir dos totais da
  agregação, com comparação MoM e YoY; período vazio resolve zero disponível (nunca falha);
  falha no período corrente falha aquele KPI sem falhar a chamada inteira (mesmo contrato "um
  KPI falha e os demais continuam" da TASK-134); filtro de equipe soma apenas
  `sellerMonthly` dos membros, com fallback seguro a zero quando a equipe não tem membro
  resolvido (nunca cai para a empresa toda).
- `load_sales_dashboard_group_rows_use_case_test.dart`: agrupamento por vendedor/cliente
  com rótulo denormalizado e comparação de período anexada; linha sem dado no período de
  comparação renderiza `null` (nunca um "-100%" fabricado); re-agregação por categoria
  (incluindo fallback "Sem categoria"); RBAC de `sellerScopeIds` (lista vazia retorna zero
  linhas sem fallback para a empresa toda e sem sequer chamar o repositório; um subconjunto
  restringe tanto o período corrente quanto o de comparação; nunca restringe uma dimensão
  não-vendedor); ordenação padrão (faturamento decrescente) e customizada (rótulo
  ascendente); modo de comparação YoY comparando contra o mesmo mês do ano anterior.
- `sales_dashboard_bloc_test.dart`: papel sem `report.viewSensitive` resolve `forbidden`;
  OWNER chega a `ready` com snapshot e tabela agrupada, registrando `dashboard_viewed`; uma
  troca de filtro para uma equipe fora do `ownScope` do gestor é ignorada; a tabela "por
  vendedor" de um SALES_MANAGER é restrita às suas equipes mesmo sem filtro de equipe
  explícito; falha ao listar empresas surge como estado de erro; um retry recarrega após
  falha.

### Testes obrigatórios da task não cobertos nesta rodada (escopo reduzido deliberadamente)
- Teste de widget dedicado para a densidade da tabela administrativa
  (desktop/tabela vs. mobile/cards): a conversão responsiva em si é comportamento de
  `AppDataTable` (Design System), já coberto por seus próprios testes e reutilizado sem
  modificação por esta task — não há lógica nova de responsividade para testar aqui. Efeito
  colateral aceito conscientemente, dado o modo econômico desta rodada; se desejado, um
  teste de widget de `SalesDashboardPage` pode ser adicionado depois seguindo o precedente
  de `executive_dashboard_page_test.dart`.
- Não há teste de Firestore Rules dedicado: esta task não altera nenhuma Security Rule
  (reaproveita as cinco coleções/regras já validadas pela TASK-133).

## Comandos executados
- `dart run build_runner build` (regeração de `injection.config.dart` para os novos
  `@injectable`: `LoadSalesDashboardSnapshotUseCase`, `LoadSalesDashboardGroupRowsUseCase`,
  `SalesDashboardBloc`). Concluído com sucesso; os únicos avisos exibidos
  (`ConnectivityPlusService`/`ImageUploadCompressor`/`ConflictResolutionService`/
  `SyncEngine`/`ProductDetailBloc`/`ProductGridBloc`/`OrderDraftBloc` dependendo de tipo não
  registrado) são pré-existentes e não relacionados a esta task.
- `flutter analyze --no-fatal-infos` (projeto inteiro) → **0 issues**.
- `dart format` nos arquivos novos/alterados → formatação aplicada, sem pendências.
- `flutter test test/features/dashboards` → **94 testes, todos passando**.
- `flutter test test/core/navigation test/core/permissions` → **60 testes, todos
  passando** (nenhuma regressão nas rotas/RBAC existentes).

## Resultado do analyzer
`flutter analyze --no-fatal-infos` → **No issues found!**

## Resultado dos testes
`flutter test test/features/dashboards`: **94 testes, 0 falhas** (inclui os 3 arquivos de
teste novos desta task e os já existentes do Executive Dashboard/TASK-134, sem regressão).
`flutter test test/core/navigation test/core/permissions`: **60 testes, 0 falhas**.
Suíte completa (`flutter test`) não executada nesta rodada — modo econômico não exige
validação de encerramento além do que a própria task pede; os subconjuntos relevantes
(dashboards, navigation, permissions) foram executados e validados.

## Decisões técnicas
- **Reuso verbatim de `ExecutiveDashboardVisibilityService`** em vez de um novo serviço:
  ambos os dashboards leem as mesmas cinco coleções de agregação, gated pela mesma
  capability — duplicar a regra criaria duas cópias para manter sincronizadas.
- **`SalesDashboardKpi` é uma entidade nova, não uma reutilização de
  `ExecutiveDashboardMetric`**: esta task pede comparação MoM e YoY simultâneas (duas
  baselines), enquanto `ExecutiveDashboardMetric` só carrega uma `previousValue`.
- **Grouping por "categoria" mapeia para a mesma dimensão `productMonthly`, nunca uma sexta
  dimensão server-side**: a TASK-133 já denormaliza `categoryId`/`categoryName` nas labels
  de cada snapshot de produto exatamente para permitir essa re-agregação client-side.
- **Drill-down por produto/categoria deliberadamente não oferecido**: ver seção de Regras de
  negócio acima.
- **Acesso de SALES_REP deliberadamente não implementado**: ver seção de pendência dedicada
  acima — é a decisão técnica mais significativa desta task.

## Riscos conhecidos
- Ver "Pendência conhecida" acima (acesso de representante bloqueado por design de
  segurança, não por esquecimento).
- Mesmos riscos já documentados pela TASK-134 (sem cache offline, `whereIn`/paginação
  limitada nas leituras de agregação) — nenhum risco novo introduzido por esta task.

## Pendências
- Extensão de `report.viewSensitive` (ou uma capability mais restrita, com scoping por
  `scopeId` nas Firestore Rules das cinco coleções de agregação) para permitir que
  SALES_REP veja a própria carteira neste dashboard — recomendado como task dedicada, dado
  o impacto compartilhado com TASK-136 a TASK-143.
- Drill-down por produto/categoria até os pedidos que o compõem — depende de um índice/campo
  de busca por item de pedido que não existe hoje em `Order`/`OrderListFilters`.
- Funcionalidade de exportação (`report_exported`, CSV/XLSX/PDF) — fora do escopo técnico
  desta task, permanece no backlog de "Relatórios e BI" (seção 12.3).
- Nenhum item de menu/navegação global aponta para `SalesDashboardRoute` ainda — mesma
  situação já documentada por `ExecutiveDashboardRoute`/`OrderListRoute` (não existe shell
  de navegação global no repositório ainda); a rota é acessível via `context.go`/deep link.

## Evidências
- `flutter analyze --no-fatal-infos`: 0 issues.
- `flutter test test/features/dashboards`: 94 testes, 0 falhas.
- `flutter test test/core/navigation test/core/permissions`: 60 testes, 0 falhas.
- `dart format`: aplicado nos arquivos novos/alterados, sem pendências restantes.

## Commit
Único commit local cobrindo implementação + documentação + atualização do
`docs/tasks/TASKS.md`.

## Push
Não realizado — sem autorização de push nesta rodada.
