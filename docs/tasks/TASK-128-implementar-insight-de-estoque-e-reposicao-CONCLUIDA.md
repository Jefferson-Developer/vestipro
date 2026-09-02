# TASK-128 — Implementar insight de estoque alto/giro baixo e reposição (CONCLUÍDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ✅ Concluída

## Resumo

Implementadas as duas regras de insight de estoque descritas na seção 11 de `tasks.md`: "produtos
com estoque alto e giro baixo" (`HighStockLowTurnoverInsightRule`) e "sugestão de reposição"
(`ReplenishmentSuggestionInsightRule`) — dois sinais opostos derivados dos mesmos indicadores de
estoque (TASK-090 saldo por variante, TASK-094 índice de giro/cobertura). Seguindo o padrão das
regras anteriores (TASK-121 a TASK-127), foram implementadas nos dois lugares em que as demais
regras já existem: no domínio Flutter/Dart e no espelho em Cloud Functions/TypeScript usado pela
geração agendada server-side (`generateInsightsScheduled`).

## Decisões de design

- **Um único snapshot de entrada compartilhado pelas duas regras:** em vez de dois datasets
  separados, foi criada uma única entidade `InsightStockPositionSnapshot` (saldo atual, cobertura em
  dias, índice de giro, dias sem saída relevante, consumo médio diário, ponto de ressuprimento
  sugerido e flag de descontinuado), consumida por ambas as regras com condições de limiar opostas.
  Isso é o que garante, por construção, a exclusão mútua exigida pelo critério de aceite: uma regra
  exige cobertura alta + giro baixo, a outra exige cobertura baixa + giro alto — as duas condições
  não podem ser verdadeiras ao mesmo tempo para o mesmo produto/variante, desde que os limiares da
  organização sejam configurados de forma consistente (limiar de estoque alto acima do limiar de
  cobertura mínima de reposição, e limiar de giro baixo abaixo do limiar de giro alto de reposição).
- **Limiares configuráveis por organização e por categoria:** `InsightOrganizationSettings` ganhou
  quatro pares de configuração (valor padrão + mapa por categoria) —
  `highStockCoverageDaysThreshold(ByCategory)`, `lowTurnoverIndexThreshold(ByCategory)`,
  `replenishmentLowCoverageDaysThreshold(ByCategory)` e
  `replenishmentHighTurnoverIndexThreshold(ByCategory)` — com resolvers
  `resolveHighStockCoverageDaysThreshold`/`resolveLowTurnoverIndexThreshold`/
  `resolveReplenishmentLowCoverageDaysThreshold`/`resolveReplenishmentHighTurnoverIndexThreshold`,
  mesmo padrão de `resolveInactivityThreshold`. Diferente dos mapas por segmento (texto livre,
  normalizados para minúsculas), os mapas por categoria usam o `categoryId` (identificador opaco)
  sem normalização de caixa, apenas `trim`.
- **Produto descontinuado como candidato de liquidação, nunca de reposição:** a regra de
  estoque alto/giro baixo não filtra produtos descontinuados (podem ser liquidados); a regra de
  reposição os exclui incondicionalmente antes mesmo de avaliar os limiares, conforme exigido pela
  regra de negócio.
- **Reposição nunca gera pedido de compra automático:** a regra apenas produz o insight/ação rápida
  "Notificar compras/reposição" (`InsightActionType.notifyReplenishment`), sem qualquer efeito
  colateral de criação de pedido — automação fica para o EPIC-27, fora do escopo desta task.
- **Ponto de ressuprimento sugerido não é recalculado pela regra:** `suggestedReorderPointQuantity`
  chega pronto no snapshot, computado upstream a partir do consumo médio recente (camada de
  agregação da TASK-133, ainda não implementada — mesmo padrão de dependência futura já aceito por
  cross-sell/up-sell/insufficient-mix). A regra apenas expõe o valor como evidência.
- **Novos tipos de ação rápida:** `InsightActionType.suggestCampaign` ("Sugerir campanha/desconto",
  rota para `/pricing/campaigns/new?...`, módulo de campanhas da TASK-087) e
  `InsightActionType.notifyReplenishment` ("Notificar compras/reposição", rota para
  `/inventory/replenishment?...`) — nenhum dos tipos existentes (`viewCategory`, `startOrder` etc.)
  cobria essas duas ações centradas em produto/estoque em vez de cliente.
- **`InsightType.highStockLowTurnover`/`InsightType.replenishmentSuggestion`** substituem o
  placeholder genérico `InsightType.stockOpportunity` (adicionado antecipadamente em TASK-121 mas
  nunca referenciado em nenhum outro lugar do código) — o backlog previa dois insights distintos
  para este ciclo, então dois tipos específicos e explicáveis são mais corretos que um único tipo
  genérico.
- **Deduplicação por variante:** como o campo `Insight.productId` é o único identificador
  relacionado disponível para insights de produto, ele recebe `variantId ?? productId` (id da
  variante quando disponível), garantindo que duas variantes do mesmo produto não colidam na chave
  de deduplicação do `InsightEngine` (`type.name:productId`).
- **Impacto estimado:** ambas as regras usam apenas `percentage` — na regra de estoque alto, o
  excesso relativo de cobertura acima do limiar (`(coverageDays - threshold) / threshold`); na
  regra de reposição, o déficit relativo de cobertura abaixo do limiar
  (`(threshold - coverageDays) / threshold`, limitado a `[0, 1]`) — suficiente para o
  `InsightStructuralValidator` e para o `InsightEngine` priorizar por impacto.

## Arquivos criados

- `lib/features/insights/domain/entities/insight_stock_position_snapshot.dart`
- `lib/features/insights/domain/rules/high_stock_low_turnover_insight_rule.dart`
- `lib/features/insights/domain/rules/replenishment_suggestion_insight_rule.dart`
- `test/features/insights/domain/rules/high_stock_low_turnover_insight_rule_test.dart`
- `test/features/insights/domain/rules/replenishment_suggestion_insight_rule_test.dart`
- `functions/src/insights/high-stock-low-turnover-insight-rule.ts`
- `functions/src/insights/replenishment-suggestion-insight-rule.ts`
- `docs/tasks/TASK-128-implementar-insight-de-estoque-e-reposicao-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/insights/domain/entities/insight_dataset.dart` — adiciona `stockPositionSnapshots`.
- `lib/features/insights/domain/entities/insight_organization_settings.dart` — adiciona os quatro
  pares de limiares (globais + por categoria) e seus resolvers.
- `lib/features/insights/domain/value_objects/insight_type.dart` — substitui `stockOpportunity` por
  `highStockLowTurnover` e `replenishmentSuggestion`.
- `lib/features/insights/domain/value_objects/insight_action_type.dart` — adiciona
  `suggestCampaign` e `notifyReplenishment`.
- `lib/features/insights/insight_module.dart` — registra as duas novas regras na lista de regras.
- `lib/features/insights/insights.dart` — exporta as novas entidades e regras.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar
  `HighStockLowTurnoverInsightRule`/`ReplenishmentSuggestionInsightRule` na injeção de dependência
  (nenhuma edição manual).
- `functions/src/insights/insight-engine.ts` — adiciona `'highStockLowTurnover'`/
  `'replenishmentSuggestion'` a `InsightType`, `'suggestCampaign'`/`'notifyReplenishment'` a
  `InsightActionType`, a interface `InsightStockPositionSnapshot`, os oito campos de limiar em
  `InsightOrganizationSettings`/`DEFAULT_INSIGHT_SETTINGS` e `stockPositionSnapshots` em
  `InsightDataset`.
- `functions/src/insights/generate-insights-scheduled.ts` — adiciona `loadStockPositionSnapshots`
  (lendo a coleção `insightStockPositionSnapshots` por organização), registra as duas novas regras
  em `defaultRules`, propaga `stockPositionSnapshots` por `buildInsightsForOrganization`, lê os
  novos limiares em `resolveSettings` e adiciona o helper `normalizeCategoryThresholds` (mapa por
  categoria sem normalização de caixa, diferente de `normalizeSegmentThresholds`).

## Testes

- `test/features/insights/domain/rules/high_stock_low_turnover_insight_rule_test.dart` (5 casos,
  cobrindo os testes obrigatórios da task): dispara com cobertura acima e giro abaixo dos limiares;
  não dispara com cobertura dentro do limiar mesmo com giro baixo; não dispara com giro acima do
  limiar mesmo com cobertura alta; respeita limiares configuráveis por categoria; inclui produto
  descontinuado como candidato de liquidação.
- `test/features/insights/domain/rules/replenishment_suggestion_insight_rule_test.dart` (5 casos):
  dispara com giro alto e cobertura baixa; não dispara com cobertura confortável; não dispara com
  giro abaixo do mínimo mesmo com cobertura baixa; exclui produto descontinuado; respeita limiares
  configuráveis por categoria.

## Validações executadas

- `flutter test test/features/insights` — 37 testes, todos passando (inclui os 10 novos).
- `flutter analyze lib/features/insights test/features/insights lib/app/injection.config.dart` —
  nenhum problema encontrado.
- `dart format` nos arquivos criados/alterados (Dart) — dois arquivos fora do escopo desta task
  (`cross_sell_insight_rule.dart`, `up_sell_insight_rule.dart`) foram reformatados incidentalmente
  pelo comando e revertidos com `git checkout` antes do commit, para não alterar nada fora do
  escopo.
- `npx tsc --noEmit` em `functions/` — sem erros de tipo.
- `npx eslint src/insights/high-stock-low-turnover-insight-rule.ts src/insights/replenishment-suggestion-insight-rule.ts src/insights/insight-engine.ts src/insights/generate-insights-scheduled.ts`
  em `functions/` — sem problemas.
- `npx jest test/insights` em `functions/` — 2 testes existentes de `generate-insights-scheduled`
  continuam passando (assinatura de `buildInsightsForOrganization` manteve compatibilidade, pois o
  novo campo é opcional).

## Pendências / riscos

- A camada de agregação server-side que popula `insightStockPositionSnapshots` (cálculo de saldo,
  cobertura, índice de giro, consumo médio e ponto de ressuprimento a partir dos dados reais de
  estoque e vendas) ainda não existe — mesmo padrão já adotado por `crossSellSnapshots`/
  `upSellSnapshots`/`insufficientMixSnapshots`, corresponde à TASK-133 (camada de agregação
  server-side), dependência declarada e ainda pendente no backlog. Nenhuma lógica desta task
  depende de TASK-133 estar concluída: o contrato de dados de entrada
  (`InsightStockPositionSnapshot`) já está pronto para ser alimentado quando essa camada for
  implementada.
- As rotas `/pricing/campaigns/new?...` (ação de estoque alto/giro baixo) e
  `/inventory/replenishment?...` (ação de reposição) seguem a mesma convenção de deep link já
  adotada pelas regras anteriores, mas não foi confirmado que essas telas/rotas já existem hoje no
  app — mesmo nível de risco já aceito pelas regras anteriores (ex. `/catalog?...&categoryIds=...`
  no mix insuficiente) e não bloqueia esta task, que cobre apenas o domínio do insight.
- A notificação efetiva ao time de compras/reposição (persistência em inbox de notificações,
  disparo de push, etc.) não é acionada automaticamente por esta task — a ação rápida
  `notifyReplenishment` apenas descreve a intenção (tipo, rota, payload); a integração com
  `core/notifications` fica para quando a tela/fluxo de reposição for implementado.
