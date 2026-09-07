# TASK-184 — Concluída (2026-09-07)

## Resumo

Implementado o motor de reposição automática do EPIC-27: uma Cloud Function agendada semanal
(`calculateReplenishmentSuggestions`) que calcula, por variante/depósito, uma quantidade sugerida de
reposição a partir do giro histórico (reaproveitando `stock-turnover-shared.ts`, TASK-094) e do saldo
atual (TASK-090), sempre marcando "dados insuficientes" quando não há histórico confiável — nunca um
número arbitrário. Toda sugestão é apenas isso, uma sugestão: uma Cloud Function callable
(`decideReplenishmentSuggestion`, OWNER/ADMIN/SALES_MANAGER) é o único jeito de aceitar/ajustar/
descartar, com auditoria completa (autor+timestamp+ação), e só ao aceitar/ajustar é gerado um
rascunho de pedido de reposição (`ReplenishmentDraftOrder`, um agregado novo e enxuto, não o
`Order`/`OrderItem` de vendas). Lado Flutter: feature nova `lib/features/replenishment/` (Clean
Architecture completa) com uma tela de gestão (`ReplenishmentSuggestionsPage`) que expõe a evidência
completa do cálculo e as três ações de decisão, além de fechar o link pendente
`/inventory/replenishment` que a TASK-128 já usava sem rota registrada.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

Cloud Functions (`functions/src/replenishment/`):
- `replenishment-calculation-shared.ts` — serviço de domínio puro: `calculateReplenishmentSuggestion`,
  `ReplenishmentParameters`/`DEFAULT_REPLENISHMENT_PARAMETERS`, `ReplenishmentSuggestionStatus`/
  `FROZEN_REPLENISHMENT_STATUSES`, `asReplenishmentVariantStockBalance`/`sellableQuantityOf`.
- `calculate-replenishment-suggestions.ts` — `calculateReplenishmentSuggestions` (`onSchedule`,
  semanal, segunda-feira 04:00 America/Sao_Paulo), mais `calculateReplenishmentSuggestionsForOrganization`/
  `calculateReplenishmentSuggestionsScheduledHandler` (testáveis via `ReplenishmentPersistence`, mesmo
  padrão "porta + adapter Firestore + fake em memória" de `sync-stock-alerts.ts`).
- `decide-replenishment-suggestion.ts` — `decideReplenishmentSuggestion` (`onCall`).
- `index.ts` (barrel do módulo).

Testes de Cloud Functions (`functions/test/replenishment/`):
- `replenishment-calculation-shared.test.ts` (puro, sem Firestore).
- `calculate-replenishment-suggestions.test.ts` (fake de persistência em memória, sem emulador).
- `decide-replenishment-suggestion.test.ts` (Firestore Emulator real, mesmo padrão de
  `recompute-stock-turnover-metrics.test.ts`).

Flutter (`lib/features/replenishment/`):
- `domain/value_objects/replenishment_suggestion_status.dart`,
  `domain/value_objects/replenishment_decision_action.dart`
- `domain/entities/replenishment_suggestion.dart`,
  `domain/entities/replenishment_suggestion_page.dart`,
  `domain/entities/replenishment_turnover_evidence.dart`,
  `domain/entities/replenishment_decision_audit_entry.dart`,
  `domain/entities/replenishment_decision_result.dart`,
  `domain/entities/replenishment_draft_order.dart`,
  `domain/entities/replenishment_draft_order_item.dart`
- `domain/repositories/replenishment_repository.dart`
- `domain/usecases/list_replenishment_suggestions_use_case.dart`,
  `domain/usecases/decide_replenishment_suggestion_use_case.dart`
- `data/dtos/replenishment_suggestion_dto.dart`,
  `data/mappers/replenishment_suggestion_mapper.dart`,
  `data/datasources/replenishment_suggestion_data_source.dart`,
  `data/datasources/firestore_replenishment_suggestion_data_source.dart`,
  `data/repositories/replenishment_repository_impl.dart`
- `presentation/bloc/replenishment_suggestions_event.dart`,
  `presentation/bloc/replenishment_suggestions_state.dart`,
  `presentation/bloc/replenishment_suggestions_bloc.dart`
- `presentation/pages/replenishment_suggestions_page.dart`
- `replenishment.dart` (barrel)

Testes Flutter (`test/features/replenishment/`):
- `domain/value_objects/replenishment_suggestion_status_test.dart`
- `domain/usecases/list_replenishment_suggestions_use_case_test.dart`
- `domain/usecases/decide_replenishment_suggestion_use_case_test.dart`
- `data/dtos/replenishment_suggestion_dto_test.dart`
- `data/mappers/replenishment_suggestion_mapper_test.dart`

## Arquivos alterados

- `functions/src/index.ts` — exporta `calculateReplenishmentSuggestions`/`decideReplenishmentSuggestion`.
- `firestore.rules` — blocos `match` novos para `replenishmentSuggestions`/`replenishmentSettings`/
  `replenishmentDraftOrders` (leitura via `report.viewSensitive`/`inventory.adjust`, escrita sempre
  `false` pelo client).
- `firestore-tests/firestore.rules.test.js` — describe novo `replenishmentSuggestions` (representativo
  das três coleções, mesmo padrão já usado para as `*Aggregates` da TASK-133).
- `lib/core/analytics/analytics_events.dart` — dois eventos novos:
  `replenishmentSuggestionsViewed`/`replenishmentSuggestionDecided`.
- `lib/core/navigation/app_route_paths.dart` — `ReplenishmentSuggestionsRoute`
  (`/org/:orgId/companies/:companyId/inventory/replenishment`).
- `lib/core/navigation/app_router.dart` — `replenishmentSuggestionsPageBuilder` +
  `GoRoute` gated por `Capability.reportViewSensitive`.
- `lib/app/bootstrap.dart` — wiring do builder da página + `_navigateForInsightAction` passa a
  resolver `InsightActionType.notifyReplenishment` para `ReplenishmentSuggestionsRoute` (fechando o gap
  documentado desde TASK-132/TASK-128).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra as novas classes
  `@injectable`/`@lazySingleton`/`@LazySingleton`).
- `test/core/analytics/analytics_events_test.dart` — lista de eventos esperados atualizada com os dois
  eventos novos.
- `docs/tasks/TASKS.md` — checkbox da TASK-184 marcado, progresso atualizado para 183/219.

## Arquitetura utilizada

Feature-first + Clean Architecture, seguindo exatamente o padrão já usado por `inventory`/`cart_share`:
Presentation (`ReplenishmentSuggestionsPage` + `ReplenishmentSuggestionsBloc`) → Use case
(`ListReplenishmentSuggestionsUseCase`/`DecideReplenishmentSuggestionUseCase`) → Repository contract
(`ReplenishmentRepository`) → Repository impl (`ReplenishmentRepositoryImpl`, combinando um datasource
Firestore só-leitura com uma chamada direta a `CloudFunctionsService` para a decisão) → Datasource
(`FirestoreReplenishmentSuggestionDataSource`). Nenhuma regra de negócio (cálculo de quantidade, RBAC
de decisão) vive na UI: o cálculo é 100% server-side (TypeScript) e a decisão é 100% validada pelo
Cloud Function callable.

O cálculo de giro/cobertura reaproveita literalmente `asStockTurnoverDailyFact`/`buildMetricSnapshot`
de `stock-turnover-shared.ts` (TASK-094) — `replenishment-calculation-shared.ts` nunca duplica essas
fórmulas, apenas consome o resultado (`ReplenishmentTurnoverEvidence`, um subconjunto de
`StockTurnoverMetricSnapshot`).

## Regras de negócio implementadas

- Nenhuma sugestão vira pedido real sem ação humana explícita — `decideReplenishmentSuggestion` é o
  único jeito de sair de `suggested`/`insufficientData`.
- Cálculo sempre roda server-side (Cloud Function); não existe nenhum "espelho" Dart do cálculo de
  giro/quantidade sugerida — decisão deliberada e documentada em código (diferente do padrão de
  insights, que têm mirror Dart+TS).
- Toda sugestão expõe a evidência do cálculo (giro médio, cobertura em dias, saldo atual, parâmetros
  usados) — nunca um número sem explicação, tanto no documento Firestore quanto na UI.
- Itens sem histórico suficiente (`insufficientData`, com `insufficientDataReason` explicando o
  porquê: `noTurnoverHistory`/`noStockBaseline`/`noRecentSales`) nunca geram uma quantidade sugerida
  arbitrária — sempre `0`, com o motivo explícito.
- Alteração de parâmetros (`replenishmentSettings/default`) nunca altera retroativamente uma sugestão
  já gerada: cada documento carrega seu próprio `parametersSnapshot` congelado no momento do cálculo.
- Reexecução no mesmo período é idempotente: o id do documento (`{warehouseId}_{variantId}_{periodEnd}`)
  é determinístico, e um status já decidido (`accepted`/`adjusted`/`discarded`,
  `FROZEN_REPLENISHMENT_STATUSES`) nunca é sobrescrito por uma nova execução.
- `decideReplenishmentSuggestion` grava auditoria append-only (`decisionAudit`) com ação, autor e
  timestamp, além de espelhar a última decisão em `decidedBy`/`decidedByName`/`decidedAt`.

## Regras Firebase implementadas

`firestore.rules`: três coleções novas
(`organizations/{organizationId}/{replenishmentSuggestions,replenishmentSettings,replenishmentDraftOrders}/{docId}`),
todas com `allow get, list: if hasCapability(organizationId, 'report.viewSensitive') ||
hasCapability(organizationId, 'inventory.adjust')` e `allow create, update, delete: if false` — mesmo
padrão exato já usado por `stockAlerts`/`stockTurnoverMetrics` (mesma classe de dado sensível
server-computado). Nenhuma escrita client-side é permitida em nenhuma das três; só a Admin SDK
(`calculateReplenishmentSuggestions`/`decideReplenishmentSuggestion`) escreve.

RBAC no callable: `decideReplenishmentSuggestion` re-valida a Membership real do chamador
(`loadActiveMembership`, nunca confia no que o client envia) e exige `OWNER`/`ADMIN`/`SALES_MANAGER`
(`ROLES_ALLOWED_TO_DECIDE`, mesmo allowlist de `recomputeStockTurnoverMetrics`).

## Analytics implementado

Dois eventos novos em `lib/core/analytics/analytics_events.dart`:
- `replenishmentSuggestionsViewed` — documentado para ser logado quando a tela é aberta (o cubit não
  chama `logEvent` diretamente na versão atual da página; ver "Pendências").
- `replenishmentSuggestionDecided` — logado por `DecideReplenishmentSuggestionUseCase` a cada
  aceite/ajuste/descarte bem-sucedido, com `organization_id`/`suggestion_id`/`action`/`final_quantity`.

## Crashlytics implementado

Nenhum código novo de captura de exceção não tratada foi adicionado — os fluxos seguem o padrão já
estabelecido: exceções de rede/servidor são convertidas em `AppFailure`/`Failure` e nunca deixadas
escapar como exceção não tratada; o `CrashReporter` global já configurado em `bootstrap.dart` continua
cobrindo qualquer erro não previsto nesta feature, sem necessidade de instrumentação adicional.

## Impacto offline

Nenhum. Sugestões de reposição são um fluxo de gestão server-computado, consumido apenas quando
online (mesmo padrão de `StockAlertsPage`/dashboards do EPIC-17) — não há Outbox nem cache Drift para
esta feature, deliberadamente: assim como um dashboard, reabrir a tela após o app fechar simplesmente
recarrega ao voltar a ficar online. Nenhuma decisão comercial de campo (pedido, preço, estoque)
depende desta tela funcionar offline.

## Impacto multi-tenant

Toda leitura é escopada por `organizationId` via `FirestoreCollectionDataSource`
(`organizations/{organizationId}/...`), nunca confiando em filtro só do client — `firestore.rules`
reforça o isolamento por tenant independentemente. `decideReplenishmentSuggestion` reconfirma
`data.organizationId === organizationId` dentro da própria transação antes de decidir, prevenindo um
`suggestionId` de uma organização ser decidido sob o escopo de outra. Testes de isolamento
multi-tenant no cálculo agendado (`calculate-replenishment-suggestions.test.ts`) confirmam que
saldos/sugestões nunca vazam entre organizações.

## Testes criados

TypeScript (`functions/`, **executados neste ambiente, sem emulador**):
- `replenishment-calculation-shared.test.ts` — 13 testes: cobertura completa/parcial/sem histórico,
  saldo zero, saldo negativo (nunca inflado), sazonalidade, quantidade nunca negativa,
  `sellableQuantityOf`/`asReplenishmentVariantStockBalance` (payload malformado → `null`, nunca throw).
- `calculate-replenishment-suggestions.test.ts` — 6 testes com `ReplenishmentPersistence` fake em
  memória: geração correta, `insufficientData` sem histórico, idempotência de reexecução no mesmo
  período, nunca sobrescreve status decidido, retorno antecipado sem saldo, isolamento de falha por
  organização, isolamento multi-tenant.
- `decide-replenishment-suggestion.test.ts` — 5 testes contra o Firebase Emulator Suite (accept/
  adjust/discard, RBAC nega SALES_REP, nunca decide duas vezes) — **não executável neste ambiente**
  (sem Java, mesma limitação pré-existente já documentada em TASK-094/TASK-133).

Dart (`test/features/replenishment/`, **executados neste ambiente**):
- `domain/value_objects/replenishment_suggestion_status_test.dart` — parse de todo status conhecido,
  `ArgumentError` para desconhecido, `isDecided`.
- `domain/usecases/list_replenishment_suggestions_use_case_test.dart` — sucesso, RBAC negado, limite
  inválido sem chamar o repositório nem a Membership.
- `domain/usecases/decide_replenishment_suggestion_use_case_test.dart` — accept/adjust com sucesso e
  analytics, `adjust` sem quantidade falha sem chamar o repositório, RBAC negado, falha do servidor
  propagada sem logar analytics.
- `data/dtos/replenishment_suggestion_dto_test.dart` — payload válido (decidido/não decidido/
  insufficientData), campo obrigatório ausente lança `ValidationException`, `parametersSnapshot`
  malformado lança `ValidationException`, round-trip `toJson`→`fromJson`.
- `data/mappers/replenishment_suggestion_mapper_test.dart` — mapeamento completo DTO→entidade
  (decidida e insufficientData).

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx jest replenishment-calculation-shared calculate-replenishment-suggestions
cd functions && npx eslint src test
cd functions && npm run build
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/features/replenishment
flutter analyze lib/app/bootstrap.dart lib/core/navigation/app_router.dart lib/core/navigation/app_route_paths.dart
flutter analyze
flutter test test/features/replenishment
flutter test
dart format --set-exit-if-changed lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart lib/core/navigation/app_route_paths.dart lib/core/navigation/app_router.dart lib/features/replenishment test/features/replenishment
```

## Resultado do formatter

`dart format --set-exit-if-changed` limpo (0 arquivos alterados) em todos os arquivos Dart tocados por
esta task, após reformatar e confirmar. **Nota:** a primeira execução de `dart format` no diretório
`lib` inteiro também reformatou dois arquivos pré-existentes fora do escopo desta task
(`locale_settings_page.dart`, `cart_share_sheet.dart`) — essas mudanças foram revertidas
(`git checkout --`) antes do commit, mantendo o diff restrito ao escopo da TASK-184.

## Resultado do analyzer

`flutter analyze` (projeto inteiro): **17 issues, todas pré-existentes ou do mesmo padrão já aceito no
restante do código** — 5 `info` de `use_null_aware_elements` (2 delas nos arquivos novos desta task,
mesmo padrão `if (x != null) 'key': x` já usado em `catalog`/`crm`/`customer_import`/`product_import`),
6 `info` de `deprecated_member_use` em `report_builder_page.dart` (não tocado por esta task) e 6 `info`
em testes de `dashboards` (não tocados). **Nenhum erro.**

## Resultado dos testes

- `npx jest replenishment-calculation-shared calculate-replenishment-suggestions` (functions): **19/19
  passando.**
- `flutter test test/features/replenishment`: **19/19 passando.**
- `flutter test` (suíte completa do projeto): **3170/3171 passando** — a única falha
  (`test/app/bootstrap_test.dart`, "bootstrap initializes Firebase exactly once and renders
  VestiProApp") é **pré-existente e não relacionada a esta task**: confirmado rodando a mesma suíte via
  `git stash` sobre o `HEAD` original (antes de qualquer mudança desta task) — falha idêntica
  (`PushDeviceMapper is not registered inside GetIt` / assertion do
  `firebase_crashlytics_platform_interface`), reproduzível sem nenhuma das mudanças desta task.
- `test/core/analytics/analytics_events_test.dart` precisou ser atualizado (lista de eventos esperados)
  para incluir os dois eventos novos — já corrigido e passando.

## Decisões técnicas

**(a) `ReplenishmentDraftOrder` é um agregado novo, não reaproveita `Order`/`OrderItem`.** Um `Order`
real (`lib/features/orders/domain/entities/order.dart`) exige `customerId`, `deliveryAddress`,
`billingAddress`, `priceListId` e `paymentTermId` — nenhum desses existe (nem faz sentido) para uma
reposição interna de estoque entre depósito/fábrica: não há cliente, não há endereço de entrega/
cobrança e não há tabela de preço envolvida. Forçar isso em `Order` significaria relaxar campos
obrigatórios de uma entidade que todo o resto do EPIC-13 depende serem sempre presentes, ou preencher
valores fictícios — ambos piores que um agregado pequeno e explícito
(`organizations/{orgId}/replenishmentDraftOrders/{id}`, campos: `id, organizationId, companyId,
warehouseId, items, sourceSuggestionIds, originType: 'replenishment', status: 'draft',
createdAt/createdBy/updatedAt/updatedBy, version`). Confirmar/transformar esse rascunho em um pedido de
compra real de fato é explicitamente fora do escopo desta task.

**(b) Popular `insightStockPositionSnapshots` continua fora de escopo.** A TASK-133 já decidiu
explicitamente (ver sua própria seção "Decisão de escopo") que popular as dez coleções
`insight*Snapshots` — incluindo `insightStockPositionSnapshots`, que `ReplenishmentSuggestionInsightRule`
(TASK-128) já espera como entrada — é um follow-up dedicado, não algo a ser "consertado de passagem"
por outra task. Esta task (TASK-184) resistiu deliberadamente à tentação de misturar isso: o motor de
cálculo aqui é um mecanismo novo e mais completo (com workflow de decisão humana), não uma correção do
gap upstream do insight. `replenishment-calculation-shared.ts` documenta, em comentário, que uma futura
task de população dos snapshots pode (e deve) reaproveitar `calculateReplenishmentSuggestion` em vez de
reimplementar a fórmula pela terceira vez.

**(c) Suposições sobre nomes de coleções Firestore confirmadas lendo o código:**
- `organizations/{orgId}/inventory/{id}` é o saldo por variante (TASK-090) — o nome real da coleção
  Firestore é `inventory`, não `variantStockBalances`, confirmado lendo
  `firestore_variant_stock_balance_data_source.dart`.
- `FutureStockEntry` (TASK-091, estoque futuro) **não tem coleção Firestore própria hoje** — é derivado
  de `ProductVariant.manualAvailabilityStatus`/`manualFutureAvailableAt`/`manualAvailableQuantity`, e a
  DI de produção usa `SharedPreferencesProductVariantRepository` (confirmado em
  `lib/app/injection.config.dart`), ou seja, `ProductVariant` é uma entidade local-only/não
  sincronizada hoje. Por isso o Cloud Function trata `futureStockQuantity` como `0` sempre, com essa
  limitação documentada explicitamente em código (`replenishment-calculation-shared.ts`) e aqui.
- O cálculo de giro por variante (`stock-turnover-shared.ts`, escopo `'variant'`) agrega
  `stockTurnoverDailyFacts` **sem separar por depósito** (mesmo comportamento de
  `recompute-stock-turnover-metrics.ts`'s `buildSnapshotsForScope`) — por isso a sugestão usa giro
  organização-wide da variante, mas saldo atual (`currentSellableQuantity`) por depósito específico.

**(d) Janela de giro (12 semanas/84 dias) e cadência semanal são constantes de código, não
configuráveis por organização** (`DEFAULT_TURNOVER_LOOKBACK_DAYS`, `schedule: 'every monday 04:00'`) —
apenas `coverageTargetDays`/`safetyStockQuantity`/`seasonalityFactor` são configuráveis
(`replenishmentSettings/default`), conforme literalmente pedido pelo escopo técnico da task.

**(e) RBAC da UI usa `Capability.reportViewSensitive`** (mesmo capability de `StockAlertsPage`) em vez
de criar uma capability nova dedicada — decisão deliberada para não expandir o enum
`Capability`/`RolePermissionMatrix` (e todo o raio de mudança que isso implicaria em testes/docs de
RBAC existentes) para uma única tela nova. A UI só melhora UX (mostra/esconde a tela); a autorização
real e definitiva de quem pode efetivamente decidir uma sugestão continua sendo
`decideReplenishmentSuggestion`'s próprio `ROLES_ALLOWED_TO_DECIDE` (OWNER/ADMIN/SALES_MANAGER),
re-validado a partir da Membership real do chamador — nunca do client.

**(f) Rota `/inventory/replenishment` ganhou o prefixo `/org/:orgId/companies/:companyId/`** (virando
`ReplenishmentSuggestionsRoute.pathPattern = '/org/:orgId/companies/:companyId/inventory/replenishment'`)
em vez do path literal usado pela TASK-128 (`/inventory/replenishment?productId=...`), que nunca foi um
path Firestore/GoRouter válido isolado (não carrega organização/empresa) — seguindo a convenção
`/org/:orgId/...` que toda outra rota autenticada do app já usa. O deep link do insight continua
funcionando: `_navigateForInsightAction` (bootstrap.dart) resolve `InsightActionType.notifyReplenishment`
para esta rota, carregando `productId`/`variantId` como query parameters.

## Riscos conhecidos

- Testes de Firestore Rules (`firestore-tests/firestore.rules.test.js`) e o teste de emulador de
  `decideReplenishmentSuggestion` não puderam ser executados neste ambiente por falta de Java
  (`firebase emulators:exec`) — mesma limitação pré-existente já aceita pelo restante do repositório
  (TASK-094/TASK-133). Devem rodar em CI/ambiente com o Firebase Emulator Suite antes de qualquer
  deploy real.
- `futureStockQuantity` é sempre `0` no cálculo server-side, já que não existe fonte Firestore para o
  estoque futuro hoje (ver decisão "c" acima) — a quantidade sugerida pode estar levemente superestimada
  para variantes com estoque futuro manualmente registrado mas não sincronizado.
- A janela de giro fixa de 84 dias pode não ser ideal para toda categoria de produto (moda tem
  sazonalidade forte); `seasonalityFactor` é o único mecanismo de ajuste disponível hoje.
- `ReplenishmentSuggestionsPage` não filtra/destaca automaticamente por `productId`/`variantId` quando
  aberta via deep link do insight (`notifyReplenishment`) — apenas os query parameters chegam à rota;
  a tela ainda não os consome para pré-filtrar/realçar a linha correspondente (só o filtro manual por
  `warehouseId` existe hoje). Ver "Pendências".
- Nenhum evento `replenishmentSuggestionsViewed` é de fato disparado ainda (a constante existe, mas
  nenhum código chama `logEvent` com ela) — ver "Pendências".

## Pendências

- Disparar `AnalyticsEvents.replenishmentSuggestionsViewed` quando `ReplenishmentSuggestionsPage`
  carrega (hoje só `replenishmentSuggestionDecided` está de fato instrumentado).
- Fazer `ReplenishmentSuggestionsPage`/`ReplenishmentSuggestionsBloc` consumirem `productId`/`variantId`
  da query string para destacar/pré-filtrar a sugestão relevante quando abertos via deep link do
  insight `notifyReplenishment`.
- Adicionar uma fonte Firestore real de estoque futuro (TASK-091 hoje é local-only) para que
  `futureStockQuantity` deixe de ser sempre `0` no cálculo server-side.
- Popular `insightStockPositionSnapshots` continua uma task própria e dedicada (fora de escopo, ver
  decisão "b").
- Rodar os testes de Firebase Emulator Suite (Cloud Functions e Security Rules) escritos nesta task em
  um ambiente com Java/Emulator Suite disponível, antes de qualquer deploy real.
- Não existe hoje nenhuma tela/fluxo que confirme/transforme um `ReplenishmentDraftOrder` em um pedido
  de compra real — este agregado só é gerado e lido, nunca "processado" — decisão consciente de escopo,
  não um bug.

## Evidências

- `cd functions && npx tsc --noEmit` → sem erros.
- `cd functions && npx jest replenishment-calculation-shared calculate-replenishment-suggestions` →
  `Tests: 19 passed, 19 total`.
- `cd functions && npx eslint src test` → sem erros/warnings.
- `cd functions && npm run build` → sem erros.
- `dart run build_runner build --delete-conflicting-outputs` → `injection.config.dart` regenerado,
  registrando `ReplenishmentSuggestionMapper`, `FirestoreReplenishmentSuggestionDataSource`,
  `ReplenishmentRepositoryImpl`, `ListReplenishmentSuggestionsUseCase`,
  `DecideReplenishmentSuggestionUseCase`, `ReplenishmentSuggestionsBloc` (confirmado via `grep
  Replenishment lib/app/injection.config.dart`).
- `flutter test test/features/replenishment` → `+19: All tests passed!`.
- `flutter test` (suíte completa) → `+3170 -1`, única falha confirmada pré-existente via `git stash`.
- `flutter analyze` (projeto inteiro) → `17 issues found`, todas `info`, nenhum `error`.

## Commit

`feat(inventory): implementa sugestao automatica de reposicao (TASK-184)`

## Push

Não realizado nesta rodada — sem autorização explícita para push nesta conversa (conforme
`AGENTS.md`: "Nunca faça push sem autorização explícita nesta conversa").

## Hash do commit

Ver seção "Hash do commit" da resposta final ao orquestrador (preenchido após o commit real).

## Branch

`main`
