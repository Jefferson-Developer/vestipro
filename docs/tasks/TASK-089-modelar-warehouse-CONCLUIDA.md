# TASK-089 — Concluída (2026-08-27)

## Resumo
Feature `inventory` criada com a entidade `Warehouse`, DTO, mapper, repositório, datasource Firestore, cache local Drift e use cases `GetWarehousesByCompany` e `GetActiveWarehouses`. A relação Warehouse→Branch foi documentada como 1:N por cobertura: um depósito central (`branchId = null`) pode atender múltiplas branches sem duplicar o warehouse.

## Agentes utilizados
- `flutter-senior-architect`

## Arquivos criados
- `lib/features/inventory/inventory.dart`
- `lib/features/inventory/domain/entities/warehouse.dart`
- `lib/features/inventory/domain/repositories/warehouse_repository.dart`
- `lib/features/inventory/domain/usecases/get_warehouses_by_company_use_case.dart`
- `lib/features/inventory/domain/usecases/get_active_warehouses_use_case.dart`
- `lib/features/inventory/domain/value_objects/warehouse_type.dart`
- `lib/features/inventory/data/dtos/warehouse_dto.dart`
- `lib/features/inventory/data/mappers/warehouse_mapper.dart`
- `lib/features/inventory/data/mappers/warehouse_local_mapper.dart`
- `lib/features/inventory/data/datasources/warehouse_remote_data_source.dart`
- `lib/features/inventory/data/datasources/firestore_warehouse_data_source.dart`
- `lib/features/inventory/data/repositories/warehouse_repository_impl.dart`
- `lib/core/database/tables/warehouses_table.dart`
- `test/features/inventory/domain/entities/warehouse_test.dart`
- `test/features/inventory/data/mappers/warehouse_mapper_test.dart`
- `test/features/inventory/domain/usecases/warehouse_use_cases_test.dart`
- `test/core/database/app_database_warehouses_test.dart`

## Arquivos alterados
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/database.dart`
- `lib/app/injection.config.dart`
- `firestore.rules`
- `firestore-tests/firestore.rules.test.js`
- `test/core/database/app_database_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Feature-first + Clean Architecture: domain (`Warehouse` + contratos + use cases), data (DTOs, mappers, datasource remoto, fallback local em Drift) e persistência tenant-scoped via `FirestoreCollectionDataSource` + `AppDatabase`.

## Regras de negócio implementadas
- Toda consulta é escopada por `organizationId` e `companyId`.
- `branchId` nulo representa depósito centralizado, permitindo atendimento multi-branch sem modelagem N:N nesta task.
- Warehouses inativos ou soft-deletados permanecem consultáveis no histórico, mas `GetActiveWarehouses` filtra apenas ativos.

## Regras Firebase implementadas
- Nova subcoleção `organizations/{organizationId}/warehouses/{warehouseId}`.
- Leitura permitida apenas a membros ativos da própria organização.
- Escrita permitida apenas para perfis com `inventory.adjust`.
- `organizationId`, `companyId`, `createdAt` e `createdBy` ficam imutáveis em update.

## Analytics implementado
Nenhum. Não havia evento de produto/estoque exigido nesta task estrutural.

## Crashlytics implementado
Nenhum fluxo novo específico; erros continuam mapeados para `AppFailure`/`AppException`.

## Impacto offline
Tabela Drift `warehouses` adicionada ao `AppDatabase` com índice composto `organizationId + companyId + branchId` e fallback local quando a leitura remota falha.

## Impacto multi-tenant
Coleção Firestore e cache local sempre escopados por organização/empresa. Nenhuma leitura cross-tenant é permitida pelas rules ou pelo repositório.

## Testes criados
- Entidade `Warehouse`
- Mapper `WarehouseDto ↔ Warehouse`
- Use cases com repositório mockado
- Migração/tabela Drift `warehouses`
- Regras Firestore para `warehouses` adicionadas ao arquivo de testes do emulator

## Comandos executados
- `dart run build_runner build`
- `dart format --set-exit-if-changed lib/features/inventory test/features/inventory test/core/database/app_database_warehouses_test.dart test/core/database/app_database_test.dart`
- `flutter test test/features/inventory/domain/entities/warehouse_test.dart test/features/inventory/data/mappers/warehouse_mapper_test.dart test/features/inventory/domain/usecases/warehouse_use_cases_test.dart test/core/database/app_database_warehouses_test.dart test/core/database/app_database_test.dart`
- `flutter analyze`
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test -- --runInBand --testNamePattern=TASK-089|warehouses"`

## Resultado do formatter
Sucesso para os arquivos Dart do escopo (`0 changed` na última execução focada).

## Resultado do analyzer
`flutter analyze` sem issues.

## Resultado dos testes
- `flutter test` focado no escopo passou.
- Teste de Firestore Rules não executou no Emulator por ausência de Java no ambiente (`Could not spawn "java -version"`).

## Decisões técnicas
- Reutilizado `FirestoreCollectionDataSource` para manter escopo tenant-safe por construção.
- O repositório prioriza remoto e atualiza o cache local; se o remoto falha, tenta fallback local antes de propagar erro.
- A relação Warehouse→Branch foi tratada como 1:N por cobertura operacional, evitando introduzir uma tabela de associação antes de haver um caso real de roteamento multi-branch.

## Riscos conhecidos
- O teste de rules depende de Java para subir o Emulator.
- A query Firestore com `branchId` nulo + branch específica depende de `Filter.or`, que precisa ser suportado pelo SDK/alvo do ambiente remoto.

## Pendências
- Preencher hash exato do commit local após o commit desta task.
- As tasks seguintes do EPIC-12 ainda vão ampliar o módulo `inventory` com saldo, estoque futuro, reserva, alertas e giro.

## Evidências
- `Warehouse` criado no domain e publicado pelo módulo `inventory`.
- `warehouses` adicionada ao `AppDatabase` com migração para schema `8`.
- `firestore.rules` estendida para a nova coleção tenant-scoped.

## Commit
Pendente nesta etapa do arquivo; será realizado localmente sem push.

## Push
Não autorizado nesta conversa.

## Hash do commit
Pendente

## Branch
`main`
