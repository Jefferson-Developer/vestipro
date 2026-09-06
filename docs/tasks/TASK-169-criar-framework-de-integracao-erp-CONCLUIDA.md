# TASK-169 — Criar framework de integração com ERPs — CONCLUÍDA

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Data de conclusão:** 2026-09-06
**Agente utilizado:** `flutter-senior-architect` (framework server-side/Cloud Functions; task sem
componente de UI — ver "Decisão: sem UI" abaixo).

## Resumo

Implementado o framework de integração com ERPs (EPIC-22) descrito em `docs/tasks/TASK-169-criar-
framework-de-integracao-erp.md`, inteiramente como uma nova feature server-side
`functions/src/erp_integration/` (nada equivalente existia — verificado antes de codar:
`grep -ri erp functions/src lib` só retornava a linha "integrações ERP" da lista de tasks futuras em
`tasks.md`, seção 19).

O framework entrega, de ponta a ponta:

- **Contrato único `ErpAdapter`** (`types.ts`): `pullInventory`/`pullPrices`/`pushOrder`/
  `pushCustomer`, independente do ERP concreto.
- **Adapter de referência `GenericRestErpAdapter`** (`adapters/generic-rest-erp-adapter.ts`): fala com
  um endpoint REST genérico e configurável por organização (`baseUrl` + caminho por operação),
  cobrindo o caso "ERP expõe uma API HTTP simples" citado na task.
- **Registry extensível** (`adapters/erp-adapter-registry.ts`): adicionar um adapter concreto (SAP,
  TOTVS, Linx...) é registrar uma nova classe, nunca editar o núcleo de fila/processamento —
  verificado em teste (`erp-adapter-registry.test.ts`, "adiciona um adapter novo sem tocar no
  registry/no núcleo").
- **Mapeamento de campos configurável por organização, sem deploy** (`saveErpIntegrationConfig`):
  cada organização mapeia `campoDoErp -> campoDoVestiPro` dentro de uma whitelist por tipo de entidade
  (`ERP_MANAGEABLE_FIELDS_BY_ENTITY`) — nunca um campo arbitrário/sensível
  (`organizationId`, `version`, campos de pedido, preço definitivo, saldo real de estoque).
- **Fila de sincronização bidirecional** (`erpSyncQueue`, `enqueueErpSyncItem`): um documento por
  registro/evento, nunca um lote monolítico — é essa granularidade que garante, por construção, que
  a falha de um item nunca compromete os demais (critério de aceite da task).
- **Idempotência real** (`computeIdempotencyKey` + ledger `erpProcessedEvents`): a chave é um hash
  determinístico de `organização + direção + tipo de entidade + id externo + versão do ERP`;
  reprocessar o mesmo evento (retry, redelivery, corrida) nunca duplica a aplicação — testado em
  `erp-integration-shared.test.ts`.
- **Falha parcial isolada + retry com backoff** (`process-erp-sync-queue-item.ts`,
  `retry-failed-erp-sync-items.ts`): item com erro fica `failed` com `attempts`/`lastError`/
  `nextRetryAt` (backoff 5/15/60/240/1440 min, teto de 5 tentativas), sem afetar nenhum outro item;
  esgotadas as tentativas, fica `failed` para intervenção manual (nunca perdido).
- **Log de sincronização por organização** (`erpSyncLogs`): um registro por item processado
  (`success`/`failed`/`conflict`/`skipped_duplicate`/`skipped_not_found` + mensagem de erro), nunca o
  payload de credenciais.
- **Resolução de conflito reaproveitando a política já definida** (`erp-integration-shared.ts`,
  `field-merge.ts`): `erpConflictPolicyFor` espelha exatamente `ConflictPolicyCatalog.policyFor`
  (`lib/core/sync/domain/conflict_policy_catalog.dart`, TASK-110) — `customer -> field_merge`
  (a mesma política do Dart para `OutboxEntityType.customer`), `inventory`/`price -> last_write_wins`
  (só escrevem em campos informativos que nada mais escreve, mesmo raciocínio do Dart para
  `crmActivity`). O merge em si (`computeErpFieldMerge`) é uma portagem TypeScript algoritmo-por-
  algoritmo de `ConflictFieldMerge.compute` (Dart) — inclusive o comportamento "um único campo em
  conflito bloqueia o merge inteiro, nunca aplica parcialmente", testado explicitamente.
- **Isolamento multi-tenant**: todo path Firestore desta feature passa por um único conjunto de
  helpers (`erpIntegrationConfigRef`/`erpSyncQueueCollection`/...) sempre sob
  `organizations/{organizationId}/...` — não há nenhum outro ponto do código que monte esse caminho.
  `firestore.rules` reforça isso: o read de `erpIntegration/credentials` é **sempre** negado (nenhuma
  capability libera), e todo o resto exige `erpIntegration.manage` (nova
  `Capability.erpIntegrationManage`, restrita a OWNER/ADMIN).

## Decisão de escopo: onde a sincronização de entrada realmente escreve

Para não violar a regra "nunca corromper estoque/preço" (organização/`AGENTS.md`) com um framework
*base* ainda sem um ERP concreto por trás, a sincronização de entrada (`inbound`) só escreve em dois
lugares:

1. **`customer`**: no documento real de `customers` (casado pelo campo natural `document`,
   exatamente a mesma chave de conciliação que `customer-import-shared.ts`/TASK-167 já usa), **com**
   a política de conflito completa (merge de três vias base/local/remoto). Um `document` do ERP que
   não corresponde a nenhum cliente existente nunca cria um cliente novo — criação em massa continua
   sendo o fluxo dedicado e com dedupe da TASK-167; este framework só concilia um cliente que já
   existe.
2. **`inventory`/`price`**: apenas em uma coleção de *staging* (`erpSyncedRecords`), em campos
   informativos (`erpQuantityOnHand`/`erpUnitCost`) — nunca nos campos reais
   `quantityOnHand`/`reservedQuantity` (motor de reserva de estoque, TASK-089/090) nem em qualquer
   campo de `PriceList` (o preço definitivo continua exclusivamente server-side/engine de
   precificação, por regra de arquitetura). Resolver código de SKU/armazém do ERP para
   `variantId`/`warehouseId` reais é responsabilidade de um adapter concreto futuro, deliberadamente
   fora do escopo desta task-base (a própria TASK-169 já delimita isso: "implementações específicas
   de ERPs concretos ficam fora do escopo desta task base").

`pushOrder`/`pushCustomer` (saída) estão implementados no contrato/registry/processamento da fila
(`direction: 'outbound'`), mas **não foram fiadas** em `submit-order.ts` nem em nenhum outro ponto do
fluxo de pedidos — isso exigiria decidir, por task própria, quando/quais pedidos disparam envio ao
ERP, risco desnecessário para uma task de framework. `enqueueErpSyncItem` está exportado
publicamente (`erp_integration/index.ts`) exatamente para uma task futura (ex.: uma TASK dedicada de
"enviar pedido aprovado ao ERP") chamá-lo sem reescrever nada aqui.

## Arquivos criados

- `functions/src/erp_integration/types.ts` — vocabulário/contrato (`ErpAdapter`,
  `InboundErpEntityType` vs. `ErpEntityType`, etc.).
- `functions/src/erp_integration/erp-integration-shared.ts` — RBAC, whitelist de campos por
  entidade, `erpConflictPolicyFor`, validação/aplicação de mapeamento, idempotência, helpers de path.
- `functions/src/erp_integration/field-merge.ts` — porte TS de `ConflictFieldMerge` (Dart, TASK-110).
- `functions/src/erp_integration/erp-config-loader.ts` — leitura tenant-scoped de config/credenciais.
- `functions/src/erp_integration/enqueue-erp-sync-item.ts` — único ponto que cria um item de fila.
- `functions/src/erp_integration/process-erp-sync-queue-item.ts` — núcleo de processamento (trigger
  `onDocumentCreated` + função pura reaproveitada pelo retry).
- `functions/src/erp_integration/pull-erp-inventory-and-prices.ts` — produtor agendado
  (`onSchedule`, hora em hora) que chama `pullInventory`/`pullPrices` por organização.
- `functions/src/erp_integration/retry-failed-erp-sync-items.ts` — produtor agendado (a cada 15 min)
  que reprocessa itens `failed` dentro do backoff/tentativas.
- `functions/src/erp_integration/save-erp-integration-config.ts` — callable (OWNER/ADMIN) que salva
  adapter/mapeamento/conexão (nunca credenciais).
- `functions/src/erp_integration/save-erp-integration-credentials.ts` — callable (OWNER/ADMIN) que
  salva credenciais num documento nunca lido de volta a nenhum cliente.
- `functions/src/erp_integration/adapters/erp-adapter-registry.ts` — registry extensível.
- `functions/src/erp_integration/adapters/generic-rest-erp-adapter.ts` — adapter de referência REST.
- `functions/src/erp_integration/index.ts` — barrel.
- `functions/test/erp_integration/field-merge.test.ts` (6 casos)
- `functions/test/erp_integration/erp-integration-shared.test.ts` (18 casos)
- `functions/test/erp_integration/adapters/generic-rest-erp-adapter.test.ts` (5 casos)
- `functions/test/erp_integration/adapters/erp-adapter-registry.test.ts` (4 casos)
- `docs/tasks/TASK-169-criar-framework-de-integracao-erp-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `functions/src/index.ts` — exporta as 5 Cloud Functions novas
  (`saveErpIntegrationConfig`/`saveErpIntegrationCredentials`/`processErpSyncQueueItem`/
  `pullErpInventoryAndPrices`/`retryFailedErpSyncItems`).
- `firestore.rules` — nova seção `organizations/{organizationId}/erpIntegration|erpSyncQueue|
  erpSyncLogs|erpConflicts|erpSyncedRecords|erpProcessedEvents` (todo write é server-owned;
  `erpIntegration/credentials` nunca tem read liberado para nenhum client, sob nenhuma capability).
- `lib/core/permissions/capability.dart` — nova `Capability.erpIntegrationManage`
  (`'erpIntegration.manage'`). Não foi necessário alterar `role_permission_matrix.dart`: OWNER
  (`Capability.values` completo) e ADMIN (`Capability.values` menos
  `organizationTransferOwnership`) já recebem qualquer capability nova por construção.
- `test/core/permissions/role_permission_matrix_test.dart` — novo caso "only OWNER/ADMIN can
  configure ERP integrations".
- `docs/tasks/TASKS.md` — checkbox da TASK-169 marcado e progresso atualizado para `168 / 220`.

## Decisão: sem UI nesta task

A própria task declara a dependência "roda como Cloud Functions/jobs server-side" e todo o escopo
técnico (`ErpAdapter`, fila, mapeamento, idempotência, log) é infraestrutura server-side. Não existe,
hoje, nenhuma tela de configuração de integração ERP no app nem foi pedida explicitamente pela task
(a seção "Arquivos prováveis" da própria task deixa em aberto "a definir pelo agente executor").
`saveErpIntegrationConfig`/`saveErpIntegrationCredentials` já expõem tudo que uma futura tela
("Configurações > Integrações > ERP") precisaria chamar — construir essa tela é trabalho de UI/UX
razoável para uma task própria (com o `flutter-ui-design-specialist`), não para esta.

## Validações executadas (reais, executadas nesta sessão)

- `cd functions && npx tsc --noEmit -p tsconfig.json` — 0 erros.
- `cd functions && npx eslint src/erp_integration test/erp_integration` — 0 problemas (também rodado
  `npx eslint src test` no diretório inteiro de `functions` — 0 problemas, nada quebrado).
- `cd functions && npx jest test/erp_integration --silent` — **33/33 passando** (4 suítes:
  `field-merge`, `erp-integration-shared`, `adapters/generic-rest-erp-adapter`,
  `adapters/erp-adapter-registry`).
- `flutter analyze lib/core/permissions` — "No issues found!".
- `flutter test test/core/permissions/role_permission_matrix_test.dart
  test/core/permissions/permission_service_test.dart` — **29/29 passando** (nenhum teste existente
  quebrou com a nova capability).
- `dart format --set-exit-if-changed lib/core/permissions/capability.dart
  test/core/permissions/role_permission_matrix_test.dart` — formatado (o teste precisou de uma
  reformatação automática de quebra de linha, aplicada e reverificada; `capability.dart` já estava
  formatado).

## Riscos e pendências conhecidas

- **Testes de Firestore Security Rules não escritos/executados nesta sessão** — mesmo bloqueio de
  ambiente sem Java/Firestore Emulator já documentado em TASK-166/167/168 (`java`/`JAVA_HOME`
  ausentes neste ambiente, confirmado nesta sessão). As regras novas seguem exatamente o padrão já
  em produção de `productImportJobs`/`customerImportJobs` (server-owned, `allow write: if false`),
  mas não foram exercitadas contra o Emulator. Mesmo risco aceito, mesmo motivo, mesma recomendação:
  próximo incremento razoável assim que o pipeline de CI (TASK-165, que já roda contra o Emulator)
  cobrir este arquivo.
- **`pushOrder`/`pushCustomer` (saída) não estão fiados a nenhum gatilho real de negócio** — o
  contrato/fila/processamento existem e estão testados isoladamente, mas nenhuma Cloud Function do
  domínio de pedidos (`submit-order.ts`) os chama ainda. Decisão deliberada (ver seção acima); listar
  como trabalho futuro explícito para quem wiring o primeiro ERP concreto.
- **Sincronização de entrada de `inventory`/`price` fica em staging, não nas coleções reais** —
  decisão deliberada (ver seção acima) para nunca arriscar corromper estoque/preço com um framework
  ainda sem ERP concreto por trás; documentado para o próximo adapter concreto resolver
  SKU/armazém externo -> `variantId`/`warehouseId` antes de escrever nas coleções reais.
- **Nenhuma tela de configuração de integração ERP** — ver "Decisão: sem UI nesta task" acima.
- **`pullErpInventoryAndPrices`/`retryFailedErpSyncItems` (Cloud Scheduler) não foram testados em
  execução real** (dependem do Cloud Scheduler + de um ERP real por trás do adapter de referência,
  nenhum dos dois disponível neste ambiente de desenvolvimento) — a lógica pura que cada um chama
  (`pullErpDataForAllOrganizations`/`retryFailedErpSyncItemsForAllOrganizations`) reaproveita, campo a
  campo, o mesmo padrão de `expireStockReservationsForAllOrganizations` (TASK-092), já em produção.
