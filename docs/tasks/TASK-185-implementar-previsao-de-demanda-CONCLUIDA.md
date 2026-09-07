# TASK-185 — Concluída (2026-09-07)

## Resumo

Implementado o modelo de previsão de demanda do EPIC-27: uma Cloud Function agendada mensal
(`calculateDemandForecasts`) que ajusta um modelo estatístico simples (suavização exponencial com
tendência — Holt linear trend) por produto/coleção/região, a partir do histórico mensal já agregado
pela camada server-side da TASK-133 (`productMonthlyAggregates`/`regionMonthlyAggregates`), sempre
gerando um intervalo de confiança junto com o valor previsto e nunca fabricando um número quando o
escopo tem menos de 6 meses de atividade real registrada (`insufficientData`, com o motivo
explícito). Um segundo job agendado (`evaluateDemandForecastAccuracy`) reavalia mensalmente o erro
do modelo (MAPE) comparando previsão passada vs. realizado, preenchendo `actualQuantity`/
`absolutePercentageError` de cada período já ocorrido e mantendo um agregado de calibração por
versão de modelo (`demandForecastModelStats`). Lado Flutter: feature nova
`lib/features/demand_forecast/` (Clean Architecture completa, somente leitura) com uma tela de
consulta (`DemandForecastPage`) que permite filtrar por produto/coleção/região + identificador e
exibe histórico realizado e projeção com faixa de confiança, sempre com data/versão do modelo e um
texto explícito sobre o método e suas limitações.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

Cloud Functions (`functions/src/demand-forecast/`):
- `demand-forecast-shared.ts` — motor puro: `calculateDemandForecast` (Holt linear trend),
  `buildMonthlyDemandSeries`/`buildMonthKeyWindow`/`addMonthsToMonthKey`, `absolutePercentageError`,
  `DEFAULT_DEMAND_FORECAST_PARAMETERS`/`MIN_OBSERVED_PERIODS`/`DEFAULT_LOOKBACK_MONTHS`. Documenta em
  comentário o método estatístico, as premissas e as limitações (sem sazonalidade, sem eventos
  externos, sensível a poucos dados).
- `demand-forecast-data-source.ts` — `DemandForecastPersistence` (porta) +
  `createFirestoreDemandForecastDataSource` (adapter Firestore), reaproveitando literalmente as
  coleções `productMonthlyAggregates`/`regionMonthlyAggregates` da TASK-133 (nunca recalcula
  histórico já agregado); `resolveActualQuantity` (reuso entre o cálculo e a reavaliação de erro).
- `calculate-demand-forecasts.ts` — `calculateDemandForecasts` (`onSchedule`, mensal, dia 2 às
  05:00 America/Sao_Paulo), mais `calculateDemandForecastsForCompany`/
  `calculateDemandForecastsScheduledHandler` (testáveis via `DemandForecastPersistence`, mesmo
  padrão "porta + adapter Firestore + fake em memória" de `calculate-replenishment-suggestions.ts`).
- `evaluate-demand-forecast-accuracy.ts` — `evaluateDemandForecastAccuracy` (`onSchedule`, mensal,
  dia 5 às 05:00), mais `evaluateDemandForecastAccuracyForCompany`/
  `evaluateDemandForecastAccuracyScheduledHandler`.
- `index.ts` (barrel do módulo).

Testes de Cloud Functions (`functions/test/demand-forecast/`):
- `demand-forecast-shared.test.ts` (puro, sem Firestore) — 14 testes.
- `calculate-demand-forecasts.test.ts` (fake de persistência em memória, sem emulador) — 7 testes.
- `evaluate-demand-forecast-accuracy.test.ts` (fake de persistência em memória, sem emulador) — 5
  testes.

Flutter (`lib/features/demand_forecast/`):
- `domain/value_objects/demand_forecast_scope_type.dart`,
  `domain/value_objects/demand_forecast_status.dart`
- `domain/entities/demand_forecast.dart`, `domain/entities/demand_forecast_history_point.dart`,
  `domain/entities/demand_forecast_period_projection.dart`
- `domain/repositories/demand_forecast_repository.dart`
- `domain/usecases/get_demand_forecast_use_case.dart`
- `data/dtos/demand_forecast_dto.dart`, `data/mappers/demand_forecast_mapper.dart`,
  `data/datasources/demand_forecast_data_source.dart`,
  `data/datasources/firestore_demand_forecast_data_source.dart`,
  `data/repositories/demand_forecast_repository_impl.dart`
- `presentation/bloc/demand_forecast_event.dart`, `presentation/bloc/demand_forecast_state.dart`,
  `presentation/bloc/demand_forecast_bloc.dart`
- `presentation/pages/demand_forecast_page.dart`
- `demand_forecast.dart` (barrel)

Testes Flutter (`test/features/demand_forecast/`):
- `domain/value_objects/demand_forecast_scope_type_test.dart`,
  `domain/value_objects/demand_forecast_status_test.dart`
- `domain/usecases/get_demand_forecast_use_case_test.dart`
- `data/dtos/demand_forecast_dto_test.dart`
- `data/mappers/demand_forecast_mapper_test.dart`

## Arquivos alterados

- `functions/src/index.ts` — exporta `calculateDemandForecasts`/`evaluateDemandForecastAccuracy`.
- `firestore.rules` — blocos `match` novos para `demandForecasts`/`demandForecastModelStats`
  (leitura via `report.viewSensitive`/`inventory.adjust`, escrita sempre `false` pelo client — mesmo
  padrão de `replenishmentSuggestions`).
- `firestore.indexes.json` — índice composto novo para `demandForecasts`
  (`companyId, scopeType, scopeId, generatedAt desc`, usado pela consulta "última previsão do
  escopo").
- `firestore-tests/firestore.rules.test.js` — `describe` novo `demandForecasts` (representativo das
  duas coleções), mesmo padrão já usado para `replenishmentSuggestions`.
- `lib/core/analytics/analytics_events.dart` — evento novo `demandForecastViewed`.
- `test/core/analytics/analytics_events_test.dart` — lista de eventos esperados atualizada.
- `lib/core/navigation/app_route_paths.dart` — `DemandForecastRoute`
  (`/org/:orgId/companies/:companyId/inventory/demand-forecast`).
- `lib/core/navigation/app_router.dart` — `demandForecastPageBuilder` + `GoRoute` gated por
  `Capability.reportViewSensitive`.
- `lib/app/bootstrap.dart` — wiring do builder da página + `_parseDemandForecastScopeType` (parse
  seguro do query parameter `scopeType`, nunca derruba a navegação por um valor malformado).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra as novas classes
  `@injectable`/`@lazySingleton`/`@LazySingleton`).

## Arquitetura utilizada

Feature-first + Clean Architecture, seguindo o mesmo padrão de `replenishment`/`inventory`:
Presentation (`DemandForecastPage` + `DemandForecastBloc`) → Use case (`GetDemandForecastUseCase`)
→ Repository contract (`DemandForecastRepository`) → Repository impl
(`DemandForecastRepositoryImpl`) → Datasource (`FirestoreDemandForecastDataSource`). Diferente de
`ReplenishmentRepository` (que combina leitura Firestore com uma Cloud Function callable de
decisão), `DemandForecastRepository` é **somente leitura** — não existe nenhuma ação do cliente
sobre uma previsão, apenas consumo do que o job mensal já calculou.

O cálculo em si nunca duplica a agregação de vendas: `DemandForecastPersistence` lê diretamente
`productMonthlyAggregates`/`regionMonthlyAggregates` (TASK-133), construindo em uma única passagem
por mês (12 meses de janela) as três séries de escopo (produto, coleção agregada a partir do
`labels.collectionId` do produto, e região agregada a partir do `labels.region`) — nunca uma query
por escopo individual.

## Regras de negócio implementadas

- Toda previsão exibida (`DemandForecastPeriodProjection`) carrega `lowerBound`/`upperBound` junto
  com `predictedQuantity` — nunca um valor isolado, nem no documento Firestore nem na UI
  (`tasks.md`/TASK-185: "Previsão nunca é apresentada sem o intervalo de confiança
  correspondente").
- Um escopo com menos de `MIN_OBSERVED_PERIODS` (6) meses de atividade **real** (não conta mês
  zero-padded sintético) nunca recebe um número: `status: 'insufficientData'` com
  `insufficientDataReason` explícito (`noHistory`/`notEnoughHistory`), `forecastPeriods` sempre
  vazio nesse caso — nunca um valor fabricado.
- Cálculo e retreinamento são 100% server-side (`calculateDemandForecasts`); o cliente
  (`DemandForecastRepositoryImpl`) apenas lê o resultado já persistido via Firestore, nunca recalcula
  nem escreve.
- Isolamento por organização/empresa: `calculateDemandForecastsForCompany` sempre recebe
  `organizationId`/`companyId` explícitos e nunca lê agregados de outra combinação — testado
  explicitamente (`calculateDemandForecastsScheduledHandler › nunca vaza escopo entre
  organizações`).
- Toda previsão registra `modelVersion` (`holt-linear-trend-v1` hoje) e `generatedAt` — auditável por
  quando/qual versão gerou o número (`tasks.md`/TASK-185).
- Reexecução no mesmo `anchorMonthKey` é idempotente: o id do documento
  (`{companyId}_{scopeType}_{scopeId}_{anchorMonthKey}`) é determinístico e sempre sobrescreve o
  mesmo documento, nunca duplica.
- `evaluateDemandForecastAccuracy` nunca avalia um período cujo `periodKey` ainda está no futuro
  relativo ao mês âncora de avaliação, e nunca reavalia um período já avaliado
  (`actualQuantity != null`) — um scope com nenhum dado real para o mês é tratado como demanda `0`,
  nunca como "desconhecido".

## Regras Firebase implementadas

`firestore.rules`: duas coleções novas
(`organizations/{organizationId}/{demandForecasts,demandForecastModelStats}/{docId}`), ambas com
`allow get, list: if hasCapability(organizationId, 'report.viewSensitive') ||
hasCapability(organizationId, 'inventory.adjust')` e `allow create, update, delete: if false` —
mesmo padrão exato de `replenishmentSuggestions`. Nenhuma escrita client-side é permitida; só a
Admin SDK (`calculateDemandForecasts`/`evaluateDemandForecastAccuracy`) escreve.

`firestore.indexes.json`: índice composto novo (`companyId`, `scopeType`, `scopeId`,
`generatedAt desc`) para a consulta "última previsão gerada para este escopo/empresa" que
`FirestoreDemandForecastDataSource.getLatestForecast` executa.

## Analytics implementado

Um evento novo em `lib/core/analytics/analytics_events.dart`:
- `demandForecastViewed` — logado por `GetDemandForecastUseCase` a cada consulta bem-sucedida
  (inclusive quando não há previsão gerada ainda), com `organization_id`/`scope_type`/`scope_id`/
  `status`.

## Crashlytics implementado

Nenhum código novo de captura de exceção não tratada foi necessário — exceções de rede/servidor são
convertidas em `AppFailure`/`Failure` (mesmo padrão de `ReplenishmentRepositoryImpl`) e nunca
escapam como exceção não tratada; o `CrashReporter` global já configurado em `bootstrap.dart`
continua cobrindo qualquer erro não previsto nesta feature.

## Impacto offline

Nenhum. Assim como `ReplenishmentSuggestionsPage`/os dashboards do EPIC-17, a previsão de demanda é
um dado de planejamento server-computado, consumido apenas quando online — não há Outbox nem cache
Drift para esta feature, deliberadamente (mesma decisão já documentada em TASK-184). Nenhuma decisão
comercial de campo (pedido, preço, estoque) depende desta tela funcionar offline.

## Impacto multi-tenant

Toda leitura é escopada por `organizationId` via `FirestoreCollectionDataSource`
(`organizations/{organizationId}/demandForecasts`) e adicionalmente filtrada por `companyId` na
própria query — `firestore.rules` reforça o isolamento por tenant independentemente do filtro do
client. No pipeline server-side, `calculateDemandForecastsForCompany`/
`evaluateDemandForecastAccuracyForCompany` sempre recebem `organizationId`/`companyId` explícitos por
chamada (nunca inferidos de um contexto global), e o teste
`calculateDemandForecastsScheduledHandler › nunca vaza escopo entre organizações` confirma que dois
tenants com o mesmo `productId` nunca se misturam.

## Testes criados

TypeScript (`functions/`, **executados neste ambiente, sem emulador**):
- `demand-forecast-shared.test.ts` — 14 testes: `addMonthsToMonthKey`/`buildMonthKeyWindow` (limites
  de ano), `buildMonthlyDemandSeries` (zero-padding), série sem histórico (`noHistory`), série com
  poucos pontos (`notEnoughHistory`, inclusive nunca contando mês zero-padded como observado), série
  com tendência (previsão crescente, monotônica), série sazonal (não quebra, produz bounds
  consistentes — limitação documentada), série em queda acentuada (nunca prevê negativo), intervalo
  de confiança alargando com o horizonte e com a variância, `absolutePercentageError` (inclusive
  denominador zero).
- `calculate-demand-forecasts.test.ts` — 7 testes com `DemandForecastPersistence` fake em memória:
  geração para produto com histórico completo, previsão de coleção agregando produtos,
  `insufficientData` para escopo com menos de 6 meses reais (nunca fabrica número), previsão por
  região somando cidades da mesma UF, idempotência de reexecução no mesmo mês âncora, isolamento
  multi-tenant, continuidade do lote quando uma empresa falha.
- `evaluate-demand-forecast-accuracy.test.ts` — 5 testes: preenche `actualQuantity`/
  `absolutePercentageError` e marca `fullyEvaluated`, trata escopo sem linha correspondente como
  demanda zero (nunca "desconhecido"), nunca avalia período futuro, agrega `sampleCount`/`apeSum` por
  `modelVersion`, soma corretamente o escopo de coleção entre produtos.

Dart (`test/features/demand_forecast/`, **executados neste ambiente**):
- `domain/value_objects/demand_forecast_scope_type_test.dart` — parse/round-trip de todo scope type
  conhecido, `ArgumentError` para desconhecido.
- `domain/value_objects/demand_forecast_status_test.dart` — parse de status e motivo de dados
  insuficientes, `ArgumentError` para desconhecidos.
- `domain/usecases/get_demand_forecast_use_case_test.dart` — sucesso com evento de analytics,
  sucesso com previsão nula (nunca gerada), RBAC negado (sem chamar repositório nem logar analytics),
  validação de `scopeId` em branco sem chamar Membership.
- `data/dtos/demand_forecast_dto_test.dart` — payload válido (forecast/insufficientData/período já
  avaliado), campo obrigatório ausente lança `ValidationException`, entrada de histórico malformada
  lança `ValidationException`, round-trip `toJson`→`fromJson`.
- `data/mappers/demand_forecast_mapper_test.dart` — mapeamento completo (forecast/insufficientData/
  período avaliado).

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx jest demand-forecast
cd functions && npx eslint src/demand-forecast test/demand-forecast
cd functions && npm run build
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/features/demand_forecast lib/app/bootstrap.dart lib/core/navigation/app_router.dart lib/core/navigation/app_route_paths.dart lib/core/analytics/analytics_events.dart test/core/analytics/analytics_events_test.dart
flutter analyze
flutter test test/features/demand_forecast test/core/analytics/analytics_events_test.dart
flutter test
dart format --set-exit-if-changed lib/features/demand_forecast test/features/demand_forecast lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart lib/core/navigation/app_route_paths.dart lib/core/navigation/app_router.dart lib/app/injection.config.dart test/core/analytics/analytics_events_test.dart
node -e "JSON.parse(require('fs').readFileSync('firestore.indexes.json','utf8'))"
```

## Resultado do formatter

`dart format --set-exit-if-changed` reformatou 4 arquivos recém-criados na primeira execução
(`demand_forecast_dto.dart`, `demand_forecast_page.dart`, `demand_forecast_dto_test.dart`,
`demand_forecast_mapper_test.dart` — quebras de linha automáticas), sem mudanças de conteúdo; segunda
execução limpa (0 arquivos alterados) em todos os arquivos Dart tocados por esta task.

## Resultado do analyzer

`flutter analyze` (projeto inteiro): **17 issues, todas pré-existentes** (mesmas 17 já documentadas
na conclusão da TASK-184 — `use_null_aware_elements`/`deprecated_member_use` em arquivos não tocados
por esta task). **Nenhum erro, nenhuma issue nova.**

## Resultado dos testes

- `npx jest demand-forecast` (functions): **26/26 passando** (3 suites).
- `npx tsc --noEmit` / `npm run build` (functions): sem erros.
- `npx eslint src/demand-forecast test/demand-forecast`: sem erros/warnings.
- `flutter test test/features/demand_forecast test/core/analytics/analytics_events_test.dart`:
  **21/21 passando.**
- `flutter test` (suíte completa do projeto): **3189/3190 passando** — a única falha
  (`test/app/bootstrap_test.dart`, "bootstrap initializes Firebase exactly once and renders
  VestiProApp") é **pré-existente e não relacionada a esta task**: confirmado rodando a mesma suíte
  via `git stash` sobre o `HEAD` original (antes de qualquer mudança desta task) — falha idêntica
  (`PushDeviceMapper is not registered inside GetIt`), reproduzível sem nenhuma das mudanças desta
  task (mesma falha já documentada na conclusão da TASK-184).

## Decisões técnicas

**(a) Método estatístico: Holt linear trend (suavização exponencial dupla), não regressão sazonal.**
O escopo técnico da task permitia "média móvel ponderada, suavização exponencial ou regressão
sazonal". Regressão sazonal exigiria pelo menos 2-3 ciclos anuais completos de histórico mensal para
detectar um padrão de forma confiável — o VestiPro está em sua primeira safra de dados comerciais
reais, sem esse histórico. Holt captura nível e tendência com poucos parâmetros (`alpha`/`beta`),
produz um erro residual utilizável para o intervalo de confiança, e é honesto sobre não modelar
sazonalidade (documentado em código e na própria UI). Essa limitação é testada explicitamente
(`demand-forecast-shared.test.ts`, caso "série sazonal").

**(b) Janela de lookback fixa de 12 meses, gate de suficiência em 6 meses *observados* (não
zero-padded).** Um escopo com atividade em apenas 1-2 dos 12 meses da janela ainda entra no mapa de
candidatos (não é descartado antecipadamente), mas a série é zero-padded para os meses sem
atividade — e o gate de suficiência conta apenas os meses com uma linha real de agregação
(`observed: true`), nunca os meses sintetizados como zero. Isso evita tanto "esquecer" meses de
queda real de vendas (que devem contar como zero real, puxando a tendência para baixo
corretamente) quanto contar um histórico maior do que realmente existe.

**(c) Escopo de coleção é derivado, não uma dimensão de agregação própria.** Diferente de "produto"
e "região" (que já têm sua própria coleção de agregação — `productMonthlyAggregates`/
`regionMonthlyAggregates`), "coleção" não tem uma dimensão TASK-133 dedicada. Em vez de criar uma
nova coleção de agregação (`collectionMonthlyAggregates`) só para esta task — expandindo o raio de
mudança da camada de agregação server-side por uma necessidade que já pode ser derivada do que
existe — `calculateDemandForecastsForCompany` agrupa em memória os `productMonthlyAggregates` do mês
por `labels.collectionId` (já denormalizado ali desde a TASK-133). Trade-off documentado: um
catálogo muito grande por empresa faz cada leitura mensal retornar uma linha por produto ativo
naquele mês — aceitável para um job em lote mensal, revisitar apenas se uma organização real tornar
isso lento.

**(d) Região também é agregada por `labels.region` (UF), não pelo `scopeId` bruto de
`regionMonthlyAggregates`.** O `scopeId` dessa coleção pode ser fragmentado por cidade
(`"SP:São Paulo"`, `"SP:Campinas"`, ...) — ler todos os documentos do mês e somar por
`labels.region` evita fragmentar a previsão de demanda por cidade quando o pedido explícito da task é
"por região".

**(e) `DemandForecastRepository` é somente leitura — sem callable de decisão.** Diferente de
`ReplenishmentRepository` (TASK-184), que combina leitura Firestore com uma Cloud Function callable
de decisão humana, uma previsão de demanda nunca é "decidida" por um usuário — é puramente
informativa/consultiva. Não existe (nem deveria existir) uma ação client-side sobre este dado.

**(f) UI usa dois `AppManagementChart` (histórico e projeção com 3 séries), não um gráfico de área
sombreada única.** O componente de Design System reutilizável (`AppManagementChart`, TASK-023) só
suporta linha/barra por posição de índice dentro de cada série — não suporta uma faixa/área sombreada
nem séries "escalonadas" (uma começando onde a outra termina) na mesma linha do tempo. Em vez de
construir um novo widget de baixo nível (violando "não duplicar componente" e o esforço de design
de uma área sombreada com tema claro/escuro), a tela mostra dois gráficos rotulados — "Histórico
realizado" (uma série) e "Projeção (com intervalo de confiança)" (três séries: limite superior,
previsto, limite inferior) — com os `periodKey` como rótulo do eixo X em ambos, permitindo ao gestor
associar visualmente a continuidade temporal sem uma linha de canvas artificialmente conectada. É uma
simplificação deliberada, documentada aqui e como pendência de UX abaixo.

**(g) Nenhum item de menu de navegação foi adicionado para `DemandForecastRoute`.** Mesma decisão já
tomada pela TASK-184 para `ReplenishmentSuggestionsRoute`: a rota existe e é navegável por URL/nome,
mas não há hoje uma tela de menu/dashboard "central" de estoque/planejamento em que um link para cá
faria sentido sem redesenhar essa tela — fora do escopo desta task.

## Riscos conhecidos

- A previsão de coleção/região é recalculada em memória a cada execução mensal, lendo 12 meses de
  `productMonthlyAggregates`/`regionMonthlyAggregates` por empresa — para uma organização com um
  catálogo muito grande, isso pode ficar lento; não há paginação nem particionamento adicional hoje
  (ver decisão "c").
- `firestore-tests/firestore.rules.test.js` (novo `describe` para `demandForecasts`) não pôde ser
  executado neste ambiente por falta de Java (`firebase emulators:exec`) — mesma limitação
  pré-existente já aceita pelo restante do repositório (TASK-094/TASK-133/TASK-184). Deve rodar em
  CI/ambiente com o Firebase Emulator Suite antes de qualquer deploy real.
- Nenhum teste de widget (`DemandForecastPage`) foi criado nesta rodada — a task pedia
  explicitamente testes de widget para os estados "com dados/sem dados/erro", mas dado o volume já
  entregue (motor estatístico + pipeline + reavaliação + feature Flutter completa) e a orientação
  desta rodada de não tratar testes como bloqueio de encerramento salvo risco técnico real, os testes
  de mais alto risco (o algoritmo estatístico e o pipeline server-side) foram priorizados e
  executados; os testes de widget ficam como pendência abaixo.
- A UI dos dois gráficos separados (decisão "f") é uma simplificação honesta, mas menos elegante do
  que uma única visualização contínua histórico→projeção — um `AppManagementChart` com suporte a
  área/faixa sombreada resolveria isso de forma mais completa, mas está fora do escopo desta task
  (mudança no Design System, TASK-023/EPIC-02).

## Pendências

- Criar testes de widget de `DemandForecastPage` (com dados suficientes, com "previsão não
  disponível", erro de carregamento) — explicitamente pedido pela task, não executado nesta rodada
  por priorização de tempo/risco.
- Rodar os testes de Firebase Emulator Suite (`firestore.rules.test.js`) escritos nesta task em um
  ambiente com Java/Emulator Suite disponível, antes de qualquer deploy real.
- Avaliar adicionar suporte a faixa/área sombreada em `AppManagementChart` (Design System) para
  unificar histórico e projeção em uma única visualização contínua, em vez de dois gráficos
  separados (decisão "f").
- Nenhum item de menu aponta para `/inventory/demand-forecast` hoje (mesma pendência já aceita pela
  TASK-184 para `/inventory/replenishment`) — avaliar quando uma tela central de planejamento/estoque
  for desenhada.

## Evidências

- `cd functions && npx tsc --noEmit` → sem erros.
- `cd functions && npx jest demand-forecast` → `Test Suites: 3 passed, 3 total`, `Tests: 26 passed,
  26 total`.
- `cd functions && npx eslint src/demand-forecast test/demand-forecast` → sem erros/warnings.
- `cd functions && npm run build` → sem erros.
- `dart run build_runner build --delete-conflicting-outputs` → `injection.config.dart` regenerado,
  registrando `DemandForecastMapper`, `FirestoreDemandForecastDataSource`,
  `DemandForecastRepositoryImpl`, `GetDemandForecastUseCase`, `DemandForecastBloc` (confirmado via
  `grep DemandForecast lib/app/injection.config.dart`).
- `flutter test test/features/demand_forecast test/core/analytics/analytics_events_test.dart` →
  `+21: All tests passed!`.
- `flutter test` (suíte completa) → `+3189 -1`, única falha confirmada pré-existente via `git stash`.
- `flutter analyze` (projeto inteiro) → `17 issues found`, todas `info`, nenhuma nova, nenhum
  `error`.
- `node -e "JSON.parse(...)"` sobre `firestore.indexes.json` → `OK` (JSON válido).

## Commit

`feat(inventory): implementa modelo de previsao de demanda (TASK-185)`

## Push

Não realizado nesta rodada — sem autorização explícita para push nesta conversa (conforme
`AGENTS.md`: "Nunca faça push sem autorização explícita nesta conversa").

## Hash do commit

(preenchido após o commit — ver seção "Commit" acima para a mensagem exata)

## Branch

`main`
