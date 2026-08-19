# TASK-134 — Implementar dashboard executivo

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side — todos os snapshots consumidos por este dashboard)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Executive Dashboard (seção 12.1 de `tasks.md`): visão geral de alto nível da operação comercial, com os KPIs principais, tendências e filtros globais de período/empresa, destinado a `OWNER`/`ADMIN` e gestores seniores.

## Escopo técnico

- Criar `ExecutiveDashboardBloc` consumindo exclusivamente os snapshots agregados (TASK-133) via `AggregationRepository` — nenhuma query bruta de pedidos/clientes na tela.
- Exibir os KPIs principais (seção 12.2 de `tasks.md`): faturamento, pedidos, ticket médio, clientes ativos, clientes novos, crescimento YoY e MoM, atingimento de meta consolidado, positivação de carteira.
- Criar filtros globais persistentes na tela: período (com comparação ao período anterior), empresa/unidade (`companyId`), equipe — refletidos na URL do Flutter Web para permitir compartilhamento do link filtrado.
- Cada KPI deve exibir comparação com o período anterior equivalente (variação percentual e absoluta) e uma tendência resumida (sparkline/mini-gráfico).
- Incluir atalho para a Central de Oportunidades (TASK-132) destacando os insights de maior impacto do período filtrado.
- Registrar evento de analytics `dashboard_viewed` com o tipo `executive` e os filtros aplicados.

## Regras de negócio e restrições

- Nenhum gráfico sem propósito: cada visualização responde a uma pergunta de negócio explícita (ex.: "o faturamento está acima ou abaixo do mesmo período do ano anterior?").
- Todo KPI exibido informa a unidade e o período de referência de forma explícita, nunca implícita.
- Filtros de empresa/equipe respeitam RBAC: usuário sem permissão de visão consolidada não pode selecionar escopo além do seu próprio.
- Dashboard nunca executa cálculo pesado no cliente — todo valor vem de snapshot pré-calculado (TASK-133).

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento com dados completos, período sem dados, falha parcial (um KPI falha e os demais continuam exibidos), mudança de filtro (período/empresa/equipe).
- Teste de RBAC restringindo o escopo de empresas/equipes visíveis por perfil.
- Teste de widget para layout mobile (KPIs empilhados), tablet e desktop (grade de KPIs lado a lado, gráficos maiores).
- Teste de acessibilidade garantindo alternativa textual resumida para cada gráfico.
- Teste de analytics validando o evento `dashboard_viewed` com os filtros aplicados.

## Critérios de aceite

- Todos os KPIs principais da seção 12.2 relevantes ao nível executivo são exibidos com comparação ao período anterior.
- Filtros globais de período/empresa/equipe funcionam e refletem na URL no Flutter Web.
- Nenhuma query bruta client-side é executada; todos os dados vêm de snapshots pré-calculados.
- Atalho para a Central de Oportunidades exibe os insights de maior impacto do período filtrado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
