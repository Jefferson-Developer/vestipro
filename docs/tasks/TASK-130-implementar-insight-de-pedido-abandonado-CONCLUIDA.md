# TASK-130 — Implementar insight de pedido abandonado/carrinho salvo (CONCLUÍDA)

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ✅ Concluída

## Resumo

Implementada a regra de insight "pedidos abandonados"/"carrinhos salvos" descrita na seção 11 de
`tasks.md`, detectando rascunhos de pedido (`OrderStatus.draft`/`pendingSync`, TASK-096) parados há
mais de X horas sem alteração de conteúdo, com dois níveis de severidade configuráveis por
organização e ação rápida de retomada exata do rascunho. Seguindo o padrão das regras anteriores
(TASK-121 a TASK-129), foi implementada nos dois lugares em que as demais regras já existem: no
domínio Flutter/Dart (`AbandonedDraftOrderInsightRule`) e no espelho em Cloud Functions/TypeScript
usado pela geração agendada server-side (`generateInsightsScheduled`).

## Decisões de design

- **Sinal único: tempo desde a última alteração de conteúdo.** `InsightAbandonedOrderSnapshot`
  carrega `lastContentChangeAt` (última vez que os itens/quantidades do rascunho mudaram) — nunca a
  última tentativa de sincronização da Outbox (TASK-108). O campo `hasPendingOutboxSync` existe na
  entidade apenas como informação, e é explicitamente **nunca lido** pelo portão de estagnação da
  regra — comentário no código documenta essa decisão, que é o próprio critério de aceite da task
  ("nunca confundir pendência de sincronização com abandono").
- **Duas faixas de severidade configuráveis:** `abandonedOrderSavedCartThresholdHours` (padrão 24h,
  `InsightSeverity.low`, rótulo "Carrinho salvo") e `abandonedOrderAbandonedThresholdHours` (padrão
  72h, `InsightSeverity.medium`, rótulo "Pedido abandonado"). Abaixo do primeiro limiar, nenhum
  insight é gerado (rascunho recente, comportamento normal). Comparações usam `>=` nas fronteiras,
  mesmo precedente das demais regras (ex. `ChurnRiskInsightRule`).
- **Impacto estimado = valor já somado dos itens do rascunho:** `estimatedImpact.amount =
  snapshot.estimatedValue` — a receita potencial em risco, exatamente como pedido pela task (sem
  percentual, já que não há uma taxa/proporção natural aqui como nas demais regras).
- **Retomada exata sem duplicar estado no snapshot:** a ação rápida "Retomar pedido"
  (`InsightActionType.resumeOrder`, novo tipo) carrega apenas `orderId` (rota `/orders/draft?orderId=
  {id}`, payload com `orderId`/`customerId`) — a restauração exata de itens/quantidades já é
  responsabilidade do `OrderDraftRepository`/`OrderDraftBloc` existentes (TASK-096), que carregam o
  rascunho completo a partir do id. O snapshot não precisa (e não deve) duplicar a lista de itens só
  para fins de insight.
- **"Contatar cliente" condicional ao contexto de atendimento:** a task pede as duas ações
  ("Retomar pedido" e "Contatar cliente"), mas apenas quando o rascunho foi iniciado em contexto de
  atendimento faz sentido sugerir contato reativo — por isso `scheduleContact` ("Contatar cliente")
  só aparece em `secondaryActions` quando `snapshot.startedInServiceContext == true`; "Abrir cliente
  360" (`openCustomer`) é sempre incluído como ação secundária de contexto, mesmo padrão de
  `ChurnRiskInsightRule`.
- **Referência inválida nunca reabre silenciosamente:** quando `hasInvalidReference == true`
  (cliente/produto excluído ou tabela de preço expirada), a regra adiciona um item de evidência
  (`invalid_reference_warning`), acrescenta o aviso à descrição, troca a recomendação para pedir
  revisão explícita antes de retomar, e propaga `hasInvalidReference: true` no `payload` da ação
  "Retomar pedido" — a decisão de bloquear ou apenas avisar na UI fica para a tela que consumir essa
  ação (fora do escopo desta task, que cobre o domínio do insight).
- **`InsightType.abandonedOrder`** já existia como placeholder desde a base do engine (TASK-121) e
  não era referenciado em nenhum lugar; esta task passa a implementá-lo de fato.
- **Novo `InsightActionType.resumeOrder`**, já que nenhum tipo existente ("startOrder" é para
  iniciar/adicionar itens a um pedido, não para reabrir um rascunho específico) cobria "reabrir este
  rascunho exato".

## Arquivos criados

- `lib/features/insights/domain/entities/insight_abandoned_order_snapshot.dart`
- `lib/features/insights/domain/rules/abandoned_order_insight_rule.dart`
- `test/features/insights/domain/rules/abandoned_order_insight_rule_test.dart`
- `functions/src/insights/abandoned-order-insight-rule.ts`
- `docs/tasks/TASK-130-implementar-insight-de-pedido-abandonado-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/insights/domain/entities/insight_dataset.dart` — adiciona `abandonedOrderSnapshots`.
- `lib/features/insights/domain/entities/insight_organization_settings.dart` — adiciona
  `abandonedOrderSavedCartThresholdHours` e `abandonedOrderAbandonedThresholdHours`.
- `lib/features/insights/domain/value_objects/insight_action_type.dart` — adiciona `resumeOrder`.
- `lib/features/insights/insight_module.dart` — registra `AbandonedDraftOrderInsightRule` na lista de
  regras.
- `lib/features/insights/insights.dart` — exporta a nova entidade e a nova regra.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar
  `AbandonedDraftOrderInsightRule` na injeção de dependência (nenhuma edição manual).
- `functions/src/insights/insight-engine.ts` — adiciona `'abandonedOrder'` a `InsightType`,
  `'resumeOrder'` a `InsightActionType`, a interface `InsightAbandonedOrderSnapshot`, os dois campos
  de limiar em `InsightOrganizationSettings`/`DEFAULT_INSIGHT_SETTINGS` e `abandonedOrderSnapshots`
  em `InsightDataset`.
- `functions/src/insights/generate-insights-scheduled.ts` — adiciona `loadAbandonedOrderSnapshots`
  (lendo a coleção `insightAbandonedOrderSnapshots` por organização), registra
  `AbandonedOrderInsightRule` em `defaultRules`, propaga `abandonedOrderSnapshots` por
  `buildInsightsForOrganization` e lê os dois novos campos de configuração em `resolveSettings`.

## Testes

`test/features/insights/domain/rules/abandoned_order_insight_rule_test.dart` (8 casos, cobrindo os
testes obrigatórios da task):

- rascunho editado recentemente (2h) não gera insight;
- fronteira exata do limiar de "carrinho salvo" (24h) gera insight `low`;
- pouco abaixo do limiar de "pedido abandonado" (71h59) permanece `low`;
- fronteira exata do limiar de "pedido abandonado" (72h) gera insight `medium`;
- rascunho com `hasPendingOutboxSync: true` mas alterado há 1h não é tratado como abandonado (prova
  que a regra ignora a flag de sincronização);
- ação "Retomar pedido" carrega o `orderId` exato do rascunho no payload;
- "Contatar cliente" só aparece nas ações secundárias quando `startedInServiceContext == true`;
- referência inválida gera evidência de aviso, propaga `hasInvalidReference` no payload da ação e
  ajusta a recomendação — nunca reabre silenciosamente.

## Validações executadas

- `flutter test test/features/insights/domain/rules/abandoned_order_insight_rule_test.dart` — 8
  testes, todos passando.
- `flutter test test/features/insights` — 52 testes, todos passando (suíte completa do módulo,
  incluindo as regras já existentes).
- `flutter analyze lib/features/insights test/features/insights lib/app/injection.config.dart` —
  nenhum problema encontrado.
- `dart format` nos arquivos criados/alterados desta task.
- `dart run build_runner build` em `functions/` não se aplica; em Flutter, regenerado
  `lib/app/injection.config.dart` (injectable) — sem edições manuais.
- `npx tsc --noEmit -p tsconfig.json` em `functions/` — sem erros de tipo.
- `npx eslint src/insights/abandoned-order-insight-rule.ts src/insights/insight-engine.ts src/insights/generate-insights-scheduled.ts`
  em `functions/` — sem problemas.
- `npx jest test/insights` em `functions/` — 2 testes existentes de `generate-insights-scheduled`
  continuam passando (assinatura de `buildInsightsForOrganization` manteve compatibilidade, pois o
  novo campo é opcional).

## Pendências / riscos

- A camada de agregação server-side que popula `insightAbandonedOrderSnapshots` (varrer pedidos com
  status `draft`/`pendingSync`, calcular `lastContentChangeAt`, `estimatedValue`,
  `startedInServiceContext` e `hasInvalidReference` a partir dos dados reais de `Order`) ainda não
  existe — mesmo padrão já adotado por `churnRiskSnapshots`/`crossSellSnapshots`/`upSellSnapshots`/
  `insufficientMixSnapshots`/`stockPositionSnapshots`, corresponde à TASK-133 (camada de agregação
  server-side), dependência declarada e ainda pendente no backlog. Nenhuma lógica desta task depende
  de TASK-133 estar concluída: o contrato de dados de entrada (`InsightAbandonedOrderSnapshot`) já
  está pronto para ser alimentado quando essa camada for implementada.
- A rota `/orders/draft?orderId={id}` (ação "Retomar pedido") segue a mesma convenção de deep link
  abstrato já usada por outras regras (ex. `up_sell` usa `/orders/draft/grid?...`), decoupled da rota
  concreta do GoRouter (`OrderDraftRoute`, que hoje usa o parâmetro de query `draftId`, não `orderId`)
  — a resolução dessas rotas de insight para rotas reais do app é escopo da TASK-132 (central de
  oportunidades), não desta task, mesmo risco já aceito pelas regras anteriores.
- Não foi criado um novo status/insight para o caso de dados insuficientes (ex. rascunho sem
  `lastContentChangeAt` conhecido) — a regra depende do dado já vir preenchido no snapshot pela
  camada de agregação futura, mesmo contrato das demais regras.
