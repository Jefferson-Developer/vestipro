# TASK-071 — Concluída (2026-08-25)

## Resumo
Implementados templates de grade de tamanho reutilizáveis por organização, com tamanhos ordenados por score explícito, CRUD administrativo, duplicação, reordenação, associação do produto por `sizeGridTemplateId` e proteção para alterações/remocões com impacto.

## Agentes utilizados
- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`

## Arquivos criados
- `lib/features/products/domain/entities/size_grid_template.dart`
- `lib/features/products/domain/repositories/size_grid_template_repository.dart`
- `lib/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart`
- `lib/features/products/domain/usecases/size_grid_template_use_case_helpers.dart`
- `lib/features/products/domain/usecases/create_size_grid_template_use_case.dart`
- `lib/features/products/domain/usecases/update_size_grid_template_use_case.dart`
- `lib/features/products/domain/usecases/list_size_grid_templates_use_case.dart`
- `lib/features/products/domain/usecases/duplicate_size_grid_template_use_case.dart`
- `lib/features/products/domain/usecases/reorder_size_grid_template_sizes_use_case.dart`
- `lib/features/products/domain/usecases/associate_product_size_grid_template_use_case.dart`
- `lib/features/products/presentation/bloc/size_grid_template_bloc.dart`
- `lib/features/products/presentation/bloc/size_grid_template_event.dart`
- `lib/features/products/presentation/bloc/size_grid_template_state.dart`
- `lib/features/products/presentation/pages/size_grid_templates_page.dart`
- `test/features/products/domain/usecases/size_grid_template_use_cases_test.dart`
- `test/features/products/presentation/bloc/size_grid_template_bloc_test.dart`
- `test/features/products/presentation/pages/size_grid_templates_page_test.dart`

## Arquivos alterados
- `lib/app/injection.config.dart`
- `lib/features/products/domain/entities/product.dart`
- `lib/features/products/domain/entities/product.freezed.dart`
- `lib/features/products/domain/entities/product_form_draft.dart`
- `lib/features/products/data/dtos/product_dto.dart`
- `lib/features/products/data/dtos/product_form_draft_dto.dart`
- `lib/features/products/data/mappers/product_mapper.dart`
- `lib/features/products/data/mappers/product_form_draft_mapper.dart`
- `lib/features/products/data/repositories/shared_preferences_product_repository.dart`
- `lib/features/products/domain/usecases/create_product_use_case.dart`
- `lib/features/products/domain/usecases/update_product_use_case.dart`
- `lib/features/products/presentation/bloc/product_form_bloc.dart`
- `lib/features/products/presentation/bloc/product_form_event.dart`
- `lib/features/products/presentation/bloc/product_form_state.dart`
- `lib/features/products/presentation/pages/product_form_page.dart`
- `lib/features/products/products.dart`
- `test/features/products/presentation/bloc/product_form_bloc_test.dart`
- `test/features/products/presentation/pages/product_form_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first em `features/products`: domínio com entidade, contrato de repositório e use cases; data com persistência local temporária em SharedPreferences; presentation com BLoC e página administrativa. A UI não acessa persistência diretamente.

## Regras de negócio implementadas
- Template pertence a uma única organização.
- Nome de template é único por organização.
- Tamanhos têm `label`, `organizationId` e `orderScore` explícito.
- Produtos apontam para um template reutilizável por `sizeGridTemplateId`, sem copiar tamanhos.
- Duplicação cria novo template e novos ids de tamanho.
- Reordenação persiste score comercial explícito.
- Alterar tamanhos/ordem de template usado por produtos publicados exige confirmação.
- Remover tamanho com uso por variantes geradas exige confirmação específica.

## Regras Firebase implementadas
Sem alteração em Firestore Rules, Storage Rules ou Cloud Functions nesta task. A persistência segue o padrão local temporário das tasks de produtos até evolução de backend/sync.

## Analytics implementado
Não foram adicionados novos eventos. Fluxos de criação/atualização de produto preservam analytics existentes.

## Crashlytics implementado
Sem alteração específica. Erros de domínio/data retornam `Failure` para tratamento pelos BLoCs.

## Impacto offline
Templates são persistidos localmente via SharedPreferences com `ProductSyncStatus.pending`, mantendo operação administrativa local antes da camada definitiva de outbox/sync.

## Impacto multi-tenant
Todas as operações são escopadas por `organizationId`. Testes cobrem unicidade por organização e permitem nomes iguais em tenants diferentes.

## Testes criados
- Testes de use cases para CRUD, unicidade por organização, reordenação e bloqueio/confirmação de remoção de tamanho usado por variantes.
- Teste de BLoC para criar, duplicar e reordenar templates.
- Teste de widget da página administrativa cobrindo criação, duplicação e reordenação.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format lib\features\products test\features\products`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test\features\products\domain\usecases\size_grid_template_use_cases_test.dart test\features\products\presentation\bloc\size_grid_template_bloc_test.dart test\features\products\presentation\pages\size_grid_templates_page_test.dart`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 1144 files, 0 changed.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
`flutter test` passou: 1516 testes, All tests passed.

## Decisões técnicas
- Usar `SizeGridTemplate` e `SizeGridSize` para evitar conflito com `dart:ui Size`/Flutter `Size` na UI.
- Guardar `sizeGridTemplateId` no produto e no draft para preservar a grade durante edição incompleta.
- Preparar índice local `size_grid_variant_usage_<organizationId>` para a TASK-072 registrar uso real de variantes sem mudar o contrato de proteção.
- Usar confirmação por `ConflictFailure` com códigos específicos consumidos pelo BLoC.

## Riscos conhecidos
- Backend/rules definitivos ainda não foram implementados para templates de grade.
- O índice de uso por variantes é local/preparatório até a geração real de variantes na TASK-072.

## Pendências
Nenhuma pendência bloqueante para a TASK-071.

## Evidências
- Analyzer completo sem issues.
- Suíte completa `flutter test` aprovada.
- Testes novos cobrem CRUD, unicidade, reordenação, confirmação de remoção usada e UI administrativa.

## Commit
Local, a ser preenchido após o commit.

## Push
Não realizado, conforme instrução do usuário.

## Hash do commit
A ser preenchido após o commit.

## Branch
main
