# TASK-118 — Implementar ranking comercial (CONCLUÍDA)

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### Configuração por organização (`lib/features/organizations/domain/`)

- `OrganizationSettings` (estendido, nunca um novo doc/coleção): 1 novo campo
  — `rankingVisibilityMode` (código string `full_ranking`/
  `relative_position_only`, default `full_ranking`). Reaproveita o mesmo
  pipeline já testado de `OrganizationSettings.validated`/
  `OrganizationSettingsDto`/`OrganizationMapper`/
  `UpdateOrganizationSettingsUseCase` que TASK-117 já usou para
  `positivacaoPeriodGranularity` — a mesma técnica de desacoplamento
  (string livre validada contra um `Set<String>` conhecido, nunca um enum de
  `targets` importado em `organizations`) evita que `organizations` dependa
  de `targets`. `OrganizationSettings.validated` rejeita qualquer código
  desconhecido.

### Domínio — quem são os pares e o que cada um pode ver (`lib/features/targets/domain/`)

- `RankingDimensionType` (novo enum, `salesRep`/`team`): deliberadamente mais
  estreito que `TargetDimensionType` (mesma técnica de
  `PositivacaoDimensionType`, TASK-117) — o escopo da task só pede "vendedor
  individual vs. equipe". `asTargetDimensionType` mapeia para o enum do
  TASK-116, reaproveitando `TargetRepository`/`TargetVisibilityFilter` sem
  duplicar nada.
- `RankingVisibilityMode` (novo enum, `fullRanking`/`relativePositionOnly`):
  parseia `OrganizationSettings.rankingVisibilityMode` com fallback seguro
  para `fullRanking` (nunca lança exceção), mesmo padrão de
  `PositivacaoSettings.fromOrganizationSettings`.
- `RankingAccessLevel` (novo enum + `resolve(...)`): combina **quem** o
  chamador é (`TargetVisibilityMode` do TASK-116) com **o que** a
  organização configurou (`RankingVisibilityMode`). Regra determinística e
  testada: `allOrganization`/`teams` (OWNER/ADMIN/SALES_MANAGER) sempre
  resolvem para `full`, incondicionalmente — a organização nunca restringe
  esses papéis. Só `ownOnly` (SALES_REP) é decidido pela configuração da
  organização. Esta é a função central da regra de negócio "SALES_MANAGER/
  ADMIN veem o ranking completo... SALES_REP vê apenas sua posição relativa
  ... conforme configuração da organização".
- `RankingPeerScope`/`RankingPeerResolverService` (novos): resolvem **quem
  são os pares** a comparar — uma pergunta distinta de "que dimensão posso
  consultar" (`TargetVisibilityFilter`, TASK-116). Regras (todas cobertas
  por teste, ver abaixo): OWNER/ADMIN comparam todos os `SALES_REP`
  ativos da organização (ou todas as equipes, para ranking por equipe);
  SALES_MANAGER compara exatamente `TargetVisibilityFilter.teamMemberIds`
  (nunca re-derivado); SALES_REP compara todos os membros de toda equipe a
  que pertence (ou apenas a si mesmo, se ainda não estiver em nenhuma
  equipe — nunca um ranking vazio só por isso); um SALES_REP nunca ranqueia
  por equipe (`RankingDimensionType.team`), mesmo que a UI de alguma forma
  peça — defesa em profundidade. Este é o limite crítico de RBAC: um par
  nunca resolvido aqui nunca pode vazar para um ranking, independente do
  que `RankingCalculationService`/`RankingAccessLevel` decidam redigir
  depois.
- `RankingParticipant`/`RankingEntry`/`RankingBoard` (novos, dados puros):
  a entrada crua por par (`RankingParticipant`, com `realizedValue` nulo
  quando nenhuma agregação calculou ainda) e o resultado já processado
  (`RankingEntry`/`RankingBoard`, com posição/rank atribuída).
- `RankingCalculationService.compute` (novo, puro, mesmo precedente
  documentado de `PositivacaoCalculationService`/`CustomerScoringService`
  como "especificação da futura Cloud Function"): calcula percentual de
  atingimento, ordena com **critério de desempate determinístico e
  documentado** (1. atingimento % desc; 2. valor absoluto desc; 3. nome
  ascendente case-insensitive; 4. `dimensionId` ascendente — desempate final
  sempre único), atribui `rank` e **aplica a redação de RBAC**: quando
  `RankingAccessLevel.relativePositionOnly`, `RankingBoard.entries` contém
  **no máximo** a própria entrada do chamador — nome/valor de qualquer outro
  par nunca entram na lista retornada, nunca dependendo da UI para
  escondê-los depois. `totalParticipants`/`currentUserRank` continuam
  corretos mesmo nesse modo (revelar a contagem não identifica ninguém).
  Participantes sem `realizedValue` calculado são excluídos do ranking e da
  contagem.
- `RankingPeriodWindow` (novo, puro): janela `[start, end)` compartilhada
  entre vários `Target`s de pares diferentes — deliberadamente desacoplada
  de um único `Target` (diferente do dashboard de atingimento, que sempre
  mostra um `Target` por vez), já que um ranking precisa comparar *vários*
  `Target`s no mesmo período exato para ser justo.

### Apresentação (`lib/features/targets/presentation/`)

- `RankingDashboardCubit`/`RankingDashboardState` (novos): `load(...)`
  resolve `TargetVisibilityFilter` (reaproveitado do TASK-116),
  `RankingVisibilityMode` da organização (via `GetOrganizationUseCase`, já
  existente) e o próprio `Membership` do chamador (só para destacar a
  própria equipe quando ranqueando por `team`), depois carrega por padrão o
  ranking `salesRep`. `selectDimension(...)` resolve o `RankingPeerScope`
  (`RankingPeerResolverService`, re-checado a cada chamada — nunca confia
  que a UI já escondeu uma opção fora do alcance) e busca o `Target` de cada
  par via `TargetRepository.listByDimension` (a **mesma fonte de dado do
  TASK-116**, nunca uma soma de pedidos brutos), agrupando os períodos
  distintos encontrados como o "filtro por período" da task.
  `selectPeriod(window)` busca o `TargetAchievementSnapshot` de cada
  `Target` daquela janela via `TargetAchievementRepository.getForTarget` —
  o mesmo `achievedValueCache` que o dashboard de atingimento lê — resolve
  nomes em lote (`MembershipRepository.listByOrganization`/
  `TeamRepository.listByOrganization`, uma chamada por seleção, nunca uma
  por par) e chama `RankingCalculationService.compute` com o
  `RankingAccessLevel` já resolvido. `sortBy(...)` só reordena a
  apresentação (`RankingDashboardState.sortedEntriesForDisplay`), nunca o
  `rank` canônico de cada `RankingEntry` — a task pede "lista ordenável (por
  atingimento %, por valor absoluto)" como uma reordenação visual, não uma
  segunda regra de desempate.
- `RankingDashboardPage` (novo): filtro de métrica, filtro de dimensão
  (vendedor vs. equipe, só para quem `canPickDimension`, mesmo padrão
  `TargetDashboardState.canPickDimension`/`PositivacaoDashboardState
  .canPickDimension`), filtro de período (botões por janela distinta,
  mesmo padrão visual do `TargetDashboardPage`), controle de ordenação
  (só quando `RankingAccessLevel.full` — não faz sentido reordenar uma
  lista de uma única entrada). Card `AppKpiCard` "Sua posição" sempre
  visível (mesmo em `relativePositionOnly`, mostrando `"Nº de M"`).
  Ranking completo renderizado com `AppDataTable<RankingEntry>` — o mesmo
  componente do Design System (TASK-023) já usado pelas outras telas de
  `targets`, que **já converte para cards em mobile automaticamente**
  (nenhum componente novo criado). A linha do usuário logado é destacada
  reaproveitando `AppDataTable.selectedIds` (mesmo efeito visual de seleção,
  sem habilitar checkboxes) mais um badge "Você"
  (`AppStatusBadge`, também já existente). Quando
  `RankingAccessLevel.relativePositionOnly`, a tabela nunca é renderizada —
  um `AppEmptyState` explica a restrição, e nenhum nome/valor de outro
  vendedor jamais chega à árvore de widgets (a redação já aconteceu em
  `RankingCalculationService`, na camada de aplicação). Protegida por
  `PermissionBuilder(capability: Capability.targetView)` — a mesma
  capability do dashboard de atingimento e da positivação de carteira
  (TASK-116/117), sem nova capability.
- `AnalyticsEvents.rankingDashboardViewed` (novo): logado uma vez por
  troca de dimensão/métrica, nunca por tick.
- `Barrel targets.dart` atualizado com todos os novos exports.

## Arquivos criados

- `lib/features/targets/domain/value_objects/ranking_dimension_type.dart`
- `lib/features/targets/domain/value_objects/ranking_visibility_mode.dart`
- `lib/features/targets/domain/value_objects/ranking_access_level.dart`
- `lib/features/targets/domain/entities/ranking_entry.dart`
- `lib/features/targets/domain/entities/ranking_board.dart`
- `lib/features/targets/domain/entities/ranking_participant.dart`
- `lib/features/targets/domain/entities/ranking_peer_scope.dart`
- `lib/features/targets/domain/entities/ranking_period_window.dart`
- `lib/features/targets/domain/services/ranking_calculation_service.dart`
- `lib/features/targets/domain/services/ranking_peer_resolver_service.dart`
- `lib/features/targets/presentation/cubit/ranking_dashboard_cubit.dart`
- `lib/features/targets/presentation/cubit/ranking_dashboard_state.dart`
- `lib/features/targets/presentation/pages/ranking_dashboard_page.dart`
- `test/features/targets/domain/services/ranking_calculation_service_test.dart`
- `test/features/targets/domain/services/ranking_peer_resolver_service_test.dart`
- `test/features/targets/presentation/pages/ranking_dashboard_page_test.dart`
- `docs/tasks/TASK-118-implementar-ranking-comercial-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/organizations/domain/value_objects/organization_settings.dart` (novo campo `rankingVisibilityMode` + validação + constantes default)
- `lib/features/organizations/data/dtos/organization_settings_dto.dart` (fromJson/toJson do novo campo)
- `lib/features/organizations/data/mappers/organization_mapper.dart` (settingsToEntity/settingsToDto)
- `lib/features/organizations/domain/usecases/update_organization_settings_use_case.dart` (novo parâmetro opcional)
- `lib/core/analytics/analytics_events.dart` (`rankingDashboardViewed`; corrigida também uma duplicata pré-existente de `positivacaoSettingsUpdated` na lista fixa, encontrada ao adicionar o novo evento)
- `lib/features/targets/targets.dart` (novos exports)
- `lib/app/injection.config.dart` (gerado pelo `build_runner`, registra `RankingPeerResolverService`/`RankingCalculationService`/`RankingDashboardCubit`)
- `lib/features/organizations/domain/value_objects/organization_settings.freezed.dart` (gerado pelo `build_runner`)
- `test/core/analytics/analytics_events_test.dart` (novo evento na lista fixa)
- `test/features/organizations/domain/value_objects/organization_settings_test.dart` (casos para o novo campo)
- `test/features/organizations/data/mappers/organization_mapper_test.dart` (round-trip do novo campo)
- `test/features/organizations/domain/usecases/update_organization_settings_use_case_test.dart` (passthrough do novo parâmetro)
- `docs/tasks/TASKS.md` (checkbox da TASK-118 e progresso 117/220 → 118/220)

## Validações executadas

- `dart run build_runner build` (duas vezes — antes e depois de anotar
  `RankingCalculationService` com `@injectable`, exigido pela injeção de
  dependência em `RankingDashboardCubit`) — sucesso em ambas. Os avisos de
  "missing dependencies" impressos pelo `injectable_generator` são
  pré-existentes (mesmos 9 já citados nas docs de conclusão de TASK-116/117),
  nenhum deles citando algo criado nesta task na segunda execução.
- `flutter analyze` (projeto completo, após todas as edições) — sem issues.
- `dart format --output=none --set-exit-if-changed .` — sem alterações
  pendentes na versão final (1882 arquivos, 0 alterados).
- `flutter test test/features/targets/domain/services/ranking_calculation_service_test.dart
  test/features/targets/domain/services/ranking_peer_resolver_service_test.dart` —
  19 testes, todos passando (ordenação/desempate determinístico e RBAC de
  redação/escopo de pares).
- `flutter test test/features/organizations/domain/value_objects/organization_settings_test.dart
  test/features/organizations/data/mappers/organization_mapper_test.dart
  test/features/organizations/domain/usecases/update_organization_settings_use_case_test.dart` —
  36 testes, todos passando.
- `flutter test test/features/targets/presentation/pages/ranking_dashboard_page_test.dart` —
  6 testes de widget, todos passando (ranking carregado, posição do usuário
  destacada, RBAC `relativePositionOnly` nunca vaza nome/valor de outro
  vendedor, SALES_MANAGER/ADMIN sempre veem completo mesmo com a
  organização restrita, estado vazio, estado de erro).
- `flutter test` (suíte completa) — 2422 testes, todos passando.

## Decisões e riscos conhecidos

- **Fonte de dado é a mesma do TASK-116, com a mesma pendência real de
  infraestrutura**: `RankingCalculationService.compute` lê
  `RankingParticipant.realizedValue`, que `RankingDashboardCubit` resolve
  via `TargetAchievementRepository.getForTarget` — exatamente o
  `TargetsTable.achievedValueCache` que TASK-116 já documenta como "ainda
  sem nenhuma Cloud Function escrevendo nele". Ou seja: o ranking aqui
  implementado é funcional e correto, mas hoje renderiza majoritariamente o
  estado "cálculo do ranking ainda não disponível"
  (`RankingDashboardStatus.notCalculated`) até essa pipeline existir — a
  mesma pendência já registrada nas conclusões de TASK-116/TASK-117, agora
  também válida para ranking. Isso é deliberado e consistente com a regra
  "nunca somar pedidos brutos no cliente" — a alternativa seria violar essa
  regra explícita.
- **Busca de `Target`/achievement por par é sequencial, não paralela**:
  `RankingDashboardCubit.selectDimension`/`selectPeriod` fazem um loop
  `await` por par em vez de `Future.wait`, mesmo precedente de
  `_resolvePendingCustomerLabels` (TASK-117) — como o tamanho típico de uma
  equipe é dezenas (não milhares) de pessoas e a leitura é local (cache
  offline via `AppDatabase`), isso não é um problema de performance real
  hoje, mas poderia ser paralelizado facilmente se necessário.
- **Falha de um único par nunca aborta o ranking inteiro**: se
  `TargetRepository.listByDimension` falhar para um par específico (ex.:
  uma leitura offline transitória), esse par simplesmente não contribui
  candidatos naquela passada — mesmo padrão de resiliência best-effort já
  documentado em `PositivacaoDashboardCubit`. Se **todos** os pares
  falharem, o ranking hoje aparece como "vazio" em vez de "erro" — uma
  distinção mais fina poderia ser adicionada no futuro se o negócio
  precisar diferenciar esses dois cenários na UI.
- **Ranking por `company`/`collection`/`category` não existe**:
  deliberadamente fora de escopo — a task pede explicitamente "vendedor
  individual vs. equipe" como as duas dimensões do filtro, e comparar uma
  única empresa/coleção/categoria contra si mesma não tem uma leitura
  natural de "quem está à frente de quem" (mesmo raciocínio documentado em
  `RankingDimensionType`'s own docs).
- **Peers de um SALES_REP incluem todo membro de toda equipe a que ele
  pertence, mesmo que multiequipe**: se um vendedor pertence a duas equipes,
  seus pares são a união de ambas — não há hoje uma configuração de
  organização para restringir isso a "apenas a equipe primária"; um
  refinamento futuro poderia adicionar essa granularidade se o negócio
  pedir (mesmo tipo de lacuna documentada nas decisões conhecidas de
  TASK-116 para o carve-out "SALES_REP vê a própria equipe").
- **Bug pré-existente corrigido en passant**: `AnalyticsEvents.values`
  (lista fixa usada pelo teste de taxonomia) já continha uma entrada
  duplicada de `positivacaoSettingsUpdated` antes desta task; corrigido ao
  adicionar `rankingDashboardViewed` à mesma lista (o teste
  `test/core/analytics/analytics_events_test.dart` já teria falhado assim
  que a duplicata fosse notada, então isso não passou despercebido nem foi
  deixado para trás).

Nenhum teste, análise ou comando foi apenas assumido: todos os comandos
listados em "Validações executadas" foram executados nesta sessão e
retornaram sucesso.
