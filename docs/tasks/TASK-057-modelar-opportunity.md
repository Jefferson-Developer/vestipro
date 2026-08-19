# TASK-057 — Modelar Opportunity

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) e TASK-055 (Modelar Lead) — Opportunity referencia cliente e/ou lead de origem já definidos nessas entidades.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade `Opportunity` (valor estimado, probabilidade de fechamento, previsão de receita, responsável, estágio do funil, cliente ou lead de origem) — a base do pipeline de vendas descrito na seção 8 de `tasks.md`.

## Escopo técnico

- Entidade `Opportunity` com: id, organizationId, companyId, título/descrição, cliente vinculado (`customerId`, opcional se originada de lead ainda não convertido) ou lead vinculado (`leadId`), valor estimado, probabilidade de fechamento (%), previsão de receita (documentar se é calculada como valor estimado × probabilidade ou informada manualmente), responsável (`userId`), estágio (`stageId`, referenciando os estágios configuráveis de TASK-058), status geral (aberta/ganha/perdida), data prevista de fechamento, motivo de perda/ganho (referência a TASK-061 quando existir).
- Casos de uso: `CreateOpportunity`, `UpdateOpportunityStage`, `MarkOpportunityWon`, `MarkOpportunityLost` (exige motivo), `RecalculateRevenueForecast`.
- Contrato `OpportunityRepository`.
- Regra de origem rastreável: toda Opportunity possui `customerId` e/ou `leadId`, nunca ambos nulos.

## Regras de negócio e restrições

- Probabilidade de fechamento deve estar entre 0 e 100; previsão de receita nunca negativa.
- Mover para "ganha" ou "perdida" exige motivo (mesmo que o catálogo completo configurável só chegue em TASK-061 — aqui já modelar o campo obrigatório e bloquear a transição sem ele).
- Uma vez "ganha" ou "perdida", a Opportunity não deve mudar de estágio livremente — um eventual fluxo de reabertura deve ser uma ação explícita e auditada, nunca uma edição comum.
- `organizationId` sempre resolvido pela sessão autenticada.

## Testes obrigatórios

- Teste de cálculo de previsão de receita (valores limite: probabilidade 0%, 100%, valores negativos rejeitados).
- Teste de transição de estágio, incluindo bloqueio de transição a partir de "ganha"/"perdida" sem ação explícita de reabertura.
- Teste de `MarkOpportunityLost`/`MarkOpportunityWon` exigindo motivo.
- Teste da regra "customerId e leadId nunca ambos nulos" na criação.

## Critérios de aceite

- Entidade Opportunity modelada com todos os campos da especificação (valor, probabilidade, previsão, responsável, estágio, origem).
- Regras de transição de estágio e motivo obrigatório implementadas e testadas.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
