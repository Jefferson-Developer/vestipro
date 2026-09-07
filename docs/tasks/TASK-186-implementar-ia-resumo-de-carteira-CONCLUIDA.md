# TASK-186 — Concluída (2026-09-07)

## Resumo

Implementado o EPIC-28 (IA generativa) para o resumo de carteira do vendedor: uma Cloud Function
callable (`generateWalletSummary`) que monta, inteiramente server-side, um payload estruturado
(`WalletSummaryPayload`) a partir de dados já calculados pelo backend — faturamento do mês corrente/
anterior (`representativeMonthlyAggregates`, TASK-133), insights ativos do vendedor (TASK-121) e o
contexto de risco de meta (insight `sellerBelowTarget`, TASK-131) — nunca de dados brutos ou texto
livre. A Function chama um provedor de LLM plugável (interface `LlmProviderAdapter`, com adapters de
referência para Anthropic e OpenAI via `fetch` puro, sem SDK novo), com um prompt fixo que exige uma
citação `[refs: código,...]` após cada afirmação numérica. Toda resposta é validada
(`validateGeneratedSummary`): rejeitada (com uma única retentativa) se citar um código inexistente,
não citar nenhuma referência, ou mencionar um número que não exista literalmente no payload — a
"trava anti-alucinação" central da task. O resultado (texto + referências resolvidas) é cacheado por
vendedor/período (`organizations/{orgId}/walletSummaries/{sellerId}_{periodKey}`, TTL de 60 minutos,
nunca legível diretamente pelo cliente) e invalidado cedo se o payload recalculado mudar de hash,
mesmo dentro do TTL; uma falha recente para o mesmo payload é limitada por frequência
(5 minutos) antes de tentar o provedor de novo. Lado Flutter: feature nova `lib/features/wallet_summary/`
(Clean Architecture completa) com um card "Resumo da carteira" — sob demanda, nunca automático — na
home do vendedor (`RepresentativeDashboardPage`), com estados de idle/carregando/pronto/erro e
referências expansíveis.

**Nota sobre credencial de provedor de LLM:** este ambiente não tem (nem pode configurar) uma chave de
API real de um provedor de LLM (Anthropic/OpenAI). A arquitetura completa foi implementada e é
totalmente testável/funcional (Cloud Function, contrato de payload, prompt, validação anti-alucinação,
cache, UI) com a chamada ao provedor real abstraída atrás de `LlmProviderAdapter`, selecionável via
`WALLET_SUMMARY_LLM_PROVIDER`/segredo `WALLET_SUMMARY_LLM_API_KEY` (nunca hardcoded, nunca chamado sem
credencial). Sem uma credencial configurada, `resolveLlmProviderAdapter` sempre resolve para o adapter
"disabled", que falha de forma controlada e recuperável (`unavailable`) — isso não é um bloqueio real
(a task é implementável e foi implementada por completo); apenas a validação end-to-end contra um
provedor real de produção fica pendente de alguém com acesso configurar a credencial (ver
"Pendências").

## Agentes utilizados

- `flutter-senior-architect` (Cloud Function, domain/data Flutter, RBAC, cache, integração LLM)
- `flutter-ui-design-specialist` (card "Resumo da carteira" — estados, acessibilidade, responsividade)

## Arquivos criados

Cloud Functions (`functions/src/wallet_summary/`):
- `wallet-summary-types.ts` — vocabulário compartilhado: `WalletSummaryDataPoint`,
  `WalletSummaryInsightHighlight`, `WalletSummaryTargetRisk`, `WalletSummaryPayload`,
  `WalletSummaryValidationOutcome`, `WalletSummaryCacheDoc`, `WalletSummaryReference`.
- `llm-provider-adapter.ts` — `LlmProviderAdapter` (interface), `DisabledLlmProviderAdapter`
  (fallback controlado quando não configurado), `AnthropicLlmProviderAdapter`/`OpenAiLlmProviderAdapter`
  (referência, via `fetch` puro), `resolveLlmProviderAdapter` (única fábrica).
- `wallet-summary-shared.ts` — núcleo puro/testável: `buildWalletSummaryPayload` (monta o payload a
  partir do Firestore, escopado por organização/empresa/vendedor), `buildWalletSummaryPrompt`,
  `validateGeneratedSummary` (trava anti-alucinação), `extractCitedDataPointCodes`,
  `parseFlexibleNumber`, `resolveWalletSummaryReferences`, `assertCanAccessSellerWallet` (RBAC),
  `computePayloadHash`, `walletSummaryRef`/`walletSummaryDocId`, constantes de TTL/rate-limit.
- `generate-wallet-summary.ts` — `generateWalletSummary` (`onCall`): auth, RBAC, cache
  hit/invalidação/rate-limit, chamada ao provedor com uma retentativa controlada em caso de resposta
  reprovada, persistência do cache (`ready`/`error`).
- `index.ts` (barrel do módulo).

Testes de Cloud Functions (`functions/test/wallet_summary/`, **executados neste ambiente, sem
emulador**):
- `wallet-summary-shared.test.ts` — 34 testes: `formatPeriodLabel`, `walletSummaryDocId`,
  `buildWalletSummaryPayload` (revenue atual/anterior, ausência de mês anterior, isolamento de
  insights por vendedor/organização, extração de risco de meta), `computePayloadHash` (estável por
  ordem, muda com dado/insight), `validateGeneratedSummary` (aceita citação válida, rejeita sem
  citação/código desconhecido/número alucinado, aceita formatação pt-BR e decimal simples),
  `extractCitedDataPointCodes`, `parseFlexibleNumber`, `resolveWalletSummaryReferences`,
  `buildWalletSummaryPrompt`, `assertCanAccessSellerWallet` (próprio vendedor, OWNER/ADMIN, gestor com
  time em comum, gestor sem time em comum, SALES_REP de outro vendedor).
- `llm-provider-adapter.test.ts` — 7 testes: adapter desabilitado (sem provedor/sem chave/provedor
  desconhecido, nunca chama a rede), Anthropic/OpenAI (chamada correta via `fetch` injetado), erro em
  resposta não-OK.

Flutter (`lib/features/wallet_summary/`):
- `domain/entities/wallet_summary.dart`, `domain/entities/wallet_summary_reference.dart`
- `domain/repositories/wallet_summary_repository.dart`
- `domain/usecases/generate_wallet_summary_use_case.dart` (RBAC client-side via
  `RepresentativeDashboardVisibilityService`, reaproveitada da TASK-140 — nunca duplicada)
- `data/repositories/cloud_functions_wallet_summary_repository.dart`
- `presentation/cubit/wallet_summary_state.dart`, `presentation/cubit/wallet_summary_cubit.dart`
- `presentation/widgets/wallet_summary_card.dart`
- `wallet_summary.dart` (barrel)

Testes Flutter (`test/features/wallet_summary/`):
- `domain/usecases/generate_wallet_summary_use_case_test.dart` — sucesso (próprio vendedor), RBAC
  negado (SALES_REP de outro vendedor), RBAC permitido (gestor com time em comum), validação sem
  chamar repositório/membership, falha do repositório propagada com analytics.
- `presentation/cubit/wallet_summary_cubit_test.dart` — estado inicial idle, `[loading, ready]` em
  sucesso, `[loading, error]` em falha, `reset()` volta a idle preservando o último resumo.
- `presentation/widgets/wallet_summary_card_test.dart` — idle (botão "Gerar resumo"), carregando
  (skeleton, sem botão), erro (mensagem + "Tentar novamente"), pronto (texto sem marcadores
  `[refs: ...]` brutos, referências expansíveis).

## Arquivos alterados

- `functions/src/index.ts` — exporta `generateWalletSummary`.
- `firestore.rules` — bloco novo `organizations/{organizationId}/walletSummaries/{summaryId}`
  (`allow read, write: if false`, mesmo padrão de `erpIntegration/credentials`/`webhookSecrets`: cache
  gerado por IA nunca é lido diretamente por nenhum cliente, apenas via resposta do próprio callable).
- `lib/core/analytics/analytics_events.dart` — dois eventos novos: `walletSummaryGenerated`/
  `walletSummaryGenerationFailed`.
- `lib/features/dashboards/presentation/pages/representative_dashboard_page.dart` — adiciona
  `WalletSummaryCard` (via `WalletSummaryCubit` provido por `MultiBlocProvider`) logo após o grid de
  KPIs; `RepresentativeDashboardPage` ganha o parâmetro obrigatório `createWalletSummaryCubit`.
- `lib/app/bootstrap.dart` — wiring de `createWalletSummaryCubit: () => getIt<WalletSummaryCubit>()`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra
  `CloudFunctionsWalletSummaryRepository`/`GenerateWalletSummaryUseCase`/`WalletSummaryCubit`).
- `test/core/analytics/analytics_events_test.dart` — lista de eventos esperados atualizada.
- `test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart` — helper
  `page()` passa a fornecer `createWalletSummaryCubit` (com um `WalletSummaryRepository` fake nunca
  invocado, já que nenhum teste existente toca o botão "Gerar resumo").
- `docs/tasks/TASKS.md` — checkbox da TASK-186 marcado, progresso atualizado para 185/219.

## Arquitetura utilizada

Feature-first + Clean Architecture, mesmo padrão de `cart_share`/`demand_forecast`: Presentation
(`WalletSummaryCard` + `WalletSummaryCubit`) → Use case (`GenerateWalletSummaryUseCase`) → Repository
contract (`WalletSummaryRepository`) → Repository impl (`CloudFunctionsWalletSummaryRepository`,
chamando `CloudFunctionsService.call('generateWalletSummary', ...)` diretamente — sem datasource
Firestore, já que o cache server-side nunca é lido pelo cliente). Nenhuma regra de negócio (montagem
do payload, prompt, validação anti-alucinação, RBAC server-side, cache/rate-limit) vive na UI ou no
cliente Dart: tudo isso é 100% Cloud Function (TypeScript). O único RBAC client-side é uma checagem de
UX (`RepresentativeDashboardVisibilityService`, já existente da TASK-140, reaproveitada sem
duplicação) — a Cloud Function sempre re-valida (`assertCanAccessSellerWallet`) de forma independente.

`llm-provider-adapter.ts` segue o mesmo "porta + adapters concretos + fábrica única" já usado por
`erp_integration/adapters/` (TASK-169): `LlmProviderAdapter` é a porta, `AnthropicLlmProviderAdapter`/
`OpenAiLlmProviderAdapter` são adapters de referência, e `resolveLlmProviderAdapter` é a única fábrica
que decide qual concreta responde — nenhum código de chamada instancia um adapter diretamente.

## Regras de negócio implementadas

- O payload enviado ao LLM é montado inteiramente a partir de dados já calculados e escopados por
  `organizationId`/`companyId`/`sellerId` via caminho Firestore (nunca um filtro vindo do cliente) —
  nunca dados brutos de pedidos, nunca dado de outra organização (`buildWalletSummaryPayload`).
- Prompt fixo (nunca gerado dinamicamente a partir de texto livre do vendedor) exige uma citação
  `[refs: código,...]` por afirmação e proíbe explicitamente introduzir números fora do payload.
- Validação pós-geração (`validateGeneratedSummary`) é a trava real, não apenas prompt engineering:
  rejeita qualquer número no texto que não corresponda (dentro de uma tolerância de 0.01) a um
  `numericValue` do payload, qualquer código de citação desconhecido, e qualquer resposta sem nenhuma
  citação — com uma única retentativa antes de falhar de forma controlada.
- O resumo nunca aciona ação comercial: `WalletSummary`/`WalletSummaryCard` são estritamente
  informativos, sem nenhum botão de desconto/contato/pedido.
- Falha de geração (provedor indisponível/não configurado, validação reprovada) é sempre um estado de
  erro recuperável (`WalletSummaryStatus.error`, com "Tentar novamente") — nunca um texto genérico
  exibido como se fosse real.
- Cache por vendedor/período (TTL de 60 minutos) reutilizado apenas se o hash do payload recém-montado
  bater com o que gerou o cache — uma mudança relevante nos dados (novo insight, agregado atualizado)
  invalida cedo, mesmo dentro do TTL. Uma tentativa recente com falha para o mesmo payload é limitada
  a uma nova tentativa a cada 5 minutos (`resource-exhausted`), controlando custo/frequência de
  chamadas ao provedor.
- RBAC: um vendedor sempre pode gerar o próprio resumo; OWNER/ADMIN podem gerar de qualquer vendedor;
  SALES_MANAGER apenas de um vendedor que compartilhe uma equipe com ele — mesmo padrão exato já
  usado por `decideOrderApproval` (TASK-103) — sempre re-validado server-side
  (`assertCanAccessSellerWallet`), nunca confiando no que o cliente afirma.

## Regras Firebase implementadas

`firestore.rules`: `organizations/{organizationId}/walletSummaries/{summaryId}` com
`allow read, write: if false` — o cache gerado pela IA nunca é lido diretamente por nenhum cliente
(nem OWNER/ADMIN), apenas através da resposta do próprio callable `generateWalletSummary`, que já
reaplica RBAC em toda chamada.

`generateWalletSummary` (Cloud Function callable): exige autenticação, recarrega a Membership real do
chamador (`loadActiveMembership`, nunca confia no client), e reaplica `assertCanAccessSellerWallet`
antes de montar qualquer payload ou tocar o cache.

## Analytics implementado

Dois eventos novos em `lib/core/analytics/analytics_events.dart`:
- `walletSummaryGenerated` — logado por `GenerateWalletSummaryUseCase` a cada resposta bem-sucedida
  (fresca ou em cache), com `organization_id`/`seller_id`/`from_cache`.
- `walletSummaryGenerationFailed` — logado a cada falha (permissão já é barrada antes deste ponto,
  então nunca loga uma negativa de RBAC; cobre falha de validação/provedor/rate-limit), com
  `organization_id`/`seller_id`/`failure_code`.

## Crashlytics implementado

Nenhum código novo de captura de exceção não tratada. Todo erro (rede, validação, RBAC, rate-limit) é
convertido em `AppFailure`/`Failure` pelo mesmo `_guard`/`mapAppExceptionToFailure` já usado por outras
`CloudFunctions*Repository` — nunca escapa como exceção não tratada. O `CrashReporter` global já
configurado em `bootstrap.dart` cobre qualquer erro verdadeiramente inesperado.

## Impacto offline

Nenhum, deliberadamente. Assim como `replenishment`/`demand_forecast`, o resumo de carteira é um
recurso gerado sob demanda que requer conectividade real (chamada a um LLM externo) — não há Outbox
nem cache Drift; o card mostra apenas seu próprio estado idle/carregando/erro/pronto, sem tentar
funcionar offline. Não há nenhuma decisão comercial de campo (pedido, preço, estoque) que dependa
desta feature funcionar offline.

## Impacto multi-tenant

Toda leitura do payload é escopada por `organizationId`/`companyId`/`sellerId` via caminho Firestore
(`organizations/{organizationId}/...`) dentro da própria Cloud Function — nunca um filtro vindo do
cliente. Testado explicitamente (`buildWalletSummaryPayload` — "scopes insights strictly to this
seller, never leaking another seller/org") que um insight de outro vendedor nunca aparece no payload
nem nos data points. O cache (`walletSummaries`) também vive sob `organizations/{organizationId}/...`
e nunca é lido fora da própria Cloud Function.

## Testes criados

TypeScript (`functions/`, **executados neste ambiente, sem emulador**):
- `wallet-summary-shared.test.ts` — 34 testes (ver "Arquivos criados").
- `llm-provider-adapter.test.ts` — 7 testes (ver "Arquivos criados").

Dart (`test/features/wallet_summary/`, **executados neste ambiente**):
- `generate_wallet_summary_use_case_test.dart` — 5 testes.
- `wallet_summary_cubit_test.dart` — 4 testes.
- `wallet_summary_card_test.dart` — 4 testes (idle/carregando/erro/pronto + expansão de referências).

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx jest test/wallet_summary
cd functions && npx eslint src test
cd functions && npm run build
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter analyze lib/features/wallet_summary test/features/wallet_summary
flutter test test/features/wallet_summary test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart test/core/analytics/analytics_events_test.dart
flutter test
dart format --set-exit-if-changed lib/features/wallet_summary test/features/wallet_summary lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart lib/features/dashboards/presentation/pages/representative_dashboard_page.dart test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart test/core/analytics/analytics_events_test.dart
```

## Resultado do formatter

`dart format --set-exit-if-changed` limpo (0 arquivos alterados na segunda execução) em todos os
arquivos Dart tocados por esta task, após reformatar (`wallet_summary_cubit.dart`,
`wallet_summary_card.dart` e três arquivos de teste novos) e confirmar.

## Resultado do analyzer

- `flutter analyze` (projeto inteiro): **17 issues, todas pré-existentes e fora do escopo desta task**
  (mesmas 17 já documentadas em TASK-184-CONCLUIDA.md: `use_null_aware_elements`/
  `deprecated_member_use` em arquivos não tocados por esta task). **Nenhum erro, nenhum issue novo.**
- `npx tsc --noEmit`/`npx eslint src test` (functions): limpos — apenas 4 warnings
  `@typescript-eslint/no-explicit-any` no fake de Firestore do teste `wallet-summary-shared.test.ts`
  (mesmo padrão de `any` já aceito em fakes de teste no restante do projeto). **Nenhum erro.**

## Resultado dos testes

- `npx jest test/wallet_summary` (functions): **41/41 passando** (34 de `wallet-summary-shared` + 7 de
  `llm-provider-adapter`).
- `flutter test test/features/wallet_summary test/features/dashboards/.../representative_dashboard_page_test.dart test/core/analytics/analytics_events_test.dart`:
  **17/17 passando** (13 da feature nova + 4 de arquivos alterados por esta task).
- `flutter test` (suíte completa do projeto): **3202/3203 passando**. A única falha
  (`test/app/bootstrap_test.dart`, "bootstrap initializes Firebase exactly once and renders
  VestiProApp") é **pré-existente e não relacionada a esta task**: mesmo sintoma exato já documentado
  em `TASK-184-implementar-replenishment-automatico-CONCLUIDA.md` (`PushDeviceMapper is not registered
  inside GetIt` / assertion do `firebase_crashlytics_platform_interface`), sem qualquer menção a
  `WalletSummaryCubit`/`GenerateWalletSummaryUseCase`/`CloudFunctionsWalletSummaryRepository` no stack
  trace — a falha vem inteiramente de `PushDeviceMapper`/`PushTokenService`/`FirebaseCrashlytics`,
  nenhum dos quais tocado por esta task.

## Decisões técnicas

**(a) Sem SDK novo de provedor de LLM.** `functions/package.json` não ganhou `@anthropic-ai/sdk` nem
`openai` — os dois adapters de referência (`AnthropicLlmProviderAdapter`/`OpenAiLlmProviderAdapter`)
chamam a API HTTP de cada provedor via `fetch` puro, exatamente como `whatsapp-shared.ts`'s
`sendMetaTemplateMessage` já faz para a API do WhatsApp — uma dependência a menos para auditar/manter
atualizada, com o mesmo `fetcher` injetável para testes que esse arquivo já usa.

**(b) `LlmProviderAdapter` plugável, resolvido por `WALLET_SUMMARY_LLM_PROVIDER`/segredo
`WALLET_SUMMARY_LLM_API_KEY`, nunca hardcoded.** Sem provedor configurado (ou sem chave), toda chamada
resolve para `DisabledLlmProviderAdapter`, que falha de forma controlada
(`LlmProviderNotConfiguredError`) sem nunca tentar uma chamada de rede — a arquitetura completa
(Cloud Function, contrato de payload, prompt, validação, cache, UI) é implementável e testável de
ponta a ponta sem qualquer credencial real; apenas a validação contra um provedor real de produção
fica pendente de quem tiver acesso para configurar o segredo (ver "Pendências"). Esta não é uma
decisão de contorno de bloqueio — é a arquitetura correta independentemente de credenciais existirem
ou não (o provedor sempre deve ser configurável, nunca fixo em código).

**(c) Payload reaproveita insights já computados (TASK-121) em vez de recalcular métricas.**
"Clientes inativos"/"risco"/"oportunidade" no resumo vêm dos insights `fresh` já ativos do próprio
vendedor (`recipientUserId == sellerId`), e o contexto de "atingimento de meta" vem do insight
`sellerBelowTarget` (TASK-131) filtrado por `sellerId` (que normalmente é endereçado ao gestor, não ao
vendedor — aqui lido independentemente do destinatário, apenas pelo `sellerId`, já que o dado em si é
sobre o vendedor). Decisão deliberada: `TargetAchievementSnapshot`/`PositivacaoSnapshot` (TASK-116) são
hoje calculados via um `achievedValueCache` do lado do Drift/cliente (ver
`drift_target_achievement_repository.dart`), sem uma Cloud Function server-side que os exponha
diretamente — reusar o insight `sellerBelowTarget` (que já tem sua própria pipeline 100% server-side,
`sales-rep-below-target-insight-rule.ts`) evita depender de um dado cuja fonte de verdade
server-side não está clara/disponível para esta Cloud Function, sem inventar um novo cálculo
duplicado de meta apenas para este resumo.

**(d) Cache/rate-limit em um único documento por (vendedor, período), nunca em um histórico.** Um novo
`generateWalletSummary` sempre sobrescreve (`set`, nunca `create`/append) o documento
`walletSummaries/{sellerId}_{periodKey}` — não existe histórico de resumos antigos, deliberadamente:
diferente de um insight ou uma sugestão de reposição, o resumo de carteira não é uma decisão a
auditar, é uma leitura descartável e regenerável a qualquer momento a partir dos mesmos dados-fonte
(que, esses sim, já são auditáveis em seus próprios lugares).

## Riscos conhecidos

- A trava anti-alucinação (`validateGeneratedSummary`) usa um parser de número tolerante
  (pt-BR e decimal simples) com uma tolerância de 0.01 — um provedor real que formate um número de
  forma muito distinta desses dois padrões (ex.: notação científica) seria erroneamente tratado como
  "alucinado" e rejeitado; dado o domínio (moeda/percentual/contagem), isso é considerado aceitável,
  mas só será confirmado com um provedor real (ver "Pendências").
- `assertCanAccessSellerWallet` (server-side) usa a mesma regra simplificada já estabelecida por
  `decide-order-approval.ts` (equipe do próprio gestor via `membership.teamIds`) — mais estrita que a
  regra Dart equivalente (`RepresentativeDashboardVisibilityService`, que também considera equipes
  onde o gestor é `managerUserId` mesmo sem estar em `teamIds`). Isso significa que, em um cenário raro
  (gestor gerencia uma equipe mas não está listado em `teamIds` dela), o client-side UX-check permitiria
  tentar gerar o resumo mas a Cloud Function negaria — um caso de erro visível ao usuário, nunca um
  furo de segurança (a Function é sempre mais restritiva, nunca mais permissiva, que a checagem
  client-side).

## Pendências

- **Ativação em produção com um provedor real de LLM:** configurar `WALLET_SUMMARY_LLM_PROVIDER`
  (`anthropic` ou `openai`) e o segredo `WALLET_SUMMARY_LLM_API_KEY`
  (`firebase functions:secrets:set WALLET_SUMMARY_LLM_API_KEY`), e então validar manualmente a
  qualidade/latência/custo real das respostas geradas — isto **não é um bloqueio de implementação**
  (a arquitetura está completa e testada), apenas uma etapa de configuração/validação que só quem tem
  acesso às credenciais/ao projeto Firebase de produção pode fazer.
- `decide-order-approval.ts`-style RBAC (nota "Riscos conhecidos" acima) poderia futuramente ser
  unificado com a regra mais completa de `RepresentativeDashboardVisibilityService` caso o time decida
  que vale a pena portar a checagem "gestor de equipe via `managerUserId`" para o lado das Cloud
  Functions — fora do escopo desta task (a regra usada aqui já é a mesma que `decideOrderApproval`
  usa há mais tempo em produção).
- Testes de integração contra o Firebase Emulator Suite para `generateWalletSummary` (RBAC ponta a
  ponta, cache real, Firestore Rules do `walletSummaries`) não foram escritos/executados nesta rodada
  — mesma limitação pré-existente já documentada em outras tasks recentes (sem Java/emulador
  disponível neste ambiente). A lógica de negócio equivalente está coberta pelos testes puros de
  `wallet-summary-shared.test.ts` com um fake de Firestore em memória.

## Evidências

Ver "Comandos executados"/"Resultado dos testes" acima — saídas completas disponíveis no histórico de
execução desta sessão.

## Commit

Ver hash abaixo.

## Push

Não realizado nesta rodada — push não autorizado.

## Hash do commit

(preenchido após commit)

## Branch

main
