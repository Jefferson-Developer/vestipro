# TASK-129 — Implementar insight de risco de churn

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-051 (carteira de clientes — vínculo vendedor-cliente e escopo de visibilidade), TASK-062 (score do cliente e health score — sinal de risco combinado nesta regra)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "risco de churn" (seção 11 de `tasks.md`), combinando sinais de queda de frequência de compra, queda de valor e health score baixo (TASK-062) em um score único de risco de churn, priorizado por impacto financeiro do cliente.

## Escopo técnico

- Criar `ChurnRiskInsightRule` implementando `InsightRule`, consumindo do dataset agregado (TASK-133) a frequência recente vs. histórica de compra, o faturamento recente vs. histórico, e o health score do cliente (TASK-062).
- Definir fórmula de composição do score de risco (ex.: média ponderada dos três sinais normalizados de 0 a 1, com pesos configuráveis por organização) e expor os pesos usados na evidência.
- Classificar o risco resultante em faixas (baixo/médio/alto/crítico) com thresholds configuráveis por organização.
- Priorizar a exibição do insight por impacto financeiro do cliente (faturamento histórico/ticket médio × nível de risco), garantindo que clientes de alto valor com risco alto apareçam antes de clientes de baixo valor com o mesmo nível de risco.
- Montar evidência: valor de cada sinal individual (frequência, valor, health score), peso de cada um na composição, faixa de risco resultante.
- Configurar `quickAction`: "Agendar contato prioritário" e "Abrir cliente 360º".

## Regras de negócio e restrições

- Pesos de composição do score configuráveis por organização, com valores padrão documentados no código/config.
- Cliente com dados históricos insuficientes (ex.: menos de N pedidos) não deve gerar score de churn confiável — sinalizar como "dados insuficientes" em vez de produzir falso positivo.
- Priorização por impacto financeiro é obrigatória na central de oportunidades (TASK-132): a ordenação nunca deve considerar apenas o score de risco isolado.

## Testes obrigatórios

- Teste da fórmula de composição com diferentes combinações de sinais (todos altos, mistos, todos baixos).
- Teste de classificação em faixas de risco nos limites de cada faixa (borda).
- Teste de priorização por impacto financeiro (cliente de alto valor e risco médio à frente de cliente de baixo valor e risco alto, conforme regra definida).
- Teste de cliente com dados insuficientes (não gera insight de risco confiável, ou gera com sinalização explícita de dados insuficientes).

## Critérios de aceite

- Score de risco é sempre acompanhado dos três sinais que o compõem, de forma explicável.
- Priorização de exibição considera impacto financeiro do cliente, não apenas o score de risco isolado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
