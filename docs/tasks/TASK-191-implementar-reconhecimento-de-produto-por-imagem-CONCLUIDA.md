# TASK-191 — Concluída (2026-09-08)

## Resumo

Implementa o reconhecimento de produto por imagem (EPIC-28): uma Cloud Function
(`indexProductImageEmbedding`, trigger de Storage) indexa o embedding de cada foto de produto no
momento do upload; outra (`recognizeProductImage`, callable) recebe a foto capturada pelo
vendedor/cliente, gera seu embedding e compara por similaridade de cosseno contra o índice da
própria organização, retornando sempre uma lista de candidatos ordenada por score — nunca uma
resposta única forçada — e explicitando quando nenhum candidato atinge o limiar mínimo de
confiança. Uma terceira função (`submitProductRecognitionFeedback`) registra o feedback
"era este"/"não era nenhum" do vendedor para acompanhamento de qualidade. No app, a tela
"Identificar produto por foto" (`ProductRecognitionPage`) captura a imagem via `image_picker`
(câmera ou galeria), mostra os candidatos e permite abrir o produto ou tentar novamente.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `functions/src/shared/image-embedding-provider-adapter.ts`
- `functions/src/product_recognition/product-recognition-shared.ts`
- `functions/src/product_recognition/product-recognition-data-source.ts`
- `functions/src/product_recognition/index-product-image-embedding.ts`
- `functions/src/product_recognition/recognize-product-image.ts`
- `functions/src/product_recognition/submit-product-recognition-feedback.ts`
- `functions/src/product_recognition/index.ts`
- `functions/test/shared/image-embedding-provider-adapter.test.ts`
- `functions/test/product_recognition/product-recognition-shared.test.ts`
- `lib/features/product_recognition/domain/entities/product_recognition_candidate.dart`
- `lib/features/product_recognition/domain/entities/product_recognition_result.dart`
- `lib/features/product_recognition/domain/value_objects/product_recognition_feedback_outcome.dart`
- `lib/features/product_recognition/domain/repositories/product_recognition_repository.dart`
- `lib/features/product_recognition/domain/usecases/recognize_product_image_use_case.dart`
- `lib/features/product_recognition/domain/usecases/submit_product_recognition_feedback_use_case.dart`
- `lib/features/product_recognition/data/repositories/cloud_functions_product_recognition_repository.dart`
- `lib/features/product_recognition/presentation/cubit/product_recognition_cubit.dart`
- `lib/features/product_recognition/presentation/cubit/product_recognition_state.dart`
- `lib/features/product_recognition/presentation/pages/product_recognition_page.dart`
- `lib/features/product_recognition/product_recognition.dart`
- `test/features/product_recognition/domain/usecases/recognize_product_image_use_case_test.dart`
- `test/features/product_recognition/domain/usecases/submit_product_recognition_feedback_use_case_test.dart`
- `test/features/product_recognition/presentation/cubit/product_recognition_cubit_test.dart`
- `docs/tasks/TASK-191-implementar-reconhecimento-de-produto-por-imagem-CONCLUIDA.md`

## Arquivos alterados

- `functions/src/index.ts` — exporta `recognizeProductImage`, `submitProductRecognitionFeedback`,
  `indexProductImageEmbedding`, `removeProductImageEmbeddingOnDelete`.
- `functions/package.json` / `functions/package-lock.json` — `google-auth-library` como
  dependência direta (antes só transitiva de `firebase-admin`), usada pelo adapter Vertex AI para
  obter um token via Application Default Credentials.
- `firestore.rules` — novas coleções `productImageEmbeddings`/`productRecognitionAttempts`
  (`allow read, write: if false`, mesma forma "server owns every write" de `walletSummaries`/
  `approachSuggestions`/`reportExplanations`).
- `storage.rules` — novo path `organizations/{organizationId}/productRecognitionQueries/{userId}/{fileName}`
  (próprio usuário, mesma forma de `users/{userId}/avatar`).
- `storage-tests/storage.rules.test.js` — testes positivos/negativos do novo path (não executados
  neste ambiente — ver "Riscos conhecidos").
- `lib/core/storage/storage_paths.dart` — `StoragePaths.productRecognitionQuery`.
- `lib/core/analytics/analytics_events.dart` — `productRecognitionCompleted`,
  `productRecognitionFailed`, `productRecognitionFeedbackSubmitted`.
- `lib/core/navigation/app_route_paths.dart` — `ProductRecognitionRoute` (sem `Capability`, mesma
  visibilidade de `CatalogHomeRoute`/`CatalogBrowseRoute`).
- `lib/core/navigation/app_router.dart` — registra `ProductRecognitionRoute` e o builder
  `productRecognitionPageBuilder`.
- `lib/app/bootstrap.dart` — conecta `ProductRecognitionPage` via `getIt<ProductRecognitionCubit>()`
  e navega para `ProductDetailRoute` ao confirmar um candidato.
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) para registrar as
  novas classes `@injectable`/`@LazySingleton`.
- `test/core/analytics/analytics_events_test.dart` — inclui os 3 novos eventos na lista esperada.
- `test/core/navigation/app_router_test.dart` — novo teste de wiring de `ProductRecognitionRoute`
  (prova que a rota não tem `redirect:`/`Capability`).

## Arquitetura utilizada

Clean Architecture/feature-first, mesmo padrão de TASK-186/187/189/190: `Presentation (Cubit) →
Use case → Repository contract → Repository impl (Cloud Functions + Storage) `. Sem datasource
Firestore no cliente (a única forma de obter um resultado é a resposta do callable
`recognizeProductImage`, exatamente como `ApproachSuggestionRepository`/
`ReportExplanationRepository` já fazem). No backend, `product-recognition-shared.ts` é puro
(sem Firestore/`firebase-functions`), mesma forma de `recommendation-shared.ts` (TASK-190).

## Regras de negócio implementadas

- Reconhecimento nunca retorna uma única resposta forçada: `rankProductRecognitionCandidates`
  sempre devolve uma lista ordenada por score de similaridade de cosseno (`0..1`), colapsando
  múltiplas fotos indexadas do mesmo produto em um único candidato (o de maior score).
- Abaixo do limiar mínimo de confiança (`PRODUCT_RECOGNITION_MIN_CONFIDENCE = 0.6`),
  `belowThreshold: true` e `candidates: []` — a UI mostra explicitamente "não foi possível
  identificar com confiança", nunca uma lista vazia silenciosa.
- Índice de embeddings sempre escopado por `organizationId` — `recognizeProductImage` só carrega
  `loadOrganizationIndex(organizationId)` do próprio chamador (nunca comparação cross-tenant).
- `storagePath` da imagem de consulta é revalidado contra o `organizationId`/`uid` reais do
  chamador (nunca confiado do payload) antes de qualquer leitura/exclusão no Storage.
- A imagem de consulta é excluída do Storage ao final do processamento (sucesso ou falha) —
  política de retenção "não retida além do necessário".
- Feedback ("era este"/"não era nenhum") só pode ser enviado uma vez por tentativa, só pelo próprio
  usuário que a originou, e `matchedProductId` só é aceito se corresponder a um dos candidatos
  realmente apresentados naquela tentativa.

## Regras Firebase implementadas

- `firestore.rules`: `productImageEmbeddings`/`productRecognitionAttempts` deny-all (só Admin SDK).
- `storage.rules`: `productRecognitionQueries/{userId}/{fileName}` — leitura/escrita/exclusão só
  pelo próprio `userId`, tipo/tamanho validados (`isValidProductImage`, reaproveitada).

## Analytics implementado

- `product_recognition_completed` (`RecognizeProductImageUseCase`, sucesso — inclui quando
  `belowThreshold` é `true`, nunca tratado como falha).
- `product_recognition_failed` (`RecognizeProductImageUseCase`, falha).
- `product_recognition_feedback_submitted` (`SubmitProductRecognitionFeedbackUseCase`, sucesso).

Nenhum evento carrega nome/foto/score de produto — apenas contagens/booleans/códigos.

## Crashlytics implementado

Nenhuma mudança específica — erros seguem o mesmo caminho de `AppException`/`Failure` já tratado
pelo `_guard` do repositório e pelos handlers globais existentes (`configureGlobalErrorHandlers`).

## Impacto offline

Feature sempre online (mesma decisão documentada por `ApproachSuggestionRepository`/
`ReportExplanationRepository`): tanto o upload da foto quanto a chamada ao provedor de embedding
exigem conectividade. Sem Outbox/sync — não é uma mutação de dado de negócio persistente offline.

## Impacto multi-tenant

- Índice de embeddings e busca sempre escopados por `organizationId` (nunca por `companyId`, já
  que `Product.companyId` é opcional — TASK-064).
- `storagePath` da imagem de consulta é re-derivado e comparado contra `organizationId`/`uid` reais
  do chamador, nunca aceito de forma que permita ler/excluir arquivo de outro usuário/organização.

## Testes criados

- **Functions (Jest)**: `product-recognition-shared.test.ts` (11 casos — cosine similarity,
  correspondência clara, ambígua, abaixo do limiar, índice vazio, colapso de múltiplas fotos do
  mesmo produto, limite máximo de candidatos, override de limiar, id determinístico) e
  `image-embedding-provider-adapter.test.ts` (adapter desabilitado por padrão, mensagem
  configurável, adapter Vertex AI com fetcher/token injetados, erro de status não-OK, embedding
  vazio/inválido nunca fabricado).
- **Flutter**: `recognize_product_image_use_case_test.dart`,
  `submit_product_recognition_feedback_use_case_test.dart`,
  `product_recognition_cubit_test.dart` (idle/recognizing/ready/error, feedback, reset).
- **Regras**: testes positivos/negativos adicionados a `storage-tests/storage.rules.test.js`
  (upload/leitura/exclusão só pelo próprio usuário, tipo/tamanho inválidos, membro inativo,
  cross-tenant) — não executados neste ambiente, ver "Riscos conhecidos".
- Não foram criados testes de widget para `ProductRecognitionPage` nem testes diretos para as
  Cloud Functions `recognizeProductImage`/`submitProductRecognitionFeedback`/
  `indexProductImageEmbedding` (que dependem de Firestore/Storage Admin SDK) — mesmo padrão já
  aceito em TASK-186/187/189/190 (`explain-report.ts`/`generate-approach-suggestion.ts` também não
  têm teste unitário direto, só seus módulos `-shared.ts`).

## Comandos executados

```bash
cd functions && npm install --no-audit --no-fund
cd functions && npx tsc --noEmit
cd functions && npx eslint src/product_recognition src/shared/image-embedding-provider-adapter.ts test/product_recognition test/shared/image-embedding-provider-adapter.test.ts
cd functions && npx jest test/product_recognition test/shared/image-embedding-provider-adapter.test.ts
cd functions && npx jest
dart run build_runner build
flutter analyze
flutter analyze lib/features/product_recognition
dart format --set-exit-if-changed <arquivos Dart tocados/criados>
flutter test test/features/product_recognition
flutter test test/core/analytics/analytics_events_test.dart test/core/storage/storage_paths_test.dart
flutter test test/core/navigation/app_router_test.dart
flutter test
git stash && flutter test test/app/bootstrap_test.dart && git stash pop
```

## Resultado do formatter

`dart format --set-exit-if-changed` sem alterações pendentes na segunda rodada (arquivos
formatados automaticamente na primeira). Nenhum arquivo `.ts` precisou de `prettier` (não há
config no projeto para isso; `eslint` cobre estilo).

## Resultado do analyzer

- `flutter analyze` (projeto completo): **18 issues, todos `info` pré-existentes** (nenhum error;
  nenhum deles em arquivo tocado por esta task).
- `flutter analyze lib/features/product_recognition`: **No issues found!**
- `npx tsc --noEmit` (functions): sem erros.
- `npx eslint` nos arquivos novos: sem erros/avisos.

## Resultado dos testes

- `npx jest test/product_recognition test/shared/image-embedding-provider-adapter.test.ts`:
  **24/24 passando**.
- `npx jest` (suíte completa de `functions`): **488 passando, 182 falhando em 29 suítes** — todas
  as falhas são testes que dependem do Firebase Emulator Suite (Firestore/Storage,
  `clearFirestore`/`testEnv`), que não roda neste ambiente por falta de Java (`java: command not
  found`) — mesma limitação já documentada na conclusão da TASK-190. Nenhuma falha é dos arquivos
  criados nesta task (confirmado individualmente).
- `flutter test test/features/product_recognition`: **13/13 passando**.
- `flutter test test/core/analytics/analytics_events_test.dart test/core/storage/storage_paths_test.dart`: **11/11 passando**.
- `flutter test test/core/navigation/app_router_test.dart`: **22/22 passando** (inclui o novo teste
  de `ProductRecognitionRoute`).
- `flutter test` (suíte completa do projeto): **3256/3257 passando** — a única falha
  (`test/app/bootstrap_test.dart`) foi confirmada **pré-existente** via `git stash` (falha
  idêntica sem nenhuma mudança desta task: `PushDeviceMapper is not registered inside GetIt` +
  assertion do plugin `firebase_crashlytics_platform_interface` em ambiente de teste — nada
  relacionado a `product_recognition`).

## Decisões técnicas

- **Provedor de embedding de imagem = Vertex AI Multimodal Embeddings (`multimodalembedding@001`)**,
  autenticado via Application Default Credentials (identidade da própria Cloud Function no GCP),
  em vez de um secret de API key por feature (padrão diferente de `AnthropicLlmProviderAdapter`/
  `OpenAiLlmProviderAdapter`, que são chamadas a APIs de terceiros). Igual às demais features de IA
  generativa do EPIC-28, o adapter é *pluggable* e **desabilitado por padrão**
  (`RECOGNIZE_PRODUCT_IMAGE_PROVIDER=disabled`); habilitar em produção exige quem administra o
  projeto GCP: (1) definir `RECOGNIZE_PRODUCT_IMAGE_PROVIDER=vertexAi`,
  `RECOGNIZE_PRODUCT_IMAGE_GCP_PROJECT_ID`, `RECOGNIZE_PRODUCT_IMAGE_REGION`; (2) conceder ao
  service account das Cloud Functions o papel `roles/aiplatform.user` (ou equivalente) no projeto.
  Sem isso, toda chamada falha de forma clara e recuperável (`ImageEmbeddingProviderNotConfiguredError`),
  nunca silenciosamente.
- **Nenhum candidato é sugerido sem um índice de embeddings existente** — `indexProductImageEmbedding`
  (trigger de Storage) e `recognizeProductImage` compartilham a mesma configuração de provedor;
  enquanto o provedor real não for habilitado, o catálogo simplesmente não é indexado e toda
  tentativa de reconhecimento retorna `belowThreshold: true` (nunca um erro fatal, nunca uma
  alucinação).
- **Um candidato por produto, não por foto** — `rankProductRecognitionCandidates` colapsa múltiplas
  fotos indexadas do mesmo produto (comum, TASK-068 permite várias) na foto de melhor score, para a
  lista de candidatos nunca repetir o mesmo produto.
- **Exclusão da imagem de consulta é responsabilidade do servidor** (`recognizeProductImage`,
  bloco `finally`), não do cliente — mantém a regra de retenção como regra de negócio no backend,
  não espalhada na UI.

## Riscos conhecidos

- O adapter Vertex AI (`VertexAiMultimodalEmbeddingAdapter`) documenta o contrato de
  request/response da API pública, mas **não foi exercitado contra a API real** neste ambiente
  (sem acesso à rede) — mesmo risco já assumido pelos adapters Anthropic/OpenAI existentes em
  `llm-provider-adapter.ts`. Recomenda-se validar contra um projeto GCP real (com
  `roles/aiplatform.user` concedido) antes de habilitar em produção.
- Sem limpeza automática (TTL) de fotos órfãs em `productRecognitionQueries/` caso o callable
  falhe antes do `finally` rodar (ex.: função derrubada pelo runtime) ou o cliente nunca chame o
  callable após o upload — mitigação recomendada: uma regra de ciclo de vida (Lifecycle) no bucket
  do Cloud Storage para esse prefixo, que é uma configuração de infraestrutura do GCP fora do
  escopo desta task (mesmo padrão de "decisão de infraestrutura documentada, não implementada
  nesta task" já usado em `recommendation-shared.ts`/TASK-190 para o pipeline de BigQuery).
- Testes de `storage.rules` para o novo path foram escritos mas **não executados neste ambiente**
  (Firebase Emulator Suite exige Java, ausente aqui) — mesma limitação documentada na conclusão da
  TASK-190; recomenda-se rodar
  `firebase emulators:exec --only "firestore,storage" "npm --prefix storage-tests test"` em um
  ambiente com Java antes de qualquer deploy real.
- Nenhum ponto de entrada de navegação foi adicionado a uma tela existente (ex.: um botão
  "Identificar produto por foto" no catálogo) — a rota `ProductRecognitionRoute` existe, está
  registrada e é navegável diretamente (testada em `app_router_test.dart`), mas descobrir onde
  colocar esse atalho na UI existente é uma decisão de design que envolve
  `flutter-ui-design-specialist`/`vestipro-sales-representative-specialist`, fora do escopo desta
  task conforme os critérios de aceite (que exigem a tela funcionar, não uma integração de
  descoberta específica).

## Pendências

- Habilitar o provedor Vertex AI em produção (variáveis de ambiente + IAM) é uma decisão/ação de
  quem administra o projeto GCP/Firebase da organização.
- Rodar os testes de `firestore.rules`/`storage.rules` no Emulator Suite (ambiente com Java) antes
  do primeiro deploy real das novas regras.
- Definir, com o time de UI/produto, onde adicionar o atalho de entrada para esta tela no fluxo do
  vendedor (catálogo, busca, etc.).

## Evidências

- `functions/src/product_recognition/*.ts`, `functions/src/shared/image-embedding-provider-adapter.ts`
- `lib/features/product_recognition/**`
- Saídas de comandos reproduzidas na seção "Resultado dos testes" acima.

## Commit

`feat(product-recognition): implementa reconhecimento de produto por imagem (TASK-191)`

## Push

Não realizado nesta rodada — push não autorizado.

## Hash do commit

`f74f49afe28303280a66fa98864139a9895f2ad8`

## Branch

`main`
