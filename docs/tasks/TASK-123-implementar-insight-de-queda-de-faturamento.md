# TASK-123 — Implementar insight de queda de faturamento

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-133 (camada de agregação server-side — fonte dos totais de faturamento por período e por cliente)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "clientes com queda de faturamento" (seção 11 de `tasks.md`), comparando o faturamento do cliente entre períodos equivalentes (ex.: mesmo mês do ano anterior) e sinalizando retração relevante conforme um threshold percentual configurável por organização.

## Escopo técnico

- Criar `RevenueDropInsightRule` implementando `InsightRule`, consumindo os snapshots de faturamento por cliente/período (TASK-133).
- Comparar o faturamento do período corrente com o mesmo período equivalente anterior (MoM e/ou YoY, configurável por organização), respeitando sazonalidade de moda (nunca comparar mês de inverno com mês de verão sem sinalizar essa diferença de estação).
- Aplicar threshold percentual de queda configurável (default sugerido: 30%), abaixo do qual o insight não é gerado, e um piso mínimo de faturamento no período de base (evitar falso positivo por variação percentual grande sobre valores irrelevantes).
- Montar evidência: faturamento do período atual, faturamento do período equivalente anterior, percentual de queda, categoria/produto que mais contribuiu para a retração quando identificável no snapshot.
- Calcular impacto estimado como a diferença absoluta em R$ entre os dois períodos.
- Configurar `quickAction`: "Abrir cliente", "Agendar contato", "Ver histórico de pedidos".

## Regras de negócio e restrições

- Threshold percentual e piso mínimo de faturamento configuráveis por organização.
- Comparação deve usar sempre períodos equivalentes reais; não comparar períodos de estações diferentes sem qualificar isso na evidência.
- Deduplicar por cliente+período: não gerar o mesmo insight repetidamente no mesmo ciclo de execução.
- Insight expira e é recalculado no próximo ciclo agendado.

## Testes obrigatórios

- Teste com queda acima do threshold (dispara) e abaixo do threshold (não dispara).
- Teste com cliente abaixo do piso mínimo de faturamento (não dispara mesmo com queda percentual alta).
- Teste do cálculo do período equivalente anterior (mesmo mês do ano anterior).
- Teste de deduplicação entre execuções consecutivas do mesmo ciclo.

## Critérios de aceite

- Insight só aparece para quedas relevantes: acima do threshold percentual e acima do piso mínimo de faturamento configurados.
- Evidência exibida mostra os dois valores comparados e o percentual de queda calculado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
