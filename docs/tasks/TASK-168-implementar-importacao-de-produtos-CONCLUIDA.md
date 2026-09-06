# TASK-168 — Implementar importação massiva de produtos — CONCLUÍDA

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Data de conclusão:** 2026-09-06
**Agentes utilizados:** `flutter-senior-architect` (domínio, dados, Cloud Functions, Security Rules) e
`flutter-ui-design-specialist` (wizard de importação, Design System).

## Resumo

Implementada a importação em massa de produtos + variantes (cor/tamanho) via planilha CSV/XLSX
(EPIC-22), como uma nova feature `lib/features/product_import/` (Clean Architecture completa:
domain → data → presentation) mais 2 Cloud Functions novas em `functions/src/products/`. Nada
equivalente existia no repositório antes desta task (verificado antes de codar — `grep -i "import"` em
`lib/features` só retornava `customer_import`, TASK-167).

Fluxo real implementado:

1. **Upload** (`ProductImportUploadStep`): o gestor seleciona um arquivo `.csv`/`.xlsx` (até 15 MB)
   com uma linha por variante (produto + cor + tamanho).
2. **Preview + mapeamento** (`ProductImportMappingStep`): as primeiras `kProductImportPreviewRowLimit`
   (20) linhas são parseadas só no cliente. O gestor mapeia cada coluna para SKU, referência, nome,
   descrição, marca, categoria, subcategoria, coleção, cor, tamanho, preço base e código de barras
   (EAN); seleciona a grade de tamanho (`SizeGridTemplate`) que esta importação inteira usa; escolhe
   se categorias/coleções não cadastradas devem ser criadas automaticamente ou rejeitar a linha (cor
   nunca é criada automaticamente); e opcionalmente seleciona um pacote de imagens (múltiplos
   arquivos, nomeados por SKU ou referência).
3. **Job assíncrono** (`startProductImportJob`, callable): faz upload do arquivo (e, se houver, de
   cada imagem) para `organizations/{orgId}/productImports/{batchId}/...` e cria
   `organizations/{orgId}/productImportJobs/{jobId}` com `status: 'queued'`.
4. **Processamento server-side** (`processProductImportJob`, trigger `onDocumentCreated`): baixa o
   arquivo do Storage, parseia com `exceljs`, valida linha a linha (SKU/EAN com mesmo algoritmo do
   Flutter, cor/tamanho/categoria/coleção resolvidos contra o lookup client-side — ver decisão
   abaixo), detecta conflito de SKU/referência contra produtos já existentes na organização, agrupa
   variantes do mesmo produto (mesmo SKU) em um único `Product`, deriva o SKU de cada
   `ProductVariant` (`{sku}-{corCódigo}-{tamanho}`, mesmo algoritmo de
   `GenerateProductVariantsUseCase._deriveSku`), grava em lote (`WriteBatch`, commit a cada 400) em
   `organizations/{orgId}/products`/`productVariants`, associa imagens por nome de arquivo (SKU ou
   referência) via `bucket.getFiles({prefix})`, grava um relatório completo em Storage, atualiza o job
   para `completed`/`failed` e registra `AuditAction.productImportCompleted`.
5. **Progresso + relatório** (`ProductImportProgressReportStep`): escuta o job via `Stream` do
   Firestore, mostra contadores (produtos criados, variantes criadas, imagens associadas/órfãs,
   rejeitados) e, ao concluir, baixa e renderiza o relatório (`AppDataTable`) linha a linha mais a
   lista de imagens sem correspondência.

## Verificação de duplicidade antes de codar

Busquei por qualquer implementação equivalente (`grep -i "import"` em `lib/features`, estrutura de
`lib/features/products/`) e não havia nada de importação de produtos — só o cadastro individual
(`ProductFormPage`, TASK-065/068). Confirmei também que `organizations/{orgId}/products` já existe
como coleção real no Firestore, lida por `FirestoreProductRemoteSearchDataSource` (TASK-069) — hoje
vazia, porque nenhum código escreve nela ainda (o cadastro manual de produto é local-only, ver
"Decisões técnicas" abaixo); os documentos criados por esta task usam exatamente o formato de campo
que `ProductDto`/`ProductMapper` (Flutter) já esperam.

## Decisão de arquitetura mais importante: resolução de categoria/coleção/cor/grade é client-side

Diferente do que o "Escopo técnico" da task sugeria à primeira vista (resolução de nomes livre
server-side), uma investigação do estado real do repositório mostrou que **`Category`, `Collection`,
`ProductColor` e `SizeGridTemplate` não têm nenhum armazenamento remoto/Firestore hoje** — todos os 4
repositórios são `SharedPreferences*Repository` (comentário nos próprios arquivos: "usado até a
implementação do sync/outbox remoto existir"), exatamente o mesmo gap arquitetural pré-existente que
`TASK-167-...-CONCLUIDA.md` já documentou para `Customer`. Isso significa que **a Cloud Function não
tem como consultar** "qual é o id da categoria 'Camisaria'" — esse catálogo só existe no
`SharedPreferences` do dispositivo que está rodando a importação.

Adaptação (documentada em `ProductImportLookup`, `lib/features/product_import/domain/entities/
product_import_lookup.dart`): o próprio dispositivo cliente resolve, a partir do seu catálogo local,
um `ProductImportLookup` (`categoryIdByName`, `collectionIdByName`, `colorIdByName`,
`sizeIdByLabel`) usando os nomes distintos encontrados na prévia da planilha, cria localmente as
categorias/coleções ausentes quando o toggle "criar automaticamente" está ligado (reaproveitando
`CreateCategoryUseCase`/`CreateCollectionUseCase` já existentes), e envia só o lookup já resolvido
para `startProductImportJob`. A Cloud Function nunca inventa/infere um id — um nome ausente do lookup
sempre rejeita a linha ("categoria/cor/tamanho não cadastrado"), o que na prática reforça ainda mais
a regra "nunca inferida silenciosamente" do que uma resolução server-side teria feito. Isso é uma
adaptação de design, não um desvio silencioso: está documentado no próprio código
(`product_import_lookup.dart`) e aqui.

## Arquivos criados

### Flutter — feature nova `lib/features/product_import/`

- `product_import.dart` (barrel).
- `domain/value_objects/`: `product_import_field.dart`, `product_import_job_status.dart`,
  `product_import_row_outcome.dart`.
- `domain/entities/`: `product_import_mapping.dart`, `product_import_lookup.dart`,
  `product_import_preview.dart`, `product_import_template.dart`, `product_import_job.dart`,
  `product_import_row_report.dart`, `product_import_report.dart` (+ `.freezed.dart` gerados).
- `domain/repositories/`: `product_import_template_repository.dart`,
  `product_import_job_repository.dart`.
- `domain/services/`: `product_import_file_parser.dart` (contrato),
  `product_import_mapping_validator.dart` (validação pura, testada).
- `domain/usecases/`: `parse_product_import_file_use_case.dart`,
  `save_product_import_template_use_case.dart`, `list_product_import_templates_use_case.dart`,
  `delete_product_import_template_use_case.dart`, `start_product_import_job_use_case.dart`,
  `watch_product_import_job_use_case.dart`, `list_product_import_jobs_use_case.dart`,
  `get_product_import_job_report_use_case.dart`.
- `data/dtos/`: `product_import_template_dto.dart`, `product_import_job_dto.dart`.
- `data/mappers/`: `product_import_mapping_codec.dart`, `product_import_template_mapper.dart`,
  `product_import_job_mapper.dart`, `product_import_report_mapper.dart`.
- `data/datasources/`: `product_import_template_data_source.dart` +
  `firestore_product_import_template_data_source.dart`, `product_import_job_data_source.dart` +
  `firestore_product_import_job_data_source.dart`, `product_import_functions_data_source.dart` +
  `cloud_functions_product_import_data_source.dart`.
- `data/parsers/`: `csv_product_import_file_parser.dart` (puro Dart, testado),
  `xlsx_product_import_file_parser.dart` (`package:excel`).
- `data/repositories/`: `product_import_template_repository_impl.dart`,
  `product_import_job_repository_impl.dart` (upload do arquivo-fonte + upload opcional do pacote de
  imagens antes de chamar a Function).
- `presentation/bloc/`: `product_import_bloc.dart`, `product_import_event.dart`,
  `product_import_state.dart` (depende também de `ListCategoriesUseCase`/`ListCollectionsUseCase`/
  `ListProductColorsUseCase`/`ListSizeGridTemplatesUseCase`/`CreateCategoryUseCase`/
  `CreateCollectionUseCase`, já existentes em `features/products`, reaproveitados em vez de
  duplicados).
- `presentation/pages/product_import_page.dart`.
- `presentation/widgets/`: `product_import_upload_step.dart`, `product_import_mapping_step.dart`,
  `product_import_progress_report_step.dart`.
- `lib/app/product_import_parsers_module.dart` (módulo injectable que coleta
  `CsvProductImportFileParser`/`XlsxProductImportFileParser`, mesmo padrão de
  `CustomerImportParsersModule`).

### Cloud Functions — `functions/src/products/`

- `product-import-shared.ts`: RBAC (`assertCanImportProducts`, OWNER/ADMIN apenas), validação de
  mapeamento/lookup, porte TypeScript de `Sku.parse`/`Ean.parse` (Dart), derivação de SKU de variante
  idêntica a `GenerateProductVariantsUseCase._deriveSku`, `validateProductImportRow`, construtores do
  documento `Product`/`ProductVariant` (shape idêntico a `ProductDto.toJson()`/
  `ProductVariantDto.toJson()`) e porte de `ProductSearchNormalizer` (texto/prefixos de busca, para
  que um produto importado já seja encontrável por `FirestoreProductRemoteSearchDataSource`).
- `start-product-import-job.ts`: callable `startProductImportJob`.
- `process-product-import-job.ts`: trigger `processProductImportJob` (Firestore
  `onDocumentCreated`), parsing real com `exceljs`, agrupamento de variantes por produto,
  detecção de conflito de SKU/referência, batch de escrita, associação de imagens via
  `bucket.getFiles({prefix})`, relatório em Storage, auditoria.
- `functions/test/products/product-import-shared.test.ts`: 25 testes unitários (SKU válido/inválido,
  EAN-8/EAN-13 válido/inválido com dígito verificador, derivação de SKU de variante incluindo
  fallback por tamanho, validação de mapeamento, validação de lookup, validação de linha completa —
  cor/tamanho/categoria/coleção ausentes do lookup, preço inválido, EAN inválido, linha só com campos
  obrigatórios).

### Testes Flutter

- `test/features/product_import/domain/services/product_import_mapping_validator_test.dart`.
- `test/features/product_import/data/parsers/csv_product_import_file_parser_test.dart`.
- `test/features/product_import/domain/usecases/start_product_import_job_use_case_test.dart`.

## Arquivos alterados

- `lib/core/permissions/capability.dart`: novo `Capability.productImport` ('product.import'),
  concedido automaticamente a OWNER (conjunto completo) e ADMIN (conjunto quase completo) — nunca a
  SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE (mesma amplitude de `Capability.catalogManage`,
  já que importação em massa de catálogo é uma ação de gestão de catálogo, não de CRM). Nenhuma
  mudança em `role_permission_matrix.dart` foi necessária (OWNER/ADMIN recebem qualquer capability
  nova automaticamente pelos seus conjuntos completo/quase completo).
- `firestore.rules` / `storage.rules`: duas coleções novas em `firestore.rules`
  (`productImportTemplates` — CRUD pelo cliente; `productImportJobs` — só leitura, escrita exclusiva
  do Admin SDK), sem necessidade de tocar `roleHasCapability` (OWNER/ADMIN já cobertos pelas
  condições existentes); dois `match` novos em `storage.rules`
  (`organizations/{organizationId}/productImports/{batchId}/{fileName}` para o arquivo-fonte e
  `.../images/{fileName}` para o pacote de imagens).
- `lib/features/audit_log/domain/value_objects/audit_action.dart` +
  `presentation/presenters/audit_log_presenter.dart`: `AuditAction.productImportCompleted` (só
  gravada server-side).
- `lib/core/navigation/app_route_paths.dart` / `app_router.dart`: rota `ProductImportRoute`
  (`/org/:orgId/companies/:companyId/products/import`), protegida por `product.import`.
- `lib/app/bootstrap.dart`: `productImportPageBuilder`.
- `functions/src/index.ts`: exports das 2 Functions novas.
- `docs/tasks/TASKS.md`: checkbox da TASK-168 marcado, progresso 166 → 167/220.

## Decisões técnicas

- **SKU da planilha é o SKU do `Product`, não do `ProductVariant`**: cada linha descreve uma variante
  (cor+tamanho) do produto identificado pelo SKU+referência daquela linha; múltiplas linhas com o
  mesmo SKU dentro do mesmo arquivo são reconhecidas como "mais uma variante do mesmo produto já
  criado nesta execução", nunca como conflito. O SKU real e único de cada `ProductVariant` é sempre
  **derivado** (`{sku}-{códigoDaCor}-{tamanho}`), nunca lido da planilha — mesmo algoritmo que
  `GenerateProductVariantsUseCase` (Dart) já usa para produtos criados manualmente, então uma variante
  importada é indistinguível de uma gerada pelo próprio app.
- **Código de barras (EAN) da planilha vira `ProductVariant.ean`, não `Product.ean`**: no mundo real
  de moda, o código de barras físico é da unidade vendável (cor+tamanho específico), não do modelo —
  mapeamento mais correto que um "EAN do produto" genérico.
- **Preço base é capturado e validado, mas não persistido em nenhum campo**: `Product` não tem campo
  de preço (preço é um domínio à parte, `PriceList`, EPIC-09) e esta task explicitamente "não cria nem
  gerencia políticas de tabela de preço" (`tasks.md`). O valor é só validado (número não-negativo) para
  não deixar passar lixo, mas fica documentado como uma lacuna de produto conhecida — um follow-up
  natural seria decidir como um preço importado alimenta uma Price List real.
- **Associação de imagem é por SKU/referência do produto, não por cor**: uma imagem carrega o mesmo
  papel para todas as variantes (cores) de um produto nesta primeira versão — a granularidade "uma
  imagem por cor" já existe no modelo (`ProductMedia.colorId`) mas não é usada por esta task, para
  manter o escopo do "pacote de imagens simples" descrito em `tasks.md`.
- **Pacote de imagens é uma seleção multi-arquivo, não um único `.zip`**: `tasks.md` menciona
  "zip/pasta"; como não havia nenhuma dependência de descompactação de zip no projeto (`functions/
  package.json` não tem `adm-zip`/`unzipper`/`jszip`), optei por reaproveitar exatamente o mecanismo já
  existente de upload multi-arquivo para Storage (o mesmo usado por mídia de produto) em vez de
  adicionar uma dependência nova só para este caso — cada imagem é enviada individualmente para
  `.../productImports/{batchId}/images/`, e a Function lista esse prefixo com `bucket.getFiles`. O
  resultado funcional (associação automática por nome de arquivo, órfãs reportadas) é o mesmo; a
  única diferença é que o gestor seleciona várias imagens em vez de um zip.
- **Nenhum compartilhamento de código físico com `customer_import/` (TASK-167)**: a task pedia para
  generalizar a infraestrutura de TASK-167; a instrução operacional desta rodada, porém, restringiu
  explicitamente qualquer alteração em arquivos fora do escopo da TASK-168 — então `product_import/`
  foi implementada em paralelo, replicando a mesma estrutura/convenções (não o mesmo código), sem
  tocar nenhum arquivo de `customer_import/`. Uma extração real para um `lib/core/import/` compartilhado
  é um refactor legítimo de follow-up, não feito aqui por esse motivo.

## Comandos executados e resultados reais

- `flutter pub get` — ok.
- `dart run build_runner build` — gerou os `.freezed.dart` das 7 entidades novas e todo o
  `injection.config.dart` (registro de 8 use cases, 3 datasources, 2 repositórios, 1 bloc, 2 parsers +
  o módulo `List<ProductImportFileParser>`). Os mesmos avisos de "missing dependency" pré-existentes
  já documentados em `TASK-167-...-CONCLUIDA.md` (`PushDeviceMapper`, `ResolvePriceForVariantUseCase`,
  etc.) aparecem no log — confirmados como não relacionados a esta task.
- `flutter analyze --no-fatal-infos` (feature completa + arquivos alterados, e depois o projeto
  inteiro) — **0 erros** em ambos. Restam só infos pré-existentes/não relacionados (`deprecated_member_use`
  em `report_builder_page.dart`, `use_null_aware_elements` em código antigo) mais 2 infos equivalentes
  no código novo (mesmo padrão `if (x != null) 'key': x` já usado sem reclamação em `CustomerDto
  .toJson()`).
- `dart format --set-exit-if-changed .` (nos arquivos desta task) — 5 arquivos reformatados
  automaticamente na primeira passada (imports/quebras de linha), 0 alterações na segunda passada.
- `flutter test test/features/product_import` — **17/17 passando**.
- `flutter test test/core/permissions test/features/audit_log test/core/navigation
  test/features/customer_import test/features/products/presentation/pages/product_form_page_test.dart`
  — todos passando (nenhuma regressão nas áreas tocadas: capability nova, rotas, `AuditAction` novo).
- `flutter test` (suíte completa) — **2985 testes, 2 falhas**, ambas confirmadas **pré-existentes**:
  fiz `git stash -u` (removendo todas as mudanças desta task) e rodei os mesmos dois arquivos contra o
  HEAD original (`de2123e`) — as duas falhas (`test/app/bootstrap_test.dart` e
  `test/core/analytics/analytics_events_test.dart`) já existiam antes desta task, pela mesma causa já
  documentada em `TASK-167-...-CONCLUIDA.md` (`GetIt: Object/factory with type PushDeviceMapper is not
  registered` em `configurePushNotificationLifecycle`, e uma contagem de taxonomia de analytics já
  desatualizada — nenhuma delas relacionada a produtos/importação). Depois de confirmar, `git stash
  pop` restaurou tudo.
- `cd functions && npx tsc --noEmit -p tsconfig.json` — 0 erros.
- `cd functions && npx eslint src/products test/products` — 0 problemas.
- `cd functions && npx jest test/products/product-import-shared.test.ts` — **25/25 passando**.

## Riscos e pendências conhecidas

- **Testes de Firestore/Storage Security Rules não escritos nesta sessão** (mesmo bloqueio de
  ambiente sem Java/Emulator já documentado em TASK-166/TASK-167) — as regras novas
  (`productImportTemplates`/`productImportJobs`/paths de Storage) seguem exatamente o padrão já
  testado de `customerImportTemplates`/`customerImportJobs`/`customerImports`, mas não foram
  exercitadas contra o Emulator. Ficam como próximo incremento razoável, análogo ao mesmo risco já
  aceito em TASK-167.
- **Gap arquitetural pré-existente, não introduzido por esta task**: `SharedPreferencesProductRepository`
  (e as de `Category`/`Collection`/`ProductColor`/`SizeGridTemplate`) ainda só persistem localmente —
  os produtos importados por esta task são gravados corretamente em `organizations/{orgId}/products`
  (Firestore, mesmo shape que o futuro sync remoto vai esperar, e já lido de verdade por
  `FirestoreProductRemoteSearchDataSource`/busca), mas **não aparecerão nas telas de gestão de catálogo
  local** (`ProductFormPage`, listas de categoria/coleção) até que o sync remoto de leitura dessas
  entidades exista. Documentado com a mesma honestidade que TASK-167 já aplicou ao gap equivalente de
  `Customer`.
- **Resolução de categoria/coleção/cor/tamanho é só sobre a prévia (20 linhas) no wizard**: a
  validação *autoritativa* acontece sempre server-side contra o `ProductImportLookup` enviado (nunca
  inferida), mas a UI só consegue *mostrar* ao gestor, antes de submeter, os nomes distintos vistos nas
  primeiras 20 linhas — um nome incomum que só aparece a partir da linha 21 ainda é corretamente
  validado/rejeitado pela Function, só não aparece antecipadamente na tela de mapeamento. Mesma
  limitação, em espírito, que a prévia limitada de TASK-167.
- **`loadExistingProductIndex` carrega todo o catálogo `products` da organização em memória** dentro
  da Function, uma vez por job — aceitável para catálogos de milhares de SKUs (o público-alvo desta
  task), não para dezenas de milhares; mesma limitação de escala já aceita e documentada para
  `loadExistingCustomerIndex` (TASK-167).
- **Testes de widget do bloc/relatório completos (mapeamento visual, 4 cenários de relatório, carga de
  milhares de linhas) descritos em "Testes obrigatórios" da task não foram criados nesta sessão** — o
  risco mais alto (parsing, validação de SKU/EAN/cor/tamanho/categoria/coleção, derivação de SKU de
  variante, agrupamento de variantes por produto) já está coberto por 42 testes automatizados (17
  Flutter + 25 Node) que rodaram e passaram de verdade nesta sessão; testes de bloc/widget adicionais
  ficam como próximo incremento razoável, não bloqueando a entrega da funcionalidade real.
- **Nenhum ponto de entrada de navegação (botão "Importar produtos") foi adicionado a uma tela de
  catálogo** — a rota (`ProductImportRoute`) está registrada e protegida por RBAC, alcançável por URL
  direta, mas o app ainda não tem uma tela de "lista/gestão administrativa de produtos" onde um botão
  permanente faria sentido (`ProductSearchPage` hoje só é usada embutida como seletor de produto em
  outro fluxo, ex. `campaign_form_page.dart`). Adicionar esse botão é um passo pequeno assim que essa
  tela existir — não fiz uma inserção semanticamente errada só para ter um botão em algum lugar.
