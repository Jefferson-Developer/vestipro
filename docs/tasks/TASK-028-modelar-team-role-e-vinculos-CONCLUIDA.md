# TASK-028 — Concluída (2026-08-22)

## Resumo

Modeladas as entidades `Role`, `Team` e `Membership` (vínculo usuário-organização-role),
na mesma feature `organizations` de TASK-026/TASK-027, seguindo exatamente o padrão já
estabelecido por `Company`/`Branch`. Implementados os 7 perfis iniciais previstos na seção
3.3 de `tasks.md` (`OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`,
`FINANCE`, `READ_ONLY`) via `EnsureSystemRolesUseCase` (idempotente, pronto para ser
invocado pelo fluxo de onboarding da TASK-037 sem duplicar a lógica de seed), além dos
casos de uso de vínculo (`AssignRoleToUserUseCase`, `CreateTeamUseCase`,
`AddUserToTeamUseCase`, `GetUserMembershipUseCase`) explicitamente pedidos pela task. Esta
task modela apenas dados e CRUD básico — a lógica de autorização (o que cada role pode
fazer) é escopo da TASK-029 (RBAC).

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task; task é puramente de
  modelagem/arquitetura, sem UI).

## Arquivos criados

Domínio:
- `lib/features/organizations/domain/value_objects/system_role_name.dart`
- `lib/features/organizations/domain/value_objects/membership_status.dart`
- `lib/features/organizations/domain/entities/role.dart` (+ `.freezed.dart` gerado, inclui
  a guarda `assertRoleIsMutable`)
- `lib/features/organizations/domain/entities/team.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/entities/membership.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/repositories/role_repository.dart`
- `lib/features/organizations/domain/repositories/team_repository.dart`
- `lib/features/organizations/domain/repositories/membership_repository.dart`
- `lib/features/organizations/domain/usecases/ensure_system_roles_use_case.dart`
- `lib/features/organizations/domain/usecases/create_team_use_case.dart`
- `lib/features/organizations/domain/usecases/add_user_to_team_use_case.dart`
- `lib/features/organizations/domain/usecases/assign_role_to_user_use_case.dart`
- `lib/features/organizations/domain/usecases/get_user_membership_use_case.dart`

Dados:
- `lib/features/organizations/data/dtos/role_dto.dart`
- `lib/features/organizations/data/dtos/team_dto.dart`
- `lib/features/organizations/data/dtos/membership_dto.dart`
- `lib/features/organizations/data/mappers/role_mapper.dart`
- `lib/features/organizations/data/mappers/team_mapper.dart`
- `lib/features/organizations/data/mappers/membership_mapper.dart`
- `lib/features/organizations/data/datasources/role_data_source.dart`
- `lib/features/organizations/data/datasources/firestore_role_data_source.dart`
- `lib/features/organizations/data/datasources/team_data_source.dart`
- `lib/features/organizations/data/datasources/firestore_team_data_source.dart`
- `lib/features/organizations/data/datasources/membership_data_source.dart`
- `lib/features/organizations/data/datasources/firestore_membership_data_source.dart`
- `lib/features/organizations/data/repositories/role_repository_impl.dart`
- `lib/features/organizations/data/repositories/team_repository_impl.dart`
- `lib/features/organizations/data/repositories/membership_repository_impl.dart`

Testes:
- `test/features/organizations/domain/entities/role_test.dart`
- `test/features/organizations/domain/entities/team_test.dart`
- `test/features/organizations/domain/entities/membership_test.dart`
- `test/features/organizations/domain/usecases/ensure_system_roles_use_case_test.dart`
- `test/features/organizations/domain/usecases/create_team_use_case_test.dart`
- `test/features/organizations/domain/usecases/add_user_to_team_use_case_test.dart`
- `test/features/organizations/domain/usecases/assign_role_to_user_use_case_test.dart`
- `test/features/organizations/domain/usecases/get_user_membership_use_case_test.dart`
- `test/features/organizations/data/dtos/role_dto_test.dart`
- `test/features/organizations/data/dtos/team_dto_test.dart`
- `test/features/organizations/data/dtos/membership_dto_test.dart`
- `test/features/organizations/data/mappers/role_mapper_test.dart`
- `test/features/organizations/data/mappers/team_mapper_test.dart`
- `test/features/organizations/data/mappers/membership_mapper_test.dart`
- `test/features/organizations/data/repositories/role_repository_impl_test.dart`
- `test/features/organizations/data/repositories/team_repository_impl_test.dart`
- `test/features/organizations/data/repositories/membership_repository_impl_test.dart`

## Arquivos alterados

- `lib/features/organizations/organizations.dart` — barrel público da feature passou a
  exportar as entidades, contratos de repositório, casos de uso e value objects de
  `Role`/`Team`/`Membership` (mesmo padrão já usado para `Organization`/`Company`/`Branch`;
  datasources/DTOs continuam privados à feature).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (novos providers
  `@injectable`/`@lazySingleton`/`@LazySingleton` de `Role`/`Team`/`Membership`).

## Arquitetura utilizada

Clean Architecture feature-first, idêntica ao padrão de `Company`/`Branch` (TASK-027):
Domain (entidades `Role`/`Team`/`Membership` com Freezed, value objects
`SystemRoleName`/`MembershipStatus`, contratos `RoleRepository`/`TeamRepository`/
`MembershipRepository`, casos de uso) → Data (DTOs, mappers, datasources Firestore
compondo `FirestoreCollectionDataSource<T>`, `*RepositoryImpl`). Não há camada de
apresentação nesta task (modelagem pura, sem UI).

## Regras de negócio implementadas

- `Role.isSystemRole == true` (os 7 perfis iniciais) nunca pode ser excluída ou renomeada
  por nenhum caso de uso desta feature: `RoleRepository` deliberadamente não expõe
  `update`/`delete`, e a guarda pura `assertRoleIsMutable(Role role)` (testada
  isoladamente) lança `ForbiddenException` para qualquer tentativa contra uma role de
  sistema — pronta para ser reutilizada pelas futuras telas de administração de roles
  customizadas (TASK-029+).
- `EnsureSystemRolesUseCase` semeia os 7 perfis (`OWNER`, `ADMIN`, `SALES_MANAGER`,
  `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`) usando o próprio código do perfil
  como id do documento (`organizations/{organizationId}/roles/{code}`), o que torna a
  operação idempotente por construção: rodar de novo nunca duplica nem sobrescreve uma role
  já existente.
- `Membership.id` é sempre igual a `Membership.userId` (documento em
  `organizations/{organizationId}/members/{userId}`) — modela a regra "um usuário só tem
  vínculo com uma Organization através de um registro explícito", nunca inferido.
- `Membership.organizationId`/`Membership.userId` são imutáveis: nenhum caso de uso ou
  método de repositório os aceita como parâmetro de atualização — trocar de organização
  significa criar um novo `Membership`, nunca editar o existente.
- `AssignRoleToUserUseCase` faz upsert consciente: cria um `Membership` quando o usuário
  ainda não tem um, ou atualiza apenas `roleId`/`roleName` preservando `teamIds`/`status`
  quando já existe — sem nenhuma verificação de autorização (RBAC é escopo da TASK-029).
- `Team.memberIds` é atualizado via `FieldValue.arrayUnion` (idempotente: adicionar o mesmo
  usuário duas vezes mantém uma única entrada).
- Toda consulta de `Role`/`Team`/`Membership` exige `organizationId` como parâmetro
  obrigatório em toda a cadeia (use case → repository → datasource → Firestore path), nunca
  uma query global entre organizações.

## Regras Firebase implementadas

- `Role` em `organizations/{organizationId}/roles/{id}`; `Team` em
  `organizations/{organizationId}/teams/{id}`; `Membership` em
  `organizations/{organizationId}/members/{userId}` — exatamente o layout pedido na seção
  20 de `tasks.md`.
- `organizationId` (e `userId`, no caso de `Membership`) persistido também como campo do
  documento (redundante com o path) para permitir que as futuras Firestore Rules
  (TASK-030) o validem sem precisar reconstruir o path.
- Nenhuma Security Rule nova criada nesta task (fora de escopo — chega na TASK-030); os
  comentários de código continuam explícitos que o escopo por `organizationId` no client é
  defesa em profundidade, nunca a autorização real.

## Analytics implementado

Nenhum — task é modelagem de domínio/dados, sem fluxo de UI/usuário para instrumentar.

## Crashlytics implementado

Nenhum novo ponto de captura explícito; exceptions do Firestore continuam mapeadas para
`AppException`/`Failure` via `mapFirestoreExceptionToAppException`/`mapAppExceptionToFailure`
já existentes.

## Impacto offline

Nenhuma mudança de comportamento offline: `Role`/`Team`/`Membership` seguem o mesmo caminho
direto ao Firestore que `Organization`/`Company`/`Branch` (sem Outbox). Gestão de
roles/teams/membership por representante em campo sem conexão ainda não passa pelo padrão
`pending -> syncing -> synced | failed | conflict` — risco documentado abaixo.

## Impacto multi-tenant

- Toda leitura/escrita de `Role`/`Team`/`Membership` exige `organizationId` explícito em
  cada camada; `listByOrganization` nunca aceita consulta sem esse escopo.
- Testes de repositório (`role_repository_impl_test.dart`, `team_repository_impl_test.dart`,
  `membership_repository_impl_test.dart`) simulam explicitamente duas organizações e
  garantem que uma listagem nunca inclui dado da outra.
- `organizationId`/`userId` nunca são aceitos como parâmetro de atualização em
  `MembershipRepository.update` — apenas como parâmetro de roteamento.

## Testes criados

- Entidades: igualdade por valor, `copyWith` preservando `organizationId`/`userId`,
  `Membership.id == Membership.userId`, defaults de `memberIds`/`teamIds`, e a guarda
  `assertRoleIsMutable` (lança para role de sistema, não lança para role customizada).
- Casos de uso: `EnsureSystemRolesUseCase` (cria os 7 perfis marcados `isSystemRole`,
  idempotência ao rodar de novo, validação e propagação de falha);
  `CreateTeamUseCase`/`AddUserToTeamUseCase` (delegação, trimming, validação,
  `NotFoundFailure` quando o time não existe); `GetUserMembershipUseCase`
  (delegação, validação, `NotFoundFailure`); `AssignRoleToUserUseCase` (cria quando não
  existe vínculo, atualiza preservando `teamIds`/`status` quando já existe, validação,
  propagação de falha de organização/usuário inexistente e de falhas não relacionadas a
  "not found").
- Mappers: round-trip DTO ↔ entidade, mapeamento de status desconhecido lançando
  `ValidationException`, defaults de listas vazias.
- DTOs: parsing de payload Firestore completo e mínimo, exceção de validação para campos
  obrigatórios ausentes/malformados, `toJson` nunca inclui `id`.
- Repositórios: sucesso, mapeamento de exceções, e — requisito explícito da task — teste
  dedicado de que a listagem nunca mistura dados de outra organização, usando datasource
  mockado com múltiplos tenants.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

Sem alterações pendentes (`Formatted 369 files (0 changed)`).

## Resultado do analyzer

`No issues found!` (analisado o projeto inteiro).

## Resultado dos testes

`flutter test` (suíte completa do projeto): **603 testes, 603 passaram, 0 falharam**.
`flutter test test/features/organizations`: **181 testes, 181 passaram** (isolado).

## Decisões técnicas

- `Role`/`Team`/`Membership` foram modelados dentro da feature `organizations` já existente
  (em vez de uma feature nova, ex. `access_control`), pois o próprio docstring de
  `Organization` (TASK-026) já os cita como parte do mesmo modelo de tenancy
  ("Every Company, Branch, Team, Role and business document is scoped under
  organizations/{id}") e reaproveitam integralmente o padrão de `Company`/`Branch`.
- `RoleRepository` deliberadamente não expõe `update`/`delete`: a task explicita que
  nenhum caso de uso desta feature pode excluir/renomear uma role de sistema, e o requisito
  de teste correspondente foi atendido por uma guarda pura de domínio
  (`assertRoleIsMutable`), evitando construir uma capacidade de mutação que hoje nunca teria
  um caminho de sucesso (não há ainda criação de roles customizadas) e que pertence, de
  fato, à administração de RBAC (TASK-029).
- `EnsureSystemRolesUseCase` usa o próprio código do perfil (`OWNER`, `ADMIN`, ...) como id
  do documento em vez de gerar um id aleatório — torna a semeadura idempotente sem precisar
  de transação, e documenta explicitamente que deve ser chamado pelo onboarding da
  TASK-037 sem duplicar esta lógica.
- `AssignRoleToUserUseCase` implementa upsert (cria se não existir vínculo, atualiza se já
  existir) em vez de dois casos de uso separados — reflete diretamente o nome pedido pela
  task ("assign role to user") e cobre tanto o primeiro convite de um usuário quanto uma
  posterior mudança de role, sem introduzir uma lógica de autorização (fica para TASK-029).
- `MembershipRepository.create` recebe `teamIds` com valor default (`const <String>[]`)
  em vez de obrigatório, já que a maioria dos vínculos nasce sem time definido.

## Riscos conhecidos

- Mesma limitação de idempotência de `create()` já documentada em TASK-027 para
  `Company`/`Branch`: como o `id` de `Team` é gerado uma vez pelo chamador e a escrita usa
  `set()` sem transação, um retry de rede após um create bem-sucedido pode, em cenários
  extremos, criar um documento duplicado se o `id` mudar entre tentativas. `Role`
  (id = código do perfil) e `Membership` (id = `userId`) não sofrem desse risco, pois seus
  ids são deterministicamente derivados, não gerados aleatoriamente.
- Não há Firestore Security Rules para `roles`/`teams`/`members` ainda (chega na
  TASK-030) — hoje o isolamento multi-tenant depende inteiramente do client sempre passar o
  `organizationId` correto; documentado no código como "defesa em profundidade apenas".
- `EnsureSystemRolesUseCase` ainda não está integrado ao fluxo real de criação de
  Organization (isso é escopo da TASK-037, "Implementar criação da primeira Organization",
  que ainda não foi executada) — hoje é um caso de uso pronto e testado, mas não invocado
  por nenhum outro fluxo do app.

## Pendências

- Integrar `EnsureSystemRolesUseCase` ao fluxo de criação da primeira Organization
  (TASK-037) e tornar o usuário criador automaticamente `OWNER` via
  `AssignRoleToUserUseCase` (mencionado como requisito futuro no próprio corpo da task).
- RBAC (o que cada role realmente pode fazer), Firestore Security Rules dedicadas e UI de
  administração de Role/Team/Membership ficam para as tasks seguintes (TASK-029 a
  TASK-030+), conforme a ordem do backlog.

## Evidências

- `flutter analyze` (projeto completo): `No issues found!`
- `flutter test` (projeto completo): `+603: All tests passed!`
- `dart format --set-exit-if-changed .`: `Formatted 369 files (0 changed)`

## Commit

Único commit cobrindo implementação + testes + documentação + atualização do backlog.

## Push

Sim, `git push origin main` executado após o commit.

## Hash do commit

Preenchido após o commit real (ver seção "Commit" abaixo do texto de retorno final).

## Branch

`main`
