# TASK-069 — Concluída (2026-08-25)

## Resumo

Implementada a busca global de produtos por nome, SKU, referência, EAN e tags, com normalização
case/acento-insensível, índice remoto por prefixos para Firestore, índice offline em Drift,
`SearchProductsUseCase`, repositório dedicado, BLoC com debounce/restartable e UI reutilizável com
alternância Online/Offline e aviso de dados offline potencialmente desatualizados.

## Agentes utilizados

- `flutter-senior-architect` (Clean Architecture, Firestore, Drift, BLoC, DI, regras e testes).
- `flutter-ui-design-specialist` (UI reutilizável com Design System, estados e aviso offline).
- `vestipro-sales-representative-specialist` (busca rápida de catálogo para venda em campo/offline).

## Arquivos criados

- `lib/core/database/tables/product_search_index_table.dart`
- `lib/features/products/domain/services/product_search_normalizer.dart`
- `lib/features/products/domain/entities/product_search_source.dart`
- `lib/features/products/domain/entities/product_search_result.dart`
- `lib/features/products/domain/repositories/product_search_repository.dart`
- `lib/features/products/domain/usecases/search_products_use_case.dart`
- `lib/features/products/data/datasources/product_remote_search_data_source.dart`
- `lib/features/products/data/datasources/firestore_product_remote_search_data_source.dart`
- `lib/features/products/data/datasources/product_local_search_index_data_source.dart`
- `lib/features/products/data/datasources/drift_product_local_search_index_data_source.dart`
- `lib/features/products/data/mappers/product_search_index_mapper.dart`
- `lib/features/products/data/repositories/product_search_repository_impl.dart`
- `lib/features/products/presentation/bloc/product_search_event.dart`
- `lib/features/products/presentation/bloc/product_search_state.dart`
- `lib/features/products/presentation/bloc/product_search_bloc.dart`
- `lib/features/products/presentation/pages/product_search_page.dart`
- Testes novos em `test/features/products/...` para normalização, use case, repositório, Drift, BLoC e página.
- `test/features/products/product_factory.dart`

## Arquivos alterados

- `lib/core/database/app_database.dart` e `.g.dart`: schema `3`, tabela/métodos do índice local.
- `lib/core/database/database.dart`: export da nova tabela.
- `lib/features/products/data/dtos/product_dto.dart`: `searchText`/`searchPrefixes` no payload Firestore.
- `lib/features/products/products.dart`: exports da busca.
- `lib/app/injection.config.dart`: DI gerada para datasources, mapper, repositório, use case e BLoC.
- `firestore.rules`: leitura tenant-scoped de `products`; escrita cliente bloqueada.
- `firestore.indexes.json`: índice de `products` para `organizationId` + `deletedAt` + `searchPrefixes`.
- `firestore-tests/firestore.rules.test.js`: casos positivos/negativos de leitura/listagem de produtos.
- `test/core/database/app_database_test.dart` e `test/features/products/data/mappers/product_mapper_test.dart`.
- `docs/tasks/TASKS.md`: checkbox da task e progresso.

## Arquitetura utilizada

Clean Architecture feature-first: UI -> BLoC -> use case -> `ProductSearchRepository` -> datasources
Firestore/Drift. O domínio não importa Flutter/Firebase/Drift. O índice remoto é materializado no DTO
como `searchPrefixes`; o índice local é uma tabela Drift dedicada e tenant-scoped.

## Regras de negócio implementadas

- Busca por nome, SKU, referência, EAN e tags.
- Normalização de case, acentos e pontuação.
- Resultado sempre filtrado por `organizationId` e `deletedAt == null`.
- Resultado offline sinalizado como potencialmente desatualizado.
- Debounce de 350ms no BLoC e cancelamento/ignorância de resultados antigos via `restartable` + token.

## Regras Firebase implementadas

- `organizations/{organizationId}/products/{productId}` permite `get/list` apenas para membro ativo,
  com payload do produto pertencente ao mesmo tenant e não soft-deleted.
- `create/update/delete` seguem negados ao cliente.
- Índice Firestore criado para a query de busca por prefixo normalizado.

## Analytics implementado

Nenhum evento novo. A task expõe UI/BLoC de busca, mas não adicionou tracking para evitar evento
prematuro antes das telas finais de catálogo/pedido consumirem o componente.

## Crashlytics implementado

Nenhuma instrumentação nova. Falhas de Firestore/Drift são convertidas para `Failure` via o fluxo
central existente.

## Impacto offline

Adicionado índice offline Drift `product_search_index`, com replace/upsert/search por tenant. A
população incremental por sync geral continua pertencendo ao EPIC-14; a API local já está pronta para
ser chamada pelo sync quando ele existir.

## Impacto multi-tenant

Queries remotas e locais exigem `organizationId`; o repositório filtra novamente os produtos por
tenant como defesa em profundidade. Regras Firestore relêem Membership real e não confiam apenas no
campo do cliente.

## Testes criados

- Normalização de texto com acentos/case/pontuação e matching por campos.
- Use case: payload inválido, query vazia e delegação com origem/limite.
- Repositório: roteamento remoto/offline, isolamento tenant defensivo e equivalência remota/offline.
- Drift local: busca por campos, acentos e isolamento por organização.
- BLoC com `bloc_test`: debounce, cancelamento de busca anterior e resultado vazio.
- Widget da página: resultado offline com aviso de dado potencialmente desatualizado.
- Firestore Rules: leitura/listagem permitida, cross-tenant/deleted negados e escrita cliente negada.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
```

O primeiro `firebase emulators:exec` falhou por `spawn java ENOENT`; foi reexecutado com
`C:\Program Files\Android\Android Studio\jbr\bin` temporariamente no `PATH`.

## Resultado do formatter

Primeira execução formatou 14 arquivos. Execução final: `Formatted 1108 files (0 changed)`.

## Resultado do analyzer

Primeira execução apontou 3 infos de estilo, corrigidas. Execução final: `No issues found!`.

## Resultado dos testes

- `flutter test`: `All tests passed!` (`+1503`).
- Firestore Rules com emulator: `76 passed, 76 total`.

## Decisões técnicas

- Firestore usa índice de prefixos (`searchPrefixes`) porque não há full-text nativo.
- Drift recebeu um índice de busca estreito, não a tabela completa de sync de produtos do EPIC-14.
- A UI alterna origem Online/Offline em vez de mascarar dado local como remoto atualizado.
- O repositório aplica filtro de tenant e soft-delete mesmo após datasources já escopados.

## Riscos conhecidos

- Documentos antigos no Firestore sem `searchPrefixes` não aparecem na busca remota até serem
  regravados/reindexados.
- O índice Drift precisa ser alimentado pelo sync de produtos quando o EPIC-14 entrar; nesta task ele
  fornece contrato, tabela e datasource.

## Pendências

- Backfill/reindex remoto de produtos já existentes.
- Integração do widget nas telas futuras de catálogo premium e pedido quando essas tasks existirem.
- Alimentação incremental do índice local pelo motor de sync.

## Evidências

- `flutter analyze`: sem issues.
- `flutter test`: suíte completa passando.
- Firestore Rules emulator: suíte Jest passando com os casos novos de produtos.

## Commit

`feat(products): implement global product search`

## Push

A realizar após commit conforme fluxo autorizado da skill.

## Hash do commit

A definir após commit.

## Branch

main
