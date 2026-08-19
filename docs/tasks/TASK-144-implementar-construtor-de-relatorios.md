# TASK-144 — Implementar construtor de relatórios

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side, fonte de dados de toda consulta montada pelo construtor)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o construtor de relatórios ad-hoc que permite ao usuário escolher dimensões, métricas,
filtros, agrupamento e ordenação, validando combinações inválidas antes de enviar a consulta à
camada de agregação. É a base sobre a qual visualizações salvas (TASK-145) e todas as exportações
(TASK-146 a TASK-148) serão construídas.

## Escopo técnico

- Criar `ReportBuilderBloc` com estado representando a seleção atual (dimensões, métricas, filtros,
  agrupamento, ordenação, comparação de período) e casos de uso independentes para carregar o
  catálogo de dimensões/métricas disponíveis (não hardcoded na UI).
- Modelar `ReportDefinition` no domínio (dimensions, metrics, filters, groupBy, sortBy,
  comparisonPeriod), reutilizável por TASK-145 a TASK-149.
- Catálogo de dimensões/métricas deve refletir os KPIs definidos em `tasks.md` (seção 12.2:
  faturamento, ticket médio, mix médio, positivação, churn, pipeline ponderado etc.), vindo de
  configuração server-side.
- Caso de uso `ValidateReportDefinition` bloqueando combinações inválidas (ex.: métrica financeira
  incompatível com dimensão de produto) antes de qualquer chamada de rede.
- Caso de uso `ExecuteReportQuery` delegando a execução real para a camada de agregação (TASK-133),
  nunca calculando métricas no cliente.
- UI (Front-end): construtor visual incremental com chips de filtro, preview de tabela/gráfico antes
  de confirmar a execução, seguindo o padrão de "impedir visualmente combinações inválidas" exigido
  para dashboards/relatórios no agente de front-end.
- Persistir rascunho de construção localmente para não perder a seleção ao trocar de tela.
- Registrar eventos de analytics `report_built` e `report_query_executed`.

## Regras de negócio e restrições

- Toda consulta é escopada por organização/empresa ativa; nunca permitir seleção de dado fora do
  tenant do usuário logado.
- RBAC aplicado tanto na composição visual (ocultar dimensão/métrica fora do escopo do perfil) quanto
  na execução real da consulta no backend de agregação — a ocultação na UI nunca substitui a
  validação no servidor.
- Perfis restritos (ex.: `SALES_REP`) só compõem relatórios sobre a própria carteira; `SALES_MANAGER`
  sobre a equipe; `FINANCE` acessa métricas financeiras sensíveis vedadas a outros perfis.
- Limitar o número de dimensões/métricas simultâneas por consulta para evitar consultas gigantes.
- Nunca calcular métrica financeira (margem, desconto médio) client-side — sempre usar o retorno da
  camada de agregação.

## Testes obrigatórios

- Testes de bloc: seleção válida executa consulta; seleção inválida bloqueia com mensagem clara;
  troca de filtro invalida métrica incompatível já selecionada.
- Teste de RBAC negando dimensão/métrica fora do escopo do perfil, tanto na composição quanto na
  execução.
- Testes de widget: chips de filtro, preview atualizando ao mudar seleção, estado vazio sem métrica
  selecionada.
- Teste de integração com a camada de agregação mockada cobrindo sucesso, timeout e erro de
  permissão.
- Teste garantindo isolamento multi-tenant na consulta gerada.

## Critérios de aceite

- Usuário monta um relatório escolhendo dimensão + métrica + filtro sem que uma combinação inválida
  chegue ao backend.
- Erros de combinação são sinalizados na UI antes do envio, com explicação compreensível.
- Resultado executado reflete exatamente o retorno da camada de agregação (TASK-133), sem cálculo
  divergente feito só na interface.
- Rascunho de construção não é perdido ao navegar entre abas/telas.
- RBAC aplicado de forma consistente na composição visual e na execução da consulta.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
