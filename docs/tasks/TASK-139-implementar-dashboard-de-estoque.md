# TASK-139 — Implementar dashboard de estoque

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-090 (saldo por variante — origem dos dados de estoque analisados)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Inventory Dashboard (seção 12.1 de `tasks.md`): cobertura, sell-through, produtos parados e alertas de ruptura consolidados, dando ao gestor de estoque/comercial uma visão única da saúde do inventário.

## Escopo técnico

- Criar `InventoryDashboardBloc` consumindo os snapshots de estoque/giro (TASK-133, alimentados pelos indicadores da TASK-094) via `AggregationRepository`.
- Exibir cobertura em dias por produto/categoria/depósito, sell-through, e lista de "produtos parados" (giro baixo e/ou sem saída no período configurável).
- Consolidar em uma única visão os alertas de ruptura já gerados (TASK-093), evitando que o gestor precise checar múltiplas telas separadas.
- Implementar filtros por depósito/unidade (`Warehouse`, TASK-089), categoria e coleção.
- Implementar drill-down do produto parado/em ruptura até o detalhe de estoque por variante (TASK-090).
- Registrar evento de analytics `dashboard_viewed` (tipo `inventory`).

## Regras de negócio e restrições

- Indicadores de cobertura e giro exibidos devem ser exatamente os mesmos consumidos pela regra de insight de estoque/reposição (TASK-128), para evitar divergência entre dashboard e central de oportunidades.
- Alertas de ruptura consolidados neste dashboard devem refletir o mesmo estado (não duplicado, não desatualizado) da tela de alertas original (TASK-093).
- Filtro por depósito respeita RBAC/escopo de empresa e unidade ativa do usuário.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento com dados completos, filtro por depósito/categoria/coleção, lista de produtos parados vazia, alertas de ruptura consolidados.
- Teste garantindo consistência entre cobertura/giro exibidos aqui e na regra de insight (TASK-128).
- Teste de drill-down do produto até o detalhe de estoque por variante.
- Teste de widget para tabela administrativa (desktop) e cards (mobile).

## Critérios de aceite

- Dashboard exibe cobertura em dias, sell-through, produtos parados e alertas de ruptura consolidados.
- Indicadores consistentes com os usados na regra de insight de estoque e reposição.
- Drill-down funcional até o detalhe de estoque por variante.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
