# TASK-089 — Modelar Warehouse

**Epic:** EPIC-12 — Estoque e Disponibilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-027 — Modelar Company e Branch (Warehouse precisa se vincular a uma empresa/unidade já existente para escopar saldo e disponibilidade corretamente)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade `Warehouse` (depósito/unidade de estoque) vinculada a Company/Branch, servindo de base estrutural para saldo por variante, estoque futuro, reserva comercial e alertas de ruptura das próximas tasks do EPIC-12. Esta task é puramente estrutural — nenhuma regra de saldo é implementada aqui.

## Escopo técnico

- Criar entidade `Warehouse` no domain de `features/inventory` com: `id`, `organizationId`, `companyId`, `branchId` (nullable quando o depósito for centralizado e atender múltiplas branches), `code`, `name`, `type` (ex.: matriz, centro de distribuição, loja, consignado), `isActive`, `priority` (ordem de prioridade quando múltiplos depósitos atendem a mesma branch), além dos campos padrão offline-first (`createdAt/By`, `updatedAt/By`, `deletedAt`, `version`, `syncStatus`).
- Criar `WarehouseDto`, mapper e contrato de repositório no domain, com implementação em `data` (datasource Firestore + Drift).
- Modelar a coleção Firestore a partir do padrão real de consulta de saldo (não por conveniência de UI) — ex.: `organizations/{orgId}/warehouses/{warehouseId}`.
- Criar tabela Drift `warehouses` com índice composto por `organizationId + companyId + branchId` para suportar consultas offline eficientes.
- Registrar como decisão documentada (na evidência de conclusão) se a relação Warehouse↔Branch é 1:N ou N:N (ex.: um CD atendendo múltiplas branches).
- Criar casos de uso mínimos: `GetWarehousesByCompany`, `GetActiveWarehouses`.

## Regras de negócio e restrições

- `organizationId`/`companyId` nunca inferidos apenas pelo cliente; toda query é escopada pela organização/empresa ativa da sessão autenticada.
- Warehouse inativo (`isActive = false`) não pode ser selecionado em novas operações de saldo/reserva, mas seu histórico permanece consultável (soft delete via `deletedAt`).
- Nenhuma regra de cálculo de saldo, disponibilidade ou reserva é implementada nesta task.

## Testes obrigatórios

- Testes unitários de entidade e mapper (DTO ↔ Entity) cobrindo campos obrigatórios, opcionais e `branchId` nulo.
- Teste de caso de uso com repositório mockado (mocktail) para busca por company/branch e para filtro de ativos.
- Teste de Firestore Security Rules (Emulator Suite) com caso positivo e negativo, garantindo que um usuário de outra organização não lê/escreve warehouses de organização diferente.
- Teste de migração Drift para a nova tabela `warehouses`.

## Critérios de aceite

- Entidade, DTO, mapper, repositório e casos de uso mínimos implementados, testados e sem código morto.
- Warehouse corretamente vinculado a Company/Branch existentes (TASK-027), sem duplicar modelo já existente.
- Security Rules com teste positivo e negativo para a nova coleção.
- Nenhuma tela/UI criada nesta task.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
