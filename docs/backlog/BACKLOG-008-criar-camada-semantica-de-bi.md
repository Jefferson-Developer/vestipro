# BACKLOG-008 — Criar camada semântica de BI (⏸️ adiada a pedido do usuário)

**Origem:** TASK-206 — Criar camada semântica de BI (EPIC-31 — Administração Avançada e Data
Platform), movida do índice obrigatório de `docs/tasks/TASKS.md` para o backlog em 2026-09-10, a
pedido explícito do usuário durante uma rodada de `/proximas-tasks`.

**Spec original (critérios de aceite completos):**
[`docs/tasks/TASK-206-criar-camada-semantica-de-bi.md`](../tasks/TASK-206-criar-camada-semantica-de-bi.md).

## Por que foi movida para o backlog

Não é um bloqueio técnico ou de acesso — é uma decisão de priorização do usuário: ele pediu para
adiar TASK-204, TASK-205 e TASK-206 (as três tasks pendentes do EPIC-31) para depois, sem executá-las
nesta rodada. Nenhuma implementação foi iniciada.

## O que já existe e pode ser reaproveitado quando isto for retomado

- Camada de agregação server-side (TASK-133) e pipeline de Data Warehouse (TASK-205, também adiada —
  ver [BACKLOG-007](BACKLOG-007-criar-pipeline-data-warehouse.md)), os dois caminhos de cálculo que
  esta task precisa unificar.
- Motor de precificação server-side (TASK-088), que a camada semântica não deve duplicar.

## Quem precisa agir (pré-requisito para reabrir esta task)

| Pendência | Quem precisa agir |
|---|---|
| Decidir quando retomar a implementação | Usuário/responsável de produto |
| Retomar antes (ou junto) o BACKLOG-007 (TASK-205), do qual esta task depende diretamente | Mesmo responsável que retomar o BACKLOG-007 |

## Como reabrir

Quando o usuário quiser retomar, promova este item de volta a uma TASK-XXX formal em
`docs/tasks/TASKS.md` (reaproveitando a spec original em
`docs/tasks/TASK-206-criar-camada-semantica-de-bi.md`) e execute o fluxo normal de `/proxima-task`,
respeitando a dependência de TASK-205/BACKLOG-007.
