# TASK-043 — Concluída (2026-08-23)

## Resumo
Implementada a gestão de perfis e permissões com bottom sheet Flutter, BLoC, use case, repository/data source via Cloud Function e validação backend transacional. A alteração de role é autorizada por RBAC server-side, bloqueia a remoção do último OWNER ativo e grava exatamente um audit log central por sucesso.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist

## Arquivos criados
- `functions/src/admin/update-user-role.ts`
- `functions/test/admin/update-user-role.test.ts`
- `lib/features/users/data/datasources/cloud_functions_user_role_data_source.dart`
- `lib/features/users/data/datasources/user_role_data_source.dart`
- `lib/features/users/data/dtos/user_role_update_result_dto.dart`
- `lib/features/users/data/mappers/user_role_update_result_mapper.dart`
- `lib/features/users/data/repositories/user_role_repository_impl.dart`
- `lib/features/users/domain/entities/user_role_update_result.dart`
- `lib/features/users/domain/repositories/user_role_repository.dart`
- `lib/features/users/domain/usecases/update_user_role_use_case.dart`
- `lib/features/users/domain/user_role_change_policy.dart`
- `lib/features/users/presentation/bloc/user_role_edit_bloc.dart`
- `lib/features/users/presentation/bloc/user_role_edit_event.dart`
- `lib/features/users/presentation/bloc/user_role_edit_event.freezed.dart`
- `lib/features/users/presentation/bloc/user_role_edit_state.dart`
- `lib/features/users/presentation/bloc/user_role_edit_state.freezed.dart`
- `lib/features/users/presentation/pages/user_role_edit_page.dart`
- `test/features/users/data/datasources/cloud_functions_user_role_data_source_test.dart`
- `test/features/users/data/repositories/user_role_repository_impl_test.dart`
- `test/features/users/domain/usecases/update_user_role_use_case_test.dart`
- `test/features/users/domain/user_role_change_policy_test.dart`
- `test/features/users/presentation/bloc/user_role_edit_bloc_test.dart`
- `test/features/users/presentation/pages/user_role_edit_page_test.dart`

## Arquivos alterados
- `functions/src/admin/index.ts`
- `functions/src/index.ts`
- `lib/app/injection.config.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/core/functions/cloud_functions_exception_mapper.dart`
- `lib/features/users/presentation/pages/user_list_page.dart`
- `lib/features/users/users.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/core/functions/cloud_functions_exception_mapper_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first: Presentation (`UserRoleEditPage` + BLoC) -> Use case (`UpdateUserRoleUseCase`) -> Repository contract -> Repository impl -> Cloud Functions data source. A UI não acessa Firestore/Storage/Drift diretamente.

## Regras de negócio implementadas
- OWNER pode atribuir qualquer role de sistema.
- ADMIN pode atribuir ADMIN ou abaixo, nunca OWNER.
- ADMIN não edita usuário com role mais privilegiada que a sua.
- Usuário não consegue autopromover a própria role para nível superior.
- Alterações sensíveis exibem confirmação: rebaixar OWNER ou promover para ADMIN/OWNER.
- Seleção de role na UI é limitada às roles atribuíveis pelo usuário logado.
- Mudança para a mesma role é bloqueada no backend.
- Operação bloqueada com mensagem clara quando deixaria a organização sem OWNER ativo.

## Regras Firebase implementadas
Criada Cloud Function callable `updateUserRole`, exportada em `functions/src/index.ts`, com validação via Admin SDK em transação Firestore: solicitante ativo, role de destino válida, hierarquia RBAC, alvo existente e bloqueio do último OWNER ativo.

## Analytics implementado
Adicionado evento `user_role_updated` sem PII, com parâmetros `previous_role` e `new_role`.

## Crashlytics implementado
Não houve integração específica nova. Falhas seguem o fluxo existente de exceptions/failures e UI feedback.

## Impacto offline
Alteração de role é operação administrativa online via Cloud Function. Não altera sync/offline existente.

## Impacto multi-tenant
Todas as operações exigem `organizationId`, leem Memberships dentro de `organizations/{organizationId}` e nunca confiam em role/tenant enviados pelo cliente para autorização.

## Testes criados
- Functions: sucesso auditado, último OWNER bloqueado, solicitante sem permissão, autopromoção indevida, role desconhecida.
- Flutter data/repository/use case: payload, parse e falhas.
- BLoC: opções atribuíveis, ADMIN contra OWNER, sucesso com analytics e falha último OWNER.
- Widget: seletor restrito, confirmação sensível e snackbar do último OWNER.
- Policy: confirmação sensível para OWNER/ADMIN.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format .`
- `npm run build` em `functions`
- `npm run lint` em `functions`
- `firebase emulators:exec --only firestore "npm --prefix functions test -- --runInBand update-user-role"` com PATH temporário incluindo `C:\Program Files\Android\Android Studio\jbr\bin`
- `flutter test test/features/users test/core/functions/cloud_functions_exception_mapper_test.dart test/core/analytics/analytics_events_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 607 arquivos, 0 alterados.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
- Functions targeted: 5 testes passaram.
- Flutter targeted: 60 testes passaram.
- `flutter test`: 1009 testes passaram.

## Decisões técnicas
- A role update administrativa ficou em Cloud Function, não no antigo `MembershipRepository.update`, para garantir RBAC, último OWNER e auditoria server-side.
- `failed-precondition` agora preserva a mensagem server-side para permitir UX clara no bloqueio do último OWNER.
- O bottom sheet foi plugado opcionalmente em `UserListPage` via `createRoleEditBloc`, preservando `onManageUser` como override.
- A auditoria server-side usa action `user.roleUpdated`, entity `membership`, `targetUserId`, `previousValue.roleName` e `newValue.roleName`.

## Riscos conhecidos
- Warnings do Firebase Emulator sobre `flutter` em `firebase.json` e múltiplos projectIds em single project mode já existem no ambiente de teste; não impediram a suíte.
- Operação administrativa depende de conectividade/Functions, sem fila offline.

## Pendências
Nenhuma pendência funcional para a TASK-043.

## Evidências
- Function test: `PASS test/admin/update-user-role.test.ts`, 5/5.
- Formatter: 0 arquivos alterados.
- Analyzer: sem issues.
- Flutter full test: 1009/1009.

## Commit
Pendente no momento de criação deste documento.

## Push
Pendente no momento de criação deste documento.

## Hash do commit
Pendente no momento de criação deste documento.

## Branch
main
