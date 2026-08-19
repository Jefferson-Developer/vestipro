# TASK-143 — Implementar dashboard geográfico

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-051 (carteira de clientes — origem dos endereços/região usados na segmentação geográfica)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Geographic Dashboard (seção 12.1 de `tasks.md`): desempenho comercial por região/estado/cidade, com visualização em mapa quando viável no Flutter Web, permitindo ao gestor identificar rapidamente áreas de força e de oportunidade geográfica.

## Escopo técnico

- Criar `GeographicDashboardBloc` consumindo os snapshots de faturamento agrupados por região/estado/cidade (TASK-133) via `AggregationRepository`.
- Exibir KPIs (seção 12.2): faturamento, clientes ativos, ticket médio e produtos mais vendidos por região (seção 11), com agrupamento hierárquico (região → estado → cidade).
- Implementar visualização em tabela/ranking (todas as plataformas) e visualização em mapa no Flutter Web quando os dados de latitude/longitude do cliente (TASK-050) estiverem disponíveis — sem bloquear a entrega do dashboard caso o mapa não seja viável no ciclo desta task (tabela/ranking é o requisito mínimo obrigatório).
- Implementar drill-down da região até a lista de clientes/pedidos daquela área geográfica.
- Registrar evento de analytics `dashboard_viewed` (tipo `geographic`).

## Regras de negócio e restrições

- Visualização em mapa é um incremento opcional desta task quando viável tecnicamente no Web; a tabela/ranking geográfico é o requisito mínimo que não pode ser omitido.
- Dados de localização exibidos respeitam a mesma política de privacidade/LGPD já aplicada aos endereços de cliente (nenhum dado de geolocalização exposto além do necessário para a análise agregada).
- Agrupamento geográfico respeita RBAC: vendedor vê apenas a própria carteira; gestor vê a da equipe/região sob sua responsabilidade.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento completo, agrupamento hierárquico região → estado → cidade, região sem dados no período.
- Teste de drill-down da região até a lista de clientes/pedidos.
- Teste de RBAC restringindo o escopo geográfico visível por perfil.
- Teste de fallback: quando dados de latitude/longitude não estão disponíveis, o dashboard exibe a tabela/ranking normalmente sem quebrar.

## Critérios de aceite

- Dashboard exibe faturamento, clientes ativos, ticket médio e produtos mais vendidos por região/estado/cidade em formato de tabela/ranking.
- Drill-down funcional da região até clientes/pedidos.
- Visualização em mapa implementada no Flutter Web quando viável, sem bloquear a entrega da tabela/ranking quando não for.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
