# TASK-114 — Modelar Target (CONCLUÍDA)

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### Domínio (`lib/features/targets/domain/`)

- `Target` (freezed) modela a meta comercial ("Target") com período
  (`startDate`/`endDate`/`periodGranularity`), dimensão (`dimensionType` +
  `dimensionId`: vendedor, equipe, empresa, coleção ou categoria), métrica
  (`metricType`: revenue/quantity/positivação), `targetValue`, `currency`,
  `status` (draft/active/closed) e os campos de auditoria/sincronização
  padrão (`createdAt/By`, `updatedAt/By`, `deletedAt`, `version`,
  `syncStatus`). A entidade deliberadamente **não** calcula
  atingimento/gap/projeção — isso é escopo da TASK-116.
- `targetPeriodsOverlap`/`Target.overlapsWith` implementam a comparação de
  período meio-aberto (`[start, end)`), garantindo que dois períodos
  encostados (ex.: janeiro terminando quando fevereiro começa) não sejam
  tratados como sobrepostos.
- `TargetRepository` define o contrato (`create`, `update`, `getById`,
  `listByDimension`) sem implementação concreta ainda — mesmo precedente de
  `OpportunityRepository` na TASK-057 (contrato primeiro, implementação
  chega com o fluxo de cadastro, aqui a TASK-115).
- `CreateTargetUseCase` valida: campos obrigatórios, `targetValue >= 0`,
  `startDate < endDate` e — apenas quando o novo `Target` é criado com
  `status = active` — que nenhum outro `Target` ativo da mesma
  organização/empresa/dimensão/métrica tenha período sobreposto (consulta via
  `TargetRepository.listByDimension`). Uma meta criada como `draft` pula essa
  checagem.
- Value objects: `TargetDimensionType`, `TargetMetricType` (taxonomia
  extensível — nova métrica é só um novo valor de enum + um novo case no
  mapper, nunca uma migração de schema), `TargetPeriodGranularity`,
  `TargetStatus`, `TargetSyncStatus`.

### Dados (`lib/features/targets/data/`)

- `TargetDto` modela o documento Firestore de
  `organizations/{organizationId}/targets/{targetId}` (já listado em
  `docs/architecture/firestore-schema.md`), com o mesmo padrão de validação
  estrita de `OpportunityDto` (lança `ValidationException` em payload
  inválido).
- `TargetMapper` converte `Target` ↔ `TargetDto`, incluindo os switches de
  enum ↔ string para `dimensionType`, `periodGranularity`, `metricType`,
  `status` e `syncStatus`.

### Offline (Drift)

- `TargetsTable` (criada de forma estrutural pela TASK-106) foi estendida
  com as colunas do modelo de domínio completo: `ownerId` virou
  `dimensionId` (mesma coluna física, significado mais amplo — vendedor,
  equipe, empresa, coleção ou categoria) e foram adicionadas `dimensionType`,
  `periodGranularity`, `currency` e `status` (todas nullable, pois esta ainda
  é só a camada de cache local — o pipeline de carga/sincronização de metas
  continua fora do escopo desta task de modelagem).
- `AppDatabase.schemaVersion` foi de 17 para 18, com uma migração
  `from < 18` que:
  - Lê `PRAGMA table_info('targets')` antes de agir, porque
    `migrator.createTable` sempre usa a definição **atual** da classe Dart —
    ou seja, um dispositivo pulando de uma versão `< 13` direto para `18`
    já ganha `dimension_id`/`dimension_type`/etc. "de graça" no `createTable`
    do bloco `from < 13`. Sem essa checagem, o `renameColumn`/`addColumn`
    incondicional quebraria a migração para esse cenário (coluna já existe
    ou `owner_id` nunca existiu).
  - Só renomeia `owner_id` → `dimension_id` quando `owner_id` existir e
    `dimension_id` ainda não existir; só adiciona cada nova coluna quando
    ela ainda não existir.
- `TargetRepository`/implementação concreta de local store (mirror de
  `DriftCustomerLocalStoreRepository`) e o pipeline de download/sync de
  metas continuam fora do escopo — ver "Pendências" abaixo.

### Barrel

- `lib/features/targets/targets.dart` exporta a superfície pública da
  feature (entidade, DTO, mapper, repositório, use case, value objects),
  seguindo o padrão de `opportunities.dart`.

## Arquivos criados

- `lib/features/targets/domain/entities/target.dart` (+ `target.freezed.dart`, gerado)
- `lib/features/targets/domain/target_period_overlap.dart`
- `lib/features/targets/domain/value_objects/target_dimension_type.dart`
- `lib/features/targets/domain/value_objects/target_metric_type.dart`
- `lib/features/targets/domain/value_objects/target_period_granularity.dart`
- `lib/features/targets/domain/value_objects/target_status.dart`
- `lib/features/targets/domain/value_objects/target_sync_status.dart`
- `lib/features/targets/domain/repositories/target_repository.dart`
- `lib/features/targets/domain/usecases/create_target_use_case.dart`
- `lib/features/targets/domain/usecases/target_use_case_helpers.dart`
- `lib/features/targets/data/dtos/target_dto.dart`
- `lib/features/targets/data/mappers/target_mapper.dart`
- `lib/features/targets/targets.dart`
- `test/features/targets/domain/entities/target_test.dart`
- `test/features/targets/domain/repositories/target_repository_test.dart`
- `test/features/targets/domain/usecases/create_target_use_case_test.dart`
- `test/features/targets/data/mappers/target_mapper_test.dart`
- `test/core/database/app_database_task_114_targets_migration_test.dart`
- `docs/tasks/TASK-114-modelar-target-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/database/tables/targets_table.dart` (colunas novas + `ownerId` → `dimensionId`)
- `lib/core/database/app_database.dart` (`schemaVersion` 17 → 18, migração `from < 18`, comentários)
- `test/core/database/app_database_test.dart` (assert `schemaVersion == 18`)
- `test/core/database/app_database_warehouses_test.dart` (assert `schemaVersion == 18`)
- `test/core/database/app_database_task_106_schema_test.dart` (assert `schemaVersion == 18`)
- `docs/tasks/TASKS.md` (checkbox da TASK-114 e progresso 113/220 → 114/220)

## Validações executadas

- `dart run build_runner build --delete-conflicting-outputs` — sucesso (gerou `target.freezed.dart` e regenerou `app_database.g.dart`/`app_database.freezed.dart` com o novo schema).
- `dart analyze lib/features/targets test/features/targets lib/core/database` — sem issues.
- `flutter analyze` (projeto completo) — sem issues.
- `flutter test test/features/targets` — 22 testes, todos passando.
- `flutter test test/core/database/` — 46 testes, todos passando (incluindo os dois novos testes de migração TASK-114 e os três arquivos de teste com a asserção de `schemaVersion` atualizada).
- `flutter test` (suíte completa) — 2317 testes, todos passando.
- `dart format --set-exit-if-changed .` — sem alterações pendentes.

## Decisões e riscos conhecidos

- **Repositório só como contrato**: seguindo o mesmo precedente de
  `OpportunityRepository` (TASK-057), `TargetRepository` não ganhou
  implementação de produção nesta task — apenas um fake em memória usado nos
  testes. A implementação concreta (Firestore/Outbox ou um local store
  interino) é esperada como parte da TASK-115 (cadastro de metas).
- **`TargetsTable` continua sendo só cache local, não uma pipeline
  funcional**: as novas colunas (`dimensionType`, `periodGranularity`,
  `currency`, `status`) são nullable porque nenhum código ainda escreve
  nelas — não existe (ainda) um `TargetLocalStoreRepository`/loader de pacote
  offline para metas, ao contrário de Customers/Price Lists. Isso é
  consistente com o próprio comentário original da TASK-106 (placeholder
  estrutural) e fica como trabalho futuro, provavelmente junto da TASK-115
  ou de uma task dedicada de sincronização de metas.
- **Migração de schema com guarda defensiva**: descobri, ao rodar os testes
  de migração já existentes (`app_database_task_106_schema_test.dart`), que
  `migrator.createTable` do Drift sempre usa a definição *atual* da tabela
  Dart — não uma versão histórica. Isso significa que qualquer dispositivo
  que ainda esteja em uma versão de schema anterior à 13 e pule direto para
  a 18 já ganha as colunas novas "de graça" no `createTable` do bloco
  `from < 13`, então o passo `from < 18` precisou checar via
  `PRAGMA table_info('targets')` se `owner_id`/as colunas novas já existem
  antes de agir, em vez de rodar `renameColumn`/`addColumn`
  incondicionalmente (o que quebraria a migração e teria corrompido o teste
  de upgrade 12→13 já existente). Esse mesmo padrão de risco
  (`addColumn` incondicional após uma janela de `createTable` já
  atualizada) parece pré-existir em outros trechos da migração (ex.:
  `orderNumber`/`duplicatedFromOrderId` do `OrdersTable`) sem teste que o
  exercite — não foi corrigido aqui por estar fora do escopo desta task, mas
  fica registrado como risco técnico conhecido do arquivo
  `lib/core/database/app_database.dart`.
- **Regra "companyId/teamId consistente" só parcialmente coberta**: a task
  pede que, quando `dimensionType` exigir (ex.: `company`, `team`), o
  `dimensionId` seja consistente com `companyId`. `CreateTargetUseCase`
  garante `companyId` obrigatório e não vazio, mas não valida
  cruzadamente se o `teamId`/`companyId` referenciado por `dimensionId`
  realmente pertence àquela empresa (exigiria consultar
  `TeamRepository`/`CompanyRepository`, o que extrapolaria o escopo de
  "modelar" desta task). Fica documentado como possível refinamento futuro
  (TASK-115 ou uma validação de integridade referencial dedicada).

Nenhum teste, análise ou comando foi apenas assumido: todos os comandos
listados em "Validações executadas" foram executados nesta sessão e
retornaram sucesso.
