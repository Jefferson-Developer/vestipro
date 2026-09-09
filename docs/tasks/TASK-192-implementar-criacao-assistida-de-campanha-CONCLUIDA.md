# TASK-192 — Concluída (2026-09-08)

## Resumo

Implementa a criação assistida de coleção/campanha via IA generativa (EPIC-28, último item): uma
Cloud Function (`assistCampaignCreation`) recebe parâmetros informados pelo admin/gestor
(productIds já selecionados no formulário de campanha, público-alvo, tom de comunicação e período)
e gera um rascunho estruturado — título, subtítulo/headline e descrição editorial — sempre
revisável antes de publicar, nunca publicado automaticamente. Todo produto citado no texto é
re-resolvido server-side contra `organizations/{organizationId}/products` (nome/categoria/coleção
apenas — nunca preço/desconto), e a resposta do modelo é reprovada/regenerada se citar um produto
fora da lista fornecida, se um produto citado não aparecer de fato no texto, ou se mencionar
qualquer termo comercial proibido (desconto, preço, condição especial etc.). No app, `CampaignFormPage`
(TASK-080) ganha a ação "Gerar sugestão com IA", que abre um bottom sheet coletando
público-alvo/tom, reaproveita os produtos relacionados e o período já preenchidos no formulário, e
— só quando o admin toca em "Usar sugestão" — pré-preenche os campos de título/subtítulo/descrição
já existentes do formulário, que continuam editáveis e só são publicados pelo fluxo de
"Criar campanha"/"Salvar alterações" já existente.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist` (checklist de UI: bottom sheet reaproveitando `AppBottomSheet`/
  `AppTextField`/`AppButton` do Design System, sem novo componente)

## Arquivos criados

- `functions/src/campaign_assist/campaign-assist-types.ts`
- `functions/src/campaign_assist/campaign-assist-shared.ts`
- `functions/src/campaign_assist/assist-campaign-creation.ts`
- `functions/src/campaign_assist/index.ts`
- `functions/test/campaign_assist/campaign-assist-shared.test.ts`
- `lib/features/campaign_assist/domain/entities/campaign_creation_draft.dart`
- `lib/features/campaign_assist/domain/repositories/campaign_assist_repository.dart`
- `lib/features/campaign_assist/domain/usecases/generate_campaign_creation_draft_use_case.dart`
- `lib/features/campaign_assist/data/repositories/cloud_functions_campaign_assist_repository.dart`
- `lib/features/campaign_assist/presentation/cubit/campaign_assist_cubit.dart`
- `lib/features/campaign_assist/presentation/cubit/campaign_assist_state.dart`
- `lib/features/campaign_assist/presentation/widgets/campaign_assist_sheet.dart`
- `lib/features/campaign_assist/campaign_assist.dart`
- `test/features/campaign_assist/domain/usecases/generate_campaign_creation_draft_use_case_test.dart`
- `test/features/campaign_assist/presentation/cubit/campaign_assist_cubit_test.dart`
- `docs/tasks/TASK-192-implementar-criacao-assistida-de-campanha-CONCLUIDA.md`

## Arquivos alterados

- `functions/src/index.ts` — exporta `assistCampaignCreation`.
- `firestore.rules` — nova coleção `campaignAssistDrafts` (`allow read, write: if false`, mesma
  forma "server owns every write" de `walletSummaries`/`approachSuggestions`/`reportExplanations`/
  `productImageEmbeddings`).
- `lib/core/analytics/analytics_events.dart` — `campaignAssistDraftGenerated`,
  `campaignAssistDraftGenerationFailed`.
- `lib/features/catalog/presentation/pages/campaign_form_page.dart` — novo parâmetro opcional
  `createCampaignAssistCubit` (na classe e em `.push()`), botão "Gerar sugestão com IA" e o helper
  `_showCampaignAssistSheet` que abre o sheet e, ao "Usar sugestão", dispara
  `CampaignFormTitleChanged`/`CampaignFormSubtitleChanged`/`CampaignFormDescriptionChanged` no
  `CampaignFormBloc` já existente.
- `lib/features/catalog/presentation/pages/campaigns_page.dart` — repassa o novo
  `createCampaignAssistCubit` opcional até `CampaignFormPage.push`.
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) para registrar
  `CloudFunctionsCampaignAssistRepository`, `GenerateCampaignCreationDraftUseCase` e
  `CampaignAssistCubit`.
- `test/core/analytics/analytics_events_test.dart` — inclui os 2 novos eventos na lista esperada.
- `test/features/catalog/presentation/pages/campaign_form_page_test.dart` — cobre o botão
  "Gerar sugestão com IA" ausente sem factory e o fluxo completo de geração + "Usar sugestão".

## Arquitetura utilizada

Clean Architecture/feature-first, mesmo padrão de TASK-186/187/189/190/191: `Presentation (Cubit) →
Use case → Repository contract → Repository impl (Cloud Functions) `. Sem datasource Firestore no
cliente — a única forma de obter um rascunho é a resposta do callable `assistCampaignCreation`,
exatamente como `ApproachSuggestionRepository`/`ReportExplanationRepository` já fazem. No backend,
`campaign-assist-shared.ts` é majoritariamente puro (só `loadCampaignAssistProductReferences` toca
Firestore, isolado do resto — mesma separação que `report-explanation-shared.ts` já usa entre payload
puro e a query real). A UI não duplica nenhum picker: reaproveita literalmente os `relatedProductIds`/
`startAt`/`endAt` já mantidos por `CampaignFormState` (TASK-080), só pedindo ao admin o que ainda não
existe no formulário (público-alvo, tom de comunicação).

## Regras de negócio implementadas

- Toda sugestão é sempre um rascunho: `assistCampaignCreation` nunca cria/edita/publica um
  `CatalogCampaign` — só devolve texto; a publicação continua exigindo o clique explícito em
  "Criar campanha"/"Salvar alterações" já existente (TASK-080).
- Payload enviado ao provedor de IA restrito aos dados reais da organização do admin autenticado:
  `loadCampaignAssistProductReferences` só lê `organizations/{organizationId}/products` do próprio
  chamador; qualquer `productId` que não pertença a essa organização (ou não exista) é
  silenciosamente descartado, nunca aceito às cegas.
- Nenhum dado de preço/estoque é lido ou enviado ao modelo — apenas nome/categoria/coleção do
  produto.
- Validação pós-geração (`validateGeneratedCampaignAssist`): resposta deve ser um JSON válido nos
  campos e tamanhos esperados; todo `productId` em `citedProductIds` deve existir nos produtos
  fornecidos (`unknown_reference` caso contrário); quando há citação, ao menos um dos produtos
  citados deve de fato ter seu nome mencionado no texto gerado (`unreferenced_citation` caso
  contrário) — o mecanismo de "citação obrigatória e verificável" já usado por
  `validateGeneratedApproachSuggestion`/`validateGeneratedReportExplanation`, adaptado de números
  para nomes de produto.
- Geração nunca cria preço, desconto ou condição comercial: reaproveita (não duplica)
  `FORBIDDEN_COMMERCIAL_TERMS` de `approach-suggestion-shared.ts` para rejeitar qualquer menção a
  desconto/cortesia/brinde/condição especial/etc. em título, subtítulo ou descrição.
- Uso de IA fica identificável para acompanhamento: `campaignAssistDraftGenerated`/
  `campaignAssistDraftGenerationFailed` (analytics) e o próprio texto "Rascunho gerado por IA —
  revise e edite antes de usar" no sheet.
- Autorização restrita a `OWNER`/`ADMIN` (`CAMPAIGN_ASSIST_ROLES`), mesmo escopo de
  `Capability.catalogManage` (`lib/core/permissions/capability.dart`) já exigido pela tela que abre
  o sheet — nunca confiado só do lado cliente: `assertCanAssistCampaignCreation` reavalia o
  `roleName` real da Membership ativa a cada chamada.

## Regras Firebase implementadas

- `firestore.rules`: `campaignAssistDrafts/{cacheKey}` — `allow read, write: if false` (deny-all,
  só Admin SDK), mesma forma das demais coleções de cache do EPIC-28.

## Analytics implementado

- `campaign_assist_draft_generated` (`GenerateCampaignCreationDraftUseCase`, sucesso — inclui
  `product_count`/`from_cache`, nunca o texto gerado).
- `campaign_assist_draft_generation_failed` (`GenerateCampaignCreationDraftUseCase`, falha —
  `failure_code`).

## Crashlytics implementado

Nenhuma mudança específica — erros seguem o mesmo caminho de `AppException`/`Failure` já tratado
pelo `_guard` do repositório e pelos handlers globais existentes.

## Impacto offline

Feature sempre online (mesma decisão documentada por `ApproachSuggestionRepository`/
`ReportExplanationRepository`): a chamada ao provedor de IA exige conectividade. Sem Outbox/sync —
não é uma mutação de dado de negócio persistente offline; o rascunho gerado só é "salvo de verdade"
quando o admin publica a campanha pelo fluxo já existente do TASK-080 (que sim é uma mutação local
via `SharedPreferencesCatalogCampaignRepository`, inalterado por esta task).

## Impacto multi-tenant

- `loadCampaignAssistProductReferences` só consulta `organizations/{organizationId}/products` do
  próprio chamador (path sempre escopado, nunca um filtro que o cliente possa manipular para ler
  produto de outra organização); um `productId` de outra organização estruturalmente nunca resolve
  nesse path, então nunca aparece em `productReferences`.
- Cache (`campaignAssistDrafts`) sempre gravado sob `organizations/{organizationId}/...` e chaveado
  por `sha256(requesterUid|payloadHash)` — dois admins (ou o mesmo admin com parâmetros diferentes)
  nunca colidem no mesmo cache entry.
- RBAC (`OWNER`/`ADMIN`) sempre revalidado a partir da Membership real do chamador, nunca do que o
  cliente afirma.

## Testes criados

- **Functions (Jest)**: `campaign-assist-shared.test.ts` (32 casos — resolução de produtos reais
  vs. inexistentes vs. de outra organização, formatação de período, truncamento defensivo de
  payload, hash estável por conteúdo, cache key por requester+hash, prompt sempre JSON-only e sem
  omitir produto, RBAC OWNER/ADMIN vs. demais papéis, e toda a árvore de validação: JSON inválido,
  campo fora do tamanho, produto citado inexistente, citação nunca mencionada no texto, termos
  comerciais proibidos, e o caminho feliz com/sem produtos).
- **Flutter**: `generate_campaign_creation_draft_use_case_test.dart` (sucesso + dedupe de
  productIds + analytics, validação de campos obrigatórios, `endAt` antes de `startAt`, propagação
  de falha), `campaign_assist_cubit_test.dart` (idle/loading/ready/error, reset).
- **Widget**: `campaign_form_page_test.dart` ganhou 2 casos novos — botão ausente sem factory, e o
  fluxo completo (abrir sheet, preencher público-alvo/tom, gerar, "Usar sugestão" preenchendo
  título/subtítulo/descrição do formulário).
- Não foi criado teste direto para a Cloud Function `assistCampaignCreation` (que depende de
  Firestore/Secret Manager via Admin SDK) — mesmo padrão já aceito em TASK-186/187/189/190/191
  (`generate-approach-suggestion.ts`/`explain-report.ts` também não têm teste unitário direto, só
  seus módulos `-shared.ts`).

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx eslint src/campaign_assist test/campaign_assist
cd functions && npx jest test/campaign_assist
cd functions && npx jest
dart run build_runner build
flutter analyze
flutter analyze lib/features/campaign_assist lib/features/catalog/presentation/pages/campaign_form_page.dart lib/features/catalog/presentation/pages/campaigns_page.dart lib/core/analytics/analytics_events.dart
dart format --set-exit-if-changed .
flutter test test/features/campaign_assist
flutter test test/core/analytics/analytics_events_test.dart test/features/catalog/presentation/pages/campaigns_page_test.dart test/features/catalog/presentation/pages/campaign_form_page_test.dart
flutter test
git stash -u && flutter test test/app/bootstrap_test.dart && git stash pop
```

## Resultado do formatter

`dart format --set-exit-if-changed .` reformatou 4 arquivos fora do escopo desta task (drift
pré-existente em `locale_settings_page.dart`, `cart_share_sheet.dart` e dois testes de
`product_import`) — revertidos via `git checkout --` (AGENTS.md: "Não alterar arquivos fora do
escopo"). Nenhum arquivo desta task precisou de reformatação após a primeira rodada.

## Resultado do analyzer

- `flutter analyze` (projeto completo): **18 issues, todos `info` pré-existentes** (nenhum error;
  nenhum deles em arquivo tocado por esta task — mesma contagem/tipo já documentada na conclusão da
  TASK-191).
- `flutter analyze` nos arquivos desta task: **No issues found!**
- `npx tsc --noEmit` (functions): sem erros.
- `npx eslint` nos arquivos novos: **0 erros** (1 warning `no-explicit-any` no arquivo de teste, o
  mesmo padrão já aceito em `approach-suggestion-shared.test.ts`/`report-explanation-shared.test.ts`).

## Resultado dos testes

- `npx jest test/campaign_assist`: **32/32 passando**.
- `npx jest` (suíte completa de `functions`): **520 passando, 182 falhando em 29 suítes** — todas
  as falhas dependem do Firebase Emulator Suite (Firestore/Storage), que não roda neste ambiente
  por falta de Java (`java: command not found`) — mesma limitação documentada nas conclusões de
  TASK-190/TASK-191. Nenhuma falha é dos arquivos criados nesta task (suíte `campaign_assist`
  isolada passa 100%).
- `flutter test test/features/campaign_assist`: **8/8 passando**.
- `flutter test test/core/analytics/analytics_events_test.dart test/features/catalog/presentation/pages/campaigns_page_test.dart test/features/catalog/presentation/pages/campaign_form_page_test.dart`:
  **16/16 passando**.
- `flutter test` (suíte completa do projeto): **3266/3267 passando** — a única falha
  (`test/app/bootstrap_test.dart`) foi confirmada **pré-existente** via `git stash -u` (falha
  idêntica sem nenhuma mudança desta task) — nada relacionado a `campaign_assist`.

## Decisões técnicas

- **Reaproveitar os campos já existentes de `CampaignFormState`** (`relatedProducts`/`startAt`/
  `endAt`) em vez de pedir ao admin para selecionar produtos/período de novo dentro do sheet de IA —
  o sheet só coleta o que ainda não existe no formulário (público-alvo, tom de comunicação),
  evitando duplicar o picker de produtos (`ProductSearchPage`) já usado por `CampaignFormBloc`.
- **Saída do LLM como JSON estruturado** (`{title, subtitle, description, citedProductIds}`) em vez
  do formato "prosa com `[refs: ...]`" usado por TASK-186/187/189 — necessário porque esta feature
  precisa de 3 campos distintos (nome/headline/descrição) e não de um único texto corrido;
  `citedProductIds` cumpre o mesmo papel de rastreabilidade que os códigos de citação numérica
  cumprem nas demais features (mecanismo verificável de "todo produto citado existe e é mencionado
  de fato").
- **Cache chaveado por `requesterUid + hash do payload`** (não por uma única entidade como
  `customerId` em `approachSuggestions`) — uma campanha em criação não tem um id estável até ser
  salva; mesmo padrão já usado por `reportExplanationCacheKey` (TASK-189) para relatórios ad-hoc
  ainda em construção no construtor.
- **`collectionId` do parâmetro "produtos/coleção" do escopo original não foi implementado como
  fonte server-side de expansão de produtos** — `Collection` (TASK-066) só tem persistência local
  (`SharedPreferencesCollectionRepository`), sem um documento Firestore verificável que o servidor
  possa ler com segurança; implementar essa expansão exigiria antes dar a `Collection` uma
  persistência real (fora do escopo desta task). O parâmetro "produtos selecionados" continua
  atendido via `productIds` (já suficiente, dado que o admin sempre seleciona produtos concretos no
  formulário antes de gerar a sugestão).

## Riscos conhecidos

- O adapter LLM (Anthropic/OpenAI, reaproveitado de `llm-provider-adapter.ts`) permanece
  **desabilitado por padrão** (`CAMPAIGN_ASSIST_LLM_PROVIDER=disabled`) — habilitar em produção
  exige quem administra o projeto Firebase: (1) `firebase functions:secrets:set
  CAMPAIGN_ASSIST_LLM_API_KEY`; (2) definir `CAMPAIGN_ASSIST_LLM_PROVIDER=anthropic|openai`. Sem
  isso, toda chamada falha de forma clara e recuperável (`unavailable`/mensagem explicativa), nunca
  silenciosamente.
- A checagem `unreferenced_citation` exige que **ao menos um** (não todos) dos produtos citados
  tenha seu nome mencionado no texto — uma citação parcialmente "solta" entre vários produtos pode
  passar; documentado como o mesmo tipo de risco residual que `validateGeneratedApproachSuggestion`
  já assume para atributos de produto não numéricos (o mecanismo prova ausência de invenção de
  `productId`, não prova 100% de aderência textual de cada citação).
- Testes de `firestore.rules` para `campaignAssistDrafts` não foram escritos isoladamente (é um
  `allow read, write: if false` trivial, mesmo padrão já não testado individualmente para
  `walletSummaries`/`approachSuggestions`/`reportExplanations`/`productImageEmbeddings`).

## Pendências

- Habilitar o provedor LLM em produção (variáveis de ambiente + secret) é uma decisão/ação de quem
  administra o projeto GCP/Firebase da organização.
- Dar a `Collection` (TASK-066) uma persistência Firestore real destravaria uma futura expansão de
  "gerar a partir de uma coleção inteira" (não apenas de produtos individualmente selecionados),
  hoje fora do escopo por falta de fonte server-side confiável.

## Evidências

- `functions/src/campaign_assist/*.ts`
- `lib/features/campaign_assist/**`
- Saídas de comandos reproduzidas na seção "Resultado dos testes" acima.

## Commit

`feat(campaign-assist): implementa criacao assistida de campanha via IA (TASK-192)`

## Push

Não realizado nesta rodada — push não autorizado.

## Hash do commit

(preenchido após o commit — ver seção final da resposta)

## Branch

`main`
