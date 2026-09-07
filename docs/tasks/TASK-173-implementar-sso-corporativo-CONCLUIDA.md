# TASK-173 — Concluída (2026-09-06)

## Resumo

Implementado suporte a SSO corporativo (SAML 2.0 e OIDC) por organização: cada organização pode
cadastrar sua própria conexão de Identity Provider (Azure AD, Okta, Google Workspace etc.), usuários
com e-mail corporativo naquele domínio conseguem entrar via "Entrar com SSO corporativo" na tela de
login, e o primeiro login provisiona automaticamente (just-in-time) o `Membership` do usuário com um
papel padrão configurável pela organização — nunca `OWNER`/`ADMIN`. Segue o mesmo padrão de escopo já
usado nas tasks anteriores de integração (TASK-169/170/171, EPIC-22): a arquitetura completa
(Cloud Functions, modelo de dados, RBAC, Security Rules, fluxo de login end-to-end) foi implementada;
a tela de administração para o gestor cadastrar a metadata do IdP (portal admin) fica para uma rodada
de UI futura, mesma pendência documentada nas tasks anteriores.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, Cloud Functions, RBAC, Firestore Rules,
  testes) — único agente exigido pela task; escopo não teve componente comercial/gerencial que
  justificasse os agentes de negócio.

## Arquivos criados

Backend (Cloud Functions, TypeScript):
- `functions/src/sso/types.ts`
- `functions/src/sso/sso-shared.ts`
- `functions/src/sso/configure-sso-connection.ts`
- `functions/src/sso/resolve-sso-for-email.ts`
- `functions/src/sso/complete-sso-login.ts`
- `functions/src/sso/index.ts`
- `functions/test/sso/sso-shared.test.ts`
- `functions/test/sso/configure-sso-connection.test.ts`
- `functions/test/sso/resolve-sso-for-email.test.ts`
- `functions/test/sso/complete-sso-login.test.ts`

Flutter — feature `sso` (Clean Architecture, feature-first):
- `lib/features/sso/domain/value_objects/sso_protocol.dart`
- `lib/features/sso/domain/entities/sso_login_route.dart` (+ `.freezed.dart`)
- `lib/features/sso/domain/entities/completed_sso_login.dart` (+ `.freezed.dart`)
- `lib/features/sso/domain/entities/corporate_sso_login_result.dart` (+ `.freezed.dart`)
- `lib/features/sso/domain/repositories/sso_repository.dart`
- `lib/features/sso/domain/usecases/sign_in_with_corporate_sso_use_case.dart`
- `lib/features/sso/data/dtos/sso_login_route_dto.dart`
- `lib/features/sso/data/dtos/completed_sso_login_dto.dart`
- `lib/features/sso/data/mappers/sso_mapper.dart`
- `lib/features/sso/data/datasources/sso_data_source.dart`
- `lib/features/sso/data/datasources/cloud_functions_sso_data_source.dart`
- `lib/features/sso/data/repositories/sso_repository_impl.dart`
- `lib/features/sso/sso.dart` (barrel)
- `lib/features/authentication/presentation/widgets/corporate_sso_login_modal.dart`
- `test/features/sso/**` (dtos, mapper, repository impl, use case)

## Arquivos alterados

- `functions/src/index.ts` — exporta `configureSsoConnection`, `resolveSsoForEmail`,
  `completeSsoLogin`.
- `firestore.rules` — bloco `organizations/{organizationId}/ssoConnections/{connectionId}`
  (`allow read, write: if false`, mesmo padrão de `webhookSecrets`/`apiKeys`).
- `firestore-tests/firestore.rules.test.js` — casos de negação total (`describe('ssoConnections')`),
  incluindo isolamento cross-tenant.
- `lib/core/permissions/capability.dart` — nova `Capability.ssoManage` (`code: 'sso.manage'`).
- `test/core/permissions/role_permission_matrix_test.dart` — cobre RBAC de `ssoManage`
  (OWNER/ADMIN apenas, automático via `RolePermissionMatrix`).
- `lib/core/auth/domain/repositories/auth_repository.dart`,
  `lib/core/auth/data/repositories/auth_repository_impl.dart`,
  `lib/core/auth/data/datasources/auth_data_source.dart`,
  `lib/core/auth/data/datasources/firebase_auth_data_source.dart` — novo método
  `signInWithFederatedProvider({providerId, isSaml})` (usa `SAMLAuthProvider`/`OAuthProvider` +
  `FirebaseAuth.signInWithProvider`, `firebase_auth ^6.5.7`, cross-platform Web/Android/iOS).
- `lib/core/auth/data/mappers/firebase_auth_exception_mapper.dart` (+ teste) — mapeamento de
  `account-exists-with-different-credential`.
- `lib/features/authentication/presentation/bloc/login_event.dart`,
  `login_state.dart`, `login_bloc.dart`, `presentation/widgets/login_form.dart` — fluxo "Entrar com
  SSO corporativo" na tela de login.
- `lib/app/injection.config.dart` — regenerado (build_runner) para os novos providers injetáveis.
- Fakes de `AuthRepository`/`SsoRepository` atualizados em 9 arquivos de teste pré-existentes que
  dependiam do contrato de `AuthRepository` (novo método do contrato): `send_password_reset_email_
  use_case_test.dart`, `forgot_password_bloc_test.dart`, `login_bloc_test.dart`,
  `sign_up_bloc_test.dart`, `forgot_password_page_test.dart`, `login_page_test.dart`,
  `sign_up_page_test.dart`, `accept_invite_page_test.dart`, `onboarding_bloc_test.dart`,
  `onboarding_wizard_page_test.dart`.

## Arquitetura utilizada

Clean Architecture feature-first, mesmo padrão de `lib/features/invites/`:
Presentation (`LoginBloc`/`CorporateSsoLoginModal`) → Use case
(`SignInWithCorporateSsoUseCase`) → Repository contract (`SsoRepository`) → Repository impl
(`SsoRepositoryImpl`) → Datasource (`CloudFunctionsSsoDataSource`, callable). O use case também
orquestra `AuthRepository.signInWithFederatedProvider` (novo método de domínio, sem dependência de
Firebase no domain — a implementação concreta com `firebase_auth` fica só em
`AuthRepositoryImpl`/`FirebaseAuthDataSource`, como já era).

No backend, `functions/src/sso/` segue exatamente o padrão de `functions/src/invites/`: um
`*-shared.ts` com validações/RBAC/paths reaproveitados pelas 3 Cloud Functions, transação Firestore
para o provisionamento (mesmo "ler tudo dentro da transação" de `accept-invite.ts`), audit log em
`organizations/{organizationId}/auditLogs`.

## Regras de negócio implementadas

- SSO nunca provisiona com papel administrativo por padrão: `validateDefaultRoleName`
  (`sso-shared.ts`) rejeita `OWNER`/`ADMIN` como `defaultRoleName` na configuração, e
  `completeSsoLogin` só usa esse mesmo campo já validado — nunca aceita um papel vindo do cliente.
- Usuário SSO segue o mesmo RBAC/isolamento que qualquer outro: JIT provisioning cria um
  `Membership` idêntico em formato ao de `acceptInvite`/`createOrganization`; nenhuma leitura/regra
  de RBAC em qualquer outra parte do app distingue a origem do Membership.
- Isolamento entre organizações: `configureSsoConnection` rejeita (`already-exists`) qualquer domínio
  de e-mail já reivindicado por outra `ssoConnection` (própria ou de outra organização) via
  `collectionGroup('ssoConnections')`; `completeSsoLogin` só resolve organização pelo `providerId`
  do token federado e revalida que o domínio do e-mail retornado pelo IdP pertence à conexão
  encontrada (defesa em profundidade contra um IdP mal configurado/comprometido).
- Falha de configuração segura: `configureSsoConnection` encapsula a chamada a
  `admin.auth().createProviderConfig`/`updateProviderConfig` em try/catch — falha persiste
  `status: 'invalid_config'` + `lastConfigError` e responde `failed-precondition`, nunca finge
  sucesso; `resolveSsoForEmail`/`completeSsoLogin` só consideram conexões `status === 'active'`.
- Login SSO nunca reseta um papel já alterado por um admin: em logins subsequentes, `completeSsoLogin`
  só atualiza `name`/`email`/`updatedAt`; `roleId`/`roleName`/`teamIds`/`status` são preservados.
- Uma Membership `inactive` nunca é reativada silenciosamente por um login SSO (mesma postura
  fail-closed de `loadActiveMembership`).
- `completeSsoLogin` só é aceito para uma sessão realmente autenticada via provedor federado
  (`request.auth.token.firebase.sign_in_provider` prefixado `saml.`/`oidc.`) — uma sessão comum
  e-mail/senha não pode chamá-la para se autoprovisionar.

## Regras Firebase implementadas

- `firestore.rules`: `organizations/{organizationId}/ssoConnections/{connectionId}` — leitura e
  escrita sempre negadas ao cliente (`allow read, write: if false`), mesmo padrão de
  `webhookSecrets`/`apiKeys`. Toda leitura/escrita real acontece só via Admin SDK dentro das 3 Cloud
  Functions.
- `Capability.ssoManage` (novo) gate a Cloud Function `configureSsoConnection` — concedida
  automaticamente a `OWNER`/`ADMIN` via `RolePermissionMatrix` (nenhuma edição na matriz foi
  necessária: `_ownerCapabilities`/`_adminCapabilities` já cobrem `Capability.values` inteiro menos
  `organizationTransferOwnership`).

## Analytics implementado

- Evento `loginCompleted` (já existente) agora também é disparado no sucesso do fluxo SSO, com
  `method: 'sso'` — nunca e-mail/uid/organizationId (LGPD, `AGENTS.md`).

## Crashlytics implementado

- Nenhuma mudança dedicada; erros do fluxo SSO propagam como `Failure`s tratadas normalmente pelo
  `CrashReporter`/`AppLogger` já centralizados (nenhum `print`/log solto introduzido).

## Impacto offline

- Nenhum: login (com ou sem SSO) sempre exige conectividade; nenhuma entidade sincronizável/Outbox
  foi tocada.

## Impacto multi-tenant

- Central ao escopo da task: `ssoConnections` é subcoleção de `organizations/{organizationId}`;
  domínios de e-mail são validados como globalmente únicos entre organizações na configuração;
  `completeSsoLogin` só resolve a organização certa a partir do `providerId` do token federado e
  revalida o domínio do e-mail contra a conexão encontrada.

## Testes criados

- `functions/test/sso/sso-shared.test.ts` — 33 testes de lógica pura (RBAC, validação de
  `defaultRoleName`/protocolo/domínios/SAML/OIDC, `buildProviderId`, `isFederatedSignInProvider`).
- `functions/test/sso/configure-sso-connection.test.ts` — RBAC (só OWNER/ADMIN), rejeita
  `defaultRoleName` OWNER/ADMIN, rejeita domínio já usado por outra organização (isolamento), sucesso
  persiste `status: active`, falha do Identity Platform (IdP mock) persiste `status: invalid_config`
  sem conceder acesso.
- `functions/test/sso/resolve-sso-for-email.test.ts` — resolve a conexão certa, isolamento entre
  organizações, `null` para domínio desconhecido/conexão inativa.
- `functions/test/sso/complete-sso-login.test.ts` — JIT cria Membership com `defaultRoleName`
  correto no primeiro login (IdP de teste/mock simulando claims federados), rejeita quando
  `sign_in_provider` não é federado, preserva role em login subsequente, nunca reativa Membership
  `inactive`.
- `firestore-tests/firestore.rules.test.js` — negação total de `ssoConnections` a qualquer papel,
  incluindo isolamento cross-tenant.
- `test/features/sso/**` (Flutter) — dtos, mapper, `SsoRepositoryImpl`,
  `SignInWithCorporateSsoUseCase` (sucesso, e-mail sem conexão, falha de autenticação, falha de
  `completeSsoLogin`).
- `test/core/auth/...` — `signInWithFederatedProvider` (datasource/repositório/mapper de exceção).
- `test/features/authentication/presentation/bloc/login_bloc_test.dart` e
  `.../pages/login_page_test.dart` — novos casos para o fluxo SSO (bloc e widget).
- `test/core/permissions/role_permission_matrix_test.dart` — cobre `Capability.ssoManage`.

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx eslint src/sso test/sso
cd functions && npx jest test/sso/sso-shared.test.ts
cd functions && npx jest
npx firebase deploy --only firestore:rules --dry-run
npx firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test
flutter analyze
flutter test test/features/sso test/core/auth test/core/permissions test/features/authentication test/app/injection_test.dart
flutter test test/features/invites/presentation/pages/accept_invite_page_test.dart test/features/onboarding
```

## Resultado do formatter

`dart format --set-exit-if-changed lib test` — limpo (sem alterações pendentes).

## Resultado do analyzer

`flutter analyze` — 15 issues, todos pré-existentes em arquivos não tocados por esta task (nenhum
issue novo introduzido pela TASK-173).

## Resultado dos testes

- `npx tsc --noEmit` (functions) — sem erros.
- `npx eslint src/sso test/sso` (functions) — sem erros.
- `npx jest test/sso/sso-shared.test.ts` — 33/33 passando (lógica pura, sem emulador).
- `npx jest` (suíte completa de `functions/`) — 27 suites passaram (incl. `sso-shared.test.ts`); 24
  suites falharam por `Could not load the default credentials` (falta de Firestore Emulator/Java no
  ambiente), incluindo as 3 novas suites de `sso/` dependentes do emulador e 21 suites pré-existentes
  não relacionadas (`accept-invite`, `create-organization`, `submit-order` etc.) — confirmado que
  essas 21 já falhavam por essa mesma causa antes desta task.
- `flutter test test/features/sso test/core/auth test/core/permissions test/features/authentication
  test/app/injection_test.dart` — 224/224 passando.
- `flutter test test/features/invites/presentation/pages/accept_invite_page_test.dart
  test/features/onboarding` — 50/50 passando (arquivos que só ganharam o stub novo do contrato de
  `AuthRepository`).
- `npx firebase deploy --only firestore:rules --dry-run` — `firestore.rules` compilou com sucesso.
- `npx firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` — falhou por
  `java: command not found` (mesma limitação de ambiente já documentada em
  `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md`); os casos de
  `firestore-tests/firestore.rules.test.js` para `ssoConnections` foram escritos mas não executados
  aqui.

## Decisões técnicas

- Escopo da UI de administração do IdP (cadastro de metadata SAML/OIDC pelo gestor) explicitamente
  adiado, seguindo o mesmo precedente já aceito em TASK-169/170/171 (EPIC-22): a Cloud Function
  `configureSsoConnection` existe e está pronta para uma tela futura, mas nenhuma tela foi construída
  nesta rodada — ver "Pendências".
- `defaultRoleName` só proíbe `OWNER`/`ADMIN` (não `SALES_MANAGER`), porque `RolePermissionMatrix`
  nunca concede a `SALES_MANAGER` capacidades administrativas (`organizationSettingsManage`/
  `roleManage`) — uma organização pode legitimamente escolher `SALES_MANAGER` como papel padrão de
  self-service mais permissivo, sem violar "nunca papel administrativo por padrão".
- `providerId` é sempre `<protocol>.<connectionId>` (prefixo exigido pelo Identity Platform),
  garantindo unicidade por construção (ids do Firestore já são únicos).
- Login SSO bem-sucedido não passa por `ResolveActiveOrganizationIdUseCase` (usado no login
  e-mail/senha): `completeSsoLogin` já devolve a organização confirmada server-side, então o
  `LoginBloc` usa esse valor diretamente — evita uma segunda fonte de verdade sobre qual organização
  é a "ativa" logo após um login SSO.

## Riscos conhecidos

- `configureSsoConnection` só funciona ponta a ponta quando o Identity Platform estiver habilitado
  no projeto Firebase real (recurso pago/Blaze) — em qualquer ambiente sem isso habilitado, toda
  configuração persiste como `status: invalid_config` (comportamento seguro e esperado, não é bug).
- Não foi validado neste ambiente (sem Java/emulador) se o Firebase Auth Emulator suporta
  `createProviderConfig`/`updateProviderConfig` para SAML/OIDC — recomendo validar ao rodar
  `functions/test/sso/configure-sso-connection.test.ts` numa máquina/CI com Java.

## Pendências

- Tela de administração (portal admin) para o gestor cadastrar/editar a metadata do IdP, ver
  `status`/`lastConfigError` e desativar uma conexão — trabalho de UI futuro, provavelmente com
  `flutter-ui-design-specialist` (mesma pendência documentada em TASK-170).
- Desativação automática de acesso quando removido no IdP corporativo: a task só pede documentar o
  caminho equivalente — hoje um `OWNER`/`ADMIN` precisa desativar o usuário manualmente via
  `deactivateUser` (TASK-033); `completeSsoLogin` já nunca reativa uma Membership `inactive`
  silenciosamente.
- Testes de Firestore Emulator (`firestore-tests/firestore.rules.test.js` e as 3 suites de Cloud
  Functions de `sso/` dependentes do Firestore) não executáveis neste ambiente por falta de Java —
  mesma limitação de `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md`. Recomendo
  rodar via `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` e
  `npx jest test/sso` numa máquina/CI com Java.

## Evidências

Ver "Comandos executados" e "Resultado dos testes" acima — saídas reais coletadas durante a
execução desta task (nenhum resultado foi presumido).

## Commit

Local apenas (push não autorizado nesta rodada) — ver hash abaixo.

## Push

Não realizado (sem autorização nesta rodada).

## Hash do commit

Ver mensagem de commit `feat(auth): implementa sso corporativo saml/oidc (TASK-173)`.

## Branch

`main`
