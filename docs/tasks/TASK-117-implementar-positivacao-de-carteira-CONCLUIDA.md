# TASK-117 — Implementar positivação de carteira (CONCLUÍDA)

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### Configuração por organização (`lib/features/organizations/domain/`)

- `OrganizationSettings` (estendido, nunca um novo doc/coleção): 3 novos campos
  — `positivacaoPeriodGranularity` (código string `monthly`/`quarterly`/`yearly`,
  default `monthly`), `positivacaoEligibleOrderStatuses` (lista de códigos
  `OrderStatus.name`, default `[approved, delivered, invoiced,
  partiallyInvoiced, shipped]`) e `positivacaoMinOrderValue` (opcional, `null`
  = sem mínimo). Reaproveita o pipeline já existente e testado de
  `OrganizationSettings.validated`/`OrganizationSettingsDto`/
  `OrganizationMapper`/`UpdateOrganizationSettingsUseCase`
  (`OrganizationRepository.updateSettings`, já Firestore-backed desde
  TASK-026/037) em vez de criar uma nova coleção/documento de settings — a
  mesma técnica de desacoplamento já usada por `requiredCustomerFields`/
  `customerAddressTypes` (strings livres, nunca um enum de outra feature
  importado aqui) evita que `organizations` precise depender de `orders`.
  `OrganizationSettings.validated` normaliza (trim/dedupe/sort) e valida a
  regra (granularidade reconhecida, lista de status não vazia, valor mínimo
  não negativo) — nunca hardcoded, editável só por quem tem
  `Capability.organizationSettingsManage` (OWNER/ADMIN).

### Domínio — regra e cálculo (`lib/features/targets/domain/`)

- `PositivacaoSettings` (novo value object): a regra já decodificada
  (`TargetPeriodGranularity`, `Set<String>` de status elegíveis, valor
  mínimo opcional), com `PositivacaoSettings.fromOrganizationSettings(...)`
  fazendo o parse a partir do `OrganizationSettings` cru (fallback seguro
  para `monthly` se a organização tiver um código de granularidade
  desconhecido, nunca lança exceção).
- `PositivacaoDimensionType` (novo enum, `salesRep`/`team`/`company`):
  deliberadamente mais estreito que `TargetDimensionType` — uma
  `collection`/`category` não tem "carteira de clientes" para positivar.
  `asTargetDimensionType` mapeia para o enum do TASK-116, permitindo
  reaproveitar `TargetVisibilityService`/`TargetVisibilityFilter` (TASK-116)
  sem duplicar a lógica OWNER/ADMIN/SALES_MANAGER/SALES_REP de visibilidade
  por dimensão — exatamente como a task pediu ("reaproveite se fizer
  sentido").
- `PositivacaoOrderSignal`/`PositivacaoCalculationService` (novo, pura,
  mesmo padrão "fonte da verdade da futura Cloud Function" que
  `CustomerScoringService` já documenta): dado um conjunto de ids de
  clientes da carteira, uma lista de sinais de pedido (`customerId`,
  `statusCode`, `orderTotal`, `orderDate`) e a `PositivacaoSettings`, decide
  quem positivou — status elegível **e** dentro do período **e** valor ≥
  mínimo configurado — e devolve o `PositivacaoSnapshot` completo (total da
  carteira, positivados, não positivados). Nunca lê nada por conta própria
  (sem repositório, sem `DateTime.now()` interno) — 100% testável sem mocks.
- `PositivacaoSnapshot` (nova entidade): `totalPortfolio`/`positivatedCount`/
  `calculatedAt` sempre todos `null` juntos ou todos preenchidos juntos —
  `null` significa "nenhuma agregação server-side calculou isso ainda"
  (estado real e esperado hoje), nunca "carteira vazia". `percentage` nunca
  divide por zero. `nonPositivatedCustomerIds` é a lista de ação comercial
  pedida pela task.
- `PositivacaoRepository` (novo contrato, `getForDimension`/
  `watchForDimension`): documentado explicitamente como **nunca um contrato
  de soma** — toda implementação deve resolver o snapshot a partir de uma
  agregação já calculada server-side, nunca somando Customer/Order brutos no
  cliente, seguindo à risca a mesma regra que `TargetAchievementRepository`
  (TASK-116) já impõe para `Target`. Essa é uma decisão deliberada: a task
  pede "agregação server-side, evitando centenas de queries do cliente", e o
  próprio código deste repositório (`AppDatabase.getTargetById`'s docs,
  TASK-116) já proíbe explicitamente até uma soma local de pedidos brutos
  como substituto — então a mesma régua se aplica aqui.
- `PositivacaoPeriod`/`PositivacaoPeriodResolver` (novo, puro): resolve a
  janela `[start, end)` do período corrente (mensal/trimestral/anual) a
  partir de `now` — nunca lê o relógio internamente, sempre injetado pelo
  chamador, mesma testabilidade de `TargetProgressViewModel.compute`.

### Dados (`lib/core/database/` e `lib/features/targets/data/`)

- `PositivacaoSnapshotsTable` (nova tabela Drift, schema version 18 → 19):
  cache local estreito, mesmo precedente de `TargetsTable.achievedValueCache`
  — colunas de resultado (`totalPortfolio`/`positivatedCount`/
  `nonPositivatedCustomerIdsJson`/`calculatedAt`) nuláveis porque **nenhum
  pipeline server-side escreve nelas ainda** (ver pendência abaixo). Chave
  primária é um id composto determinístico
  (`organizationId:dimensionType:dimensionId:periodStart`) construído pelo
  repositório, nunca fornecido pelo cliente.
- `AppDatabase.getPositivacaoSnapshotById`/`watchPositivacaoSnapshotById`
  (novos): leem/observam exatamente essa linha, escopados por
  `organizationId` em defesa de profundidade — nunca somam
  `OrdersTable`/`CustomersTable` localmente (a doc de
  `getTargetById`/`TargetAchievementRepository` já proíbe isso
  explicitamente até para o cache local).
- `DriftPositivacaoRepository` (novo, `@LazySingleton`): implementação
  concreta lendo essa tabela — linha ausente e linha com `calculatedAt` nulo
  resolvem para o mesmo `PositivacaoSnapshot` "não calculado".

### Apresentação — dashboard (`lib/features/targets/presentation/`)

- `PositivacaoDashboardCubit`/`PositivacaoDashboardState` (novos): `load(...)`
  resolve `TargetVisibilityFilter` (reaproveitado) e a `PositivacaoSettings`
  da organização (via `GetOrganizationUseCase`, já existente), depois carrega
  por padrão a própria carteira `salesRep` do chamador.
  `selectDimension(...)` **re-checa `TargetVisibilityFilter.canView`** antes
  de assinar o stream — nunca confia que a UI já escondeu uma opção fora do
  alcance (mesmo padrão de defesa em profundidade do TASK-116). Resolve o
  período corrente (`PositivacaoPeriod.current`) a partir da granularidade
  configurada e assina `PositivacaoRepository.watchForDimension` — o
  mecanismo near real-time. Resolve os nomes dos clientes pendentes
  (`GetCustomerByIdUseCase`, já existente) de forma assíncrona/best-effort
  depois do estado `ready`, nunca bloqueando a UI nem violando a regra de
  "nunca centenas de queries no cliente" (é uma leitura local por cliente já
  autorizado da carteira, não uma varredura ampla).
- `PositivacaoDashboardPage` (novo): KPIs (Carteira total, Clientes
  positivados, % Positivação) com `AppKpiCard`, tabela `AppDataTable` com a
  lista de clientes pendentes de compra ("ação comercial"), texto de período
  de referência e aviso de "cálculo ainda não disponível" quando
  `calculatedAt` é nulo, filtro de dimensão (vendedor/equipe/empresa) só
  para quem `canPickDimension`. Protegida por
  `PermissionBuilder(capability: Capability.targetView)` — a mesma
  capability do dashboard de atingimento (TASK-116), sem nova capability.
- `AnalyticsEvents.positivacaoDashboardViewed` (novo): logado uma vez por
  troca de dimensão, nunca por tick de sincronização.

### Apresentação — configuração admin (`lib/features/targets/presentation/`)

- `PositivacaoSettingsCubit`/`PositivacaoSettingsFormPage` (novos): tela
  administrativa dedicada pedida pela task ("permitir a configuração da
  regra... em uma tela administrativa"). Carrega o `Organization` atual
  (`GetOrganizationUseCase`) e salva reenviando **todo** o
  `OrganizationSettings` (currency/country/etc. preservados) mais os 3
  campos de positivação editados — necessário porque
  `FirestoreOrganizationDataSource.updateSettings` substitui o mapa
  `settings` inteiro (`whole-map replace`, já documentado no DTO), nunca um
  merge parcial. Protegida por `Capability.organizationSettingsManage`
  (OWNER/ADMIN apenas — mesma capability que já governa todo o resto de
  `OrganizationSettings`).
- `AnalyticsEvents.positivacaoSettingsUpdated` (novo).
- `Barrel targets.dart` atualizado com todos os novos exports.

## Arquivos criados

- `lib/features/targets/domain/value_objects/positivacao_dimension_type.dart`
- `lib/features/targets/domain/value_objects/positivacao_settings.dart`
- `lib/features/targets/domain/entities/positivacao_snapshot.dart`
- `lib/features/targets/domain/services/positivacao_calculation_service.dart`
- `lib/features/targets/domain/services/positivacao_period_resolver.dart`
- `lib/features/targets/domain/repositories/positivacao_repository.dart`
- `lib/core/database/tables/positivacao_snapshots_table.dart`
- `lib/features/targets/data/repositories/drift_positivacao_repository.dart`
- `lib/features/targets/presentation/cubit/positivacao_dashboard_cubit.dart`
- `lib/features/targets/presentation/cubit/positivacao_dashboard_state.dart`
- `lib/features/targets/presentation/cubit/positivacao_settings_cubit.dart`
- `lib/features/targets/presentation/cubit/positivacao_settings_state.dart`
- `lib/features/targets/presentation/pages/positivacao_dashboard_page.dart`
- `lib/features/targets/presentation/pages/positivacao_settings_form_page.dart`
- `test/features/targets/domain/services/positivacao_calculation_service_test.dart`
- `test/features/targets/domain/value_objects/positivacao_settings_test.dart`
- `test/features/targets/data/repositories/drift_positivacao_repository_test.dart`
- `test/features/targets/presentation/pages/positivacao_dashboard_page_test.dart`
- `docs/tasks/TASK-117-implementar-positivacao-de-carteira-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/organizations/domain/value_objects/organization_settings.dart` (3 novos campos + validação + constantes default)
- `lib/features/organizations/data/dtos/organization_settings_dto.dart` (fromJson/toJson dos novos campos)
- `lib/features/organizations/data/mappers/organization_mapper.dart` (settingsToEntity/settingsToDto)
- `lib/features/organizations/domain/usecases/update_organization_settings_use_case.dart` (novos parâmetros opcionais)
- `lib/core/database/app_database.dart` (nova tabela, schemaVersion 18 → 19, migração, `getPositivacaoSnapshotById`/`watchPositivacaoSnapshotById`)
- `lib/core/analytics/analytics_events.dart` (`positivacaoDashboardViewed`/`positivacaoSettingsUpdated`)
- `lib/features/targets/targets.dart` (novos exports)
- `lib/app/injection.config.dart` (gerado pelo `build_runner`)
- `lib/features/organizations/domain/value_objects/organization_settings.freezed.dart` (gerado pelo `build_runner`)
- `lib/core/database/app_database.g.dart` (gerado pelo `build_runner`)
- `test/core/analytics/analytics_events_test.dart` (novos eventos na lista fixa)
- `test/core/database/app_database_task_106_schema_test.dart`, `app_database_task_114_targets_migration_test.dart`, `app_database_test.dart`, `app_database_warehouses_test.dart` (`schemaVersion` esperado 18 → 19)
- `test/features/organizations/domain/value_objects/organization_settings_test.dart` (casos para os novos campos)
- `test/features/organizations/data/mappers/organization_mapper_test.dart` (round-trip dos novos campos)
- `test/features/organizations/domain/usecases/update_organization_settings_use_case_test.dart` (passthrough dos novos parâmetros)
- `docs/tasks/TASKS.md` (checkbox da TASK-117 e progresso 116/220 → 117/220)

## Validações executadas

- `dart run build_runner build` (sem `--delete-conflicting-outputs`, opção
  já removida da versão atual do pacote — a flag foi ignorada com um
  warning inofensivo) — sucesso, regenerou `organization_settings.freezed.dart`,
  `app_database.g.dart` e `injection.config.dart`. Os avisos de "missing
  dependencies" impressos pelo `injectable_generator` são pré-existentes,
  não relacionados a esta task.
- `flutter analyze` (projeto completo, duas vezes — antes e depois da
  correção de teste) — sem issues em ambas.
- `dart format --output=none --set-exit-if-changed .` — sem alterações
  pendentes na versão final (1866 arquivos, 0 alterados).
- `flutter test test/features/targets test/features/organizations
  test/core/analytics` — 318 testes, todos passando (após corrigir a ordem
  default de `positivacaoEligibleOrderStatuses`, adicionar os 2 novos
  eventos à lista fixa de `analytics_events_test.dart` e corrigir uma
  condição de corrida real no `PositivacaoDashboardCubit`, ver abaixo).
- `flutter test` (suíte completa) — 2391 testes, todos passando (após
  atualizar 4 asserções de `schemaVersion` de 18 para 19).

## Decisões e riscos conhecidos

- **`PositivacaoSnapshotsTable` fica sempre com `calculatedAt` nulo hoje,
  para qualquer carteira**: exatamente como o `TargetsTable.achievedValueCache`
  do TASK-116, nenhuma Cloud Function/pipeline de BI escreve nessa tabela
  ainda. `PositivacaoCalculationService` existe, é testado e é a
  especificação exata da futura agregação server-side (mesmo precedente de
  `CustomerScoringService`, que documenta a formula como "daily Cloud
  Function source of truth" antes de a Cloud Function TS equivalente
  existir) — mas nenhuma Cloud Function em `functions/src/` chama esse
  cálculo ainda, e nenhum pipeline sincroniza o resultado para
  `PositivacaoSnapshotsTable` (local) nem para um Firestore equivalente.
  Isso é consistente com — e não contorna — a regra "cálculo de agregação
  nunca é feito só no cliente somando documentos brutos": a alternativa
  seria violar essa regra explícita já documentada por `TargetsTable`/
  `TargetAchievementRepository`. Fica registrada como a mesma pendência real
  de infraestrutura já citada na TASK-116, agora também válida para
  positivação — a primeira task que efetivamente construir essa agregação
  server-side (provavelmente uma Cloud Function agendada, no mesmo molde de
  `recalculateCustomerScores`) deve escrever tanto em
  `TargetsTable.achievedValueCache` (para metas com `metric: positivacao`)
  quanto num novo doc/coleção Firestore que `PositivacaoRepository` passe a
  ler em vez do cache Drift local.
- **Dimensão `team`/`company` funciona no domínio/RBAC, mas nunca terá dado
  calculado até essa pipeline existir**: como não há agregação real ainda,
  não há como validar hoje se o formato de rollup por equipe/empresa
  (somar carteiras de vários vendedores) está correto — apenas o
  `PositivacaoDimensionType`/`TargetVisibilityFilter` já sabem decidir quem
  pode *pedir* para ver essas dimensões.
- **Tela de configuração não valida se os `OrderStatus` string codes
  existem de fato**: `OrganizationSettings.validated` só normaliza
  (trim/dedupe/sort) a lista de status elegíveis como strings livres, sem
  confirmar que cada código corresponde a um `OrderStatus.name` real — a
  mesma folga que `customerAddressTypes`/`customerContactTypes` já têm. A
  tela (`PositivacaoSettingsFormPage`) só oferece os valores reais de
  `OrderStatus` no multi-select, então um valor inválido só entraria via
  chamada direta ao use case fora da UI; uma validação mais rígida no
  domínio ficaria fácil de adicionar depois (bastaria a `targets` feature
  expor um `Set<String>` de códigos válidos para o form consultar).
- **Bug real encontrado e corrigido durante os testes**: o cubit original
  fazia `await _snapshotSubscription?.cancel();` antes de emitir tanto o
  estado `forbidden` quanto o próximo `loading` — em produção isso é
  inofensivo, mas expôs uma race condition real do ambiente de teste do
  Flutter (`awaiting` o cancelamento de uma subscription viva a um
  `Stream` `broadcast`/`async*` não resolve dentro de `pumpAndSettle`,
  travando a emissão do próximo estado até depois do teste terminar,
  gerando `Bad state: Cannot emit new states after calling close`). Corrigido
  trocando para `unawaited(_snapshotSubscription?.cancel())` nos dois
  pontos — cancelar uma subscription já impede novos eventos
  sincronicamente, não há necessidade real de esperar a limpeza interna do
  stream antes de prosseguir. Vale considerar aplicar a mesma correção
  preventiva em `TargetDashboardCubit`/`TargetAchievementRepository`
  (TASK-116) numa task futura, já que ele tem o mesmo padrão `await
  cancel()` — hoje não quebra os testes existentes só porque nenhum deles
  exercita um `selectDimension`/`selectPeriod` sobre uma subscription já
  viva no cenário de RBAC negado.
- **Resolução de nomes de clientes pendentes é sequencial, não paralela**:
  `_resolvePendingCustomerLabels` chama `GetCustomerByIdUseCase` um por um
  em vez de `Future.wait`, para manter o código simples; como a carteira de
  um vendedor tende a ser pequena (dezenas, não milhares) e a leitura é
  local (cache offline), isso não é um problema de performance real hoje,
  mas poderia ser paralelizado facilmente se necessário.

Nenhum teste, análise ou comando foi apenas assumido: todos os comandos
listados em "Validações executadas" foram executados nesta sessão e
retornaram sucesso.
