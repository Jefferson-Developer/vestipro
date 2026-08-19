# TASK-058 — Implementar funil de vendas configurável

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-057 (Modelar Opportunity) — o funil organiza e movimenta as oportunidades já modeladas.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o pipeline de vendas com estágios configuráveis por organização, drag-and-drop entre estágios na Web e alternativa por ação explícita no mobile, exibindo contagem e valor total por estágio.

## Escopo técnico

- Entidade `PipelineStage` (id, organizationId, nome, ordem, cor/indicador visual, indicação de estágio terminal ganho/perdido), administrável em tela própria (criar/reordenar/renomear estágios).
- Página `SalesPipelinePage`: na Web, colunas por estágio com drag-and-drop (componente de patterns do Design System, TASK-025); no mobile, lista agrupada por estágio com ação explícita "Mover para estágio X", sem depender de gesto de arrastar.
- Cabeçalho de cada coluna/grupo exibindo contagem de oportunidades e valor total somado do estágio.
- `SalesPipelineBloc` com evento de mover oportunidade de estágio, validando transições permitidas.

## Regras de negócio e restrições

- Reordenar/renomear estágios é ação administrativa (RBAC restrito a `ADMIN`/`OWNER`/`SALES_MANAGER` conforme política).
- Mover oportunidade para um estágio terminal (ganho/perdido) deve disparar o fluxo de motivo obrigatório (TASK-057/061), nunca uma movimentação simples de coluna.
- Contagem e valor total por estágio devem refletir apenas oportunidades ativas dentro do escopo de visibilidade do usuário (RBAC de carteira/equipe).
- Drag-and-drop no Web é conveniência de UX; a movimentação real passa pelo mesmo caso de uso de domínio usado no mobile — nunca lógica duplicada entre as duas plataformas.

## Testes obrigatórios

- Teste de widget: drag-and-drop no Web movendo oportunidade e atualizando contagem/valor do estágio.
- Teste de widget: ação explícita de mover estágio no mobile (sem gesto).
- Teste de bloc: bloqueio de movimentação direta para estágio terminal sem motivo.
- Teste de RBAC: usuário sem permissão não consegue reordenar/renomear estágios.

## Critérios de aceite

- Funil configurável por organização, com estágios administráveis.
- Movimentação funciona via drag-and-drop no Web e ação explícita no mobile, usando o mesmo caso de uso de domínio.
- Contagem e valor total por estágio corretos e atualizados em tempo real após movimentação.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
