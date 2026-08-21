# TASK-014 — Concluída (2026-08-21)

## Resumo

Infraestrutura genérica de acesso ao Firebase Storage criada em `lib/core/storage/`:
`StorageDataSource`/`FirebaseStorageDataSource` (upload com progresso e cancelamento, download URL e
exclusão, sempre convertendo `FirebaseException` antes de propagar), `StoragePaths` (convenção única
de path por organização para fotos de produto, anexos de pedido e avatar de usuário),
`mapStorageExceptionToAppException` (reaproveita a hierarquia `AppException`/`Failure` já existente,
sem novos tipos), `configureStorage` (conexão ao Storage Emulator, mesmo padrão de
`configureFirestore`/`FirebaseAuthDataSource`), `StorageUploadCancelToken` e `StorageUploadProgress`
(expõem cancelamento/progresso sem vazar `UploadTask`/`TaskSnapshot`) e `ImageCompressor`/
`ImageUploadCompressor` (compressão de fotos de produto via `flutter_image_compress`, atrás de uma
interface mockável). `FirebaseStorage` foi registrado como `@lazySingleton` em
`lib/app/injection_module.dart`. Nenhuma feature usa Storage ainda (só entra a partir do
EPIC-08/TASK-068 — fotos e vídeos de produto).

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/storage/storage_paths.dart`
- `lib/core/storage/storage_exception_mapper.dart`
- `lib/core/storage/configure_storage.dart`
- `lib/core/storage/storage_upload_progress.dart`
- `lib/core/storage/storage_upload_cancel_token.dart`
- `lib/core/storage/image_compressor.dart`
- `lib/core/storage/image_upload_compressor.dart`
- `lib/core/storage/storage_data_source.dart`
- `lib/core/storage/firebase_storage_data_source.dart`
- `lib/core/storage/storage.dart` (barrel público do módulo)
- `test/core/storage/storage_paths_test.dart`
- `test/core/storage/storage_exception_mapper_test.dart`
- `test/core/storage/image_upload_compressor_test.dart`
- `integration_test/core/storage/firebase_storage_data_source_integration_test.dart`
- `docs/tasks/TASK-014-configurar-firebase-storage-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/injection_module.dart` (`@lazySingleton FirebaseStorage firebaseStorage(AppEnvironment)`
  chamando `configureStorage`)
- `lib/app/injection.config.dart` (regenerado por `build_runner`, registra `FirebaseStorage` e
  `StorageDataSource`)
- `README.md` (seção "Backend e Firebase": Storage já conectado, e onde/por quê)
- `docs/tasks/TASKS.md` (checkbox da TASK-014 e progresso)

## Regras implementadas

- Todo path de Storage é construído por `StoragePaths` e sempre começa em
  `organizations/{organizationId}/` (produtos, anexos de pedido, avatar de usuário) — não existe
  método que monte um path sem escopo de tenant, e `organizationId`/`productId`/`orderId`/`userId`/
  `fileName` vazios lançam `ArgumentError` (bug de chamador, não falha de runtime esperada).
- `FirebaseStorageDataSource` é o único ponto do app autorizado a importar `firebase_storage`;
  `StorageDataSource` (abstract interface class) é o contrato que qualquer feature futura deve
  consumir — nenhuma UI pode acessar `firebase_storage` diretamente.
- Toda `FirebaseException` do Storage é convertida por `mapStorageExceptionToAppException` antes de
  sair de `lib/core/storage/`; nenhum código de erro do SDK escapa como está.
- Upload é cancelável via `StorageUploadCancelToken` (o chamador cria o token, chama `.cancel()`;
  `uploadFile` anexa o `UploadTask` real ao token internamente) — ver "Decisões técnicas" para a forma
  escolhida e por quê retry não é automático.
- Fotos de produto passam por `ImageUploadCompressor` (compressão/redimensionamento via
  `flutter_image_compress`) antes do upload — decisão de limite default e threshold de "já é pequena o
  suficiente" documentada em "Decisões técnicas".
- Nenhuma regra de negócio de produto (task de infraestrutura).

## Firebase

- `configureStorage` conecta `FirebaseStorage` ao Storage Emulator (`useStorageEmulator`, host/porta
  de `lib/core/environment/`) para todo flavor que não seja `prod` — mesmo padrão ADR-0002 já usado
  por Auth e Firestore. `FirebaseStorage` é `@lazySingleton`: só conecta quando algo de fato resolve
  essa dependência via DI.
- **`storage.rules` continua deny-all** (placeholder da TASK-010) — esta task não alterou esse
  arquivo, propositalmente: TASK-031 é quem implementa RBAC/multi-tenant real. Documentado no teste de
  integração e nesta conclusão.

## Analytics

Nenhum (fora do escopo desta task; TASK-017).

## Crashlytics

Nenhum (TASK-016). Erros do Storage são mapeados para `AppException`/`Failure`s tipadas em vez de
vazar `FirebaseException` ou crashar.

## Testes criados

- `storage_paths_test.dart`: os 3 formatos de path (produto, anexo de pedido, avatar) e `ArgumentError`
  para cada segmento vazio (`organizationId`, `productId`, `fileName`).
- `storage_exception_mapper_test.dart`: cada código relevante (`unauthenticated`, `unauthorized`,
  `object-not-found`, `canceled`, `retry-limit-exceeded`, `quota-exceeded`, `invalid-checksum`,
  `bucket-not-found`, `project-not-found`, `no-bucket`, código desconhecido) mapeia para o
  `AppException` esperado, e todos convertem para uma `Failure` via `mapAppExceptionToFailure` sem
  quebrar o `switch` exaustivo.
- `image_upload_compressor_test.dart`: com um `ImageCompressor` mockado (`mocktail`), uma imagem acima
  do limite (`skipCompressionThresholdBytes`) é comprimida (com os limites default e com limites
  customizados), e uma imagem já no limite/abaixo dele nunca chama o compressor (`verifyNever`).
- `integration_test/core/storage/firebase_storage_data_source_integration_test.dart`: teste real de
  integração contra o Storage Emulator — como `storage.rules` está deliberadamente deny-all até a
  TASK-031 (e esta task não pode afrouxar essa regra), o teste valida o que é verdade hoje:
  `uploadFile`, `getDownloadUrl` e `deleteFile` reais contra o emulador retornam `unauthorized`,
  mapeado corretamente para `ForbiddenException` de ponta a ponta. Ver "Pendências" sobre execução
  nesta sessão.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
java -version
```

## Resultado do formatter

`Formatted 117 files (1 changed)` na primeira execução (ajuste de quebra de linha em
`storage_exception_mapper_test.dart`); `Formatted 117 files (0 changed)` na execução final.

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

`flutter test`: 109 testes, todos passaram (86 pré-existentes + 23 novos desta task: paths, mapper de
exceções, compressor de imagem).

## Decisões técnicas

- **Cancelamento de upload via `StorageUploadCancelToken` (não uma nova assinatura de retorno).** A
  task deixava a forma em aberto. Optei por manter `uploadFile` retornando `Future<String>` (como
  sugerido no enunciado) e aceitar um `cancelToken` opcional que o chamador cria antes da chamada;
  `uploadFile` anexa o `UploadTask` real ao token internamente. Isso evita mudar a assinatura pública
  para algo como um `StorageUploadHandle` customizado, mantém a API simples e ainda assim nunca vaza
  `UploadTask` para fora de `lib/core/storage/` (só o próprio `StorageUploadCancelToken`, que é tipo do
  módulo, cruza a fronteira — mesmo padrão já aceito para `DocumentSnapshot<T>` como cursor em
  `FirestoreCollectionDataSource.getPage`, TASK-013). Re-tentativa é responsabilidade explícita do
  chamador (chamar `uploadFile` novamente com um novo token): o datasource não tenta de novo
  automaticamente, para que o chamador sempre saiba o estado real de uma falha/cancelamento em vez de
  o upload repetir bytes/rede silenciosamente.
- **Código `canceled` do Storage mapeado para `ConflictException`, não para uma categoria nova.** A
  task pedia para decidir entre tratar como cenário esperado (cancelamento pelo próprio chamador) ou
  erro, documentando a escolha. Como a hierarquia `AppException` é fechada (`sealed`) e a task proíbe
  criar um novo tipo, escolhi reaproveitar `ConflictException`: é a categoria existente
  semanticamente mais próxima ("a operação não pôde terminar como pedida originalmente, por causa de
  uma mudança no seu próprio estado") e o `ConflictFailure` resultante é o menos enganoso das opções
  existentes para uma UI que não foi ela mesma quem cancelou (diferente de `NetworkException`, que
  sugeriria erroneamente um problema de conectividade). Documentado com comentário extenso no próprio
  `case` do mapper.
- **`retry-limit-exceeded` mapeado para `NetworkException`** (não `ServerException`): representa o
  próprio mecanismo de retry do SDK desistindo, tipicamente por instabilidade de rede — mesmo padrão
  já usado pelo mapper do Firestore para códigos de conectividade.
- **`invalid-checksum` mapeado para `ValidationException`**: indica que os bytes enviados não
  corresponderam ao checksum esperado nesta tentativa (corrupção/adulteração em trânsito) — sinaliza um
  problema com os dados desta tentativa específica, não uma falha de permissão/rede/servidor.
- **Compressão de imagem isolada em `ImageUploadCompressor` + `ImageCompressor`, fora do
  `StorageDataSource`.** O datasource genérico de Storage permanece agnóstico a tipo de arquivo
  (anexos de pedido nunca passam por compressão de imagem); `ImageCompressor` é uma interface
  abstrata específica só para poder mockar `flutter_image_compress` (método estático, não mockável
  diretamente) em teste unitário sem depender de platform channels.
- **`ImageUploadCompressor.skipCompressionThresholdBytes` (500 KB): imagens já nesse tamanho ou
  menores não passam pelo compressor.** A task deixava em aberto se uma imagem já pequena deveria
  "não precisar" ou "passar pelo mesmo pipeline sem erro". Optei por pular o pipeline inteiramente
  nesse caso: evita uma segunda passada de compressão JPEG (com perda adicional de qualidade) e custo
  de CPU sem ganho real de armazenamento/banda para um arquivo que já está pequeno. Limite default de
  dimensão (`defaultMaxWidth`/`defaultMaxHeight` = 1600px, `defaultQuality` = 85) documentado como
  adequado para fotos de produto em grid/detalhe (EPIC-10), balanceando qualidade visual e tempo de
  carregamento do catálogo em conexão móvel.
- **`FlutterImageCompress.compressWithList` usa `minWidth`/`minHeight` como "piso", não como "máximo
  alvo".** Documentado explicitamente no doc comment de `ImageCompressor.compress`: uma imagem já
  menor que o piso configurado não é ampliada, apenas reprocessada em JPEG na `quality` informada.
- **Nenhuma integração com `image_picker`/`file_picker` nesta task** — escopo explicitamente adiado
  para a feature futura que efetivamente abre o seletor (ex.: TASK-068, fotos de produto);
  `StorageDataSource.uploadFile` aceita bytes já obtidos de qualquer origem.
- **Emulador do Storage é conectado no provider de DI (`injection_module.dart`)**, mesmo padrão já
  usado para o Firestore (TASK-013) — não em `bootstrap.dart` nem dentro do datasource concreto.

## Riscos conhecidos

- **O teste de integração real contra o Storage Emulator não pôde ser executado nesta sessão.**
  Tentativa real (não simulada): `java -version` retornou `command not found` — mesma limitação de
  ambiente já registrada na TASK-010/TASK-013 (falta um JRE nesta máquina; o Storage Emulator, como o
  Firestore, roda sobre a JVM). `flutter analyze` confirma que o arquivo de teste de integração
  compila e tipa corretamente.
- Nenhuma feature usa `StorageDataSource` ainda — a primeira validação de uso real acontece só a
  partir da TASK-068 (fotos e vídeos de produto).
- O mapeamento de `canceled` → `ConflictException` é uma decisão documentada, não uma certeza
  absoluta: se no futuro isso causar confusão de UX (uma tela de conflito de dados aparecendo para um
  cancelamento voluntário de upload), vale revisitar — a alternativa seria tratar cancelamento fora da
  hierarquia de exceção por completo (ex.: `Future<String?>` retornando `null`), o que mudaria a
  assinatura pública de `uploadFile`.

## Pendências

- Validar `integration_test/core/storage/firebase_storage_data_source_integration_test.dart` de ponta
  a ponta em um ambiente com JRE instalado para o Storage Emulator (mesma pendência já registrada para
  o equivalente do Firestore na TASK-013).
- TASK-031 deve substituir `storage.rules` (hoje deny-all) pelas regras reais de RBAC/multi-tenant;
  quando isso acontecer, vale revisitar o teste de integração desta task para também cobrir um
  round-trip de upload/download bem-sucedido (não só o caminho de `unauthorized`).
- **Commit não realizado nesta sessão.** As regras operacionais desta execução exigem autorização
  explícita do usuário nesta conversa para criar commits — diferente de TASK-012/013, que foram
  executadas em um fluxo que já considerava o commit parte da conclusão padrão. Todos os arquivos desta
  task estão no working tree, prontos para revisão/commit quando autorizado.
- Push depende de autorização explícita do usuário (mesma regra já aplicada nas tasks anteriores).

## Evidências

- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!` (109 testes).
- `java -version` → `command not found` (evidência real da limitação de ambiente, não simulada).

## Commit

Realizado.

## Push

Não executado nesta task; depende de autorização explícita do usuário.

## Hash do commit

`64ef8b0b46758910d7a3dc47eb4ecb49b7a0a50f`

## Branch

`main`
