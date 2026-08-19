# TASK-094 — Implementar indicadores de giro de estoque

**Epic:** EPIC-12 — Estoque e Disponibilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-090 — Implementar saldo por variante (giro/sell-through/cobertura são calculados a partir do histórico de saldo e vendas)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar o cálculo de sell-through e cobertura de estoque, expondo esses indicadores como dados consumíveis pelos dashboards (EPIC-17, ex.: Inventory Dashboard) e pela engine de insights (EPIC-16, ex.: insight de estoque alto/giro baixo da TASK-128), sempre como agregação pré-computada.

## Escopo técnico

- Criar serviço de domínio/Cloud Function de agregação que calcula, por produto/variante/coleção/warehouse e período: sell-through rate (quantidade vendida / (estoque inicial + recebido)), cobertura de estoque (dias restantes de estoque com base na venda média recente) e giro (vendas / estoque médio no período).
- Persistir os indicadores como snapshot pré-calculado (ex.: coleção/tabela de agregação diária) — nunca calcular em tempo real a partir de todo o histórico de movimentações no client.
- Expor caso de uso `GetStockTurnoverMetrics(scope, period)` reutilizável tanto pelos dashboards (Inventory/Product/Collection Dashboard) quanto pela engine de insights.
- Definir um DTO de saída estável para que EPIC-16 e EPIC-17 consumam sem acoplamento direto à implementação interna do cálculo.

## Regras de negócio e restrições

- Cálculo de giro/sell-through/cobertura é sempre server-side, como agregação pré-computada, nunca client-side.
- Período de análise configurável (ex.: 30/60/90 dias), nunca hardcoded no cálculo.
- Casos de borda tratados explicitamente: produto sem venda no período (giro zero, nunca divisão por zero/erro) e produto sem estoque inicial cadastrado.

## Testes obrigatórios

- Teste unitário do cálculo de sell-through/cobertura/giro cobrindo divisão por zero e períodos sem dados.
- Teste de agregação (Emulator) validando que o snapshot é gerado corretamente a partir de dados simulados de saldo e vendas.
- Teste de contrato garantindo que o DTO de saída é estável e consumível por um mock de dashboard e de insight.

## Critérios de aceite

- Indicadores de giro, sell-through e cobertura calculados e persistidos como agregação pré-computada.
- Caso de uso reutilizável, documentado e testado, pronto para consumo por EPIC-16/EPIC-17.
- Nenhum cálculo pesado realizado no client.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
