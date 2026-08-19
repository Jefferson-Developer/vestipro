# TASK-052 — Implementar detalhe do cliente 360º

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-049 (Implementar cadastro de cliente) — a tela consolida os dados cadastrais já implementados.

> **Nota:** esta tela consolidará também dados de pedidos (EPIC-13) e atividades CRM (TASK-059) quando essas features existirem. A primeira versão pode e deve exibir essas seções com placeholder claro de "ainda não disponível", nunca omitindo a seção ou quebrando a tela.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar uma tela única que consolide histórico comercial, atividades CRM, indicadores (score/health score) e oportunidades do cliente — a visão "360º" que sustenta o atendimento diário do vendedor em campo e do gestor.

## Escopo técnico

- Página `CustomerDetailPage` com seções: dados cadastrais (endereços/contatos da TASK-050), indicadores (score/health score da TASK-062, quando existir), timeline de atividades (TASK-059), oportunidades abertas (TASK-057/058), histórico de pedidos (EPIC-13) e próxima melhor ação (TASK-063).
- Cada seção cujo dado ainda não existir no repositório (pedidos, atividades, score) deve exibir um estado vazio explícito de "em breve", nunca erro nem seção quebrada ou ausente.
- Layout responsivo: mobile em abas/scroll vertical, desktop em colunas lado a lado aproveitando o espaço extra.
- Ação rápida de contato (ligar, registrar atividade) acessível no topo da tela.
- Navegação tipada via `go_router` (`/org/:orgId/customers/:customerId`).

## Regras de negócio e restrições

- Nunca ocultar uma seção inteira quando não houver dado — exibir estado vazio explicando o motivo (ex.: "Histórico de pedidos estará disponível quando o módulo de pedidos for implementado").
- Respeitar RBAC: campos financeiros/comerciais sensíveis visíveis apenas a perfis autorizados.
- Nenhuma consulta pode varrer dados de outra organização — escopo de tenant obrigatório em toda seção.

## Testes obrigatórios

- Testes de widget cobrindo todas as seções com dados completos, com dados parciais e com placeholders (seções ainda não implementadas).
- Teste de responsividade (mobile/tablet/desktop) da composição de seções.
- Teste de RBAC ocultando/exibindo seções sensíveis conforme o perfil do usuário.
- Teste de navegação para a rota tipada do cliente.

## Critérios de aceite

- Tela consolida todas as seções previstas, com placeholders claros para os módulos ainda não implementados.
- Layout funciona em mobile, tablet e desktop sem quebra visual.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
