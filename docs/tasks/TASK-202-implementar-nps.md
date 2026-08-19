# TASK-202 — Implementar NPS e pesquisa de satisfação

**Epic:** EPIC-30 — Pós-venda
**Status:** ⬜ Pendente
**Depende de:** TASK-201 (acompanhamento de pós-venda, fonte dos marcos que disparam a pesquisa)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar pesquisa de satisfação (NPS) disparada após marcos definidos do pós-venda (ex.: entrega confirmada, resolução de um problema reportado), calculando NPS agregado por vendedor/organização e alimentando dashboards existentes.

## Escopo técnico

- Cloud Function `triggerNpsSurvey` disparada por eventos da timeline de pós-venda (TASK-201) — ex.: evento "entregue" ou "resolvido" — que cria uma solicitação de pesquisa (`NpsSurveyRequest`) vinculada ao pedido/cliente, enviada pelo canal disponível (notificação interna, WhatsApp com opt-in de TASK-183, e-mail).
- Modelar `NpsResponse` (customerId, orderId de origem, nota 0–10, comentário opcional, data de resposta), com formulário simples de resposta (link com token, sem exigir login complexo do cliente, seguindo o mesmo padrão de segurança de link do compartilhamento de catálogo, TASK-081).
- Cálculo de NPS agregado (promotores menos detratores, sobre o total de respondentes) por vendedor, equipe e organização, via camada de agregação server-side (padrão de TASK-133) — nunca recalculado ad hoc no cliente.
- Alimentar dashboards existentes (ex.: dashboard do representante/executivo) com o indicador de NPS agregado e sua evolução no tempo.
- Evitar disparo duplicado de pesquisa para o mesmo marco do mesmo pedido (uma solicitação por marco relevante).

## Regras de negócio e restrições

- Envio de pesquisa respeita opt-in/consentimento de comunicação do cliente (mesmas regras de TASK-183/LGPD).
- Resposta de NPS é vinculada ao pedido/marco de origem, permitindo análise por vendedor/coleção/período sem expor a resposta de um cliente a outra organização.
- Cálculo de NPS agregado é sempre feito server-side, com fórmula única e documentada (evitar divergência de números entre telas — alinhado ao objetivo da camada semântica de BI, EPIC-31).
- Um mesmo marco de pedido não deve gerar múltiplas solicitações de pesquisa duplicadas ao mesmo cliente.

## Testes obrigatórios

- Testes da Cloud Function: disparo por marco válido, marco sem opt-in (não envia), tentativa de disparo duplicado (bloqueada).
- Testes de cálculo de NPS agregado: cenário com promotores/neutros/detratores, cenário sem respostas.
- Testes de segurança do link de resposta (mesmo padrão de TASK-081): token inválido/expirado.
- Testes de widget: formulário de resposta, indicador de NPS no dashboard, estado sem dados suficientes.

## Critérios de aceite

- Pesquisa é disparada automaticamente nos marcos definidos, respeitando o opt-in do cliente.
- Nenhum marco gera solicitação de pesquisa duplicada.
- NPS agregado por vendedor/organização é calculado de forma única e consistente, refletido nos dashboards.
- Resposta do cliente não expõe nem mistura dados entre organizações.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
