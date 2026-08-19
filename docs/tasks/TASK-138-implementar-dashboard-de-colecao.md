# TASK-138 — Implementar dashboard de coleção

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-066 (coleções e estações — dimensão de agrupamento deste dashboard)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Collection Dashboard (seção 12.1 de `tasks.md`): performance por coleção/estação, com comparação entre coleções, permitindo ao gestor de produto/comercial avaliar o desempenho de cada lançamento sazonal.

## Escopo técnico

- Criar `CollectionDashboardBloc` consumindo os snapshots de faturamento/quantidade agrupados por coleção/estação (TASK-133) via `AggregationRepository`.
- Exibir KPIs por coleção: faturamento, quantidade vendida, ticket médio, margem, mix médio de categorias dentro da coleção, e sell-through (percentual do estoque inicial da coleção já vendido).
- Implementar comparação lado a lado entre duas ou mais coleções (mesma estação de anos diferentes, ou coleções concorrentes da mesma estação), com os mesmos KPIs alinhados.
- Implementar drill-down da coleção até os produtos que a compõem (reaproveitando o dashboard de produtos, TASK-137, filtrado pela coleção).
- Registrar evento de analytics `dashboard_viewed` (tipo `collection`).

## Regras de negócio e restrições

- Sell-through deve ser calculado a partir do estoque inicial alocado à coleção e do saldo atual (TASK-090), nunca estimado sem base real de estoque.
- Comparação entre coleções de estações diferentes deve deixar explícito o período de cada uma (nunca comparar silenciosamente coleções de durações distintas).
- Apenas coleções publicadas (não rascunhos) entram na análise comparativa.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento de uma coleção, comparação entre duas ou mais coleções, coleção sem vendas no período.
- Teste do cálculo de sell-through com estoque inicial e saldo atual variados (incluindo saldo zerado).
- Teste de drill-down da coleção até os produtos filtrados no dashboard de produtos.
- Teste de widget para comparação lado a lado em desktop e empilhada em mobile.

## Critérios de aceite

- Dashboard exibe faturamento, quantidade vendida, ticket médio, margem, mix médio e sell-through por coleção.
- Comparação entre coleções funcional, com período de cada coleção explícito na visualização.
- Drill-down da coleção até os produtos que a compõem funcional.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
