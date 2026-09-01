# TASK-116 — Implementar dashboard de atingimento (CONCLUÍDA)

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### RBAC (`lib/core/permissions/`)

- `Capability.targetView` (nova): gate de "pode abrir o dashboard de
  atingimento", separado de `Capability.targetManage` (cadastro/edição,
  TASK-115) — mesmo formato de duas camadas que `Capability.orderView` +
  `OrderVisibilityService` já usam para Order. Concedida a
  `OWNER`/`ADMIN` (via conjunto completo/quase-completo), e explicitamente a
  `SALES_MANAGER` e `SALES_REP`; **não** concedida a
  `SALES_ASSISTANT`/`FINANCE`/`READ_ONLY`.
- `TargetDashboardPage` usa `PermissionBuilder(capability:
  Capability.targetView)` — quem não tem a capability nunca alcança a
  página, igual ao padrão de `TargetFormPage`.

### Domínio — visibilidade por dimensão (`lib/features/targets/domain/`)

- `TargetVisibilityMode`/`TargetVisibilityFilter` (novos): mesmo formato de
  `OrderVisibilityMode`/`OrderVisibilityFilter` (TASK-102), mas resolvendo
  **quais `dimensionType`/`dimensionId` de `Target`** o chamador pode ver —
  não apenas "quais pedidos". `canView(dimensionType, dimensionId)` decide:
  - `allOrganization` (OWNER/ADMIN): qualquer dimensão.
  - `teams` (SALES_MANAGER): a própria meta (`salesRep` = o próprio id),
    a meta de qualquer integrante das equipes que gerencia, as próprias
    equipes (`team`), e qualquer meta de `company`/`collection`/`category`
    (não são amarradas a uma pessoa).
  - `ownOnly` (SALES_REP): apenas a própria meta (`salesRep` = o próprio
    id) — nunca a de outro vendedor, nem a de equipe/empresa. O carve-out
    "e a de sua equipe se explicitamente permitido" citado na task não tem
    nenhum toggle de `OrganizationSettings` para ler ainda (mesma lacuna já
    documentada por `Capability.targetManage` na TASK-115), então fica
    fora de escopo aqui também, deliberadamente.
  - `none`: sem Membership ativa, ou role sem `targetView`.
- `TargetVisibilityService` (novo, `@injectable`): resolve o
  `TargetVisibilityFilter` reaproveitando `PortfolioVisibilityService`
  (TASK-051) para o mesmo branching OWNER/ADMIN/SALES_MANAGER/SALES_REP —
  nunca reimplementado — e resolvendo os `teamIds` do manager em
  `teamMemberIds` concretos via `TeamRepository.listByOrganization` +
  `Team.memberIds`, no mesmo molde de `OrderVisibilityService`.

### Domínio — cálculo de atingimento (`lib/features/targets/domain/`)

- `TargetAchievementSnapshot` (novo): `realizedValue`/`calculatedAt`
  sempre ambos `null` ou ambos preenchidos — `null` significa "nenhuma
  agregação server-side calculou isso ainda" (estado real e esperado hoje,
  já que nenhuma task antes desta liga `Target` a um pipeline de
  agregação), nunca "realizado zero".
- `TargetAchievementRepository` (novo contrato): `getForTarget`/
  `watchForTarget`. Documentado como o "seam" único que
  `UpdateTargetUseCase.currentAchievedValue` (TASK-115) já antecipava
  ("e.g. from the TASK-116 dashboard's local cache").
- `TargetProgressViewModel` (novo, função pura `compute(...)`): realizado,
  gap absoluto/percentual, atingimento %, % do período decorrido e uma
  projeção linear simples (`realizado / fração decorrida do período`).
  `now`/`calculatedAt` são sempre injetados pelo chamador — nunca lidos
  internamente — o que manteve a função 100% testável sem mocks. Trata
  explicitamente meta zerada (sem divisão por zero), realizado > meta
  (gap negativo, atingimento > 100%, sem clamp), período ainda não
  iniciado (0% decorrido, sem extrapolar do zero) e período já encerrado
  (100% decorrido, projeção = valor final, sem re-extrapolar).

### Dados (`lib/features/targets/data/` e `lib/core/database/`)

- `AppDatabase.getTargetById`/`watchTargetById` (novos): leem uma única
  linha de `TargetsTable` por `id` (escopada por `organizationId`,
  defesa em profundidade). `watchTargetById` é a fonte do "near real-time"
  do dashboard — reemite sempre que uma sincronização futura sobrescrever a
  linha (ex.: um `achievedValueCache` mais novo após um pull), sem polling.
- `DriftTargetAchievementRepository` (novo, `@LazySingleton`): implementação
  concreta de `TargetAchievementRepository` lendo exatamente a coluna
  `achievedValueCache`/`updatedAt` que os próprios comentários de
  `TargetsTable` (TASK-114) já reservavam para este dashboard — nunca soma
  pedidos brutos no cliente. Uma linha ausente e uma `achievedValueCache`
  nula resolvem para o mesmo snapshot "não calculado".

### Apresentação (`lib/features/targets/presentation/`)

- `TargetDashboardCubit`/`TargetDashboardState` (novos): `load(...)`
  resolve a visibilidade e carrega por padrão a própria dimensão
  `salesRep` do chamador (a visão "minha meta", garantida para qualquer
  papel que alcance a página). `selectDimension(...)` troca de
  dimensão/métrica, **re-checando `TargetVisibilityFilter.canView` no
  domínio** antes de carregar — nunca assumindo que a UI já escondeu uma
  opção fora do alcance do usuário. `selectPeriod(...)` troca de período já
  listado, reassinando o stream de `TargetAchievementRepository
  .watchForTarget` e recomputando `TargetProgressViewModel.compute` a cada
  emissão — o mecanismo de atualização near real-time da task.
- `TargetDashboardPage` (novo): KPIs (Meta, Realizado, Gap, Atingimento)
  com `AppKpiCard`, gráfico de evolução (Meta / Realizado / Projeção) com
  `AppManagementChart` (reaproveitando os componentes do Design System da
  TASK-023, nenhum novo componente de gráfico/KPI criado), legenda textual
  explicando a pergunta de negócio respondida pelo gráfico, texto de
  período de referência e do horário do último cálculo (ou aviso de
  "cálculo ainda não disponível" quando `achievedValueCache` é nulo),
  filtros de métrica/dimensão/período via `AppAdminPageLayout.
  filtersBuilder` (dimensão só aparece para quem `canPickDimension`, isto
  é, OWNER/ADMIN/SALES_MANAGER — nunca para SALES_REP). Protegida por
  `PermissionBuilder(capability: Capability.targetView)`.
- `AnalyticsEvents.targetDashboardViewed` (novo): logado uma vez por troca
  de dimensão (nunca a cada tick de sincronização, para não inundar a
  taxonomia).
- `Barrel targets.dart` atualizado com os novos exports.

## Arquivos criados

- `lib/features/targets/domain/entities/target_achievement_snapshot.dart`
- `lib/features/targets/domain/entities/target_progress_view_model.dart`
- `lib/features/targets/domain/entities/target_visibility_filter.dart`
- `lib/features/targets/domain/repositories/target_achievement_repository.dart`
- `lib/features/targets/domain/services/target_visibility_service.dart`
- `lib/features/targets/data/repositories/drift_target_achievement_repository.dart`
- `lib/features/targets/presentation/cubit/target_dashboard_cubit.dart`
- `lib/features/targets/presentation/cubit/target_dashboard_state.dart`
- `lib/features/targets/presentation/pages/target_dashboard_page.dart`
- `test/features/targets/domain/entities/target_progress_view_model_test.dart`
- `test/features/targets/domain/services/target_visibility_service_test.dart`
- `test/features/targets/data/repositories/drift_target_achievement_repository_test.dart`
- `test/features/targets/presentation/pages/target_dashboard_page_test.dart`
- `docs/tasks/TASK-116-implementar-dashboard-de-atingimento-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/permissions/capability.dart` (novo `Capability.targetView`)
- `lib/core/permissions/role_permission_matrix.dart` (`targetView` para `SALES_MANAGER`/`SALES_REP`)
- `lib/core/analytics/analytics_events.dart` (`targetDashboardViewed`)
- `lib/core/database/app_database.dart` (`getTargetById`/`watchTargetById`)
- `lib/features/targets/targets.dart` (novos exports)
- `lib/app/injection.config.dart` (gerado pelo `build_runner`, registra `TargetVisibilityService`/`DriftTargetAchievementRepository`/`TargetDashboardCubit`)
- `test/core/permissions/role_permission_matrix_test.dart` (assert `targetView` por papel)
- `test/core/analytics/analytics_events_test.dart` (novo evento na lista fixa)
- `docs/tasks/TASKS.md` (checkbox da TASK-116 e progresso 115/220 → 116/220)

## Validações executadas

- `dart run build_runner build` — sucesso, regenerou `lib/app/injection.config.dart` com os novos registros de DI (os avisos de "missing dependencies" impressos pelo `injectable_generator` são pré-existentes, não relacionados a esta task — nenhum deles cita algo criado aqui).
- `flutter analyze` (projeto completo) — sem issues.
- `dart format --output=none --set-exit-if-changed .` — sem alterações pendentes (1848 arquivos, 0 alterados).
- `flutter test test/features/targets test/core/permissions test/core/analytics test/core/database` — 145 testes, todos passando.
- `flutter test` (suíte completa) — 2353 testes, todos passando.

## Decisões e riscos conhecidos

- **`achievedValueCache` fica quase sempre nulo hoje, para qualquer meta
  criada pelo fluxo atual**: `Target` (TASK-114/115) ainda é persistido só
  via `SharedPreferencesTargetRepository` (local-only, sem Firestore/Outbox
  — ver pendência já registrada na TASK-115), e nenhuma Cloud
  Function/pipeline de BI escreve em `TargetsTable.achievedValueCache`
  ainda. Ou seja: o dashboard implementado aqui é funcional e correto, mas
  hoje renderiza principalmente o estado "cálculo ainda não disponível"
  (`TargetDashboardStatus.notCalculated`) para qualquer meta recém-criada
  na tela de cadastro, já que ela nunca chega a existir na tabela Drift que
  `DriftTargetAchievementRepository` lê. Isso é consistente com — e não
  contorna — a regra "cálculo de atingimento nunca é feito só no cliente
  somando documentos brutos": a alternativa seria violar essa regra
  explícita da task. Fica registrada como pendência real de infraestrutura
  para uma task futura (a primeira a de fato construir a agregação
  server-side de pedidos faturados/aprovados por dimensão/período — Cloud
  Function ou snapshot — e a escrever o resultado em
  `TargetsTable.achievedValueCache`/backend equivalente, junto da primeira
  vez que `Target` for ligado a Firestore/Outbox).
- **Gráfico de evolução é uma aproximação de 2-3 pontos, não uma série
  diária real**: sem uma agregação por dia/semana disponível (só existe um
  único valor "realizado até agora"), o gráfico mostra Meta (linha de
  referência constante), Realizado (0 no início → valor atual hoje) e
  Projeção (valor atual hoje → projeção linear no fim do período) — 3
  séries de até 3 pontos, não uma curva diária de acumulado. Isso cumpre a
  letra da task ("gráfico de evolução acumulada... comparado à linha de
  meta") com os dados hoje disponíveis, mas é visualmente mais simples do
  que uma série temporal densa seria. `AppManagementChart` (TASK-023)
  também não suporta um estilo tracejado para diferenciar visualmente
  "realizado" de "projeção" (só cor/legenda) — uma melhoria de design
  dedicada (`flutter-ui-design-specialist`) poderia refinar isso quando uma
  série diária real existir.
- **Seleção de dimensão por id digitado, não por busca/autocomplete**: os
  filtros reaproveitam o mesmo padrão já usado por `TargetFormPage`
  (TASK-115) — dropdown de `TargetDimensionType` + campo de texto livre
  para o id. Um seletor com busca por nome (vendedor/equipe) melhoraria a
  UX, mas não estava listado como exigência explícita da task; mesma
  pendência já registrada na TASK-115, agora também válida aqui.
- **RBAC de "gestor vê equipe/empresa" cobre `salesRep`/`team` pelos
  membros/equipes geridos, e `company`/`collection`/`category` para
  qualquer gestor da organização**: a task não detalha uma regra granular
  por empresa/coleção/categoria (essas dimensões não são amarradas a uma
  pessoa/equipe específica), então qualquer `SALES_MANAGER` pode ver metas
  nessas três dimensões — mesmo raciocínio já usado para `reportExport`/
  `reportViewSensitive`, capabilities de relatório cross-cutting que todo
  `SALES_MANAGER` já tem na matriz atual. Uma regra mais fina (ex.: só a
  empresa/filial do próprio gestor) fica como possível refinamento futuro
  se o negócio pedir.
- **`TargetAchievementRepository.getForTarget` (leitura única) existe no
  contrato mas não é chamado por `TargetDashboardCubit` hoje** — o cubit
  usa só `watchForTarget` (stream), que já emite o valor atual imediatamente
  na assinatura. `getForTarget` fica disponível para um uso futuro pontual
  (ex.: `TargetFormCubit` pré-carregando `currentAchievedValue` ao editar
  uma meta, exatamente o cenário que a doc do TASK-115 já previa), sem
  exigir mudança de contrato quando essa integração for feita.

Nenhum teste, análise ou comando foi apenas assumido: todos os comandos
listados em "Validações executadas" foram executados nesta sessão e
retornaram sucesso.
