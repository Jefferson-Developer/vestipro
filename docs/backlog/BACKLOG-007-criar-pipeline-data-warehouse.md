# BACKLOG-007 — Criar pipeline de Data Warehouse / BigQuery (⏸️ adiada a pedido do usuário)

**Origem:** TASK-205 — Criar pipeline de Data Warehouse / BigQuery (EPIC-31 — Administração Avançada
e Data Platform), movida do índice obrigatório de `docs/tasks/TASKS.md` para o backlog em 2026-09-10,
a pedido explícito do usuário durante uma rodada de `/proximas-tasks`.

**Spec original (critérios de aceite completos):**
[`docs/tasks/TASK-205-criar-pipeline-data-warehouse.md`](../tasks/TASK-205-criar-pipeline-data-warehouse.md).

## Por que foi movida para o backlog

Não é um bloqueio técnico ou de acesso — é uma decisão de priorização do usuário: ele pediu para
adiar TASK-204, TASK-205 e TASK-206 (as três tasks pendentes do EPIC-31) para depois, sem executá-las
nesta rodada. Nenhuma implementação foi iniciada.

## O que já existe e pode ser reaproveitado quando isto for retomado

- Camada de agregação server-side (TASK-133), referência de dados já consolidados a serem também
  exportados ao Data Warehouse.
- ADR de banco local (TASK-105) como padrão de formato para o ADR de decisão de pipeline
  (extensão oficial "Export Collections to BigQuery" vs. pipeline próprio).

## Quem precisa agir (pré-requisito para reabrir esta task)

| Pendência | Quem precisa agir |
|---|---|
| Decidir quando retomar a implementação | Usuário/responsável de produto |
| Providenciar/confirmar acesso a um projeto BigQuery real para validar o pipeline (staging) | Infra com acesso ao Google Cloud/Firebase Console do projeto real |

## Como reabrir

Quando o usuário quiser retomar, promova este item de volta a uma TASK-XXX formal em
`docs/tasks/TASKS.md` (reaproveitando a spec original em
`docs/tasks/TASK-205-criar-pipeline-data-warehouse.md`) e execute o fluxo normal de `/proxima-task`.
Nota: TASK-206 (camada semântica de BI) depende desta task, então a ordem de retomada deve respeitar
essa dependência.
