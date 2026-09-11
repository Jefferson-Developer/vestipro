# TASK-207 — Concluída (2026-09-10)

## Resumo

Modelada a fundação de domínio/dados do EPIC-32 (Operações Comerciais Avançadas de Moda B2B):
`CommercialPack` (kit/pacote/sortimento vendável), `PackComponent` (item que compõe o pacote,
referenciando variante específica, produto inteiro, cor, tamanho, categoria, coleção ou outro
`CommercialPack` aninhado) e `AssortmentRule` (regra adicional de composição por grade). A entidade
nunca calcula preço final nem reserva estoque — política de preço (`CommercialPackPricingPolicyType`)
e política de estoque (`CommercialPackStockPolicyType`) são contratos apenas, para o motor de
precificação (TASK-088) e o fluxo de pedido/estoque (EPIC-12/EPIC-13) aplicarem depois. Inclui um
validador puro de composição (`ValidateCommercialPackCompositionUseCase`, cobrindo componente
inválido, proporção/quantidade inválida, vigência expirada e composição circular), três casos de uso
de ciclo de vida (`CreateCommercialPackUseCase`, `UpdateCommercialPackUseCase`,
`ReviseCommercialPackUseCase` — este último implementa o versionamento obrigatório de pacote ativo),
cache offline via Drift (`CommercialPacksTable`/`DriftCommercialPackLocalStoreRepository`),
repositório "de produção" (`SharedPreferencesCommercialPackRepository`, mesmo precedente de
`PriceList`/`Customer`/`Product`), e Firestore Security Rules com leitura escopada por organização e
escrita restrita a `OWNER`/`ADMIN`/`SALES_MANAGER` (nova capability `commercialPack.manage`).

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task; escopo é modelagem de
  domínio/dados/Firebase, sem UI).

## Arquivos criados

- `lib/features/commercial_packs/domain/entities/commercial_pack.dart` (+ `.freezed.dart` gerado)
- `lib/features/commercial_packs/domain/entities/pack_component.dart` (+ `.freezed.dart` gerado)
- `lib/features/commercial_packs/domain/entities/assortment_rule.dart` (+ `.freezed.dart` gerado)
- `lib/features/commercial_packs/domain/value_objects/commercial_pack_type.dart`
- `lib/features/commercial_packs/domain/value_objects/commercial_pack_status.dart`
- `lib/features/commercial_packs/domain/value_objects/commercial_pack_sync_status.dart`
- `lib/features/commercial_packs/domain/value_objects/commercial_pack_pricing_policy_type.dart`
- `lib/features/commercial_packs/domain/value_objects/commercial_pack_stock_policy_type.dart`
- `lib/features/commercial_packs/domain/value_objects/pack_component_scope_type.dart`
- `lib/features/commercial_packs/domain/value_objects/pack_component_composition_type.dart`
- `lib/features/commercial_packs/domain/value_objects/assortment_rule_type.dart`
- `lib/features/commercial_packs/domain/repositories/commercial_pack_repository.dart`
- `lib/features/commercial_packs/domain/repositories/commercial_pack_local_store_repository.dart`
- `lib/features/commercial_packs/domain/usecases/validate_commercial_pack_composition_use_case.dart`
- `lib/features/commercial_packs/domain/usecases/create_commercial_pack_use_case.dart`
- `lib/features/commercial_packs/domain/usecases/update_commercial_pack_use_case.dart`
- `lib/features/commercial_packs/domain/usecases/revise_commercial_pack_use_case.dart`
- `lib/features/commercial_packs/data/dtos/commercial_pack_dto.dart`
- `lib/features/commercial_packs/data/dtos/pack_component_dto.dart`
- `lib/features/commercial_packs/data/dtos/assortment_rule_dto.dart`
- `lib/features/commercial_packs/data/mappers/commercial_pack_mapper.dart`
- `lib/features/commercial_packs/data/mappers/commercial_pack_local_mapper.dart`
- `lib/features/commercial_packs/data/repositories/shared_preferences_commercial_pack_repository.dart`
- `lib/features/commercial_packs/data/repositories/drift_commercial_pack_local_store_repository.dart`
- `lib/features/commercial_packs/commercial_packs.dart` (barrel)
- `lib/core/database/tables/commercial_packs_table.dart`
- `test/features/commercial_packs/commercial_pack_test_fakes.dart` (fake in-memory
  `CommercialPackRepository` compartilhado pelos testes de caso de uso)
- `test/features/commercial_packs/domain/entities/commercial_pack_test.dart`
- `test/features/commercial_packs/domain/usecases/validate_commercial_pack_composition_use_case_test.dart`
- `test/features/commercial_packs/domain/usecases/create_commercial_pack_use_case_test.dart`
- `test/features/commercial_packs/domain/usecases/update_commercial_pack_use_case_test.dart`
- `test/features/commercial_packs/domain/usecases/revise_commercial_pack_use_case_test.dart`
- `test/features/commercial_packs/data/dtos/commercial_pack_dto_test.dart`
- `test/features/commercial_packs/data/mappers/commercial_pack_mapper_test.dart`
- `test/features/commercial_packs/data/repositories/shared_preferences_commercial_pack_repository_test.dart`
- `test/features/commercial_packs/data/repositories/drift_commercial_pack_local_store_repository_test.dart`

## Arquivos alterados

- `lib/core/database/app_database.dart`: registra `CommercialPacksTable`, bump `schemaVersion`
  23→24, migração `onUpgrade` (`from < 24` cria a tabela incondicionalmente — tabela nova, mesmo
  precedente das branches `from < 22`/`from < 23`), métodos
  `replaceCommercialPacks`/`upsertCommercialPack`/`getCommercialPacksForOrganization`/
  `countCommercialPacksForOrganization` (todos com `companyId` opcional, mirando
  `replaceProducts`/`getProductsForCompany`, já que `CommercialPack.companyId` também é opcional).
- `lib/core/database/app_database.g.dart`: regenerado via `build_runner` (Drift).
- `lib/core/database/database.dart`: exporta `tables/commercial_packs_table.dart`.
- `lib/core/permissions/capability.dart`: adiciona `Capability.commercialPackManage`.
- `lib/core/permissions/role_permission_matrix.dart`: adiciona `Capability.commercialPackManage` às
  capabilities de `SALES_MANAGER` (OWNER/ADMIN já herdam via conjunto completo/quase completo).
- `lib/app/injection.config.dart`: regenerado via `build_runner` (injectable) — registra os novos
  mappers/repositórios/casos de uso desta feature (nenhuma remoção; apenas adições, ver "Riscos
  conhecidos").
- `firestore.rules`: `roleHasCapability` inclui `'commercialPack.manage'` para `SALES_MANAGER`;
  `validCommercialPackPayload`/`canReadCommercialPack`/`canCreateCommercialPack`/
  `canUpdateCommercialPack` + `match /commercialPacks/{commercialPackId}` (leitura por qualquer
  membro ativo da organização, escrita só com `commercialPack.manage`, `unchanged('packCode')`
  obrigatório no update, `delete` sempre `false`).
- `firestore-tests/firestore.rules.test.js`: `commercialPackDoc()` e
  `describe('organizations/{organizationId}/commercialPacks/{commercialPackId} ...')` com 9 casos
  positivos/negativos.
- `test/core/database/app_database_test.dart`: `schemaVersion` 23→24, `'commercial_packs'` na lista
  de tabelas esperadas.
- `test/core/database/app_database_task_106_schema_test.dart`,
  `test/core/database/app_database_task_114_targets_migration_test.dart`,
  `test/core/database/app_database_task_176_customer_geocoding_migration_test.dart`,
  `test/core/database/app_database_task_177_visit_routes_migration_test.dart`,
  `test/core/database/app_database_task_180_order_signatures_migration_test.dart`,
  `test/core/database/app_database_warehouses_test.dart`: cada um hardcodava
  `expect(database.schemaVersion, 23)` para "schema atual de uma base recém-criada" — atualizados
  para `24` (mesmo bump acima; nenhum outro comportamento desses testes muda).
- `test/core/permissions/role_permission_matrix_test.dart`: novo teste garantindo que só
  OWNER/ADMIN/SALES_MANAGER têm `commercialPackManage`.
- `docs/tasks/TASKS.md`: marca TASK-207 como concluída e atualiza progresso para 203/216.

## Arquitetura utilizada

Clean Architecture feature-first, mesmo padrão de `pricing`/`customers`/`products`: entidades
`freezed` imutáveis em `domain/entities` (`CommercialPack`, `PackComponent`, `AssortmentRule`),
contrato de repositório em `domain/repositories` (`CommercialPackRepository` remoto +
`CommercialPackLocalStoreRepository` offline), casos de uso em `domain/usecases` fazendo toda
validação de negócio (nunca em widget/UI — task não tem escopo de UI). Camada `data/` traduz
para/de `CommercialPackDto` (formato Firestore, `Timestamp`, com `PackComponentDto`/
`AssortmentRuleDto` embutidos como arrays — nunca subcoleções, mesmo precedente `OrderDto.items`) via
`CommercialPackMapper`, e para/de `CommercialPacksTable` (Drift, com `componentsJson`/
`assortmentRulesJson` como colunas de texto JSON — mesmo precedente `CampaignsTable.productIdsJson`)
via `CommercialPackLocalMapper`, delegando os mesmos códigos enum<->string do mapper remoto. O
repositório "de produção" hoje é `SharedPreferencesCommercialPackRepository` — mesmo precedente já
usado por `SharedPreferencesPriceListRepository`/`SharedPreferencesCustomerRepository`/
`SharedPreferencesProductRepository`: mantém o app offline-first enquanto o sync remoto real
(EPIC-14) não existe. Não foi criado um `FirestoreCommercialPackRepository` real nesta task — mesma
decisão e mesmo motivo documentado por TASK-083 para `PriceList` (as Security Rules são testadas
diretamente via JS/emulador, sem depender de código Dart).

## Regras de negócio implementadas

- `CommercialPack` nunca calcula preço final nem reserva estoque: `pricingPolicyType`
  (`componentSum`/`fixedPrice`/`packDiscount`/`bonusItem`) e `stockPolicyType`
  (`consumeComponentBalances`/`dedicatedStock`) — mais os parâmetros que cada um exige
  (`fixedPrice`, `discountPercentage`, `bonusComponentId`, `dedicatedWarehouseId`) — são
  exclusivamente um contrato para o motor de precificação (TASK-088) e o fluxo de
  pedido/estoque aplicarem depois; nenhum método desta feature soma preço nem debita saldo.
- `ValidateCommercialPackCompositionUseCase` (função de domínio pura, sem dependência de
  repositório concreto) rejeita: componente sem `scopeReferenceId`, quantidade zero/negativa em
  composição fixa, `minQuantity`/`maxQuantity` ausente ou invertido em composição flexível,
  proporção fora de `(0, 1]` em composição por grade, regra de sortimento sem os campos que seu
  `AssortmentRuleType` exige, política de preço/estoque sem o parâmetro que exige, e vigência
  (`validTo`) já expirada. Também recebe dois *resolvers* opcionais (nunca implementados aqui,
  apenas o contrato — a resolução real é escopo de TASK-208): `isComponentReferenceValid`
  (variante inativa/produto excluído/coleção fora da organização) e `componentsOfPack` (mapa
  `packId -> componentes`, usado para andar a cadeia de composição e detectar circularidade).
- Composição circular proibida: um pacote não pode conter, direta ou indiretamente, outro pacote
  que já contenha o primeiro (`PackComponentScopeType.commercialPack`, o único scope que permite
  aninhar um `CommercialPack` dentro de outro). Detectado via busca em profundidade sobre o grafo
  de componentes, com proteção contra revisitar o mesmo id (evita explosão exponencial ou loop
  infinito em composições em diamante que não são, de fato, circulares).
- Versionamento obrigatório: alterar um pacote `active` nunca reescreve o documento publicado.
  `ReviseCommercialPackUseCase` só aceita agir quando o pacote atual está `active`; cria um novo
  documento (novo `id`, mesmo `packCode`, `version` + 1, nasce `draft`) e só então marca o
  documento antigo como `superseded` (com `supersededByPackId` apontando para a nova versão) — a
  ordem (criar a nova versão antes de superseder a antiga) é deliberada: se a criação falhar, nada
  muda no pacote atual; se só a marcação de superseded falhar depois de criar a nova versão, o
  estado é recuperável (repetir), nunca deixa o `packCode` sem nenhuma versão vendável. O conteúdo
  substantivo do documento antigo (nome, componentes, política de preço/estoque) nunca é
  reescrito — um pedido antigo que referencia o `id` antigo sempre lê a composição exata que
  existia quando o pedido foi feito.
- `UpdateCommercialPackUseCase` só edita um pacote em `draft` diretamente (inclusive publicá-lo
  para `active`); rejeita editar um pacote já `active` (deve ser revisado) e nunca aceita `status`
  `superseded`/`expired` como alvo direto (o primeiro é exclusivo de `ReviseCommercialPackUseCase`,
  o segundo de um job de ciclo de vida futuro).
- `CreateCommercialPackUseCase` nunca aceita `status`/`version` como parâmetro — todo pacote nasce
  `draft`, `version` 1 (mesmo padrão de `CreatePriceListUseCase`/`CreateCollectionUseCase`).
  `packCode` é opcional na criação e, se omitido, assume o próprio `id`.

## Regras Firebase implementadas

- Coleção `organizations/{organizationId}/commercialPacks/{commercialPackId}`, mesmo padrão real
  já usado por toda a árvore de subcollections do projeto.
- `canReadCommercialPack`: qualquer membro ativo da própria organização lê (`get`/`list`); nunca
  cross-tenant; nunca não-autenticado.
- `canCreateCommercialPack`/`canUpdateCommercialPack`: exigem capability `commercialPack.manage`
  (hoje OWNER/ADMIN/SALES_MANAGER via `RolePermissionMatrix`/`roleHasCapability`), validam o
  payload completo (`validCommercialPackPayload`: tipos, enums, `validTo > validFrom` quando
  presente, `components` é lista não vazia). `canUpdateCommercialPack` também exige
  `unchanged('organizationId'|'packCode'|'createdAt'|'createdBy')` — `packCode` imutável é o
  espelho, em Rules, da mesma regra de negócio que o repositório Dart já aplica.
- `delete` sempre `false` — soft delete apenas via `deletedAt` (nenhum caso de uso de exclusão
  física existe); versionar um pacote ativo sempre cria um novo documento, nunca reescreve o
  existente.
- Validação profunda de `components`/`assortmentRules` (tipo de escopo, forma de
  quantidade/proporção, circularidade) é deliberadamente **não** feita em Rules — é
  responsabilidade exclusiva de `ValidateCommercialPackCompositionUseCase` (camada de domínio)
  antes mesmo da escrita ser tentada, mesmo precedente que nenhum outro campo de array embutido
  neste `firestore.rules` já segue (Rules aqui só verificam forma de topo, escopo de tenant e
  RBAC).

## Analytics implementado

Nenhum — task de modelagem de domínio/dados sem tela; não há evento de UI para instrumentar.

## Crashlytics implementado

Nenhum evento específico novo; os `Failure`s desta feature seguem o mesmo mapeamento
`AppException`→`Failure` já coberto pela infraestrutura existente, sem necessidade de tratamento
adicional.

## Impacto offline

`CommercialPacksTable` (Drift) replica os campos de sincronização padrão (`organizationId`,
`companyId` nullable, `createdAt/By`, `updatedAt/By`, `deletedAt`, `syncStatus`), com índices
compostos `(organizationId, companyId)` e `(organizationId, packCode)`. `components`/
`assortmentRules` são persistidos como colunas de texto JSON (`componentsJson`/
`assortmentRulesJson`), reaproveitando o mesmo `PackComponentDto`/`AssortmentRuleDto.toJson`/
`fromJson` já usado pelo lado Firestore — nenhuma tabela filha separada, já que nada nesta feature
precisa consultar um componente/regra individualmente no nível SQL, apenas carregar o pacote
inteiro para avaliar sua composição. `DriftCommercialPackLocalStoreRepository.replaceInitialLoad`
cobre a carga inicial completa; `upsert` cobre atualização incremental por registro, pronto para o
motor de sincronização do EPIC-14 consumir sem mudança de schema. `deletedAt` é tombstone, nunca
exclusão física; consultas "ativas" já filtram `deletedAt IS NULL`.

## Impacto multi-tenant

Toda leitura/escrita — local (Drift) e remota (Firestore Rules) — exige `organizationId` explícito,
nunca inferido do payload isolado; `SharedPreferencesCommercialPackRepository` particiona por
`organizationId` na própria chave de armazenamento (`commercial_packs_{organizationId}`), mesmo
padrão de `SharedPreferencesPriceListRepository`. `companyId` é opcional em todas as camadas (um
pacote pode ser válido para toda a organização); `listByOrganization`/`getAll`/
`getCommercialPacksForOrganization` narrowing por `companyId`, quando informado, sempre inclui
pacotes "org-wide" (`companyId == null`) além dos da própria empresa, nunca de uma empresa
diferente. Testes de isolamento cross-tenant cobertos tanto no Drift (`getAll never returns a pack
belonging to a different organization`) quanto no repositório de produção
(`listByOrganization never returns a pack of a different organization`) quanto nas Firestore Rules
(`membro da Org A não le o commercial pack da Org B`).

## Testes criados

73 testes novos (72 em `test/features/commercial_packs/` + 1 em
`test/core/permissions/role_permission_matrix_test.dart`), cobrindo:

- **Entidade** (`commercial_pack_test.dart`): criação válida, `isWithinValidityWindow` (limites
  inclusivos, `validTo` nulo nunca expira), `isApplicableAt` (status não-active, fora da janela
  mesmo com status active, soft-deleted, caso positivo), `matchesCustomerContext` para
  segmento/canal isolados e combinados.
- **`ValidateCommercialPackCompositionUseCase`** (25 testes): pacote sem componentes,
  `scopeReferenceId` vazio, `isComponentReferenceValid` rejeitando/aceitando referência (variante
  inativa/produto excluído/coleção fora da organização, simulado via stub), quantidade zero/
  negativa em composição fixa, `minQuantity`/`maxQuantity` ausente/invertido em composição
  flexível, proporção `<= 0`/`> 1` em composição por grade, regra de sortimento
  `minPercentagePerColor`/`minQuantityPerSize` sem os campos exigidos, cada política de preço
  (`fixedPrice`/`packDiscount`/`bonusItem`) sem seu parâmetro obrigatório (incluindo
  `bonusComponentId` referenciando um componente inexistente), política `dedicatedStock` sem
  `dedicatedWarehouseId`, vigência expirada/futura, circularidade direta (A contém A), indireta (A
  contém B, B contém A), composição em diamante acíclica (válida) e omissão do resolver de
  circularidade (pula a checagem, contrato apenas).
- **`CreateCommercialPackUseCase`**: criação válida (draft, versão 1, `packCode` default = id),
  id vazio, `validTo` antes de `validFrom`, composição inválida (sem componentes).
- **`UpdateCommercialPackUseCase`**: edição direta de um pacote `draft` (incluindo publicá-lo para
  `active`), pacote inexistente, pacote já `active` rejeitado (deve ser revisado), status
  `superseded` rejeitado como alvo direto.
- **`ReviseCommercialPackUseCase`** (o teste central de versionamento pedido pela task): revisar um
  pacote `active` cria um segundo documento com o mesmo `packCode`/`version + 1`/`status: draft`,
  enquanto o documento original mantém seu próprio conteúdo (`name`/`components`) intocado e só
  ganha `status: superseded`/`supersededByPackId` — nunca reescreve o histórico; pacote ainda
  `draft` rejeitado (deve ser editado direto); pacote inexistente; reuso do id atual como novo id
  rejeitado; nova composição que introduziria uma referência circular rejeitada.
- **`CommercialPackDto`** (mapper Firestore): payload válido (com componente aninhado),
  `organizationId`/`packCode` ausentes lançam `ValidationException`, componente malformado lança
  `ValidationException`, round-trip `toJson`/`fromJson` incluindo componentes/regras de
  sortimento aninhados.
- **`CommercialPackMapper`**: round-trip completo entidade↔DTO para composição fixa, flexível,
  por grade (cor/tamanho) e para um componente aninhado `commercialPack` (kit dentro de kit);
  round-trip de todo código enum (`packType`/`status`/`pricingPolicyType`/`stockPolicyType`/
  `syncStatus`/`scopeType`/`compositionType`/`assortmentRuleType`); código desconhecido lança
  `ValidationException`.
- **`SharedPreferencesCommercialPackRepository`**: criar/buscar por id, id duplicado rejeitado
  (`ConflictFailure`), `listByOrganization` nunca retorna pacote de outra organização (isolamento
  multi-tenant), narrowing por `companyId` inclui pacotes org-wide mas exclui outra empresa,
  `update` aceito quando `packCode` não muda, `update` rejeitado quando `packCode` muda
  (`ValidationFailure`), `update` de pacote inexistente (`NotFoundFailure`), e um teste de
  versionamento ponta a ponta ao nível do repositório (revisar cria um segundo documento com o
  mesmo `packCode`, o original vira `superseded` sem perder seu próprio conteúdo).
- **`DriftCommercialPackLocalStoreRepository`** (Drift em memória): carga inicial completa,
  substituição idempotente sem sobras, isolamento por organização mesmo sem `companyId`
  informado, narrowing por `companyId` inclui pacotes org-wide, `upsert` insere/atualiza e
  round-tripa `components`/`assortmentRules` pelas colunas JSON locais, soft-deleted não aparece
  em `getAll`/`count`.
- **`RolePermissionMatrix`**: só OWNER/ADMIN/SALES_MANAGER têm `commercialPackManage`.
- **Firestore Security Rules** (`firestore-tests/firestore.rules.test.js`, 9 casos, não executados
  nesta sessão — ver "Pendências"): leitura por membro ativo, negação cross-tenant, negação para
  visitante não autenticado, criação por OWNER/ADMIN/SALES_MANAGER, negação para SALES_REP/FINANCE,
  pacote sem componentes rejeitado, `validTo` antes de `validFrom` rejeitado, update preservando
  `packCode` aceito, update trocando `packCode` rejeitado, delete físico sempre rejeitado.

## Comandos executados

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
dart format --set-exit-if-changed .
flutter test
firebase deploy --only firestore:rules --dry-run   # validação estática das Rules (compila OK)
node --check firestore-tests/firestore.rules.test.js   # sintaxe JS válida
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"   # não executado: sem Java
```

## Resultado do formatter

`dart format --set-exit-if-changed .` (repositório inteiro) reformatou inicialmente 6 arquivos fora
do escopo desta task (`lib/core/localization/presentation/pages/locale_settings_page.dart`,
`lib/features/cart_share/presentation/widgets/cart_share_sheet.dart`,
`test/features/after_sales/data/mappers/post_sale_event_mapper_test.dart`,
`test/features/after_sales/domain/usecases/register_post_sale_event_use_case_test.dart`,
`test/features/product_import/domain/services/product_import_mapping_validator_test.dart`,
`test/features/product_import/domain/usecases/start_product_import_job_use_case_test.dart`) — mesmo
drift de formatação pré-existente entre o toolchain atual e o que está commitado em `HEAD`, já
documentado em TASK-083. Revertidos via `git checkout --` para não introduzir mudança fora de
escopo. Após reverter, os arquivos desta task passam limpos por `dart format`.

## Resultado do analyzer

`flutter analyze` (repositório inteiro): 18 issues — todos pré-existentes e sem qualquer relação com
esta task (avisos `info` de `use_null_aware_elements`/`deprecated_member_use` em
`customer_import`/`product_import`/`replenishment`/`report_explanation`/`reports`/`dashboards`,
nenhum em `lib/features/commercial_packs/` nem nos demais arquivos alterados). Confirmado via
`flutter analyze 2>&1 | grep -i commercial_pack` (nenhum resultado).

## Resultado dos testes

`flutter test` (suíte completa): **3417 aprovados, 1 falha** —
`test/app/bootstrap_test.dart: bootstrap initializes Firebase exactly once and renders VestiProApp`,
falha pré-existente e sem relação com esta task: `GetIt: Object/factory with type PushDeviceMapper is
not registered inside GetIt` — confirmado com `git show HEAD:lib/app/injection.config.dart | grep
PushDeviceMapper` (já não registrado antes de qualquer mudança desta task) e com `git diff
lib/app/injection.config.dart` (o diff é 100% aditivo — só acrescenta os registros da feature
`commercial_packs`, nunca remove nada relacionado a `PushDeviceMapper`).

Inclui os 73 testes novos desta task e os 7 arquivos de teste pré-existentes ajustados
(`app_database_test.dart` + 5 outros `app_database_task_*`/`warehouses` para `schemaVersion` 24,
`role_permission_matrix_test.dart`).

Testes de Firestore Security Rules (`firestore-tests/firestore.rules.test.js`) **não foram
executados** nesta sessão: o ambiente não tem Java instalado (`java: command not found`),
pré-requisito do Firebase Emulator Suite — mesma limitação de ambiente já documentada em
TASK-079/TASK-081/TASK-083. As Rules foram validadas estaticamente via
`firebase deploy --only firestore:rules --dry-run` (projeto `vestipro`, autenticado): `rules file
firestore.rules compiled successfully` / `Dry run complete!` — equivalente ao MCP
`firebase_validate_security_rules` usado em TASK-083 (não disponível nesta sessão). Os 9 casos de
teste JS foram escritos seguindo exatamente o mesmo padrão dos `describe` blocks já existentes no
arquivo (seed de fixtures, `assertSucceeds`/`assertFails`) e têm sintaxe validada via
`node --check`, mas ficam como não verificados contra o emulador real nesta rodada.

## Decisões técnicas

- `CommercialPack.packCode` (estável entre versões) segue exatamente o padrão pedido pela task:
  agrupa todas as versões do "mesmo" pacote; `id`/`version` mudam a cada revisão
  (`ReviseCommercialPackUseCase`), `packCode` nunca muda — imutabilidade reforçada tanto no
  repositório Dart (`SharedPreferencesCommercialPackRepository.update` rejeita mudança de
  `packCode`, mesmo precedente da imutabilidade de `currency` em `PriceList`) quanto na Firestore
  Rule (`canUpdateCommercialPack` exige `unchanged('packCode')`).
- A nova versão criada por `ReviseCommercialPackUseCase` nasce **`draft`**, não `active` — decisão
  deliberada para manter uma responsabilidade única por caso de uso: revisar só versiona/preserva
  histórico, nunca decide se a nova versão já está pronta para vender. Publicá-la (`draft` ->
  `active`) é um passo explícito e separado via `UpdateCommercialPackUseCase`, mesmo RBAC
  (`commercialPackManage`). Isso deixa uma pequena janela em que, tecnicamente, nenhuma versão
  "vendável" existe para aquele `packCode` até a nova ser publicada — aceito como trade-off
  deliberado (documentado em "Riscos conhecidos") em favor de nunca confundir "versionar" com
  "publicar automaticamente", e de sempre permitir revisar sem já se comprometer a vender a nova
  composição imediatamente.
- Circularidade de composição (`PackComponentScopeType.commercialPack`, o único scope que permite
  aninhar um `CommercialPack` dentro de outro) é validada de fato (não apenas como contrato) nos
  três casos de uso desta task (`Create`/`Update`/`Revise`), que já têm acesso ao
  `CommercialPackRepository.listByOrganization` — constroem um resolver `packId -> componentes`
  local e o passam para `ValidateCommercialPackCompositionUseCase`. Já a validade da *referência*
  de cada componente (variante ativa, produto não excluído, coleção da mesma organização) fica
  como contrato apenas (`PackComponentReferenceResolver`), porque exigiria acoplar esta feature a
  repositórios de `products`/`catalog` que a task explicitamente deixa para TASK-208.
  Estruturalmente, isso significa que hoje é possível criar um `CommercialPack` referenciando uma
  variante inativa sem que nenhum destes três casos de uso rejeite — aceito, documentado em
  "Riscos conhecidos", e coberto por teste demonstrando que o contrato (`isComponentReferenceValid`)
  já existe e funciona quando um resolver de verdade for plugado.
- `components`/`assortmentRules` são arrays embutidos no próprio documento Firestore/linha Drift
  (nunca uma subcoleção/tabela filha separada) — mesmo precedente `OrderDto.items`/
  `OrderItemsTable` (embutido no Firestore) e `CampaignsTable.productIdsJson` (JSON local): esta
  feature nunca precisa consultar um componente/regra isoladamente, só carregar o pacote inteiro
  para avaliar sua composição, então uma tabela/coleção filha separada só adicionaria
  complexidade sem benefício de consulta.
- `CommercialPackStatus` ganhou um quinto valor, `superseded`, deliberadamente distinto de
  `archived`: `superseded` significa "substituído por uma versão mais nova" (sempre com
  `supersededByPackId` preenchido), `archived` significa "retirado manualmente sem nunca ter sido
  revisado" — a distinção importa para relatórios/auditoria (TASK-208 em diante) diferenciarem os
  dois motivos de um pacote não estar mais vendável.
- Repositório "de produção" continua `SharedPreferencesCommercialPackRepository` (não
  `FirestoreCommercialPackRepository`) — mesmo precedente de `PriceList`/`Customer`/`Product`:
  mantém offline-first hoje, sem exigir o sync remoto real do EPIC-14. `CommercialPackDto`/
  `CommercialPackMapper` já são 100% Firestore-shaped (`Timestamp`), então plugar essa
  implementação futuramente é um drop-in, sem qualquer mudança de schema.
- Validação de Firestore Rules para `components`/`assortmentRules` fica deliberadamente rasa (só
  tipo `list` + não-vazio para `components`) — a validação profunda (forma de cada scope/
  quantidade/proporção, circularidade) já é feita client-side por
  `ValidateCommercialPackCompositionUseCase` antes mesmo da escrita ser tentada, e nenhum outro
  campo de array embutido neste `firestore.rules` (ex.: `CampaignsTable.productIdsJson`, que sequer
  tem uma Rule de escrita própria) tenta validar profundidade de item — replicar esse mesmo nível
  de rigor evita expandir o escopo de Rules para além do padrão já estabelecido no arquivo.

## Riscos conhecidos

- Testes de Firestore Security Rules não executados contra o emulador real nesta sessão (ambiente
  sem Java) — mesmo risco já assumido/documentado por TASK-079/TASK-081/TASK-083; mitigado
  parcialmente por `firebase deploy --only firestore:rules --dry-run` (compilação real confirmada
  contra o projeto `vestipro`) e pelos mesmos padrões (helpers/estrutura de match) já usados e
  comprovados em produção por `priceLists`/`warehouses`.
- A nova versão criada por `ReviseCommercialPackUseCase` nasce `draft`: entre o momento em que um
  pacote é revisado e o momento em que alguém publica a nova versão (`UpdateCommercialPackUseCase`),
  nenhuma versão daquele `packCode` está `active` — decisão deliberada (ver "Decisões técnicas"),
  mas requer que o fluxo de UI (TASK-208 em diante) sempre encadeie "revisar" com "publicar" na
  mesma interação para não deixar um pacote temporariamente invisível para venda.
  `RolePermissionMatrix`/`firestore.rules` precisam ser mantidos manualmente em sincronia (mesmo
  risco documentado desde TASK-030) — a mudança desta task (`commercialPackManage` para
  SALES_MANAGER) foi replicada nos dois lugares e coberta por teste Dart; o lado Rules só pode ser
  confirmado quando o emulador rodar de fato.
- A validade de referência de cada `PackComponent` (variante ativa, produto não excluído, coleção
  da mesma organização) é só um contrato (`PackComponentReferenceResolver`) nesta task — nenhum dos
  três casos de uso de ciclo de vida chama um resolver real de catálogo ainda, então hoje é
  possível persistir um pacote com uma referência hoje inválida sem ser bloqueado; TASK-208 precisa
  implementar e plugar o resolver de verdade antes de expor qualquer fluxo de venda por pacote.
- `PackComponentScopeType.category`/`.collection`/`.color`/`.size` resolvem para *conjuntos* de
  variantes (não uma variante única) — esta task modela o contrato do componente, mas a
  materialização real "quais variantes vendáveis esse componente representa agora" é integralmente
  escopo de TASK-208, incluindo qualquer regra de desempate/priorização quando o conjunto for
  ambíguo.

## Pendências

- Rodar `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em um
  ambiente com Java instalado, para confirmar de fato os 9 casos positivos/negativos de
  `organizations/{organizationId}/commercialPacks/{commercialPackId}` contra o Emulator Suite real.
- TASK-208 (venda por kit/pacote/sortimento no pedido) precisa: implementar o resolver real de
  `PackComponentScopeType` -> variantes vendáveis (incluindo o `PackComponentReferenceResolver` de
  liveness/tenant), plugar esse resolver nos três casos de uso de ciclo de vida desta task, e
  integrar `pricingPolicyType`/`stockPolicyType` com o motor de precificação (TASK-088) e o saldo
  por variante (TASK-090) reais.

## Evidências

- `flutter analyze` → 18 issues, todas pré-existentes/fora de escopo (0 em `commercial_packs`)
- `dart format --set-exit-if-changed .` (escopo da task) → limpo após reverter os 6 arquivos fora
  de escopo
- `flutter test` → `+3417 -1` (1 falha pré-existente/não relacionada, ver "Resultado dos testes")
- `firebase deploy --only firestore:rules --dry-run` → `rules file firestore.rules compiled
  successfully` / `Dry run complete!`
- `node --check firestore-tests/firestore.rules.test.js` → sintaxe válida

## Commit

`feat(commercial_packs): model commercial pack, component and assortment rule entities (TASK-207)`

## Push

Não realizado — push não autorizado nesta rodada.

## Hash do commit

Ver `git log -1` após o commit (registrado na resposta final desta task).

## Branch

main
