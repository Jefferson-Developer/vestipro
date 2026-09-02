# TASK-131 — Implementar insight de vendedor abaixo da meta (CONCLUIDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** Concluída

## Resumo

Implementada a regra de insight "vendedor abaixo da meta", cruzando o dataset agregado de metas
(EPIC-15, TASK-115) com a engine de insights (EPIC-16, TASK-121), seguindo exatamente o padrão
arquitetural das regras anteriores (snapshot de entrada + regra de domínio + espelho TypeScript em
Cloud Functions).

A regra detecta, por vendedor, se o ritmo médio realizado até o momento do período — projetado
linearmente até o fim do período — indica que a meta cadastrada não será atingida, e envia o
insight exclusivamente ao gestor da equipe do vendedor (nunca ao próprio vendedor).

## O que foi implementado

### Dart (app)

- `lib/features/insights/domain/entities/insight_sales_rep_below_target_snapshot.dart` — novo
  snapshot de entrada (`InsightSalesRepBelowTargetSnapshot`), com `targetValue`, `realizedValue`,
  `elapsedRelevantDays`/`totalRelevantDays` (já resolvidos upstream pela camada de agregação,
  TASK-133, seja em dias corridos ou dias úteis, conforme configuração da organização) e getters
  derivados: `currentDailyPace`, `requiredDailyPaceForRemainingDays`, `projectedValue`,
  `projectedAchievementPercentage`, `underAchievementRatio`.
- `lib/features/insights/domain/rules/sales_rep_below_target_insight_rule.dart` —
  `SalesRepBelowTargetInsightRule`, que:
  - Ignora snapshots de outra organização/empresa.
  - Ignora período/meta inválidos (`totalRelevantDays <= 0` ou `targetValue <= 0`).
  - Só gera insight a partir da janela mínima de dias decorridos
    (`sellerBelowTargetMinimumElapsedDays`, default 5).
  - Calcula a projeção linear simples e classifica em 3 faixas de risco (moderado/alto/crítico)
    com base em `underAchievementRatio`, com um pequeno epsilon de tolerância para evitar que erro
    de ponto flutuante faça um vendedor exatamente no limiar (ex.: projeção de exatos 90%) escapar
    da classificação.
  - Monta evidência completa: período, meta, realizado, dias decorridos/restantes, ritmo atual vs.
    necessário, percentual de atingimento projetado.
  - `quickAction`: novo tipo `InsightActionType.viewSellerDetail` ("Ver detalhe do vendedor").
  - `secondaryActions`: reaproveita `InsightActionType.viewOpportunities` ("Sugerir plano de
    ação"), apontando para a central de oportunidades (TASK-132) filtrada por `sellerId` — a mesma
    central que já prioriza clientes inativos (TASK-122) e risco de churn (TASK-129) na carteira
    do vendedor.
  - RBAC: `recipientUserId` do insight é sempre o gestor (nunca o vendedor) — a mesma restrição já
    usada por todas as outras regras via filtro exato de `recipientUserId` no
    `FirestoreInsightDataSource`, documentada explicitamente no snapshot.
- `insight_organization_settings.dart` — novos campos: `sellerBelowTargetMinimumElapsedDays`
  (default 5), `sellerBelowTargetMediumThreshold` (0.10), `sellerBelowTargetHighThreshold` (0.30),
  `sellerBelowTargetCriticalThreshold` (0.50).
- `insight_dataset.dart` — novo campo `salesRepBelowTargetSnapshots`.
- `insight_action_type.dart` — novo valor `viewSellerDetail`.
- `insight_type.dart` já continha `sellerBelowTarget` (adicionado preventivamente em task
  anterior) — apenas consumido aqui pela primeira vez.
- `insight_module.dart` / `insights.dart` — wiring da nova regra no DI e no barrel export.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` (novo binding de
  `SalesRepBelowTargetInsightRule` e atualização da lista `List<InsightRule>`).
- `test/features/insights/domain/rules/sales_rep_below_target_insight_rule_test.dart` — 11 casos:
  ritmo constante suficiente (sem insight), ritmo "desacelerando" (risco alto), ritmo
  "acelerando" mas insuficiente (risco moderado), janela mínima de dias (antes/exatamente),
  borda do threshold de projeção (89%/90%/91%), RBAC (dois vendedores/gestores distintos, sem
  vazamento), quick action/secondary action, e escopo por organização/empresa.

### TypeScript (Cloud Functions)

- `functions/src/insights/insight-engine.ts` — adicionados `'sellerBelowTarget'` a `InsightType`,
  `'viewSellerDetail'` a `InsightActionType`, a interface `InsightSalesRepBelowTargetSnapshot`, os
  4 campos de settings correspondentes (com defaults em `DEFAULT_INSIGHT_SETTINGS`) e o campo
  `salesRepBelowTargetSnapshots` em `InsightDataset`.
- `functions/src/insights/sales-rep-below-target-insight-rule.ts` — espelho exato da regra Dart.
- `functions/src/insights/generate-insights-scheduled.ts` — nova regra registrada em
  `defaultRules`, novo loader `loadSalesRepBelowTargetSnapshots` (coleção
  `insightSalesRepBelowTargetSnapshots`), settings resolvidos em `resolveSettings`, e o novo
  dataset propagado em `buildInsightsForOrganization`.

## Validações executadas

- `dart run build_runner build` (regenerar `injection.config.dart`) — sucesso, sem novos warnings
  além dos pré-existentes não relacionados a esta task.
- `flutter test test/features/insights/` — 63 testes, todos passando.
- `flutter analyze` (projeto inteiro) — nenhum problema encontrado.
- `dart format` nos arquivos criados/alterados desta task.
- `cd functions && npm run build` (tsc) — sucesso.
- `cd functions && npm run lint` (eslint) — sucesso.
- `cd functions && npx jest test/insights` — 2 testes (suíte de integração existente,
  `generate-insights-scheduled.test.ts`), todos passando; não foi necessário alterá-la porque o
  novo dataset é opcional (`?? []`).

## Pendências / próximos passos

- TASK-133 (camada de agregação server-side) ainda não existe: os campos
  `elapsedRelevantDays`/`totalRelevantDays`/`targetValue`/`realizedValue` do snapshot assumem que
  essa camada resolverá a contagem de dias úteis vs. corridos e a hierarquia gestor→vendedor
  corretamente; a regra de insight em si é agnóstica a essa origem.
- TASK-132 (central de oportunidades) ainda não existe: a rota `/opportunities?sellerId=...` usada
  na ação secundária é um placeholder de convenção, consistente com o mesmo padrão já usado por
  `growing_customer_insight_rule.dart` para `customerId`.
- Não existe ainda uma tela de detalhe do vendedor; a rota `/team/sellers/{sellerId}` da
  `quickAction` também é um placeholder até essa tela (fora do escopo desta task) ser criada.
