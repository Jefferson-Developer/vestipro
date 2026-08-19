# TASK-141 — Implementar dashboard de funil (CRM)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-058 (funil de vendas configurável — origem das etapas e oportunidades analisadas)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Funnel Dashboard (seção 12.1 de `tasks.md`): conversão por etapa do funil, aging do pipeline e motivos de perda mais frequentes, dando visibilidade ao gestor de CRM sobre a saúde do pipeline comercial.

## Escopo técnico

- Criar `FunnelDashboardBloc` consumindo os snapshots de oportunidades por etapa/período (TASK-133) via `AggregationRepository`, refletindo as etapas configuráveis do funil (TASK-058).
- Exibir KPIs (seção 12.2): conversão por etapa (taxa de passagem de uma etapa para a próxima), pipeline ponderado (valor das oportunidades ponderado pela probabilidade de cada etapa), aging do pipeline (tempo médio parado em cada etapa).
- Exibir ranking dos motivos de perda mais frequentes (TASK-061), com filtro por etapa em que a perda ocorreu.
- Implementar visualização do funil em formato de etapas empilhadas (contagem e valor total por estágio, consistente com o funil visual da TASK-058), com drill-down até a lista de oportunidades de cada etapa.
- Registrar evento de analytics `dashboard_viewed` (tipo `funnel`).

## Regras de negócio e restrições

- Contagem e valor por estágio devem ser sempre exibidos juntos (nunca apenas contagem ou apenas valor isoladamente), consistente com o padrão definido para o funil de vendas.
- Aging do pipeline deve considerar apenas oportunidades abertas (não fechadas/ganhas/perdidas) no cálculo de tempo parado.
- Filtros de equipe/vendedor respeitam RBAC (vendedor vê o próprio funil; gestor vê o da equipe).

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento completo, etapa sem oportunidades, cálculo de conversão entre etapas, cálculo de pipeline ponderado.
- Teste do cálculo de aging considerando apenas oportunidades abertas.
- Teste de ranking de motivos de perda filtrado por etapa.
- Teste de RBAC restringindo o escopo de vendedores/equipes visíveis.
- Teste de widget para visualização de etapas empilhadas em desktop e lista/cards em mobile.

## Critérios de aceite

- Dashboard exibe conversão por etapa, aging do pipeline, pipeline ponderado e motivos de perda mais frequentes.
- Drill-down funcional do estágio do funil até a lista de oportunidades correspondente.
- Contagem e valor sempre exibidos juntos por estágio.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
