# TASK-123 - Implementar insight de queda de faturamento (CONCLUIDA)

**Epic:** EPIC-16 - Insights e Recomendacao  
**Status:** Concluida  
**Data:** terça-feira, 1 de setembro de 2026  
**Branch:** `main`

## O que foi feito

- Implementei `RevenueDropInsightRule` no dominio Flutter e no backend TypeScript, plugadas na engine de insights sem alterar o nucleo da `InsightEngine`.
- A regra compara o faturamento atual com o periodo equivalente anterior segundo `revenueComparisonMode`, respeita threshold percentual configuravel, piso minimo de faturamento e rejeita comparacoes sazonais diferentes quando os snapshots informam estacoes divergentes.
- A evidencia gerada inclui faturamento atual, faturamento base, percentual de queda e categoria com maior retracao quando disponivel no snapshot.
- Modelei o impacto estimado como a diferenca absoluta em BRL entre os dois periodos e disponibilizei acoes tipadas para abrir cliente, agendar contato e ver historico de pedidos.
- Adicionei testes cobrindo queda acima e abaixo do threshold, piso minimo e exclusao de comparacao com sazonalidade divergente.
- Atualizei a validacao do backend para checar ids deterministas e separacao por empresa, garantindo recalculo sem duplicacao em ciclos consecutivos.

## Arquivos criados ou alterados

- `lib/features/insights/domain/rules/revenue_drop_insight_rule.dart`
- `functions/src/insights/revenue-drop-insight-rule.ts`
- `test/features/insights/domain/rules/revenue_drop_insight_rule_test.dart`
- `functions/test/insights/generate-insights-scheduled.test.ts`
- `docs/tasks/TASK-123-implementar-insight-de-queda-de-faturamento-CONCLUIDA.md` (este arquivo)
- `docs/tasks/TASKS.md`

## Validacoes executadas

- `flutter test test/features/insights` - sucesso.
- `npm test -- --runInBand insights` em `functions/` - sucesso.
- `flutter analyze` - sucesso, sem issues.

## Decisoes e riscos conhecidos

- A comparacao MoM/YoY esta pronta por configuracao, mas os snapshots agregados reais ainda precisam ser entregues no backlog de BI/TASK-133 para alimentar dados de producao.
- O criterio de sazonalidade hoje depende da presenca de `currentSeasonCode`/`previousSeasonCode` nos snapshots; sem esses campos, a regra assume equivalencia e segue a comparacao configurada.

## Commit

- Commit local desta task: `feat(insights): implementa insight de queda de faturamento`

## Push

- Nenhum push foi realizado nesta sessao, conforme solicitado.
