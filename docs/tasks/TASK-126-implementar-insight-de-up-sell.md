# TASK-126 — Implementar insight de up-sell

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-064 (Product modelado — categorias já compradas pelo cliente como base do cálculo)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "oportunidades de up-sell" (seção 11 de `tasks.md`), identificando oportunidade de aumentar ticket/quantidade em categorias já compradas pelo cliente, com base no padrão de clientes semelhantes de maior volume nessas mesmas categorias.

## Escopo técnico

- Criar `UpSellInsightRule` implementando `InsightRule`, consumindo o dataset agregado (TASK-133) de ticket médio e quantidade por categoria por cliente.
- Para cada categoria já comprada pelo cliente, comparar seu ticket médio/quantidade média por pedido com a média de clientes semelhantes de volume superior (ex.: percentil superior do mesmo grupo de comparação usado no cross-sell, TASK-125).
- Montar evidência: ticket médio atual do cliente na categoria, ticket médio de clientes semelhantes de maior volume, diferença percentual entre os dois.
- Configurar `quickAction`: "Sugerir grade ampliada" (pré-popula o pedido em rascunho com quantidades sugeridas por variante dentro da mesma categoria, reaproveitando a tela de grade comercial, TASK-098).
- Consultar disponibilidade real de estoque da variante (TASK-090) antes de sugerir qualquer quantidade adicional.

## Regras de negócio e restrições

- Só considerar categorias em que o cliente já possui histórico de compra (diferencia esta regra do cross-sell, TASK-125).
- Sugestão de quantidade nunca pode ultrapassar o saldo disponível real da variante.
- Não gerar insight quando o cliente já está acima ou igual à média do grupo de comparação na categoria.

## Testes obrigatórios

- Teste com cliente abaixo da média do grupo de comparação (dispara) e acima/igual (não dispara).
- Teste de respeito ao estoque disponível ao calcular a sugestão de quantidade.
- Teste do cálculo de percentil/grupo de comparação usado como referência.

## Critérios de aceite

- Insight só aparece quando há diferença relevante e sustentável em relação ao grupo de comparação de maior volume.
- Sugestão de quantidade nunca excede a disponibilidade real de estoque da variante.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
