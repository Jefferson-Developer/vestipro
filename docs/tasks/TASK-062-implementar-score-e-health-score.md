# TASK-062 — Implementar score do cliente e health score

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) — o score é persistido como campo denormalizado no cliente; TASK-052 (Implementar detalhe do cliente 360º) — os indicadores serão exibidos na seção de indicadores já estruturada nessa tela.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar o cálculo do score comercial do cliente (frequência, recência, valor) e do health score (indicador simples de risco de churn), documentando a fórmula e os pesos usados, recalculados periodicamente via Cloud Function — indicadores centrais consumidos pelo detalhe 360º (TASK-052) e pela próxima melhor ação (TASK-063).

## Escopo técnico

- Serviço de domínio `CustomerScoringService` calculando `commercialScore` (baseado em frequência de compra, recência da última compra e valor histórico — modelo RFV/RFM simplificado) e `healthScore` (indicador 0–100 combinando recência, tendência de queda de compra e atividades CRM recentes).
- Cloud Function agendada (scheduled function) recalculando score/health score periodicamente para todos os clientes da organização (definir e documentar a periodicidade, ex.: diária ou semanal).
- Persistir `commercialScore`, `healthScore` e `scoreUpdatedAt` como campos denormalizados em `Customer` (ou coleção derivada), consumidos pela UI sem recalcular no cliente.
- Documentar a fórmula e os pesos aplicados (comentário estruturado no código e/ou ADR), permitindo auditoria e ajuste futuro.
- Nesta primeira versão, dados de pedidos/faturamento podem não existir ainda (EPIC-13 pendente) — a implementação deve degradar graciosamente, calculando o score apenas com os dados disponíveis (atividades CRM, recência de cadastro/contato), documentando a limitação e o ponto de evolução quando os pedidos existirem.

## Regras de negócio e restrições

- Cálculo definitivo de score/health score ocorre em Cloud Function, nunca só no cliente (mesmo que a UI possa exibir uma estimativa local para feedback imediato).
- Fórmula e pesos devem ser documentados e versionados — mudança de fórmula deve ser rastreável, nunca silenciosa.
- Health score deve classificar em faixas compreensíveis (ex.: saudável/atenção/risco) além do número bruto, para uso direto na UI sem lógica adicional na apresentação.
- Nunca considerar dados de outra organização no cálculo (escopo de tenant estrito).

## Testes obrigatórios

- Teste unitário da fórmula de `commercialScore` com casos limite (cliente sem nenhuma atividade, cliente muito recente, cliente muito antigo sem contato).
- Teste unitário da fórmula de `healthScore` cobrindo as faixas de classificação (saudável/atenção/risco).
- Teste do fallback quando dados de pedido/faturamento não existem (graceful degradation).
- Teste garantindo que o cálculo nunca mistura dados de organizações diferentes.

## Critérios de aceite

- Score comercial e health score calculados, documentados (fórmula e pesos) e recalculados periodicamente via Cloud Function.
- Cálculo degrada graciosamente sem dados de pedidos, sem quebrar a UI.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
