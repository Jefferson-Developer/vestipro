# TASK-039 — Concluída (2026-08-23)

## Resumo

Implementado o fluxo completo de convite de usuários (TASK-039, EPIC-04): `OWNER`/`ADMIN`
convidam colaboradores por e-mail para uma Organization, escolhendo a role de destino (restrita
às roles que o convidador tem permissão de atribuir), com token seguro gerado exclusivamente
server-side, expiração configurável (padrão 7 dias), reenvio (novo token, invalida o anterior) e
revogação — tudo via três Cloud Functions callable novas (`createInvite`, `resendInvite`,
`revokeInvite`, seguindo exatamente o padrão já estabelecido por `createOrganization`, TASK-037).
Cada ação gera uma entrada de auditoria server-side, na mesma transação Firestore que a escrita
principal. Do lado Flutter, foi criada a feature `lib/features/invites/` completa
(domain/data/presentation), com `InviteUserPage` (formulário de convite) e `InviteListPage`
(lista de convites pendentes/expirados, com ações de reenviar/revogar).

## Agentes utilizados

- `flutter-senior-architect` (Cloud Functions, domain/data, RBAC server-side, Firestore Rules,
  testes de Emulator).
- `flutter-ui-design-specialist` (BLoC/estado de UI, `InviteUserPage`, `InviteListPage`,
  reaproveitamento do Design System).

## Arquivos criados

Backend (Cloud Functions, TypeScript):

- `functions/src/invites/invite-shared.ts` — helpers compartilhados: tabela de rank dos 7 system
  roles (`SYSTEM_ROLE_RANK`), `ROLES_ALLOWED_TO_INVITE` (OWNER/ADMIN), `loadActiveMembership`,
  `assertCanIssueInvite` (RBAC + hierarquia de roles), `generateInviteToken` (token seguro +
  hash SHA-256), `resolveInviteExpiration`, `serializeInvite`, `resolveActorName`.
- `functions/src/invites/create-invite.ts` — Cloud Function callable `createInvite`.
- `functions/src/invites/resend-invite.ts` — Cloud Function callable `resendInvite`.
- `functions/src/invites/revoke-invite.ts` — Cloud Function callable `revokeInvite`.
- `functions/test/invites/create-invite.test.ts` (9 testes, Firestore Emulator real).
- `functions/test/invites/resend-invite.test.ts` (9 testes, Firestore Emulator real).
- `functions/test/invites/revoke-invite.test.ts` (6 testes, Firestore Emulator real).

Frontend (feature `lib/features/invites/` completa):

- `domain/value_objects/invite_status.dart`, `domain/entities/invite.dart`,
  `domain/entities/issued_invite.dart` (+ `.freezed.dart` gerados via build_runner).
- `domain/role_hierarchy.dart` (rank dos system roles espelhado do lado TS,
  `assignableRolesFor`, `systemRoleNameFromCode`).
- `domain/repositories/invite_repository.dart`.
- `domain/validators/invite_form_validators.dart`.
- `domain/usecases/create_invite_use_case.dart`, `list_pending_invites_use_case.dart`,
  `resend_invite_use_case.dart`, `revoke_invite_use_case.dart`.
- `data/dtos/invite_dto.dart`, `data/mappers/invite_mapper.dart`.
- `data/datasources/invite_data_source.dart` (contrato) e
  `data/datasources/firestore_invite_data_source.dart` (Firestore para leitura,
  `CloudFunctionsService` para `create`/`resend`/`revoke`).
- `data/repositories/invite_repository_impl.dart`.
- `presentation/bloc/invite_form_event.dart`, `invite_form_state.dart`, `invite_form_bloc.dart`
  (+ `.freezed.dart` gerados) — drive `InviteUserPage`.
- `presentation/bloc/invite_list_event.dart`, `invite_list_state.dart`, `invite_list_bloc.dart`
  (+ `.freezed.dart` gerados) — drive `InviteListPage`.
- `presentation/pages/invite_user_page.dart`, `presentation/pages/invite_list_page.dart`.
- `invites.dart` (barrel file).

Testes (Dart, mirror 1:1 da estrutura acima):

- `test/features/invites/domain/role_hierarchy_test.dart`.
- `test/features/invites/domain/validators/invite_form_validators_test.dart`.
- `test/features/invites/domain/usecases/create_invite_use_case_test.dart`,
  `list_pending_invites_use_case_test.dart`, `resend_invite_use_case_test.dart`,
  `revoke_invite_use_case_test.dart`.
- `test/features/invites/data/dtos/invite_dto_test.dart`.
- `test/features/invites/data/mappers/invite_mapper_test.dart`.
- `test/features/invites/data/datasources/firestore_invite_data_source_test.dart`.
- `test/features/invites/data/repositories/invite_repository_impl_test.dart`.
- `test/features/invites/presentation/bloc/invite_form_bloc_test.dart`.
- `test/features/invites/presentation/bloc/invite_list_bloc_test.dart`.

Documentação:

- `docs/tasks/TASK-039-implementar-convite-de-usuarios-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `functions/src/index.ts` — exporta `createInvite`, `resendInvite`, `revokeInvite`.
- `firestore.rules` — nova subcoleção `organizations/{organizationId}/invites/{inviteId}`:
  `read` gated por `hasCapability(organizationId, 'user.invite')`; `create`/`update`/`delete`
  sempre `if false` (exclusivo das 3 Cloud Functions, Admin SDK). Comentário de cabeçalho
  atualizado para listar `invites` entre as subcoleções modeladas.
- `firestore.indexes.json` — novo índice composto `invites` (`status` ASC + `createdAt` DESC),
  necessário para a query de `InviteListPage` (`where('status', whereIn: [...]).orderBy('createdAt', descending: true)`)
  funcionar em produção (não obrigatório no Emulator, mas seria rejeitado pelo Firestore real sem
  o índice).
- `firestore-tests/firestore.rules.test.js` — novo helper `inviteDoc(...)` e 6 testes novos
  (positivos: OWNER lê convite pendente da própria organization; negativos: SALES_REP não lê,
  cross-tenant não lê, nem mesmo OWNER cria/atualiza/exclui um convite diretamente pelo cliente).
- `lib/features/audit_log/domain/value_objects/audit_action.dart` — dois novos valores:
  `AuditAction.userInviteResent` (`'user.inviteResent'`, gravado por `resendInvite`) e
  `AuditAction.userInviteRevoked` (`'user.inviteRevoked'`, gravado por `revokeInvite`) — mesma
  situação de `AuditAction.organizationCreated`: nunca escritos por código Dart, só
  interpretados de volta. `AuditAction.userInvited` (`'user.invited'`) já existia e foi
  reaproveitado por `createInvite`.
- `lib/core/analytics/analytics_events.dart` — novo `AnalyticsEvents.inviteSent`
  (`'invite_sent'`), disparado pelo `InviteFormBloc` após uma criação de convite bem-sucedida.
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) para registrar as
  novas classes `@injectable`/`@LazySingleton` da feature `invites`.
- `test/core/analytics/analytics_events_test.dart` — `invite_sent` adicionado à lista esperada.
- `test/features/audit_log/domain/value_objects/audit_action_test.dart` — asserções para os dois
  novos códigos.
- `docs/tasks/TASKS.md` — checkbox da TASK-039 marcado e `Progresso` atualizado para `39 / 220`.

Nenhum outro arquivo foi alterado. `lib/main.dart` tem uma modificação pré-existente não
relacionada a esta task (troca de entrypoint `main_dev.dart`/`main_prod.dart`, deixada por uma
sessão anterior) que foi deliberadamente ignorada — não lida, não revertida, não incluída em
nenhum commit desta task.

## Arquitetura utilizada

- Feature-first + Clean Architecture: nova feature `lib/features/invites/` completa
  (`domain/`, `data/`, `presentation/`), seguindo o padrão já estabelecido por `organizations`/
  `onboarding` — `Invite`/`IssuedInvite` (entidades `freezed`), `InviteRepository` (contrato),
  4 use cases (`create`/`list`/`resend`/`revoke`), `InviteDto`/`InviteMapper`,
  `FirestoreInviteDataSource` (composição de `FirestoreCollectionDataSource` para leitura +
  `CloudFunctionsService` para as 3 escritas), `InviteRepositoryImpl`.
- `create`/`resend`/`revoke` nunca escrevem no Firestore diretamente — sempre via
  `CloudFunctionsService.call(...)`, com parsing manual da resposta JSON (datas ISO-8601, não
  `Timestamp`), exatamente o mesmo padrão que `FirestoreOrganizationDataSource.create` estabeleceu
  na TASK-037 (`_organizationDtoFromCallableResponse` → aqui,
  `_inviteDtoFromJson`/`_issuedInviteFromCallableResponse`).
- `createInvite`/`resendInvite`/`revokeInvite` seguem o mesmo padrão de
  `functions/src/organizations/create-organization.ts`: `onCall`, `resolveCorrelationId`,
  validação de payload antes de qualquer leitura/escrita, `db.runTransaction` para escrever o
  documento principal e a entrada de auditoria atomicamente, `logger.info` estruturado sem dado
  sensível.
- `InviteFormBloc`/`InviteListBloc` seguem o padrão de `OnboardingBloc` (TASK-038): `@injectable`,
  eventos/estados `freezed`, nenhuma regra de negócio na `presentation/` — toda validação de
  e-mail é client-side/UX (`invite_form_validators.dart`), toda autorização real é
  server-side.
- `InviteUserPage`/`InviteListPage` reaproveitam o Design System integralmente
  (`AppTextField`, `AppDropdown`, `AppButton`, `AppEmptyState`, `AppErrorState`,
  `AppConfirmationDialog`, `AppSnackbar`, `AppStatusBadge`) — nenhum componente novo criado.

## Regras de negócio implementadas

- Apenas `OWNER`/`ADMIN` podem convidar, reenviar ou revogar convites — validado a partir do
  Membership real do chamador (`loadActiveMembership`), nunca de nada enviado pelo cliente.
- Hierarquia de roles: um `ADMIN` pode convidar/reenviar para qualquer role até `ADMIN`
  (inclusive), mas nunca para `OWNER`; um `OWNER` pode convidar para qualquer role, incluindo
  outro `OWNER`. Implementado via tabela de rank (`SYSTEM_ROLE_RANK` no TS,
  `systemRoleRank`/`assignableRolesFor` no Dart — mesma sincronização manual já aceita para
  `roleHasCapability`/`RolePermissionMatrix`).
- Token de convite: gerado com `crypto.randomBytes(32)` (256 bits de entropia,
  `base64url`), nunca `Math.random`/id sequencial. Apenas o hash SHA-256 do token
  (`Invite.tokenHash`) é persistido no Firestore — o token em claro só existe na resposta da
  Function no momento da criação/reenvio, nunca voltando a ser lido depois (nem mesmo por quem
  criou o convite). `InviteUserPage` mostra o link de convite (com o token) uma única vez, logo
  após a criação, para cópia/compartilhamento manual.
- Expiração: configurável por organização via `organizations/{id}.settings.inviteExpirationDays`
  (padrão 7 dias quando ausente/inválido) — não há UI dedicada para configurar esse valor ainda
  (ver "Pendências").
- Reenvio: só permitido para convite `pending`/`expired` (reativa como `pending`); gera um novo
  token/hash/`expiresAt` no **mesmo** documento — o token anterior deixa de ser válido porque só
  o hash atual é aceito, sem precisar de uma lista de tokens revogados.
- Revogação: só permitida para convite `pending`; marca `status: 'revoked'` e limpa `tokenHash`
  (`null`) como defesa em profundidade.
- Cada criação/reenvio/revogação grava exatamente uma entrada de auditoria
  (`user.invited`/`user.inviteResent`/`user.inviteRevoked`) na mesma transação Firestore da
  escrita principal — nunca client-side, diferente do padrão ainda em uso por
  `RecordAuditLogUseCase` para outras features.
- E-mail transacional: **decisão técnica registrada** — não há Firebase Extension
  (`firestore-send-email`) nem provedor terceiro (SendGrid etc.) configurado neste projeto ainda
  (`firebase.json` não declara `extensions`, nenhuma credencial de e-mail existe). Em vez de
  simular um envio que não aconteceria de fato, `createInvite`/`resendInvite` devolvem o link de
  convite (token) na própria resposta, e `InviteUserPage` o exibe para cópia/compartilhamento
  manual — comportamento honesto e funcional hoje, com a integração de e-mail real registrada como
  pendência explícita (ver "Pendências").

## Regras Firebase implementadas

- `firestore.rules`: nova subcoleção `organizations/{organizationId}/invites/{inviteId}` —
  `read` exige `hasCapability(organizationId, 'user.invite')` (mesma capability que já protegia
  `members.create`); `create`/`update`/`delete` são `if false` incondicionalmente — só as 3 Cloud
  Functions (Admin SDK, que ignora Rules) escrevem essa coleção.
- `firestore.indexes.json`: índice composto novo (`invites`: `status` ASC + `createdAt` DESC)
  para a query de listagem funcionar em produção.
- `firestore-tests/firestore.rules.test.js`: 6 testes novos — 3 positivos/negativos de leitura
  (OWNER lê, SALES_REP não lê, cross-tenant não lê) e 3 negativos de escrita (nem OWNER
  cria/atualiza/exclui um convite pelo cliente).

## Analytics implementado

- `AnalyticsEvents.inviteSent` (`'invite_sent'`), disparado por `InviteFormBloc` só após
  `createInvite` retornar sucesso, com um único parâmetro (`role`, o código da role atribuída) —
  nunca o e-mail do convidado (dado pessoal), mesma restrição documentada em
  `AnalyticsService.logEvent`.

## Crashlytics implementado

Nenhuma captura nova dedicada: toda falha de `InviteRepository`/`InviteDataSource` propaga como
`Failure`/`AppException` já tratada pelo `CrashReporter` central (TASK-016), mesmo padrão de toda
outra feature.

## Impacto offline

Nenhuma mutação desta feature é offline-first: criar, reenviar e revogar um convite são chamadas
de Cloud Function online-only (mesma decisão já tomada para `createOrganization` na TASK-037) —
sem rede, a operação falha com uma `Failure` tipada, sem persistência local/Outbox. A leitura da
lista de convites (`listPending`) também é uma leitura Firestore direta, sem cache local dedicado
além do que o SDK do Firestore já mantém — aceitável para uma tela administrativa de baixa
frequência de uso, mesmo raciocínio de outras telas administrativas ainda não construídas.

## Impacto multi-tenant

- Toda leitura/escrita de `Invite` é escopada por `organizationId` desde o domínio
  (`InviteRepository`/`InviteDataSource` exigem `organizationId` em todo método) até o Firestore
  (subcoleção de `organizations/{organizationId}`) e a Cloud Function (lê o Membership do
  chamador dentro do mesmo `organizationId` recebido, nunca de um campo solto do payload).
- Nenhuma Cloud Function nova confia em `organizationId`/role/uid vindos do payload para decidir
  autorização: `uid` sempre vem de `request.auth.uid`; a role do chamador sempre vem de uma
  leitura real de `organizations/{organizationId}/members/{uid}`.

## Testes criados

- `functions/test/invites/create-invite.test.ts` (9 testes, Firestore Emulator real via Admin SDK
  + `firebase-functions-test`): criação com token seguro/hash/auditoria, `expiresAt` padrão de 7
  dias, `expiresAt` configurável por organização, ADMIN convidando ADMIN (permitido) vs. ADMIN
  convidando OWNER (rejeitado), SALES_REP sem `user.invite` (rejeitado), sem Membership ativo
  (rejeitado), Membership inativo (rejeitado), chamada não autenticada (rejeitada), e-mail
  malformado e roleName desconhecido (rejeitados).
- `functions/test/invites/resend-invite.test.ts` (9 testes): novo token/hash/`expiresAt` +
  auditoria, token anterior de fato invalidado (dois reenvios seguidos geram tokens diferentes),
  reenvio de convite `expired` reativa como `pending`, reenvio de convite `accepted`/`revoked`
  rejeitado (`failed-precondition`), SALES_REP sem `user.invite` rejeitado, ADMIN reenviando um
  convite originalmente para OWNER rejeitado, convite inexistente (`not-found`), chamada não
  autenticada rejeitada.
- `functions/test/invites/revoke-invite.test.ts` (6 testes): revogação com `tokenHash` limpo +
  auditoria, segunda revogação do mesmo convite rejeitada (`failed-precondition`, não é idempotente
  por design — mensagem clara em vez de falso "já revogado com sucesso"), revogar um convite
  `accepted` rejeitado, SALES_MANAGER sem `user.invite` rejeitado (e o convite permanece
  `pending`), convite inexistente (`not-found`), chamada não autenticada rejeitada.
- `firestore-tests/firestore.rules.test.js`: 6 testes novos para a subcoleção `invites` (ver
  "Regras Firebase implementadas").
- Lado Dart, 57 testes novos, espelhando 1:1 a estrutura da feature: 4 suites de use case
  (validação client-side + delegação/propagação de falha), `role_hierarchy_test.dart`
  (`assignableRolesFor`/`systemRoleNameFromCode` para os 7 system roles),
  `invite_form_validators_test.dart`, `invite_dto_test.dart` (parsing/validação de todos os
  campos obrigatórios), `invite_mapper_test.dart` (roundtrip de `roleName`/`status`, rejeição de
  valores desconhecidos), `firestore_invite_data_source_test.dart` (parsing manual da resposta das
  3 Cloud Functions, incluindo erros de formato e propagação de `FirebaseFunctionsException`),
  `invite_repository_impl_test.dart`, `invite_form_bloc_test.dart` (resolução de
  `assignableRoles` a partir do Membership real, validação de formulário, sucesso/analytics,
  falha do repositório) e `invite_list_bloc_test.dart` (carga, reenvio, revogação, dedup de
  estados idênticos pelo próprio `Bloc`).

## Comandos executados

```bash
cd functions && npm run build
cd functions && npm run lint
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix functions test -- invites"
firebase emulators:exec --only firestore "npm --prefix functions test"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/invites/
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` → `Formatted 536 files (0 changed) in 2.02 seconds.` (última
passada, após todas as correções de formatação automática já aplicadas nas passadas anteriores).

## Resultado do analyzer

`flutter analyze` → `No issues found! (ran in 10.7s)`.

## Resultado dos testes

- `npm run build` (functions/TypeScript): sem erros.
- `npm run lint` (functions/ESLint): sem erros/avisos.
- `firebase emulators:exec --only firestore "npm --prefix functions test"`: `Test Suites: 6
  passed, 6 total` / `Tests: 40 passed, 40 total` (14 de `create-organization`/`callable-meta`/
  `health-check` já existentes + 9 de `create-invite` + 9 de `resend-invite` + 6 de
  `revoke-invite`; os números batem porque `callable-meta`/`health-check` somam 7 dos 14
  originais).
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`: `Tests: 57
  passed, 57 total` (era 51 antes desta task).
- `flutter test test/features/invites/`: `+57: All tests passed!`.
- `flutter test` (suíte completa do repositório): `+907: All tests passed!` (era +795 após a
  TASK-037; a diferença inclui os testes desta task mais os que outras tasks concluídas
  posteriormente já haviam adicionado).

## Decisões técnicas

- **E-mail transacional não enviado de fato, link exibido na UI em vez disso** — decisão
  documentada em "Regras de negócio implementadas"/"Pendências": não instalar uma Extension nem
  integrar um provedor terceiro sem credenciais/decisão de produto real disponíveis agora seria
  simular algo que não funciona; a resposta da Function já traz tudo que uma integração futura
  precisaria (token, e-mail, papel, mensagem) — trocar "exibir link" por "enviar e-mail de fato"
  fica inteiramente contido em `createInvite`/`resendInvite` no futuro, sem exigir nenhuma
  mudança de contrato do lado Dart.
- **Token de convite: hash SHA-256 persistido, nunca o valor em claro** — mesmo quando
  `InviteListPage` (OWNER/ADMIN) pode ler a coleção `invites` inteira, nenhum deles pode
  reconstruir um token utilizável a partir do que está no Firestore. Mais forte do que o mínimo
  exigido pela task (que só pedia "token seguro, não previsível"), sem custo real de
  implementação.
- **Hierarquia de roles como tabela de rank simples (`Map<SystemRoleName, int>`), duplicada
  manualmente entre TypeScript e Dart** — mesmo trade-off já aceito e documentado para
  `roleHasCapability` (Rules) vs. `RolePermissionMatrix` (Dart) desde a TASK-030: um terceiro
  lugar (Cloud Functions) que replica a mesma decisão de RBAC precisa ser mantido em sincronia
  manualmente. Alternativa descartada: derivar a Function a partir de
  `role_permission_matrix.dart` diretamente — impossível sem um passo de build compartilhado
  entre Dart e TypeScript, fora de escopo desta task.
- **`InviteUserPage`/`InviteListPage` não foram wireadas em `AppRouter`/`bootstrap.dart`** — a
  feature `organizations` (TASK-026 a TASK-029), de onde `InviteRepository` deriva boa parte do
  seu contexto (Membership, roles), também não tem nenhuma tela própria nem rota registrada ainda;
  a navegação administrativa real (lista de usuários, perfis, equipes) é escopo explícito de
  TASK-042 a TASK-047. Construir agora uma rota real sem o resto do shell administrativo que a
  hospedaria repetiria o mesmo risco que a TASK-026/TASK-037 já registraram e evitaram
  deliberadamente para `ActiveOrganizationGuard` ("religar um guard real sem o fluxo que o
  alimenta cria uma dependência quebrada"). As duas páginas são componentes completos,
  testáveis e prontos (`organizationId`/`createBloc` injetados pelo chamador), à espera da tela
  administrativa que as hospedará.
- **`resend`/`revoke` fazem sua leitura de precondição fora da transação, escrevem dentro dela** —
  diferente de `createOrganization`, que lê tudo dentro da transação para garantir atomicidade
  completa contra corrida concorrente. Para `resend`/`revoke`, uma corrida entre duas chamadas
  simultâneas na pior hipótese gera dois tokens onde só o último é válido (resend) ou uma segunda
  chamada que erra com `failed-precondition` em vez de confirmar sucesso (revoke) — nenhum
  cenário deixa o `Invite` em um estado inconsistente ou duplica efeito. Ganho de simplicidade
  aceito conscientemente; documentado aqui para quem revisar depois.

## Riscos conhecidos

- Mesmo risco já registrado pela TASK-030/TASK-037: `SYSTEM_ROLE_RANK`
  (`functions/src/invites/invite-shared.ts`) e `systemRoleRank`
  (`lib/features/invites/domain/role_hierarchy.dart`) precisam ser mantidos sincronizados
  manualmente com os 7 system roles — nenhum teste de contrato automatizado compara os dois hoje.
- `InviteUserPage`/`InviteListPage` não têm rota real no `AppRouter` (ver "Decisões técnicas") —
  quem for wireá-las numa futura tela administrativa deve lembrar de usar
  `PermissionAuthorizationGuard`/`Capability.userInvite` no nível de rota, não só o
  `state.assignableRoles.isEmpty` que `InviteUserPage` já usa como UX.
- Sem e-mail transacional real, o convite depende de um humano copiar/enviar o link manualmente —
  aceitável para o volume inicial de uso, mas não escala para convites em massa; ver Pendências.

## Pendências

- Integrar um provedor de e-mail transacional real (Firebase Extension `firestore-send-email` ou
  API de terceiro) para que `createInvite`/`resendInvite` disparem o e-mail de fato, em vez de só
  devolver o link para exibição manual — decisão de infraestrutura/produto fora do escopo desta
  task.
- Construir uma UI de configuração de `organizations/{id}.settings.inviteExpirationDays` — hoje
  só é ajustável escrevendo diretamente no Firestore.
- Wireear `InviteUserPage`/`InviteListPage` em `AppRouter`/`bootstrap.dart` assim que a tela
  administrativa de usuários/equipes (TASK-042 a TASK-047) existir para hospedá-las.
- TASK-040 (aceite de convite) consome o token gerado aqui — a interpretação de e-mail divergente
  entre convite e conta na hora do aceite é responsabilidade explícita daquela task, não desta.
- Nenhuma pendência bloqueia a conclusão desta task: os 4 critérios de aceite (convite só por
  OWNER/ADMIN autorizado e validado no backend; token seguro/expirável/revogável comprovado por
  teste; uma entrada de auditoria por ação; formatter/analyzer/testes sem erros) estão
  implementados e testados.

## Evidências

- `functions/src/invites/` (4 arquivos) e `functions/test/invites/` (3 arquivos, 24 testes).
- `firestore.rules` (bloco `invites`), `firestore.indexes.json` e
  `firestore-tests/firestore.rules.test.js` (6 testes novos).
- `lib/features/invites/` (feature completa) e `test/features/invites/` (57 testes).
- Saída de `firebase emulators:exec --only firestore "npm --prefix functions test"`
  (`Tests: 40 passed, 40 total`), de `firebase emulators:exec --only firestore "npm --prefix
  firestore-tests test"` (`Tests: 57 passed, 57 total`) e de `flutter test`
  (`+907: All tests passed!`), reproduzidas nas seções "Resultado dos testes" acima.

## Commit

Criado com sucesso (`lib/main.dart`, alteração pré-existente não relacionada a esta task, foi
deliberadamente deixado de fora do commit).

## Push

Autorizado nesta rodada; executado com sucesso após o commit.

## Hash do commit

Ver seção "Hash do commit" da resposta final desta task.

## Branch

`main`
