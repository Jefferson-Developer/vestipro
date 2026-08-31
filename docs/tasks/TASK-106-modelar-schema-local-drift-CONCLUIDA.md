# TASK-106 — Modelar schema local (Drift) — CONCLUÍDA

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** Concluída em 2026-08-31.
**Depende de:** TASK-105 (ADR-0003, `docs/adr/0003-banco-local-drift.md`).

## Estado real do repositório ao iniciar a task

Diferente do que o backlog original presumia ("este backlog foi escrito antes da implementação"), o
`AppDatabase` (`lib/core/database/app_database.dart`) já existia em produção de código, em
`schemaVersion` 12, com 12 tabelas Drift reais cobrindo clientes, endereços, contatos, favoritos,
índice de busca de produto, tabelas de preço e itens, condições de pagamento, warehouses, saldo de
estoque por variante, pedidos e itens de pedido — todas já seguindo o padrão de sincronização da
seção 5.3 de `tasks.md` (`organizationId`, `companyId`, `createdAt/By`, `updatedAt/By`, `deletedAt`,
`version`, `syncStatus`).

Comparando esse estado com a lista de entidades da carga offline (seção 5.1 de `tasks.md`) e com o
escopo técnico literal da task, faltavam 6 das 13 tabelas pedidas:

| Entidade da seção 5.1 | Situação encontrada |
| --- | --- |
| clientes | Já coberta (`CustomersTable` + relacionadas) |
| produtos | Faltava — só existia `ProductSearchIndexTable` (índice de busca estreito, TASK-069) |
| variantes | Faltava — nenhuma tabela local |
| cores | Faltava — nenhuma tabela local |
| grades | Faltava — nenhuma tabela local |
| tabelas de preço | Já coberta (`PriceListsTable`/`PriceListItemsTable`) |
| condições de pagamento | Já coberta (`PaymentTermsTable`) |
| estoque resumido | Já coberta (`VariantStockBalancesTable` + `WarehousesTable`) — equivalente funcional ao "InventorySnapshotsTable" do backlog original; não duplicada |
| campanhas | Faltava — nenhuma tabela local |
| pedidos recentes | Já coberta (`OrdersTable`/`OrderItemsTable`) |
| catálogos | Fora do escopo desta task (não há uma entidade "Catalog" separada de Product no domínio atual) |
| metas | Faltava — e o domínio `Target` ainda nem existe (deferido para TASK-114, EPIC-15) |
| parâmetros comerciais | Fora do escopo desta task (não há uma entidade dedicada; tratado por `DiscountPolicy`/settings fora do EPIC-14) |

## O que foi implementado

Seis novas tabelas Drift, cada uma espelhando a entidade de domínio equivalente já existente (quando
existente) e seguindo os mesmos convencionais já em uso no `AppDatabase` (JSON-columns para listas,
`@TableIndex` composto por tenant, soft delete via `deletedAt`, FK com `ON DELETE CASCADE` só onde a
tabela pai é substituída por reload completo):

- `lib/core/database/tables/colors_table.dart` — espelha `ProductColor` (TASK-070).
- `lib/core/database/tables/size_grids_table.dart` — espelha `SizeGridTemplate`/`SizeGridSize`
  (TASK-071), com `sizesJson` para a lista ordenada de tamanhos.
- `lib/core/database/tables/products_table.dart` — cache canônico completo do agregado `Product`
  (EPIC-08), distinto do `ProductSearchIndexTable` (TASK-069), que continua sendo apenas a projeção
  estreita de busca — ambos coexistem, alimentados pelo mesmo futuro pipeline de sync (TASK-109).
- `lib/core/database/tables/product_variants_table.dart` — espelha `ProductVariant` (TASK-072),
  com FK `productId → ProductsTable` (`ON DELETE CASCADE`), exatamente como pedido no escopo técnico
  da task. Sem `companyId`/`deletedAt` porque a entidade de domínio não os possui (documentado no
  arquivo).
- `lib/core/database/tables/campaigns_table.dart` — espelha `PromotionalCampaign` (EPIC-11).
- `lib/core/database/tables/targets_table.dart` — placeholder estrutural documentado explicitamente
  como **não** o schema final de `Target` (essa modelagem de domínio é o objetivo da própria
  TASK-114, "Modelar Target", EPIC-15/ainda não iniciada). Segue o mesmo precedente já usado no
  projeto para `ProductSearchIndexTable` e `OrdersTable` (tabela estrutural adiantada, antes do
  domínio/motor completo existir), para não bloquear a carga offline de metas nem duplicar trabalho
  de TASK-114.

`lib/core/database/app_database.dart`:

- Registrou as 6 tabelas na anotação `@DriftDatabase`.
- Subiu `schemaVersion` de 12 para 13.
- Adicionou o bloco `if (from < 13)` em `onUpgrade`, criando as 6 tabelas nesse incremento — sem
  alterar nenhuma migração anterior.
- Adicionou métodos de conveniência `replaceX`/`upsertX`/`getXFor...` para cada nova tabela, seguindo
  exatamente o mesmo padrão dos métodos já existentes (`replacePriceLists`/`upsertPriceList`/
  `getPriceListsForCompany`, etc.), como ponto de extensão para o motor de sincronização (TASK-109).

Código gerado (`app_database.g.dart`) foi regenerado via `flutter pub run build_runner build` e
versionado, seguindo a convenção já usada no projeto.

## Testes

Novo arquivo `test/core/database/app_database_task_106_schema_test.dart` (7 testes), cobrindo os 4
requisitos obrigatórios da task:

1. **Criação do schema (`onCreate`)** — abre um banco em memória na versão atual (13) e confirma que
   as 18 tabelas (12 antigas + 6 novas) existem, e que `product_variants` tem exatamente as colunas
   esperadas (incluindo a FK `product_id`).
2. **Migração incremental testada** — em vez de um esqueleto trivial 1→2, o teste exercita a
   migração real 12→13: semeia um arquivo sqlite bruto na "versão 12" (via `NativeDatabase` +
   `QueryExecutorUser` no-op, sem passar pelo `onCreate` do `AppDatabase`, com uma tabela/linha de
   controle `legacy_probe`), depois abre esse mesmo arquivo com o `AppDatabase` real (`schemaVersion`
   13). Confirma que `onUpgrade(from: 12, to: 13)` roda de fato, que a linha pré-existente
   (`legacy_probe`) é preservada intacta, e que as 6 tabelas novas passam a existir e funcionar através
   dos helpers recém-criados.
3. **Isolamento multi-tenant local** — grava cores/campanhas em duas organizações/empresas diferentes
   e confirma que cada consulta escopada retorna só as linhas do tenant correto.
4. **Soft delete** — grava uma cor e um produto com `deletedAt` preenchido; confirma que as consultas
   "ativas" (`getColorsForOrganization`/`getProductsForCompany`) os excluem, mas que a linha continua
   fisicamente na tabela (`select(...).get()` sem filtro ainda retorna as duas linhas).
5. Teste adicional de integridade referencial: `ON DELETE CASCADE` de `product_variants` quando o
   produto pai é removido por um `replaceProducts` com conjunto vazio.

Os dois testes pré-existentes que comparavam `database.schemaVersion` a `12`
(`test/core/database/app_database_test.dart`,
`test/core/database/app_database_warehouses_test.dart`) foram atualizados para `13`, já que o bump de
versão é uma consequência direta e esperada desta task.

## Comandos executados e resultados reais

- `flutter pub run build_runner build` — `Built with build_runner/aot in 17s; wrote 302 outputs.`
- `dart format lib/core/database test/core/database` — 2 arquivos formatados.
- `dart format --set-exit-if-changed .` (repo inteiro) — `Formatted 1703 files (0 changed)`.
- `flutter analyze` (repo inteiro) — `3 issues found`, todos `info`, pré-existentes e em arquivos não
  tocados por esta task (`cloud_functions_order_approval_data_source.dart`,
  `cloud_functions_order_submission_data_source.dart`,
  `add_items_to_order_draft_use_case_test.dart`).
- `flutter test test/core/database/` — 36 testes, todos passando.
- `flutter test test/features/customers/data test/features/favorites/data
  test/features/inventory/data test/features/pricing/data test/features/products/data
  test/features/orders` — 299 testes, todos passando (confirma que nenhum consumidor existente do
  `AppDatabase` quebrou com o bump de `schemaVersion`).
- `flutter test` (suíte completa do repositório) — 2171 testes, `All tests passed!`.

## Critérios de aceite (checklist)

- [x] Schema Drift cobrindo as entidades da carga offline (seção 5.1) com os campos de sincronização
      (seção 5.3), incluindo as que já existiam antes desta task.
- [x] Estratégia de migração implementada e testada (12→13 real, não apenas um esqueleto).
- [x] Isolamento multi-tenant local validado por teste automatizado.
- [x] `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` passam; código gerado
      do `build_runner` versionado.

## Pendências e riscos conhecidos

- **Suporte Web real (`sqlite3.wasm`/worker via `drift_flutter`)** continua pendente — herdado do
  ADR-0003/ADR-0001, não resolvido nesta task. A suíte de testes ainda roda só no target VM/nativo
  (`flutter test`), não em `flutter test -d chrome`.
- **`TargetsTable` é deliberadamente um placeholder estrutural**, não o schema final de metas — a
  TASK-114 ("Modelar Target", EPIC-15) deve revisar/estender essas colunas quando o domínio `Target`
  for de fato modelado, em vez de criar uma segunda tabela local.
- **"catálogos" e "parâmetros comerciais"** (seção 5.1) não ganharam tabela própria nesta task por não
  existir hoje uma entidade de domínio distinta e estável para elas (catálogo é hoje uma composição de
  `Product`/`Collection`/`Campaign`; parâmetros comerciais estão espalhados em `DiscountPolicy`/
  settings). Fica como observação para quando essas entidades forem modeladas em EPICs futuros.
- Nenhum motor de sincronização foi implementado nesta task — os métodos `replaceX`/`upsertX`
  adicionados são apenas primitivas de leitura/escrita local, consumidas pela TASK-108 (Outbox) e
  TASK-109 (motor de sincronização incremental), como já documentado nos comentários do código.

## Referências

- `lib/core/database/app_database.dart`
- `lib/core/database/tables/colors_table.dart`
- `lib/core/database/tables/size_grids_table.dart`
- `lib/core/database/tables/products_table.dart`
- `lib/core/database/tables/product_variants_table.dart`
- `lib/core/database/tables/campaigns_table.dart`
- `lib/core/database/tables/targets_table.dart`
- `test/core/database/app_database_task_106_schema_test.dart`
- `docs/adr/0003-banco-local-drift.md`
