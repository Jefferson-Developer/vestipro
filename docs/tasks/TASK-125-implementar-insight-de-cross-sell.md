# TASK-125 — Implementar insight de cross-sell

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-064 (Product modelado — categorias e subcategorias que fundamentam a comparação)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "oportunidades de cross-sell" e "produtos comprados por clientes semelhantes" (seção 11 de `tasks.md`), sugerindo categorias que o cliente ainda não compra mas que clientes semelhantes compram, sempre com explicação clara da base de comparação usada.

## Escopo técnico

- Criar `CrossSellInsightRule` implementando `InsightRule`, consumindo o dataset agregado (TASK-133) de compras por categoria por cliente.
- Definir e documentar explicitamente o critério de "semelhança" entre clientes na primeira versão (ex.: mesmo segmento/porte + mesma região, calculado no dataset agregado) — este critério deve ser exposto na evidência do insight, nunca uma "caixa preta".
- Para cada cliente, identificar categorias com alta adesão entre clientes semelhantes e ausentes no histórico de compra do próprio cliente.
- Montar evidência: categoria sugerida, percentual de clientes semelhantes que compram essa categoria, ticket médio da categoria entre os clientes semelhantes.
- Limitar a no máximo 3 sugestões simultâneas por cliente, ordenadas por relevância (percentual de adesão × ticket médio).
- Configurar `quickAction`: "Adicionar categoria ao pedido" (abre o catálogo já filtrado pela categoria sugerida, pronto para incluir no pedido em rascunho do cliente, reaproveitando TASK-097).

## Regras de negócio e restrições

- Nunca sugerir categoria indisponível no catálogo/tabela de preço ativa do cliente-alvo.
- Toda sugestão deve expor a base de comparação usada (grupo de clientes semelhantes) — requisito de explicabilidade da engine (TASK-121), sem exceção.
- Não sugerir categorias descontinuadas ou fora de coleção vigente.

## Testes obrigatórios

- Teste com cliente sem nenhuma compra em categoria popular entre clientes semelhantes (dispara sugestão).
- Teste com cliente que já compra todas as categorias relevantes do grupo de comparação (não dispara).
- Teste do limite de 3 sugestões e da ordenação por relevância.
- Teste de exclusão de categoria indisponível na tabela de preço do cliente.

## Critérios de aceite

- Cada sugestão de cross-sell expõe explicitamente a base de comparação (grupo de clientes semelhantes) usada no cálculo.
- Ação rápida abre o catálogo já filtrado pela categoria sugerida, pronto para adicionar ao pedido.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
