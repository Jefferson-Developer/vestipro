# TASK-108 — Implementar Outbox

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-106 (tabelas Drift existentes — a Outbox referencia registros por tipo de entidade + id)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a fila local (Outbox) de operações pendentes de sincronização — criação de pedido, atividade CRM, etc. — com uma máquina de estados robusta e persistência que sobrevive ao fechamento do app, conforme a seção 5.4 de `tasks.md`.

## Escopo técnico

- Criar `OutboxTable` no Drift com colunas: `id`, `organizationId`, `companyId`, `entityType` (enum: order, orderItem, crmActivity, customer, ...), `entityId`, `operationType` (create/update/delete), `payload` (JSON serializado do DTO da operação), `status` (pending/syncing/synced/failed/conflict), `attemptCount`, `lastAttemptAt`, `lastError`, `createdAt`, `createdBy`, `sequenceNumber` (ordem de criação local).
- Criar `OutboxRepository` com métodos `enqueue`, `markSyncing`, `markSynced`, `markFailed`, `markConflict` e listagem por status/entityType.
- Garantir ordem de processamento preservada quando relevante: operações sobre o mesmo `entityId` são processadas na ordem de criação (`sequenceNumber`), para nunca aplicar um `update` antes do `create` correspondente.
- Persistir o payload de forma re-executável de forma idempotente, incluindo um `clientOperationId` único gerado no momento da criação, usado depois pelo backend/Functions para deduplicar (ver TASK-109).
- Expor um stream/cubit reativo (`OutboxWatcherCubit`) para a Central de Sincronização (TASK-112) observar pendências/falhas em tempo real.
- Garantir que o `enqueue` e a operação local correspondente (ex.: gravar o pedido em rascunho) ocorram na mesma transação Drift — nunca a operação local sem o registro de Outbox, e vice-versa.

## Regras de negócio e restrições

- Toda operação offline crítica (pedido, atividade CRM) gera exatamente um registro de Outbox por operação, mesmo se o app fechar/crashar no meio.
- Nunca perder uma operação enfileirada: falha de sincronização move o registro para `failed`, nunca remove sem confirmação explícita de sucesso do backend.
- `attemptCount` e `lastError` alimentam a política de retry (TASK-109) e a UI de falhas (TASK-112).
- Operações sobre a mesma entidade são processadas em ordem — nunca em paralelo descontrolado quando há dependência (ex.: dois updates seguidos do mesmo pedido).

## Testes obrigatórios

- Teste garantindo que `enqueue` e a operação local ocorrem atomicamente (a transação impede que uma grave sem a outra).
- Teste de persistência da Outbox sobrevivendo a um "reinício simulado" do banco (reabrir a conexão Drift e confirmar que os registros `pending` continuam presentes).
- Teste de ordenação: duas operações sobre o mesmo `entityId` processadas na ordem correta (create antes de update).
- Teste de transição de estados `pending → syncing → synced` e `pending → syncing → failed → syncing` (retry).
- Teste de idempotência: reenviar o mesmo `clientOperationId` não gera duplicidade lógica.

## Critérios de aceite

- Outbox persiste operações pendentes e sobrevive ao fechamento/reabertura do app.
- Estados pending/syncing/synced/failed/conflict implementados e testados.
- Ordem de processamento por entidade preservada.
- `flutter analyze` e `flutter test` passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
