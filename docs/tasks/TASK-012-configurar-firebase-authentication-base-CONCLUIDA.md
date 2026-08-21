# TASK-012 — Concluída (2026-08-21)

## Resumo

Infraestrutura de autenticação criada em `lib/core/auth/` (Clean Architecture: domínio, dados,
mapeamento de erros), sem nenhuma tela — login real fica para a TASK-034, conforme escopo da task.
`AuthRepository`/`AuthDataSource` isolam `firebase_auth` do resto do app; `FirebaseAuthException` é
convertida para a hierarquia `AppException`/`Failure` já existente, sem precisar de novos tipos.
`SessionAuthGuard` foi criado para substituir o stub `AlwaysAllowAuthGuard` do `go_router`, mas
**não foi ligado por padrão** em `lib/app/bootstrap.dart` — decisão explícita documentada em
"Decisões técnicas". O Auth Emulator é conectado automaticamente para os flavors `dev`/`staging`
(ADR-0002), a partir do momento em que a instância de `FirebaseAuthDataSource` é resolvida pelo
container de DI.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/auth/domain/entities/session_user.dart` (+ `session_user.freezed.dart`, gerado)
- `lib/core/auth/domain/value_objects/auth_provider_type.dart`
- `lib/core/auth/domain/repositories/auth_repository.dart`
- `lib/core/auth/data/dtos/auth_user_dto.dart`
- `lib/core/auth/data/datasources/auth_data_source.dart`
- `lib/core/auth/data/datasources/firebase_auth_data_source.dart`
- `lib/core/auth/data/mappers/auth_user_mapper.dart`
- `lib/core/auth/data/mappers/firebase_auth_exception_mapper.dart`
- `lib/core/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/auth/auth.dart` (barrel público do módulo)
- `lib/core/navigation/session_auth_guard.dart`
- `lib/core/environment/firebase_emulator_host.dart`
- `lib/core/environment/firebase_emulator_ports.dart`
- `test/core/auth/domain/domain_import_boundary_test.dart`
- `test/core/auth/data/mappers/firebase_auth_exception_mapper_test.dart`
- `test/core/auth/data/mappers/auth_user_mapper_test.dart`
- `test/core/auth/data/repositories/auth_repository_impl_test.dart`
- `test/core/navigation/session_auth_guard_test.dart`
- `integration_test/core/auth/firebase_auth_data_source_integration_test.dart`
- `docs/tasks/TASK-012-configurar-firebase-authentication-base-CONCLUIDA.md`

## Arquivos alterados

- `lib/core/navigation/app_route_paths.dart` (novo `LoginRoute`, sem `GoRoute` registrado ainda)
- `lib/core/navigation/navigation.dart` (exporta `session_auth_guard.dart`)
- `lib/app/injection_module.dart` (`@lazySingleton FirebaseAuth get firebaseAuth`)
- `lib/app/injection.config.dart` (regenerado por `build_runner`, registra `AuthRepository`,
  `AuthDataSource`, `AuthUserMapper`, `FirebaseAuth`)
- `pubspec.yaml` / `pubspec.lock` (dev dependency `integration_test` — necessária para o teste de
  integração exigido pela task)
- `README.md` (seção "Backend e Firebase": Auth já conectado ao emulador, e onde/por quê)
- `docs/tasks/TASKS.md` (checkbox da TASK-012 e progresso)

## Arquitetura utilizada

Clean Architecture feature-first, igual ao padrão já estabelecido em `lib/features/settings/`:
`AuthRepository` (contrato de domínio) → `AuthRepositoryImpl` (converte `AppException` em `Failure`
via `AppResult`, mesmo código genérico de `mapAppExceptionToFailure` já usado por
`AboutAppRepositoryImpl`) → `AuthDataSource` (contrato de dados) → `FirebaseAuthDataSource`
(único ponto que importa `firebase_auth`). DTO (`AuthUserDto`) e mapper (`AuthUserMapper`) isolam o
tipo `User` do SDK da entidade de domínio `SessionUser` (`freezed`, como `AboutApp`). Teste de
fronteira (`domain_import_boundary_test.dart`) garante que `lib/core/auth/domain/` nunca importa
`flutter`/`firebase`/`drift`, no mesmo padrão já usado por `features/settings/domain`.

`AuthProviderType` (enum: `emailAndPassword`, `google`, `apple`, `corporateSso`) e
`AuthRepository.signInWithProvider` implementam a extensibilidade pedida pela task para provedores
futuros (Google/Apple/SSO corporativo da TASK-173): hoje todo provider retorna uma `Failure`
`auth_provider_not_supported` — inclusive `emailAndPassword`, que deve usar
`signInWithEmailAndPassword` (métodos separados porque só e-mail/senha precisa de credenciais como
parâmetro; os demais fazem fluxo nativo/OAuth sem elas).

## Regras de negócio implementadas

- Nenhuma regra de negócio de produto (task de infraestrutura). Regra de arquitetura: nenhuma
  camada fora de `lib/core/auth/data/` pode importar `firebase_auth` — reforçado pelo teste de
  fronteira do domínio e pela ausência de qualquer outro import de `firebase_auth` em `lib/`.
- Nenhum token de sessão é persistido manualmente (nem em `shared_preferences`, nem em
  `flutter_secure_storage`): a task pede infraestrutura pronta para a TASK-041 usar
  `flutter_secure_storage` quando a persistência local de sessão for de fato implementada; até lá,
  a própria sessão do SDK `firebase_auth` (que já persiste nativamente) é a única fonte de verdade.

## Regras Firebase implementadas

- Provedor e-mail/senha é o único mapeado nesta task (`FirebaseAuthDataSource`); o Auth Emulator
  Suite já habilita esse provedor por padrão, sem configuração extra em `firebase.json`.
- ADR-0002: `FirebaseAuthDataSource` chama `useAuthEmulator(host, 9099)` para todo flavor que não
  seja `prod`, usando `resolveFirebaseEmulatorHost()` (localhost fora do Android, `10.0.2.2` no
  emulador Android) e `FirebaseEmulatorPorts.auth` — ambos em `lib/core/environment/`, reutilizáveis
  pelas TASK-013 (Firestore), TASK-014 (Storage) e TASK-015 (Functions).

## Analytics implementado

Nenhum (fora do escopo desta task; TASK-017). Nenhum dado de e-mail/senha é logado.

## Crashlytics implementado

Nenhum (TASK-016). Falhas de auth são mapeadas para `Failure`s tipadas em vez de crashar ou vazar
`FirebaseAuthException` para camadas superiores.

## Impacto offline

Nenhuma mudança de comportamento offline existente. `authStateChanges`/`currentUser` refletem o
cache local do próprio SDK `firebase_auth` (que já funciona offline para sessão já autenticada);
`signInWithEmailAndPassword`/`sendPasswordResetEmail` exigem rede, como sempre exigiram no SDK.

## Impacto multi-tenant

Nenhum ainda: `Organization`/`organizationId` só existem a partir da TASK-026/037.
`ActiveOrganizationGuard` continua como stub; `SessionAuthGuard` cobre apenas autenticação, não
autorização por tenant.

## Testes criados

- `domain_import_boundary_test.dart`: `lib/core/auth/domain/` nunca importa Flutter/Firebase/Drift.
- `firebase_auth_exception_mapper_test.dart`: cada código relevante do `firebase_auth`
  (`user-not-found`, `wrong-password`, `invalid-credential`, `invalid-email`, `user-disabled`,
  `network-request-failed`, `too-many-requests`, `email-already-in-use`, `weak-password`,
  `operation-not-allowed`, código desconhecido) mapeia para o `AppException` esperado, e todos
  convertem para uma `Failure` via `mapAppExceptionToFailure` sem quebrar o `switch` exaustivo.
- `auth_user_mapper_test.dart`: `AuthUserDto` → `SessionUser`, incluindo campos nulos.
- `auth_repository_impl_test.dart`: `currentUser`/`authStateChanges` mapeando DTO → entidade (cobre
  o requisito "stream emite autenticado/não autenticado corretamente"); `signInWithEmailAndPassword`
  (sucesso, `AppException` → `Failure`, exceção genérica → `UnexpectedFailure`);
  `signInWithProvider` retornando falha para todo provider, sem tocar o datasource;
  `signOut`/`sendPasswordResetEmail` (sucesso e erro).
- `session_auth_guard_test.dart`: sessão autenticada permite navegação; sem sessão redireciona para
  `LoginRoute` (cai na página "não encontrada" hoje, pois a tela de login é da TASK-034); uma
  requisição já destinada a `LoginRoute` não gera loop de redirecionamento.
- `integration_test/core/auth/firebase_auth_data_source_integration_test.dart`: teste real de
  integração contra o Firebase Auth Emulator (login válido e inválido) — ver "Riscos conhecidos"
  sobre por que não pôde ser executado de ponta a ponta nesta sessão.

## Comandos executados

```bash
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --target lib/main_dev.dart --output build/web-dev-check
flutter build apk --debug --flavor dev -t lib/main_dev.dart
firebase emulators:start --only auth --project vestipro
flutter test integration_test/core/auth/firebase_auth_data_source_integration_test.dart -d chrome
flutter test integration_test/core/auth/firebase_auth_data_source_integration_test.dart -d windows
```

## Resultado do formatter

`Formatted 91 files (1 changed)` (fixou apenas o arquivo de teste de integração recém-criado).

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

`flutter test`: 66 testes, todos passaram (60 pré-existentes + testes novos desta task: fronteira de
domínio, mapper de exceções, mapper de usuário, repositório e guard).

`flutter build web`/`flutter build apk --flavor dev` concluíram com sucesso (evidência de que o novo
código compila nos targets Web e Android).

O teste de integração real contra o Auth Emulator **não pôde ser executado de ponta a ponta** nesta
sessão — ver "Riscos conhecidos".

## Decisões técnicas

- **`SessionAuthGuard` não foi ligado por padrão em `VestiProApp`/`bootstrap.dart`.** Tentei
  conectar (`AppRouter(authGuard: SessionAuthGuard(getIt<AuthRepository>()))`) e o teste existente
  `test/app/bootstrap_test.dart` (`bootstrap initializes Firebase exactly once and renders
  VestiProApp`) **travou indefinidamente** (>180s) ao resolver `FirebaseAuth.instance` sem um mock
  de plataforma para `firebase_auth` — o mesmo tipo de travamento que a TASK-011 já tinha
  documentado para canais de plataforma sem handler registrado. `firebase_auth_platform_interface`,
  diferente de `firebase_core_platform_interface`, **não expõe um `test.dart` público** para mockar
  o host nativo, então não há hoje um jeito limpo de simular esse SDK em teste de widget. Revertido:
  `AppRouter` continua com `AlwaysAllowAuthGuard` como padrão (guard real, testado, disponível via
  parâmetro), e a troca real fica para a TASK-034 (quando a tela de login existir — hoje redirecionar
  para `/login` só mostraria a página "não encontrada", uma regressão sem contrapartida).
- Pela mesma razão, a conexão com o Auth Emulator **não fica em `bootstrap.dart`** (que roda sempre,
  em todo teste de widget), e sim no construtor de `FirebaseAuthDataSource` — só executa quando algo
  de fato resolve `AuthRepository`/`AuthDataSource` via DI, o que hoje não acontece em nenhum teste
  existente. A chamada usa `unawaited` (não pode bloquear a resolução do singleton em um getter
  síncrono do `injectable`); documentado no próprio código.
- `AuthProviderType`/`signInWithProvider` cobrem a extensibilidade pedida pela task sem
  sobre-engenharia: um enum e um método, sem hierarquia de credenciais especulativa para provedores
  que ainda não existem.
- Erros de `firebase_auth` reaproveitam 100% a hierarquia `AppException`/`Failure` já existente
  (nenhum tipo novo necessário) — `user-not-found`/`wrong-password` → `UnauthorizedException` →
  `AuthenticationFailure`; `network-request-failed` → `NetworkException` → `ConnectivityFailure`,
  exatamente como pedido pelos testes obrigatórios da task.
- `resolveFirebaseEmulatorHost()`/`FirebaseEmulatorPorts` ficaram em `lib/core/environment/` (não em
  `lib/core/auth/`) porque TASK-013/014/015 vão precisar do mesmo host/portas para
  Firestore/Storage/Functions — evita duplicar essa lógica quatro vezes.

## Riscos conhecidos

- **O teste de integração real contra o Auth Emulator não foi executado de ponta a ponta nesta
  sessão.** Tentativas reais e não simuladas:
  - `flutter test integration_test/... -d chrome`: falhou com "Web devices are not supported for
    integration tests yet." (limitação do próprio pacote `integration_test`, não do código).
  - `flutter test integration_test/... -d windows`: falhou com "No Windows desktop project
    configured" — o projeto nunca teve suporte a desktop Windows adicionado (TASK-001/002 só
    configuraram Android/iOS/Web), e adicioná-lo agora só para validar este teste estaria fora do
    escopo da TASK-012.
  - Não há emulador Android nem host macOS disponíveis nesta máquina (mesma limitação já registrada
    em TASK-010/TASK-011), e `flutter test --platform chrome`/`flutter drive` com `chromedriver` não
    é viável sem instalar um `chromedriver` compatível (não presente na máquina).
  - `flutter analyze` confirma que o arquivo de teste de integração compila e tipa corretamente; o
    Auth Emulator foi de fato iniciado e validado via `curl` (HTTP 200) durante esta sessão — só a
    execução do teste Flutter contra ele não foi possível no ambiente atual.
  - Fica como pendência real (não simulada como concluída): executar
    `firebase emulators:exec "flutter test integration_test/core/auth/... -d chrome"` em uma máquina
    com `chromedriver` instalado, ou em CI com um dispositivo Android/iOS real.
- `SessionAuthGuard` existe e está testado, mas **não está conectado no app real** — ver "Decisões
  técnicas". Isso significa que, até a TASK-034, nenhuma rota do app exige sessão de fato (mesmo
  comportamento que já existia antes desta task).
- `lib/firebase_options.dart` continua gitignorado (ADR-0002); herda a mesma pendência de geração
  local já registrada nas TASK-010/011.

## Pendências

- TASK-034 deve trocar `AlwaysAllowAuthGuard` por `SessionAuthGuard(getIt<AuthRepository>())` na
  composição de `VestiProApp`/`bootstrap.dart` quando a tela de login existir.
- Validar `integration_test/core/auth/firebase_auth_data_source_integration_test.dart` de ponta a
  ponta em um ambiente com `chromedriver` ou dispositivo Android/iOS real.
- Push depende de autorização explícita do usuário.

## Evidências

- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!` (66 testes).
- `flutter build web --target lib/main_dev.dart --output build/web-dev-check` → `Built
  build\web-dev-check` (removido após a validação, é apenas saída de build gitignorada).
- `flutter build apk --debug --flavor dev -t lib/main_dev.dart` → `Built
  build\app\outputs\flutter-apk\app-dev-debug.apk`.
- `curl http://127.0.0.1:9099/emulator/v1/projects/vestipro/config` → `200` (Auth Emulator real,
  iniciado e verificado nesta sessão).

## Commit

Commit criado após a conclusão desta documentação.

## Push

Não executado nesta task; depende de autorização explícita do usuário.

## Hash do commit

Preenchido após o commit real (ver mensagem final desta conversa).

## Branch

`main`
