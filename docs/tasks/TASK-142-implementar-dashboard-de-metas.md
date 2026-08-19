# TASK-142 — Implementar dashboard de metas

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-115 (cadastro de metas — origem dos objetivos comparados neste dashboard)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Targets Dashboard (seção 12.1 de `tasks.md`): performance versus objetivo, com filtros por equipe, vendedor e período, dando ao gestor uma visão consolidada de atingimento de metas em múltiplos níveis (organização, equipe, vendedor).

## Escopo técnico

- Criar `TargetsDashboardBloc` consumindo os snapshots de realizado vs. meta (TASK-133) via `AggregationRepository`, cruzando com as metas cadastradas (TASK-114/TASK-115).
- Exibir KPIs (seção 12.2): atingimento de meta (percentual e absoluto), previsão de fechamento (reaproveitando o cálculo de projeção da TASK-119), comparação entre equipes/vendedores.
- Implementar filtros por equipe, vendedor e período, com visão hierárquica (drill-down de organização → equipe → vendedor).
- Reaproveitar a lógica de ranking comercial já existente (TASK-118) para exibir os vendedores/equipes mais próximos ou mais distantes da meta.
- Destacar visualmente vendedores/equipes com o insight de "abaixo da meta" ativo (TASK-131), cruzando com a Central de Oportunidades.
- Registrar evento de analytics `dashboard_viewed` (tipo `targets`).

## Regras de negócio e restrições

- Percentual de atingimento e previsão de fechamento exibidos devem ser exatamente os mesmos calculados na regra de insight de vendedor abaixo da meta (TASK-131), para evitar divergência entre dashboard e central de oportunidades.
- Filtros de equipe/vendedor respeitam RBAC: vendedor vê apenas a própria meta; gestor vê a da equipe; admin vê a da organização.
- Metas sem período vigente definido não devem ser exibidas como "em risco" — apenas metas ativas no período consultado entram no cálculo.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento completo, filtro por equipe/vendedor/período, drill-down hierárquico, meta não cadastrada para o período.
- Teste garantindo consistência entre o atingimento/previsão exibidos aqui e os calculados na regra de insight (TASK-131).
- Teste de RBAC restringindo o escopo de metas visíveis por perfil.
- Teste de widget para visão hierárquica em desktop (tabela expansível) e mobile (navegação em níveis).

## Critérios de aceite

- Dashboard exibe atingimento de meta e previsão de fechamento com filtros por equipe/vendedor/período.
- Drill-down hierárquico funcional (organização → equipe → vendedor).
- Valores consistentes com a regra de insight de vendedor abaixo da meta.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
