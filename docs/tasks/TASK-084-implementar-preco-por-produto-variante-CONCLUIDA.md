# TASK-084 — Concluída (2026-08-27)

## Resumo
Implementado suporte a preço-base por produto e exceção por variante dentro da Price List, com fallback único `variante -> produto -> sem preço definido`, persistência offline em Drift, tela administrativa de cadastro em lote e bloqueio explícito de pedido quando não houver preço resolvido.

## Agentes utilizados
- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-commercial-ops-strategist`

## Arquivos criados
- `lib/core/database/tables/price_list_items_table.dart`
- `lib/features/pricing/domain/entities/price_list_item.dart`
- `lib/features/pricing/domain/entities/resolved_variant_price.dart`
- `lib/features/pricing/domain/repositories/price_list_item_repository.dart`
- `lib/features/pricing/domain/repositories/price_list_item_local_store_repository.dart`
- `lib/features/pricing/data/mappers/price_list_item_local_mapper.dart`
- `lib/features/pricing/data/repositories/shared_preferences_price_list_item_repository.dart`
- `lib/features/pricing/data/repositories/drift_price_list_item_local_store_repository.dart`
- `lib/features/pricing/domain/usecases/upsert_price_list_items_batch_use_case.dart`
- `lib/features/pricing/domain/usecases/resolve_price_for_variant_use_case.dart`
- `lib/features/pricing/presentation/cubit/price_list_item_batch_state.dart`
- `lib/features/pricing/presentation/cubit/price_list_item_batch_cubit.dart`
- `lib/features/pricing/presentation/pages/price_list_item_batch_page.dart`
- `test/features/pricing/domain/usecases/resolve_price_for_variant_use_case_test.dart`
- `test/features/pricing/domain/usecases/upsert_price_list_items_batch_use_case_test.dart`
- `test/features/pricing/data/repositories/drift_price_list_item_local_store_repository_test.dart`

## Arquivos alterados
- `lib/app/injection.config.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/database.dart`
- `lib/features/pricing/pricing.dart`
- `lib/features/catalog/presentation/bloc/product_detail_bloc.dart`
- `lib/features/catalog/presentation/bloc/product_detail_state.dart`
- `lib/features/catalog/presentation/bloc/product_grid_bloc.dart`
- `lib/features/catalog/presentation/bloc/product_grid_state.dart`
- `lib/features/catalog/presentation/pages/product_detail_page.dart`
- `lib/features/catalog/presentation/pages/product_grid_page.dart`
- `test/core/database/app_database_test.dart`
- `test/features/catalog/presentation/bloc/product_detail_bloc_test.dart`
- `test/features/catalog/presentation/pages/product_detail_page_test.dart`

## Arquitetura utilizada
Clean Architecture por feature, com contratos de repositório no domínio, casos de uso para resolução/upsert, persistência remota mockada em SharedPreferences, cache offline em Drift e integração na UI via BLoC/Cubit.

## Regras de negócio implementadas
- Fallback único e explícito: item específico de variante -> item do produto na mesma Price List -> ausência explícita de preço.
- Variante sem preço resolvido na tabela ativa não aceita digitação nem adição ao pedido.
- Cadastro em lote exige confirmação para sobrescrever preço existente.
- Exceção de variante é preservada para auditoria via `ResolvedVariantPrice.origin`.

## Regras Firebase implementadas
Nenhuma nesta task.

## Analytics implementado
- Mantido `product_viewed`.
- Mantido `product_added_to_order`, agora coerente com o bloqueio por ausência de preço.

## Crashlytics implementado
Nenhuma alteração nesta task.

## Impacto offline
`PriceListItem` passa a ser persistido localmente em Drift, permitindo resolução de preço do catálogo com dados locais salvos.

## Impacto multi-tenant
Todos os itens e consultas permanecem escopados por `organizationId` e `companyId`.

## Testes criados
- Cobertura do `ResolvePriceForVariantUseCase` para preço por variante, fallback por produto, ausência de preço e precedência entre tabelas aplicáveis.
- Cobertura do `UpsertPriceListItemsBatchUseCase` para criação, sobrescrita confirmada e bloqueio sem confirmação.
- Cobertura do repositório Drift de `PriceListItem`.
- Ajustes/expansões nos testes de detalhe do produto e banco local para o novo contrato de preço.

## Comandos executados
- `dart run build_runner build`
- `dart format test/core/database/app_database_test.dart test/features/catalog/presentation/bloc/product_detail_bloc_test.dart test/features/catalog/presentation/pages/product_detail_page_test.dart`
- `flutter test test/core/database/app_database_test.dart test/features/catalog/presentation/bloc/product_detail_bloc_test.dart test/features/catalog/presentation/pages/product_detail_page_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
Sucesso.

## Resultado do analyzer
Sucesso (`No issues found!`).

## Resultado dos testes
Sucesso (`All tests passed!`).

## Decisões técnicas
- Persistência offline modelada em tabela própria `price_list_items` no Drift.
- Resolução de preço encapsulada em caso de uso para impedir lógica de fallback em widget.
- UI de catálogo passa a exibir “Sem preço definido na tabela ativa” em vez de assumir preço zero/nulo.

## Riscos conhecidos
- `flutter test` continua exibindo logs de debug de `active_organization_guard`, herdados de trabalho anterior e fora do escopo desta task.
- O ambiente de geração de código ainda emite um aviso pré-existente sobre `ImageUploadCompressor`/`ImageCompressor`, sem impacto no analyzer/test desta task.

## Pendências
Nenhuma pendência funcional identificada dentro do escopo da task.

## Evidências
- `dart format --set-exit-if-changed .` concluído sem alterações pendentes.
- `flutter analyze` concluído sem issues.
- `flutter test` concluído com `All tests passed!`.

## Commit
Pendente no momento da documentação.

## Push
Não autorizado nesta conversa.

## Hash do commit
Pendente no momento da documentação.

## Branch
`main`
