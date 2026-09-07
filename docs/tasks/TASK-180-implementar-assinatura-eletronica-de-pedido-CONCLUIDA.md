# TASK-180 — Concluída (2026-09-07)

## Resumo

Implementada a assinatura eletrônica de pedido (EPIC-13): o vendedor (ou o cliente, no próprio
aparelho do vendedor) pode desenhar a assinatura em tela no momento do fechamento do pedido já
submetido, essa assinatura fica anexada de forma imutável ao pedido (nunca removida/substituída),
com hash do conteúdo do pedido no momento da assinatura, metadados de quem assinou/quando/
dispositivo/IP, funciona 100% offline (captura local sempre, sincronização automática quando há
conexão), bloqueia edição do pedido depois de assinado, e é exibida em um novo comprovante/PDF do
pedido (que também não existia neste código antes desta task).

Nenhum modelo de dado do agregado `Order` foi alterado: `OrderSignature` é um registro irmão,
referenciando o pedido por `orderId`, exatamente como `Order` já se relaciona com aprovações/
histórico sem misturar tudo em um único documento. Toda validação de autenticidade/conteúdo é
recalculada no backend (`signOrder`, Cloud Function) — o cliente nunca é a fonte de verdade da
assinatura, apenas quem captura a evidência.

## Agentes utilizados

- `flutter-senior-architect` (domain/data/BLoC/Firebase/RBAC/segurança/offline — único agente
  obrigatório listado na task; a UI de captura/comprovante foi implementada por este mesmo agente,
  seguindo os componentes de Design System já existentes, sem invocar o agente de front-end).

## Arquivos criados

Domain (`lib/features/orders/domain`):
- `value_objects/order_signature_method.dart`, `order_signature_status.dart`,
  `order_signature_sync_status.dart`, `order_signer_role.dart`
- `entities/order_signature.dart` (+ `.freezed.dart`, gerado)
- `entities/order_signature_submission_result.dart` (+ `.freezed.dart`, gerado)
- `services/order_content_hasher.dart` — SHA-256 determinístico do conteúdo comercial do pedido
  (`crypto` package, nova dependência pura-Dart em `pubspec.yaml`)
- `services/order_receipt_pdf_encoder.dart` — primeiro encoder de comprovante/PDF de pedido deste
  código (não existia nenhum antes — ver "Decisões técnicas")
- `repositories/order_signature_draft_repository.dart` (contrato local/offline)
- `repositories/order_signature_submission_repository.dart` (contrato remoto/Cloud Function)
- `repositories/external_esignature_provider_gateway.dart` — ponto de extensão para um futuro
  provedor externo de assinatura eletrônica avançada/qualificada (sem implementação concreta,
  sem binding de DI — ver "Decisões técnicas")
- `usecases/capture_order_signature_use_case.dart` (inclui `kSignableOrderStatuses`)
- `usecases/submit_order_signature_use_case.dart`
- `usecases/get_order_signature_use_case.dart`
- `usecases/list_pending_order_signatures_use_case.dart`

Data (`lib/features/orders/data`):
- `mappers/order_signature_codec.dart` (codificação enum<->string compartilhada)
- `mappers/order_signature_local_mapper.dart` (entidade <-> linha Drift)
- `mappers/order_signature_submission_mapper.dart` (DTO -> entidade)
- `dtos/order_signature_submission_result_dto.dart`
- `datasources/order_signature_submission_data_source.dart` (contrato)
- `datasources/cloud_functions_order_signature_submission_data_source.dart` (chama `signOrder`)
- `repositories/drift_order_signature_draft_repository.dart`
- `repositories/order_signature_submission_repository_impl.dart`

Core (`lib/core/database`):
- `tables/order_signatures_table.dart` — nova tabela Drift (cache offline-first da assinatura,
  incluindo o `BLOB` da imagem, mantido mesmo após sincronizar)

Presentation (`lib/features/orders/presentation`):
- `bloc/order_signature_state.dart` (`OrderSignatureFlowStatus`), `bloc/order_signature_cubit.dart`
- `widgets/order_signature_pad.dart` — canvas de assinatura manuscrita (CustomPainter +
  RepaintBoundary, sem depender de nenhum pacote externo de "signature pad")
- `pages/order_signature_capture_page.dart` — tela "Assinar pedido"
- `pages/order_receipt_preview_page.dart` — tela "Ver comprovante" (reaproveita `PdfPreview` do
  pacote `printing`, mesmo padrão de `ReportPdfPreviewPage`, TASK-148)

Cloud Functions (`functions/src/orders`):
- `sign-order.ts` — Function `signOrder` (idempotente, recomputa `buildOrderContentHash`
  server-side, nunca confia no hash do cliente, faz upload da imagem via Admin SDK)

Testes novos:
- `test/features/orders/domain/services/order_content_hasher_test.dart`
- `test/features/orders/domain/services/order_receipt_pdf_encoder_test.dart`
- `test/features/orders/domain/usecases/capture_order_signature_use_case_test.dart`
- `test/features/orders/domain/usecases/submit_order_signature_use_case_test.dart`
- `test/core/database/app_database_task_180_order_signatures_migration_test.dart`
- `functions/test/orders/sign-order.test.ts`

## Arquivos alterados

- `pubspec.yaml`: nova dependência `crypto: ^3.0.6` (SHA-256 puro-Dart).
- `lib/core/analytics/analytics_events.dart`: `orderSignatureCaptured`, `orderSignatureSynced`,
  `orderSignatureSyncFailed`, `orderReceiptViewed`.
- `lib/core/database/app_database.dart` (+ `.g.dart`, regenerado): `OrderSignaturesTable` na lista
  de tabelas, `schemaVersion` 22 → 23, migração `from < 23` (criação incondicional, tabela nova),
  métodos `upsertOrderSignature`/`getOrderSignatureByOrderId`/`getPendingSyncOrderSignatures`.
- `lib/features/orders/domain/usecases/add_items_to_order_draft_use_case.dart`: nova dependência
  `OrderSignatureDraftRepository` — rejeita adicionar itens a um pedido com assinatura válida
  (`ConflictFailure`, code `order_draft_locked_by_signature`).
- `lib/features/orders/presentation/pages/order_history_page.dart`: ações "Assinar pedido"/"Ver
  comprovante", novo `BlocProvider<OrderSignatureCubit>` (parâmetro obrigatório
  `createSignatureCubit`).
- `lib/features/orders/orders.dart`: barrel atualizado com todos os arquivos novos.
- `lib/app/bootstrap.dart` (+ `injection.config.dart`, regenerado): wiring de
  `createSignatureCubit: () => getIt<OrderSignatureCubit>()` em `OrderHistoryPage`.
- `functions/src/index.ts`, `functions/src/orders/index.ts`: export de `signOrder`.
- `firestore.rules`: nova subcoleção `orders/{orderId}/signatures/{signatureId}` (leitura pela
  mesma visibilidade do pedido, escrita sempre `if false`).
- `storage.rules`: novo path `organizations/{organizationId}/orders/{orderId}/signatures/{fileName}`
  (leitura para membro ativo, escrita sempre `if false`).
- `firestore-tests/firestore.rules.test.js`, `storage-tests/storage.rules.test.js`: testes
  positivos/negativos para os paths novos.
- `package.json` (raiz): `test:functions` passa a subir também o emulador de `storage` (necessário
  para o novo `signOrder`, que agora faz upload de imagem).
- `test/features/orders/domain/usecases/add_items_to_order_draft_use_case_test.dart`,
  `test/features/orders/domain/usecases/duplicate_order_use_case_test.dart`: adaptados à nova
  dependência de `AddItemsToOrderDraftUseCase` (fake `OrderSignatureDraftRepository` adicionado) +
  2 novos testes de bloqueio de edição.
- `test/core/database/app_database_task_106_schema_test.dart`,
  `app_database_task_114_targets_migration_test.dart`,
  `app_database_task_176_customer_geocoding_migration_test.dart`,
  `app_database_task_177_visit_routes_migration_test.dart`, `app_database_test.dart`,
  `app_database_warehouses_test.dart`: `schemaVersion` esperado 22 → 23.

## Arquitetura utilizada

Clean Architecture + BLoC, seguindo exatamente o mesmo padrão que `Order`/`submitOrder` já
estabelecem neste código:

- Presentation (`OrderSignatureCapturePage`/`OrderHistoryPage`) → `OrderSignatureCubit` → use
  cases (`CaptureOrderSignatureUseCase`, `SubmitOrderSignatureUseCase`, `GetOrderSignatureUseCase`)
  → contratos de repositório (`OrderSignatureDraftRepository`/`OrderSignatureSubmissionRepository`)
  → implementações Drift/Cloud Functions.
- Domain 100% livre de Flutter/Firebase/Drift — `OrderContentHasher`/`OrderReceiptPdfEncoder` são
  Dart puro (o `pdf` package também é puro-Dart, mesmo precedente de `PdfReportEncoder`, TASK-148).
- UI nunca acessa Firestore/Storage/Drift diretamente — todo acesso passa pelos use cases acima.
- DI por `@injectable`/`@lazySingleton` + construtor, nada de `GetIt.instance` espalhado.

## Regras de negócio implementadas

- Captura de assinatura por desenho em tela (`OrderSignaturePad`) como mecanismo padrão.
- Pedido só pode ser assinado em um dos `kSignableOrderStatuses` (`submitted`, `under_review`,
  `approved`, `processing`, `invoiced`, `partially_invoiced`, `shipped`, `delivered`) — nunca
  `draft`/`pending_sync`/`cancelled`/`rejected`.
- Uma vez válida, uma `OrderSignature` nunca é removida/substituída — assinar de novo é rejeitado
  (`ConflictFailure`/`failed-precondition`, tanto no cliente quanto no `signOrder`), a única
  transição permitida é para `invalidated` (com rastro), e não há nenhum endpoint client-facing que
  produza essa transição nesta task (ver "Decisões técnicas").
- `OrderContentHasher` grava o hash SHA-256 do conteúdo comercial do pedido (cliente, itens,
  valores, condições, endereços — nunca status/histórico/aprovação) no momento da assinatura;
  `signOrder` recalcula esse mesmo hash a partir do documento atual no Firestore e rejeita a
  assinatura se divergir (pedido mudou desde a última sincronização do cliente).
- `AddItemsToOrderDraftUseCase` (o único lugar que hoje edita `Order.items` neste código) passa a
  consultar `OrderSignatureDraftRepository` e recusa a edição quando existe assinatura válida —
  "bloquear alteração do pedido após assinatura sem gerar uma nova versão/aditivo explícito" é
  satisfeito direcionando o vendedor para "Repetir pedido" (`DuplicateOrderUseCase`, já existente),
  nunca uma edição silenciosa.
- Comprovante/PDF do pedido (`OrderReceiptPdfEncoder`) inclui a assinatura (imagem, nome de quem
  assinou, papel, data/hora, hash) quando existe uma.
- Offline: captura sempre local primeiro (`CaptureOrderSignatureUseCase`/
  `OrderSignatureDraftRepository`, Drift), nunca bloqueada por conectividade; sincronização
  (`SubmitOrderSignatureUseCase`) tenta imediatamente e, em caso de falha de conectividade, mantém
  o registro local intacto como `pendingSync` (nunca perde a assinatura já capturada) — mesmo
  contrato que `submitOrderFromDraft` já estabelece para o próprio `Order`.

### Validade jurídica (documentação exigida pela task)

A assinatura por desenho em tela captura consentimento e evidência visual, mas **não é**, por si
só, uma assinatura eletrônica avançada/qualificada nos termos da MP 2.200-2/2001 (ICP-Brasil) — ela
não usa certificado digital nem um terceiro confiável que ateste a identidade do signatário no
momento da assinatura. Para o processo comercial da VestiPro (fechamento de pedido B2B, onde as
partes já têm relação comercial estabelecida e o vendedor está fisicamente com o cliente), esse
nível é adequado e é o padrão de mercado equivalente ao já usado por apps de entrega/logística.
`signedAt` é capturado no cliente (não é criptograficamente prova contra manipulação de relógio do
aparelho); `serverReceivedAt` é o instante que o Firestore realmente registrou o processamento —
esse último é o que deve ser tratado como o instante juridicamente mais defensável para efeitos de
"quando a evidência foi recebida pela plataforma". Para processos que exijam assinatura eletrônica
qualificada (ex.: contratos de maior valor, exigência regulatória específica), o time comercial/
jurídico deve avaliar integrar um provedor externo através do ponto de extensão
`ExternalESignatureProviderGateway` (ver "Decisões técnicas").

## Regras Firebase implementadas

- `firestore.rules`: `organizations/{organizationId}/orders/{orderId}/signatures/{signatureId}` —
  leitura pela mesma `canReadOrder(organizationId)` que já protege o pedido pai; `create`/`update`/
  `delete` sempre `false` (só o Admin SDK, via `signOrder`, escreve).
- `storage.rules`: `organizations/{organizationId}/orders/{orderId}/signatures/{fileName}` —
  leitura para qualquer membro ativo da organização; escrita sempre `false` (só `signOrder`, via
  Admin SDK, faz upload).
- `signOrder` (Cloud Function): autenticação obrigatória; papel restrito a
  OWNER/ADMIN/SALES_MANAGER/SALES_REP (mesmo conjunto de `submitOrder`); `order.sellerId === uid`
  obrigatório; status do pedido revalidado; assinatura já existente (válida) bloqueia uma segunda;
  hash do conteúdo recomputado a partir do Firestore (nunca confia no hash do cliente);
  `deviceInfo`/`ipAddress` resolvidos pelo próprio Function (nunca aceitos como campo do payload);
  idempotente via `signatureId` como id do documento.

## Analytics implementado

- `order_signature_captured` — ao capturar localmente (offline-safe).
- `order_signature_synced` — ao confirmar sincronização com `signOrder`.
- `order_signature_sync_failed` — quando a sincronização falha (nunca quando é apenas
  `ConnectivityFailure` esperado, mas o evento ainda é logado para observabilidade).
- `order_receipt_viewed` — ao abrir o comprovante/PDF.

Nenhum evento carrega imagem/dado biométrico — apenas `organization_id`/`company_id`/`order_id`/
`signer_role`/`method`, mesmo "nunca dado pessoal desnecessário em analytics" já seguido pelo resto
do código.

## Crashlytics implementado

Nenhum ponto de captura/try-catch novo precisou de report explícito ao Crashlytics além do que já
existe: toda falha de use case retorna `AppFailure`/`Failure` tipada (nunca lança), e o
`AppErrorState`/`AppSnackbar` já exibem a mensagem — mesmo padrão de toda a feature `orders`. A
`CloudFunctionsExceptionMapper` já existente converte qualquer erro do `signOrder` normalmente.

## Impacto offline

- Captura sempre local primeiro (Drift, `OrderSignaturesTable`), nunca bloqueada por
  conectividade — testado em `app_database_task_180_order_signatures_migration_test.dart`
  (assinatura sobrevive a fechar/reabrir o banco, ainda `pending_sync`) e em
  `submit_order_signature_use_case_test.dart` (falha de sincronização nunca apaga o registro local).
- Imagem (`BLOB`) permanece salva localmente mesmo depois de sincronizada — o comprovante/PDF
  sempre pode ser renderizado neste mesmo aparelho, mesmo sem conexão.
- Retry automático de assinaturas pendentes (Central de Sincronização) **não foi wireado** nesta
  task — ver "Pendências". A base (`ListPendingOrderSignaturesUseCase`,
  `OrderSignatureDraftRepository.getPendingSync`) já existe para isso.

## Impacto multi-tenant

- `OrderSignature.organizationId`/`companyId` nunca são aceitos do cliente como autorização —
  `signOrder` sempre revalida contra o Membership real e o próprio documento do pedido.
- Toda leitura (Firestore/Storage Rules) é escopada por `organizationId` real (Membership), nunca
  pelo path sozinho.
- `OrderSignatureDraftRepository` (Drift) sempre filtra por `organizationId`/`companyId`, mesmo
  padrão de todo outro repositório local já existente.

## Testes criados

- `OrderContentHasher`: hash estável para o mesmo conteúdo, muda quando item/valor muda, não muda
  para campos de auditoria (status/histórico/syncStatus), e cobre o pitfall de serialização
  cross-language (double "inteiro" nunca muda o hash por conta de como seria serializado como
  número JSON puro).
- `CaptureOrderSignatureUseCase`: captura e persiste com hash correto; rejeita status não
  assinável; rejeita assinar duas vezes; permite assinar de novo após invalidação; rejeita imagem
  vazia; rejeita nome em branco.
- `SubmitOrderSignatureUseCase`: sincroniza e reconcilia metadados do servidor; nunca perde a
  assinatura já capturada quando a sincronização falha (offline).
- `AddItemsToOrderDraftUseCase` (2 testes novos): bloqueia edição de pedido assinado; permite
  edição quando a única assinatura foi invalidada.
- `OrderReceiptPdfEncoder`: gera PDF válido (`%PDF-`) sem assinatura; PDF maior quando a assinatura
  (imagem real, rasterizada via `dart:ui`) é embutida.
- `AppDatabase` (TASK-180): cria a tabela em banco novo; migra de schema 22 para 23; assinatura
  capturada offline sobrevive a fechar/reabrir o banco e é corretamente listada como pendente até
  ser reconciliada como `synced`.
- `signOrder` (Cloud Function, `functions/test/orders/sign-order.test.ts`): sucesso (assinatura +
  imagem persistidas, resposta correta); hash divergente rejeitado; assinar duas vezes rejeitado;
  retry idempotente nunca duplica; status não assinável rejeitado; papel sem permissão rejeitado;
  vendedor errado rejeitado; não autenticado rejeitado; imagem inválida rejeitada.
- Firestore/Storage Rules (`firestore-tests`/`storage-tests`): leitura permitida pela mesma
  visibilidade do pedido pai, cross-tenant negado, escrita sempre negada pelo cliente (mesmo para
  OWNER).

## Comandos executados

```
flutter pub get
dart run build_runner build
dart format --set-exit-if-changed <arquivos desta task>
flutter analyze
flutter test test/features/orders/
flutter test test/core/database/
cd functions && npm run build
cd functions && npm run lint
cd functions && npx jest test/orders/sign-order.test.ts   # ver "Riscos conhecidos"/"Pendências"
firebase emulators:exec --only auth,firestore,storage "npm --prefix functions test -- test/orders/sign-order.test.ts"   # ver abaixo
```

## Resultado do formatter

`dart format --set-exit-if-changed` limpo em todos os 52 arquivos Dart tocados por esta task (0
alterações necessárias na segunda execução). Duas execuções completas de `dart format .` sobre o
repositório inteiro reformataram 3 arquivos fora do escopo desta task
(`locale_settings_page.dart`, `product_import_mapping_validator_test.dart`,
`start_product_import_job_use_case_test.dart`) — revertidos via `git checkout` em ambas as vezes,
por já terem drift de formatação pré-existente não relacionado a esta task.

## Resultado do analyzer

`flutter analyze`: 0 erros. Restam apenas 14-15 avisos `info` pré-existentes e não relacionados
(ex.: `RadioGroup` deprecado em `report_builder_page.dart`, `use_null_aware_elements` em imports/
customer/product) — confirmados via `git diff`/inspeção de que nenhum é causado por esta task.

## Resultado dos testes

- `flutter test test/features/orders/`: **203 testes, todos passando.**
- `flutter test test/core/database/`: **55 testes, todos passando** (incluindo os 6 arquivos cujo
  `schemaVersion` esperado foi atualizado de 22 para 23).
- `cd functions && npm run build`: sucesso, sem erros de TypeScript.
- `cd functions && npm run lint`: sucesso, sem erros de ESLint.
- `functions/test/orders/sign-order.test.ts`: **não foi possível executar neste ambiente** — o
  Firebase Emulator Suite (Firestore/Storage) exige Java, que não está instalado nesta máquina
  (`Could not spawn 'java -version'`). Isso também impediu rodar
  `firestore-tests/firestore.rules.test.js`/`storage-tests/storage.rules.test.js` (as suítes de
  Rules positivas/negativas já escritas para os 2 paths novos). O código TypeScript compila e passa
  no lint; a lógica do teste espelha exatamente o padrão já estabelecido e comprovadamente correto
  de `decide-order-approval.test.ts` (mesmo harness `firebase-functions-test`). Ver "Riscos
  conhecidos"/"Pendências" — recomenda-se rodar `npm run test:integration` (ou os scripts
  individuais `test:rules:firestore`/`test:rules:storage`/`test:functions`) em CI/ambiente com Java
  antes do merge para produção.

## Decisões técnicas

1. **`OrderSignature` como registro irmão, não campo de `Order`.** Evita tocar
   `order.dart`/`order_dto.dart`/`order_mapper.dart`/`order_local_mapper.dart` e todos os testes
   que já constroem um `Order` (dezenas, em várias features) — muito menor superfície de risco, e é
   o mesmo padrão que aprovação/histórico já usam (documentos irmãos, nunca tudo em um único
   agregado gigante).
2. **Sem endpoint de "invalidar assinatura" nesta task.** `OrderSignatureStatus.invalidated` existe
   no modelo (para nunca ser um "breaking change" de schema no futuro), mas nada nesta task
   transiciona para ele — a task pede apenas que a assinatura nunca seja removida/substituída, não
   que exista um fluxo de invalidação; esse fluxo naturalmente pertence a uma futura task de
   cancelamento/nova versão de pedido, quando essa área existir.
3. **`ExternalESignatureProviderGateway` documentado, não implementado.** A task pede para "avaliar
   e documentar" a necessidade de um provedor externo — a avaliação (seção "Validade jurídica"
   acima) conclui que o desenho em tela é suficiente hoje; o ponto de extensão existe para quando
   isso mudar, sem nenhum binding de DI (não é chamado por nada).
4. **Comprovante/PDF criado do zero.** `tasks.md` presumia um fluxo de PDF/comprovante de pedido já
   existente ("exibir a assinatura como parte do PDF... já gerado pelo fluxo existente") — não
   existe nenhum no código (só o `PdfReportEncoder` de relatórios, TASK-148, que é de outro
   domínio). `OrderReceiptPdfEncoder` foi criado deliberadamente mínimo (capa+itens+totais+
   assinatura), reaproveitando o mesmo pacote `pdf` já dependência do projeto — não é substituto de
   nota fiscal.
5. **Hash monetário como string de precisão fixa, nunca número JSON cru.** `Dart.jsonEncode`
   serializa um `double` inteiro como `"120.0"`; `JSON.stringify` (TypeScript, no `signOrder`)
   serializa o mesmo valor como `"120"` — divergência que faria o hash do cliente e do servidor
   discordarem só pela linguagem, nunca pelo conteúdo real. `OrderContentHasher._money`/
   `buildOrderContentHash`'s `money()` (TS) resolvem isso formatando cada valor monetário como
   string de 2 casas decimais antes de hashear.
6. **Bloqueio de edição implementado em `AddItemsToOrderDraftUseCase`, não em `SaveOrderDraftUseCase`.**
   `SaveOrderDraftUseCase` é usado tanto para edição do vendedor quanto para reconciliação
   automática pós-submissão (`submitOrderFromDraft`) — bloquear ali quebraria essa reconciliação.
   `AddItemsToOrderDraftUseCase` é o único lugar que hoje efetivamente muta `Order.items`, então é
   onde o bloqueio tem efeito real sem introduzir uma regressão em um fluxo que já funciona.
7. **`test:functions` (raiz) agora sobe o emulador de `storage`.** Necessário porque `signOrder` é
   a primeira Cloud Function de pedidos que faz upload de mídia — mudança de uma linha, sem
   impacto em nenhum teste existente (eles simplesmente não usavam Storage).

## Riscos conhecidos

- **Hash mirror entre Dart e TypeScript mantido manualmente** (`OrderContentHasher` vs
  `buildOrderContentHash` em `sign-order.ts`) — mesmo risco já aceito e documentado por
  `firestore.rules`' `roleHasCapability` (mirror de `RolePermissionMatrix`). Uma mudança em um dos
  dois sem replicar no outro faria toda assinatura subsequente falhar com "conteúdo do pedido
  mudou" — um risco de disponibilidade, não de segurança (nunca persiste uma assinatura com hash
  divergente).
- **Testes de `signOrder`/Firestore Rules/Storage Rules não executados neste ambiente** (falta de
  Java para o Emulator Suite) — ver "Resultado dos testes"/"Pendências".
- **`OrderSignatureDraftRepository.getByOrderId` é local-only.** Uma assinatura capturada em um
  aparelho não aparece em outro aparelho do mesmo vendedor até existir um fetch remoto dedicado
  (fora do escopo — ver "Pendências"). O backstop real (impedir uma segunda assinatura válida)
  continua 100% garantido no servidor (`signOrder` consulta a subcoleção `signatures` inteira, não
  o cache local de nenhum cliente).

## Pendências

- Rodar `npm run test:integration` (ou `test:rules:firestore`/`test:rules:storage`/`test:functions`
  individualmente) em um ambiente com Java instalado (CI) antes do próximo deploy, para validar de
  fato o `signOrder` e as novas Rules contra o Emulator Suite real.
- Central de Sincronização (`SyncCenterPage`) não foi conectada a
  `ListPendingOrderSignaturesUseCase` — hoje a única forma de reconciliar uma assinatura que falhou
  ao sincronizar é reabrir a tela do pedido (que tenta de novo pela própria captura, não por um
  retry automático). A base de dados/use case já existe para um retry automático futuro.
- Assinatura só é lida do cache local do próprio aparelho (ver "Riscos conhecidos") — nenhum
  fetch remoto por `orderId` foi implementado para exibir uma assinatura já capturada em outro
  aparelho.
- Nenhum fluxo de "invalidar assinatura" existe ainda (ver "Decisões técnicas" #2) — pertence a uma
  futura task de cancelamento/nova versão de pedido.
- `ExternalESignatureProviderGateway` é só a interface — nenhum provedor real (DocuSign/Clicksign/
  ZapSign) foi integrado (avaliação de que não é necessário hoje, ver "Validade jurídica").

## Evidências

- `flutter test test/features/orders/` → `+203: All tests passed!`
- `flutter test test/core/database/` → `+55: All tests passed!`
- `flutter analyze` → `No issues found` além dos pré-existentes não relacionados.
- `cd functions && npm run build` → sucesso (tsc sem output = sem erros).
- `cd functions && npm run lint` → sucesso (eslint sem output = sem erros).

## Commit

Commit local único contendo toda a implementação (domain/data/presentation/Cloud Function/Rules/
testes/documentação) desta task.

## Push

Não realizado — apenas commit local, conforme autorizado para esta rodada.

## Hash do commit

`71b54c8c6bc0a1e7b5681fa4c24d9600bcf785dd`

## Branch

`main`
