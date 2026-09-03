# TASK-134 — Implementar dashboard executivo — CONCLUÍDA

**Epic:** EPIC-17 — Dashboards e BI
**Agentes:** `flutter-senior-architect`, `flutter-ui-design-specialist`

## Resumo

Implementado o Executive Dashboard (seção 12.1/12.2 de `tasks.md`): a primeira tela de
`lib/features/dashboards/presentation/`, consumindo exclusivamente snapshots pré-computados
(`AggregationRepository` da TASK-133, `PositivacaoRepository` da TASK-117, `TargetRepository`/
`TargetAchievementRepository` da TASK-116) — nenhuma query bruta de `orders`/`customers`/`products`
em nenhum ponto do fluxo — com filtros globais de mês/empresa/equipe refletidos na URL do Flutter Web,
comparação com o período anterior em todo KPI e um atalho para a Central de Oportunidades (TASK-132)
destacando os insights de maior impacto do período filtrado.

## Decisões de escopo

### Granularidade mensal única para o filtro de período

O filtro de período é um único mês calendário (`ExecutiveDashboardFilters.year`/`month`, navegável por
setas "mês anterior"/"próximo mês", nunca além do mês corrente), não um range arbitrário de datas. Isso
porque quatro das cinco dimensões de agregação da TASK-133 (`customerMonthly`/`productMonthly`/
`sellerMonthly`/`regionMonthly`) já são mensais; ancorar o filtro no mesmo grão evita qualquer
re-bucketização client-side dessas dimensões. A "comparação com o período anterior" pedida no escopo
técnico cai naturalmente no mês calendário anterior (MoM); "crescimento YoY" compara com o mesmo mês do
ano anterior — ambos exibidos como cards de KPI dedicados, além do badge de variação percentual (MoM)
já embutido nos cards de Faturamento/Pedidos/Ticket médio/Clientes ativos (`AppKpiCard.trendPercentage`).

### "Clientes novos" — exibido, porém sempre "cálculo ainda não disponível"

Nenhuma fonte de dado hoje distingue "cliente que comprou pela primeira vez neste período": as cinco
dimensões da TASK-133 não carregam essa informação, e `Customer.createdAt` é a data de cadastro no
sistema, não a de primeira compra — usá-lo exigiria escanear o histórico de pedidos do cliente no
cliente, exatamente o que a regra "Dashboard nunca executa cálculo pesado no cliente" desta task proíbe.
Em vez de omitir o KPI (o que contradiria "todos os KPIs... são exibidos") ou fabricar um `0`,
`ExecutiveDashboardSnapshot.newCustomers` é sempre `ExecutiveDashboardMetric.notCalculated()`, exibido
com o texto "Cálculo ainda não disponível" — mesmo padrão de UX que `PositivacaoSnapshot.notCalculated`/
`TargetAchievementSnapshot` (`realizedValue == null`) já estabelecem para "pipeline ainda não existe".
Fica como pendência explícita (ver seção própria abaixo) para uma extensão futura da agregação.

### Filtro de equipe — limitado às KPIs que já têm dimensão nativa de equipe

TASK-133 modelou exatamente cinco dimensões de agregação e nenhuma delas é "por equipe" (só
`sellerMonthly`, por vendedor). Por isso, quando o filtro de equipe está ativo:

- **Faturamento/pedidos/ticket médio/crescimento MoM/YoY**: somados a partir dos snapshots
  `sellerMonthly` de cada vendedor membro da equipe filtrada (`AggregationRepository.listByPeriod`,
  uma única leitura limitada a 500 vendedores, filtrada client-side aos `memberIds` da equipe — nunca
  um fan-out de leituras por vendedor). Sem filtro de equipe, esses mesmos KPIs usam `salesDaily`
  (escopo empresa, exato, uma leitura por range de dias do mês).
- **Positivação de carteira / atingimento de meta**: `PositivacaoDimensionType`/`TargetDimensionType`
  já modelam `team` nativamente (TASK-116/TASK-117, independente da TASK-133), então esses dois KPIs
  são recalculados de verdade para a equipe quando o filtro está ativo.
- **Clientes ativos/clientes novos e o sparkline de tendência diária**: permanecem sempre no nível da
  empresa mesmo com filtro de equipe ativo — nem `salesDaily` (usado no sparkline) nem `customerMonthly`
  (usado para clientes ativos, hoje calculado apenas via `PositivacaoSnapshot`, não por essa dimensão)
  carregam uma dimensão de equipe. Documentado inline em
  `LoadExecutiveDashboardSnapshotUseCase`'s próprio doc comment.

### Capability reaproveitada, nenhuma nova

A página é protegida por `Capability.reportViewSensitive` — a mesma capability que `firestore.rules`
já exige para ler qualquer uma das cinco coleções de agregação da TASK-133. Isso evita capability
sprawl: um papel que já não pode ler os dados agregados no servidor não teria por que enxergar uma tela
cujo único propósito é mostrar exatamente esses dados. Hoje essa capability já é concedida a
OWNER/ADMIN/SALES_MANAGER/FINANCE (`RolePermissionMatrix`), alinhado com "destinado a OWNER/ADMIN e
gestores seniores" do Objetivo desta task.

*Qual* empresa/equipe o filtro pode selecionar é uma decisão separada, resolvida por um novo serviço,
`ExecutiveDashboardVisibilityService` (não reaproveita `PortfolioVisibilityService`/
`TargetVisibilityService`: nenhum dos dois modela FINANCE como visão consolidada, que é o comportamento
correto aqui) — OWNER/ADMIN/FINANCE veem qualquer empresa/equipe da organização; SALES_MANAGER só as
empresas/equipes que gerencia; qualquer outro papel (sem `reportViewSensitive`, portanto já bloqueado
pelo `PermissionBuilder` da própria página) resolve para `none`.

## O que foi implementado

### Domain (`lib/features/dashboards/domain/`)

- `entities/executive_dashboard_filters.dart` — mês/empresa/equipe, serialização de/para query
  parameters (mesmo contrato de `OpportunityCenterFilters`), `previousMonth`/`previousYear`/`isAfter`.
- `entities/executive_dashboard_metric.dart` — o valor de um KPI com três estados possíveis
  (`available`/`notCalculated`/`failed`) e `changePercentage` (nunca `NaN`/`Infinity`).
- `entities/executive_dashboard_trend_point.dart`, `entities/executive_dashboard_snapshot.dart` — os
  nove KPIs do escopo técnico (faturamento, pedidos, ticket médio, clientes ativos, clientes novos,
  positivação, atingimento de meta, crescimento MoM, crescimento YoY) + sparkline diário.
- `entities/executive_dashboard_visibility_filter.dart` +
  `services/executive_dashboard_visibility_service.dart` — RBAC de escopo (ver seção acima).
- `usecases/load_executive_dashboard_snapshot_use_case.dart` — orquestra `AggregationRepository`/
  `PositivacaoRepository`/`TargetRepository`/`TargetAchievementRepository`; cada KPI degrada
  independentemente em caso de falha de uma fonte específica (nunca falha o `AppResult` inteiro por uma
  fonte com problema).

### Presentation (`lib/features/dashboards/presentation/`)

- `bloc/executive_dashboard_bloc.dart` (+ event/state) — resolve visibilidade, lista
  empresas/equipes selecionáveis (`CompanyRepository`/`TeamRepository`, filtrados pelo
  `ExecutiveDashboardVisibilityFilter`), carrega o snapshot de KPIs, carrega o atalho de insights
  (reaproveitando `ListOpportunityCenterInsightsUseCase` da TASK-132, nunca uma segunda regra de
  visibilidade), e registra `dashboard_viewed` (`dashboard_type: executive`) a cada carregamento/troca
  de filtro.
- `pages/executive_dashboard_page.dart` — `PermissionBuilder` + `AppAdminPageLayout` (filtros
  empresa/equipe/mês num painel lateral em desktop, bottom sheet em mobile/tablet — grátis via
  `AppAdminPageLayout`, já testado nas demais telas administrativas); grid de `AppKpiCard` (via `Wrap`,
  reflow automático mobile empilhado / desktop lado a lado); `AppManagementChart` (linha) para o
  sparkline de faturamento diário, com alternativa em tabela e resumo textual acessível já embutidos no
  próprio componente; card de atalho para a Central de Oportunidades.

### Navegação/DI/Analytics

- `ExecutiveDashboardRoute` (`lib/core/navigation/app_route_paths.dart`) +
  `executiveDashboardPageBuilder`/`GoRoute` (`app_router.dart`, protegido por
  `Capability.reportViewSensitive`) + wiring em `bootstrap.dart`.
- `AnalyticsEvents.dashboardViewed` (`dashboard_viewed`) — evento novo, deliberadamente compartilhado
  por todo dashboard do EPIC-17 (TASK-135 a TASK-143 devem reaproveitá-lo, nunca criar
  `*_dashboard_viewed` próprio, ao contrário do que EPIC-15 fez antes dessa convenção existir).
- DI: `AggregationRepositoryImpl`/`FirestoreAggregationDataSource`/`AggregationSnapshotMapper` (TASK-133)
  finalmente anotados (`@LazySingleton`/`@injectable`) e registrados — a própria TASK-133 documentou que
  isso ficaria para "a primeira task de dashboard que consumir este repositório", que é esta. Mais
  `ExecutiveDashboardVisibilityService`, `LoadExecutiveDashboardSnapshotUseCase`,
  `ExecutiveDashboardBloc` (`@injectable`). `build_runner` executado, `injection.config.dart`
  regenerado.

## Testes

- `test/features/dashboards/domain/entities/executive_dashboard_filters_test.dart` (9 casos): grão
  mensal, rollover ano/mês, `isAfter`, round-trip de query parameters, fallback de mês
  malformado/ausente.
- `test/features/dashboards/domain/entities/executive_dashboard_metric_test.dart` (7 casos):
  `changePercentage` sucesso/negativo/`previousValue` nulo/`previousValue` zero (nunca
  `NaN`/`Infinity`), estados `notCalculated`/`failed`.
- `test/features/dashboards/domain/services/executive_dashboard_visibility_service_test.dart`
  (13 casos): OWNER/ADMIN/FINANCE → `allOrganization`; SALES_MANAGER → `ownScope` limitado às
  próprias equipes/empresas; SALES_REP/SALES_ASSISTANT/READ_ONLY/sem Membership/Membership inativa →
  `none`; falha do repositório de Membership/Team propagada como `AppFailure`.
- `test/features/dashboards/domain/usecases/load_executive_dashboard_snapshot_use_case_test.dart`
  (14 casos): validação de payload; período vazio (zero disponível, nunca "não calculado"); dados
  completos (soma exata de faturamento/pedidos/ticket médio, crescimento MoM/YoY, positivação,
  atingimento de meta, sparkline); **falha parcial** — falha de agregação nunca contamina
  positivação/meta e vice-versa, falha isolada do mês de comparação degrada só o `changePercentage`
  sem falhar o valor atual; filtro de equipe (soma restrita aos `sellerMemberIds`, equipe vazia nunca
  chama o repositório).
- `test/features/dashboards/presentation/bloc/executive_dashboard_bloc_test.dart` (8 casos): papel sem
  `report.viewSensitive` → forbidden; carregamento completo + evento `dashboard_viewed`; fallback para
  a primeira empresa permitida quando o filtro inicial aponta para escopo fora do alcance do
  SALES_MANAGER; troca de filtro para um escopo fora do `ownScope` é ignorada; troca de mês recarrega;
  falha ao listar empresas vira estado de erro; retry recarrega; atalho de insights ordenado por
  impacto e filtrado ao período.
- `test/features/dashboards/presentation/pages/executive_dashboard_page_test.dart` (9 casos): loading;
  capability gate bloqueia SALES_REP (página nunca alcançada); todos os nove KPIs renderizados;
  "clientes novos" sempre "cálculo ainda não disponível"; atalho abre a Central de Oportunidades;
  gráfico com resumo textual acessível (`Semantics.label` contendo "Gráfico de linha"); layout mobile
  (KPIs empilhados, `dy` diferente), desktop (lado a lado, mesmo `dy`) e tablet (sem overflow).
- `test/core/analytics/analytics_events_test.dart` — atualizado com `dashboard_viewed`.

Comandos executados: `flutter test test/features/dashboards/ test/core/analytics/` →
**83/83 passando**. `flutter test` completo do projeto → **2595/2595 passando** (nenhuma regressão).
`flutter analyze` (projeto inteiro) → nenhum problema. `dart format` nos arquivos tocados por esta
task → sem alterações pendentes (um `dart format lib test` amplo também reformatou 4 arquivos
pré-existentes não relacionados a esta task — revertidos via `git checkout --` para manter o commit
escopado).

## Critérios de aceite (checagem)

- Os nove KPIs relevantes ao nível executivo (faturamento, pedidos, ticket médio, clientes ativos,
  clientes novos, crescimento MoM, crescimento YoY, atingimento de meta consolidado, positivação de
  carteira) são exibidos, cada um com comparação ao período anterior quando disponível (ou um estado
  "não calculado" honesto, nunca um zero fabricado).
- Filtros globais de mês/empresa/equipe funcionam e refletem na URL no Flutter Web
  (`ExecutiveDashboardRoute.queryParameters`, `ExecutiveDashboardFilters.toQueryParameters`/
  `fromQueryParameters`).
- Nenhuma query bruta client-side é executada — todo valor vem de snapshots pré-calculados
  (`AggregationRepository`/`PositivacaoRepository`/`TargetRepository`/`TargetAchievementRepository`).
- Atalho para a Central de Oportunidades exibe os insights de maior impacto do período filtrado,
  reaproveitando a mesma regra de visibilidade da TASK-132.

## Arquivos criados/alterados

- `lib/features/dashboards/domain/entities/executive_dashboard_filters.dart` (novo)
- `lib/features/dashboards/domain/entities/executive_dashboard_metric.dart` (novo)
- `lib/features/dashboards/domain/entities/executive_dashboard_snapshot.dart` (novo)
- `lib/features/dashboards/domain/entities/executive_dashboard_trend_point.dart` (novo)
- `lib/features/dashboards/domain/entities/executive_dashboard_visibility_filter.dart` (novo)
- `lib/features/dashboards/domain/services/executive_dashboard_visibility_service.dart` (novo)
- `lib/features/dashboards/domain/usecases/load_executive_dashboard_snapshot_use_case.dart` (novo)
- `lib/features/dashboards/presentation/bloc/executive_dashboard_{bloc,event,state}.dart` (novo)
- `lib/features/dashboards/presentation/pages/executive_dashboard_page.dart` (novo)
- `lib/features/dashboards/dashboards.dart` (alterado — exporta os arquivos acima)
- `lib/features/dashboards/data/{datasources/firestore_aggregation_data_source,mappers/aggregation_snapshot_mapper,repositories/aggregation_repository_impl}.dart`
  (alterados — anotações de DI, TASK-133 as havia deixado pendentes)
- `lib/core/navigation/app_route_paths.dart` (alterado — `ExecutiveDashboardRoute`)
- `lib/core/navigation/app_router.dart` (alterado — builder + `GoRoute`)
- `lib/app/bootstrap.dart` (alterado — wiring do builder)
- `lib/core/analytics/analytics_events.dart` (alterado — `dashboardViewed`)
- `lib/app/injection.config.dart` (regenerado via `build_runner`)
- `test/features/dashboards/domain/entities/*.dart` (novo)
- `test/features/dashboards/domain/services/*.dart` (novo)
- `test/features/dashboards/domain/usecases/*.dart` (novo)
- `test/features/dashboards/presentation/bloc/*.dart` (novo)
- `test/features/dashboards/presentation/pages/*.dart` (novo)
- `test/core/analytics/analytics_events_test.dart` (alterado)

## Pendências e riscos

- **"Clientes novos" não é calculado** (ver seção de decisão acima) — recomenda-se uma task dedicada
  que estenda `customerMonthly` (TASK-133) com um sinal de primeira compra, ou modele uma nova dimensão
  de aquisição de clientes, antes de tentar preencher esse KPI.
- O "atingimento de meta consolidado" resolve o primeiro `Target` cujo período contém o mês filtrado;
  se a organização cadastrar metas trimestrais/anuais, o valor exibido é o da meta inteira, não uma
  fração proporcional ao mês — mesma limitação que `TargetDashboardCubit` já aceita para seu próprio
  "atingimento".
- O filtro de equipe é uma soma de `sellerMonthly` limitada a 500 vendedores por leitura
  (`AggregationRepository.listByPeriod`); uma organização com mais vendedores ativos que isso em um
  único mês precisaria desse limite revisitado (documentado em código).
- Testes de Firebase Emulator Suite/Cloud Functions não se aplicam a esta task (nenhuma Cloud Function
  nova) — nenhuma pendência nesse eixo.
