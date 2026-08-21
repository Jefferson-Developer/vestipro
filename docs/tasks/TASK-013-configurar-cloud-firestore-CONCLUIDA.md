# TASK-013 — Concluída (2026-08-21)

## Resumo

Infraestrutura genérica de acesso ao Cloud Firestore criada em `lib/core/database/`:
`FirestoreCollectionDataSource<T>` (datasource base tenant-scoped, com paginação por cursor, soft
delete e conversores tipados), `FirestoreConverter<T>` (padroniza `withConverter` por entidade),
`mapFirestoreExceptionToAppException` (reaproveita a hierarquia `AppException`/`Failure` já
existente, sem novos tipos) e `configureFirestore` (persistência offline nativa + conexão ao
Firestore Emulator, no mesmo padrão de `FirebaseAuthDataSource` da TASK-012). `FirebaseFirestore` foi
registrado como `@lazySingleton` em `lib/app/injection_module.dart`, pronto para as próximas ~30
tasks de feature que vão construir seus datasources sobre essa base — nenhuma feature usa Firestore
ainda (só entra a partir do EPIC-06/TASK-048).

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/database/firestore_collection_data_source.dart`
- `lib/core/database/firestore_converter.dart`
- `lib/core/database/firestore_exception_mapper.dart`
- `lib/core/database/firestore_page_slice.dart`
- `lib/core/database/firestore_query_page.dart`
- `lib/core/database/configure_firestore.dart`
- `lib/core/database/database.dart` (barrel público do módulo)
- `test/core/database/firestore_exception_mapper_test.dart`
- `test/core/database/firestore_converter_test.dart`
- `test/core/database/firestore_page_slice_test.dart`
- `test/core/database/firestore_collection_data_source_no_raw_map_test.dart`
- `integration_test/core/database/firestore_collection_data_source_integration_test.dart`
- `docs/architecture/firestore-schema.md`
- `docs/tasks/TASK-013-configurar-cloud-firestore-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/injection_module.dart` (`@lazySingleton FirebaseFirestore firebaseFirestore(AppEnvironment)`
  chamando `configureFirestore`)
- `lib/app/injection.config.dart` (regenerado por `build_runner`, registra `FirebaseFirestore`)
- `docs/architecture/README.md` (link para `firestore-schema.md`)
- `README.md` (seção "Backend e Firebase": Firestore já conectado, e onde/por quê)
- `docs/tasks/TASKS.md` (checkbox da TASK-013 e progresso)

## Arquitetura utilizada

Infraestrutura pura em `lib/core/database/` (sem `domain/`/`presentation/` própria, pois esta task
não implementa nenhuma feature de negócio — apenas a base reutilizável por todas). Segue o mesmo
molde de isolamento de SDK já usado pelo Auth (TASK-012):
`FirestoreCollectionDataSource<T>` é o único ponto do app autorizado a importar `cloud_firestore`
para acesso a dados de feature; toda leitura/escrita passa por um `FirestoreConverter<T>` que
delega para o DTO/mapper da feature (convenção TASK-004), então nenhum `Map<String, dynamic>` ou
tipo do SDK (`DocumentSnapshot`, `QuerySnapshot`) atravessa a fronteira de `data/`. Erros do SDK
(`FirebaseException`) são convertidos por `mapFirestoreExceptionToAppException` para a hierarquia
`AppException` já existente (reaproveitada 100%, nenhum tipo novo), depois para `Failure` via
`mapAppExceptionToFailure` (mesma função genérica que `AboutAppRepositoryImpl`/`AuthRepositoryImpl`
já usam). Paginação por cursor usa uma função pura (`sliceFetchedPage`) separada da chamada real ao
SDK, para ser testável sem depender de uma instância real do Firestore.

## Regras de negócio implementadas

- Nenhuma regra de negócio de produto (task de infraestrutura).
- Toda operação de `FirestoreCollectionDataSource` exige `organizationId` explicitamente — não existe
  método que monte uma query sem escopo de tenant; a raiz de todo path é sempre
  `organizations/{organizationId}/{collectionName}`.
- "Delete" nunca é físico: `softDelete` sempre grava `deletedAt` (Timestamp) via `update`, nunca chama
  `DocumentReference.delete()`.
- `getPage` sempre busca `limit + 1` documentos para saber se há próxima página sem uma query de
  contagem separada; não existe operação que carregue uma collection inteira sem paginação.

## Regras Firebase implementadas

- `configureFirestore` habilita `Settings(persistenceEnabled: true)` e conecta ao Firestore Emulator
  (`useFirestoreEmulator`, host/porta de `lib/core/environment/`) para todo flavor que não seja
  `prod` — mesmo padrão ADR-0002 já usado pelo Auth.
- `FirebaseFirestore` é `@lazySingleton`: só é resolvido (e só então conecta ao emulador) quando algo
  de fato pede essa dependência via DI — hoje nenhuma feature pede, então isso não roda em nenhum
  teste de widget existente, pelo mesmo motivo documentado na TASK-012 para `firebase_auth`.
- **Firestore Security Rules continuam deny-all** (`firestore.rules`, placeholder da TASK-010) — esta
  task não alterou esse arquivo, propositalmente: TASK-030 é quem implementa RBAC/multi-tenant real.
  Isso é documentado explicitamente em `docs/architecture/firestore-schema.md` e refletido no próprio
  teste de integração (ver "Testes criados").

## Analytics implementado

Nenhum (fora do escopo desta task; TASK-017).

## Crashlytics implementado

Nenhum (TASK-016). Erros do Firestore são mapeados para `Failure`s tipadas em vez de vazar
`FirebaseException` ou crashar.

## Impacto offline

Nenhuma mudança de comportamento offline existente (nenhuma feature usa Firestore ainda).
`configureFirestore` habilita a persistência nativa do SDK (`Settings(persistenceEnabled: true)`) como
uma camada complementar — `docs/architecture/firestore-schema.md` documenta explicitamente a distinção
de responsabilidade com o Drift/Outbox do EPIC-14 (que continua sendo a camada deliberada de
offline-first do produto, ainda não implementada).

## Impacto multi-tenant

`FirestoreCollectionDataSource` obriga `organizationId` em toda operação (raiz
`organizations/{organizationId}`), mas isso é só defesa em profundidade do lado cliente — a garantia
real de isolamento de tenant continua dependendo inteiramente da TASK-030 (Firestore Security Rules),
que ainda não existe; hoje o `firestore.rules` deny-all bloqueia qualquer acesso real, inclusive desta
task.

## Testes criados

- `firestore_exception_mapper_test.dart`: cada código relevante (`unauthenticated`,
  `permission-denied`, `not-found`, `already-exists`, `aborted`, `failed-precondition`,
  `unavailable`, `deadline-exceeded`, `resource-exhausted`, `invalid-argument`, código desconhecido)
  mapeia para o `AppException` esperado, e todos convertem para uma `Failure` via
  `mapAppExceptionToFailure` sem quebrar o `switch` exaustivo.
- `firestore_converter_test.dart`: `fromSnapshotData`/`toDocumentData` fazem o round-trip
  DTO-map⇄entidade corretamente, incluindo o caso de dado nulo (documento vazio vindo do cache).
- `firestore_page_slice_test.dart`: `sliceFetchedPage` não repete itens entre páginas consecutivas
  (cobre "segunda página não repete itens da primeira") e uma página já retornada permanece intacta e
  imutável mesmo que a busca da página seguinte falhe (cobre "preserva itens já carregados em caso de
  erro na página seguinte").
- `firestore_collection_data_source_no_raw_map_test.dart`: escaneia o código-fonte da classe base e
  confirma que nenhuma assinatura pública `Future<...>`/`Stream<...>` contém `Map<String, dynamic>`
  no tipo de retorno.
- `integration_test/core/database/firestore_collection_data_source_integration_test.dart`: teste real
  de integração contra o Firestore Emulator — como `firestore.rules` está deliberadamente deny-all até
  a TASK-030 (e esta task não pode afrouxar essa regra), o teste valida o que é verdade hoje: `set`,
  `getById` e `getPage` reais contra o emulador retornam `permission-denied`, mapeado corretamente
  para `ForbiddenException` de ponta a ponta (não apenas para uma `FirebaseException` construída à
  mão, como no teste de mapper). Ver "Riscos conhecidos" sobre execução nesta sessão.

## Comandos executados

```bash
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --target lib/main_dev.dart --output build/web-dev-check
firebase emulators:start --only firestore --project vestipro
```

## Resultado do formatter

`Formatted 103 files (4 changed)` — apenas os arquivos novos desta task.

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

`flutter test`: 86 testes, todos passaram (66 pré-existentes + 20 novos desta task: mapper de
exceções, converter, paginação por cursor, teste estrutural de não-vazamento de `Map`).

`flutter build web --target lib/main_dev.dart` concluiu com sucesso (evidência de que o novo código
compila no target Web com a nova dependência de `FirebaseFirestore` na árvore de DI).

## Decisões técnicas

- **`FirestoreCollectionDataSource<T>` exige `organizationId` como parâmetro nomeado obrigatório em
  toda operação**, em vez de guardar um `organizationId` fixo na construção — reforça a regra "toda
  query deve ser escopada por tenant" estruturalmente (não há como esquecer), e permite reutilizar a
  mesma instância para chamadas de diferentes tenants sem recriar o datasource.
- **Nenhuma constante `Dart` foi criada para o mapa completo de collections da seção 20 de
  `tasks.md`** (customers, leads, priceLists, etc.): esse levantamento é conceitual e será
  revisto/ajustado por cada task de modelagem futura (TASK-048, TASK-064, TASK-083...); documentá-lo
  em `docs/architecture/firestore-schema.md` evita uma enum especulativa que ficaria desatualizada a
  cada nova task, sem nenhum código hoje dependendo dela.
- **`update(data: Map<String, Object?>)` mantém uma entrada em mapa para atualização parcial de
  campos** (pedida explicitamente pela task: "get, getStream, query..., set, update, delete") — usa
  `Object?` em vez de `dynamic` para ser mais estrito, e não conflita com "nunca expor
  `Map<String, dynamic>` cru": a regra é sobre o que o datasource *retorna* para fora de `data/`, não
  sobre o payload de escrita que o próprio chamador (dentro de `data/`) já monta a partir de um DTO.
- **`sliceFetchedPage` foi extraído como função pura livre de `cloud_firestore`**, genérica sobre
  qualquer `D`, especificamente para poder testar as regras de paginação (sem repetição entre
  páginas, imutabilidade de página já retornada) sem precisar de uma instância real do Firestore nem
  de mocks pesados do SDK.
- **O teste de integração assume `firestore.rules` deny-all e valida `permission-denied` em vez de um
  round-trip de escrita/leitura bem-sucedido.** Alternativa descartada: afrouxar `firestore.rules`
  temporariamente para permitir o teste passar com dados reais — rejeitada porque o próprio arquivo
  documenta explicitamente "nunca deve ficar mais permissivo que deny all antes da TASK-030", e
  AGENTS.md proíbe enfraquecer regras de segurança fora do escopo da task que as possui.
- **Emulador do Firestore é conectado no provider de DI (`injection_module.dart`)**, não em
  `bootstrap.dart` nem dentro de `FirestoreCollectionDataSource` — diferente do Auth (que conecta
  dentro do próprio `FirebaseAuthDataSource`) porque ainda não existe nenhum datasource concreto de
  feature que sirva de "ponto único" de resolução; o provider do `FirebaseFirestore` em si já é esse
  ponto, e evita duplicar a chamada de configuração em cada futura `FirestoreCollectionDataSource`
  construída pelas features.

## Riscos conhecidos

- **O teste de integração real contra o Firestore Emulator não pôde ser executado nesta sessão.**
  Tentativa real (não simulada): `firebase emulators:start --only firestore --project vestipro`
  falhou com `Could not spawn 'java -version'. Please make sure Java is installed and on your system
  PATH.` — confirma a mesma limitação já registrada na TASK-010 ("Instalar um JRE para validar
  `firebase emulators:start --only firestore,storage` localmente" ficou pendente). O `firebase`
  CLI está instalado (`15.24.0`) e funcional; falta apenas o JRE nesta máquina para o próprio
  emulador do Firestore (que roda sobre a JVM, diferente do Auth Emulator).
  - `flutter analyze` confirma que o arquivo de teste de integração compila e tipa corretamente.
  - Fica como pendência real (não simulada como concluída): instalar um JRE nesta máquina (ou rodar
    em CI/outra máquina com Java disponível) e então executar
    `firebase emulators:exec "flutter test integration_test/core/database/... -d chrome"`.
- O modelo de collections em `docs/architecture/firestore-schema.md` é conceitual (mesma ressalva já
  presente na seção 20 de `tasks.md`); cada task de modelagem futura pode ajustar paths/índices
  conforme o padrão real de consulta.
- Nenhuma feature usa `FirestoreCollectionDataSource` ainda — a primeira validação de uso real
  acontece só a partir da TASK-048 (modelar Customer).

## Pendências

- Validar `integration_test/core/database/firestore_collection_data_source_integration_test.dart` de
  ponta a ponta em um ambiente com JRE instalado para o Firestore Emulator.
- TASK-030 deve substituir `firestore.rules` (hoje deny-all) pelas regras reais de RBAC/multi-tenant;
  quando isso acontecer, vale revisitar o teste de integração desta task para também cobrir um
  round-trip de escrita/leitura bem-sucedido (não só o caminho de `permission-denied`).
- Push depende de autorização explícita do usuário.

## Evidências

- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!` (86 testes).
- `flutter build web --target lib/main_dev.dart --output build/web-dev-check` → `Built
  build\web-dev-check` (removido após a validação, é apenas saída de build gitignorada).
- `firebase emulators:start --only firestore --project vestipro` → `Could not spawn 'java -version'.
  Please make sure Java is installed and on your system PATH.` (evidência real da limitação de
  ambiente, não simulada).

## Commit

Commit criado após a conclusão desta documentação.

## Push

Não executado nesta task; depende de autorização explícita do usuário.

## Hash do commit

Preenchido após a criação do commit (ver seção seguinte da resposta final).

## Branch

`main`
