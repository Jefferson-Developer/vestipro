# TASK-074 - Concluida (2026-08-25)

## Resumo
Implementado o contrato central `VariantAvailability` para disponibilidade por variante, com estados pronta entrega, estoque futuro e indisponivel, quantidade opcional e data prevista opcional. A fonte inicial usa metadados manuais em `ProductVariant`, preparada para ser substituida pelo saldo real da TASK-090 sem retrabalho de UI.

## Agentes utilizados
- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`

## Arquivos criados
- `lib/features/products/domain/value_objects/variant_availability_status.dart`
- `lib/features/products/domain/entities/variant_availability.dart`
- `lib/features/products/domain/entities/variant_availability_snapshot.dart`
- `lib/features/products/domain/repositories/variant_availability_repository.dart`
- `lib/features/products/domain/usecases/get_variant_availability_use_case.dart`
- `lib/features/products/data/repositories/product_variant_availability_repository.dart`
- `test/features/products/domain/entities/variant_availability_test.dart`
- `test/features/products/domain/usecases/get_variant_availability_use_case_test.dart`
- `test/features/products/presentation/widgets/variant_availability_contract_widget_test.dart`

## Arquivos alterados
- `firestore.rules`
- `lib/app/injection.config.dart`
- `lib/core/design_system/components/catalog/app_product_grid.dart`
- `lib/core/design_system/components/catalog/app_size_grid.dart`
- `lib/features/products/data/dtos/product_variant_dto.dart`
- `lib/features/products/data/mappers/product_variant_mapper.dart`
- `lib/features/products/data/repositories/shared_preferences_product_variant_repository.dart`
- `lib/features/products/domain/entities/product_variant.dart`
- `lib/features/products/domain/usecases/update_product_variant_use_case.dart`
- `lib/features/products/domain/value_objects/commercial_variant_availability.dart`
- `lib/features/products/presentation/bloc/commercial_size_grid_bloc.dart`
- `lib/features/products/presentation/bloc/commercial_size_grid_event.dart`
- `lib/features/products/presentation/bloc/commercial_size_grid_state.dart`
- `lib/features/products/presentation/bloc/product_search_bloc.dart`
- `lib/features/products/presentation/bloc/product_search_state.dart`
- `lib/features/products/presentation/pages/product_search_page.dart`
- `lib/features/products/presentation/widgets/commercial_size_grid.dart`
- `lib/features/products/products.dart`
- `test/features/products/data/mappers/product_variant_mapper_test.dart`
- `test/features/products/presentation/bloc/commercial_size_grid_bloc_test.dart`
- `test/features/products/presentation/bloc/product_search_bloc_test.dart`
- `test/features/products/presentation/pages/product_search_page_test.dart`
- `test/features/products/presentation/widgets/commercial_size_grid_golden_test.dart`
- `test/features/products/presentation/widgets/commercial_size_grid_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first em `features/products`: dominio com contrato estavel, snapshot e use case; data com reposititorio inicial baseado em `ProductVariant`; presentation com BLoCs consumindo `GetVariantAvailabilityUseCase`; componentes do design system apenas renderizam labels/status resolvidos.

## Regras de negocio implementadas
- Disponibilidade e representada por variante, nao por produto isolado.
- Estados suportados: `readyStock`, `futureStock` e `unavailable`.
- Variante inativa e sempre tratada como indisponivel.
- Ausencia de dado manual em variante ativa cai para pronta entrega, preservando o comportamento atual ate a TASK-090.
- Estoque futuro pode carregar data prevista e quantidade disponivel opcional.
- Variante indisponivel permanece visivel na grade, mas nao aceita quantidade.
- Catalogo e grade comercial consomem o mesmo contrato central.

## Regras Firebase implementadas
`firestore.rules` passou a aceitar e validar os campos opcionais `manualAvailabilityStatus`, `manualAvailableQuantity` e `manualFutureAvailableAt` em `productVariants`, mantendo RBAC `catalog.manage`, tenant pelo path e delete fisico negado.

## Analytics implementado
Nao foram adicionados novos eventos. A task altera contrato/renderizacao de disponibilidade e preserva fluxos existentes.

## Crashlytics implementado
Sem alteracao especifica. Falhas de disponibilidade retornam `Failure` tipado para os BLoCs.

## Impacto offline
A fonte inicial e offline-first: metadados manuais de disponibilidade sao persistidos no reposititorio local de variantes em SharedPreferences. O contrato pode trocar para saldo real remoto/local na TASK-090 sem alterar UI.

## Impacto multi-tenant
Consultas e persistencia seguem escopadas por `organizationId`; Firestore Rules validam `organizationId` pelo path e os BLoCs consultam disponibilidade usando a organizacao ativa do produto/busca.

## Testes criados
- Contrato `VariantAvailability` cobrindo pronta entrega, futuro com data/quantidade e indisponivel.
- Snapshot de disponibilidade por produto e variante.
- Use case com fonte simplificada cobrindo tres estados, ausencia de dado e contrato substituivel pela TASK-090.
- Widget de regressao garantindo que catalogo e grade exibem a mesma disponibilidade para a mesma variante.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test test\features\products\domain\entities\variant_availability_test.dart test\features\products\domain\usecases\get_variant_availability_use_case_test.dart test\features\products\data\mappers\product_variant_mapper_test.dart test\features\products\presentation\bloc\commercial_size_grid_bloc_test.dart test\features\products\presentation\bloc\product_search_bloc_test.dart test\features\products\presentation\pages\product_search_page_test.dart test\features\products\presentation\widgets\commercial_size_grid_test.dart test\features\products\presentation\widgets\variant_availability_contract_widget_test.dart`
- `flutter test test\features\products\presentation\widgets\commercial_size_grid_golden_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `$env:PATH='C:\Program Files\Android\Android Studio\jbr\bin;' + $env:PATH; firebase emulators:exec --only firestore "echo rules-ok"`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 1181 files, 0 changed.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
`flutter test` passou: 1542 testes, All tests passed.

O Firestore Emulator carregou `firestore.rules` com sucesso e executou `rules-ok`. Testes funcionais positivos/negativos de rules seguem limitados pelo mesmo runner de `integration_test` indisponivel neste ambiente; a regra foi validada ao menos por carregamento no Emulator.

## Decisoes tecnicas
- Usar `VariantAvailabilityStatus` como enum central e manter `CommercialVariantAvailability` como typedef deprecated para compatibilidade.
- Guardar disponibilidade manual opcional em `ProductVariant`, sem criar regra de estoque definitiva antes da TASK-090.
- Criar `VariantAvailabilityRepository` para permitir troca da fonte por saldo real sem mudar BLoCs ou widgets.
- Fazer o catalogo resumir disponibilidade por produto via snapshot, priorizando pronta entrega, depois estoque futuro, depois indisponivel.

## Riscos conhecidos
- A fonte manual ainda nao e saldo real de estoque; TASK-090 deve substituir o reposititorio.
- Campo manual de disponibilidade ainda nao tem tela administrativa dedicada; esta task modela contrato e consumo.
- Rules tiveram carregamento validado em Emulator, mas os testes de integration runner permanecem pendentes pelo ambiente.

## Pendencias
Executar testes de rules/integration completos quando houver runner Flutter compatível disponivel para `integration_test`.

## Evidencias
- Testes focados de dominio, use case, mapper, BLoCs e widgets passaram.
- Goldens de grade comercial continuam estaveis.
- Suite completa `flutter test` aprovada com 1542 testes.
- Firestore Emulator carregou rules com os novos campos opcionais.

## Commit
Local, a ser preenchido apos o commit.

## Push
Nao realizado, conforme instrucao do usuario.

## Hash do commit
A ser preenchido apos o commit.

## Branch
main
