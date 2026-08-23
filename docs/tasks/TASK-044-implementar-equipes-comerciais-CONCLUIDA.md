# TASK-044 — Concluída (2026-08-23)

## Resumo
Implementada a gestão de equipes comerciais com domínio, use cases, BLoCs e páginas Flutter para listar, criar, editar e excluir equipes. A equipe agora possui gestor responsável, membros elegíveis por role, suporte a usuário em múltiplas equipes e bloqueio de exclusão quando houver vínculos comerciais.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- vestipro-commercial-ops-strategist

## Arquivos criados
- `lib/features/organizations/domain/usecases/add_member_to_team_use_case.dart`
- `lib/features/organizations/domain/usecases/delete_team_use_case.dart`
- `lib/features/organizations/domain/usecases/remove_member_from_team_use_case.dart`
- `lib/features/organizations/domain/usecases/team_membership_policy.dart`
- `lib/features/organizations/domain/usecases/update_team_use_case.dart`
- `lib/features/users/domain/entities/commercial_team.dart`
- `lib/features/users/domain/usecases/list_commercial_teams_use_case.dart`
- `lib/features/users/presentation/bloc/team_form_bloc.dart`
- `lib/features/users/presentation/bloc/team_form_event.dart`
- `lib/features/users/presentation/bloc/team_form_state.dart`
- `lib/features/users/presentation/bloc/team_list_bloc.dart`
- `lib/features/users/presentation/bloc/team_list_event.dart`
- `lib/features/users/presentation/bloc/team_list_state.dart`
- `lib/features/users/presentation/pages/team_form_page.dart`
- `lib/features/users/presentation/pages/team_list_page.dart`
- `test/features/organizations/domain/usecases/add_member_to_team_use_case_test.dart`
- `test/features/organizations/domain/usecases/delete_team_use_case_test.dart`
- `test/features/organizations/domain/usecases/remove_member_from_team_use_case_test.dart`
- `test/features/organizations/domain/usecases/update_team_use_case_test.dart`
- `test/features/users/presentation/pages/team_form_page_test.dart`
- `test/features/users/presentation/pages/team_list_page_test.dart`
- `docs/tasks/TASK-044-implementar-equipes-comerciais-CONCLUIDA.md`

## Arquivos alterados
- `lib/app/injection.config.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/features/organizations/data/datasources/firestore_team_data_source.dart`
- `lib/features/organizations/data/datasources/team_data_source.dart`
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`
- `lib/features/organizations/data/dtos/team_dto.dart`
- `lib/features/organizations/data/mappers/organization_mapper.dart`
- `lib/features/organizations/data/mappers/team_mapper.dart`
- `lib/features/organizations/data/repositories/team_repository_impl.dart`
- `lib/features/organizations/domain/entities/team.dart`
- `lib/features/organizations/domain/entities/team.freezed.dart`
- `lib/features/organizations/domain/repositories/team_repository.dart`
- `lib/features/organizations/domain/usecases/create_team_use_case.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.freezed.dart`
- `lib/features/organizations/organizations.dart`
- `lib/features/users/users.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/features/organizations/data/repositories/team_repository_impl_test.dart`
- `test/features/organizations/domain/usecases/create_team_use_case_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first: Presentation (`TeamListPage`, `TeamFormPage` + BLoCs) -> Use cases -> Repository contracts -> Repository impl -> Firestore datasource. A UI não acessa Firestore, Storage ou Drift diretamente.

## Regras de negócio implementadas
- `Team` recebeu `managerUserId` obrigatório nos fluxos de create/update.
- Gestor responsável precisa ser Membership ativo com role `SALES_MANAGER`.
- Membros selecionáveis precisam ser Membership ativo com role `SALES_REP` ou `SALES_ASSISTANT`.
- Usuário pode permanecer em múltiplas equipes simultaneamente; `Membership.teamIds` preserva vínculos anteriores.
- Limite opcional `OrganizationSettings.maxTeamsPerUser` bloqueia novas associações quando configurado.
- Remover membro de uma equipe remove apenas o `teamId` daquela Membership, preservando vínculos em outras equipes.
- Exclusão de equipe consulta vínculos comerciais em `customers`/`orders` e bloqueia quando há referência por `teamId` ou `teamIds`.
- Exclusão é soft delete; não há deleção em cascata de dados comerciais.

## Regras Firebase implementadas
Não houve alteração em `firestore.rules`. As operações continuam protegidas pelas regras existentes de `team.manage` e escopo `organizations/{organizationId}`. A checagem de vínculos comerciais foi implementada no datasource/repository/use case, sem acesso direto pela UI.

## Analytics implementado
Adicionados eventos sem PII: `team_created`, `team_updated` e `team_deleted`, com `organization_id`, `team_id` e, quando aplicável, `member_count`.

## Crashlytics implementado
Não houve integração específica nova. Erros seguem o fluxo existente de exceptions/failures, BLoC state e feedback via UI.

## Impacto offline
Não foi criada persistência offline/Outbox nesta task. As mutações de equipe são administrativas e dependem dos repositories existentes; a estrutura preserva dados locais/futuros por não fazer cascade delete.

## Impacto multi-tenant
Todas as operações exigem `organizationId`, consultam Membership/Team dentro do tenant e não reescrevem `organizationId`. `companyId` e `branchId` foram adicionados como escopos opcionais em `Team` para uso quando aplicável.

## Testes criados
- Use cases: criação, edição, adição de membro, remoção de membro, múltiplas equipes simultâneas, limite configurável e exclusão bloqueada por vínculo comercial.
- Widget: formulário com validação de gestor obrigatório, criação com multi-seleção de membros, edição de equipe e estado vazio da lista.
- Analytics: catálogo atualizado para os eventos de equipe.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format .`
- `flutter analyze` (intermediário, falhou por testes antigos desatualizados; corrigido)
- `flutter test test/features/organizations/domain/usecases/create_team_use_case_test.dart test/features/organizations/domain/usecases/update_team_use_case_test.dart test/features/organizations/domain/usecases/add_member_to_team_use_case_test.dart test/features/organizations/domain/usecases/remove_member_from_team_use_case_test.dart test/features/organizations/domain/usecases/delete_team_use_case_test.dart test/features/users/presentation/pages/team_form_page_test.dart test/features/users/presentation/pages/team_list_page_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 628 arquivos, 0 alterados.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
- Testes focados da task: 15/15 passaram.
- `flutter test`: 1021/1021 testes passaram.

## Decisões técnicas
- `AddMemberToTeamUseCase` foi criado sem remover `AddUserToTeamUseCase`, preservando compatibilidade com a TASK-028 e evitando quebra de callers antigos.
- A consistência entre `Team.memberIds` e `Membership.teamIds` ficou nos use cases de equipe, centralizando regra fora da UI.
- A checagem de exclusão consulta coleções comerciais futuras (`customers`/`orders`) por `teamId` e `teamIds`, bloqueando de forma conservadora qualquer referência encontrada.
- `OrganizationSettings.maxTeamsPerUser` é opcional para não quebrar organizações já existentes.

## Riscos conhecidos
- As mutações que atualizam `Team` e `Membership` ainda são orquestradas no cliente por use case; uma Cloud Function transacional pode reforçar atomicidade em uma task futura.
- As queries de vínculo comercial usam coleções ainda futuras no backlog; quando `Customer`/`Order` forem modelados, índices/regras poderão exigir ajuste fino.

## Pendências
Nenhuma pendência funcional para a TASK-044.

## Evidências
- Build runner executado com sucesso e `injection.config.dart`/Freezed atualizados.
- Formatter: 0 arquivos alterados no modo verificação.
- Analyzer: sem issues.
- Flutter full test: 1021/1021 testes passaram.

## Commit
Pendente no momento de criação deste documento.

## Push
Pendente no momento de criação deste documento.

## Hash do commit
Pendente no momento de criação deste documento.

## Branch
main
