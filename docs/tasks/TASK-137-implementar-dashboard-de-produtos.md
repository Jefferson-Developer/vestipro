# TASK-137 — Implementar dashboard de produtos

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-064 (Product modelado — categoria, cor, tamanho e coleção como dimensões de análise)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Product Dashboard (seção 12.1 de `tasks.md`): análise de mix, giro e desempenho por produto, coleção, cor, tamanho e categoria, permitindo ao gestor identificar rapidamente o que está vendendo bem e o que precisa de atenção.

## Escopo técnico

- Criar `ProductDashboardBloc` consumindo os snapshots de produto/período (TASK-133) via `AggregationRepository`.
- Exibir KPIs (seção 12.2): quantidade vendida, mix médio, desconto médio, margem — segmentados por produto, categoria, cor e tamanho.
- Implementar ranking de "produtos mais vendidos" e "produtos com maior conversão" (seção 11), com filtros por coleção/categoria/cor/tamanho.
- Cruzar com os indicadores de giro de estoque (TASK-094) para exibir, lado a lado, desempenho de venda e giro por produto.
- Implementar drill-down do ranking até o detalhe do produto (reaproveitando TASK-078).
- Registrar evento de analytics `dashboard_viewed` (tipo `product`).

## Regras de negócio e restrições

- "Maior conversão" deve ser calculada como proporção de visualizações/adições ao pedido que resultaram em pedido submetido, vinda do snapshot agregado — nunca calculada ad-hoc no cliente.
- Dados de giro exibidos devem ser exatamente os mesmos usados pela regra de insight de estoque (TASK-128), para evitar divergência entre dashboard e central de oportunidades.
- Filtros de coleção/categoria devem respeitar apenas produtos vigentes na tabela de preço ativa da organização/empresa do usuário.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento com dados completos, filtro por coleção/categoria/cor/tamanho, ranking de mais vendidos e maior conversão, ausência de dados no período.
- Teste garantindo consistência entre giro exibido no dashboard e o usado na regra de insight de estoque (TASK-128).
- Teste de widget para tabela administrativa (desktop) e cards (mobile), incluindo imagem do produto.
- Teste de drill-down do ranking até o detalhe do produto.

## Critérios de aceite

- Dashboard exibe quantidade vendida, mix médio, desconto médio e margem segmentados por produto/categoria/cor/tamanho.
- Ranking de mais vendidos e maior conversão funcional com filtros por coleção/categoria.
- Indicadores de giro exibidos consistentes com a regra de insight de estoque.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
