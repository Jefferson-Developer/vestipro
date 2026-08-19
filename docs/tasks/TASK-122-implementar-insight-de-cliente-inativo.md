# TASK-122 — Implementar insight de cliente inativo

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights — framework de regras e contrato `Insight`), TASK-051 (carteira de clientes — vínculo vendedor-cliente e escopo de visibilidade)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a regra de insight "cliente sem compra há X dias" (seção 11 de `tasks.md`), detectando clientes cujo tempo sem pedido ultrapassa uma janela configurável por organização, com ação recomendada de contato/visita. Este é o primeiro insight concreto plugado na `InsightEngine` criada na TASK-121.

## Escopo técnico

- Criar `InactiveCustomerInsightRule` implementando `InsightRule`, consumindo do dataset agregado (TASK-133) a data do último pedido faturado/submetido por cliente.
- Comparar `hoje - dataUltimoPedido` com `inactivityThresholdDays`, configurável por organização (default sugerido: 45 dias), com possibilidade de override por segmento de cliente (ex.: cliente sazonal vs. recorrente).
- Montar evidência do insight: data do último pedido, valor do último pedido, ticket médio histórico do cliente, quantidade de dias corridos sem compra.
- Calcular impacto estimado como o ticket médio histórico do cliente (proxy de receita em risco de reativação).
- Configurar `quickAction` com dois atalhos: "Agendar contato" (cria atividade CRM já vinculada ao cliente, reaproveitando TASK-059) e "Abrir cliente" (leva ao detalhe 360º, TASK-052).
- Excluir da regra clientes marcados como inativos/desativados administrativamente — não gerar insight de reativação para cliente encerrado no cadastro.

## Regras de negócio e restrições

- O threshold de dias sem compra deve ser configurável por organização, nunca hardcoded no código da regra.
- Cliente sem nenhum pedido histórico (nunca comprou) não gera este insight — é fluxo de prospecção, fora deste escopo.
- Visibilidade respeita a carteira: vendedor só vê inatividade de clientes da própria carteira; gestor vê da equipe (RBAC aplicado no `InsightRepository`, não recalculado na UI).
- Insight expira e é recalculado no próximo ciclo agendado (herdado do framework da TASK-121).

## Testes obrigatórios

- Teste da regra com cliente exatamente no limite do threshold (borda), um dia abaixo e um dia acima.
- Teste com cliente sem histórico de pedidos (não deve gerar insight).
- Teste com threshold customizado por organização e por segmento.
- Teste de exclusão de cliente desativado administrativamente.
- Teste de RBAC (vendedor não recebe insight de cliente fora da própria carteira).

## Critérios de aceite

- Insight aparece somente para clientes com pedido anterior e sem compra dentro da janela configurada pela organização.
- Evidência exibida inclui data do último pedido e dias corridos sem compra.
- Ação "agendar contato" cria a atividade CRM corretamente vinculada ao cliente do insight.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
