# TASK-127 — Implementar insight de mix insuficiente (CONCLUÍDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ✅ Concluída

## Resumo

Implementada a regra de insight "mix abaixo do ideal", que compara o número de categorias
distintas compradas por um cliente com o benchmark (média) de um grupo de comparação configurável
pela organização (segmento, região, porte ou combinação), sinalizando quando o cliente compra
significativamente menos categorias do que clientes semelhantes. A regra foi implementada nos dois
lugares em que as demais regras de insight já existem no repositório: no domínio Flutter/Dart
(`InsufficientMixInsightRule`) e no espelho em Cloud Functions/TypeScript usado pela geração
agendada server-side (`generateInsightsScheduled`), seguindo o mesmo padrão das regras anteriores
(TASK-121 a TASK-126).

## Decisões de design

- **Benchmark nunca hardcoded, sempre derivado de dados explicáveis:** em vez de um escalar bruto
  pré-computado, o benchmark (número médio de categorias distintas compradas pelo grupo) é
  calculado pela própria regra somando `peerAdoptionRate` (fração 0..1 do grupo que compra aquela
  categoria) de cada categoria do universo de comparação. Por linearidade de esperança, essa soma
  é matematicamente igual à média de categorias distintas compradas por cliente do grupo — o que
  elimina a necessidade de um campo opaco e torna o cálculo auditável categoria a categoria (mesma
  evidência already exposta por categoria).
- **Exclusão de categorias parametrizável por organização/segmento:** `InsightOrganizationSettings`
  ganhou `insufficientMixExcludedCategoryIds` (exclusão global) e
  `insufficientMixExcludedCategoryIdsBySegment` (exclusão adicional por segmento/perfil de
  cliente), com resolver `resolveInsufficientMixExcludedCategoryIds(segment)` que mescla os dois
  conjuntos — mesmo padrão já usado por `inactivityThresholdDaysBySegment`/
  `resolveInactivityThreshold`. A exclusão afeta tanto o cálculo do benchmark quanto a contagem de
  categorias do cliente e a lista de categorias ausentes sugeridas, nunca só a exibição.
- **Threshold configurável:** `insufficientMixThresholdPercentage` (padrão `0.7` = 70% do
  benchmark), nova configuração em `InsightOrganizationSettings`, seguindo o padrão de
  `upSellMinimumTicketGapPercentage`/`customerGrowthMinimumAverageRate`.
- **Um insight agregado por cliente:** diferente do up-sell (um insight por categoria elegível), o
  mix insuficiente segue o padrão do cross-sell — um único insight por cliente reunindo até 5
  categorias ausentes mais relevantes (ordenadas por `peerAdoptionRate` decrescente), pois o
  objetivo é uma visão consolidada do "buraco" no mix, não uma ação por categoria isolada.
- **Ação rápida:** "Ver categorias ausentes" (`InsightActionType.viewCategory`, tipo já existente
  no enum), com rota `/catalog?...&categoryIds=...&addToDraftOrder=true` e payload com
  `categoryIds`/`categoryNames`, permitindo abrir a lista de categorias faltantes com atalho direto
  para adicionar ao pedido em rascunho, conforme pedido no objetivo da task.
- **`InsightType.insufficientMix`** já existia no enum Dart (definido antecipadamente em
  TASK-121); foi adicionado ao union type equivalente em TypeScript (`insight-engine.ts`).
- **Impacto estimado:** como o dataset de mix não carrega valor monetário (apenas taxas de adoção),
  `estimatedImpact` usa somente `percentage` (o gap `1 - ratio` entre o cliente e o benchmark),
  suficiente para satisfazer `InsightStructuralValidator.hasValue` e para o `InsightEngine`
  priorizar por impacto.

## Arquivos criados

- `lib/features/insights/domain/entities/insight_insufficient_mix_category_candidate.dart`
- `lib/features/insights/domain/entities/insight_insufficient_mix_snapshot.dart`
- `lib/features/insights/domain/rules/insufficient_mix_insight_rule.dart`
- `test/features/insights/domain/rules/insufficient_mix_insight_rule_test.dart`
- `functions/src/insights/insufficient-mix-insight-rule.ts`
- `docs/tasks/TASK-127-implementar-insight-de-mix-insuficiente-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/insights/domain/entities/insight_dataset.dart` — adiciona
  `insufficientMixSnapshots`.
- `lib/features/insights/domain/entities/insight_organization_settings.dart` — adiciona
  `insufficientMixThresholdPercentage` (padrão `0.7`), `insufficientMixExcludedCategoryIds` e
  `insufficientMixExcludedCategoryIdsBySegment`, com o resolver
  `resolveInsufficientMixExcludedCategoryIds`.
- `lib/features/insights/insight_module.dart` — registra `InsufficientMixInsightRule` na lista de
  regras.
- `lib/features/insights/insights.dart` — exporta as novas entidades e a nova regra.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar
  `InsufficientMixInsightRule` na injeção de dependência (nenhuma edição manual).
- `functions/src/insights/insight-engine.ts` — adiciona `'insufficientMix'` a `InsightType`, os
  tipos `InsightInsufficientMixCategoryCandidate`/`InsightInsufficientMixSnapshot`, o campo
  `insufficientMixSnapshots` em `InsightDataset` e `insufficientMixThresholdPercentage`/
  `insufficientMixExcludedCategoryIds`/`insufficientMixExcludedCategoryIdsBySegment` em
  `InsightOrganizationSettings`/`DEFAULT_INSIGHT_SETTINGS`.
- `functions/src/insights/generate-insights-scheduled.ts` — adiciona
  `loadInsufficientMixSnapshots` (lendo a coleção `insightInsufficientMixSnapshots` por
  organização), registra `InsufficientMixInsightRule` em `defaultRules`, propaga
  `insufficientMixSnapshots` por `buildInsightsForOrganization` e lê as novas configurações em
  `resolveSettings` (com os novos helpers `normalizeStringArray`/`normalizeSegmentCategoryIds`).

## Testes

- `test/features/insights/domain/rules/insufficient_mix_insight_rule_test.dart` (4 casos, cobrindo
  os 3 testes obrigatórios da task):
  1. Dispara quando o cliente compra menos categorias distintas do que o benchmark do grupo de
     comparação (benchmark calculado a partir da soma dos `peerAdoptionRate`).
  2. Não dispara quando o cliente já está no benchmark ou acima dele.
  3. Exclusão de categorias irrelevantes configuradas pela organização (por segmento): mesmo
     snapshot dispara sem a configuração de exclusão e deixa de disparar quando as categorias
     irrelevantes são excluídas do cálculo (tanto do benchmark quanto da contagem do cliente).
  4. Recomputo do benchmark ao alterar o grupo de comparação: o mesmo cliente, com um snapshot de
     um grupo de comparação diferente (outra região/adoção), dispara ou deixa de disparar conforme
     o novo benchmark.

## Validações executadas

- `flutter test test/features/insights` — 27 testes, todos passando (inclui os 4 novos).
- `flutter analyze lib/features/insights test/features/insights lib/app/injection.config.dart` —
  nenhum problema encontrado.
- `dart format` nos arquivos criados/alterados (Dart).
- `npx tsc --noEmit` em `functions/` — sem erros de tipo.
- `npx eslint src/insights/insufficient-mix-insight-rule.ts src/insights/insight-engine.ts src/insights/generate-insights-scheduled.ts`
  em `functions/` — sem problemas.
- `npx jest test/insights` em `functions/` — 2 testes existentes de `generate-insights-scheduled`
  continuam passando (assinatura de `buildInsightsForOrganization` manteve compatibilidade, pois o
  novo campo é opcional).

## Pendências / riscos

- A camada de agregação server-side que efetivamente popula `insightInsufficientMixSnapshots`
  (cálculo das categorias distintas por cliente, das taxas de adoção do grupo de comparação e do
  grupo em si a partir dos pedidos reais) ainda não existe — mesmo padrão já adotado por
  `crossSellSnapshots` e `upSellSnapshots` nas tasks anteriores, e corresponde à TASK-133 (camada
  de agregação server-side), dependência declarada e ainda pendente no backlog. Nenhuma lógica
  desta task depende de TASK-133 estar concluída antes: o contrato de dados de entrada
  (`InsightInsufficientMixSnapshot`) já está pronto para ser alimentado quando essa camada for
  implementada.
- A rota `/catalog?...` usada na ação rápida segue a mesma convenção já adotada pelo cross-sell —
  ainda não foi confirmado que o parâmetro `categoryIds` (lista) é suportado hoje pela tela de
  catálogo (que hoje trata `categoryId` singular no cross-sell); é o mesmo nível de risco já aceito
  pelas regras anteriores e não bloqueia esta task, que cobre apenas o domínio do insight.
