# TASK-070 — Concluída (2026-08-25)

## Resumo
Implementado cadastro administrativo de paleta de cores reutilizável por organização, com entidade de domínio, validação de HEX/EAN, sugestão de duplicidade por nome normalizado/hex próximo, persistência local temporária via SharedPreferences, BLoC, tela administrativa com swatch e associação N:N de cores em Product por `colorIds`.

## Agentes utilizados
- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados
- `lib/features/products/domain/entities/product_color.dart`
- `lib/features/products/domain/value_objects/hex_color.dart`
- `lib/features/products/domain/value_objects/product_color_status.dart`
- `lib/features/products/domain/services/product_color_similarity_service.dart`
- `lib/features/products/domain/repositories/product_color_repository.dart`
- `lib/features/products/domain/usecases/create_product_color_use_case.dart`
- `lib/features/products/domain/usecases/update_product_color_use_case.dart`
- `lib/features/products/domain/usecases/list_product_colors_use_case.dart`
- `lib/features/products/domain/usecases/mark_product_color_unavailable_use_case.dart`
- `lib/features/products/domain/usecases/associate_product_colors_use_case.dart`
- `lib/features/products/data/repositories/shared_preferences_product_color_repository.dart`
- `lib/features/products/presentation/bloc/product_color_palette_bloc.dart`
- `lib/features/products/presentation/bloc/product_color_palette_event.dart`
- `lib/features/products/presentation/bloc/product_color_palette_state.dart`
- `lib/features/products/presentation/pages/product_color_palette_page.dart`
- `test/features/products/data/repositories/shared_preferences_product_color_repository_test.dart`
- `test/features/products/domain/services/product_color_similarity_service_test.dart`
- `test/features/products/presentation/bloc/product_color_palette_bloc_test.dart`
- `test/features/products/presentation/pages/product_color_palette_page_test.dart`

## Arquivos alterados
- `lib/app/injection.config.dart`
- `lib/features/products/domain/entities/product.dart`
- `lib/features/products/domain/entities/product.freezed.dart`
- `lib/features/products/data/dtos/product_dto.dart`
- `lib/features/products/data/mappers/product_mapper.dart`
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
Clean Architecture feature-first em `features/products`: domain com entidade/value objects/serviços/use cases/contrato de repositório; data com implementação local; presentation com BLoC e página. UI não acessa SharedPreferences/Firebase/Storage diretamente.

## Regras de negócio implementadas
- Paleta de cores reutilizável por organização.
- Criação/edição de cor com código, nome, HEX/RGB derivado, imagem principal, imagens adicionais, EANs e disponibilidade.
- Sugestão obrigatória de possível duplicidade por nome normalizado ou hex próximo, com confirmação explícita.
- Indisponibilidade sinalizada sem remover associações existentes.
- EAN de cor validado com o value object `Ean` e unicidade local por organização.
- Associação N:N produto-cor via `Product.colorIds`.

## Regras Firebase implementadas
Não houve alteração em Firestore Rules/Storage Rules nesta task. Persistência segue o padrão local temporário via SharedPreferences até implementação remota/outbox.

## Analytics implementado
Não foram adicionados novos eventos. Fluxos de produto existentes preservados.

## Crashlytics implementado
Sem alteração específica; erros continuam retornando `Failure` para tratamento pelos BLoCs.

## Impacto offline
Cadastro de cores persistido localmente via SharedPreferences com `ProductSyncStatus.pending`, seguindo padrão offline temporário usado em produtos/coleções antes do outbox.

## Impacto multi-tenant
Repositório e use cases escopam operações por `organizationId`. Teste cobre isolamento de paletas e EANs entre organizações.

## Testes criados
- Unitários do algoritmo de cor equivalente por nome normalizado e hex próximo.
- Testes de BLoC para criar, editar e marcar cor como indisponível.
- Teste de widget da tela de paleta/swatch.
- Teste de repositório cobrindo isolamento multi-tenant e unicidade de EAN por organização.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format .`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test/features/products/presentation/pages/product_color_palette_page_test.dart`
- `flutter test test/features/products/presentation/bloc/product_color_palette_bloc_test.dart`
- `flutter test test/features/products/domain/services/product_color_similarity_service_test.dart`
- `flutter test`
- Tentativas não finais: `flutter test integration_test/features/products/product_color_tenant_isolation_test.dart`, `flutter test integration_test/features/products/product_color_tenant_isolation_test.dart -d windows`, `flutter test integration_test/features/products/product_color_tenant_isolation_test.dart -d chrome`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 1127 files, 0 changed.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
`flutter test` passou: 1511 testes, All tests passed.

O teste inicialmente criado em `integration_test` não pôde ser executado por limitação de device do ambiente/projeto (Windows desktop não configurado; web não suportado para integration_test). A cobertura foi movida para `test/features/products/data/repositories/shared_preferences_product_color_repository_test.dart`, executada e aprovada dentro de `flutter test`.

## Decisões técnicas
- Usar `ProductColor` para evitar colisão com `dart:ui Color` e manter semântica de domínio.
- Guardar associação N:N no produto como `colorIds`, sem duplicar dados da cor no produto.
- Usar SharedPreferences como persistência local provisória, coerente com tasks anteriores de produtos.
- Implementar confirmação de duplicidade como `ConflictFailure` com código específico consumido pelo BLoC.

## Riscos conhecidos
- Sem backend/rules específicas ainda; segurança remota deverá ser reforçada quando a paleta migrar para Firestore/Functions.
- Upload real de imagem da cor ainda representado por URL/campo local; integração Storage completa pode evoluir em task futura.

## Pendências
Nenhuma pendência bloqueante para a TASK-070.

## Evidências
- Formatter, analyzer e suíte completa executados com sucesso.
- Testes novos cobrem similaridade, CRUD via BLoC, UI de paleta e isolamento multi-tenant.

## Commit
Local, a ser preenchido após o commit.

## Push
Não realizado, conforme instrução do usuário.

## Hash do commit
A ser preenchido após o commit.

## Branch
main
