# TASK-103 — Implementar aprovação de pedidos

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-101 — Implementar submissão do pedido (aprovação intercepta o fluxo de submissão); TASK-029 — Implementar RBAC (define quem pode aprovar); TASK-086 — Implementar políticas de desconto por perfil (define o limite que dispara a aprovação)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o fluxo de aprovação para pedidos com desconto ou condição especial acima do limite do perfil do vendedor, com notificação ao aprovador e trilha de decisão (quem aprovou/rejeitou e quando).

## Escopo técnico

- Criar Cloud Function/regra que, na submissão (TASK-101), detecta quando o pedido excede o limite de desconto/condição do perfil do vendedor (política definida em TASK-086) e transiciona o status para `under_review` em vez de seguir direto para `submitted` (ou de `submitted` para `under_review`, conforme desenho final da máquina de estados da TASK-095).
- Criar entidade `OrderApprovalDecision` (`approverId`, `decision`: `approved`/`rejected`, `reason`, `decidedAt`) vinculada ao pedido.
- Implementar tela de fila de aprovação para o perfil aprovador (ex.: `SALES_MANAGER`), com detalhe do pedido, motivo do encaminhamento (qual regra foi excedida) e ações de aprovar/rejeitar com justificativa.
- Disparar notificação ao aprovador quando um pedido entrar em `under_review` (hook para integração futura com FCM/central de notificações — TASK-150/TASK-151, sem exigir que já estejam prontas).
- Registrar a decisão na trilha de histórico do pedido (`OrderStatusHistoryEntry` + `OrderApprovalDecision`).

## Regras de negócio e restrições

- A regra de quais descontos/condições exigem aprovação vive na camada de domínio/Functions (TASK-086/TASK-029), nunca hardcoded na tela de aprovação.
- Apenas perfis com permissão de aprovação (RBAC) podem aprovar/rejeitar — validado em Function/Rules, não apenas ocultando o botão na UI.
- Pedido rejeitado retorna ao vendedor com o motivo, permitindo ajuste e reenvio (gera um novo ciclo de submissão, nunca reaproveita o pedido rejeitado como aprovado posteriormente).

## Testes obrigatórios

- Teste de Cloud Function cobrindo pedido dentro do limite (vai direto para `submitted`) versus acima do limite (vai para `under_review`).
- Teste de RBAC negando aprovação para perfil sem permissão (Emulator, Rules/Functions).
- Teste de widget da fila de aprovação cobrindo aprovar/rejeitar com justificativa obrigatória na rejeição.
- Teste garantindo que a trilha de decisão registra corretamente aprovador, decisão e timestamp.

## Critérios de aceite

- Pedido acima do limite de desconto/condição do perfil é automaticamente encaminhado para aprovação.
- Aprovador recebe notificação e consegue decidir com contexto completo (motivo do encaminhamento).
- Trilha de decisão (quem, quando, aprovado/rejeitado, motivo) registrada e consultável no histórico do pedido.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
