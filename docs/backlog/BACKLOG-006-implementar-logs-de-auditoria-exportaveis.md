# BACKLOG-006 — Implementar logs de auditoria exportáveis (⏸️ adiada a pedido do usuário)

**Origem:** TASK-204 — Implementar logs de auditoria exportáveis (EPIC-31 — Administração Avançada e
Data Platform), movida do índice obrigatório de `docs/tasks/TASKS.md` para o backlog em 2026-09-10,
a pedido explícito do usuário durante uma rodada de `/proximas-tasks`.

**Spec original (critérios de aceite completos):**
[`docs/tasks/TASK-204-implementar-logs-de-auditoria-exportaveis.md`](../tasks/TASK-204-implementar-logs-de-auditoria-exportaveis.md).

## Por que foi movida para o backlog

Não é um bloqueio técnico ou de acesso — é uma decisão de priorização do usuário: ele pediu para
adiar TASK-204, TASK-205 e TASK-206 (as três tasks pendentes do EPIC-31) para depois, sem executá-las
nesta rodada. Nenhuma implementação foi iniciada.

## O que já existe e pode ser reaproveitado quando isto for retomado

- Audit log central (TASK-033) e tela de auditoria de acessos (TASK-047), que são a fonte dos
  registros a serem exportados.
- Exportação CSV/XLSX/PDF de relatórios (EPIC-18, TASK-146 a TASK-148), reaproveitável como base para
  a geração dos arquivos de exportação do audit log.

## Quem precisa agir (pré-requisito para reabrir esta task)

| Pendência | Quem precisa agir |
|---|---|
| Decidir quando retomar a implementação | Usuário/responsável de produto |

## Como reabrir

Quando o usuário quiser retomar, promova este item de volta a uma TASK-XXX formal em
`docs/tasks/TASKS.md` (reaproveitando a spec original em
`docs/tasks/TASK-204-implementar-logs-de-auditoria-exportaveis.md`) e execute o fluxo normal de
`/proxima-task`.
