# TASK-124 - Implementar insight de cliente em crescimento (CONCLUIDA)

**Epic:** EPIC-16 - Insights e Recomendacao
**Status:** Concluida
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

- Implementei `GrowingCustomerInsightRule` no dominio Flutter e no backend TypeScript (Cloud
  Functions), plugada na engine de insights existente sem alterar o nucleo de `InsightEngine`.
- A regra consome uma nova serie de faturamento por cliente/periodo
  (`InsightCustomerGrowthSnapshot`/`InsightCustomerGrowthPeriod` no Dart,
  `InsightCustomerGrowthSnapshot`/`InsightCustomerGrowthPeriod` no TS), adicionada ao
  `InsightDataset` como `customerGrowthSnapshots`. Essa serie ainda depende dos snapshots
  agregados reais que a TASK-133 (camada de agregacao server-side) deve entregar; a estrutura foi
  construida para consumir esses dados assim que a TASK-133 existir, seguindo o mesmo padrao ja
  usado pela TASK-123 (que tambem dependia da TASK-133 e foi implementada antecipando o contrato de
  dados).
- Exijo N periodos consecutivos de crescimento MoM (`customerGrowthMinConsecutivePeriods`, default
  3) e um limite minimo de taxa media de crescimento (`customerGrowthMinimumAverageRate`, default
  15%), ambos configuraveis por organizacao via `InsightOrganizationSettings`.
- Para evitar falso positivo por pico isolado, cada periodo carrega `hasOutlierOrder` +
  `outlierAdjustedRevenue`; o calculo de tendencia usa `trendRevenue` (revenue ajustado quando ha
  outlier) em vez do revenue bruto, então um unico pedido atipico nao consegue fabricar uma
  sequencia de crescimento nem inflar a taxa media.
- A evidencia gerada mostra o faturamento de cada um dos periodos usados no calculo, a taxa media
  de crescimento e a categoria que mais cresceu no intervalo (quando disponivel no snapshot).
- O impacto estimado é uma extrapolacao linear simples (ultimo faturamento real x taxa media de
  crescimento) e a descricao do insight deixa explicito que é uma estimativa, nao uma garantia.
- `quickAction` = "Sugerir ampliacao de mix" (novo `InsightActionType.viewOpportunities`, rota
  `/opportunities?customerId=...` — pagina da central de oportunidades ainda pendente da TASK-132)
  e `secondaryActions` = "Agendar visita de relacionamento" (`scheduleContact`).
- Adicionei testes cobrindo os 4 cenarios exigidos pela task: crescimento consistente em 3
  periodos (dispara), crescimento inconsistente com queda intermediaria (nao dispara), outlier
  isolado tratado corretamente sem falso positivo, e configuracao de threshold/numero minimo de
  periodos por organizacao.
- Regenerei `lib/app/injection.config.dart` via `build_runner` para registrar
  `GrowingCustomerInsightRule` no `InsightModule` e na lista de `InsightRule` injetada na
  `InsightEngine`.
- No backend TypeScript, adicionei o carregamento de
  `insightCustomerGrowthSnapshots` (nova colecao Firestore, espelhando o padrao de
  `insightRevenueComparisons`) e conectei a nova regra ao `generateInsightsScheduled`.

## Arquivos criados ou alterados

- `lib/features/insights/domain/entities/insight_customer_growth_period.dart` (novo)
- `lib/features/insights/domain/entities/insight_customer_growth_snapshot.dart` (novo)
- `lib/features/insights/domain/entities/insight_dataset.dart`
- `lib/features/insights/domain/entities/insight_organization_settings.dart`
- `lib/features/insights/domain/value_objects/insight_action_type.dart`
- `lib/features/insights/domain/rules/growing_customer_insight_rule.dart` (novo)
- `lib/features/insights/insight_module.dart`
- `lib/features/insights/insights.dart`
- `lib/app/injection.config.dart` (regenerado via `build_runner`)
- `test/features/insights/domain/rules/growing_customer_insight_rule_test.dart` (novo)
- `functions/src/insights/insight-engine.ts`
- `functions/src/insights/growing-customer-insight-rule.ts` (novo)
- `functions/src/insights/generate-insights-scheduled.ts`
- `docs/tasks/TASK-124-implementar-insight-de-cliente-em-crescimento-CONCLUIDA.md` (este arquivo)
- `docs/tasks/TASKS.md`

## Validacoes executadas

- `flutter test test/features/insights` - sucesso (15 testes, incluindo os 4 novos da
  `GrowingCustomerInsightRule`).
- `flutter analyze` (projeto completo) - sucesso, sem issues.
- `npx tsc --noEmit` em `functions/` - sucesso, sem erros de tipo.
- `npx jest test/insights --runInBand` em `functions/` - sucesso (suite existente continua
  passando).

## Decisoes e riscos conhecidos

- Assim como a TASK-123, esta regra depende de dados agregados reais que so a TASK-133 vai
  entregar em producao; a colecao `insightCustomerGrowthSnapshots` e o formato do snapshot foram
  definidos antecipando esse contrato.
- Adicionei `InsightActionType.viewOpportunities` e a rota `/opportunities?customerId=...` para o
  quick action "Sugerir ampliacao de mix"; essa central de oportunidades ainda nao existe
  (TASK-132 pendente) — a rota fica pronta para quando a tela for implementada.
- A deteccao de outlier depende dos campos `hasOutlierOrder`/`outlierAdjustedRevenue` virem
  preenchidos corretamente pela camada de agregacao; sem esses campos, a regra usa o revenue bruto
  do periodo (comportamento seguro, mas sem protecao contra outlier).

## Commit

- Commit local desta task: `feat(insights): implementa insight de cliente em crescimento`

## Push

- Nenhum push foi realizado nesta sessao, conforme solicitado (push nao autorizado nesta rodada).
