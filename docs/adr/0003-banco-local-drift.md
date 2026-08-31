# ADR-0003 - Banco local: Drift/SQLite vs. Isar

## Status

Aceita em 2026-08-31.

## Contexto

A seção 5.2 de `tasks.md` pede um banco local "apropriado ao Flutter, preferencialmente Drift/SQLite,
ou Isar se houver justificativa técnica", com a escolha documentada por ADR. A TASK-105
(`docs/tasks/TASK-105-criar-adr-de-banco-local.md`, EPIC-14 — Offline e Sincronização) formaliza essa
decisão para servir de base única e sem ambiguidade às ~15 tasks seguintes do EPIC-14 (schema local,
Outbox, motor de sincronização incremental, resolução de conflitos, indicador de conectividade).

Ao iniciar esta task, o repositório já continha uma decisão de fato tomada e em uso extenso, não um
cenário em branco:

- ADR-0001 (`docs/adr/0001-dependencias-base.md`, TASK-003) já registrou `drift`, `drift_flutter` e
  `drift_dev` como as dependências de banco local/offline do projeto, com uma nota explícita de que o
  suporte Web (`sqlite3.wasm` + worker) ficaria para a task de schema/offline.
- `lib/core/database/app_database.dart` já define um `AppDatabase` (`@DriftDatabase`) real, em
  `schemaVersion` 12, com 12 migrações incrementais (`onUpgrade` de `from < 2` até `from < 12`) já
  aplicadas ao longo das TASK-048 a TASK-104 (EPIC-06, EPIC-08, EPIC-09, EPIC-11, EPIC-12, EPIC-13).
- Há 12 tabelas Drift reais em `lib/core/database/tables/` (clientes, endereços, contatos, favoritos,
  índice de busca de produto, tabelas de preço e seus itens, condições de pagamento, warehouses, saldo
  de estoque por variante, pedidos e itens de pedido), todas seguindo o mesmo padrão de campos de
  sincronização da seção 5.3 de `tasks.md` (`id`, `organizationId`, `companyId`, `createdAt/By`,
  `updatedAt/By`, `deletedAt`, `version`, `syncStatus`).
- Há 17 arquivos de teste automatizado (`test/core/database/**`, `test/features/**/data/**`) que já
  exercitam esse `AppDatabase` com `NativeDatabase.memory()`, incluindo criação de schema, leitura,
  escrita, `ON DELETE CASCADE` e migração incremental — nenhum usa Isar.

Ou seja: a escolha técnica por Drift já havia sido tomada operacionalmente na TASK-003 e validada em
produção de código por 10 tasks subsequentes, sem que existisse até agora o ADR formal que a seção 5.2
exige. Esta task fecha essa lacuna documental, avalia Isar como alternativa com os mesmos critérios
objetivos pedidos pela TASK-105 e confirma (ou reverteria, se a análise apontasse nisso) a decisão já
em uso.

## Alternativas consideradas

### Drift/SQLite (`drift` + `drift_flutter` + `drift_dev`)

- **Queries relacionais complexas**: SQL real com joins tipados. Já comprovado no próprio
  `AppDatabase` — `getCustomersForCompany`/`getOrdersForCompany` combinam cliente/endereço/contato e
  pedido/itens em uma única leitura consistente, exatamente o padrão que TASK-106+ vai precisar entre
  pedidos, itens, variantes e tabelas de preço.
- **Volume esperado** (milhares de variantes, centenas de clientes por vendedor): SQLite lida bem com
  esse volume em dispositivo móvel; índices explícitos (`@TableIndex`, ex.:
  `idx_orders_org_company`, `idx_orders_customer`) já usados para as buscas por tenant/cliente mais
  frequentes.
- **Migrações versionadas**: `MigrationStrategy.onUpgrade` com migração incremental por
  `schemaVersion`, já testada em produção de código (12 versões incrementais, cobertas por
  `app_database_warehouses_test.dart` como exemplo de teste de migração dedicado).
- **Maturidade/manutenção**: pacote mantido pela Simon Binder (autor também do `sqlite3` Dart),
  atualizações frequentes, uso amplo na comunidade Flutter, sem sinais de abandono.
- **Flutter Web**: suporte real via `drift_flutter` + `sqlite3.wasm`/worker (mecanismo documentado e
  já antecipado no ADR-0001); exige arquivos estáticos adicionais no build Web, tratado como pendência
  explícita para a task de schema/offline (TASK-106), não um bloqueio à escolha do pacote.
- **Integração com `freezed`/`build_runner`**: já convive no mesmo pipeline `build_runner` do projeto
  (`drift_dev` ao lado de `freezed`, `json_serializable`, `injectable_generator`), gerando
  `app_database.g.dart` sem conflito.
- **Testabilidade**: `NativeDatabase.memory()` cria um banco SQLite em memória sem depender de nenhum
  binário nativo externo nem de emulador — já usado em todos os testes de repositório do projeto,
  rodando em milissegundos.
- **Isolamento multi-tenant**: toda tabela carrega `organizationId`/`companyId`; toda query em
  `AppDatabase` filtra explicitamente por esses campos (nenhuma consulta genérica "sem escopo"),
  reforçado por índice composto quando a tabela é consultada com frequência por tenant.

### Isar

- **Modelo**: NoSQL orientado a objeto (coleções, não tabelas relacionais); relações entre coleções
  usam `IsarLinks`, que não oferecem o mesmo nível de join/agrupamento SQL que pedidos, itens,
  variantes e tabelas de preço exigem (grade comercial e resumo de pedido combinam essas quatro
  entidades ao mesmo tempo).
- **Migração de schema**: versionamento de schema menos explícito/controlado que `MigrationStrategy`
  do Drift; risco maior de mudança silenciosa de schema entre versões do app sem uma trilha de
  migração tão auditável quanto o `onUpgrade` incremental já em uso.
- **Maturidade/manutenção**: a manutenção oficial do pacote `isar` (v3, isar-community em pub.dev)
  ficou historicamente mais lenta que a do `drift`/`sqlite3` desde 2023, com a comunidade migrando
  parte do ecossistema para um fork (`isar_community`); menor previsibilidade de longo prazo para um
  produto que depende do banco local para todo o EPIC-14 em diante.
- **Flutter Web**: suporte Web do Isar é mais limitado/experimental que o de `drift_flutter` (que se
  apoia diretamente no `sqlite3` compilado para wasm); o VestiPro precisa de paridade real entre
  Android, iOS e Web (seção 1 de `tasks.md`), o que pesa contra o Isar.
- **Integração com `freezed`/`build_runner`**: tecnicamente possível (`isar_generator` também roda em
  `build_runner`), mas exigiria reintroduzir um segundo gerador de schema convivendo com `drift_dev`
  já em produção, sem ganho compensador dado o restante desta análise.
- **Testabilidade**: também suporta instância em memória para teste, mas exigiria reescrever toda a
  suíte de testes de repositório já existente (17 arquivos) que hoje depende de `NativeDatabase`.
- **Vantagem real**: API mais simples/menos verbosa que SQL explícito para casos de objeto único sem
  relações complexas — não é o caso predominante do domínio comercial do VestiPro (pedido, item, grade,
  preço são fortemente relacionais).

## Decisão

Mantém-se **Drift/SQLite** como o banco local definitivo do VestiPro, para todas as tabelas ofline já
existentes e para todo o schema que TASK-106 em diante (Outbox, motor de sincronização, conflitos)
vier a modelar. Não há adoção de Isar em nenhuma parte do app.

Esta decisão:

- Confirma formalmente, com os critérios objetivos pedidos pela TASK-105, a escolha já operacional
  desde a TASK-003/ADR-0001 e usada em 12 tabelas reais no schema `AppDatabase` (versão 12).
- Usa como prova de viabilidade (spike) a suíte de testes já existente e reexecutada nesta task:
  `test/core/database/app_database_test.dart`, `test/core/database/app_database_orders_test.dart` e
  `test/core/database/app_database_warehouses_test.dart` — juntos, criam o schema em um banco SQLite
  em memória (`NativeDatabase.memory()`), leem e escrevem linhas reais (clientes, endereços, contatos,
  pedidos, itens de pedido, warehouses), validam `ON DELETE CASCADE` e uma migração incremental de
  schema (versão 8, `warehouses`). Reexecutados nesta task via `flutter test test/core/database/`:
  30 testes, todos passando (`All tests passed!`), sem nenhum erro de plataforma.
- Isar não é adotado; qualquer reversão futura dessa decisão exige um novo ADR explícito (nunca uma
  troca silenciosa de banco local em uma task de feature), conforme a restrição da própria TASK-105.

## Consequências

- TASK-106 (Modelar schema local Drift) e as demais tasks do EPIC-14 (Outbox, motor de sincronização,
  resolução de conflitos, central de sincronização, indicador de conectividade) devem estender o mesmo
  `AppDatabase`/mesma cadeia de migração já existente em `lib/core/database/app_database.dart`, nunca
  criar um segundo banco local. Isso já está documentado como restrição explícita nos comentários da
  classe `AppDatabase`.
- Todo novo campo/tabela sincronizável deve seguir o padrão de sync já em uso (`organizationId`,
  `companyId` quando aplicável, `createdAt/By`, `updatedAt/By`, `deletedAt`, `version`, `syncStatus`),
  como já ocorre em `OrdersTable`/`CustomersTable`.
- Suporte Flutter Web pleno (build com `sqlite3.wasm`/worker do `drift_flutter`, e uma verificação
  automatizada rodando de fato no alvo Web) continua pendente e é responsabilidade explícita da
  TASK-106 (schema local) — hoje a suíte de testes roda apenas no target VM/nativo (`flutter test`),
  não em `flutter test -d chrome`; esta é uma pendência conhecida herdada do ADR-0001, não resolvida
  nesta task.
- Verbosidade do `drift_dev`/SQL explícito é o trade-off conscientemente aceito em troca de joins
  relacionais reais, migração versionada auditável e testabilidade em memória sem dependências
  nativas — considerado o custo certo dado o domínio fortemente relacional de pedido/item/variante/
  preço do VestiPro.
- `lib/core/database/README.md` foi atualizado para apontar este ADR como fonte da verdade da decisão
  de banco local.

## Fontes consultadas

- `tasks.md` (raiz do projeto), seções 1, 5.2, 5.3, 5.4, 5.5.
- `docs/adr/0001-dependencias-base.md` (decisão original de dependências, incluindo `drift`/
  `drift_flutter`/`drift_dev`).
- `lib/core/database/app_database.dart`, `lib/core/database/tables/*.dart` (schema real já
  implementado, 12 tabelas, `schemaVersion` 12).
- `test/core/database/app_database_test.dart`, `test/core/database/app_database_orders_test.dart`,
  `test/core/database/app_database_warehouses_test.dart` (spike/prova de viabilidade reexecutada nesta
  task via `flutter test test/core/database/`).
- https://pub.dev/packages/drift
- https://pub.dev/packages/drift_flutter
- https://pub.dev/packages/isar
- https://pub.dev/packages/isar_community
