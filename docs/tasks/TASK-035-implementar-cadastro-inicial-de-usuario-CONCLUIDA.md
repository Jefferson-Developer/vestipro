# TASK-035 — Concluída (2026-08-23)

## Resumo

Implementado o cadastro inicial de usuário (nome, e-mail, senha, confirmação de senha e aceite
obrigatório dos Termos de Uso/Política de Privacidade), reaproveitando ao máximo a base deixada pela
TASK-034 (`AuthRepository`, mapeamento de exceções do Firebase Auth, padrão de BLoC/Cubit e
componentes de Design System). A conta é criada no Firebase Auth e um documento de perfil básico
(`users/{uid}`) é persistido no Firestore com evidência de consentimento (versão do termo + timestamp
do aceite), sem vincular nenhuma Organization — isso é escopo exclusivo da TASK-037. Após sucesso, o
usuário é redirecionado para a rota (ainda não implementada) do wizard de onboarding.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, Firebase Auth, Firestore Rules, testes).
- `flutter-ui-design-specialist` (tela `SignUpPage`/`SignUpForm`, novo componente `AppCheckbox` no
  Design System, responsividade compact/wide seguindo o padrão de `LoginPage`).

## Arquivos criados

- `lib/core/design_system/components/inputs/app_checkbox.dart` — novo componente de Design System
  (checkbox com label/rich label, error text e estado desabilitado).
- `lib/features/authentication/domain/entities/user_profile.dart` (+ `.freezed.dart`)
- `lib/features/authentication/domain/repositories/user_profile_repository.dart`
- `lib/features/authentication/domain/usecases/create_account_with_email_and_password_use_case.dart`
- `lib/features/authentication/domain/validators/sign_up_form_validators.dart`
- `lib/features/authentication/domain/value_objects/terms_of_service_version.dart`
- `lib/features/authentication/data/dtos/user_profile_dto.dart`
- `lib/features/authentication/data/mappers/user_profile_mapper.dart`
- `lib/features/authentication/data/datasources/user_profile_data_source.dart`
- `lib/features/authentication/data/datasources/firestore_user_profile_data_source.dart`
- `lib/features/authentication/data/repositories/user_profile_repository_impl.dart`
- `lib/features/authentication/presentation/bloc/sign_up_event.dart` (+ `.freezed.dart`)
- `lib/features/authentication/presentation/bloc/sign_up_state.dart` (+ `.freezed.dart`)
- `lib/features/authentication/presentation/bloc/sign_up_bloc.dart`
- `lib/features/authentication/presentation/pages/sign_up_page.dart`
- `lib/features/authentication/presentation/widgets/sign_up_form.dart`
- Testes: `test/core/design_system/components/inputs/app_checkbox_test.dart`,
  `test/features/authentication/domain/entities/user_profile_test.dart`,
  `test/features/authentication/domain/validators/sign_up_form_validators_test.dart`,
  `test/features/authentication/domain/usecases/create_account_with_email_and_password_use_case_test.dart`,
  `test/features/authentication/data/dtos/user_profile_dto_test.dart`,
  `test/features/authentication/data/mappers/user_profile_mapper_test.dart`,
  `test/features/authentication/data/datasources/firestore_user_profile_data_source_test.dart`,
  `test/features/authentication/data/repositories/user_profile_repository_impl_test.dart`,
  `test/features/authentication/presentation/bloc/sign_up_bloc_test.dart`,
  `test/features/authentication/presentation/pages/sign_up_page_test.dart`.
- `docs/tasks/TASK-035-implementar-cadastro-inicial-de-usuario-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `firestore.rules` — novo bloco `match /users/{userId}` (perfil básico, fora do escopo de
  Organization).
- `firestore-tests/firestore.rules.test.js` — 8 novos testes positivos/negativos para
  `users/{userId}`.
- `lib/app/bootstrap.dart` — wiring do `signUpPageBuilder` no `AppRouter`/`VestiProApp`.
- `lib/app/injection.config.dart` — regenerado pelo `injectable_generator` (novos providers:
  `CreateAccountWithEmailAndPasswordUseCase`, `UserProfileMapper`, `FirestoreUserProfileDataSource`,
  `UserProfileRepositoryImpl`, `SignUpBloc`).
- `lib/core/analytics/analytics_events.dart` — novo evento `sign_up_completed`.
- `lib/core/auth/domain/repositories/auth_repository.dart`,
  `lib/core/auth/data/datasources/auth_data_source.dart`,
  `lib/core/auth/data/datasources/firebase_auth_data_source.dart`,
  `lib/core/auth/data/repositories/auth_repository_impl.dart` — novo método
  `createUserWithEmailAndPassword`.
- `lib/core/design_system/components/components.dart` — export do novo `AppCheckbox`.
- `lib/core/navigation/app_route_paths.dart` — novas rotas `SignUpRoute`, `OnboardingWizardRoute`
  (placeholder para TASK-037/038) e `TermsOfServiceRoute` (placeholder para TASK-156).
- `lib/core/navigation/app_router.dart` — registro de `SignUpRoute` e `signUpPageBuilder`.
- `lib/features/authentication/authentication.dart` — export de `SignUpPage`.
- `lib/features/authentication/presentation/widgets/login_form.dart` — link recíproco "Criar conta"
  para `SignUpRoute`.
- Testes ajustados para a nova assinatura de `AuthRepository`/`AppRouter`: `test/core/analytics/analytics_events_test.dart`,
  `test/core/auth/data/repositories/auth_repository_impl_test.dart`,
  `test/core/navigation/app_router_test.dart`, `test/core/navigation/session_auth_guard_test.dart`,
  `test/features/authentication/presentation/bloc/login_bloc_test.dart`,
  `test/features/authentication/presentation/pages/login_page_test.dart`.
- `docs/tasks/TASKS.md` — checkbox da TASK-035 marcado e progresso atualizado para 35/220.

## Arquitetura utilizada

Clean Architecture + feature-first, seguindo exatamente o padrão da TASK-034:
`SignUpPage` → `SignUpBloc` → `CreateAccountWithEmailAndPasswordUseCase` → `AuthRepository` +
`UserProfileRepository` (contratos) → `AuthRepositoryImpl`/`UserProfileRepositoryImpl` →
`FirebaseAuthDataSource`/`FirestoreUserProfileDataSource`. Nenhum tipo do `firebase_auth`/
`cloud_firestore` escapa da camada `data/`. `UserProfileRepository` é um contrato novo e deliberadamente
estreito (só `createInitialProfile`), assim como `OrganizationRepository` é estreito em torno de
`create`/`getById`/`updateSettings`.

## Regras de negócio implementadas

- Nome obrigatório (mínimo 2 caracteres), e-mail em formato válido, senha com política mínima (8+
  caracteres, letras e números) e confirmação de senha igual à senha — tudo validado no domain
  (`sign_up_form_validators.dart`), antes de qualquer chamada ao Firebase Auth.
- Checkbox de aceite de termos obrigatório: o botão "Criar conta" fica desabilitado enquanto
  `termsAccepted` for `false`; um `termsError` de defesa em profundidade cobre qualquer tentativa de
  `submitted` que burle a UI.
- Consentimento registrado como parte do próprio perfil (`UserProfile.termsVersion` +
  `termsAcceptedAt`), com timestamp e versão do termo (`kCurrentTermsOfServiceVersion`) — o conteúdo
  real dos termos é escopo da TASK-156 (EPIC-20); esta task só consome o link e grava o aceite.
- Nenhuma Organization é criada ou vinculada nesta task (escopo exclusivo da TASK-037).
- Bloqueio de duplo envio (`droppable` no bloc + tap-lock do `AppButton`); campos nunca são limpos após
  um erro.
- Mapeamento de `email-already-in-use`, senha fraca e falhas de rede para mensagens em português via
  `firebase_auth_exception_mapper.dart` (já existente, reaproveitado sem alteração).
- Se a conta é criada no Firebase Auth mas a escrita do perfil falha, o caso de uso desloga o usuário
  (`AuthRepository.signOut`) para não deixar uma sessão "meio onboardada" — ver riscos conhecidos.

## Regras Firebase implementadas

Novo bloco `match /users/{userId}` em `firestore.rules`:

- `get`: só o próprio usuário (`request.auth.uid == userId`).
- `list`: sempre `false` (nunca listar todos os usuários por query aberta).
- `create`: só o próprio usuário, com `uid` do payload igual ao `userId` do path e `name`/`email`/
  `termsVersion` não vazios — nunca confiando em nenhum campo do payload como autorização isolada.
- `update`/`delete`: `false` (edição de perfil é responsabilidade de uma task futura).

Validado com 8 novos testes positivos/negativos no Firebase Emulator (ver seção de testes).

## Analytics implementado

Novo evento `sign_up_completed` em `AnalyticsEvents`, disparado pelo `SignUpBloc` só em caso de
sucesso, com `method: 'email'` e `platform` — nunca nome, e-mail ou uid (mesma restrição de LGPD já
aplicada ao `login_completed`).

## Crashlytics implementado

Nenhuma instrumentação nova necessária: exceções inesperadas continuam cobertas pelos handlers globais
já configurados em `bootstrap.dart` (`configureGlobalErrorHandlers`), e todo erro esperado (validação,
Firebase Auth, Firestore) já é convertido em `Failure`/mensagem amigável antes de chegar à UI.

## Impacto offline

Fluxo de cadastro depende de conectividade (cria conta no Firebase Auth + documento no Firestore);
falha de rede é mapeada para `ConnectivityFailure` e exibida via `AppSnackbar`, sem perda dos campos
digitados. Não há escrita local/Outbox aqui — criação de conta não é uma operação comercial offline-
first (é pré-requisito para logar, e exige o backend).

## Impacto multi-tenant

Nenhum: o perfil criado (`users/{uid}`) é global, sem `organizationId` — o usuário só passa a
pertencer a um tenant na TASK-037 (criação da Organization) e TASK-039 (convite). O isolamento aqui é
por identidade (uid), não por tenant.

## Testes criados

- `sign_up_form_validators_test.dart`: nome, e-mail, senha (comprimento/complexidade) e confirmação de
  senha — sucesso, nulos, vazios e limites.
- `user_profile_test.dart`: igualdade, `copyWith`, evidência de consentimento (versão + timestamp).
- `user_profile_dto_test.dart`/`user_profile_mapper_test.dart`: serialização Firestore, `uid` como
  campo (necessário pelas rules) e mapeamento completo indo e voltando.
- `firestore_user_profile_data_source_test.dart`: escrita idempotente (`set`, não `create`-only),
  mapeamento de `FirebaseException`.
- `user_profile_repository_impl_test.dart`: sucesso e mapeamento de falhas (`AppException`/genérica).
- `create_account_with_email_and_password_use_case_test.dart`: sucesso completo (com verificação do
  perfil capturado, incluindo `termsVersion`/`termsAcceptedAt`), falha de e-mail já em uso sem criar
  perfil, e rollback (`signOut`) quando a conta é criada mas o perfil falha.
- `sign_up_bloc_test.dart`: todos os `bloc_test` pedidos pela task — sucesso, e-mail já em uso, senhas
  divergentes, falha de rede, submit sem aceitar os termos, toggle de visibilidade e concorrência
  (`droppable`).
- `sign_up_page_test.dart`: checkbox bloqueando o envio, mensagens de erro por campo, navegação após
  sucesso/falha, link de volta para o login.
- `app_checkbox_test.dart`: novo componente de Design System.
- Ajustes em testes existentes (`AuthRepository`/`AppRouter`) para a nova assinatura/parâmetro
  obrigatório.
- 8 novos testes de Firestore Rules (`firestore.rules.test.js`) para `users/{userId}`.

## Comandos executados

```bash
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd firestore-tests && npm install
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
```

## Resultado do formatter

```text
Formatted 449 files (0 changed) in 1.63 seconds.
```

## Resultado do analyzer

```text
Analyzing VestiPro...
No issues found! (ran in 10.6s)
```

## Resultado dos testes

`flutter test` (suíte completa):

```text
00:25 +773: All tests passed!
```

`firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`:

```text
Test Suites: 1 passed, 1 total
Tests:       50 passed, 50 total (42 já existentes + 8 novos de users/{userId})
Time:        4.292 s
```

## Decisões técnicas

- `UserProfile` (`users/{uid}`) foi modelado como coleção raiz do Firestore, fora de qualquer
  `organizations/{organizationId}`, seguindo o mesmo precedente de `OrganizationDataSource`
  (`FirestoreOrganizationDataSource` também não usa `FirestoreCollectionDataSource` por não ter
  tenant ainda).
- `AuthRepository.createUserWithEmailAndPassword` foi adicionado ao contrato já existente (em vez de
  criar um repositório de auth paralelo), mantendo `SessionUser` como única fronteira de sessão.
- Consentimento de termos foi embutido no próprio `UserProfile` (campos `termsVersion`/
  `termsAcceptedAt`) em vez de uma coleção de auditoria de consentimento separada — suficiente para o
  critério de aceite desta task ("registrado com timestamp e versão"); uma trilha de auditoria mais
  rica (histórico de todas as aceitações) fica para o EPIC-20 se for exigida.
- `OnboardingWizardRoute` e `TermsOfServiceRoute` foram declaradas com o mesmo padrão já usado por
  `PasswordResetRoute` antes da TASK-036: rota tipada existente, mas ainda não registrada como
  `GoRoute` real — cai no `NotFoundRoute`/`errorBuilder` até TASK-037/038 e TASK-156 existirem.
- Foi criado o componente `AppCheckbox` no Design System (não existia) por ser pré-requisito direto do
  aceite de termos e ser reutilizável por telas futuras (ex.: preferências no wizard de onboarding).
- Foi adicionado um link recíproco "Criar conta" na tela de login (`LoginForm`), fora do escopo
  literal da task, mas necessário para a experiência real do fluxo the-onboarding ser navegável nos
  dois sentidos — mesmo padrão de link cruzado já usado por "Esqueci minha senha".

## Riscos conhecidos

- Se a conta é criada no Firebase Auth mas a escrita subsequente do perfil falhar (ex.: rede cai no
  meio), o caso de uso desloga o usuário para não deixar uma sessão "meio onboardada", mas uma nova
  tentativa de cadastro com o mesmo e-mail falhará com `email-already-in-use` — não há hoje um fluxo de
  "retomar cadastro"/criar perfil a partir do login. Fica registrado como gap até uma task dedicada de
  retomada de onboarding (TASK-037/TASK-041) existir.
- `roleHasCapability`/regras de `users/{userId}` não têm relação com RBAC (usuário ainda não pertence
  a nenhuma organização) — o isolamento aqui é só "é o próprio uid", o que é suficiente para o escopo
  desta task, mas precisa ser revisitado se um dia perfis puderem ser lidos por terceiros (ex.: um
  ADMIN listando usuários pendentes de convite).
- Não foi executado `flutter build web`/`flutter build appbundle` (não estritamente exigido pela task;
  `flutter analyze` + suíte completa de testes de widget/bloc já cobrem o código novo).

## Pendências

- Nenhuma pendência bloqueante para esta task. TASK-037 (criação da Organization) e TASK-038 (wizard)
  precisarão registrar as rotas `OnboardingWizardRoute`/`TermsOfServiceRoute` como `GoRoute` reais.

## Evidências

- `flutter test` → `773` testes, `0` falhas.
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` → `50` testes,
  `0` falhas.
- `flutter analyze` → `No issues found!`.
- `dart format --set-exit-if-changed .` → `0 changed`.

## Commit

Criado ao final desta resposta (commit local, sem push).

## Push

Não realizado — sem autorização nesta conversa.

## Hash do commit

Ver resposta final.

## Branch

`main`
