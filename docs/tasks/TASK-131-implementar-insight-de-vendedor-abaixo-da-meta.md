# TASK-131 — Implementar insight de vendedor abaixo da meta

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-115 (cadastro de metas — origem da meta do período por vendedor)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "vendedores abaixo da meta" (seção 11 de `tasks.md`), identificando vendedores com ritmo insuficiente para atingir a meta cadastrada (TASK-115) até o final do período, direcionado à home do gestor de equipe.

## Escopo técnico

- Criar `SalesRepBelowTargetInsightRule` implementando `InsightRule`, consumindo do dataset agregado (TASK-133) o realizado até o momento de cada vendedor e a meta cadastrada (TASK-115).
- Calcular o ritmo diário/semanal necessário nos dias restantes do período para atingir a meta, comparando com o ritmo médio realizado até o momento; sinalizar quando a projeção linear simples indicar não atingimento (threshold configurável, ex.: projeção abaixo de 90% da meta).
- Montar evidência: meta do período, realizado até o momento, dias restantes no período, ritmo necessário vs. ritmo médio atual, percentual de atingimento projetado.
- Configurar `quickAction`, direcionada à home do gestor: "Ver detalhe do vendedor" e "Sugerir plano de ação" (abre a carteira do vendedor priorizada por outros insights já existentes, ex.: clientes inativos da TASK-122 e risco de churn da TASK-129).
- Restringir visibilidade padrão a perfis `SALES_MANAGER`/`ADMIN` (o insight não é exibido ao próprio vendedor por padrão nesta task).

## Regras de negócio e restrições

- Cálculo de projeção deve considerar apenas dias úteis/período comercial relevante quando a organização assim configurar (evitar distorção por feriados/fins de semana).
- Insight não deve ser gerado nos primeiros dias do período (janela mínima configurável, ex.: só a partir do 5º dia útil), para evitar alarme falso com poucos dados acumulados.
- Visibilidade respeita hierarquia: gestor vê apenas vendedores da própria equipe; dados de meta nunca vazam entre equipes diferentes.

## Testes obrigatórios

- Teste de cálculo de projeção com ritmo constante, ritmo acelerando e ritmo desacelerando ao longo do período.
- Teste da janela mínima de dias antes de permitir a geração do insight.
- Teste de RBAC (gestor só vê vendedores da própria equipe).
- Teste de borda no threshold de projeção (ex.: 89% vs. 90% vs. 91% da meta).

## Critérios de aceite

- Insight aparece apenas após a janela mínima do período e quando a projeção indicar risco real de não atingimento da meta.
- Evidência exibida mostra claramente meta, realizado, dias restantes e ritmo necessário vs. atual.
- Visibilidade restrita ao gestor da equipe correspondente ao vendedor avaliado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
