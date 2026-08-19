# TASK-135 — Implementar dashboard de vendas

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-101 (submissão do pedido — origem do evento que alimenta os snapshots de faturamento/pedidos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Sales Dashboard (seção 12.1 de `tasks.md`): análise detalhada de pedidos e faturamento, com comparação temporal e capacidade de drill-down até o pedido individual, destinado a gestores comerciais e representantes.

## Escopo técnico

- Criar `SalesDashboardBloc` consumindo os snapshots de faturamento/pedidos por período (TASK-133) via `AggregationRepository`.
- Exibir KPIs (seção 12.2): faturamento, quantidade vendida, pedidos, ticket médio, desconto médio, margem, peças por pedido, produtos por pedido — com comparação MoM e YoY.
- Implementar comparação de período (seção 12.3): seletor de período corrente vs. período anterior/equivalente, com variação percentual e absoluta destacada.
- Implementar drill-down: do KPI agregado até a lista de pedidos que o compõem, e da lista de pedidos até o detalhe individual de cada pedido (reaproveitando a tela de detalhe da TASK-102).
- Adicionar agrupamento e ordenação por vendedor, cliente, produto/categoria e período (seção 12.3).
- Registrar evento de analytics `dashboard_viewed` (tipo `sales`) e `report_exported` quando aplicável.

## Regras de negócio e restrições

- Drill-down para o pedido individual deve ser uma consulta pontual e limitada (não recalcular o agregado inteiro), nunca uma varredura completa de coleção no cliente.
- Descontos e margem exibidos devem refletir exatamente o resultado do motor de precificação (TASK-088), nunca um cálculo divergente feito na camada de apresentação.
- Filtros de vendedor/equipe respeitam RBAC (representante vê apenas a própria carteira; gestor vê a equipe).

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento com dados completos, comparação de período, agrupamento por vendedor/cliente/produto, drill-down até o pedido individual.
- Teste de RBAC restringindo o escopo de vendedores/equipes visíveis.
- Teste de widget para tabela administrativa densa no desktop e conversão em cards no mobile.
- Teste garantindo que valores de desconto/margem exibidos batem exatamente com o resultado do motor de precificação.

## Critérios de aceite

- Dashboard exibe faturamento, quantidade vendida, pedidos, ticket médio, desconto médio e margem com comparação temporal.
- Drill-down funcional do agregado até o pedido individual.
- Agrupamento por vendedor, cliente e produto/categoria disponível e respeitando RBAC.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
