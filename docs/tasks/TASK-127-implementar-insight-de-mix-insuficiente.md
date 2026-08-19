# TASK-127 — Implementar insight de mix insuficiente

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-064 (Product modelado — categorias e subcategorias usadas no cálculo de mix)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "mix abaixo do ideal" e "clientes sem determinadas categorias" (seção 11 de `tasks.md`), comparando o mix de categorias compradas pelo cliente com um benchmark parametrizável (ex.: mix médio de clientes do mesmo segmento/região).

## Escopo técnico

- Criar `InsufficientMixInsightRule` implementando `InsightRule`, consumindo o dataset agregado (TASK-133) de categorias distintas compradas por cliente no período.
- Calcular o benchmark de mix (quantidade média de categorias distintas compradas) para o grupo de comparação configurado pela organização (por segmento, região, porte, ou combinação), recalculado no mesmo ciclo da agregação de TASK-133.
- Comparar a quantidade de categorias do cliente com o benchmark do grupo; gerar insight quando estiver abaixo do esperado (threshold configurável, ex.: 70% do benchmark).
- Montar evidência: quantidade de categorias compradas pelo cliente, benchmark do grupo de comparação, lista das categorias ausentes mais relevantes no benchmark.
- Configurar `quickAction`: "Ver categorias ausentes" (abre lista das categorias faltantes com atalho direto para adicionar ao pedido em rascunho).

## Regras de negócio e restrições

- Benchmark deve ser recalculado periodicamente junto ao ciclo de agregação (TASK-133), nunca fixo/hardcoded no código.
- Permitir que a organização exclua categorias irrelevantes para determinados perfis de cliente do cálculo (ex.: categoria exclusiva de outro canal/segmento).
- Grupo de comparação (segmento/região/porte) configurável por organização.

## Testes obrigatórios

- Teste com cliente abaixo do benchmark (dispara) e igual/acima do benchmark (não dispara).
- Teste de exclusão de categorias irrelevantes configuradas pela organização.
- Teste de recomputo do benchmark ao alterar o grupo de comparação (segmento/região).

## Critérios de aceite

- Insight mostra claramente o benchmark usado no cálculo e a lista de categorias ausentes mais relevantes.
- Benchmark e grupo de comparação são parametrizáveis pela organização sem alteração de código.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
