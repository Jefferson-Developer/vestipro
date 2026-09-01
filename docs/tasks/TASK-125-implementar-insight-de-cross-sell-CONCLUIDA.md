# TASK-125 — Implementar insight de cross-sell (CONCLUÍDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ✅ Concluída

## Resumo

Implementada a regra de insight "oportunidades de cross-sell", que compara cada cliente contra um
grupo de "clientes semelhantes" (critério explícito e configurável no próprio dataset, nunca uma
caixa preta) e sugere categorias de produto que o grupo compra com frequência e que o cliente-alvo
ainda não compra. A regra foi implementada nos dois lugares em que as demais regras de insight já
existem no repositório: no domínio Flutter/Dart (`CrossSellInsightRule`, usada localmente e como
referência de contrato) e no espelho em Cloud Functions/TypeScript usado pela geração agendada
server-side (`generateInsightsScheduled`), seguindo o mesmo padrão das regras anteriores (TASK-121 a
TASK-124).

## Decisões de design

- **Critério de semelhança explícito:** o dataset de entrada (`InsightCrossSellSnapshot`) carrega um
  `similarityGroupLabel` (texto legível, ex.: "Mesmo segmento (Premium) e regiao (Sul)") e um
  `similarityGroupSize` (tamanho do grupo de comparação), sempre expostos como evidência do insight.
  A composição desse grupo (ex.: segmento + região) é responsabilidade da camada de agregação que
  alimenta o snapshot — assim como as demais regras já existentes (`customerGrowthSnapshots`,
  `revenueComparisons`) recebem dados já agregados, sem uma "TASK-133" genérica ainda implementada.
- **Um insight por cliente, não por categoria:** como o motor de insights (`InsightEngine` /
  `evaluateInsights`) deduplica por `type:customerId`, mantendo apenas o insight de maior impacto, a
  regra agrupa até 3 sugestões de categoria em um único `Insight` por cliente — a categoria de maior
  relevância (adesão × ticket médio) vira `quickAction` e as demais (até 2) viram `secondaryActions`.
  Isso preserva o requisito de "no máximo 3 sugestões simultâneas por cliente, ordenadas por
  relevância" sem ser descartado pela deduplicação do motor.
- **Elegibilidade de candidato:** um `InsightCrossSellCategoryCandidate` só é sugerido quando
  `!alreadyPurchasedByCustomer && isAvailableInCustomerPriceList && isActiveCollection &&
  peerAdoptionRate > 0`, cobrindo as regras de negócio da task (nunca sugerir categoria indisponível
  na tabela de preço do cliente-alvo, nem categoria descontinuada/fora de coleção vigente, nem
  categoria que o cliente já compra).
- **Ação rápida:** `InsightActionType.startOrder`, reaproveitando a rota do catálogo (TASK-097) já
  filtrada por `categoryId` e `customerId`, com payload pronto para adicionar ao pedido em rascunho.
- **`InsightType.crossSell`** já existia no enum Dart (definido antecipadamente em TASK-121); foi
  adicionado ao union type equivalente em TypeScript (`insight-engine.ts`), que antes só cobria os 3
  tipos já implementados.

## Arquivos criados

- `lib/features/insights/domain/entities/insight_cross_sell_category_candidate.dart`
- `lib/features/insights/domain/entities/insight_cross_sell_snapshot.dart`
- `lib/features/insights/domain/rules/cross_sell_insight_rule.dart`
- `test/features/insights/domain/rules/cross_sell_insight_rule_test.dart`
- `functions/src/insights/cross-sell-insight-rule.ts`
- `docs/tasks/TASK-125-implementar-insight-de-cross-sell-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/insights/domain/entities/insight_dataset.dart` — adiciona `crossSellSnapshots`.
- `lib/features/insights/insight_module.dart` — registra `CrossSellInsightRule` na lista de regras.
- `lib/features/insights/insights.dart` — exporta as novas entidades e a nova regra.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar
  `CrossSellInsightRule` na injeção de dependência (nenhuma edição manual).
- `functions/src/insights/insight-engine.ts` — adiciona `'crossSell'` a `InsightType` e os tipos
  `InsightCrossSellCategoryCandidate` / `InsightCrossSellSnapshot`, além do campo
  `crossSellSnapshots` em `InsightDataset`.
- `functions/src/insights/generate-insights-scheduled.ts` — adiciona `loadCrossSellSnapshots`
  (lendo a coleção `insightCrossSellSnapshots` por organização), registra `CrossSellInsightRule` em
  `defaultRules` e propaga `crossSellSnapshots` por `buildInsightsForOrganization`.

## Testes

- `test/features/insights/domain/rules/cross_sell_insight_rule_test.dart` (4 casos, cobrindo os 4
  testes obrigatórios da task):
  1. Dispara quando existe categoria popular entre semelhantes ausente no histórico do cliente.
  2. Não dispara quando o cliente já compra todas as categorias relevantes do grupo de comparação.
  3. Limita a 3 sugestões por cliente, ordenadas por relevância (adesão × ticket médio).
  4. Exclui categoria indisponível na tabela de preço do cliente (e também cobre categoria fora de
     coleção vigente).

## Validações executadas

- `flutter test test/features/insights` — 18 testes, todos passando (inclui os 4 novos).
- `flutter analyze lib/features/insights` — nenhum problema encontrado.
- `npx tsc --noEmit` em `functions/` — sem erros de tipo.
- `npx jest test/insights` em `functions/` — 2 testes existentes de `generate-insights-scheduled`
  continuam passando (assinatura de `buildInsightsForOrganization` manteve compatibilidade, pois o
  novo campo é opcional).

## Pendências / riscos

- A camada de agregação server-side que efetivamente popula `insightCrossSellSnapshots` (cálculo do
  grupo de clientes semelhantes e adesão por categoria a partir dos pedidos reais) ainda não existe —
  isso é esperado, pois é o mesmo padrão já adotado por `customerGrowthSnapshots` e
  `revenueComparisons` nas tasks anteriores (TASK-122 a TASK-124), e corresponde ao EPIC-17
  (TASK-133 — camada de agregação server-side), que é uma dependência declarada e ainda pendente no
  backlog. Nenhuma lógica desta task depende de TASK-133 estar concluída antes: o contrato de dados
  de entrada (`InsightCrossSellSnapshot`) já está pronto para ser alimentado quando essa camada for
  implementada.
