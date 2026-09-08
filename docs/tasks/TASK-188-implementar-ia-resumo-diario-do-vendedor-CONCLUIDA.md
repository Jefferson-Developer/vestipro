# TASK-188 — Concluída (2026-09-07)

## Resumo

Implementado o "resumo diário do vendedor" (EPIC-28, IA generativa): uma Cloud Function agendada
(`generateDailyRepSummary`, 07:00 `America/Sao_Paulo`) que, por organização/empresa, monta um payload
estruturado com desempenho de vendas do dia, risco de meta, pedidos rejeitados ainda relevantes e
insights prioritários já calculados — reaproveitando integralmente a infraestrutura de IA generativa
extraída nas TASK-186/TASK-187 (`shared/llm-provider-adapter.ts`, `shared/citation-validation.ts`,
`shared/team-membership.ts`) — gera o texto via LLM com a mesma validação anti-alucinação numérica,
persiste o resultado (histórico do dia) e dispara uma notificação interna (`commercial`/`inApp`)
respeitando preferências de comunicação e quiet hours (TASK-154/TASK-155). Um novo callable
`getDailyRepSummary` expõe a leitura (nunca a geração) do resumo do dia para o próprio vendedor ou
gestor autorizado. No Flutter, um card "Resumo do dia" foi adicionado fixo no topo do dashboard do
representante (`RepresentativeDashboardPage`), carregando automaticamente ao abrir a tela.

## Agentes utilizados

- `flutter-senior-architect` (Cloud Function agendada, callable, RBAC, Firestore Rules, notificações,
  domínio/dados/BLoC Flutter)
- `flutter-ui-design-specialist` (card "Resumo do dia", estados loading/vazio/erro/pronto)

## Arquivos criados

Cloud Functions (`functions/src/daily_rep_summary/`):

- `daily-rep-summary-types.ts` — vocabulário compartilhado (payload, data points, referências, doc de
  cache/histórico).
- `daily-rep-summary-shared.ts` — montagem pura do payload a partir de dados já buscados por empresa,
  prompt fixo, validação anti-alucinação + termos comerciais proibidos (reaproveitados de
  `approach_suggestion`), RBAC (`assertCanAccessDailyRepSummary`, mesmo formato de
  `assertCanAccessSellerWallet`/`assertCanAccessCustomer`).
- `daily-rep-summary-notification.ts` — porta server-side (TS) das regras TASK-154/TASK-155 de
  preferência de comunicação (`categories.commercial.inApp`) e quiet hours
  (`QuietHours.isActiveAt`/`nextAllowedInstant`), já que todo gerador de notificação existente roda
  no cliente (Dart) e esta é a primeira Cloud Function a escrever a central de notificações
  diretamente.
- `generate-daily-rep-summary.ts` — `onSchedule` (07:00, `America/Sao_Paulo`,
  `southamerica-east1`): por organização ativa → por empresa ativa (`listActiveCompanyIds`, já
  existente em `aggregations/aggregation-data-source.ts`) → lê `insights` (`status: fresh`),
  `orders` (`status: rejected`, não deletados) e `sellerDailyAggregates` (dia atual) uma vez por
  empresa, deriva o conjunto de vendedores com algum sinal hoje, resolve nomes de vendedor/cliente
  em lote (`db.getAll`), e para cada vendedor ainda não processado hoje (idempotência por existência
  do documento) monta o payload, chama o adapter de LLM configurável, valida, persiste e tenta
  disparar a notificação.
- `get-daily-rep-summary.ts` — `onCall`: lê (nunca gera) o documento persistido para
  `sellerId`/`dateKey` (padrão: hoje), com o mesmo RBAC de leitura.
- `index.ts` — barrel.

Flutter (`lib/features/daily_rep_summary/`):

- `domain/entities/daily_rep_summary.dart`, `domain/entities/daily_rep_summary_reference.dart`
- `domain/repositories/daily_rep_summary_repository.dart`
- `domain/usecases/load_daily_rep_summary_use_case.dart` (RBAC de UX via
  `RepresentativeDashboardVisibilityService`, mesmo padrão de `GenerateWalletSummaryUseCase`)
- `data/repositories/cloud_functions_daily_rep_summary_repository.dart`
- `presentation/cubit/daily_rep_summary_state.dart`, `presentation/cubit/daily_rep_summary_cubit.dart`
  (carrega automaticamente ao ser criado — diferente do `WalletSummaryCubit`, que só chama o backend
  sob demanda, pois esta leitura nunca aciona um LLM)
- `presentation/widgets/daily_rep_summary_card.dart` — card com estados loading/erro/pronto (com
  citações expansíveis, mesmo padrão de `WalletSummaryCard`)/vazio ("nada urgente hoje")/ainda não
  gerado.
- `daily_rep_summary.dart` (barrel)

Documentação:

- `docs/tasks/TASK-188-implementar-ia-resumo-diario-do-vendedor-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `functions/src/index.ts` — exporta `generateDailyRepSummary`/`getDailyRepSummary`.
- `firestore.rules` — nova seção `organizations/{organizationId}/dailyRepSummaries/{summaryId}`
  (`allow read, write: if false`, mesmo padrão deny-all de `walletSummaries`/`approachSuggestions` —
  todo acesso passa por `getDailyRepSummary`).
- `lib/features/dashboards/presentation/pages/representative_dashboard_page.dart` — novo
  `createDailyRepSummaryCubit`, `DailyRepSummaryCard()` fixo no topo do corpo do dashboard (antes do
  banner de atualização).
- `lib/app/bootstrap.dart` — import do novo barrel + `createDailyRepSummaryCubit: () =>
  getIt<DailyRepSummaryCubit>()`.
- `lib/core/analytics/analytics_events.dart` — novos eventos `dailyRepSummaryViewed`/
  `dailyRepSummaryLoadFailed` (e na lista fixa `values`).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (novos bindings
  `CloudFunctionsDailyRepSummaryRepository`/`LoadDailyRepSummaryUseCase`/`DailyRepSummaryCubit`).
- `test/core/analytics/analytics_events_test.dart` — lista fixa de eventos atualizada com os 2 novos.
- `test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart` — novo
  parâmetro obrigatório `createDailyRepSummaryCubit` construído com um fake
  `DailyRepSummaryRepository` (o card carrega automaticamente, diferente do `WalletSummaryCubit`, que
  só é acionado sob demanda) e stub de `MembershipRepository` para o caminho de autoacesso.

## Arquitetura utilizada

Mesmo formato "core de cálculo puro e testável + wrapper onCall/onSchedule fino" de
`wallet-summary-shared.ts`/`approach-suggestion-shared.ts` (TASK-186/187): `daily-rep-summary-shared.ts`
não acessa o Firestore diretamente — recebe os documentos já lidos (uma vez por empresa) e monta o
payload por vendedor de forma pura. A varredura de vendedores usa apenas dados já indexados e
existentes (nenhum índice novo em `firestore.indexes.json` foi necessário): `insights`
(`companyId`+`status`), `orders` (`companyId`+`deletedAt`+`status`+`createdAt desc`, índice composto
já existente) e `sellerDailyAggregates` (`companyId`+`periodKey`).

No Flutter, Clean Architecture feature-first idêntica a `wallet_summary`/`approach_suggestion`:
presentation (Cubit) → use case → repository (contrato) → repository (Cloud Functions) — sem
datasource local/offline, pelo mesmo motivo dessas duas features (o resumo é sempre server-side).

## Regras de negócio implementadas

- Payload monta-se exclusivamente a partir de dados já calculados/persistidos server-side (nenhum
  cálculo novo introduzido por esta task).
- Validação pós-geração: toda citação `[refs: ...]` deve existir no payload; todo número no texto
  deve corresponder a um valor conhecido; nenhum termo comercial proibido (desconto, cortesia,
  promoção, "garantimos" etc. — lista reaproveitada de `approach_suggestion`) pode aparecer, já que
  este resumo é despachado automaticamente como notificação, sem revisão humana antes do envio
  (diferente do rascunho editável de `suggestApproach`).
- Idempotência: a mera existência do documento
  `organizations/{organizationId}/dailyRepSummaries/{sellerId}_{dateKey}` (status `ready`, `empty` ou
  `error`) impede reprocessamento e nova notificação no mesmo dia.
- Estado "vazio" tratado: quando não há risco de meta, pedido com problema, insight nem venda hoje,
  nenhuma chamada ao provedor de LLM é feita e nenhuma notificação é disparada — nunca se fabrica um
  resumo do nada.
- Falha de geração nunca bloqueia a home: `getDailyRepSummary` devolve `not_generated_yet`/`error`
  como estados tratados, nunca uma exceção que quebre o dashboard.
- Notificação respeita `communicationPreferences` (categoria `commercial`, canal `inApp`) e quiet
  hours (deliverAt futuro quando dentro da janela) — porta fiel, em TypeScript, das mesmas regras já
  usadas pelos 4 geradores client-side existentes (TASK-154/TASK-155), já que esta é a primeira Cloud
  Function a escrever a central de notificações diretamente.
- RBAC de leitura: o próprio vendedor, OWNER/ADMIN, ou um SALES_MANAGER que compartilhe equipe com o
  vendedor — mesmo formato de `assertCanAccessSellerWallet`/`assertCanAccessCustomer`.

## Regras Firebase implementadas

- `firestore.rules`: `organizations/{organizationId}/dailyRepSummaries/{summaryId}` — leitura e
  escrita negadas para qualquer cliente (deny-all); toda escrita é feita pela Cloud Function agendada
  via Admin SDK (que ignora as Rules), e toda leitura passa por `getDailyRepSummary` (que já
  reaplica o RBAC).
- Nenhum índice novo em `firestore.indexes.json` — todas as consultas usam apenas filtros de
  igualdade (sem índice composto necessário) ou o índice composto de `orders`
  (`companyId`+`deletedAt`+`status`+`createdAt desc`) já existente.

## Analytics implementado

- `dailyRepSummaryViewed` (status `ready`/`empty`/`error`/`notGeneratedYet` como parâmetro) e
  `dailyRepSummaryLoadFailed` (`failure_code`), logados por `LoadDailyRepSummaryUseCase` — mesmo
  padrão de `walletSummaryGenerated`/`walletSummaryGenerationFailed`. Nenhum texto livre/PII é
  carregado como parâmetro.

## Crashlytics

Nenhuma integração nova de Crashlytics — segue o mesmo padrão de `wallet_summary`/
`approach_suggestion` (falhas são tratadas como `Failure`/estado de UI, não exceções não capturadas).

## Impacto offline

Nenhum — mesma decisão de `wallet_summary`/`approach_suggestion`: o resumo é sempre gerado/lido
server-side (a geração é uma chamada de LLM agendada; a leitura exige conectividade). Uma falha de
rede na leitura aparece como o estado `error` do card, sem perder dados nem travar a home.

## Impacto multi-tenant

Toda leitura/escrita é escopada por `organizations/{organizationId}` e, dentro dela, por
`companyId`/`sellerId` já presentes nos documentos de origem (`insights`, `orders`,
`sellerDailyAggregates`) — nenhuma consulta cruza organização, e o payload de um vendedor nunca
inclui um fato de outro vendedor/empresa.

## Testes criados

Nenhum teste novo dedicado foi criado nesta execução (protocolo desta rodada não exige testes como
etapa obrigatória de encerramento). Validações reais executadas em vez disso:

- `npx tsc --noEmit` (Cloud Functions) — limpo.
- `npx eslint src/daily_rep_summary` — limpo.
- `npx jest test/wallet_summary test/approach_suggestion` — 59/59 passando (sanity check por
  reaproveitar `FORBIDDEN_COMMERCIAL_TERMS` de `approach_suggestion` e o mesmo padrão de
  `shared/llm-provider-adapter.ts`/`shared/citation-validation.ts`/`shared/team-membership.ts`, sem
  alterar nenhum desses arquivos).
- `npx jest` (suíte completa) — mesma contagem de falhas (182 falhando, 427 passando, 609 total) com
  e sem as mudanças desta task (`git stash`/`git stash pop` comparativo) — confirma que as falhas
  pré-existentes (testes que dependem do Firestore Emulator, indisponível nesta sessão) não têm
  relação com esta task.
- `flutter analyze` (projeto completo) — 0 erros; os 17 infos remanescentes já existiam antes desta
  task (deprecação de `RadioListTile` em `report_builder_page.dart` e `use_null_aware_elements` em
  testes pré-existentes).
- `dart format --output=none --set-exit-if-changed` nos arquivos criados/alterados — sem alterações
  pendentes.
- `dart run build_runner build` — regenerou `lib/app/injection.config.dart` com sucesso (os avisos de
  "missing dependencies" impressos são pré-existentes, confirmados também no `git stash` comparativo).
- `flutter test test/features/dashboards test/core/analytics` — 207/207 passando, incluindo o arquivo
  de teste que precisou ser ajustado (`representative_dashboard_page_test.dart`, novo parâmetro
  obrigatório) e a lista fixa de eventos (`analytics_events_test.dart`).
- `flutter test test/features/wallet_summary test/features/approach_suggestion` — 25/25 passando
  (sanity check equivalente do lado Flutter).

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx eslint src/daily_rep_summary
cd functions && npx jest test/wallet_summary test/approach_suggestion
cd functions && npx jest
cd functions && git stash && npx jest && git stash pop   # comparativo, confirma falhas pré-existentes
dart run build_runner build
flutter analyze
flutter analyze lib/features/daily_rep_summary lib/features/dashboards/presentation/pages/representative_dashboard_page.dart lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart
flutter analyze test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart
dart format --output=none --set-exit-if-changed lib/features/daily_rep_summary lib/features/dashboards/presentation/pages/representative_dashboard_page.dart lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart test/features/dashboards/presentation/pages/representative_dashboard_page_test.dart
flutter test test/features/dashboards test/core/analytics
flutter test test/features/wallet_summary test/features/approach_suggestion
```

## Resultado do formatter

`dart format` não alterou nenhum arquivo criado/alterado após o ajuste inicial (o único arquivo
alterado por uma passada de formatação foi `daily_rep_summary_card.dart`, uma quebra de linha do
`Icon(...)`).

## Resultado do analyzer

`flutter analyze` (projeto inteiro): 0 erros; 17 infos, todos pré-existentes e sem relação com esta
task (confirmados na mesma varredura anterior a esta execução).

## Resultado dos testes

- `flutter test test/features/dashboards test/core/analytics`: 207/207 passando.
- `flutter test test/features/wallet_summary test/features/approach_suggestion`: 25/25 passando.
- `npx jest test/wallet_summary test/approach_suggestion` (functions): 59/59 passando.
- `npx jest` (functions, suíte completa): 427/609 passando — as 182 falhas restam idênticas com e sem
  esta task (dependem do Firestore Emulator, indisponível nesta sessão); nenhuma delas menciona
  `daily_rep_summary`.

## Decisões técnicas

- **"Atingimento de meta" vem do insight `sellerBelowTarget` (TASK-131), não de `TargetsTable`**:
  `Target`/`achievedValueCache` (TASK-114/115/116) são persistidos apenas localmente
  (`SharedPreferencesTargetRepository`/Drift, sem Firestore/Outbox — lacuna já documentada na própria
  TASK-116), então uma Cloud Function não consegue lê-los. Em vez de deixar a seção de meta sempre
  ausente, esta task reaproveita o precedente já estabelecido pela TASK-186
  (`wallet-summary-shared.ts`'s `extractTargetRisk`): o insight `sellerBelowTarget`
  (`insights` com `sellerId`+`type: 'sellerBelowTarget'`) já carrega `target_value`/`realized_value`/
  `projected_achievement_percentage` como evidência server-side real, e o próprio `generateWalletSummary`
  já entrega esse mesmo conteúdo diretamente ao vendedor quando ele pede o próprio resumo de carteira
  — precedente já em produção que esta task apenas repete.
- **Follow-ups do dia ficam sempre vazios (`followUpsToday: []`)**: `CrmTask` (TASK-152) também não
  tem persistência Firestore/Outbox (`SharedPreferencesCrmTaskRepository`, local-only) — mesma classe
  de lacuna que `ApproachSuggestionPayload.recentOutcomeReason` já documenta para Opportunities
  (TASK-187). O tipo `DailyRepSummaryFollowUpHighlight`/campo `followUpsToday` foi mantido (nunca
  removido) para que uma task futura que dê a `CrmTask` persistência Firestore real possa populá-lo
  sem quebrar o contrato de payload/prompt.
- **Enumeração de vendedores por sinal, não por `Membership.companyIds`**: o campo `companyIds` do
  documento `members` nunca é de fato escrito por nenhuma Cloud Function hoje (confirmado por busca
  em todo `functions/src`) — apenas lido defensivamente/anulado em dois lugares. Sem uma fonte
  confiável de "qual(is) empresa(s) este vendedor atende", a enumeração usa, por empresa ativa
  (`listActiveCompanyIds`, já existente), a união de vendedores presentes em `insights`
  (`recipientUserId`/`sellerId` do tipo `sellerBelowTarget`), `sellerDailyAggregates` de hoje
  (`scopeId`) e `orders` rejeitados (`sellerId`) — todos já escopados por `companyId` nos próprios
  documentos. Um vendedor sem nenhum sinal hoje (sem meta em risco, sem pedido rejeitado, sem
  insight, sem venda) não gera um documento `empty` explícito, mas o resultado prático é idêntico ao
  que geraria (nenhuma notificação, nenhum dado a mostrar) — o card do lado do cliente já trata esse
  caso como `not_generated_yet`, uma mensagem igualmente amigável (não idêntica a "nada urgente
  hoje", mas com o mesmo efeito prático de não sinalizar nada pendente).
- **Vocabulário proibido reaproveitado de `approach_suggestion` por importação direta**
  (`FORBIDDEN_COMMERCIAL_TERMS`), não copiado — esta notificação é despachada automaticamente sem
  revisão humana, então precisa da mesma barreira contra menção a desconto/preço/promessa contratual
  que o rascunho de abordagem já aplica.
- **Card carrega automaticamente (diferente do `WalletSummaryCard`)**: a leitura nunca aciona um LLM
  (o resumo já foi gerado pela Cloud Function agendada horas antes), então não há custo/latência a
  proteger atrás de um botão — mostrar o resumo assim que a home abre é o comportamento esperado de
  "card fixo no topo da home".

## Riscos conhecidos

- **Seção de meta/atingimento só aparece quando existe um insight `sellerBelowTarget` ativo para o
  vendedor** (isto é: quando ele está abaixo do ritmo) — um vendedor no ritmo ou sem meta cadastrada
  nunca verá essa seção, mesma limitação que `WalletSummaryCard` já tem em produção hoje (não é uma
  regressão introduzida por esta task).
- **Follow-ups do dia nunca aparecem** até que uma task futura dê a `CrmTask` persistência Firestore
  real (ver "Decisões técnicas").
- **Sem teste automatizado dedicado** para `daily-rep-summary-shared.ts`/
  `daily-rep-summary-notification.ts`/`generate-daily-rep-summary.ts`/`get-daily-rep-summary.ts` nem
  para os arquivos Flutter novos — os pontos de maior risco de regressão silenciosa seriam: (1) a
  porta TypeScript de quiet hours nunca divergir da implementação Dart original; (2) a idempotência
  por-dia realmente nunca duplicar notificação; (3) a validação anti-alucinação/termos proibidos
  rejeitar corretamente um texto malformado. `npx tsc --noEmit` + `npx eslint` confirmam que o código
  compila e não viola nenhuma regra de lint, mas não substituem um teste de comportamento.
- **Ativação em produção depende de credencial de provedor de LLM**: a arquitetura completa (Cloud
  Function agendada, prompt, contrato de dados, validação, UI) está implementada com a chamada ao
  provedor abstraída atrás do `shared/llm-provider-adapter.ts` já existente — sem hardcode de
  segredo, sem chamada real sem credencial. Até alguém configurar
  `DAILY_REP_SUMMARY_LLM_PROVIDER`/o segredo `DAILY_REP_SUMMARY_LLM_API_KEY`
  (`firebase functions:secrets:set DAILY_REP_SUMMARY_LLM_API_KEY`), todo dia o resumo de cada
  vendedor com dados não-vazios resolve para o estado `error` (`DisabledLlmProviderAdapter`), tratado
  pelo card como um estado normal ("um novo resumo é gerado automaticamente amanhã") — nunca um crash
  nem um dado fabricado.
- **`AppNotificationBellButton`/central de notificações continuam sem estar conectados a nenhum shell
  de navegação real** (lacuna já registrada desde TASK-151) — a notificação desta task é persistida
  corretamente na central, mas o único jeito de vê-la hoje é abrir `NotificationCenterRoute`
  diretamente.
- Push (`git push`) não realizado nesta rodada — não autorizado.

## Pendências

- Popular `followUpsToday` quando `CrmTask` ganhar persistência Firestore/Outbox real (task futura).
- Testes automatizados dedicados para os novos módulos (ver "Riscos conhecidos").
- Conectar a central de notificações/`AppNotificationBellButton` a um shell de navegação real
  (pendência pré-existente desde TASK-151, não introduzida aqui).

## Evidências

Ver seção "Resultado dos testes"/"Comandos executados" acima — todos executados nesta sessão.

## Commit

Único commit local cobrindo toda a task (código + documentação + atualização de `TASKS.md`).

## Push

Não realizado — não autorizado nesta rodada.

## Hash do commit

Ver `docs/tasks/TASKS.md` (linha do commit) / saída de `git log -1` logo após o commit desta task.

## Branch

`main`
