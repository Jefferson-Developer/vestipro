# TASK-083 — Concluída (2026-08-26)

## Resumo

Modelada a entidade `PriceList` (tabela de preço), fundação do EPIC-11 (Tabelas de Preço e
Condições Comerciais): entidade de domínio, DTO/mapper Firestore, repositório remoto
(`SharedPreferencesPriceListRepository`, mesmo precedente de `CustomerRepository`/
`ProductRepository` até o sync remoto real existir), cache offline via Drift
(`PriceListsTable`/`DriftPriceListLocalStoreRepository`), caso de uso
`CreatePriceListUseCase` (validação de criação) e `ResolveApplicablePriceListsUseCase`
(resolução de aplicabilidade por vigência/escopo/prioridade), além de Firestore Security Rules
com leitura escopada por organização e escrita restrita a `OWNER`/`ADMIN`/`FINANCE`.

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task; escopo é modelagem de
  domínio/dados/Firebase, sem UI).

## Arquivos criados

- `lib/features/pricing/domain/entities/price_list.dart` (+ `.freezed.dart` gerado)
- `lib/features/pricing/domain/value_objects/price_list_status.dart`
- `lib/features/pricing/domain/value_objects/price_list_scope_type.dart`
- `lib/features/pricing/domain/value_objects/price_list_sync_status.dart`
- `lib/features/pricing/domain/repositories/price_list_repository.dart`
- `lib/features/pricing/domain/repositories/price_list_local_store_repository.dart`
- `lib/features/pricing/domain/usecases/create_price_list_use_case.dart`
- `lib/features/pricing/domain/usecases/resolve_applicable_price_lists_use_case.dart`
- `lib/features/pricing/data/dtos/price_list_dto.dart`
- `lib/features/pricing/data/mappers/price_list_mapper.dart`
- `lib/features/pricing/data/mappers/price_list_local_mapper.dart`
- `lib/features/pricing/data/repositories/shared_preferences_price_list_repository.dart`
- `lib/features/pricing/data/repositories/drift_price_list_local_store_repository.dart`
- `lib/features/pricing/pricing.dart` (barrel)
- `lib/core/database/tables/price_lists_table.dart`
- `test/features/pricing/domain/entities/price_list_test.dart`
- `test/features/pricing/domain/usecases/create_price_list_use_case_test.dart`
- `test/features/pricing/domain/usecases/resolve_applicable_price_lists_use_case_test.dart`
- `test/features/pricing/data/dtos/price_list_dto_test.dart`
- `test/features/pricing/data/mappers/price_list_mapper_test.dart`
- `test/features/pricing/data/repositories/shared_preferences_price_list_repository_test.dart`
- `test/features/pricing/data/repositories/drift_price_list_local_store_repository_test.dart`

## Arquivos alterados

- `lib/core/database/app_database.dart`: registra `PriceListsTable`, bump `schemaVersion` 4→5,
  migração `onUpgrade` (`from < 5` cria a tabela), métodos `replacePriceLists`/`upsertPriceList`/
  `getPriceListsForCompany`/`countPriceListsForCompany`.
- `lib/core/database/app_database.g.dart`: regenerado via `build_runner` (Drift).
- `lib/core/database/database.dart`: exporta `tables/price_lists_table.dart`.
- `lib/core/permissions/role_permission_matrix.dart`: adiciona `Capability.priceListManage` às
  capabilities de `FINANCE` (OWNER/ADMIN já herdam via conjunto completo/quase completo).
- `firestore.rules`: `roleHasCapability` inclui `'priceList.manage'` para `FINANCE`;
  `validPriceListPayload`/`canReadPriceList`/`canCreatePriceList`/`canUpdatePriceList` +
  `match /priceLists/{priceListId}` (leitura por qualquer membro ativo da organização, escrita só
  com `priceList.manage`, `unchanged('currency')` obrigatório no update, `delete` sempre `false`).
- `firestore-tests/firestore.rules.test.js`: role `FINANCE`/membro `finance-a` na seed,
  `priceListDoc()` e `describe('organizations/{organizationId}/priceLists/{priceListId} ...')` com
  10 casos positivos/negativos.
- `lib/app/injection.config.dart`: regenerado via `build_runner` (injectable) — registra os novos
  mappers/repositórios/casos de uso.
- `test/core/database/app_database_test.dart`: `schemaVersion` 4→5, `'price_lists'` na lista de
  tabelas esperadas.
- `test/core/permissions/role_permission_matrix_test.dart`: novo teste garantindo que só
  OWNER/ADMIN/FINANCE têm `priceListManage`.

## Arquitetura utilizada

Clean Architecture feature-first, mesmo padrão de `customers`/`products`: entidade `freezed`
imutável em `domain/entities`, contrato de repositório em `domain/repositories`
(`PriceListRepository` remoto + `PriceListLocalStoreRepository` offline), casos de uso em
`domain/usecases` fazendo toda validação de negócio (nunca em widget/UI — task não tem escopo de
UI). Camada `data/` traduz para/de `PriceListDto` (formato Firestore, `Timestamp`) via
`PriceListMapper`, e para/de `PriceListsTable` (Drift) via `PriceListLocalMapper`, delegando os
mesmos códigos enum<->string do mapper remoto (evita duplicar a tabela de códigos). O repositório
"de produção" hoje é `SharedPreferencesPriceListRepository` — mesmo precedente já usado por
`SharedPreferencesCustomerRepository`/`SharedPreferencesProductRepository`: mantém o app
offline-first enquanto o sync remoto real (EPIC-14) não existe. Não foi criado um
`FirestorePriceListRepository` nesta task por não ser exigido por nenhum critério de aceite (as
Security Rules são testadas diretamente via JS/emulador, sem depender de código Dart) — fica como
extensão natural de uma task futura de EPIC-11/EPIC-14, mesmo padrão já adotado por
`FirestoreProductVariantRepository` (existe, mas não registrado em DI).

## Regras de negócio implementadas

- Múltiplas Price Lists podem coexistir ativas para a mesma organização/empresa; a resolução de
  "qual vale para este cliente/pedido agora" é 100% do `ResolveApplicablePriceListsUseCase`
  (domínio), nunca de UI — considera vigência (`validFrom`/`validTo`), status
  (`PriceListStatus.active`), escopo/`scopeValue` (`company`/`channel`/`segment`, casado contra
  `customerChannel`/`customerSegment`) e desempate por `priority` (maior primeiro), depois
  especificidade do escopo (segmento > canal > empresa), depois `validFrom` mais recente, depois
  `id` — determinístico.
- Uma tabela fora do período de vigência nunca é retornada como aplicável, mesmo que `status`
  ainda diga `active` (`PriceList.isApplicableAt`/`isWithinValidityWindow`) — cobre o caso de um
  operador esquecer de expirar a tabela manualmente.
- Moeda é imutável após a criação: `CreatePriceListUseCase` nunca aceita mudar moeda de uma tabela
  existente (não há caso de uso de "editar moeda"); `SharedPreferencesPriceListRepository.update`
  rejeita qualquer `update` que troque `currency`; a Firestore Rule `canUpdatePriceList` exige
  `unchanged('currency')`. Trocar moeda sempre significa criar uma nova Price List.
- `CreatePriceListUseCase` nunca aceita `status` como parâmetro — toda tabela nasce
  `PriceListStatus.draft` (mesmo padrão de `CreateCollectionUseCase`/`CreateProductUseCase`).
- Escopo `channel`/`segment` exige `scopeValue` não vazio; escopo `company` exige `scopeValue`
  vazio — validado tanto no use case quanto na Firestore Rule.

## Regras Firebase implementadas

- Coleção `organizations/{organizationId}/priceLists/{priceListId}` (confirma o desenho já
  documentado em `docs/architecture/firestore-schema.md`, não `companies/{companyId}/priceLists`
  como o texto solto da task sugeria — seguido o padrão real já em uso por toda a árvore de
  `organizations/{organizationId}/...`).
- `canReadPriceList`: qualquer membro ativo da própria organização lê (`get`/`list`); nunca
  cross-tenant; nunca não-autenticado.
- `canCreatePriceList`/`canUpdatePriceList`: exigem capability `priceList.manage` (hoje
  OWNER/ADMIN/FINANCE via `RolePermissionMatrix`/`roleHasCapability`), validam o payload
  completo (`validPriceListPayload`: tipos, `validTo > validFrom` quando presente, `scope`/
  `scopeValue` consistentes, `currency` como código ISO de 3 letras maiúsculas, `syncStatus`
  dentre os 5 valores válidos). `canUpdatePriceList` também exige
  `unchanged('organizationId'|'companyId'|'currency'|'createdAt'|'createdBy')`.
- `delete` sempre `false` — soft delete apenas via `deletedAt` (nenhum caso de uso de exclusão
  física existe).

## Analytics implementado

Nenhum — task de modelagem de domínio/dados sem tela; não há evento de UI para instrumentar.

## Crashlytics implementado

Nenhum evento específico novo; os `Failure`s desta feature seguem o mesmo mapeamento
`AppException`→`Failure` já coberto pela infraestrutura existente (`firestore_exception_mapper.dart`),
sem necessidade de tratamento adicional.

## Impacto offline

`PriceListsTable` (Drift) replica os campos de sincronização padrão (`organizationId`,
`companyId`, `createdAt/By`, `updatedAt/By`, `deletedAt`, `version`, `syncStatus`), com índice
composto `(organizationId, companyId)`. `PriceListLocalStoreRepository.replaceInitialLoad` cobre a
carga inicial completa (substituição idempotente, mesmo padrão de `CustomerLocalStoreRepository`);
`upsert` cobre atualização incremental por registro (mesmo padrão de `FavoritesTable.upsertFavorite`),
pronto para o motor de sincronização do EPIC-14 (TASK-109) consumir sem mudança de schema.
`deletedAt` é tombstone, nunca exclusão física; consultas "ativas" (`getPriceListsForCompany`/
`count`) já filtram `deletedAt IS NULL`.

## Impacto multi-tenant

Toda leitura/escrita — local (Drift) e remota (Firestore Rules) — exige `organizationId`
explícito, nunca inferido do payload isolado; `SharedPreferencesPriceListRepository` particiona por
`organizationId` na própria chave de armazenamento (`price_lists_{organizationId}`), mesmo padrão
de `SharedPreferencesCustomerRepository`. Testes de isolamento cross-tenant cobertos tanto no Drift
(`replaceInitialLoad never touches another organization/company scope`) quanto nas Firestore Rules
(`membro da Org A não lê a Price List da Org B`).

## Testes criados

56 testes novos (todos em `test/features/pricing/` + 1 em `test/core/permissions/`), cobrindo:

- **Entidade** (`price_list_test.dart`): criação válida, `isWithinValidityWindow` (limites
  inclusivos, `validTo` nulo nunca expira), `isApplicableAt` (status draft, fora da janela mesmo
  com status active, soft-deleted, caso positivo), `matchesCustomerContext` para os 3 escopos.
- **`CreatePriceListUseCase`**: criação válida (draft, versão 1, `pending`), `validTo` antes/igual
  a `validFrom`, moeda ausente/vazia, moeda fora do padrão ISO, `scopeValue` ausente para
  channel/segment, `scopeValue` presente indevidamente para company, `priority` negativa.
- **`ResolveApplicablePriceListsUseCase`**: nenhuma vigente, uma vigente, múltiplas com
  prioridades diferentes (ordenação), tabela expirada por data (mesmo com status active) excluída,
  tabela agendada (validFrom futuro) excluída, filtragem por canal/segmento do cliente,
  organizationId/companyId ausentes.
- **`PriceListDto`** (mapper Firestore): payload válido, `currency`/`scope`/`organizationId`
  ausentes lançam `ValidationException`, round-trip `toJson`/`fromJson`.
- **`PriceListMapper`**: round-trip completo entidade↔DTO, round-trip de cada enum
  (`status`/`scope`/`syncStatus`), código desconhecido lança `ValidationException`.
- **`SharedPreferencesPriceListRepository`**: criar/buscar por id, id duplicado rejeitado
  (`ConflictFailure`), `listByCompany` filtra por empresa, `update` aceito quando moeda não muda,
  `update` rejeitado quando moeda muda (`ValidationFailure`), `update` de tabela inexistente
  (`NotFoundFailure`).
- **`DriftPriceListLocalStoreRepository`** (Drift em memória): carga inicial completa, substituição
  idempotente sem sobras, isolamento por organização/empresa, `upsert` insere e atualiza,
  soft-deleted não aparece em `getAll`/`count`.
- **`RolePermissionMatrix`**: só OWNER/ADMIN/FINANCE têm `priceListManage`.
- **Firestore Security Rules** (`firestore-tests/firestore.rules.test.js`, 10 casos, não
  executados nesta sessão — ver "Pendências"): leitura por membro ativo, negação cross-tenant,
  negação para visitante não autenticado, criação por OWNER/ADMIN/FINANCE, negação para
  SALES_REP/SALES_MANAGER, `validTo` antes de `validFrom` rejeitado, escopo channel/segment sem
  `scopeValue` rejeitado, update preservando moeda aceito, update trocando moeda rejeitado, delete
  físico sempre rejeitado.

## Comandos executados

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
dart format --set-exit-if-changed .
flutter test
mcp: firebase_validate_security_rules (type=firestore, source_file=firestore.rules)
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"   # falhou: Java ausente
```

## Resultado do formatter

`dart format --set-exit-if-changed .` roda limpo para todos os arquivos desta task (0 alterações).
Uma execução ampla do formatter sobre o repositório inteiro reformatou adicionalmente 3 arquivos
fora do escopo (`lib/core/navigation/active_organization_guard.dart`,
`lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart`,
`lib/features/settings/presentation/widgets/about_app_content.dart`) — drift de formatação
pré-existente entre o toolchain atual e o que está commitado em `HEAD`, sem relação com esta task.
Foram revertidos para `HEAD` (`git checkout --`) para não introduzir mudança fora de escopo; o
working tree final não contém esses 3 arquivos como alterados.

## Resultado do analyzer

`flutter analyze` (repositório inteiro): **No issues found!**

## Resultado dos testes

`flutter test` (suíte completa, 1917 testes): **All tests passed!** — inclui os 56 testes novos
desta task e os 2 arquivos de teste pré-existentes ajustados
(`app_database_test.dart`/`role_permission_matrix_test.dart`).

Testes de Firestore Security Rules (`firestore-tests/firestore.rules.test.js`) **não foram
executados** nesta sessão: o ambiente não tem Java instalado (`Could not spawn "java -version"`),
pré-requisito do Firebase Emulator Suite — mesma limitação de ambiente já documentada em
TASK-079/TASK-081. As Rules foram validadas estaticamente via `firebase_validate_security_rules`
(MCP): `OK: No errors detected.` Os 10 casos de teste foram escritos seguindo exatamente o mesmo
padrão dos `describe` blocks já existentes no arquivo (seed de fixtures, `assertSucceeds`/
`assertFails`), mas ficam como não verificados contra o emulador real nesta rodada.

## Decisões técnicas

- Coleção Firestore em `organizations/{organizationId}/priceLists/{priceListId}` (não
  `companies/{companyId}/priceLists`, que era só uma sugestão solta no texto da task) — segue o
  desenho já documentado em `docs/architecture/firestore-schema.md` e o padrão real usado por toda
  a árvore de subcollections do projeto (`FirestoreCollectionDataSource` é sempre
  `organizations/{organizationId}/{collectionName}`), com `companyId` como campo indexável para
  filtrar por empresa dentro da organização.
- `scope`/`scopeValue`: modelado como um par (`PriceListScopeType` enum + `String? scopeValue`) em
  vez de um discriminador aberto, para casar 1:1 com os campos já existentes em `Customer`
  (`Customer.originChannel`/`Customer.segment`, texto livre) sem introduzir uma nova entidade de
  "canal"/"segmento de precificação" fora de escopo desta task.
  `PriceList.matchesCustomerContext` é o único lugar que decide o casamento.
  `ResolveApplicablePriceListsUseCase` usa esse mesmo método, nunca reimplementa a comparação.
  `Order`/`Customer` não são passados para o use case — só os dois campos de contexto necessários
  (`customerChannel`/`customerSegment`) — porque o motor de precificação (TASK-088) ainda não
  existe; a assinatura fica deliberadamente estreita para não vazar dependência para outros
  agregados que essa task ainda não modela.
- Repositório "de produção" continua `SharedPreferencesPriceListRepository` (não
  `FirestorePriceListRepository`) — mesmo precedente de `Customer`/`Product`: mantém offline-first
  hoje, sem exigir o sync remoto real do EPIC-14. Não foi criado nenhum
  `FirestorePriceListRepository` Dart nesta task por não ser exigido por nenhum critério de
  aceite: as Security Rules são validadas diretamente via JS/emulador Firestore, sem depender de
  código Dart algum. Fica registrado como extensão natural de task futura (TASK-084 em diante, ou
  parte do trabalho de sync do EPIC-14), seguindo o mesmo padrão que
  `FirestoreProductVariantRepository` (existe hoje, mas não registrado na DI) já demonstra.
  `PriceListDto`/`PriceListMapper` já são 100% Firestore-shaped (`Timestamp`), então plugar essa
  implementação futuramente é um drop-in, sem qualquer mudança de schema.
- `CreatePriceListUseCase` normaliza `currency` para maiúsculas e valida contra `^[A-Z]{3}$`
  (ISO 4217 simplificado) — suficiente para o escopo desta task; validação de moeda "existe de
  fato" (tabela de moedas suportadas) fica para TASK-175 (multi-moeda), fora de escopo aqui.
- Critério de desempate de `ResolveApplicablePriceListsUseCase` (priority desc → especificidade de
  escopo desc → validFrom desc → id asc) é determinístico e coberto por teste; escolha de
  especificidade (segmento > canal > empresa) segue a intuição comercial usual (regra mais
  específica vence quando a prioridade numérica empata), documentada no próprio use case.

## Riscos conhecidos

- Testes de Firestore Security Rules não executados contra o emulador real nesta sessão (ambiente
  sem Java) — mesmo risco já assumido/documentado por TASK-079/TASK-081; mitigado parcialmente por
  validação estática (`firebase_validate_security_rules`) e pelos mesmos padrões (helpers/estrutura
  de match) já usados e comprovados em produção por `productVariants`/`catalogShares`/`customers`.
- `RolePermissionMatrix`/`firestore.rules` precisam ser mantidos manualmente em sincronia (mesmo
  risco documentado desde TASK-030) — a mudança desta task (`priceListManage` para FINANCE) foi
  replicada nos dois lugares e coberta por teste Dart; o lado Rules só pode ser confirmado quando o
  emulador rodar de fato.
- Nenhum caso de uso de "editar Price List" além da validação de imutabilidade de moeda foi criado
  nesta task (fora do escopo de "modelar"); `PriceListRepository.update` existe como ponto de
  extensão para a task que implementar a edição completa (TASK-084 em diante).

## Pendências

- Rodar `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em um
  ambiente com Java instalado, para confirmar de fato os 10 casos positivos/negativos de
  `organizations/{organizationId}/priceLists/{priceListId}` contra o Emulator Suite real.
- TASK-084 a TASK-088 (preço por variante, condições de pagamento, políticas de desconto,
  campanhas, motor de precificação server-side) continuam pendentes, agora com a fundação de
  `PriceList` pronta para se apoiar.

## Evidências

- `flutter analyze` → `No issues found!`
- `dart format --set-exit-if-changed .` (escopo da task) → `Formatted 28 files (0 changed)`
- `flutter test` → `+1917: All tests passed!`
- `firebase_validate_security_rules` (MCP, firestore) → `OK: No errors detected.`

## Commit

`feat(pricing): model PriceList entity with offline cache and Firestore rules (TASK-083)`

## Push

Não realizado — push não autorizado nesta rodada.

## Hash do commit

Ver `git log -1` após o commit (registrado na resposta final desta task).

## Branch

main
