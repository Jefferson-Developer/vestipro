# TASK-187 — Concluída (2026-09-07)

## Resumo

Implementado o segundo recurso do EPIC-28 (IA generativa): sugestão de abordagem comercial por
cliente. Uma nova Cloud Function callable (`suggestApproach`) monta, inteiramente server-side, um
payload estruturado (`ApproachSuggestionPayload`) a partir de dados reais já persistidos — últimas
compras (`orders`, filtradas por `customerId`, nunca dados de outro cliente), atividades de CRM
recentes (`crmActivities`, TASK-059) e insights ativos do cliente (`insights`, TASK-121) — nunca
texto livre do vendedor nem dado de outra organização. A Function reaproveita o adapter de LLM
plugável criado na TASK-186 (extraído para `functions/src/shared/llm-provider-adapter.ts` nesta
task, para que as duas features de IA generativa compartilhem a mesma porta + adapters concretos
sem duplicação), com um prompt fixo que proíbe explicitamente introduzir números fora do payload,
citar produto/fato não fornecido, sugerir desconto/preço/condição comercial, ou usar linguagem de
compromisso contratual. Toda resposta é validada (`validateGeneratedApproachSuggestion`): rejeitada
(com uma única retentativa) se citar um código inexistente, não citar nenhuma referência, mencionar
um número que não exista literalmente no payload, **ou mencionar um termo comercial proibido**
(desconto, cortesia, brinde, promoção, "garantimos", etc.) — essa última é uma trava específica
desta task, além das três já herdadas da TASK-186. O resultado é sempre um **rascunho editável**:
nunca uma chamada, pedido ou mensagem é disparada automaticamente. Lado Flutter: feature nova
`lib/features/approach_suggestion/` (Clean Architecture completa) com um `ApproachSuggestionSheet`
reaproveitado em dois pontos de entrada — o botão "Abordagem" no detalhe 360 do cliente
(`CustomerDetailPage`, TASK-052) e a ação "Sugerir abordagem comercial com IA" por linha na central
de oportunidades (`OpportunityCenterPage`, TASK-132) — sempre com o texto sugerido em um campo
editável antes de qualquer uso; "Usar como atividade" no detalhe do cliente reabre a sheet
"Registrar atividade" já existente pré-preenchida com o texto (editado) marcado como "Abordagem
sugerida por IA", dando rastreabilidade na timeline CRM sem inventar uma segunda persistência
paralela só para esta feature.

**Nota sobre credencial de provedor de LLM:** assim como na TASK-186, este ambiente não tem (nem
pode configurar) uma chave de API real de um provedor de LLM. A arquitetura completa foi
implementada e é totalmente testável/funcional (Cloud Function, contrato de payload, prompt,
validação anti-alucinação + anti-termo-comercial, cache, UI) com a chamada ao provedor real
abstraída atrás do mesmo `LlmProviderAdapter` compartilhado, selecionável via
`APPROACH_SUGGESTION_LLM_PROVIDER`/segredo `APPROACH_SUGGESTION_LLM_API_KEY` (nunca hardcoded, nunca
chamado sem credencial, deliberadamente independente das variáveis da TASK-186 — cada feature de IA
pode usar um provedor diferente ou nenhum). Sem uma credencial configurada, `resolveLlmProviderAdapter`
sempre resolve para o adapter "disabled", que falha de forma controlada e recuperável
(`unavailable`) — isso não é um bloqueio real (a task é implementável e foi implementada por
completo); apenas a validação end-to-end contra um provedor real de produção fica pendente de
alguém com acesso configurar a credencial (ver "Pendências").

## Agentes utilizados

- `flutter-senior-architect` (Cloud Function, domain/data Flutter, RBAC, cache, refatoração
  compartilhada do adapter LLM)
- `flutter-ui-design-specialist` (sheet "Sugerir abordagem" — estados, campo editável,
  acessibilidade, responsividade)

## Arquivos criados

Cloud Functions — infraestrutura compartilhada extraída (`functions/src/shared/`):
- `llm-provider-adapter.ts` — versão generalizada de `LlmProviderAdapter`/`resolveLlmProviderAdapter`
  (aceita `notConfiguredMessage` por chamador, em vez de mensagem fixa da TASK-186).
- `citation-validation.ts` — `extractCitedDataPointCodes`, `parseFlexibleNumber`,
  `findHallucinatedNumberToken` (extraídos de `wallet-summary-shared.ts` sem mudar comportamento).
- `team-membership.ts` — `membersShareTeam` (extraído da checagem inline de
  `assertCanAccessSellerWallet`).

Cloud Functions — feature nova (`functions/src/approach_suggestion/`):
- `approach-suggestion-types.ts` — `ApproachSuggestionDataPoint`, `ApproachSuggestionOrderHighlight`,
  `ApproachSuggestionActivityHighlight`, `ApproachSuggestionInsightHighlight`,
  `ApproachSuggestionPayload`, `ApproachSuggestionValidationOutcome`, `ApproachSuggestionCacheDoc`,
  `ApproachSuggestionReference`.
- `approach-suggestion-shared.ts` — núcleo puro/testável: `buildApproachSuggestionPayload` (monta o
  payload a partir de `orders`/`crmActivities`/`insights`, escopado por
  organização/empresa/cliente), `buildApproachSuggestionPrompt`,
  `validateGeneratedApproachSuggestion` (citações + alucinação + termo comercial proibido),
  `assertCanAccessCustomer` (RBAC), `computePayloadHash`, `resolveApproachSuggestionReferences`,
  `approachSuggestionRef`/`approachSuggestionDocId`, constantes de TTL/rate-limit/limites.
- `generate-approach-suggestion.ts` — `suggestApproach` (`onCall`): auth, RBAC, cache
  hit/invalidação/rate-limit, chamada ao provedor com retentativa controlada, persistência do cache.
- `index.ts` (barrel do módulo).

Testes de Cloud Functions (`functions/test/`, **executados neste ambiente, sem emulador**):
- `shared/llm-provider-adapter.test.ts` — 8 testes (adapter genérico, mensagem customizável).
- `shared/team-membership.test.ts` — 3 testes.
- `approach_suggestion/approach-suggestion-shared.test.ts` — 21 testes: payload (pedidos recentes,
  isolamento multi-cliente/tenant, `recentOutcomeReason` sempre nulo, ordenação de insights por
  impacto), `computePayloadHash`, `validateGeneratedApproachSuggestion` (aceita citação válida,
  rejeita sem citação/código desconhecido/número alucinado/termo comercial proibido — 4 variações
  de termo + 1 caso combinado), `resolveApproachSuggestionReferences`,
  `buildApproachSuggestionPrompt`, `assertCanAccessCustomer` (vendedor responsável, OWNER/ADMIN,
  gestor com time em comum, gestor sem time em comum, vendedor de outro cliente, cliente
  inexistente).

Flutter (`lib/features/approach_suggestion/`):
- `domain/entities/approach_suggestion.dart`, `domain/entities/approach_suggestion_reference.dart`
- `domain/repositories/approach_suggestion_repository.dart`
- `domain/usecases/generate_approach_suggestion_use_case.dart`
- `data/repositories/cloud_functions_approach_suggestion_repository.dart`
- `presentation/cubit/approach_suggestion_state.dart`, `presentation/cubit/approach_suggestion_cubit.dart`
- `presentation/widgets/approach_suggestion_sheet.dart`
- `approach_suggestion.dart` (barrel)

Testes Flutter (`test/features/approach_suggestion/`):
- `domain/usecases/generate_approach_suggestion_use_case_test.dart` — 3 testes (sucesso + analytics,
  validação sem chamar repositório, falha propagada + analytics).
- `presentation/cubit/approach_suggestion_cubit_test.dart` — 4 testes (idle, `[loading, ready]`,
  `[loading, error]`, `reset()`).
- `presentation/widgets/approach_suggestion_sheet_test.dart` — 6 testes (idle, carregando, erro,
  pronto com campo editável sem marcadores `[refs: ...]` brutos e referências expansíveis, e o
  texto **editado** — não o original — sendo devolvido ao caller via `onUseAsActivity`).

## Arquivos alterados

Cloud Functions:
- `functions/src/index.ts` — exporta `suggestApproach`.
- `functions/src/wallet_summary/llm-provider-adapter.ts` — vira um wrapper fino sobre
  `../shared/llm-provider-adapter.ts`, preservando a mensagem/env vars específicas da TASK-186
  (`WALLET_SUMMARY_LLM_PROVIDER`/`WALLET_SUMMARY_LLM_API_KEY`) — nenhuma mudança de comportamento,
  nenhuma mudança necessária em `generate-wallet-summary.ts` ou em seus testes.
- `functions/src/wallet_summary/wallet-summary-shared.ts` — `assertCanAccessSellerWallet` passa a
  chamar `membersShareTeam` (shared) em vez de repetir a checagem de time inline;
  `extractCitedDataPointCodes`/`parseFlexibleNumber` passam a ser importados de
  `../shared/citation-validation` e re-exportados (mesma API pública); `validateGeneratedSummary`
  passa a usar `findHallucinatedNumberToken` (shared) em vez de duplicar a regex/loop de checagem de
  número alucinado. Comportamento idêntico, confirmado pelos 34 testes pré-existentes de
  `wallet-summary-shared.test.ts`/`llm-provider-adapter.test.ts` continuando 100% verdes.
- `firestore.rules` — bloco novo `organizations/{organizationId}/approachSuggestions/{customerId}`
  (`allow read, write: if false`, mesmo padrão de `walletSummaries`).
- `firestore.indexes.json` — índice composto novo para `crmActivities` (`customerId` ASC,
  `occurredAt` DESC), necessário para a consulta de atividades recentes por cliente
  (`buildApproachSuggestionPayload`); nenhum índice novo foi necessário para `orders` (já existia um
  compatível) nem para `insights` (múltiplas igualdades sem `orderBy`, mesmo caso já coberto pela
  TASK-186).

Flutter:
- `lib/core/analytics/analytics_events.dart` — dois eventos novos:
  `approachSuggestionGenerated`/`approachSuggestionGenerationFailed`.
- `lib/features/customers/presentation/pages/customer_detail_page.dart` — novo parâmetro obrigatório
  `createApproachSuggestionCubit` em `CustomerDetailPage` (threaded por toda a árvore de widgets até
  `_QuickActions`); botão "Abordagem" (rótulo compacto para caber ao lado de "Ligar"/"Mensagem"/
  "Atividade" em mobile — mesma razão da TASK-063: "rótulos compactos em largura estreita para
  evitar overflow"; `semanticLabel` completo: "Sugerir abordagem comercial com IA"); nova função
  `_showApproachSuggestionSheet` que abre `ApproachSuggestionSheet` e, no callback "Usar como
  atividade", fecha a sheet e reabre `_showRegisterActivitySheet` (já existente) pré-preenchida.
- `lib/features/insights/presentation/pages/opportunity_center_page.dart` — novo parâmetro
  obrigatório `createApproachSuggestionCubit`; nova ação de linha "Sugerir abordagem comercial com
  IA" (ícone `Icons.auto_awesome`) na `AppDataTable` — mostra um snackbar informativo quando o
  insight não tem `customerId` (nenhum predicado de visibilidade condicional existe no componente de
  tabela compartilhado, então a ação sempre aparece, mas é um no-op guiado nesse caso); "Usar como
  atividade" aqui copia o texto editado para a área de transferência e orienta o vendedor a abrir o
  cliente 360 para registrar — esta tela não tem fluxo próprio de registro de atividade CRM, e não
  foi criado um segundo caminho de persistência só para esta feature (ver "Decisões técnicas").
- `lib/app/bootstrap.dart` — wiring de `createApproachSuggestionCubit: () =>
  getIt<ApproachSuggestionCubit>()` nos dois pontos de entrada.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra
  `CloudFunctionsApproachSuggestionRepository`/`GenerateApproachSuggestionUseCase`/
  `ApproachSuggestionCubit`).
- `test/core/analytics/analytics_events_test.dart` — lista de eventos esperados atualizada.
- `test/features/customers/presentation/pages/customer_detail_page_test.dart` — helper `_pumpPage`
  passa a fornecer `createApproachSuggestionCubit` (com um `ApproachSuggestionRepository` fake que
  lança `UnimplementedError` se chamado, já que nenhum teste existente toca o botão "Abordagem").
- `test/features/insights/presentation/pages/opportunity_center_page_test.dart` — `buildPage()`
  passa a fornecer `createApproachSuggestionCubit` com o mesmo fake "nunca chamado".
- `docs/tasks/TASKS.md` — checkbox da TASK-187 marcado, progresso atualizado para 186/219.

## Arquitetura utilizada

Feature-first + Clean Architecture, mesmo padrão de `wallet_summary`/`demand_forecast`: Presentation
(`ApproachSuggestionSheet` + `ApproachSuggestionCubit`) → Use case
(`GenerateApproachSuggestionUseCase`) → Repository contract (`ApproachSuggestionRepository`) →
Repository impl (`CloudFunctionsApproachSuggestionRepository`, chamando
`CloudFunctionsService.call('suggestApproach', ...)` diretamente — sem datasource Firestore, já que
o cache server-side nunca é lido pelo cliente). Nenhuma regra de negócio (montagem do payload,
prompt, validação anti-alucinação/anti-termo-comercial, RBAC server-side, cache/rate-limit) vive na
UI ou no cliente Dart: tudo isso é 100% Cloud Function (TypeScript).

Diferente da TASK-186 (que tinha um `RepresentativeDashboardVisibilityService` client-side
reaproveitável para a checagem de UX), esta task não duplicou um serviço de visibilidade
client-side equivalente: os dois pontos de entrada (`CustomerDetailPage`, gated por
`Capability.customerView`; `OpportunityCenterPage`, gated por `Capability.insightView` +
`InsightVisibilityService` já filtrando quais insights o próprio ator vê) já garantem que o cliente
mostrado é um que o ator já está autorizado a visualizar — a Cloud Function
(`assertCanAccessCustomer`) continua sendo a única fronteira de autorização real, exatamente como em
toda outra task deste tipo.

`functions/src/shared/llm-provider-adapter.ts`, `citation-validation.ts` e `team-membership.ts`
seguem o mesmo "porta + adapters concretos + fábrica única"/"núcleo puro extraído" já usado em
`erp_integration/adapters/` (TASK-169): a TASK-186 tinha esse código dentro de
`wallet_summary/`; esta task o promoveu para `shared/` (mantendo `wallet_summary/llm-provider-adapter.ts`
como um wrapper fino, para não reabrir/alterar o comportamento já concluído da TASK-186) para que a
segunda feature de IA generativa nunca duplicasse ~190 linhas de adapters HTTP nem a lógica de
regex/parsing de citação anti-alucinação.

## Regras de negócio implementadas

- O payload enviado ao LLM é montado inteiramente a partir de dados já persistidos e escopados por
  `organizationId`/`companyId`/`customerId` via caminho/filtro Firestore (nunca um filtro vindo do
  cliente) — nunca dado de outro cliente ou de outra organização
  (`buildApproachSuggestionPayload`, testado explicitamente).
- Prompt fixo (nunca gerado dinamicamente a partir de texto livre do vendedor) exige uma citação
  `[refs: código,...]` por afirmação numérica, proíbe introduzir números fora do payload, e proíbe
  explicitamente desconto/preço/condição comercial/promessa contratual.
- Validação pós-geração (`validateGeneratedApproachSuggestion`) é a trava real, não apenas prompt
  engineering: (1) rejeita resposta sem nenhuma citação; (2) rejeita código de citação desconhecido;
  (3) rejeita qualquer número no texto que não corresponda (tolerância 0.01) a um `numericValue` do
  payload; (4) **rejeita qualquer menção a um termo comercial proibido** (desconto, cortesia,
  brinde, promoção, condição especial, isento, grátis, "garantimos", "prometemos", "compromisso da
  empresa"), independentemente de o restante do texto estar correto — com uma única retentativa
  antes de falhar de forma controlada.
- A sugestão nunca aciona ação comercial: `ApproachSuggestionSheet` sempre abre o texto em um campo
  editável; nenhum botão desta feature envia mensagem, cria pedido ou contata o cliente
  diretamente — "Usar como atividade" apenas devolve o texto (possivelmente editado pelo vendedor)
  para o caller decidir o que fazer com ele.
- Uso da sugestão como base de uma atividade fica rastreável na timeline CRM: no detalhe do cliente,
  a descrição da atividade registrada é prefixada com "Abordagem sugerida por IA (revisada pelo
  vendedor): ..." — reaproveitando o fluxo/persistência já existente de `RegisterCrmActivityUseCase`
  (TASK-059), nunca uma segunda tabela/coleção inventada só para isto.
- `recentOutcomeReason` (motivo de perda/ganho recente) é sempre `null`: `OpportunityOutcomeReason`
  (TASK-061) hoje só existe em `SharedPreferencesOpportunityOutcomeReasonRepository`
  (local-only, sem persistência Firestore) — uma Cloud Function não tem como lê-lo de forma
  confiável/auditável hoje. Decisão deliberada (documentada no próprio tipo
  `ApproachSuggestionPayload.recentOutcomeReason`): omitir o campo em vez de aceitá-lo como texto
  livre vindo do cliente (o que quebraria a garantia "payload nunca inclui texto não verificado do
  chamador") ou inventar uma leitura não confiável. O campo permanece no contrato para quando
  Opportunities ganhar persistência Firestore real.
- RBAC (`assertCanAccessCustomer`): o próprio vendedor responsável pelo cliente sempre pode gerar a
  sugestão; OWNER/ADMIN podem gerar para qualquer cliente da organização; SALES_MANAGER apenas para
  um cliente cujo vendedor responsável compartilhe uma equipe com ele — mesmo padrão exato já usado
  por `assertCanAccessSellerWallet` (TASK-186)/`decideOrderApproval` (TASK-103), agora via
  `membersShareTeam` compartilhado — sempre re-validado server-side, nunca confiando no que o
  cliente afirma.

## Regras Firebase implementadas

`firestore.rules`: `organizations/{organizationId}/approachSuggestions/{customerId}` com
`allow read, write: if false` — o cache gerado pela IA nunca é lido diretamente por nenhum cliente,
apenas através da resposta do próprio callable `suggestApproach`, que já reaplica RBAC em toda
chamada.

`firestore.indexes.json`: índice composto novo para `crmActivities` (`customerId` ASC, `occurredAt`
DESC).

`suggestApproach` (Cloud Function callable): exige autenticação, recarrega a Membership real do
chamador (`loadActiveMembership`, nunca confia no client), e reaplica `assertCanAccessCustomer` antes
de montar qualquer payload ou tocar o cache.

## Analytics implementado

Dois eventos novos em `lib/core/analytics/analytics_events.dart`:
- `approachSuggestionGenerated` — logado por `GenerateApproachSuggestionUseCase` a cada resposta
  bem-sucedida (fresca ou em cache), com `organization_id`/`customer_id`/`from_cache`.
- `approachSuggestionGenerationFailed` — logado a cada falha, com
  `organization_id`/`customer_id`/`failure_code`.

Nenhum evento novo para "usar como atividade": o registro em si já loga `crmActivityCreated`
(existente, TASK-059) quando feito a partir do detalhe do cliente.

## Crashlytics implementado

Nenhum código novo de captura de exceção não tratada. Todo erro (rede, validação, RBAC, rate-limit)
é convertido em `AppFailure`/`Failure` pelo mesmo `_guard`/`mapAppExceptionToFailure` já usado por
outras `CloudFunctions*Repository` — nunca escapa como exceção não tratada.

## Impacto offline

Nenhum, deliberadamente — mesma razão da TASK-186: a sugestão de abordagem é um recurso sob demanda
que requer conectividade real (chamada a um LLM externo); não há Outbox nem cache Drift. O sheet
mostra apenas seu próprio estado idle/carregando/erro/pronto. O único efeito colateral local
("Usar como atividade" no detalhe do cliente) reaproveita o fluxo de registro de atividade CRM já
existente, que já é offline-first (grava local e sincroniza depois) — esta feature não muda esse
comportamento.

## Impacto multi-tenant

Toda leitura do payload (`orders`, `crmActivities`, `insights`) é escopada por
`organizationId`/`companyId`/`customerId` via caminho/filtro Firestore dentro da própria Cloud
Function — nunca um filtro vindo do cliente. Testado explicitamente
(`buildApproachSuggestionPayload` — "never leaks another customer's order/activity/insight into the
payload") que um pedido/atividade/insight de outro cliente nunca aparece no payload. O cache
(`approachSuggestions`) também vive sob `organizations/{organizationId}/...` e nunca é lido fora da
própria Cloud Function.

## Testes criados

TypeScript (`functions/`, **executados neste ambiente, sem emulador**):
- `test/shared/llm-provider-adapter.test.ts` — 8 testes.
- `test/shared/team-membership.test.ts` — 3 testes.
- `test/approach_suggestion/approach-suggestion-shared.test.ts` — 21 testes.

Dart (`test/features/approach_suggestion/`, **executados neste ambiente**):
- `generate_approach_suggestion_use_case_test.dart` — 3 testes.
- `approach_suggestion_cubit_test.dart` — 4 testes.
- `approach_suggestion_sheet_test.dart` — 6 testes.

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx eslint src test
cd functions && npx jest test/wallet_summary test/approach_suggestion test/shared
cd functions && npx jest                     # suíte completa (ver "Resultado dos testes")
cd functions && npm run build
node -e "JSON.parse(require('fs').readFileSync('firestore.indexes.json','utf8'))"
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter analyze lib/features/customers/presentation/pages/customer_detail_page.dart
flutter analyze lib/features/insights/presentation/pages/opportunity_center_page.dart
flutter test test/features/approach_suggestion test/features/customers/presentation/pages/customer_detail_page_test.dart test/features/insights/presentation/pages/opportunity_center_page_test.dart test/core/analytics/analytics_events_test.dart
flutter test
dart format --set-exit-if-changed lib/features/approach_suggestion test/features/approach_suggestion lib/features/customers/presentation/pages/customer_detail_page.dart lib/features/insights/presentation/pages/opportunity_center_page.dart lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart test/core/analytics/analytics_events_test.dart test/features/customers/presentation/pages/customer_detail_page_test.dart test/features/insights/presentation/pages/opportunity_center_page_test.dart
```

## Resultado do formatter

`dart format --set-exit-if-changed` limpo (0 arquivos alterados na verificação final) em todos os
arquivos Dart tocados por esta task. Uma execução anterior de `dart format --set-exit-if-changed .`
(repositório inteiro) reformatou 4 arquivos **fora do escopo desta task** (drift de formatação
pré-existente, não relacionado a IA generativa/abordagem) — revertidos via `git checkout --` antes
do commit, para não misturar uma mudança não solicitada nesta task.

## Resultado do analyzer

- `flutter analyze` (projeto inteiro): **17 issues, todas pré-existentes e fora do escopo desta
  task** (mesmas 17 já documentadas em `TASK-184-CONCLUIDA.md`/`TASK-186-CONCLUIDA.md`:
  `use_null_aware_elements`/`deprecated_member_use` em arquivos não tocados por esta task).
  **Nenhum erro, nenhum issue novo.**
- `npx tsc --noEmit`/`npx eslint src test` (functions): limpos — apenas 9 warnings
  `@typescript-eslint/no-explicit-any` em fakes de Firestore de teste (mesmo padrão de `any` já
  aceito em fakes de teste no restante do projeto, incluindo os já existentes de
  `wallet-summary-shared.test.ts`). **Nenhum erro.**

## Resultado dos testes

- `npx jest test/wallet_summary test/approach_suggestion test/shared` (functions): **70/70
  passando** (34 de `wallet_summary` — confirmando que a refatoração compartilhada do adapter/
  citação/team-membership não quebrou a TASK-186 — + 21 de `approach-suggestion-shared` + 8 de
  `shared/llm-provider-adapter` + 3 de `shared/team-membership` + 4 de `wallet_summary/llm-provider-adapter`).
- `npx jest` (suíte completa de `functions/`): **427 passando, 182 falhando em 29 suítes** — todas as
  falhas são a **mesma limitação pré-existente já documentada em TASK-184/185/186**
  ("Could not load the default credentials" / timeout de hooks que dependem do Firebase Emulator
  Suite com Java, indisponível neste ambiente); nenhuma delas cita `approach_suggestion`,
  `llm-provider-adapter`, `team-membership` ou `citation-validation` como causa — são os mesmos
  arquivos de teste que já dependiam de emulador antes desta task (`orders`, `pricing`, `sso`,
  `privacy`, `webhooks`, etc.). Confirmado individualmente: os 5 arquivos de teste tocados/criados
  por esta task (`wallet-summary-shared.test.ts`, `wallet_summary/llm-provider-adapter.test.ts`,
  `shared/llm-provider-adapter.test.ts`, `shared/team-membership.test.ts`,
  `approach_suggestion/approach-suggestion-shared.test.ts`) passam 100% quando executados sem o
  restante da suíte dependente de emulador.
- `npm run build` (functions, `tsc`): compilação limpa, sem erros.
- `flutter test test/features/approach_suggestion ...` (escopo desta task): **13/13 passando**.
- `flutter test` (suíte completa do projeto): **3214/3215 passando**. A única falha
  (`test/app/bootstrap_test.dart`, "bootstrap initializes Firebase exactly once and renders
  VestiProApp") é **pré-existente e não relacionada a esta task** — mesmo sintoma exato já
  documentado em `TASK-184-implementar-replenishment-automatico-CONCLUIDA.md`/
  `TASK-186-implementar-ia-resumo-de-carteira-CONCLUIDA.md` (`PushDeviceMapper is not registered
  inside GetIt`), sem qualquer menção a `ApproachSuggestionCubit`/
  `GenerateApproachSuggestionUseCase`/`CloudFunctionsApproachSuggestionRepository` no stack trace.

## Decisões técnicas

**(a) Extração da infraestrutura compartilhada da TASK-186 para `functions/src/shared/`, em vez de
duplicá-la.** `llm-provider-adapter.ts` (adapters Anthropic/OpenAI/disabled, ~190 linhas),
`citation-validation.ts` (regex de citação + parsing de número pt-BR + checagem de alucinação) e
`team-membership.ts` (checagem "gestor compartilha equipe com o alvo") já existiam, criados pela
TASK-186. Em vez de copiar esse código para `approach_suggestion/` (o que violaria a regra "não
duplicar" do `AGENTS.md`), eles foram promovidos para `shared/`, com `wallet_summary/` passando a
importar de lá através de um wrapper fino que preserva exatamente a mensagem/env vars/API pública
originais — os 34 testes pré-existentes de `wallet_summary` continuam passando sem alteração,
confirmando que o comportamento da TASK-186 não mudou. Esta é a única alteração feita em arquivos da
TASK-186 nesta rodada; nenhuma decisão de negócio da TASK-186 foi revisitada.

**(b) `LlmProviderAdapter` de cada feature é independente (variáveis de ambiente próprias).** Em vez
de reaproveitar `WALLET_SUMMARY_LLM_PROVIDER`/`WALLET_SUMMARY_LLM_API_KEY` para as duas features,
`suggestApproach` usa seu próprio par (`APPROACH_SUGGESTION_LLM_PROVIDER`/
`APPROACH_SUGGESTION_LLM_API_KEY`) — uma organização pode escolher um provedor diferente (ou
nenhum) por feature de IA generativa, e desativar uma sem afetar a outra.

**(c) Termo comercial proibido validado por substring, não apenas por prompt.** Assim como a
TASK-186 nunca confia apenas em prompt engineering para números, esta task adiciona uma quarta
checagem pós-geração (`FORBIDDEN_COMMERCIAL_TERMS`) que rejeita qualquer menção a
desconto/cortesia/promoção/compromisso contratual, mesmo que o resto do texto passe nas outras três
checagens. É uma lista fixa e pragmática (substring, case-insensitive) — não uma análise semântica —
mas cobre o vocabulário realista deste domínio (moda B2B) e nunca deixa passar silenciosamente uma
promessa comercial não autorizada.

**(d) `recentOutcomeReason` sempre `null` — gap arquitetural aceito, não contornado com dado não
confiável.** `OpportunityOutcomeReason` (motivo de perda/ganho, TASK-061) só existe hoje em
`SharedPreferencesOpportunityRepository`/`SharedPreferencesOpportunityOutcomeReasonRepository`
(armazenamento local, sem Firestore) — não há como uma Cloud Function lê-lo. As alternativas
descartadas: (i) aceitar o motivo como um campo de texto livre vindo do próprio request do cliente —
quebraria a garantia central de todo este módulo ("payload nunca contém texto não verificado
fornecido pelo chamador", a mesma que impede um vendedor de injetar uma promessa de desconto via
"contexto adicional"); (ii) inventar uma leitura substituta não confiável. Optou-se por manter o
campo no contrato (`ApproachSuggestionPayload.recentOutcomeReason: string | null`), sempre `null`
hoje, documentado como pendente de uma futura task que dê a Opportunities uma persistência
Firestore real (ver "Pendências").

**(e) Rastreabilidade de uso via texto da atividade, não via um novo registro dedicado.** O critério
de aceite "uso da sugestão fica rastreável na timeline do cliente" é satisfeito reaproveitando
`RegisterCrmActivityUseCase` (TASK-059) — a descrição da atividade registrada carrega o prefixo
"Abordagem sugerida por IA (revisada pelo vendedor): ...". Não foi criado um novo campo/coleção
"usedSuggestionId" ou equivalente: a busca textual/visual na timeline já resolve o requisito sem
uma segunda fonte de verdade para o mesmo fato.

**(f) Central de oportunidades usa "copiar para a área de transferência", não um segundo fluxo de
atividade.** Diferente do detalhe do cliente (que já tem uma sheet de registro de atividade),
`OpportunityCenterPage` não tem nenhum fluxo de CRM embutido. Em vez de duplicar
`_RegisterActivitySheet` nessa tela (o que criaria duas implementações da mesma responsabilidade),
"Usar como atividade" ali copia o texto (editado) para a área de transferência e orienta o vendedor
a abrir o cliente 360, onde o registro reaproveita o único caminho existente. Ver "Riscos
conhecidos".

## Riscos conhecidos

- **Fluxo de "usar como atividade" a partir da central de oportunidades é dois passos (copiar +
  abrir manualmente o cliente 360)**, não uma navegação direta — porque esta tela não tem, nem
  antes desta task tinha, uma rota tipada própria para abrir o cliente 360 com uma ação
  pré-carregada a partir daqui (o padrão existente, `onActionExecuted`, é acionado a partir de um
  `InsightAction` predefinido do próprio insight, não de um texto gerado dinamicamente). Nenhum dado
  é perdido (o texto fica na área de transferência), mas a experiência é menos direta que a do
  detalhe do cliente.
- A ação de linha "Sugerir abordagem" na central de oportunidades aparece para **todo** insight,
  mesmo os sem `customerId` (produto/vendedor) — o componente `AppDataTableAction` compartilhado não
  tem um predicado de visibilidade por linha. Nesse caso o botão mostra um snackbar informativo em
  vez de abrir a sheet; nenhum comportamento incorreto, apenas uma ação visível que nem sempre faz
  algo (mesmo padrão de robustez client-side, nunca client-side como fronteira de autorização real).
- `assertCanAccessCustomer` (server-side) usa a mesma regra simplificada já estabelecida por
  `decide-order-approval.ts`/`assertCanAccessSellerWallet` (equipe do próprio gestor via
  `membership.teamIds`) — mesma ressalva já documentada em `TASK-186-CONCLUIDA.md`: mais estrita que
  qualquer regra client-side equivalente que considere `managerUserId` fora de `teamIds`; a Function
  nunca é mais permissiva que o client, apenas potencialmente mais restritiva em um caso raro.
- `FORBIDDEN_COMMERCIAL_TERMS` é uma lista fixa de substrings (não uma análise semântica) — um termo
  sinônimo não listado (ex.: uma gíria regional para "desconto") poderia escapar da checagem; a
  lista cobre o vocabulário comercial padrão em português do Brasil para este domínio, mas não é
  exaustiva por natureza.

## Pendências

- **Ativação em produção com um provedor real de LLM:** configurar `APPROACH_SUGGESTION_LLM_PROVIDER`
  (`anthropic` ou `openai`) e o segredo `APPROACH_SUGGESTION_LLM_API_KEY`
  (`firebase functions:secrets:set APPROACH_SUGGESTION_LLM_API_KEY`), e então validar manualmente a
  qualidade/latência/custo real das respostas geradas — isto **não é um bloqueio de implementação**,
  apenas uma etapa de configuração/validação que só quem tem acesso às credenciais/ao projeto
  Firebase de produção pode fazer.
- **`recentOutcomeReason` permanecerá `null` até Opportunities ganhar persistência Firestore real**
  (hoje `SharedPreferencesOpportunityRepository`/`SharedPreferencesOpportunityOutcomeReasonRepository`,
  local-only) — fora do escopo desta task; quando essa lacuna for resolvida por uma task futura, o
  campo já existe no contrato (`ApproachSuggestionPayload`/prompt) só esperando ser populado.
- Testes de integração contra o Firebase Emulator Suite para `suggestApproach` (RBAC ponta a ponta,
  cache real, Firestore Rules de `approachSuggestions`) não foram escritos/executados nesta rodada —
  mesma limitação pré-existente já documentada em outras tasks recentes (sem Java/emulador
  disponível neste ambiente).
- A navegação direta da central de oportunidades para o cliente 360 com a atividade pré-carregada
  (em vez de copiar/colar manualmente) fica como melhoria futura, condicionada a uma rota tipada que
  ainda não existe (ver "Riscos conhecidos").

## Evidências

Ver "Comandos executados"/"Resultado dos testes" acima — saídas completas disponíveis no histórico
de execução desta sessão.

## Commit

Ver hash abaixo.

## Push

Não realizado nesta rodada — push não autorizado.

## Hash do commit

Ver seção abaixo (preenchido após a criação do commit).

## Branch

main
