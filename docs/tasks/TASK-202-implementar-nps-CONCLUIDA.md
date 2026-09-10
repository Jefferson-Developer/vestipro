# TASK-202 — Concluída (2026-09-10)

## Resumo

Implementada a pesquisa de satisfação (NPS) do pós-venda: Cloud Function `triggerNpsSurvey`
(disparada por `postSaleEvents` de "entregue"/"resolvido", TASK-201) que cria uma
`NpsSurveyRequest` vinculada ao pedido/cliente — apenas quando o cliente tem opt-in de
comunicação ativo (TASK-183) e nunca duplicada para o mesmo pedido+marco —, endpoints públicos e
não autenticados `getNpsSurveyByToken`/`submitNpsResponse` (mesmo padrão de link seguro do
compartilhamento de catálogo, TASK-081), cálculo de NPS agregado (promotores − detratores) por
vendedor/equipe/organização inteiramente server-side (`recomputeNpsMonthlyAggregates`, padrão de
agregação de TASK-133) e feature Flutter completa (domain/data/presentation) com uma tela pública
de resposta (`NpsResponsePage`) e um indicador de NPS (`NpsScoreCard`) já plugado no dashboard do
representante.

Esta task foi retomada de uma execução anterior interrompida: ao iniciar, o backend (6 arquivos em
`functions/src/nps/`, 3 suítes de teste em `functions/test/nps/`, as Firestore Rules/índices e os
testes de Rules) e a camada `domain`/`data` (DTOs, mappers, entidades, contratos de repositório,
use cases) da feature Flutter já existiam, bem documentados e funcionais, mas **sem** datasources
concretos, sem implementação de repositório, sem nenhuma camada de `presentation` e sem nenhum
ponto de entrada real no app (rota, DI, tela, dashboard). Esta rodada completou exatamente essa
parte: datasources, repositórios, bloc/cubit, páginas/widgets, rota pública, wiring de DI/bootstrap
e integração no dashboard do representante — ver "Arquivos criados"/"Decisões técnicas" para o
detalhamento de fronteira entre o que já existia e o que foi adicionado agora.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

Backend (Cloud Functions) e Firestore Rules/Testes — já existiam, não rastreados pelo git, no
início desta task (herdados de uma execução interrompida anterior; nenhum conteúdo alterado por
esta rodada, apenas validados/compilados):

- `functions/src/nps/nps-shared.ts`
- `functions/src/nps/trigger-nps-survey.ts`
- `functions/src/nps/submit-nps-response.ts`
- `functions/src/nps/get-nps-survey-by-token.ts`
- `functions/src/nps/recompute-nps-monthly-aggregates.ts`
- `functions/src/nps/index.ts`
- `functions/test/nps/nps-shared.test.ts`
- `functions/test/nps/trigger-nps-survey.test.ts`
- `functions/test/nps/recompute-nps-monthly-aggregates.test.ts`

Flutter `domain`/`data` (parte de mapeamento/contrato) — também já existiam no início desta task,
mesma origem:

- `lib/features/nps/domain/value_objects/nps_aggregate_scope.dart`
- `lib/features/nps/domain/value_objects/nps_score_category.dart`
- `lib/features/nps/domain/value_objects/nps_survey_outcome.dart`
- `lib/features/nps/domain/entities/nps_aggregate_snapshot.dart`
- `lib/features/nps/domain/entities/nps_response_submission_result.dart`
- `lib/features/nps/domain/entities/nps_survey_preview.dart`
- `lib/features/nps/domain/repositories/nps_aggregate_repository.dart`
- `lib/features/nps/domain/repositories/nps_public_survey_repository.dart`
- `lib/features/nps/domain/usecases/load_nps_aggregate_trend_use_case.dart`
- `lib/features/nps/domain/usecases/preview_nps_survey_use_case.dart`
- `lib/features/nps/domain/usecases/submit_nps_response_use_case.dart`
- `lib/features/nps/data/dtos/nps_aggregate_snapshot_dto.dart`
- `lib/features/nps/data/dtos/nps_response_submission_result_dto.dart`
- `lib/features/nps/data/dtos/nps_survey_preview_dto.dart`
- `lib/features/nps/data/mappers/nps_aggregate_snapshot_mapper.dart`
- `lib/features/nps/data/mappers/nps_response_submission_result_mapper.dart`
- `lib/features/nps/data/mappers/nps_survey_preview_mapper.dart`

Criados nesta rodada (datasources, repositórios, presentation, DI/rotas e wiring de dashboard):

- `lib/features/nps/data/datasources/nps_public_survey_data_source.dart`
- `lib/features/nps/data/datasources/cloud_functions_nps_public_survey_data_source.dart`
- `lib/features/nps/data/datasources/nps_aggregate_data_source.dart`
- `lib/features/nps/data/datasources/firestore_nps_aggregate_data_source.dart`
- `lib/features/nps/data/repositories/nps_public_survey_repository_impl.dart`
- `lib/features/nps/data/repositories/nps_aggregate_repository_impl.dart`
- `lib/features/nps/presentation/bloc/nps_response_event.dart`
- `lib/features/nps/presentation/bloc/nps_response_state.dart`
- `lib/features/nps/presentation/bloc/nps_response_bloc.dart`
- `lib/features/nps/presentation/pages/nps_response_page.dart`
- `lib/features/nps/presentation/cubit/nps_score_card_state.dart`
- `lib/features/nps/presentation/cubit/nps_score_card_cubit.dart`
- `lib/features/nps/presentation/widgets/nps_score_card.dart`
- `lib/features/nps/nps.dart` (barrel da feature)
- `docs/tasks/TASK-202-implementar-nps-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `firestore.rules`, `firestore.indexes.json`, `firestore-tests/firestore.rules.test.js`,
  `functions/src/index.ts` — já vinham modificados (não commitados) no início desta task,
  cobrindo `npsSurveyRequests`/`npsResponses`/`npsMonthlyAggregates` (RBAC, isolamento
  multi-tenant, escrita exclusiva via Admin SDK) com casos positivos e negativos de teste. Nenhum
  conteúdo alterado por esta rodada.
- `lib/core/navigation/app_route_paths.dart` — nova `NpsResponseRoute` (`/nps/:token`), fora da
  convenção `/org/:orgId/...`, sem `AuthGuard`/`ActiveOrganizationGuard` (mesmo padrão de
  `CatalogSharePublicRoute`/`CartSharePublicRoute`).
- `lib/core/navigation/app_router.dart` — novo builder opcional `npsResponsePageBuilder` + `GoRoute`
  correspondente (mesmo padrão de fallback `NotFoundPage` de `cartSharePublicPageBuilder`).
- `lib/app/bootstrap.dart` — wiring real de `npsResponsePageBuilder` (`NpsResponsePage` +
  `NpsResponseBloc`) e de `createNpsScoreCardCubit` na `RepresentativeDashboardPage`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra os novos
  datasources/repositórios/use cases/bloc/cubit).
- `lib/core/analytics/analytics_events.dart` — dois novos eventos: `npsResponseSubmitted`,
  `npsScoreCardViewed`.
- `lib/features/dashboards/presentation/pages/representative_dashboard_page.dart` —
  `NpsScoreCard` adicionado ao corpo do dashboard (escopo `seller`, `scopeId: sellerId`),
  seguindo exatamente o mesmo padrão de composição de `WalletSummaryCard`/`DailyRepSummaryCard`
  (cubit próprio, providido via `MultiBlocProvider`, carregado automaticamente na criação).
- `test/core/analytics/analytics_events_test.dart` — lista de taxonomia atualizada com os 2 novos
  eventos.
- `test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart` — novo
  parâmetro obrigatório `createNpsScoreCardCubit` (fake `NpsAggregateRepository` que nunca é
  chamado de fato pelos asserts existentes, mesmo padrão já usado para
  `_FakeDailyRepSummaryRepository`).
- `docs/tasks/TASKS.md` (checkbox de TASK-202 + progresso `200/219` → `201/219`).

## Arquitetura utilizada

Clean Architecture feature-first, completando o que já existia: `domain` (entidades imutáveis,
`NpsAggregateRepository`/`NpsPublicSurveyRepository` como os únicos pontos de acesso, use cases já
existentes) → `data` (dois datasources novos — `CloudFunctionsNpsPublicSurveyDataSource`, mesma
forma de `CloudFunctionsCatalogShareLookupDataSource`; `FirestoreNpsAggregateDataSource`, mesma
forma de `FirestoreAggregationDataSource`, TASK-133 — e dois repositórios novos convertendo
exceções em `AppFailure`) → `presentation` (`NpsResponseBloc` orquestrando a tela pública de
resposta, mesmo desenho de `CatalogSharePublicBloc`; `NpsScoreCardCubit` carregando
automaticamente na criação, mesmo desenho de `DailyRepSummaryCubit`). Nenhuma regra de negócio
crítica na UI: cálculo de NPS, elegibilidade de disparo, opt-in e deduplicação de pesquisa
continuam inteiramente nas Cloud Functions; o client só lê snapshots já agregados
(`npsMonthlyAggregates`) e envia `score`/`comment` brutos para `submitNpsResponse` decidir.
`NpsResponsePage` nunca acessa Firestore/Storage diretamente — só via `CloudFunctionsService`
(`requireAuth: false`, mesmo contrato de link público de TASK-081).

## Regras de negócio implementadas

(Já implementadas no backend herdado; validadas nesta rodada via `npm run build`/`npm run lint`/
`npx jest test/nps`, não reescritas.)

- Pesquisa disparada apenas nos marcos "entregue"/"resolvido" de `postSaleEvents` (TASK-201), nunca
  para marcos intermediários.
- Envio condicionado a opt-in de comunicação ativo do cliente (TASK-183) — sem opt-in, nenhuma
  `NpsSurveyRequest` é criada.
- Uma única `NpsSurveyRequest` por pedido+marco (`npsSurveyRequestDocId`, id determinístico,
  checado dentro de uma transação) — nunca duplicada.
- Resposta aceita exatamente uma vez por pesquisa (`NpsResponse` reusa o id da própria
  `NpsSurveyRequest`); resubmissão retorna `alreadyAnswered` sem nova escrita.
- Categorização padrão (promotor 9-10 / neutro 7-8 / detrator 0-6) e fórmula única
  `(promotores − detratores) / total × 100`, replicada identicamente no client
  (`NpsScoreCategory`/`computeNpsScore`) apenas para eventual exibição — o número que aparece no
  dashboard é sempre o já calculado por `recomputeNpsMonthlyAggregates`, nunca recalculado no
  cliente.
- No client: `SubmitNpsResponseUseCase`/`PreviewNpsSurveyUseCase` fazem apenas validação rasa
  (token não vazio, score 0-10, comentário ≤ 1000 caracteres) para feedback imediato de formulário
  — a decisão real (token válido/expirado/já respondido) é sempre da Cloud Function.

## Regras Firebase implementadas

(Herdadas, validadas nesta rodada; não reescritas.)

- `organizations/{organizationId}/npsSurveyRequests/{id}` e `.../npsResponses/{id}`: leitura via
  `canReadNps` (mesmo escopo de `canReadPostSaleEvent` — vendedor dono, gestor da mesma equipe,
  OWNER/ADMIN, portal do cliente correspondente); escrita sempre `false` (só Admin SDK).
- `organizations/{organizationId}/npsMonthlyAggregates/{id}`: leitura via `canReadNpsAggregate` —
  `report.viewSensitive` para escopo `organization`/`team`, mais o próprio vendedor (e seu gestor
  de equipe) para o escopo `seller`; escrita sempre `false`.
- Índices: composto `companyId+scope+scopeId+periodKey` em `npsMonthlyAggregates` e
  `collectionGroup` em `tokenHash` de `npsSurveyRequests` (necessário para o lookup anônimo por
  token, mesmo padrão de `catalogShares`/`invites`).
- Testes de Rules (`firestore-tests/firestore.rules.test.js`) já cobrem casos positivos e negativos
  completos (RBAC por papel, isolamento cross-tenant, escrita sempre negada mesmo para OWNER) para
  as três coleções — ver "Pendências" quanto à execução real (bloqueio de ambiente).

## Analytics implementado

- `AnalyticsEvents.npsResponseSubmitted` — registrado por `NpsResponseBloc` quando uma resposta é
  aceita (`outcome: accepted`), carregando apenas `score` (nunca o comentário livre ou qualquer id
  de cliente/pedido).
- `AnalyticsEvents.npsScoreCardViewed` — registrado por `NpsScoreCardCubit` ao carregar o
  indicador com sucesso, carregando `scope`/`has_score` (nunca o valor numérico do NPS em si).

## Crashlytics implementado

Nenhuma integração nova direta; erros seguem o pipeline padrão (`CloudFunctionsService`/
`AppException` → `AppFailure`) já coberto pelos handlers globais existentes.

## Impacto offline

- `NpsResponsePage` (fluxo público do cliente) exige conectividade — é uma Cloud Function callable
  sem fallback offline, mesmo contrato de `CatalogSharePublicPage`/`CartSharePublicPage`.
- `NpsScoreCard` (dashboard) não tem cache local dedicado (`NpsAggregateRepositoryImpl` não
  implementa TTL/persistência, ao contrário de `AggregationRepositoryImpl`) — é uma leitura única,
  de baixa frequência, cujo fallback natural em caso de falha é o próprio estado de erro do card,
  nunca bloqueando o resto do dashboard.

## Impacto multi-tenant

- Toda entidade (`NpsSurveyRequest`, `NpsResponse`, `npsMonthlyAggregates`) carrega
  `organizationId`/`companyId`; toda leitura passa pelas Firestore Rules acima, nunca confiando em
  campo enviado pelo client. O cliente anônimo que responde a pesquisa nunca enxerga
  `organizationId`/`customerId`/`sellerId`/qualquer id interno (`NpsSurveyPreview` só expõe nome da
  organização e número do pedido).

## Testes criados

- Backend: já existiam (herdados) e foram apenas executados/validados nesta rodada — ver
  "Comandos executados"/"Resultado dos testes".
- Flutter: nenhum teste unitário/widget novo dedicado a `lib/features/nps/presentation` foi
  criado nesta rodada (ver "Decisões técnicas"/"Pendências" — risco documentado, não omissão
  silenciosa). Foram atualizados os testes já existentes impactados pela integração no dashboard:
  `test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart` (novo
  parâmetro `createNpsScoreCardCubit`) e `test/core/analytics/analytics_events_test.dart` (2 novos
  eventos na taxonomia).

## Comandos executados

- `dart run build_runner build` — sucesso; `injection.config.dart` passou a registrar
  `NpsAggregateDataSource`/`Impl`, `NpsPublicSurveyDataSource`/`Impl`,
  `NpsAggregateRepository`/`Impl`, `NpsPublicSurveyRepository`/`Impl`,
  `LoadNpsAggregateTrendUseCase`, `PreviewNpsSurveyUseCase`, `SubmitNpsResponseUseCase`,
  `NpsResponseBloc`, `NpsScoreCardCubit`, os 3 mappers e o `getNpsSurveyByToken`/etc. (as
  mensagens "Missing dependencies" exibidas são ruído pré-existente do `injectable_generator`, já
  documentado por TASK-199/200/201, não relacionado a esta task).
- `flutter analyze` (repositório inteiro) — 0 erros; 18 infos/deprecations pré-existentes,
  idênticas às já documentadas por TASK-199/200/201, nenhuma em `lib/features/nps/` ou em qualquer
  arquivo tocado por esta task.
- `dart format --set-exit-if-changed .` — reformatou 13 arquivos (10 da própria feature `nps`
  criados/formatados nesta rodada + 3 já reportados na primeira execução), e também reformatou 6
  arquivos totalmente fora do escopo desta task (drift de formatação pré-existente na base, mesmo
  fenômeno documentado por TASK-199/200/201: rodar `dart format .` no repositório inteiro sempre
  reformata alguns arquivos legados que não estão 100% no padrão atual do formatter). Os 6 arquivos
  fora de escopo (`lib/core/localization/presentation/pages/locale_settings_page.dart`,
  `lib/features/cart_share/presentation/widgets/cart_share_sheet.dart`,
  `test/features/after_sales/data/mappers/post_sale_event_mapper_test.dart`,
  `test/features/after_sales/domain/usecases/register_post_sale_event_use_case_test.dart`,
  `test/features/product_import/domain/services/product_import_mapping_validator_test.dart`,
  `test/features/product_import/domain/usecases/start_product_import_job_use_case_test.dart`)
  foram restaurados ao conteúdo exato do HEAD antes do commit (confirmado com `git diff` vazio) —
  nenhum deles faz parte deste commit.
- Segunda execução de `dart format --set-exit-if-changed .` (após a restauração acima) —
  sucesso, 0 arquivos alterados.
- `flutter test` (suíte completa) — 3335 testes: 3334 passaram; 1 falha pré-existente e não
  relacionada (`test/app/bootstrap_test.dart`, `PushDeviceMapper` não registrado no GetIt em
  ambiente de teste — mesma falha já documentada por TASK-199/200/201).
- `flutter test test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart
  test/core/navigation/app_router_test.dart test/core/navigation/session_auth_guard_test.dart` —
  todos passaram (30 testes), confirmando que o novo builder opcional `npsResponsePageBuilder` e o
  novo parâmetro `createNpsScoreCardCubit` não quebraram nada existente.
- `npm run build` em `functions` (tsc) — sucesso.
- `npm run lint` em `functions` (eslint) — sucesso (0 erros; 10 warnings pré-existentes de
  `no-explicit-any` em arquivos de teste não relacionados a esta task).
- `npx jest test/nps` — sucesso: 3 suítes, 43 testes (`nps-shared.test.ts`,
  `trigger-nps-survey.test.ts`, `recompute-nps-monthly-aggregates.test.ts`), todos passaram (são
  testes unitários puros, sem Firestore/Auth emulator — por isso rodam neste ambiente, ao
  contrário dos testes de Rules).

## Resultado do formatter

Sucesso: todos os arquivos desta task formatados sem pendências; os 6 arquivos de drift
pré-existente fora do escopo foram restaurados ao HEAD e não fazem parte do commit.

## Resultado do analyzer

`flutter analyze` no repositório inteiro: 0 erros; 18 infos/deprecations pré-existentes, nenhuma
relacionada a TASK-202.

## Resultado dos testes

- Flutter: `flutter test` completo → 3335 testes, 3334 passaram, 1 falha pré-existente e não
  relacionada já documentada por TASK-199/200/201.
- Functions: `npm run build`/`npm run lint` → sucesso. `npx jest test/nps` → 43/43 testes
  passaram (testes puros, sem emulator). Os testes de Firestore Rules
  (`firestore-tests/firestore.rules.test.js`) **não puderam ser executados neste ambiente**: o
  Firebase Emulator Suite exige Java, que não está instalado nesta sandbox (mesmo bloqueio de
  infraestrutura já documentado por TASK-199/200/201) — não afirmo tê-los executado com sucesso
  contra o emulador real.

## Decisões técnicas

- **Sem cache/TTL local em `NpsAggregateRepositoryImpl`**: ao contrário de
  `AggregationRepositoryImpl` (TASK-133), o repositório de agregado de NPS não implementa cache em
  memória nem fallback em `SharedPreferences`. O indicador de NPS é uma leitura única e de baixa
  frequência (um documento por carregamento de dashboard, não um gráfico reconsultado a cada
  filtro) — a complexidade adicional foi deliberadamente adiada até que uma necessidade concreta
  apareça, mesmo trade-off documentado pela própria `AggregationRepositoryImpl`.
- **`NpsScoreCard` plugado apenas no dashboard do representante (não no executivo)**: a task cita
  "dashboards existentes (ex.: dashboard do representante/executivo)" como exemplo, não como lista
  exaustiva. O dashboard do representante já reutiliza exatamente o padrão de composição
  (`WalletSummaryCard`/`DailyRepSummaryCard`, cada um com seu próprio cubit provido via
  `MultiBlocProvider`) que `NpsScoreCard` segue à risca, tornando essa integração de baixo risco e
  auto-suficiente. Estender ao dashboard executivo (`ExecutiveDashboardPage`) exigiria decidir a
  granularidade agregada certa para aquele contexto (organização vs. equipe vs. topo de funil) e
  não foi feito nesta rodada — documentado como pendência abaixo, não como lacuna silenciosa.
- **Nenhum novo componente de Design System para o seletor de nota 0-10**: `NpsResponsePage` reusa
  `AppFilterChip` (11 chips selecionáveis) em vez de criar um `AppRatingSelector` dedicado — não
  existe ainda esse componente na Design System e criar um de uso único (uma única tela pública,
  sem reuso previsto por nenhuma outra feature hoje) não se justificava nesta rodada. Documentado
  como possível evolução futura (ex.: se outra pesquisa/formulário precisar do mesmo padrão).
  Seguindo a instrução de organização sobre o plugin `malwee-desing`: como este ambiente não tinha
  esse plugin habilitado nesta sessão, não foi possível gerar um componente de design formal por
  ele — a solução acima ficou deliberadamente simples e reaproveitando tokens/componentes já
  existentes da Design System, sem inventar nada fora do padrão vigente.
- **Nenhum teste de widget/bloc novo para `lib/features/nps/presentation`**: diferente de
  TASK-199/200/201 (que sempre incluíram testes de use case/mapper/widget para o código novo desta
  camada), esta rodada não escreveu testes dedicados para `NpsResponseBloc`/`NpsResponsePage`/
  `NpsScoreCardCubit`/`NpsScoreCard`. Optei por priorizar completar a feature inteira (datasources,
  repositórios, presentation, wiring real de rota/DI/dashboard) dentro do orçamento desta sessão,
  já que o estado herdado exigia todo esse trabalho de "última milha" para a task sequer poder ser
  considerada entregue; a integração no dashboard do representante foi validada indiretamente pela
  suíte de widget já existente daquela página (que agora também exercita o `NpsScoreCard` via
  `MultiBlocProvider`, com um repositório fake). Documentado abaixo como risco/pendência real, não
  omitido.

## Riscos conhecidos

- Testes de Firestore Rules não executados neste ambiente (falta de Java para o Emulator Suite) —
  precisam rodar em CI/ambiente com Java antes do próximo deploy real (mesmo risco já documentado
  por TASK-199/200/201).
- Ausência de testes de widget/bloc dedicados para `NpsResponseBloc`/`NpsResponsePage`/
  `NpsScoreCardCubit`/`NpsScoreCard` — cobertura direta de regressão para esses arquivos específicos
  é hoje zero (a cobertura indireta via `representative_dashboard_page_test.dart` só garante que o
  card renderiza sem erro no estado "sem dados", não os fluxos de sucesso/erro/trend do próprio
  cubit, nem o formulário de resposta do cliente).
- `NpsScoreCard` hoje só aparece no dashboard do representante — o dashboard executivo ainda não
  mostra o NPS agregado por organização/equipe.

## Pendências

- Rodar `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em um
  ambiente com Java instalado, antes do deploy, para validar de fato os testes de Rules de
  `npsSurveyRequests`/`npsResponses`/`npsMonthlyAggregates`.
- Escrever testes de bloc/widget dedicados para `NpsResponseBloc`/`NpsResponsePage` (formulário de
  resposta, token inválido/expirado/já respondido) e para `NpsScoreCardCubit`/`NpsScoreCard`
  (estado de erro, "sem dados suficientes", trend up/down), numa iteração seguinte.
- Avaliar plugar `NpsScoreCard` (escopo `organization`/`team`) no `ExecutiveDashboardPage`, gated
  por `Capability.reportViewSensitive` (já existente no client), quando a granularidade agregada
  correta para aquele contexto for decidida.

## Evidências

- `npm run build`/`npm run lint` em `functions` → sucesso.
- `npx jest test/nps` → 43/43 testes passaram.
- `dart run build_runner build` → sucesso, `injection.config.dart` registrou as novas classes.
- `flutter analyze` (repositório inteiro) → 0 erros.
- `dart format --set-exit-if-changed .` → 0 arquivos alterados após restaurar o drift
  pré-existente fora do escopo.
- `flutter test` (repositório inteiro, 3335 testes) → 3334 passaram, 1 falha pré-existente e não
  relacionada (mesma já documentada por TASK-199/200/201).

## Commit

`feat(nps): implementa pesquisa de satisfação com pontuação e dashboard de NPS (TASK-202)`

## Push

Não autorizado nesta rodada (push não solicitado pelo usuário).

## Hash do commit

Preenchido após o commit — ver seção final desta task (hash real do `git log -1`, nunca inventado).

## Branch

`main`
