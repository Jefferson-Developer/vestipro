# TASK-129 — Implementar insight de risco de churn (CONCLUÍDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ✅ Concluída

## Resumo

Implementada a regra de insight "risco de churn" descrita na seção 11 de `tasks.md`, combinando três
sinais independentes — queda de frequência de compra, queda de faturamento e health score do cliente
(TASK-062) — em um único score de risco explicável, priorizado por impacto financeiro do cliente.
Seguindo o padrão das regras anteriores (TASK-121 a TASK-128), foi implementada nos dois lugares em
que as demais regras já existem: no domínio Flutter/Dart (`ChurnRiskInsightRule`) e no espelho em
Cloud Functions/TypeScript usado pela geração agendada server-side (`generateInsightsScheduled`).

## Decisões de design

- **Snapshot único por cliente:** `InsightChurnRiskSnapshot` carrega os dados brutos necessários aos
  três sinais — frequência recente/histórica, faturamento recente/histórico, health score (0..100,
  TASK-062) e `historicalOrderCount` (gate de confiabilidade) — mais um `averageTicket` opcional como
  fallback de impacto financeiro. A entidade expõe apenas getters de normalização puros
  (`frequencyDeclineRatio`, `revenueDeclineRatio`, `healthScoreRiskRatio`, `financialImpactBase`),
  sem depender de configuração da organização, mantendo a composição dos pesos na regra (que é onde
  os `InsightOrganizationSettings` entram).
- **Composição por média ponderada normalizada:** o score de risco é
  `(freq*pesoFreq + valor*pesoValor + health*pesoHealth) / (pesoFreq+pesoValor+pesoHealth)`. Dividir
  pela soma dos pesos garante que o score permaneça em `[0, 1]` mesmo se a organização configurar
  pesos que não somem exatamente 1. Pesos padrão documentados no código:
  `churnRiskFrequencyWeight=0.35`, `churnRiskValueWeight=0.35`, `churnRiskHealthScoreWeight=0.30`.
- **Faixas de risco configuráveis, "baixo" não gera insight:** `churnRiskMediumThreshold` (0.35),
  `churnRiskHighThreshold` (0.55) e `churnRiskCriticalThreshold` (0.75) mapeiam o score para
  medio/alto/critico → `InsightSeverity.medium/high/critical`. Scores abaixo do limiar médio são
  "baixo risco" e não geram insight — mesmo padrão das demais regras (ex. `revenueDropThreshold`),
  evitando ruído para clientes sem sinal de risco relevante.
- **Dados insuficientes não geram falso positivo:** `churnRiskMinimumHistoricalOrders` (padrão 3)
  bloqueia a regra inteira para clientes com poucos pedidos históricos — um cliente novo tem
  naturalmente frequência baixa, o que não deve virar "risco de churn". A regra optou por **não
  gerar** o insight nesse caso (em vez de gerar com uma flag de "dados insuficientes"), consistente
  com o padrão de todas as regras existentes, que sempre usam `continue`/`return []` para descartar
  candidatos sem sinal confiável, em vez de emitir insights degradados.
- **Priorização por impacto financeiro, não pelo score isolado:** `estimatedImpact.amount =
  financialImpactBase * riskScore` (faturamento histórico, com fallback para ticket médio, vezes o
  score de risco) e `estimatedImpact.percentage = riskScore`. Como o `InsightEngine`/`evaluateInsights`
  já ordenam globalmente por `amount + percentage*1000`, um cliente de alto valor com risco médio
  produz um `amount` maior que um cliente de baixo valor com risco alto, satisfazendo o critério de
  aceite sem precisar de lógica de ordenação adicional na regra.
- **Evidência sempre com os três sinais e seus pesos:** cada insight expõe oito itens de evidência —
  valor e peso de cada um dos três sinais, o score composto e a faixa de risco resultante — para que
  o score nunca seja uma "caixa preta".
- **Ações rápidas:** `quickAction` = "Agendar contato prioritario" (`scheduleContact`), conforme
  pedido explicitamente pela task por ser a ação mais urgente; `secondaryActions` = "Abrir cliente
  360" (`openCustomer`, rota `/customers/{id}`). Nenhum novo `InsightActionType` foi necessário — os
  dois tipos já existiam.
- **`InsightType.churnRisk`** já existia como placeholder desde a base do engine (TASK-121) e não era
  referenciado em nenhum lugar; esta task passa a implementá-lo de fato.

## Arquivos criados

- `lib/features/insights/domain/entities/insight_churn_risk_snapshot.dart`
- `lib/features/insights/domain/rules/churn_risk_insight_rule.dart`
- `test/features/insights/domain/rules/churn_risk_insight_rule_test.dart`
- `functions/src/insights/churn-risk-insight-rule.ts`
- `docs/tasks/TASK-129-implementar-insight-de-risco-de-churn-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/insights/domain/entities/insight_dataset.dart` — adiciona `churnRiskSnapshots`.
- `lib/features/insights/domain/entities/insight_organization_settings.dart` — adiciona os pesos de
  composição, o mínimo de pedidos históricos e os três limiares de faixa de risco.
- `lib/features/insights/insight_module.dart` — registra `ChurnRiskInsightRule` na lista de regras.
- `lib/features/insights/insights.dart` — exporta a nova entidade e a nova regra.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar
  `ChurnRiskInsightRule` na injeção de dependência (nenhuma edição manual).
- `functions/src/insights/insight-engine.ts` — adiciona `'churnRisk'` a `InsightType`, a interface
  `InsightChurnRiskSnapshot`, os sete campos de configuração em `InsightOrganizationSettings`/
  `DEFAULT_INSIGHT_SETTINGS` e `churnRiskSnapshots` em `InsightDataset`.
- `functions/src/insights/generate-insights-scheduled.ts` — adiciona `loadChurnRiskSnapshots` (lendo
  a coleção `insightChurnRiskSnapshots` por organização), registra `ChurnRiskInsightRule` em
  `defaultRules`, propaga `churnRiskSnapshots` por `buildInsightsForOrganization` e lê os novos
  campos de configuração em `resolveSettings`.

## Testes

`test/features/insights/domain/rules/churn_risk_insight_rule_test.dart` (7 casos, cobrindo os
testes obrigatórios da task):

- composição com os três sinais altos → score 1.0 → faixa crítica, evidência completa;
- composição com sinais mistos (todos em 0.5) → faixa média;
- composição com os três sinais baixos (0.1) → nenhum insight gerado (risco "baixo" não é
  acionável);
- classificação nas fronteiras de cada faixa (0.349/0.351, 0.549/0.551, 0.749/0.751 — deslocadas por
  uma pequena margem dos limiares exatos por serem médias ponderadas em ponto flutuante, evitando
  falso-negativo por erro de arredondamento na igualdade exata);
- priorização por impacto financeiro: cliente de alto valor (R$ 200.000, risco médio) à frente de
  cliente de baixo valor (R$ 5.000, risco alto);
- cliente com histórico insuficiente (2 pedidos, abaixo do mínimo de 3) não gera insight mesmo com
  sinais no máximo;
- fallback para ticket médio quando não há faturamento histórico.

## Validações executadas

- `flutter test test/features/insights/domain/rules/churn_risk_insight_rule_test.dart` — 7 testes,
  todos passando.
- `flutter analyze lib/features/insights test/features/insights lib/app/injection.config.dart` —
  nenhum problema encontrado.
- `dart format` nos arquivos criados/alterados desta task.
- `npx tsc --noEmit -p tsconfig.json` em `functions/` — sem erros de tipo.
- `npx eslint src/insights/churn-risk-insight-rule.ts src/insights/insight-engine.ts src/insights/generate-insights-scheduled.ts`
  em `functions/` — sem problemas.
- `npx jest test/insights` em `functions/` — 2 testes existentes de `generate-insights-scheduled`
  continuam passando (assinatura de `buildInsightsForOrganization` manteve compatibilidade, pois o
  novo campo é opcional).

## Pendências / riscos

- A camada de agregação server-side que popula `insightChurnRiskSnapshots` (cálculo de frequência
  recente/histórica, faturamento recente/histórico e leitura do health score do cliente a partir dos
  dados reais de pedidos e do `CustomerScoringService`) ainda não existe — mesmo padrão já adotado
  por `crossSellSnapshots`/`upSellSnapshots`/`insufficientMixSnapshots`/`stockPositionSnapshots`,
  corresponde à TASK-133 (camada de agregação server-side), dependência declarada e ainda pendente no
  backlog. Nenhuma lógica desta task depende de TASK-133 estar concluída: o contrato de dados de
  entrada (`InsightChurnRiskSnapshot`) já está pronto para ser alimentado quando essa camada for
  implementada.
- A rota `/customers/{id}` (ação "Abrir cliente 360") segue a mesma convenção de deep link já usada
  por outras regras (ex. `revenue_drop`), mas não foi confirmado nesta task que a tela de "cliente
  360º" com essa exata rota já existe no app — mesmo nível de risco já aceito pelas regras
  anteriores, e não bloqueia esta task, que cobre apenas o domínio do insight.
- A regra optou por não emitir insight de "dados insuficientes" (apenas descarta o candidato), o que
  atende a um dos dois comportamentos aceitos explicitamente pela task ("não gera insight de risco
  confiável, ou gera com sinalização explícita de dados insuficientes"). Se o produto decidir, no
  futuro, que é desejável sinalizar explicitamente esses clientes (para incentivar coleta de
  histórico/CRM), será necessário um novo tipo de insight ou um status dedicado — fora do escopo
  desta task.
