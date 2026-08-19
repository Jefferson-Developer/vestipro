# TASK-136 — Implementar dashboard de clientes

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-048 (Customer modelado — origem dos dados de carteira/segmento)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Customer Dashboard (seção 12.1 de `tasks.md`): análise de carteira, retenção, ativação e ranking de clientes, permitindo ao gestor identificar rapidamente saúde e composição da base de clientes.

## Escopo técnico

- Criar `CustomerDashboardBloc` consumindo os snapshots de cliente/período (TASK-133) via `AggregationRepository`.
- Exibir KPIs (seção 12.2): clientes ativos, clientes novos, clientes reativados, taxa de recompra, frequência média de compra, churn, cobertura de carteira, positivação.
- Implementar ranking de clientes por faturamento/volume no período, com paginação e ordenação por diferentes critérios (faturamento, frequência, ticket médio).
- Implementar segmentação dinâmica reaproveitando os critérios já existentes em TASK-053 (segmento, região, porte) como filtros do dashboard.
- Adicionar drill-down do ranking até o detalhe do cliente 360º (TASK-052).
- Registrar evento de analytics `dashboard_viewed` (tipo `customer`).

## Regras de negócio e restrições

- "Clientes ativos" e "clientes reativados" devem usar a mesma definição/janela de tempo já usada pela regra de insight de cliente inativo (TASK-122), para evitar números conflitantes entre dashboard e central de oportunidades.
- Ranking e KPIs respeitam RBAC: vendedor vê apenas a própria carteira; gestor vê a equipe; admin vê a organização.
- Nenhum cálculo de retenção/churn pode ser recalculado do zero no cliente — sempre a partir do snapshot pré-calculado.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento com dados completos, filtro por segmento/região, ordenação do ranking por diferentes critérios, paginação preservando itens carregados.
- Teste de RBAC restringindo o escopo de clientes visíveis por perfil.
- Teste garantindo consistência entre a definição de "cliente ativo/inativo" deste dashboard e a regra de insight (TASK-122).
- Teste de widget para tabela administrativa (desktop) e cards (mobile).

## Critérios de aceite

- Dashboard exibe clientes ativos, novos, reativados, taxa de recompra, frequência média, churn, cobertura de carteira e positivação.
- Ranking de clientes ordenável e paginado, com drill-down até o detalhe 360º.
- Definição de cliente ativo/inativo consistente com a central de oportunidades.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
