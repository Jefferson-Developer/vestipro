# TASK-072 — Concluída (2026-08-25)

## Resumo
Implementada a geração automática e incremental de variantes vendáveis produto-cor-tamanho, com `ProductVariant`, SKU/EAN próprios, unicidade por organização, edição manual, inativação sem exclusão física e persistência local offline-first. Também foi criada uma camada Firestore opt-in e um teste de integração de emulador para validar persistência remota quando houver runner `integration_test` disponível.

## Agentes utilizados
- `flutter-senior-architect`

## Arquivos criados
- `lib/features/products/domain/entities/product_variant.dart`
- `lib/features/products/domain/value_objects/product_variant_status.dart`
- `lib/features/products/domain/repositories/product_variant_repository.dart`
- `lib/features/products/domain/usecases/generate_product_variants_use_case.dart`
- `lib/features/products/domain/usecases/update_product_variant_use_case.dart`
- `lib/features/products/domain/usecases/delete_product_variant_use_case.dart`
- `lib/features/products/data/repositories/shared_preferences_product_variant_repository.dart`
- `lib/features/products/data/dtos/product_variant_dto.dart`
- `lib/features/products/data/mappers/product_variant_mapper.dart`
- `lib/features/products/data/repositories/firestore_product_variant_repository.dart`
- `test/features/products/domain/usecases/generate_product_variants_use_case_test.dart`
- `test/features/products/domain/usecases/product_variant_use_cases_test.dart`
- `test/features/products/data/mappers/product_variant_mapper_test.dart`
- `integration_test/features/products/product_variant_firestore_repository_integration_test.dart`

## Arquivos alterados
- `firestore.rules`
- `lib/app/injection.config.dart`
- `lib/features/products/products.dart`
- `test/features/products/product_factory.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first em `features/products`: domínio com entidade, value object, contrato de repositório e use cases; data com repositório local SharedPreferences e repositório Firestore opt-in; integração por `FirestoreCollectionDataSource`; UI não acessa persistência diretamente.

## Regras de negócio implementadas
- Variante representa uma combinação vendável de produto, cor e tamanho.
- Geração cor x tamanho a partir de `Product.colorIds` e `Product.sizeGridTemplateId`.
- Geração incremental idempotente: execução repetida preserva ids e não duplica combinações.
- Nova cor/tamanho gera apenas variantes faltantes.
- SKU derivado de SKU do produto + código da cor + tamanho, com edição manual via use case.
- EAN da variante é independente do EAN de produto/cor.
- SKU e EAN ativos são únicos por organização.
- Remoção de variante sempre inativa o registro, preservando histórico.

## Regras Firebase implementadas
Adicionadas rules para `organizations/{organizationId}/productVariants/{variantId}` com leitura para membro ativo, escrita restrita a `catalog.manage`, validação de payload, imutabilidade de tenant/matriz após criação e `delete` físico negado.

## Analytics implementado
Não foram adicionados novos eventos. Esta task não incluiu UI/fluxo analítico novo.

## Crashlytics implementado
Sem alteração específica. Falhas são retornadas como `Failure` tipado para tratamento pelos fluxos consumidores.

## Impacto offline
Persistência principal segue local via SharedPreferences com `ProductSyncStatus.pending`. O repositório de variantes atualiza o índice `size_grid_variant_usage_<organizationId>` para proteger tamanhos já usados por variantes.

## Impacto multi-tenant
Todas as operações são escopadas por `organizationId`; unicidade de SKU/EAN é por organização; rules validam `organizationId` pelo path e não confiam apenas no payload.

## Testes criados
- Unitários de geração cobrindo produto novo, idempotência e incremento por nova cor.
- Unitários de unicidade de SKU/EAN com `ConflictFailure`.
- Unitário de inativação de variante referenciada por pedido.
- Unitário de mapper Firestore de `ProductVariant`.
- Integration test de emulador para persistência Firestore com Auth + `createOrganization` + RBAC `catalog.manage` preparado em `integration_test/features/products/product_variant_firestore_repository_integration_test.dart`.

## Comandos executados
- `dart format lib\features\products test\features\products`
- `dart format lib\features\products\data\dtos\product_variant_dto.dart lib\features\products\data\mappers\product_variant_mapper.dart lib\features\products\data\repositories\firestore_product_variant_repository.dart test\features\products\data\mappers\product_variant_mapper_test.dart integration_test\features\products\product_variant_firestore_repository_integration_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test\features\products\data\mappers\product_variant_mapper_test.dart test\features\products\domain\usecases\generate_product_variants_use_case_test.dart test\features\products\domain\usecases\product_variant_use_cases_test.dart`
- `flutter test`
- `$env:PATH='C:\Program Files\Android\Android Studio\jbr\bin;' + $env:PATH; firebase emulators:exec --only auth,firestore,functions "flutter test integration_test/features/products/product_variant_firestore_repository_integration_test.dart -d chrome"`
- `$env:PATH='C:\Program Files\Android\Android Studio\jbr\bin;' + $env:PATH; firebase emulators:exec --only auth,firestore,functions "flutter test integration_test/features/products/product_variant_firestore_repository_integration_test.dart -d windows"`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 1158 files, 0 changed.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
`flutter test` passou: 1522 testes, All tests passed.

O teste de integração com Firebase Emulator foi criado e os emuladores Auth/Firestore/Functions subiram com sucesso usando o JDK do Android Studio. A execução do `integration_test` não pôde ser concluída neste ambiente: `-d chrome` falhou porque web não é suportado para integration tests; `-d windows` falhou porque o projeto não tem Windows desktop configurado. As rules foram carregadas pelo Firestore Emulator nas duas tentativas.

## Decisões técnicas
- Manter SharedPreferences como repositório injetado padrão para preservar o fluxo offline-first atual.
- Criar `FirestoreProductVariantRepository` sem trocar a DI, preparando sincronização remota e teste de persistência com emulador.
- Usar status `inactive` como soft delete único, sem método de exclusão física no contrato.
- Validar uniqueness apenas entre variantes ativas, permitindo histórico inativo com SKU/EAN antigo.

## Riscos conhecidos
- O integration test de emulador depende de um device/runner suportado pelo projeto, ainda indisponível neste ambiente.
- A persistência Firestore foi preparada como camada opt-in; a sincronização definitiva entre cache local e remoto ainda depende de tarefas futuras de outbox/sync.

## Pendências
Executar `integration_test/features/products/product_variant_firestore_repository_integration_test.dart` quando houver Android device/emulator ou suporte desktop configurado para o projeto.

## Evidências
- Formatter, analyzer e suíte completa executados com sucesso.
- Testes novos cobrem geração, idempotência, incremento, unicidade, inativação e mapper Firestore.
- Firebase Emulator iniciou Auth/Firestore/Functions e carregou `firestore.rules`; falha restante foi limitação do runner Flutter.

## Commit
Local, a ser preenchido após o commit.

## Push
Não realizado, conforme instrução do usuário.

## Hash do commit
A ser preenchido após o commit.

## Branch
main
