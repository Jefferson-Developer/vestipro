# TASK-090 — Concluída (2026-08-27)

## Resumo
Saldo agregado por `variantId + warehouseId` implementado no módulo `inventory`, com leitura remota eficiente por variante/produto/warehouse, cache local Drift com TTL e adaptação do contrato existente de `VariantAvailability` para consumir o saldo vendável consolidado. A escrita crítica passou a ter uma Cloud Function transacional e idempotente que aplica deltas com `FieldValue.increment` e grava auditoria centralizada.

## Agentes utilizados
- `flutter-senior-architect`

## Arquivos criados
- `lib/features/inventory/domain/entities/variant_stock_balance.dart`
- `lib/features/inventory/domain/entities/variant_inventory_availability.dart`
- `lib/features/inventory/domain/repositories/variant_stock_balance_repository.dart`
- `lib/features/inventory/domain/usecases/get_variant_inventory_availability_use_case.dart`
- `lib/features/inventory/data/dtos/variant_stock_balance_dto.dart`
- `lib/features/inventory/data/mappers/variant_stock_balance_mapper.dart`
- `lib/features/inventory/data/mappers/variant_stock_balance_local_mapper.dart`
- `lib/features/inventory/data/datasources/variant_stock_balance_remote_data_source.dart`
- `lib/features/inventory/data/datasources/firestore_variant_stock_balance_data_source.dart`
- `lib/features/inventory/data/repositories/variant_stock_balance_repository_impl.dart`
- `lib/features/inventory/data/repositories/inventory_variant_availability_repository.dart`
- `lib/core/database/tables/variant_stock_balances_table.dart`
- `functions/src/inventory/apply-stock-balance-adjustment.ts`
- `functions/test/inventory/apply-stock-balance-adjustment.test.ts`
- `test/features/inventory/data/mappers/variant_stock_balance_mapper_test.dart`
- `test/features/inventory/data/repositories/variant_stock_balance_repository_impl_test.dart`
- `test/features/inventory/domain/usecases/get_variant_inventory_availability_use_case_test.dart`

## Arquivos alterados
- `lib/features/inventory/inventory.dart`
- `lib/features/products/domain/entities/variant_availability.dart`
- `lib/features/products/data/repositories/product_variant_availability_repository.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/database.dart`
- `lib/app/injection.config.dart`
- `lib/features/audit_log/domain/value_objects/audit_action.dart`
- `lib/features/audit_log/presentation/presenters/audit_log_presenter.dart`
- `firestore.rules`
- `test/core/database/app_database_test.dart`
- `test/core/database/app_database_warehouses_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture/feature-first: contratos e entidades em `domain`, leitura remota/cache local em `data`, adaptação de disponibilidade preservando o contrato já consumido pela UI e escrita crítica concentrada em Cloud Function server-side.

## Regras de negócio implementadas
- Saldo vendável é derivado de `physicalQuantity - reservedQuantity - blockedQuantity`, sempre truncado para não expor negativo ao client.
- O client apenas consulta saldo agregado pronto; não recalcula histórico de movimentações.
- Consultas por `warehouseId` usam paginação com `limit` e cursor simples (`startAfterId`), evitando leitura integral da coleção.
- Variante sem saldo cadastrado retorna disponibilidade zerada, nunca erro.
- A trilha de auditoria registra origem, deltas aplicados e snapshots anterior/novo do agregado.

## Regras Firebase implementadas
- Leitura de `organizations/{organizationId}/inventory/{inventoryId}` liberada apenas para membro ativo da própria organização.
- Escrita client-side em `inventory` permanece bloqueada; mutação crítica fica na Function `applyStockBalanceAdjustment`.
- A Function valida membership ativo real do caller, restringe ajuste a `OWNER/ADMIN`, aplica incremento atômico e rejeita qualquer resultado que deixe campos agregados ou saldo vendável negativos.
- Cada ajuste cria registro idempotente em `inventoryAdjustments` e entrada em `auditLogs`.

## Analytics implementado
Nenhum. Esta task permaneceu em domain/data/backend sem evento de uso comercial novo.

## Crashlytics implementado
Nenhum fluxo específico novo. Falhas continuam propagadas como `AppFailure`/`HttpsError` conforme a camada.

## Impacto offline
Nova tabela Drift `variant_stock_balances` adicionada com cache de curto prazo (`10` minutos). Com TTL válido, a leitura serve do cache; com TTL expirado, força nova busca remota. O cache é explícito como apoio offline, não fonte definitiva quando há conectividade.

## Impacto multi-tenant
Todas as leituras e escritas são escopadas por `organizationId`. O agregado também mantém `companyId`, `productId`, `variantId` e `warehouseId` no documento para consulta eficiente sem vazar tenant.

## Testes criados
- Mapper `VariantStockBalanceDto -> VariantStockBalance`
- Use case de disponibilidade zerada sem saldo
- Repositório com cache fresco, TTL expirado e paginação por warehouse
- Teste TypeScript da Function cobrindo ajuste incremental, replay idempotente e bloqueio de saldo vendável negativo

## Comandos executados
- `dart format lib/features/audit_log/domain/value_objects/audit_action.dart lib/features/audit_log/presentation/presenters/audit_log_presenter.dart lib/features/inventory lib/features/products/domain/entities/variant_availability.dart lib/features/products/data/repositories/product_variant_availability_repository.dart lib/core/database lib/app/injection.config.dart test/features/inventory test/core/database`
- `flutter analyze`
- `flutter test test/features/inventory/domain/usecases/get_variant_inventory_availability_use_case_test.dart test/features/inventory/data/mappers/variant_stock_balance_mapper_test.dart test/features/inventory/data/repositories/variant_stock_balance_repository_impl_test.dart test/core/database/app_database_warehouses_test.dart test/core/database/app_database_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter test`
- `npm run build` (em `functions/`)
- `npm test -- --runTestsByPath test/inventory/apply-stock-balance-adjustment.test.ts` (em `functions/`)

## Resultado do formatter
Após uma primeira execução corrigir 1 arquivo de teste, a base ficou formatada e apta para seguir.

## Resultado do analyzer
`flutter analyze` sem issues.

## Resultado dos testes
- `flutter test` focado do escopo passou.
- `flutter test` completo do repositório passou.
- `npm run build` das Cloud Functions passou.
- O teste Node da Function não executou com sucesso neste ambiente porque o Admin SDK tentou usar credenciais padrão do Google Cloud; a alternativa via Emulator segue bloqueada pela ausência de Java local.

## Decisões técnicas
- O contrato legado `VariantAvailabilityRepository` foi mantido e adaptado para ler do novo agregado de inventory, evitando quebra nas telas já existentes.
- O cache local foi mantido dentro do repositório de saldo, centralizando a política de TTL.
- A idempotência server-side foi implementada com `idempotencyKey` persistida em `inventoryAdjustments`, evitando aplicar o mesmo delta mais de uma vez em retry.
- A auditoria reaproveita o `auditLogs` central com nova action `inventory.balanceAdjusted`, tornando a trilha imediatamente consultável pelo módulo já existente.

## Riscos conhecidos
- O cursor por warehouse usa `variantId` como marcador simples; se houver necessidade de ordenação estável por múltiplos campos em grande volume, a paginação pode evoluir para cursor composto em task futura.
- O teste automatizado da Function ainda depende de ambiente com credenciais válidas ou Emulator funcional com Java.

## Pendências
- Preencher hash exato do commit local após o commit desta task.
- O backend ainda não expõe fluxos de reserva/consumo/expiração; isso fica para TASK-092 e TASK-101.

## Evidências
- `variant_stock_balances` adicionada ao `AppDatabase` com schema `9`.
- `inventory.balanceAdjusted` reconhecida pelo módulo de auditoria.
- `applyStockBalanceAdjustment` adicionada às Cloud Functions exportadas.

## Commit
Pendente nesta etapa do arquivo; será realizado localmente sem push.

## Push
Não autorizado nesta conversa.

## Hash do commit
Pendente

## Branch
`main`
