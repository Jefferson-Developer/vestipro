# TASK-124 — Implementar insight de cliente em crescimento

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-133 (camada de agregação server-side — série histórica de faturamento por cliente/período)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "clientes crescendo" (seção 11 de `tasks.md`), identificando clientes com crescimento consistente de faturamento em múltiplos períodos consecutivos, sinalizando oportunidade de aprofundar relacionamento e ampliar mix.

## Escopo técnico

- Criar `GrowingCustomerInsightRule` implementando `InsightRule`, consumindo a série de faturamento por cliente/período dos snapshots (TASK-133).
- Exigir crescimento em N períodos consecutivos (configurável por organização, default 3 meses seguidos de crescimento MoM) e calcular a taxa de crescimento média desses períodos.
- Aplicar threshold mínimo de crescimento médio configurável (ex.: acima de 15%) para gerar o insight.
- Montar evidência: faturamento dos últimos N períodos, taxa de crescimento período a período, categorias que mais cresceram no intervalo.
- Calcular impacto estimado como projeção de faturamento incremental caso a tendência se mantenha no próximo período (extrapolação linear simples), deixando explícito na descrição que é uma estimativa.
- Configurar `quickAction`: "Sugerir ampliação de mix" (leva à central de oportunidades filtrada pelo cliente, cruzando com cross-sell/up-sell) e "Agendar visita de relacionamento".

## Regras de negócio e restrições

- Exigir no mínimo N períodos consecutivos de crescimento (configurável, default 3) para evitar falso positivo por pico isolado.
- Detectar e excluir crescimento decorrente de um único pedido atípico (outlier muito acima do padrão histórico do cliente) do cálculo de tendência.
- Threshold de crescimento médio e número mínimo de períodos configuráveis por organização.

## Testes obrigatórios

- Teste com crescimento consistente em 3 períodos consecutivos (dispara).
- Teste com crescimento não consistente — queda em um dos períodos intermediários (não dispara).
- Teste com outlier isolado (um pedido muito acima do padrão) tratado corretamente sem gerar falso positivo.
- Teste de configuração de threshold e número mínimo de períodos por organização.

## Critérios de aceite

- Insight só aparece com tendência de crescimento sustentada em múltiplos períodos, nunca por um pico isolado.
- Evidência exibida mostra a série de períodos usada no cálculo e a taxa de crescimento média.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
