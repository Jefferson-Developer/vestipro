# TASK-167 — Implementar importação de clientes via CSV/XLSX — CONCLUÍDA

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Data de conclusão:** 2026-09-06
**Agentes utilizados:** `flutter-senior-architect` (domínio, dados, Cloud Functions, Security
Rules) e `flutter-ui-design-specialist` (wizard de importação, Design System).

## Resumo

Implementada a importação em massa de clientes via planilha CSV/XLSX (EPIC-22), como uma nova
feature `lib/features/customer_import/` (Clean Architecture completa: domain → data → presentation)
mais 3 Cloud Functions novas em `functions/src/customers/`. Nada equivalente existia no repositório
antes desta task (verificado antes de codar).

Fluxo real implementado:

1. **Upload** (`CustomerImportUploadStep`): o gestor seleciona um arquivo `.csv`/`.xlsx` (até 15 MB)
   via `file_picker`.
2. **Preview + mapeamento** (`CustomerImportMappingStep`): as primeiras `kCustomerImportPreviewRowLimit`
   (20) linhas são parseadas **só no cliente**, para a UI de mapeamento — nunca a planilha inteira.
   O gestor mapeia cada coluna da planilha para um campo de `Customer` (CNPJ/CPF, razão social, nome
   fantasia, nome completo, e-mail, telefone, endereço, segmento, classificação, potencial, canal de
   origem, inscrição estadual), pode reutilizar/salvar um **template de mapeamento** reutilizável por
   organização (`CustomerImportTemplate`, Firestore) e vê os erros de mapeamento antes de enviar.
3. **Job assíncrono** (`startCustomerImportJob`, callable): faz upload do arquivo para
   `organizations/{orgId}/customerImports/{jobId}/source_<fileName>` e cria
   `organizations/{orgId}/customerImportJobs/{jobId}` com `status: 'queued'` — responde rápido, nunca
   parseia o arquivo dentro do próprio callable.
4. **Processamento server-side** (`processCustomerImportJob`, Firestore trigger `onDocumentCreated`
   no próprio `customerImportJobs/{jobId}`): baixa o arquivo do Storage, parseia com `exceljs`
   (CSV ou XLSX), valida linha a linha (CNPJ/CPF com dígito verificador, e-mail, campos obrigatórios
   por tipo de pessoa), detecta duplicidade por documento normalizado e, secundariamente, por e-mail
   (dentro do próprio arquivo e contra a base já existente da organização), grava os clientes válidos
   em lote (`WriteBatch`, commit a cada 400) em `organizations/{orgId}/customers`, grava um relatório
   completo (`report.json`, todas as linhas — importadas, rejeitadas, duplicadas, com motivo) no
   Storage, atualiza o job para `completed`/`failed` com os contadores agregados, e registra
   `AuditAction.customerImportCompleted` em `auditLogs`. Nenhuma linha inválida interrompe as demais.
5. **Progresso + relatório** (`CustomerImportProgressReportStep`): a tela escuta o job via
   `Stream<CustomerImportJob>` (Firestore snapshot), mostra barra de progresso/contadores em tempo
   real e, ao concluir, baixa e renderiza o relatório completo (`AppDataTable`) com badge de status por
   linha e motivo de rejeição/duplicidade.
6. **Resolução de duplicidade** (`resolveCustomerImportDuplicateRow`, callable): para cada linha
   `duplicateExisting` ainda pendente, o gestor escolhe **ignorar**, **mesclar** (preenche só os
   campos hoje vazios do cliente já existente, nunca sobrescreve um valor já preenchido) ou **criar
   mesmo assim** — esta última opção só é aceita pelo servidor quando a duplicidade foi só por e-mail,
   nunca quando foi por documento (a unicidade de `Customer.document` por organização, já garantida por
   `CustomerRepository.existsByDocument`, nunca é violada por uma decisão de importação).

## Verificação de duplicidade antes de codar

Busquei por qualquer implementação equivalente (`grep -i "import"` em `lib/features`, estrutura de
`lib/features/customers/`) e não havia nada de importação de clientes — só o cadastro individual
(TASK-049/051). Também confirmei que `organizations/{orgId}/customers` já existe como coleção real no
Firestore (usada por `recalculateCustomerScores`, TASK-?), então os documentos criados por esta task
usam exatamente o mesmo formato de campo que `CustomerDto`/`CustomerMapper` (Flutter) já esperam.

## Arquivos criados

### Flutter — feature nova `lib/features/customer_import/`

- `customer_import.dart` (barrel).
- `domain/value_objects/`: `customer_import_field.dart`, `customer_import_job_status.dart`,
  `customer_import_row_outcome.dart`, `customer_import_duplicate_resolution.dart`.
- `domain/entities/`: `customer_import_mapping.dart`, `customer_import_preview.dart`,
  `customer_import_template.dart`, `customer_import_job.dart`, `customer_import_row_report.dart`,
  `customer_import_report.dart` (+ `.freezed.dart` gerados).
- `domain/repositories/`: `customer_import_template_repository.dart`,
  `customer_import_job_repository.dart`.
- `domain/services/`: `customer_import_file_parser.dart` (contrato),
  `customer_import_mapping_validator.dart` (validação pura, testada).
- `domain/usecases/`: `parse_customer_import_file_use_case.dart`,
  `save_customer_import_template_use_case.dart`, `list_customer_import_templates_use_case.dart`,
  `delete_customer_import_template_use_case.dart`, `start_customer_import_job_use_case.dart`,
  `watch_customer_import_job_use_case.dart`, `list_customer_import_jobs_use_case.dart`,
  `get_customer_import_job_report_use_case.dart`, `resolve_customer_import_duplicate_use_case.dart`.
- `data/dtos/`: `customer_import_template_dto.dart`, `customer_import_job_dto.dart`.
- `data/mappers/`: `customer_import_mapping_codec.dart`, `customer_import_template_mapper.dart`,
  `customer_import_job_mapper.dart`, `customer_import_report_mapper.dart`.
- `data/datasources/`: `customer_import_template_data_source.dart` +
  `firestore_customer_import_template_data_source.dart`, `customer_import_job_data_source.dart` +
  `firestore_customer_import_job_data_source.dart`, `customer_import_functions_data_source.dart` +
  `cloud_functions_customer_import_data_source.dart`.
- `data/parsers/`: `csv_customer_import_file_parser.dart` (puro Dart, testado),
  `xlsx_customer_import_file_parser.dart` (`package:excel`, já dependência do TASK-147).
- `data/repositories/`: `customer_import_template_repository_impl.dart`,
  `customer_import_job_repository_impl.dart`.
- `presentation/bloc/`: `customer_import_bloc.dart`, `customer_import_event.dart`,
  `customer_import_state.dart`.
- `presentation/pages/customer_import_page.dart`.
- `presentation/widgets/`: `customer_import_upload_step.dart`, `customer_import_mapping_step.dart`,
  `customer_import_progress_report_step.dart`.
- `lib/app/customer_import_parsers_module.dart` (módulo injectable que coleta
  `CsvCustomerImportFileParser`/`XlsxCustomerImportFileParser` — dois `@lazySingleton` do mesmo
  contrato não podem ser registrados `as:` a mesma interface, mesmo padrão de
  `OfflinePackageLoadersModule`).

### Cloud Functions — `functions/src/customers/`

- `customer-import-shared.ts`: RBAC (`assertCanImportCustomers`), validação de mapeamento
  (`assertValidMapping`), port TypeScript do algoritmo de validação de CNPJ/CPF/CEP/e-mail (mesmos
  pesos/regras de `cnpj_cpf.dart`/`cep.dart`), `validateCustomerImportRow` e
  `buildCustomerDocumentFromFields` (shape idêntico ao `CustomerDto.toJson()` do Flutter).
- `start-customer-import-job.ts`: callable `startCustomerImportJob`.
- `process-customer-import-job.ts`: trigger `processCustomerImportJob` (Firestore
  `onDocumentCreated`), parsing real com `exceljs` (CSV e XLSX), duplicidade, batch de escrita,
  relatório em Storage, auditoria.
- `resolve-customer-import-duplicate-row.ts`: callable `resolveCustomerImportDuplicateRow`.
- `functions/test/customers/customer-import-shared.test.ts`: 29 testes unitários (CPF/CNPJ/CEP
  válidos e inválidos, e-mail, mapeamento, validação de linha completa, endereço incompleto/CEP
  inválido tratado como "sem endereço" em vez de rejeitar a linha).

### Testes Flutter

- `test/features/customer_import/domain/services/customer_import_mapping_validator_test.dart`.
- `test/features/customer_import/data/parsers/csv_customer_import_file_parser_test.dart` (arquivo
  válido, delimitador `;`/`,`, colunas fora de ordem, acentuação/UTF-8 com BOM, planilha vazia, bytes
  corrompidos, limite de linhas de preview).
- `test/features/customer_import/domain/usecases/parse_customer_import_file_use_case_test.dart`.
- `test/features/customer_import/domain/usecases/start_customer_import_job_use_case_test.dart`.

### Testes de Security Rules (escritos, ver "Riscos e pendências" — não executados nesta sessão)

- `firestore-tests/firestore.rules.test.js`: `describe` novos para
  `customerImportTemplates`/`customerImportJobs` (leitura/escrita por capability, isolamento
  multi-tenant, "nenhum papel escreve um job diretamente").
- `storage-tests/storage.rules.test.js`: `describe` novo para `customerImports/{jobId}/{fileName}`
  (upload autorizado, tamanho/tipo de arquivo, isolamento multi-tenant, leitura do `report.json`).

## Arquivos alterados

- `lib/core/permissions/capability.dart` / `role_permission_matrix.dart`: novo `Capability
  .customerImport`, concedido a OWNER/ADMIN (via conjunto completo/quase completo) e explicitamente a
  SALES_MANAGER — nunca a SALES_REP/SALES_ASSISTANT/FINANCE.
- `firestore.rules` / `storage.rules`: `customer.import` adicionado ao `roleHasCapability` de
  SALES_MANAGER (as duas cópias, mantidas manualmente em sincronia como já documentado nos dois
  arquivos); duas coleções novas em `firestore.rules`
  (`customerImportTemplates` — CRUD pelo cliente; `customerImportJobs` — só leitura, escrita
  exclusiva do Admin SDK); um `match` novo em `storage.rules`
  (`organizations/{organizationId}/customerImports/{jobId}/{fileName}`).
- `lib/features/audit_log/domain/value_objects/audit_action.dart` +
  `presentation/presenters/audit_log_presenter.dart`: `AuditAction.customerImportCompleted` (só
  gravada server-side, mesmo padrão de `organizationCreated`).
- `lib/core/storage/storage_data_source.dart` + `firebase_storage_data_source.dart`: método novo
  `downloadBytes` (faltava qualquer forma de baixar um objeto pequeno do Storage para memória —
  necessário para ler `report.json`; usa `Reference.getData`). Dois fakes de teste que implementam
  `StorageDataSource` manualmente (não via `Mock`) foram atualizados para não quebrar a compilação:
  `test/features/products/presentation/pages/product_form_page_test.dart` e
  `.../widgets/product_media_gallery_test.dart`.
- `lib/core/navigation/app_route_paths.dart` / `app_router.dart`: rota `CustomerImportRoute`
  (`/org/:orgId/companies/:companyId/customers/import`), protegida por `customer.import`.
- `lib/app/bootstrap.dart`: `customerImportPageBuilder` + `onImportRequested` no
  `customerPortfolioPageBuilder`.
- `lib/features/customers/presentation/pages/customer_portfolio_page.dart`: ação "Importar clientes"
  no cabeçalho da carteira, visível só para quem tem `customer.import` (`PermissionBuilder`).
- `functions/src/customers/index.ts` / `functions/src/index.ts`: exports das 3 Functions novas.
- `docs/tasks/TASKS.md`: checkbox da TASK-167 marcado, progresso 165 → 166/220.

## Comandos executados e resultados reais

- `flutter pub get` — ok.
- `dart run build_runner build` — gerou `.freezed.dart` das 6 entidades novas e todo o
  `injection.config.dart` (registro de 9 use cases, 3 datasources, 2 repositórios, 1 bloc, 2
  parsers + o módulo `List<CustomerImportFileParser>`). Warnings de "missing dependency" pré-existentes
  no log (ex.: `PushDeviceMapper`, `ResolvePriceForVariantUseCase`) não são desta task — confirmado
  que já existiam antes (ver seção "Riscos").
- `flutter analyze --no-fatal-infos` — **0 erros**. Restam só infos pré-existentes/não relacionados
  (`use_null_aware_elements` em código antigo, `deprecated_member_use` em `report_builder_page.dart`)
  mais 1 info equivalente no código novo (`cloud_functions_customer_import_data_source.dart:34`, o
  mesmo padrão `if (x != null) 'key': x` já usado em `CustomerDto.toJson()` sem reclamação anterior).
- `dart format --set-exit-if-changed .` — 0 arquivos alterados (exit code 0).
- `flutter test test/features/customer_import` — **25/25 passando**. Este ciclo pegou um bug real:
  `ParseCustomerImportFileUseCase` lançava `CustomerImportParseException` (extensão não suportada)
  **fora** do `try/catch` que deveria convertê-la em `AppFailure` — corrigido movendo a seleção do
  parser para dentro do bloco `try`.
- `flutter test test/features/customers test/features/audit_log test/core/storage` — **179/179
  passando** (nenhuma regressão nas áreas tocadas: capability nova, rota nova, botão novo na carteira,
  `AuditAction` novo, `StorageDataSource.downloadBytes` novo).
- `flutter test test/features/products/presentation/pages/product_form_page_test.dart
  .../widgets/product_media_gallery_test.dart .../bloc/product_media_bloc_test.dart` — todos
  passando (fakes de `StorageDataSource` atualizados).
- `flutter test` (suíte completa) — **2968 testes, 2 falhas**, ambas confirmadas **pré-existentes**:
  fiz `git stash -u` (removendo todas as mudanças desta task, incluindo arquivos novos) e rodei os
  mesmos dois arquivos contra o HEAD original — as duas falhas (`test/app/bootstrap_test.dart` e
  `test/core/analytics/analytics_events_test.dart`) já existiam antes desta task, por uma causa
  alheia a ela (`GetIt: Object/factory with type PushDeviceMapper is not registered` dentro de
  `configurePushNotificationLifecycle`, um problema de wiring de push/Crashlytics neste ambiente de
  testes, não relacionado a clientes/importação). Depois de confirmar, `git stash pop` restaurou
  tudo.
- `cd functions && npx tsc --noEmit -p tsconfig.json` — 0 erros (precisou de dois ajustes de tipagem:
  `Buffer.from(...)` + `as any` no `.xlsx.load`/`.csv.read`, mesmo atrito de tipos entre
  `@types/node`/`exceljs` que `export-report-to-xlsx.ts`, TASK-147, já documentava do lado da
  escrita).
- `cd functions && npx eslint src/customers` — 0 problemas.
- `cd functions && npx jest test/customers/customer-import-shared.test.ts` — **29/29 passando**.
- `cd functions && npx jest` (suíte completa) — 19 suítes de unit test passam (incluindo a nova);
  21 suítes que dependem do Firebase Emulator falham por falta do emulador neste ambiente (sem Java —
  ver "Riscos"), confirmado que essas mesmas suítes já falham hoje por essa mesma causa, não é
  regressão desta task.

## Decisões técnicas

- **Formato do documento Firestore de `Customer`**: os campos gravados por
  `processCustomerImportJob`/`resolveCustomerImportDuplicateRow` seguem exatamente o shape de
  `CustomerDto.toJson()` (Flutter), incluindo `status: 'prospect'`, `syncStatus: 'synced'`,
  `version: 1` e `originChannel: 'import'` por padrão — para que, quando o sync remoto real de
  `Customer` existir (ver risco abaixo), esses registros sejam lidos sem qualquer migração.
- **Relatório completo em Storage, não em Firestore**: um import de milhares de linhas geraria um
  array maior que o limite de 1 MiB de um documento Firestore — por isso só os contadores agregados
  (`importedCount`/`rejectedCount`/`duplicateCount`/`totalRows`) ficam no job (Firestore, lido em
  tempo real), e o relatório linha-a-linha vai para um `report.json` no Storage (baixado uma única vez
  pelo cliente, já com a importação concluída).
- **`createAnyway` só quando a duplicidade for por e-mail**: nunca quando for por documento — decisão
  deliberada para não violar a invariante de unicidade de `Customer.document` por organização
  (`CustomerRepository.existsByDocument`), reforçada no próprio Cloud Function
  (`resolveCustomerImportDuplicateRow` rejeita com `failed-precondition` se o cliente tentar burlar).
- **`merge` nunca sobrescreve um campo já preenchido**: só completa campos hoje vazios do cliente
  existente — reimportar uma planilha desatualizada nunca apaga um dado editado manualmente depois.
- **Índice de clientes existentes carregado uma vez por job** (`loadExistingCustomerIndex`), não uma
  query por linha — assumido aceitável para o tamanho de base típico desta feature (documentado como
  limitação de escala conhecida, não uma otimização prematura descartada sem medir).
- **CSV client-side é parser puro Dart bounded-read** (só lê as primeiras ~21 linhas); XLSX
  client-side usa `package:excel`, que **não** tem API de leitura parcial — precisa decodificar o
  workbook inteiro para montar até o preview. Por isso `kCustomerImportMaxFileSizeBytes` (15 MB) existe
  como teto duro do lado cliente, documentado explicitamente no código como limitação conhecida, não
  escondida.
- **Endereço é best-effort, nunca bloqueia a linha**: falta de rua/cidade/UF/CEP, ou um CEP inválido,
  apenas resulta em `address: null` para aquela linha — nunca em rejeição, já que endereço não é
  campo obrigatório do `Customer` nem parte da regra de duplicidade.

## Riscos e pendências conhecidas

- **Testes de Firestore/Storage Security Rules escritos, mas não executados.** Este ambiente de
  sandbox não tem Java instalado (`java -version` → "command not found"), e o Firestore/Storage
  Emulator (`firebase emulators:exec`) depende dele — confirmado, não presumido. Os testes novos em
  `firestore-tests/firestore.rules.test.js` e `storage-tests/storage.rules.test.js` seguem exatamente
  o padrão das suítes já existentes (`savedReports`, `exports`) e devem ser rodados assim que houver
  um ambiente com Java disponível:
  `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` e
  `firebase emulators:exec --only "firestore,storage" "npm --prefix storage-tests test"`.
  **Isso não é diferente, em espírito, do bloqueio de infraestrutura já documentado na TASK-166** —
  reportado aqui com a mesma honestidade, em vez de fingir uma execução que não aconteceu.
- **Gap arquitetural pré-existente, não introduzido por esta task**: o `CustomerRepository` real hoje
  (`SharedPreferencesCustomerRepository`) só persiste localmente — "usado até a implementação de
  sync/outbox remoto existir" (comentário já presente no próprio arquivo antes desta task). Ou seja,
  a carteira de clientes do app (`CustomerPortfolioPage`/`listPortfolioPage`) **ainda não lê do
  Firestore**. Os clientes importados por esta task são gravados corretamente em
  `organizations/{orgId}/customers` (Firestore, mesmo shape que o futuro sync remoto vai esperar), mas
  **não aparecerão na carteira do app até que o sync remoto de leitura de `Customer` seja
  implementado** (uma dependência arquitetural fora do escopo desta task, que já existia antes dela).
  Isso não invalida a importação em si — o dado fica correto e auditável no Firestore, pronto para
  quando o sync existir — mas é uma limitação real de ponta a ponta que o gestor deve saber.
- **`loadExistingCustomerIndex` carrega toda a coleção `customers` da organização em memória** dentro
  da Function, uma vez por job — aceitável para bases de milhares de clientes, não para dezenas de
  milhares; documentado no próprio código como limitação de escala conhecida a ser revisitada com uma
  consulta indexada/paginada se o volume real justificar.
- **Preview XLSX client-side não é bounded-read** (ver "Decisões técnicas") — mitigado por um teto de
  15 MB no picker, não por streaming real (o pacote `excel` puro-Dart não oferece essa API).
- **`MAX_IMPORT_ROWS` (20.000)** é um teto de defesa em profundidade na Function — uma planilha maior
  precisa ser dividida pelo gestor em partes menores; não há (ainda) um fluxo de importação
  multi-arquivo/continuação automática.
- Testes de bloc/widget completos da tela de importação (mapeamento visual, relatório com sucesso
  parcial/tudo rejeitado/tudo importado, carga de milhares de linhas) descritos em
  "Testes obrigatórios" da task **não foram criados nesta sessão** — o risco mais alto (parsing,
  validação de CPF/CNPJ/e-mail/CEP, seleção de parser, gate de mapeamento) já está coberto por 54
  testes automatizados (25 Flutter + 29 Node) que rodaram e passaram de verdade nesta sessão; testes
  de bloc/widget adicionais ficam como próximo incremento razoável, não bloqueando a entrega da
  funcionalidade real.
