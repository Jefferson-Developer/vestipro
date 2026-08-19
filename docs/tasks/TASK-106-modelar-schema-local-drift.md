# TASK-106 — Modelar schema local (Drift)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-105 (ADR de banco local definindo Drift/SQLite como tecnologia escolhida)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar as tabelas Drift que espelham as entidades sincronizáveis essenciais da carga offline (clientes, produtos, variantes, tabelas de preço, pedidos, etc.), cada uma com os campos padrão de sincronização definidos na seção 5.3 de `tasks.md`, com estratégia de migração testada, servindo de schema base para a Outbox (TASK-108) e o motor de sincronização (TASK-109).

## Escopo técnico

- Criar `lib/core/database/app_database.dart` com Drift (`drift`, `drift_flutter`, `drift_dev`) definindo tabelas: `CustomersTable`, `ProductsTable`, `ProductVariantsTable`, `ColorsTable`, `SizeGridsTable`, `PriceListsTable`, `PriceListItemsTable`, `PaymentTermsTable`, `InventorySnapshotsTable`, `OrdersTable`, `OrderItemsTable`, `CampaignsTable`, `TargetsTable` — cobrindo os itens da carga offline listados na seção 5.1.
- Cada tabela deve conter as colunas padrão da seção 5.3: `id` (chave primária), `organizationId`, `companyId` (anulável quando não aplicável), `createdAt`, `createdBy`, `updatedAt`, `updatedBy`, `deletedAt` (anulável), `version` (inteiro) e `syncStatus` (enum via `TextColumn` com `TypeConverter`: pending/syncing/synced/failed/conflict).
- Criar índices compostos por `(organizationId, companyId)` e por chaves de busca frequentes (ex.: `customerId` em `OrdersTable`, `productId` em `ProductVariantsTable`) para evitar table scans em consultas offline.
- Definir `schemaVersion` e `MigrationStrategy` com `onCreate` e `onUpgrade` explícitos desde a v1, preparando o terreno para migrações incrementais futuras.
- Modelar relacionamentos via foreign keys onde fizer sentido (`OrderItemsTable` → `OrdersTable`, `ProductVariantsTable` → `ProductsTable`), garantindo que soft delete (`deletedAt`) não quebre a integridade referencial local.
- Gerar código via `build_runner`/`drift_dev` e versionar os arquivos gerados conforme convenção já usada no projeto.

## Regras de negócio e restrições

- Nenhuma tabela local pode ser consultada sem filtro por `organizationId` (e `companyId` quando aplicável) — essa responsabilidade é do repositório da camada `data`, nunca da UI.
- Soft delete: `deletedAt` é apenas marcado; nunca há `DELETE` físico automático (limpeza real fica para política de retenção/LGPD, fora do escopo desta task).
- `version` é incrementado a cada alteração local ou remota aplicada, e é consumido pelo motor de sincronização (TASK-109) e pela resolução de conflitos (TASK-110).
- `syncStatus` é o único campo de controle de fila na tabela de domínio; estado de UI não é persistido aqui.

## Testes obrigatórios

- Teste de criação do banco (`onCreate`) validando a existência de todas as tabelas e colunas obrigatórias.
- Teste de migração incremental simulando upgrade de `schemaVersion` 1→2 com dado existente preservado, mesmo que a migração real ainda não exista (criar um esqueleto de migração trivial para provar o mecanismo).
- Teste de consulta comprovando que filtros por `organizationId`+`companyId` retornam apenas os registros esperados (isolamento multi-tenant local).
- Teste de soft delete garantindo que um registro com `deletedAt` preenchido não aparece em consultas "ativas" padrão, mas permanece no banco.

## Critérios de aceite

- Schema Drift cobrindo todas as entidades da carga offline (seção 5.1) com os campos de sincronização (seção 5.3).
- Estratégia de migração implementada e testada, mesmo havendo apenas uma versão de schema até aqui.
- Isolamento multi-tenant local validado por teste automatizado.
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` passam; código gerado do `build_runner` versionado conforme convenção do projeto.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
