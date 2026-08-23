# TASK-046 — Concluída (2026-08-23)

## Resumo
Implementada a desativação e reativação auditada de usuários da organização, preservando histórico de pedidos, CRM, carteira e auditoria. A UI de usuários agora confirma a ação, exibe status atualizado e chama Cloud Functions por use cases/repository, sem acesso direto a Firestore.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- vestipro-commercial-ops-strategist

## Arquivos criados
- `functions/src/admin/update-user-access.ts`
- `functions/test/admin/update-user-access.test.ts`
- `lib/features/users/domain/entities/user_access_update_result.dart`
- `lib/features/users/domain/repositories/user_access_repository.dart`
- `lib/features/users/domain/usecases/deactivate_user_use_case.dart`
- `lib/features/users/domain/usecases/reactivate_user_use_case.dart`
- `lib/features/users/data/dtos/user_access_update_result_dto.dart`
- `lib/features/users/data/mappers/user_access_update_result_mapper.dart`
- `lib/features/users/data/datasources/user_access_data_source.dart`
- `lib/features/users/data/datasources/cloud_functions_user_access_data_source.dart`
- `lib/features/users/data/repositories/user_access_repository_impl.dart`
- `test/features/users/domain/usecases/user_access_use_cases_test.dart`
- `test/features/users/data/datasources/cloud_functions_user_access_data_source_test.dart`
- `test/features/users/data/repositories/user_access_repository_impl_test.dart`
- `docs/tasks/TASK-046-implementar-desativacao-de-usuario-CONCLUIDA.md`

## Arquivos alterados
- `functions/src/admin/index.ts`
- `functions/src/index.ts`
- `functions/src/invites/invite-shared.ts`
- `lib/app/injection.config.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/core/auth/data/mappers/firebase_auth_exception_mapper.dart`
- `lib/core/design_system/components/tables/app_data_table.dart`
- `lib/features/users/users.dart`
- `lib/features/users/presentation/bloc/user_list_bloc.dart`
- `lib/features/users/presentation/bloc/user_list_event.dart`
- `lib/features/users/presentation/bloc/user_list_event.freezed.dart`
- `lib/features/users/presentation/bloc/user_list_state.dart`
- `lib/features/users/presentation/bloc/user_list_state.freezed.dart`
- `lib/features/users/presentation/pages/user_list_page.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/core/auth/data/mappers/firebase_auth_exception_mapper_test.dart`
- `test/features/users/presentation/bloc/user_list_bloc_test.dart`
- `test/features/users/presentation/pages/user_list_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first: `UserListPage` -> `UserListBloc` -> use cases -> repository -> Cloud Functions datasource. A regra sensível ficou no backend em callable Functions transacionais, com a UI apenas solicitando a mudança e refletindo o resultado.

## Regras de negócio implementadas
- `deactivateUser` marca `organizations/{organizationId}/members/{targetUserId}` como `inactive`, sem remover documento de usuário nem registros associados.
- `reactivateUser` restaura o vínculo para `active` de forma simétrica.
- Toda alteração incrementa `version`, atualiza auditoria do vínculo e registra audit log tenant-scoped.
- Usuário desativado tem refresh tokens revogados; quando não mantém outro membership ativo, o Auth user é desabilitado e recebe claim `vestiproAccessDisabled`.
- Reativação remove a claim de bloqueio criada pela VestiPro e reabilita o Auth user quando aplicável.
- A desativação do último `OWNER` ativo é bloqueada.
- Hierarquia OWNER/ADMIN é respeitada para impedir alteração de usuário mais privilegiado.

## Regras Firebase implementadas
Não houve alteração de Firestore Rules. A implementação usa Cloud Functions com Admin SDK, valida membership ativo do operador, RBAC e hierarquia no backend, e escreve audit logs em `organizations/{organizationId}/auditLogs`. A sessão aberta é invalidada por revogação de tokens e por bloqueio no próximo callable autenticado que exige membership ativo.

## Analytics implementado
Adicionados eventos sem PII `user_deactivated` e `user_reactivated`, emitidos após sucesso da alteração de acesso.

## Crashlytics implementado
Não houve integração específica nova. Erros seguem o fluxo existente de exceptions/failures, BLoC state e feedback por snackbar.

## Impacto offline
Não foi criada fila offline para mutações administrativas. Usuários já desativados deixam de executar ações autenticadas no próximo request online e têm sessão revogada por refresh token.

## Impacto multi-tenant
As operações são escopadas por `organizationId` e membership. O Auth user só é desabilitado globalmente quando não há outro membership ativo em qualquer organização, preservando acesso multi-tenant legítimo.

## Testes criados
- Testes de Cloud Function para desativação, preservação de histórico, audit log, bloqueio de próximo request autenticado, reativação, multi-org e bloqueio do último `OWNER`.
- Testes de use cases, datasource Cloud Functions e repository de acesso de usuário.
- Testes de BLoC para desativar, reativar e propagar falha do último `OWNER`.
- Testes de widget para diálogo de confirmação, preservação de histórico no texto, ação de reativação e status atualizado na listagem.
- Teste de mapper de Auth para a mensagem clara de acesso desativado.
- Teste de taxonomia Analytics com os novos eventos.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format .`
- `dart format --set-exit-if-changed .`
- `npm --prefix functions run build`
- `npm --prefix functions run lint`
- `flutter analyze`
- `flutter test test/features/users test/core/auth/data/mappers/firebase_auth_exception_mapper_test.dart test/core/analytics/analytics_events_test.dart`
- `flutter test`
- `npm test -- --runInBand update-user-access` em `functions`
- `firebase emulators:exec --only firestore "npm --prefix functions test -- --runInBand update-user-access"`
- `$env:PATH = 'C:\Program Files\Android\Android Studio\jbr\bin;' + $env:PATH; firebase emulators:exec --only firestore "npm --prefix functions test -- --runInBand update-user-access"`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 658 arquivos, 0 alterados.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
- `npm --prefix functions run build`: passou.
- `npm --prefix functions run lint`: passou.
- `flutter test`: 1047/1047 testes passaram.
- Testes direcionados Flutter da task: 80/80 testes passaram após correção de overflow do badge de status.
- Cloud Function com Firestore Emulator: 4/4 testes passaram.
- `npm test -- --runInBand update-user-access` falhou sem emulator/default credentials; o teste depende do Firestore Emulator.
- A primeira tentativa do emulator falhou por Java ausente no `PATH`; rerodado com o JBR do Android Studio e passou.

## Decisões técnicas
- A Function revoga refresh tokens sempre que o membership muda, mesmo quando o usuário ainda possui outro tenant ativo.
- O Auth user só é desabilitado quando não há mais nenhum membership ativo, evitando bloquear organizações independentes.
- `vestiproAccessDisabled` é tratado como claim de controle da VestiPro e removido na reativação, preservando outras claims existentes.
- `AppDataTableAction` ganhou builders opcionais de ícone e semântica para suportar ação dinâmica de desativar/reativar sem duplicar tabela.

## Riscos conhecidos
- O bloqueio imediato de sessão depende do próximo request autenticado ou refresh de token; usuários offline não executam ações remotas até reconectar.
- O aviso do Firestore Emulator sobre múltiplos projectIds permanece existente na suíte, mas os testes passam.

## Pendências
Nenhuma pendência funcional para a TASK-046.

## Evidências
- Build runner executado com sucesso e `injection.config.dart` atualizado.
- Formatter: 658 arquivos, 0 alterados no modo verificação.
- Analyzer: sem issues.
- Flutter full test: 1047/1047 testes passaram.
- Functions emulator: 4/4 testes passaram.
- Push autorizado pelo usuário para esta task em lote.

## Commit
Pendente no momento de criação deste documento.

## Push
Pendente no momento de criação deste documento.

## Hash do commit
Pendente no momento de criação deste documento.

## Branch
main
