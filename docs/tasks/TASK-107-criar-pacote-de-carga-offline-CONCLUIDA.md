# TASK-107 — Criar pacote de carga offline (CONCLUÍDA)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída (com escopo de entidades explicitamente parcial — ver "Pendências" abaixo)
**Agente executor:** flutter-senior-architect

## O que foi entregue

### 1. Motor reutilizável de carga offline (`lib/core/offline/`)

- `OfflinePackageEntityLoader` (`lib/core/offline/domain/offline_package_entity_loader.dart`):
  contrato que cada feature implementa por entidade (`kind`, `isApplicable` — gate de
  RBAC/carteira —, `estimate`, `load`), permitindo ao orquestrador tratar toda entidade da
  mesma forma sem conhecer detalhes de feature.
- `DownloadOfflinePackageUseCase` (`lib/core/offline/domain/download_offline_package_use_case.dart`):
  orquestra os loaders registrados — resolve RBAC (`isApplicable`), calcula estimativa de
  tamanho, baixa entidade por entidade **sequencialmente** (nunca acumula o pacote inteiro em
  memória de uma vez), verifica cancelamento entre lotes/entidades, e marca cada entidade como
  incompleta antes de começar e completa somente depois do replace local atômico ter
  efetivamente commitado. Suporta retomada por entidade (`forceFullReload: false` pula
  entidades já `isComplete`).
- `OfflinePackageCancellationToken`: flag cooperativa de cancelamento checada entre lotes —
  nunca interrompe uma escrita já em andamento, só impede que uma nova comece.
- `OfflinePackageLoadStatusTable` (`lib/core/database/tables/offline_package_load_status_table.dart`,
  Drift, `schemaVersion` 13→14 com migração `if (from < 14)`): marcador persistente de "carga
  completa"/"carga incompleta" por `organizationId`/`companyId`/entidade —
  `DriftOfflinePackageStatusRepository` implementa o contrato de domínio correspondente.
- `OfflinePackageDownloadCubit` (`lib/core/offline/presentation/cubit/`): estados `idle`,
  `estimating`, `downloading` (com `OfflinePackageProgress`), `cancelled`, `completed`,
  `failed`, conforme pedido pela task. `cancel()` aciona o token ativo; não há tela associada
  nesta task (agente indicado foi só Flutter Senior — UI fica para uma task de Front-end
  posterior, provavelmente junto da Central de Sincronização, TASK-112).

### 2. Loaders concretos registrados hoje

- **Clientes** (`lib/features/customers/domain/services/customer_offline_package_entity_loader.dart`):
  adapta o `LoadInitialCustomerOfflineDataUseCase` já existente (TASK-054), que já resolve RBAC
  de carteira (`SALES_REP` só a própria carteira, `SALES_MANAGER` só times geridos, `ADMIN`/
  `OWNER` toda a organização). Esse use case foi estendido (retrocompatível — parâmetros novos
  são opcionais) com `cancellationToken`/`onPageFetched` e um campo `cancelled` em
  `CustomerOfflineLoadSummary`, para checar cancelamento entre páginas sem nunca disparar o
  `replaceInitialLoad` final quando cancelado.
- **Tabelas de preço** (`lib/features/pricing/domain/services/price_list_offline_package_entity_loader.dart`)
  e **condições de pagamento** (`.../payment_term_offline_package_entity_loader.dart`): novos
  use cases `LoadInitialPriceListOfflineDataUseCase`/`LoadInitialPaymentTermOfflineDataUseCase`
  que replicam o padrão do TASK-054 para os local stores Drift que já existiam desde
  TASK-083/TASK-084 mas ainda não eram alimentados por nenhum fluxo de carga. Gate de RBAC:
  `Capability.orderCreate` (não `priceListManage`, que é só para as telas de *gestão* de
  pricing) — todo perfil que pode criar/precificar pedido, incluindo `SALES_REP`, precisa dessas
  tabelas offline.
- DI: `lib/app/offline_package_loaders_module.dart` agrega os três loaders concretos em
  `List<OfflinePackageEntityLoader>` — novo loader = adicionar 1 linha nesse módulo, sem tocar
  em `core/offline`.

### 3. Testes (37 testes novos, todos verdes)

- `test/core/offline/domain/download_offline_package_use_case_test.dart`: sucesso completo,
  RBAC excluindo loader não aplicável, cancelamento entre entidades (preserva a já commitada),
  loader que retorna `cancelled`, falha no meio (preserva commitadas, aborta as seguintes),
  retomada (`forceFullReload` true/false).
- `test/core/offline/data/repositories/drift_offline_package_status_repository_test.dart`:
  marca incompleta/completa, reverte para incompleta numa nova tentativa, isolamento
  multi-tenant.
- `test/core/offline/presentation/cubit/offline_package_download_cubit_test.dart`: transições
  de estado completas (idle→estimating→downloading→completed/failed/cancelled).
- `test/features/customers/domain/usecases/load_initial_customer_offline_data_use_case_test.dart`:
  novo teste de cancelamento entre páginas.
- `test/features/pricing/domain/usecases/load_initial_price_list_offline_data_use_case_test.dart`
  e `load_initial_payment_term_offline_data_use_case_test.dart`.
- `test/features/pricing/domain/services/price_list_offline_package_entity_loader_test.dart` e
  `payment_term_offline_package_entity_loader_test.dart`: RBAC (`SALES_REP`/`SALES_MANAGER`
  aplicável, `READ_ONLY`/sem Membership não aplicável) e cancelamento pré-load.

## Arquivos criados

- `lib/core/database/tables/offline_package_load_status_table.dart`
- `lib/core/offline/domain/entities/offline_package_entity_kind.dart`
- `lib/core/offline/domain/entities/offline_package_entity_status.dart`
- `lib/core/offline/domain/entities/offline_package_progress.dart`
- `lib/core/offline/domain/entities/offline_package_load_summary.dart`
- `lib/core/offline/domain/offline_package_cancellation_token.dart`
- `lib/core/offline/domain/offline_package_entity_loader.dart`
- `lib/core/offline/domain/download_offline_package_use_case.dart`
- `lib/core/offline/domain/repositories/offline_package_status_repository.dart`
- `lib/core/offline/data/repositories/drift_offline_package_status_repository.dart`
- `lib/core/offline/presentation/cubit/offline_package_download_state.dart`
- `lib/core/offline/presentation/cubit/offline_package_download_cubit.dart`
- `lib/core/offline/offline.dart`
- `lib/app/offline_package_loaders_module.dart`
- `lib/features/customers/domain/services/customer_offline_package_entity_loader.dart`
- `lib/features/pricing/domain/usecases/load_initial_price_list_offline_data_use_case.dart`
- `lib/features/pricing/domain/usecases/load_initial_payment_term_offline_data_use_case.dart`
- `lib/features/pricing/domain/services/price_list_offline_package_entity_loader.dart`
- `lib/features/pricing/domain/services/payment_term_offline_package_entity_loader.dart`
- Testes: `test/core/offline/**`,
  `test/features/pricing/domain/usecases/load_initial_price_list_offline_data_use_case_test.dart`,
  `test/features/pricing/domain/usecases/load_initial_payment_term_offline_data_use_case_test.dart`,
  `test/features/pricing/domain/services/price_list_offline_package_entity_loader_test.dart`,
  `test/features/pricing/domain/services/payment_term_offline_package_entity_loader_test.dart`

## Arquivos alterados

- `lib/core/database/app_database.dart` (`schemaVersion` 13→14, nova tabela, migração,
  helpers `markOfflinePackageEntityIncomplete`/`markOfflinePackageEntityComplete`/
  `getOfflinePackageStatuses`) e `app_database.g.dart` (gerado)
- `lib/core/database/database.dart` (export da nova tabela)
- `lib/features/customers/domain/usecases/load_initial_customer_offline_data_use_case.dart`
  (parâmetros opcionais de cancelamento/progresso, retrocompatíveis)
- `lib/features/customers/domain/entities/customer_offline_load_summary.dart` (campo
  `cancelled`, default `false`)
- `lib/features/customers/customers.dart`, `lib/features/pricing/pricing.dart` (exports)
- `lib/app/injection.config.dart` (gerado via `build_runner`)
- `test/core/database/app_database_task_106_schema_test.dart`,
  `test/core/database/app_database_test.dart`,
  `test/core/database/app_database_warehouses_test.dart` (assert de `schemaVersion` atualizado
  de 13 para 14 — pré-existentes, quebrados só pelo bump de versão desta task)
- `test/features/customers/domain/usecases/load_initial_customer_offline_data_use_case_test.dart`
  (novo teste de cancelamento)

Não alterado: `AGENTS.md` (modificação preexistente fora do escopo desta task, deixada como
estava, conforme instrução).

## Pendências e riscos conhecidos

- **Escopo de entidades parcial.** `tasks.md` (seção 5.1) pede clientes, produtos, variantes,
  cores, grades, tabelas de preço, condições de pagamento, estoque resumido, campanhas,
  pedidos recentes, catálogos, metas e parâmetros comerciais. Hoje só **clientes**, **tabelas
  de preço** e **condições de pagamento** têm loader registrado, porque são as únicas entidades
  com local store Drift já ligado a um fluxo de carga real (o restante — produtos/variantes,
  estoque, campanhas/catálogos, metas — tem tabela Drift modelada desde TASK-106, e
  estoque/warehouse já tem até mapper local pronto, mas nenhuma tem `XLocalStoreRepository`
  nem fluxo de carga inicial ainda). O motor foi desenhado para ser extensível sem mudança de
  arquitetura: cada novo loader só precisa implementar `OfflinePackageEntityLoader` e ser
  adicionado a `OfflinePackageLoadersModule`. Ampliar essa cobertura é trabalho natural de uma
  próxima task (ou de quem entregar o local store de produtos/estoque/campanhas).
- **Sem tela/UI.** Só o Cubit foi entregue (agente desta task foi só Flutter Senior). A UI de
  download com barra de progresso/tamanho estimado/cancelar é trabalho do
  `flutter-ui-design-specialist` numa task futura (provável candidata: parte da Central de
  Sincronização, TASK-112, ou uma task dedicada de onboarding offline).
- **Resumo é por entidade, não por lote interno.** Uma entidade cancelada/falha no meio nunca
  deixa dado parcial no banco (a escrita local de cada entidade é atômica), mas ao retomar, essa
  entidade é buscada do zero (não retoma exatamente a página em que parou). Retomada fina por
  página é responsabilidade explícita do motor de sincronização incremental (TASK-109), que já
  tinha esse mesmo comentário de extensão em `AppDatabase.replaceCustomers`/`replacePriceLists`
  desde as tasks anteriores.
- **Estimativa de tamanho é heurística.** Não existe endpoint remoto barato de contagem para
  clientes/tabelas de preço; a estimativa usa a contagem local já armazenada de uma carga
  anterior (`0` na primeira carga do dispositivo). Documentado no próprio contrato
  `OfflinePackageEntityLoader.estimate`.

## Validações executadas (resultados reais)

- `dart format --set-exit-if-changed .` → `Formatted 1729 files (0 changed)` (limpo após ajustes).
- `flutter analyze` → `3 issues found` (os 3 já existiam antes desta task, em arquivos não
  tocados por ela: `cloud_functions_order_approval_data_source.dart`,
  `cloud_functions_order_submission_data_source.dart`,
  `add_items_to_order_draft_use_case_test.dart`).
- `flutter test` (suíte completa) → `+2202 -0`, todos verdes, incluindo os 37 testes novos desta
  task e os 3 testes pré-existentes de schema (`app_database_test.dart`,
  `app_database_warehouses_test.dart`, `app_database_task_106_schema_test.dart`) corrigidos para
  o novo `schemaVersion` 14.
- `flutter pub run build_runner build` (duas vezes: schema Drift + injectable) → sucesso, sem
  warnings de dependência não registrada nas classes desta task.

## Referências

- Especificação: `tasks.md`, seção 5.1 e VESTI-080.
- ADR do banco local: `docs/adr/0003-banco-local-drift.md` (TASK-105).
- Schema local completo: TASK-106 (`lib/core/database/app_database.dart`).
