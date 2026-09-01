# TASK-126 — Implementar insight de up-sell (CONCLUÍDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ✅ Concluída

## Resumo

Implementada a regra de insight "oportunidades de up-sell", que identifica categorias que o
próprio cliente já compra (diferente do cross-sell, TASK-125, que só olha categorias ainda não
compradas) onde seu ticket médio por pedido está abaixo da média de um grupo de "clientes
semelhantes de maior volume" na mesma categoria. Toda quantidade adicional sugerida para a ação
rápida "Sugerir grade ampliada" é sempre limitada ao saldo real de estoque disponível da variante
(TASK-090), nunca ultrapassando-o. A regra foi implementada nos dois lugares em que as demais
regras de insight já existem no repositório: no domínio Flutter/Dart (`UpSellInsightRule`) e no
espelho em Cloud Functions/TypeScript usado pela geração agendada server-side
(`generateInsightsScheduled`), seguindo o mesmo padrão das regras anteriores (TASK-121 a TASK-125).

## Decisões de design

- **Grupo de comparação explícito:** o dataset de entrada (`InsightUpSellSnapshot`) carrega um
  `comparisonGroupLabel` (texto legível, ex.: "Mesmo segmento (Premium) e regiao (Sul), maior
  volume") e um `comparisonGroupSize`, sempre expostos como evidência do insight — mesma base de
  explicabilidade já usada pelo cross-sell (TASK-125), reaproveitando o critério de semelhança já
  estabelecido, apenas restrito ao subgrupo de maior volume.
- **Um insight por categoria elegível (não agregado por cliente):** diferente do cross-sell (que
  agrupa até 3 categorias em um único insight), cada categoria elegível de up-sell vira um
  `Insight` próprio (`id: up_sell:$recipientUserId:$customerId:$categoryId`), pois cada categoria
  carrega sua própria sugestão de grade ampliada (ação rápida com quantidades por variante
  específicas daquela categoria) — agregar diluiria a ação rápida acionável.
- **Elegibilidade de categoria:** `InsightUpSellCategoryCandidate.isEligible` exige
  `customerAverageTicket > 0` (histórico de compra existente na categoria — diferencia de
  cross-sell) `&& customerAverageTicket < peerAverageTicket` (nunca dispara quando o cliente já
  está acima ou igual à média do grupo). Além disso, a regra só gera insight quando o gap percentual
  (`ticketGapPercentage`) atinge o mínimo configurável `upSellMinimumTicketGapPercentage` (padrão
  15%, nova configuração em `InsightOrganizationSettings`, espelhando o padrão já usado por
  `customerGrowthMinimumAverageRate`) — garante que só apareça diferença "relevante e sustentável"
  (critério de aceite da task), evitando ruído por diferenças marginais.
- **Estoque real antes de sugerir quantidade:** `InsightUpSellVariantCandidate` carrega
  `desiredAdditionalQuantity` (quantidade ideal, antes de checar estoque) e `availableStock` (saldo
  real da variante); `suggestedAdditionalQuantity` sempre retorna
  `min(desiredAdditionalQuantity, availableStock)` (nunca negativo, nunca ultrapassa o saldo).
  Variantes sem sugestão (`suggestedAdditionalQuantity == 0`, seja por falta de estoque ou por já
  estar no ideal) são excluídas do payload da ação rápida; se nenhuma variante da categoria tiver
  sugestão válida, o insight inteiro não é gerado (não faz sentido sugerir grade ampliada sem
  nenhuma variante disponível).
- **Ação rápida:** novo `InsightActionType.expandGrid` ("Sugerir grade ampliada"), reaproveitando a
  rota da tela de grade comercial (TASK-098) já filtrada por `customerId` e `categoryId`
  (`/orders/draft/grid?...`), com payload `variantQuantities` (mapa `variantId -> quantidade
  sugerida`) pronto para pré-popular o pedido em rascunho.
- **`InsightType.upSell`** já existia no enum Dart (definido antecipadamente em TASK-121); foi
  adicionado ao union type equivalente em TypeScript (`insight-engine.ts`).

## Arquivos criados

- `lib/features/insights/domain/entities/insight_up_sell_variant_candidate.dart`
- `lib/features/insights/domain/entities/insight_up_sell_category_candidate.dart`
- `lib/features/insights/domain/entities/insight_up_sell_snapshot.dart`
- `lib/features/insights/domain/rules/up_sell_insight_rule.dart`
- `test/features/insights/domain/rules/up_sell_insight_rule_test.dart`
- `functions/src/insights/up-sell-insight-rule.ts`
- `docs/tasks/TASK-126-implementar-insight-de-up-sell-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/insights/domain/entities/insight_dataset.dart` — adiciona `upSellSnapshots`.
- `lib/features/insights/domain/entities/insight_organization_settings.dart` — adiciona
  `upSellMinimumTicketGapPercentage` (padrão `0.15`).
- `lib/features/insights/domain/value_objects/insight_action_type.dart` — adiciona `expandGrid`.
- `lib/features/insights/insight_module.dart` — registra `UpSellInsightRule` na lista de regras.
- `lib/features/insights/insights.dart` — exporta as novas entidades e a nova regra.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar
  `UpSellInsightRule` na injeção de dependência (nenhuma edição manual).
- `functions/src/insights/insight-engine.ts` — adiciona `'upSell'` a `InsightType`, `'expandGrid'`
  a `InsightActionType`, os tipos `InsightUpSellVariantCandidate` / `InsightUpSellCategoryCandidate`
  / `InsightUpSellSnapshot`, o campo `upSellSnapshots` em `InsightDataset` e
  `upSellMinimumTicketGapPercentage` em `InsightOrganizationSettings`/`DEFAULT_INSIGHT_SETTINGS`.
- `functions/src/insights/generate-insights-scheduled.ts` — adiciona `loadUpSellSnapshots` (lendo a
  coleção `insightUpSellSnapshots` por organização), registra `UpSellInsightRule` em `defaultRules`,
  propaga `upSellSnapshots` por `buildInsightsForOrganization` e lê
  `upSellMinimumTicketGapPercentage` em `resolveSettings`.

## Testes

- `test/features/insights/domain/rules/up_sell_insight_rule_test.dart` (5 casos, cobrindo os 3
  testes obrigatórios da task e mais 2 casos de borda):
  1. Dispara quando o cliente está abaixo da média do grupo de comparação de maior volume.
  2. Não dispara quando o cliente já está acima/igual à média do grupo (incluindo categoria já na
     média exata).
  3. Não dispara quando o gap fica abaixo do mínimo configurável (diferença não relevante/
     sustentável).
  4. Limita a quantidade sugerida ao saldo real disponível da variante (nunca sugere além do
     estoque; exclui variante sem estoque).
  5. Não gera insight quando nenhuma variante da categoria tem estoque disponível para sugestão.

## Validações executadas

- `flutter test test/features/insights` — 24 testes, todos passando (inclui os 5 novos).
- `flutter analyze lib/features/insights` — nenhum problema encontrado.
- `npx tsc --noEmit` em `functions/` — sem erros de tipo.
- `npx jest test/insights` em `functions/` — 2 testes existentes de `generate-insights-scheduled`
  continuam passando (assinatura de `buildInsightsForOrganization` manteve compatibilidade, pois o
  novo campo é opcional).

## Pendências / riscos

- A camada de agregação server-side que efetivamente popula `insightUpSellSnapshots` (cálculo do
  ticket médio/quantidade por categoria por cliente e do grupo de comparação de maior volume a
  partir dos pedidos reais) ainda não existe — mesmo padrão já adotado por `crossSellSnapshots`,
  `customerGrowthSnapshots` e `revenueComparisons` nas tasks anteriores, e corresponde ao EPIC-17
  (TASK-133 — camada de agregação server-side), dependência declarada e ainda pendente no backlog.
  Nenhuma lógica desta task depende de TASK-133 estar concluída antes: o contrato de dados de
  entrada (`InsightUpSellSnapshot`) já está pronto para ser alimentado quando essa camada for
  implementada.
- A rota `/orders/draft/grid` usada na ação rápida segue a mesma convenção já adotada pelas demais
  regras de insight (ex.: `/catalog?...` no cross-sell) — ainda não foi confirmado que essa rota
  exata está registrada em `app_router.dart` (a navegação real do pedido em rascunho/grade
  comercial, TASK-096 a TASK-098, não expõe essa rota nomeada hoje); é o mesmo nível de risco já
  aceito pelas regras anteriores e não bloqueia esta task, que cobre apenas o domínio do insight.
