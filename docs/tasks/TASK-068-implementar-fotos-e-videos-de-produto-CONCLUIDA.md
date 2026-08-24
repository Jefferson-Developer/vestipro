# TASK-068 — Concluída (2026-08-24)

## Resumo

Implementada a galeria de mídia de produto: upload de fotos com compressão e geração de
thumbnail, upload de vídeo curto com validação client-side de tamanho/duração antes de
transferir qualquer byte, reordenação (drag-and-drop no Web/desktop, "mover para cima/baixo"
no mobile), definição/promoção automática de foto principal e exclusão com auto-promoção de
substituta. `photoUrls`/`videoUrls` (listas simples de string do TASK-064) foram substituídas
por `Product.media: List<ProductMedia>`, o único jeito de representar ordem, foto principal e
vínculo opcional com cor (TASK-070) exigido por esta task.

## Agentes utilizados

- `flutter-senior-architect` (domínio, dados, BLoC, DI, Storage Rules, Remote Config)
- `flutter-ui-design-specialist` (seção "Mídia" do formulário, galeria reordenável, player
  básico de vídeo)

## Arquivos criados

- `lib/features/products/domain/value_objects/product_media_type.dart`
- `lib/features/products/domain/entities/product_media.dart` (+ `.freezed.dart` gerado)
- `lib/features/products/domain/product_media_rules.dart` (append/reorder/setPrincipal/remove
  puros, sem I/O)
- `lib/features/products/domain/usecases/update_product_media_use_case.dart`
- `lib/features/products/data/dtos/product_media_dto.dart`
- `lib/features/products/presentation/bloc/product_media_event.dart`
- `lib/features/products/presentation/bloc/product_media_state.dart`
- `lib/features/products/presentation/bloc/product_media_bloc.dart`
- `lib/features/products/presentation/widgets/product_media_gallery.dart`
  (`ProductMediaGallerySection` + player de vídeo básico)
- `test/features/products/domain/product_media_rules_test.dart`
- `test/features/products/domain/usecases/update_product_media_use_case_test.dart`
- `test/features/products/presentation/bloc/product_media_bloc_test.dart`
- `test/features/products/presentation/widgets/product_media_gallery_test.dart`

## Arquivos alterados

- `lib/features/products/domain/entities/product.dart` (+ `.freezed.dart`): `photoUrls`/
  `videoUrls` → `media`; getters `photos`/`videos`/`principalPhoto`/`hasPrincipalPhoto`.
- `lib/features/products/domain/product_completeness_validator.dart`: novo parâmetro
  `hasPrincipalPhoto`, erro de campo `media`.
- `lib/features/products/domain/usecases/publish_product_use_case.dart`: passa
  `current.hasPrincipalPhoto` para o validador.
- `lib/features/products/data/dtos/product_dto.dart`,
  `lib/features/products/data/mappers/product_mapper.dart`,
  `lib/features/products/data/repositories/shared_preferences_product_repository.dart`:
  serialização de `media` (Firestore e o store local `SharedPreferences` até o Outbox real,
  TASK-105+).
- `lib/features/products/presentation/pages/product_form_page.dart`: nova seção "Mídia",
  `createMediaBloc` (só instancia `ProductMediaBloc` quando o produto já existe).
- `lib/features/products/products.dart`: novos exports.
- `lib/core/storage/image_upload_compressor.dart`, `lib/core/storage/image_compressor.dart`:
  `@lazySingleton`/`@LazySingleton(as: ImageCompressor)` — infraestrutura do TASK-014 ainda não
  registrada na DI, precisou ser registrada para o primeiro consumidor real.
- `lib/core/analytics/analytics_events.dart`: `productMediaUpdated`.
- `lib/core/feature_flags/feature_flag_registry.dart`,
  `docs/architecture/feature-flags.md`: `config_products_video_max_duration_seconds` (default
  60s) e `config_products_video_max_size_mb` (default 50MB) — "limite configurável por
  organização" via Remote Config, mesmo mecanismo já usado por `feature_insights_enabled`.
- `storage.rules`: `isValidProductImage` → `isValidProductMedia` (foto OU vídeo, com teto de
  100MB para vídeo — duração não é verificável em Security Rules, só client-side).
- `storage-tests/storage.rules.test.js`: 2 casos novos (upload de vídeo válido/oversized).
- `pubspec.yaml`/`pubspec.lock`: `video_player: ^2.14.0`.
- Testes existentes ajustados para o novo campo `media`/regra de foto principal:
  `test/features/products/data/mappers/product_mapper_test.dart`,
  `test/features/products/domain/product_completeness_validator_test.dart`,
  `test/features/products/domain/usecases/publish_product_use_case_test.dart`,
  `test/features/products/presentation/bloc/product_form_bloc_test.dart`,
  `test/features/products/presentation/pages/product_form_page_test.dart`,
  `test/core/analytics/analytics_events_test.dart`.

## Arquitetura utilizada

Clean/feature-first + BLoC. `ProductMediaBloc` é um BLoC dedicado (não uma extensão do já
grande `ProductFormBloc`), instanciado em um `BlocProvider` próprio na seção "Mídia" — só
quando `ProductFormState.currentProduct != null`, já que todo path de Storage exige um
`productId` real (`StoragePaths.productFile`). Toda mutação de `Product.media` passa por
`UpdateProductMediaUseCase`, nunca por uma chamada direta a `ProductRepository.update` fora
dele. A UI (`ProductMediaGallerySection`) nunca toca `StorageDataSource`/`ProductRepository`
diretamente — só dispara eventos e lê o estado do bloc.

## Regras de negócio implementadas

- Produto não pode ser publicado sem foto principal (`hasPrincipalPhoto`), verificado por
  `validateProductCompletenessForPublish` e `PublishProductUseCase`.
- A primeira foto enviada é promovida automaticamente a principal (`appendProductMedia`).
- Excluir a foto principal promove automaticamente a próxima foto restante (`removeProductMedia`);
  se não houver outra, o produto fica sem principal (volta a bloquear publicação, sem bloquear
  a exclusão em si — uma das duas opções que a task permitia).
- Reordenação é sempre escopada por tipo (fotos e vídeos têm sequências independentes) e exige o
  conjunto completo de ids do mesmo tipo — um conjunto incompleto/mesclado é ignorado.
- Vídeo respeita limite de tamanho/duração antes de qualquer upload (`ProductMediaBloc` valida
  contra os parâmetros do Remote Config antes de chamar `StorageDataSource.uploadFile`).
- Cancelamento de upload em andamento (`StorageUploadCancelToken`) não é tratado como falha
  visível ao usuário — mesma regra já documentada em `mapStorageExceptionToAppException`.

## Regras Firebase implementadas

`storage.rules`: o path de produto (`organizations/{organizationId}/products/{productId}/{fileName}`)
agora aceita `image/*` (10MB) OU `video/*` (100MB), mantendo RBAC (`catalog.manage`) e
isolamento multi-tenant já existentes desde o TASK-031. Duração de vídeo não é validável em
Security Rules — só client-side, documentado explicitamente na regra.

## Analytics implementado

`AnalyticsEvents.productMediaUpdated` (`product_media_updated`), disparado após cada upload de
foto bem-sucedido, com `organization_id`/`product_id`/`media_type`/`media_count` (sem dado
pessoal/sensível).

## Crashlytics implementado

Nenhuma mudança dedicada — erros de upload/persistência de mídia seguem o mesmo caminho de
`AppException`/`Failure` já coberto pelo `CrashReporter` central (TASK-016), sem necessidade de
instrumentação adicional nesta task.

## Impacto offline

`SharedPreferencesProductRepository` (armazenamento local até o Outbox real do TASK-108+)
passa a serializar `media` da mesma forma que já fazia com `photoUrls`/`videoUrls`. O upload em
si (Storage) continua exigindo rede — este task não implementa fila offline de upload de mídia;
isso fica registrado como pendência conhecida (mesma linha que outros uploads/anexos do app
ainda não têm outbox dedicado).

## Impacto multi-tenant

Nenhuma mudança de isolamento: o path de Storage continua
`organizations/{organizationId}/products/{productId}/{fileName}`, com o mesmo Membership real
relido nas regras (nunca confiando em `organizationId` vindo do cliente).

## Testes criados

- `product_media_rules_test.dart`: append/reorder/setPrincipal/remove, incluindo auto-promoção
  de principal e rejeição de conjunto de reordenação incompleto.
- `update_product_media_use_case_test.dart`: persistência com/sem auditoria conforme status do
  produto, e validação de campos obrigatórios.
- `product_media_bloc_test.dart`: upload de foto (compressão + thumbnail + persistência como
  principal), rejeição de vídeo acima do limite de duração/tamanho **antes** de chamar
  `StorageDataSource.uploadFile`, cancelamento de upload em andamento, exclusão da foto
  principal com promoção automática e tentativa de exclusão dos arquivos de Storage
  correspondentes (foto + thumbnail).
- `product_media_gallery_test.dart` (widget): renderização de fotos com badge "Principal",
  definição de nova foto principal end-to-end (persistindo no repositório) e reordenação via
  "mover para baixo" (mobile, sem gesto de arrastar), seguindo o mesmo padrão de
  `CategoriesPage`'s reorder test.
- Testes existentes atualizados: `product_mapper_test.dart` (round-trip de `media`),
  `product_completeness_validator_test.dart`/`publish_product_use_case_test.dart` (bloqueio de
  publish sem foto principal), `product_form_bloc_test.dart`/`product_form_page_test.dart`
  (novo parâmetro `createMediaBloc`), `analytics_events_test.dart` (novo evento).
- Storage Rules: 2 novos casos em `storage-tests/storage.rules.test.js` (upload de vídeo
  válido e vídeo acima do tamanho máximo) — **não executados nesta rodada** (exigem
  `firebase emulators:exec --only "firestore,storage" "npm --prefix storage-tests test"`, fora
  do escopo de `flutter test`); os casos de foto positiva/negativa já existiam desde o
  TASK-031 e continuam cobrindo RBAC/multi-tenant/tipo/tamanho.

## Comandos executados

```bash
flutter pub get
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 1085 files (0 changed) in 3.18 seconds.` — sem alterações pendentes.

## Resultado do analyzer

`No issues found!`

## Resultado dos testes

`flutter test` (suíte completa): `+1487` — todos passando, nenhuma falha.

## Decisões técnicas

- `ProductMediaBloc` separado do `ProductFormBloc` (já grande, organizado por seção) — mantém a
  galeria isolada e testável sem inflar ainda mais o bloc do formulário.
- `ProductMedia.id` dobra como nome de arquivo no Storage (`StoragePaths.productFile`), evitando
  um campo extra de "storage path" que teria que ser mantido em sincronia com `url`.
- Thumbnail sempre gerado via `ImageCompressor.compress` (não via `ImageUploadCompressor.
  compressForUpload`, que pula compressão para arquivos já pequenos) — garante que a miniatura
  nunca seja, na prática, a imagem original, mesmo para uma foto de poucos KB mas alta resolução.
- Limite de tamanho/duração de vídeo "configurável por organização" implementado via Remote
  Config (`FeatureFlagRegistry`), o mesmo mecanismo já usado por `feature_insights_enabled` —
  não existe hoje uma entidade de configuração por organização dedicada; documentado como a
  extensão natural quando essa entidade existir.
- `video_player: ^2.14.0` foi adicionado como nova dependência (Android/iOS/Web — os 3
  alvos deste projeto; sem Windows/macOS/Linux no repositório) para o player básico e para
  sondar a duração do vídeo antes do upload.
- `ImageUploadCompressor`/`FlutterImageCompressor` (infraestrutura já existente do TASK-014,
  nunca antes consumida por nenhuma feature) precisaram ganhar registro de DI
  (`@lazySingleton`) — primeira feature real a depender deles.

## Riscos conhecidos

- `roleHasCapability`/limites de mídia em `storage.rules` continuam sendo uma cópia manual do
  Dart (`RolePermissionMatrix`) — mesmo risco de divergência já registrado desde o TASK-030/031,
  agora com mais uma regra (`isValidProductMedia`) sujeita a isso.
- Geração de thumbnail de vídeo não foi implementada (exigiria `video_thumbnail` ou uma Cloud
  Function dedicada); `ProductMedia.thumbnailUrl` fica `null` para vídeos — a UI usa um ícone de
  play como placeholder no lugar de uma miniatura real.
- Exclusão do arquivo de Storage ao remover uma mídia é best-effort (a metadata em
  `Product.media` é a fonte da verdade e é atualizada primeiro); uma falha na exclusão do
  arquivo deixa um objeto órfão no bucket, sem referência em nenhum documento.
- Upload de mídia não passa pelo Outbox/offline (exige rede no momento do upload) — consistente
  com o restante do app antes do TASK-108, mas vale registrar como limite explícito desta task.
- Os 2 novos casos de Storage Rules para vídeo não foram executados nesta rodada (dependem do
  Firebase Emulator Suite via Node/Jest, fora do escopo de `flutter test`).

## Pendências

- Miniatura de vídeo real (via `video_thumbnail` ou Cloud Function no upload).
- Configuração de limite de vídeo por organização via uma entidade de configuração dedicada,
  quando essa entidade existir (hoje é um parâmetro global de Remote Config).
- Rodar `storage-tests/storage.rules.test.js` contra o Firebase Emulator Suite para validar os
  2 casos novos de vídeo.

## Evidências

- `flutter test` completo: `+1487` (todos passando).
- `flutter analyze`: sem apontamentos.
- `dart format --set-exit-if-changed .`: sem alterações pendentes.

## Commit

Ver hash abaixo.

## Push

Não realizado nesta rodada (autorização apenas para commit local).

## Hash do commit

Ver mensagem final da task.

## Branch

main
