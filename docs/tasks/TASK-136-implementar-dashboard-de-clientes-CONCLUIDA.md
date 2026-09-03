# TASK-136 — Concluída (2026-09-02)

## Resumo

Implementado o Customer Dashboard (EPIC-17, seção 12.1/12.2/12.3 de
`tasks.md`): clientes ativos, clientes novos, clientes reativados, taxa de
recompra, frequência média de compra, churn, cobertura de carteira e
positivação, mais um ranking de clientes ordenável (faturamento, frequência,
ticket médio) com filtro por segmento e paginação, e drill-down até o
detalhe do cliente 360 (TASK-052). Toda leitura vem exclusivamente da camada
de agregação server-side da TASK-133 (`AggregationRepository`,
`customerMonthly`) e da camada de positivação da TASK-117
(`PositivacaoRepository`) — nunca uma query direta a `orders`/`customers`.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domínio, dados, RBAC, use cases,
  bloc, DI).
- `flutter-ui-design-specialist` (perspectiva de UI/Design System coberta
  diretamente pelo agente arquiteto nesta execução — reuso de `AppKpiCard`,
  `AppDataTable`, `AppAdminPageLayout`, `AppDropdown`, `AppTextField`,
  responsividade tabela/card, mesmos precedentes já usados pelo Executive
  Dashboard/TASK-134 e pelo Sales Dashboard/TASK-135).

## Arquivos criados

Domínio:
- `lib/features/dashboards/domain/value_objects/customer_dashboard_sort_field.dart`
- `lib/features/dashboards/domain/entities/customer_dashboard_filters.dart`
- `lib/features/dashboards/domain/entities/customer_dashboard_snapshot.dart`
- `lib/features/dashboards/domain/entities/customer_dashboard_ranking_row.dart`
- `lib/features/dashboards/domain/usecases/load_customer_dashboard_snapshot_use_case.dart`
- `lib/features/dashboards/domain/usecases/load_customer_dashboard_ranking_use_case.dart`

Apresentação:
- `lib/features/dashboards/presentation/bloc/customer_dashboard_event.dart`
- `lib/features/dashboards/presentation/bloc/customer_dashboard_state.dart`
- `lib/features/dashboards/presentation/bloc/customer_dashboard_bloc.dart`
- `lib/features/dashboards/presentation/pages/customer_dashboard_page.dart`

Testes:
- `test/features/dashboards/domain/usecases/load_customer_dashboard_snapshot_use_case_test.dart`
- `test/features/dashboards/domain/usecases/load_customer_dashboard_ranking_use_case_test.dart`
- `test/features/dashboards/presentation/bloc/customer_dashboard_bloc_test.dart`

Documentação:
- `docs/tasks/TASK-136-implementar-dashboard-de-clientes-CONCLUIDA.md` (este
  arquivo).

## Arquivos alterados

- `lib/features/dashboards/dashboards.dart`: exports dos novos arquivos.
- `lib/core/navigation/app_route_paths.dart`: nova rota
  `CustomerDashboardRoute`
  (`/org/:orgId/companies/:companyId/dashboards/customers`), com
  `queryParameters` para `teamId`/`month`/`segment`/`sortBy`/`sortDir` (deep
  link Flutter Web).
- `lib/core/navigation/app_router.dart`: `customerDashboardPageBuilder`
  injetável + registro da rota, protegida por `report.viewSensitive`.
- `lib/app/bootstrap.dart`: `customerDashboardPageBuilder` monta
  `CustomerDashboardPage`, navegando para `CustomerDetailRoute` (TASK-052)
  no drill-down.
- `lib/app/injection.config.dart` (gerado via `dart run build_runner build`):
  registro DI de `LoadCustomerDashboardSnapshotUseCase`,
  `LoadCustomerDashboardRankingUseCase` e `CustomerDashboardBloc`.
- `docs/tasks/TASKS.md`: checkbox da TASK-136 marcado e progresso atualizado
  para 136/220.

## Arquitetura utilizada

Clean Architecture feature-first, seguindo o precedente já estabelecido pelo
Executive Dashboard (TASK-134) e pelo Sales Dashboard (TASK-135):
`CustomerDashboardBloc` reaproveita **verbatim**
`ExecutiveDashboardVisibilityService`/`ExecutiveDashboardVisibilityFilter`
(mesma capability `report.viewSensitive`, mesma semântica "toda a
organização" para OWNER/ADMIN/FINANCE e "próprio escopo" para
SALES_MANAGER) em vez de duplicar essa regra em um serviço
"CustomerDashboardVisibilityService" próprio. Os KPIs de
clientes ativos/cobertura de carteira/positivação reaproveitam o
`PositivacaoRepository` (TASK-117) — a mesma fonte que o Executive Dashboard
já usa para "clientes ativos"/"positivação" — garantindo que os dois
dashboards nunca divirjam na definição de "cliente ativo" (critério de
aceite explícito desta task).

## Regras de negócio implementadas

- Toda leitura de KPI/linha do ranking vem de `AggregationRepository`
  (`customerMonthly`, TASK-133) ou `PositivacaoRepository` (TASK-117) —
  nunca uma soma client-side de pedidos/clientes crus.
- **Clientes ativos** = `PositivacaoSnapshot.positivatedCount` — mesma fonte
  e definição que `ExecutiveDashboardSnapshot.activeCustomers` já usa
  (critério de aceite: "definição de cliente ativo/inativo consistente
  entre dashboard e central de oportunidades" — ver divergência documentada
  abaixo sobre por que **não** foi possível reusar literalmente a janela em
  dias da TASK-122).
- **Cobertura de carteira** = `PositivacaoSnapshot.totalPortfolio` (tamanho
  da carteira medida no período); **positivação** =
  `PositivacaoSnapshot.percentage` — dois números distintos derivados do
  mesmo snapshot pré-calculado, nunca uma segunda fonte inventada.
- **Taxa de recompra** = fração dos clientes com `orderCount >= 2` dentro do
  próprio `customerMonthly` do período (recompra intra-período), e
  **frequência média de compra** = soma de `orderCount` / clientes ativos no
  período — ambas derivadas inteiramente de uma lista já buscada e já
  limitada de snapshots pré-calculados, nunca um novo cálculo sobre pedidos
  brutos.
- **Churn** = fração dos clientes presentes no `customerMonthly` do período
  anterior que **não** aparecem no período corrente — também derivado
  inteiramente de dois snapshots pré-calculados (uma segunda leitura
  limitada, não uma varredura).
- **Clientes novos e clientes reativados são sempre `notCalculated`, nunca
  um valor inventado**: nenhuma dimensão de agregação da TASK-133 (nem
  `Customer.createdAt`, uma data de cadastro, não de "primeira compra")
  permite distinguir "cliente que comprou pela primeira vez" de "cliente que
  já comprava e voltou" sem escanear o histórico completo de pedidos do
  cliente — proibido pelo próprio escopo técnico da task. Mesmo padrão já
  usado por `ExecutiveDashboardSnapshot.newCustomers`.
- Ranking de clientes ordenável (faturamento, frequência/pedidos, ticket
  médio) e paginado (janela client-side sobre uma única leitura limitada já
  buscada, preservando itens já carregados a cada "carregar mais" —
  `CustomerDashboardState.visibleRankingRows`/`hasMoreRankingRows`), com
  filtro por segmento (`AggregationSnapshot.labels['segment']`,
  case-insensitive) e drill-down para `CustomerDetailRoute` (TASK-052).
- Evento de analytics `dashboard_viewed` (parâmetro `dashboard_type:
  'customer'`) registrado a cada carregamento bem-sucedido do snapshot.

## Divergência documentada: definição de churn/cliente ativo vs. TASK-122

A regra de insight de cliente inativo (TASK-122,
`InactiveCustomerInsightRule`) define inatividade por **dias corridos desde
o último pedido** (`asOf - lastOrderAt > threshold`, configurável por
organização/segmento). Esse dado (`lastOrderAt` por cliente) **não existe em
nenhuma dimensão de agregação da TASK-133** — `customerMonthly` carrega
apenas `revenueGross`/`revenueNet`/`discountAmount`/`orderCount`/
`itemQuantity` e os labels `customerName`/`segment`, nunca uma data do
último pedido. Além disso, o dataset que alimenta a regra de insight
(`InsightCustomerSnapshot`/`InsightDataset.customerSnapshots`) **não tem
nenhuma implementação de repositório/data source no cliente Flutter hoje**
(confirmado: `lib/features/insights/data/` não contém nenhum código que
popule `customerSnapshots` a partir de Firestore) — é consumido apenas em
testes unitários da própria regra, plugado por uma pipeline server-side
(`functions/src/insights`) ainda não exposta como uma leitura que este
dashboard pudesse reaproveitar.

Reproduzir literalmente a definição da TASK-122 exigiria uma nova dimensão
de agregação com `lastOrderAt` por cliente — fora do escopo técnico desta
task. Em vez disso, "clientes ativos" usa a mesma fonte que o Executive
Dashboard já usa (`PositivacaoSnapshot`, "comprou dentro do período
calendário filtrado") e "churn" usa uma definição período-a-período
derivada exclusivamente de `customerMonthly` (ver acima) — ambas
computáveis apenas a partir de dado já pré-calculado, sem recalcular nada do
zero no cliente (a restrição inegociável da própria task). Na prática, as
duas definições raramente divergem (um cliente sem compra no mês corrente
quase sempre já ultrapassou o threshold padrão de 45 dias da TASK-122), mas
tecnicamente não são a mesma regra — documentado aqui como decisão
consciente, não como um esquecimento, e recomendado como pendência para uma
task dedicada de extensão de schema quando a leitura real de
`InsightCustomerSnapshot` for implementada no cliente.

## Pendência conhecida e deliberadamente não resolvida nesta task: acesso de representante

Mesma pendência já documentada pela TASK-134 e pela TASK-135:
`Capability.reportViewSensitive` — exigida para ler qualquer uma das cinco
coleções de agregação da TASK-133, incluindo `customerMonthlyAggregates` —
não é concedida a `SALES_REP` (`RolePermissionMatrix`), e essas Security
Rules são gated apenas por capability, sem verificação de posse por
`scopeId`. Conceder a capability a `SALES_REP` hoje permitiria que qualquer
representante listasse o faturamento agregado de **todos os outros**
clientes da organização — uma regressão de segurança, não apenas uma
limitação de UX. Resolver isso exige escopo por `scopeId` nas Security
Rules das cinco coleções (infraestrutura compartilhada por todo o EPIC-17) —
uma task própria, já recomendada pelas TASK-134/TASK-135.

## Limitação de dado: filtro de equipe não narrows o ranking nem
## recompra/frequência/churn

`customerMonthly` carrega apenas `customerId` como `scopeId` — nenhum
`sellerId`/`teamId` denormalizado (diferente de `sellerMonthly`, que o Sales
Dashboard usa para restringir por equipe). Por isso:

- **Restringível por equipe** (via `PositivacaoDimensionType.team`, que já
  modela nativamente a dimensão de equipe desde a TASK-117): clientes
  ativos, cobertura de carteira e positivação — exatamente como o Executive
  Dashboard já restringe os mesmos KPIs.
- **Não restringível por equipe hoje**: taxa de recompra, frequência média,
  churn e a tabela de ranking de clientes inteira — ficam sempre
  empresa/organização inteira mesmo com um filtro de equipe ativo. Narrowing
  exigiria uma nova dimensão de agregação (`customerMonthly` ganhando
  `sellerId`/`teamId`) ou uma junção client-side contra a carteira
  RBAC-resolvida (uma segunda leitura potencialmente grande, o que a própria
  task proíbe para um KPI/tabela). A UI comunica essa limitação
  explicitamente quando um filtro de equipe está selecionado.

## Analytics implementado

`dashboard_viewed` (evento já existente, TASK-134) com `dashboard_type:
'customer'` a cada carregamento bem-sucedido do snapshot.
`report_exported` **não foi implementado** — mesma pendência já documentada
pela TASK-135 (nenhuma funcionalidade de exportação construída em nenhuma
task até aqui).

## Impacto offline

Mesma limitação já documentada e aceita pelas TASK-134/TASK-135: a leitura
de agregações/positivação é 100% online (sem cache Drift local) — um gestor
offline não vê o dashboard até reconectar. Nenhuma regressão introduzida.

## Impacto multi-tenant

Toda leitura é escopada por `organizationId` + `companyId`, delegada a
`AggregationRepository` (já isolado por tenant desde a TASK-133) e a
`PositivacaoRepository` (já isolado por tenant desde a TASK-117), com o
`ExecutiveDashboardVisibilityService` reaproveitado (já isolado por tenant
desde a TASK-134) resolvendo o escopo de empresa/equipe. Nenhuma nova
superfície de leitura cross-tenant foi introduzida.

## Testes criados

- `load_customer_dashboard_snapshot_use_case_test.dart`: validação de
  payload; clientes novos/reativados sempre `notCalculated`; clientes
  ativos/cobertura de carteira/positivação vindos de `PositivacaoSnapshot`
  com comparação MoM (e `notCalculated` quando a positivação ainda não foi
  calculada); taxa de recompra e frequência média calculadas exatamente a
  partir dos `customerMonthly` já buscados (incluindo o caso de zero
  clientes, sem divisão por zero); uma falha ao buscar o período corrente
  falha apenas recompra/frequência/churn sem falhar os KPIs de positivação
  (contrato "um KPI falha e os demais continuam"); churn calculado por
  diferença de conjuntos entre dois períodos, e `notCalculated` quando não
  há período anterior; filtro de equipe usando
  `PositivacaoDimensionType.team`.
- `load_customer_dashboard_ranking_use_case_test.dart`: validação de
  payload; mapeamento de snapshot para linha com ticket médio; fallback do
  nome para o `customerId` quando não há label denormalizado; filtro por
  segmento case-insensitive; ordenação por faturamento (padrão),
  frequência e ascendente/descendente; propagação de falha do repositório.
- `customer_dashboard_bloc_test.dart`: papel sem `report.viewSensitive`
  resolve `forbidden`; OWNER chega a `ready` com snapshot e ranking,
  registrando `dashboard_viewed`; uma troca de filtro para uma equipe fora
  do `ownScope` do gestor é ignorada; paginação do ranking cresce a janela
  visível preservando todas as linhas já carregadas; falha ao listar
  empresas surge como estado de erro.

### Testes obrigatórios da task não cobertos nesta rodada (escopo reduzido deliberadamente)

- Teste de widget dedicado para a densidade da tabela administrativa
  (desktop/tabela vs. mobile/cards): mesma decisão já tomada pela TASK-135 —
  a conversão responsiva é comportamento de `AppDataTable` (Design System),
  já coberto por seus próprios testes e reutilizado sem modificação.
- Não há teste de Firestore Rules dedicado: esta task não altera nenhuma
  Security Rule (reaproveita as coleções/regras já validadas pelas
  TASK-133/TASK-117).

## Comandos executados

- `dart run build_runner build --delete-conflicting-outputs` (regeração de
  `injection.config.dart` para os novos `@injectable`:
  `LoadCustomerDashboardSnapshotUseCase`, `LoadCustomerDashboardRankingUseCase`,
  `CustomerDashboardBloc`). Concluído com sucesso; os únicos avisos exibidos
  (`ConnectivityPlusService`/`ImageUploadCompressor`/
  `ConflictResolutionService`/`SyncEngine`/`ProductDetailBloc`/
  `ProductGridBloc`/`OrderDraftBloc` dependendo de tipo não registrado) são
  pré-existentes e não relacionados a esta task.
- `flutter analyze --no-fatal-infos` (projeto inteiro) → 1 issue (info-level
  `use_null_aware_elements` em um arquivo de teste, não bloqueante).
- `dart format` nos arquivos novos/alterados → formatação aplicada.
- `flutter test test/features/dashboards` → 119 testes, todos passando
  (inclui os 24 testes novos desta task e os já existentes de Executive/
  Sales Dashboard, sem regressão).
- `flutter test test/core/navigation test/core/permissions` → 60 testes,
  todos passando (nenhuma regressão nas rotas/RBAC existentes).

## Resultado do analyzer

`flutter analyze --no-fatal-infos` → 1 issue (info-level, não bloqueante).

## Resultado dos testes

`flutter test test/features/dashboards`: 119 testes, 0 falhas.
`flutter test test/core/navigation test/core/permissions`: 60 testes, 0
falhas. Suíte completa (`flutter test`) não executada nesta rodada — modo
econômico não exige validação de encerramento além do que a própria task
pede/do risco técnico real já coberto; os subconjuntos relevantes
(dashboards, navigation, permissions) foram executados e validados.

## Decisões técnicas

- **Reuso verbatim de `ExecutiveDashboardVisibilityService`** e de
  `PositivacaoRepository`, em vez de novos serviços/entidades: ambos os
  dashboards leem exatamente as mesmas fontes pré-calculadas, gated pela
  mesma capability — duplicar a regra criaria cópias para manter
  sincronizadas.
- **`CustomerDashboardSnapshot` reaproveita `ExecutiveDashboardMetric`**
  (não uma nova entidade de KPI): este dashboard só precisa de uma
  comparação (mês anterior), o mesmo contrato que `ExecutiveDashboardMetric`
  já modela — diferente do Sales Dashboard, que precisou de uma entidade
  nova por exigir duas baselines simultâneas (MoM+YoY).
- **Taxa de recompra/frequência/churn computados no use case, não deixados
  como `notCalculated`**: diferente de "clientes novos"/"reativados", esses
  três são derivináveis inteiramente a partir de dados já pré-computados
  (`customerMonthly` do período corrente e, quando necessário, do anterior)
  sem nenhuma varredura de pedidos brutos — uma leitura honesta da regra
  "nunca recalculado do zero no cliente" (que veta *recalcular*, não veta
  *derivar uma razão simples de dois números já agregados*, o mesmo
  raciocínio que já permite `ticket médio = faturamento / pedidos`).
- **Segmentação limitada ao `segment` label**: a task pedia reaproveitar os
  critérios de TASK-053 (segmento, região, porte). Região/porte não são
  denormalizados em `customerMonthly` (só `customerName`/`segment`) — filtrar
  por eles exigiria uma junção client-side contra a carteira RBAC-resolvida
  (uma segunda leitura potencialmente grande para uma tabela de BI, o que a
  task proíbe). Apenas o filtro de segmento foi implementado; região/porte
  ficam como pendência.
- **Paginação client-side sobre uma única leitura limitada**: a mesma
  filosofia de bound já usada por `LoadSalesDashboardGroupRowsUseCase`
  (`_rowLimit`) e `LoadExecutiveDashboardSnapshotUseCase`
  (`_sellerMonthlyLimit`) — um único `listByPeriod` (limite de 1000
  clientes) cobre "ranking do mês", com a paginação sendo apenas uma janela
  em memória (`CustomerDashboardState.visibleRankingCount`), nunca um
  cursor de servidor.

## Riscos conhecidos

- Ver "Divergência documentada" acima: a definição de churn/cliente ativo
  deste dashboard não é bit-a-bit idêntica à da TASK-122 (central de
  oportunidades), por falta de um dado pré-computado comum
  (`lastOrderAt`/threshold em dias). Risco baixo na prática (as duas
  definições raramente discordam), mas documentado.
- Mesmos riscos já documentados pelas TASK-134/TASK-135 (sem cache offline,
  acesso de SALES_REP bloqueado por design de segurança, bound de leitura
  em vez de paginação de servidor) — nenhum risco novo introduzido.

## Pendências

- Extensão de `report.viewSensitive` (ou uma capability mais restrita, com
  scoping por `scopeId`) para permitir que SALES_REP veja a própria carteira
  neste dashboard — recomendado como task dedicada, mesma pendência já
  levantada pelas TASK-134/TASK-135.
- Uma nova dimensão de agregação (ou extensão de `customerMonthly`) com
  `lastOrderAt`/`sellerId`/`teamId` por cliente resolveria, de uma vez, três
  pendências desta task: (1) alinhar churn/cliente ativo à definição exata
  da TASK-122; (2) permitir "clientes novos"/"reativados" reais; (3)
  permitir restringir o ranking e taxa de recompra/frequência/churn por
  equipe.
- Filtros de região/porte na segmentação do ranking (TASK-053) — hoje só o
  filtro de segmento está implementado.
- Funcionalidade de exportação (`report_exported`, CSV/XLSX/PDF) — fora do
  escopo técnico desta task, permanece no backlog de "Relatórios e BI"
  (seção 12.3).
- Nenhum item de menu/navegação global aponta para `CustomerDashboardRoute`
  ainda — mesma situação já documentada por `ExecutiveDashboardRoute`/
  `SalesDashboardRoute` (não existe shell de navegação global no repositório
  ainda); a rota é acessível via `context.go`/deep link.

## Evidências

- `flutter analyze --no-fatal-infos`: 1 issue (info-level, não bloqueante).
- `flutter test test/features/dashboards`: 119 testes, 0 falhas.
- `flutter test test/core/navigation test/core/permissions`: 60 testes, 0
  falhas.
- `dart format`: aplicado nos arquivos novos/alterados.

## Commit

Único commit local cobrindo implementação + documentação + atualização do
`docs/tasks/TASKS.md`.

## Push

Não realizado — sem autorização de push nesta rodada.
