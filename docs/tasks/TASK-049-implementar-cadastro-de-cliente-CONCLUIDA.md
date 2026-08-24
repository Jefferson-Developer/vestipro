# TASK-049 — Concluída (2026-08-24)

## Resumo
Implementado o fluxo de cadastro/edição de cliente com `CustomerFormPage`, `CustomerFormBloc`, validação imediata de CPF/CNPJ, alternância PJ/PF, campos obrigatórios configuráveis por organização, RBAC para criação/edição e seleção de vendedor responsável, rascunho local persistente e criação local com `syncStatus.pending`.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- vestipro-sales-representative-specialist

## Arquivos criados
- `lib/features/customers/data/datasources/customer_form_draft_data_source.dart`
- `lib/features/customers/data/datasources/shared_preferences_customer_form_draft_data_source.dart`
- `lib/features/customers/data/dtos/customer_form_draft_dto.dart`
- `lib/features/customers/data/mappers/customer_form_draft_mapper.dart`
- `lib/features/customers/data/repositories/customer_form_draft_repository_impl.dart`
- `lib/features/customers/data/repositories/shared_preferences_customer_repository.dart`
- `lib/features/customers/domain/entities/customer_form_config.dart`
- `lib/features/customers/domain/entities/customer_form_draft.dart`
- `lib/features/customers/domain/repositories/customer_form_draft_repository.dart`
- `lib/features/customers/domain/usecases/clear_customer_form_draft_use_case.dart`
- `lib/features/customers/domain/usecases/get_customer_form_config_use_case.dart`
- `lib/features/customers/domain/usecases/get_customer_form_draft_use_case.dart`
- `lib/features/customers/domain/usecases/save_customer_form_draft_use_case.dart`
- `lib/features/customers/domain/value_objects/customer_required_field.dart`
- `lib/features/customers/presentation/bloc/customer_form_bloc.dart`
- `lib/features/customers/presentation/bloc/customer_form_event.dart`
- `lib/features/customers/presentation/bloc/customer_form_state.dart`
- `lib/features/customers/presentation/pages/customer_form_page.dart`
- `test/features/customers/data/repositories/shared_preferences_customer_repository_test.dart`
- `test/features/customers/presentation/bloc/customer_form_bloc_test.dart`
- `test/features/customers/presentation/pages/customer_form_page_test.dart`
- `docs/tasks/TASK-049-implementar-cadastro-de-cliente-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md`
- `lib/app/bootstrap.dart`
- `lib/app/injection.config.dart`
- `lib/core/navigation/app_route_paths.dart`
- `lib/core/navigation/app_router.dart`
- `lib/features/customers/customers.dart`
- `lib/features/customers/domain/usecases/create_customer_use_case.dart`
- `lib/features/customers/domain/usecases/update_customer_use_case.dart`
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`
- `lib/features/organizations/data/mappers/organization_mapper.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.freezed.dart`
- `test/core/navigation/app_router_test.dart`

## Arquitetura utilizada
Clean Architecture feature-first com domain/data/presentation. A UI usa BLoC e Design System, sem acesso direto a Firestore/Storage/Drift. A persistência local temporária usa `SharedPreferences` por contrato de datasource/repository, deixando a troca futura por Drift/outbox isolada na camada data.

## Regras de negócio implementadas
- PJ exibe e exige CNPJ válido e razão social.
- PF exibe e exige CPF válido e nome completo.
- Campos extras obrigatórios vêm de `OrganizationSettings.requiredCustomerFields`.
- Documento duplicado na organização bloqueia a submissão com mensagem clara.
- Duplo submit é bloqueado enquanto a submissão está em andamento.
- Erros não limpam os dados digitados.
- Rascunho incompleto pode ser salvo e retomado por organização/usuário.
- Seleção de vendedor responsável aparece somente quando RBAC permite gestão de equipe.

## Regras Firebase implementadas
Não houve alteração em Firestore Rules ou Storage Rules. A rota é protegida por `Capability.customerCreate`; a validação definitiva backend/rules segue pendente para a persistência remota futura.

## Analytics implementado
Ao salvar cliente, o BLoC registra `AnalyticsEvents.customerCreated` com `organization_id`, `customer_id`, `customer_type` e `sync_status`, sem PII.

## Crashlytics implementado
Não aplicável. Falhas são propagadas por `AppResult`/`Failure` e exibidas na UI.

## Impacto offline
Clientes criados são persistidos localmente em `SharedPreferencesCustomerRepository` com `CustomerSyncStatus.pending`. Rascunhos também são persistidos localmente para retomada após fechar o app.

## Impacto multi-tenant
Rascunhos são escopados por `organizationId` e `userId`; clientes locais são armazenados por `organizationId`; a rota e a página recebem `organizationId`/`companyId` e aplicam RBAC com `PermissionService`.

## Testes criados
- BLoC: submissão válida, documento inválido, documento duplicado, rascunho salvo/retomado e obrigatórios configuráveis.
- Widget: formulário PJ, formulário PF, alternância de tipo, obrigatórios configuráveis, RBAC de vendedor responsável, labels semânticas e foco no primeiro erro.
- Data: criação local pendente de sync e bloqueio de duplicidade no cache da organização.
- Navegação: rota de cadastro protegida por `customer.create`.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format --set-exit-if-changed .`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
Primeira execução formatou `lib/main.dart` (alteração pré-existente fora do escopo) e retornou exit code 1 por mudança aplicada. Segunda execução: `Formatted 709 files (0 changed)` com exit code 0.

## Resultado do analyzer
`flutter analyze`: `No issues found!`

## Resultado dos testes
`flutter test`: 1092 testes passaram.

## Decisões técnicas
- Usado `SharedPreferences` como cache local temporário porque o schema Drift ainda não foi criado.
- `CustomerRepository` ganhou implementação local para permitir cadastro offline/pending sync sem antecipar Firestore/outbox.
- Use cases `CreateCustomerUseCase` e `UpdateCustomerUseCase` passaram a entrar no DI porque agora há implementação registrada de `CustomerRepository`.
- `OrganizationSettings.requiredCustomerFields` armazena códigos estáveis para manter a configuração desacoplada da UI.

## Riscos conhecidos
- A persistência local é provisória até as tasks de Drift/outbox/sync.
- A unicidade definitiva do documento ainda precisa ser reforçada no backend/regras remotas quando a persistência Firestore for implementada.

## Pendências
- Substituir ou complementar o cache local por Drift/outbox nas tasks de offline/sincronização.
- Implementar backend/rules definitivos para persistência remota e auditoria sensível.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1092/1092 testes passaram.
- Backlog atualizado para 49 / 220.

## Commit
`feat(customers): add customer form`

## Push
Não realizado por solicitação do lote (`sem push`).

## Hash do commit
Pendente no momento de criação deste documento; informado na resposta final da task.

## Branch
main
