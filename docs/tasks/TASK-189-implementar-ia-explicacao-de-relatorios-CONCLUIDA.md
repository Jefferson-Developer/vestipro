# TASK-189 — Concluída (2026-09-08)

## Resumo

Implementada a explicação em linguagem natural de um relatório/dashboard já calculado pelo
construtor de relatórios (TASK-144): Cloud Function `explainReport` que re-executa
`runReportAggregation` (nunca confia em um `ReportQueryResult` vindo do cliente — mesmo padrão de
`exportReportToCsv`, TASK-146), monta um payload de "data points" citáveis (linhas + totais por
métrica + variação percentual quando há comparação de período), pede a um LLM configurável que
narre tendências/destaques citando `[refs: ...]`, valida a resposta contra o payload (rejeitando
número fora do payload ou citação inexistente) e cacheia por requester+relatório. No Flutter, feature
`report_explanation` completa (Clean Architecture + Cubit) com o botão "Explicar este relatório"
integrado ao construtor de relatórios (`ReportBuilderPage`).

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, Cloud Function, RBAC, cache, testes)
- `flutter-ui-design-specialist` (não invocado como subagente separado — o painel de UI seguiu o
  padrão visual já estabelecido por `WalletSummaryCard`/`ApproachSuggestionSheet`, reaproveitado
  diretamente por ser um caso simples de checklist)

## Arquivos criados

Backend (Cloud Functions):
- `functions/src/report_explanation/report-explanation-types.ts`
- `functions/src/report_explanation/report-explanation-shared.ts`
- `functions/src/report_explanation/explain-report.ts`
- `functions/src/report_explanation/index.ts`
- `functions/test/report_explanation/report-explanation-shared.test.ts` (16 testes)

Flutter (feature `report_explanation`):
- `lib/features/report_explanation/domain/entities/report_explanation.dart`
- `lib/features/report_explanation/domain/entities/report_explanation_reference.dart`
- `lib/features/report_explanation/domain/repositories/report_explanation_repository.dart`
- `lib/features/report_explanation/domain/usecases/explain_report_use_case.dart`
- `lib/features/report_explanation/data/repositories/cloud_functions_report_explanation_repository.dart`
- `lib/features/report_explanation/presentation/cubit/report_explanation_state.dart`
- `lib/features/report_explanation/presentation/cubit/report_explanation_cubit.dart`
- `lib/features/report_explanation/presentation/widgets/report_explanation_panel.dart`
- `lib/features/report_explanation/report_explanation.dart` (barrel)

Testes Dart:
- `test/features/report_explanation/domain/usecases/explain_report_use_case_test.dart` (4 testes)
- `test/features/report_explanation/presentation/cubit/report_explanation_cubit_test.dart` (4 testes)
- `test/features/report_explanation/presentation/widgets/report_explanation_panel_test.dart` (4 testes)

## Arquivos alterados

- `functions/src/index.ts` — exporta `explainReport`.
- `functions/src/reports/execute-report-query.ts` — `parsePeriod` passa a ser exportado (reuso
  exato pelo `explainReport`, evitando uma segunda implementação de parsing de período).
- `firestore.rules` — bloco novo `organizations/{organizationId}/reportExplanations/{cacheKey}`
  (`allow read, write: if false`, mesmo padrão de `walletSummaries`/`approachSuggestions`/
  `dailyRepSummaries`).
- `lib/core/analytics/analytics_events.dart` — dois eventos novos: `reportExplanationGenerated`/
  `reportExplanationGenerationFailed`.
- `lib/features/reports/presentation/pages/report_builder_page.dart` — `ReportBuilderPage` ganha o
  parâmetro opcional `createReportExplanationCubit`; quando fornecido, `_Preview` renderiza
  `ReportExplanationPanel` (dentro de um `BlocProvider<ReportExplanationCubit>` próprio) logo abaixo
  da `DataTable`, assim que a query retorna ao menos uma linha.
- `lib/app/bootstrap.dart` — wiring de `createReportExplanationCubit: () =>
  getIt<ReportExplanationCubit>()` no builder de `ReportBuilderPage`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra
  `CloudFunctionsReportExplanationRepository`/`ExplainReportUseCase`/`ReportExplanationCubit`).

## Arquitetura utilizada

Clean Architecture + feature-first, mesmo padrão das TASK-186/187/188 (EPIC-28):
Presentation (`ReportExplanationPanel`) → `ReportExplanationCubit` → `ExplainReportUseCase` →
`ReportExplanationRepository` (contrato) → `CloudFunctionsReportExplanationRepository` (impl) → Cloud
Function `explainReport`. Sem datasource Firestore direto no Flutter: o cache
(`organizations/{organizationId}/reportExplanations/{cacheKey}`) nunca é lido pelo cliente
diretamente (`firestore.rules` nega tudo); a única forma de obter uma explicação é a resposta do
próprio callable.

No backend, `explain-report.ts` (o `onCall`) nunca monta o payload sozinho: reaproveita
`runReportAggregation` (já existente, de `execute-report-query.ts`, usado também por
`executeReportQuery` e `exportReportToCsv`) para re-derivar as linhas do relatório sob o
escopo de role/tenant do próprio chamador — o cliente nunca envia um `ReportQueryResult` que a
function confie cegamente. `report-explanation-shared.ts` isola a lógica pura e testável (montagem
do payload, hash, prompt, validação anti-alucinação, resolução de referências), no mesmo molde de
`wallet-summary-shared.ts`/`approach-suggestion-shared.ts`.

## Regras de negócio implementadas

- A IA nunca recalcula ou reinterpreta valores: todo `dataPoint` citável vem literalmente da
  agregação já validada (`runReportAggregation`) ou de uma soma determinística e não-discricionária
  feita pela própria Cloud Function (`total_<metricId>` = soma dos valores já agregados por linha —
  operação equivalente à que `aggregateRows` já faz ao somar snapshots dentro de um grupo).
- Todo número citado no texto gerado deve corresponder a um valor do payload (`[refs: ...]` +
  verificação de token numérico); resposta com número fora do payload é descartada e há uma
  retentativa única antes de falhar definitivamente.
- O prompt exige que o texto declare explicitamente o período de referência (`periodLabel`,
  ex. "setembro/2026") logo no início, e nunca faça recomendação de ação comercial — apenas descreve.
- Payload restrito ao escopo de acesso do usuário: o RBAC é o mesmo já aplicado por
  `runReportAggregation`/`catalogForRole` (dimensões/métricas indisponíveis pelo perfil,
  `SALES_REP` restrito ao próprio `scopeId`, `SALES_MANAGER` restrito às próprias equipes) — não há
  um segundo mecanismo de autorização a manter em sincronia.
- Cache por relatório (via `savedReportId` quando disponível, ou fingerprint determinístico da
  definição quando ainda não salvo) + hash do payload, sempre escopado por `requesterUid` — nunca
  compartilhado entre usuários diferentes, já que dois papéis podem ver linhas diferentes para a
  mesma definição.
- Relatório sem linhas (`rows.length === 0`) nunca chega à IA: falha com
  `failed-precondition`/"dados insuficientes", tratado pela UI como estado de erro recuperável.

## Regras Firebase implementadas

`firestore.rules`: `organizations/{organizationId}/reportExplanations/{cacheKey}` com
`allow read, write: if false` — o cache gerado pela IA nunca é lido diretamente por nenhum cliente,
apenas através da resposta do próprio callable `explainReport`.

`explainReport` (Cloud Function callable): exige autenticação, recarrega a Membership real do
chamador, exige perfil em `REPORT_ROLES` (mesmo conjunto de `executeReportQuery`), e reexecuta
`runReportAggregation` sob esse escopo antes de montar qualquer payload ou tocar o cache — nunca
confia em dimensões/métricas/linhas enviadas pelo cliente como se já fossem o resultado final.

## Analytics implementado

`reportExplanationGenerated` (sucesso, com `from_cache`) e `reportExplanationGenerationFailed` (com
`failure_code`), logados por `ExplainReportUseCase` — nunca o texto gerado como parâmetro.

## Crashlytics implementado

Nenhum handler específico novo: erros do `explainReport` já fluem pelo `AppException`/`Failure`
padrão (`CloudFunctionsService`/`mapAppExceptionToFailure`), que já alimenta o pipeline de
Crashlytics existente para toda chamada de Cloud Function.

## Impacto offline

Nenhum: mesma decisão das TASK-186/187/188 — a explicação depende de uma chamada de rede a um LLM
provider, não há modo offline para esta feature (documentado no contrato de
`ReportExplanationRepository`).

## Impacto multi-tenant

Zero risco novo de vazamento entre tenants: o payload nunca é montado a partir de dado enviado pelo
cliente — é sempre a saída de `runReportAggregation`, que já escopa por `organizationId`/`companyId`/
role/equipe antes de qualquer linha ser lida. O cache é sempre gravado sob
`organizations/{organizationId}/reportExplanations/{cacheKey}` e nunca lido fora da resposta do
próprio callable.

## Testes criados

TypeScript (`functions/`, executados neste ambiente, sem emulador):
- `report-explanation-shared.test.ts` — 16 testes: montagem do payload (linhas/totais/cap de linhas/
  variação percentual/payload vazio), hash estável, validação anti-alucinação (aceita, sem citação,
  citação desconhecida, número alucinado), resolução de referências, prompt e determinismo da chave
  de cache (por requester, por `savedReportId`).

Dart (`test/features/report_explanation/`, executados neste ambiente):
- `explain_report_use_case_test.dart` — 4 testes (sucesso+analytics, validação sem dimensão/métrica,
  falha propagada+analytics).
- `report_explanation_cubit_test.dart` — 4 testes (idle, loading→ready, loading→error, reset).
- `report_explanation_panel_test.dart` — 4 testes (idle/carregando/erro/pronto + expansão de
  referências).

RBAC: não foi criado um teste de RBAC dedicado para `explainReport`, porque a autorização é
inteiramente delegada a `runReportAggregation`/`catalogForRole` — já cobertos por
`functions/test/reports/report-catalog.test.ts` (`catalogForRole('READ_ONLY')` lança `HttpsError`) e
`functions/test/reports/execute-report-query.test.ts`. Duplicar esse teste aqui violaria a regra de
não duplicar cobertura de uma mesma regra (`AGENTS.md`).

## Comandos executados

```bash
cd functions && npx jest test/report_explanation test/reports test/wallet_summary test/approach_suggestion
cd functions && npx tsc --noEmit -p tsconfig.json
cd functions && npm run lint
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/app/injection.config.dart"
dart format --set-exit-if-changed lib test
flutter analyze
flutter test test/features/report_explanation test/app/injection_test.dart test/features/reports/presentation/pages/report_builder_page_test.dart
flutter test test/features/reports
```

## Resultado do formatter

`dart format --set-exit-if-changed lib test`: reformatou os 3 arquivos de teste novos desta feature
(indentação padrão) e, incidentalmente, 4 arquivos pré-existentes fora do escopo desta task
(`locale_settings_page.dart`, `cart_share_sheet.dart` e dois testes de `product_import` — drift de
formatação anterior à esta task); esses 4 foram revertidos (`git checkout --`) para manter o commit
restrito a TASK-189, conforme `AGENTS.md` ("Não altere arquivos fora do escopo").

## Resultado do analyzer

`flutter analyze`: 18 issues, todas nível `info` (nenhum erro/warning), a maioria pré-existente no
restante do código (ex.: `deprecated_member_use` de `RadioListTile.groupValue` em código que já
existia antes desta task) — apenas uma nova, também `info`, no mesmo estilo já presente em
`replenishment_repository_impl.dart` (`use_null_aware_elements` para `if (x != null) 'key': ...` em
literal de mapa).

## Resultado dos testes

- Cloud Functions: 122/122 testes passando em `test/report_explanation`, `test/reports`,
  `test/wallet_summary`, `test/approach_suggestion` (a suíte completa `npx jest` tem falhas
  pré-existentes e não relacionadas em specs que dependem do Firebase Emulator, indisponível neste
  ambiente — mesma limitação documentada nas TASK-186/187/188).
- Flutter: 19/19 testes passando em `test/features/report_explanation` +
  `test/app/injection_test.dart` + `test/features/reports/presentation/pages/report_builder_page_test.dart`;
  103/103 testes passando em `test/features/reports` (suíte inteira do módulo tocado).

## Decisões técnicas

- `explainReport` nunca aceita um `ReportQueryResult` do cliente como fonte de verdade — sempre
  re-executa `runReportAggregation` (mesma decisão de `exportReportToCsv`, TASK-146), garantindo que
  o RBAC/escopo de tenant seja sempre o mesmo já testado para a query interativa e para a exportação,
  em vez de duplicar essa lógica ou confiar em algo computado no cliente.
- `savedReportId` é opcional e usado apenas para estabilizar a chave de cache (evita gerar de novo
  para o mesmo relatório salvo) — nunca é tratado como fonte de autorização; a autorização real é
  sempre re-derivada de `dimensions`/`metrics`/`filters` e do papel/tenant atual do chamador.
- A "explicação nunca é fonte de verdade" foi reforçada tecnicamente: o único cálculo feito pela
  própria function (fora do LLM) é uma soma determinística por métrica sobre linhas já validadas —
  nunca uma projeção, margem ou regra de negócio nova.
- Numerais do período de referência (ano/mês) e a contagem de linhas omitidas são tratados como
  "contexto permitido" na validação anti-alucinação (sem exigir citação `[refs: ...]`), já que são
  dados de contexto determinísticos, não métricas de negócio — evita falso-positivo de "alucinação"
  ao exigir que o texto declare o período.
- Botão "Explicar este relatório" integrado apenas ao construtor de relatórios (`ReportBuilderPage`)
  nesta rodada — ver Pendências sobre dashboards existentes.

## Riscos conhecidos

- O provedor de LLM real (Anthropic/OpenAI) não está configurado neste ambiente
  (`REPORT_EXPLANATION_LLM_PROVIDER=disabled` por padrão) — a feature está pronta end-to-end, mas só
  produz explicações reais quando alguém com acesso aos segredos do Firebase configurar
  `REPORT_EXPLANATION_LLM_PROVIDER`/`REPORT_EXPLANATION_LLM_API_KEY` em produção (mesmo modelo já
  usado por TASK-186/187/188).
- `injection.config.dart` foi regenerado via `build_runner` neste ambiente (levou ~36 minutos devido
  ao tamanho do projeto) — confirmado que os 3 novos registros (`ReportExplanationRepository`,
  `ExplainReportUseCase`, `ReportExplanationCubit`) foram gerados corretamente e que `flutter
  analyze`/`flutter test` seguem passando.

## Pendências

- O botão "Explicar este relatório" foi integrado apenas ao construtor de relatórios
  (`ReportBuilderPage`, TASK-144). A task pedia também integração "nos dashboards existentes" — não
  foi feita nesta rodada por escopo/tempo: `ReportExplanationPanel`/`ReportExplanationCubit` já são
  genéricos (recebem apenas um `ReportDefinition` e um `savedReportId?` opcional) e podem ser
  reaproveitados por qualquer dashboard que já monte um `ReportDefinition` equivalente, sem alterar o
  contrato do backend. Sugestão: abrir uma task específica (ou ampliar TASK-190+) para essa
  integração adicional quando houver demanda concreta de qual(is) dashboard(s) priorizar.

## Evidências

Ver "Comandos executados"/"Resultado dos testes" acima — sem screenshots (mudança de backend +
integração de UI que já segue exatamente o padrão visual existente de `WalletSummaryCard`).

## Commit

`feat(report-explanation): implementa IA generativa para explicação de relatórios (TASK-189)`

## Push

Não realizado nesta rodada — push não autorizado.

## Hash do commit

`ac6f4e6ea059209d46c4c9bb0003696392871597`

## Branch

`main`
