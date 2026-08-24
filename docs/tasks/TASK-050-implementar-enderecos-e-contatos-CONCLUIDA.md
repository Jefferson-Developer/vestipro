# TASK-050 — Concluída (2026-08-24)

## Resumo
Implementado suporte a múltiplos endereços e contatos por cliente, com entidades imutáveis, validação de CEP, tipos padrão/customizados por organização, manutenção automática de item principal e edição inline no formulário de cliente.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- vestipro-sales-representative-specialist

## Arquivos criados
- `lib/features/customers/domain/customer_address_contact_rules.dart`
- `lib/features/customers/domain/entities/customer_address.dart`
- `lib/features/customers/domain/entities/customer_address.freezed.dart`
- `lib/features/customers/domain/entities/customer_contact.dart`
- `lib/features/customers/domain/entities/customer_contact.freezed.dart`
- `lib/features/customers/domain/usecases/customer_address_use_cases.dart`
- `lib/features/customers/domain/usecases/customer_contact_use_cases.dart`
- `lib/features/customers/domain/value_objects/cep.dart`
- `lib/features/customers/domain/value_objects/customer_address_type.dart`
- `lib/features/customers/domain/value_objects/customer_contact_type.dart`
- `test/features/customers/domain/usecases/customer_address_contact_use_cases_test.dart`
- `docs/tasks/TASK-050-implementar-enderecos-e-contatos-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md`
- `lib/app/injection.config.dart`
- `lib/features/customers/customers.dart`
- `lib/features/customers/data/dtos/customer_dto.dart`
- `lib/features/customers/data/dtos/customer_form_draft_dto.dart`
- `lib/features/customers/data/mappers/customer_form_draft_mapper.dart`
- `lib/features/customers/data/mappers/customer_mapper.dart`
- `lib/features/customers/data/repositories/shared_preferences_customer_repository.dart`
- `lib/features/customers/domain/entities/customer.dart`
- `lib/features/customers/domain/entities/customer.freezed.dart`
- `lib/features/customers/domain/entities/customer_form_config.dart`
- `lib/features/customers/domain/entities/customer_form_draft.dart`
- `lib/features/customers/domain/usecases/create_customer_use_case.dart`
- `lib/features/customers/domain/usecases/get_customer_form_config_use_case.dart`
- `lib/features/customers/domain/usecases/update_customer_use_case.dart`
- `lib/features/customers/presentation/bloc/customer_form_bloc.dart`
- `lib/features/customers/presentation/bloc/customer_form_event.dart`
- `lib/features/customers/presentation/bloc/customer_form_state.dart`
- `lib/features/customers/presentation/pages/customer_form_page.dart`
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`
- `lib/features/organizations/data/mappers/organization_mapper.dart`
- `lib/features/organizations/domain/usecases/update_organization_settings_use_case.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.freezed.dart`
- `test/features/customers/data/mappers/customer_mapper_test.dart`
- `test/features/customers/data/repositories/shared_preferences_customer_repository_test.dart`
- `test/features/customers/presentation/bloc/customer_form_bloc_test.dart`
- `test/features/customers/presentation/pages/customer_form_page_test.dart`

## Arquitetura utilizada
Clean Architecture feature-first com domain/data/presentation. A UI segue usando BLoC e Design System; serialização e persistência ficam na camada data, enquanto as regras de principal, normalização e validação ficam no domínio.

## Regras de negócio implementadas
- Cliente suporta múltiplos endereços e contatos.
- Quando há itens cadastrados, sempre existe exatamente um endereço principal e um contato principal.
- Ao adicionar o primeiro item, ele é promovido automaticamente a principal.
- Ao definir um item como principal, os demais são rebaixados.
- Ao remover o principal, o próximo item disponível é promovido automaticamente.
- CEP aceita somente 8 dígitos válidos e rejeita valores mal formatados.
- Campos essenciais de endereço continuam obrigatórios no domínio.
- Tipos padrão e tipos customizados por organização são expostos ao formulário.

## Regras Firebase implementadas
Não houve alteração em Firestore Rules, Storage Rules ou Cloud Functions. A persistência implementada nesta etapa permanece local e pendente de sincronização.

## Analytics implementado
Não foram criados novos eventos. O fluxo de salvamento segue usando o evento de criação de cliente já existente, sem PII.

## Crashlytics implementado
Não aplicável. Falhas continuam retornando por `AppResult`/`Failure` e sendo exibidas no fluxo da UI.

## Impacto offline
Endereços e contatos são serializados junto do cliente e do rascunho local em `SharedPreferences`, preservando dados para criação/edição offline com `CustomerSyncStatus.pending`.

## Impacto multi-tenant
Clientes continuam escopados por `organizationId` e `companyId`; rascunhos permanecem escopados por organização/usuário. Tipos customizados de endereço/contato entram via `OrganizationSettings`.

## Testes criados
- Use cases de endereço: adicionar, atualizar, remover e definir principal.
- Use cases de contato: adicionar, atualizar, remover e definir principal.
- Validação de CEP mal formatado.
- Widget: estados vazios de endereço/contato e fluxo inline de adicionar, editar e remover.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .`: `Formatted 720 files (0 changed)`.

## Resultado do analyzer
`flutter analyze`: `No issues found!`

## Resultado dos testes
`flutter test`: 1101 testes passaram.

## Decisões técnicas
- As regras de principal foram centralizadas em helpers de domínio para serem reutilizadas pelo formulário e pelos use cases.
- `OrganizationSettings` foi estendido com listas de tipos customizados para evitar hardcode na UI.
- Cidade/UF são preservadas como campos locais já existentes no formulário, sem acoplar a task a serviço externo síncrono.
- O cache local foi mantido em `SharedPreferences` por consistência com a TASK-049 até a chegada das tasks de Drift/outbox/sync.

## Riscos conhecidos
- A persistência remota e as garantias definitivas em Firebase ainda precisam ser implementadas nas tasks futuras de sincronização/backend.
- O preenchimento assistido de cidade/UF depende de dados já disponíveis localmente; não há integração com serviço de CEP nesta task.

## Pendências
- Complementar persistência remota, regras e auditoria quando o módulo de clientes sair do cache local provisório.
- Reaproveitar as novas seções no detalhe 360º da TASK-052.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1101/1101 testes passaram.
- Backlog atualizado para 50 / 220.

## Commit
`feat(customers): add customer addresses and contacts`

## Push
Não realizado por solicitação do lote (`sem push`).

## Hash do commit
Pendente no momento de criação deste documento; informado na resposta final da task.

## Branch
main
