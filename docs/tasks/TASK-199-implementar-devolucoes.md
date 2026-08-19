# TASK-199 — Implementar devoluções

**Epic:** EPIC-30 — Pós-venda
**Status:** ⬜ Pendente
**Depende de:** TASK-101 (submissão do pedido, origem à qual toda devolução deve estar vinculada)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o fluxo de solicitação de devolução vinculado ao pedido original, com motivo obrigatório, e com impacto no estoque e no financeiro rastreado de ponta a ponta (incluindo eventual estorno de comissão, ver EPIC-29).

## Escopo técnico

- Modelar `ReturnRequest` (orderId, itens/variantes e quantidades devolvidas, motivo obrigatório categorizado — ex.: defeito, troca de decisão, erro de pedido —, status: solicitada/em análise/aprovada/recusada/concluída).
- Cloud Function `createReturnRequest` valida que os itens/quantidades pertencem ao pedido original e não excedem o que foi de fato comprado; `resolveReturnRequest` aplica a decisão (aprovar/recusar) e dispara os efeitos (reposição de estoque, ajuste financeiro).
- Ao aprovar, reintegrar a quantidade ao saldo do warehouse de origem (TASK-090) e sinalizar o impacto financeiro (estorno/nota de crédito) de forma rastreável até o pedido original.
- Tela de solicitação de devolução (vendedor/cliente conforme perfil habilitado), exigindo motivo obrigatório e evidência opcional (foto), e tela de análise para quem aprova.
- Histórico de devoluções vinculado ao pedido (visível na listagem/detalhe de pedido, TASK-102).

## Regras de negócio e restrições

- Toda devolução exige motivo obrigatório categorizado; texto livre nunca substitui a categoria.
- Quantidade devolvida nunca pode exceder a quantidade original do item no pedido; validado sempre server-side.
- Reposição de estoque e qualquer ajuste financeiro só ocorrem após aprovação formal, nunca automaticamente na simples solicitação.
- Toda decisão (aprovação/recusa) é registrada com autor, timestamp e motivo, na trilha de auditoria do pedido.
- Isolamento multi-tenant: devolução de um pedido só pode ser criada/vista por usuários da mesma organização do pedido.

## Testes obrigatórios

- Testes da Cloud Function: solicitação válida, quantidade excedente (rejeitada), aprovação com reposição de estoque correta, recusa sem efeito no estoque.
- Testes de RBAC: quem pode solicitar vs. quem pode aprovar.
- Testes de auditoria: histórico completo de decisões por devolução.
- Testes de widget: formulário de solicitação com motivo obrigatório, tela de análise, histórico no detalhe do pedido.

## Critérios de aceite

- Devolução sempre exige motivo categorizado e nunca excede a quantidade do pedido original.
- Estoque só é reposto após aprovação formal, de forma rastreável.
- Toda decisão fica auditável no histórico do pedido.
- Isolamento multi-tenant é respeitado em toda a operação.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
