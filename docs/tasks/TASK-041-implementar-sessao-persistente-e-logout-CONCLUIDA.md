# TASK-041 — Concluída (2026-08-23)

## Resumo

Implementada a persistência segura de sessão, o logout e a detecção de revogação remota
(EPIC-04). O ponto de partida real era diferente do backlog: `AuthRepository` (TASK-012) e
`SessionAuthGuard` (guard de rota por sessão) já existiam e já tinham testes, mas
`SessionAuthGuard` nunca havia sido conectado como o `AuthGuard` real de `VestiProApp` — três
tasks anteriores (TASK-012, TASK-034, TASK-038) documentaram explicitamente essa lacuna e a
delegaram para esta task. Isso significava que, em produção, **qualquer rota era acessível sem
sessão nenhuma** (o guard default de `AppRouter`, `AlwaysAllowAuthGuard`, nunca foi substituído).

Esta task:

- Criou `SessionService` (contrato em `domain/services/`, implementação em `data/services/`) como
  a peça central de sessão: `logout()` (signOut + limpeza local incondicional) e
  `ensureSessionIsActive()` (força refresh do ID token via Firebase Auth para detectar
  revogação/desativação remota, nunca derrubando a sessão por causa de uma falha de conectividade).
- Criou `SecureSessionStore` (contrato + implementação `flutter_secure_storage`) — o único dado de
  sessão persistido localmente pelo app é o `uid` do último usuário confirmado, nunca token nem
  senha, nunca `SharedPreferences`.
- Estendeu `AuthRepository`/`AuthDataSource`/`FirebaseAuthDataSource` com `refreshSession()`
  /`refreshIdToken()`, e o mapper de exceções do Firebase Auth com os códigos
  `user-token-expired`/`invalid-user-token`.
- Tornou `AuthGuard.redirect` assíncrono (`FutureOr<String?>`, mesmo formato que
  `AuthorizationGuard` já usava) e reescreveu `SessionAuthGuard` para usar `SessionService`,
  detectando sessão revogada em toda navegação a rota protegida, com `LoginRoute` carregando
  `returnTo`/`reason` como query parameters.
- **Conectou `SessionAuthGuard` como o guard real de `VestiProApp`** (`lib/app/bootstrap.dart`) —
  o trabalho que as três tasks anteriores deixaram pendente.

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task: domain/data, Firebase Auth,
  DI, guards de rota, testes). Nenhum agente de negócio/front-end era aplicável — a task não tem
  UI própria (nenhuma tela nova; `LoginPage` já existia da TASK-034 e não foi alterada em
  aparência).

## Arquivos criados

- `lib/core/auth/domain/value_objects/session_ended_reason.dart` — enum `SessionEndedReason`
  (`userInitiated`, `revoked`) com mensagem de usuário em português, carregado como query parameter
  do redirect para `LoginRoute` quando uma sessão já autenticada é encerrada por revogação.
- `lib/core/auth/data/datasources/secure_session_store.dart` — contrato `SecureSessionStore`.
- `lib/core/auth/data/datasources/secure_flutter_session_store.dart` — implementação com
  `flutter_secure_storage`, registrada via `@LazySingleton(as: SecureSessionStore)`.
- `lib/core/auth/domain/services/session_service.dart` — contrato `SessionService`.
- `lib/core/auth/data/services/session_service_impl.dart` — implementação `SessionServiceImpl`,
  registrada via `@LazySingleton(as: SessionService)`.
- `test/core/auth/data/datasources/secure_flutter_session_store_test.dart` — 5 testes, usando o
  seam de teste real do pacote (`flutter_secure_storage/test/test_flutter_secure_storage_platform.dart`
  + `FlutterSecureStoragePlatform.instance`), sem tocar plataforma nativa.
- `test/core/auth/data/services/session_service_impl_test.dart` — 11 testes cobrindo logout,
  `ensureSessionIsActive` (sucesso, offline, revogação por código, código não-relacionado) e um
  teste de regressão explícito para o bug descrito em "Decisões técnicas".
- `test/support/fake_firebase_core.dart` — fake host API do Firebase Core (`FakeFirebaseCoreHostApi`)
  e helpers `setUpFakeFirebaseCore()`/`tearDownFakeFirebaseCore()`, extraídos de
  `test/app/bootstrap_test.dart` e reutilizados também por `test/widget_test.dart` (ver "Decisões
  técnicas").

## Arquivos alterados

Domain/data de autenticação:

- `lib/core/auth/domain/repositories/auth_repository.dart` — novo método `refreshSession()`.
- `lib/core/auth/data/repositories/auth_repository_impl.dart` — implementação de `refreshSession()`.
- `lib/core/auth/data/datasources/auth_data_source.dart` — novo método `refreshIdToken()`.
- `lib/core/auth/data/datasources/firebase_auth_data_source.dart` — implementação de
  `refreshIdToken()` via `User.getIdToken(true)`.
- `lib/core/auth/data/mappers/firebase_auth_exception_mapper.dart` — mapeia `user-token-expired`
  e `invalid-user-token` para `UnauthorizedException`.
- `lib/core/auth/auth.dart` — exporta `SessionService` e `SessionEndedReason`.
- `lib/core/auth/README.md` — documenta o desenho de sessão/logout/revogação.

Navegação:

- `lib/core/navigation/auth_guard.dart` — `AuthGuard.redirect` agora retorna `FutureOr<String?>`.
- `lib/core/navigation/session_auth_guard.dart` — reescrito sobre `SessionService`, assíncrono,
  com `returnTo`/`reason`.
- `lib/core/navigation/app_router.dart` — `_redirect` assíncrono (`await authGuard.redirect(...)`,
  com `context.mounted` antes de reusar o `context` depois do `await`).
- `lib/core/navigation/app_route_paths.dart` — `LoginRoute` ganhou `returnTo`/`endedSessionReason`
  opcionais, codificados como query parameters em `location`.
- `docs/architecture/navigation.md` — documenta o guard real conectado e os novos query
  parameters.

Composição/DI:

- `lib/app/bootstrap.dart` — `VestiProApp` agora passa
  `authGuard: SessionAuthGuard(getIt<SessionService>())` para `AppRouter` (o fio que faltava).
- `lib/app/injection_module.dart` — novo provider `FlutterSecureStorage` (`@lazySingleton`).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (novas injeções).
- `pubspec.yaml` — novo `dev_dependency` `flutter_secure_storage_platform_interface` (mesmo
  padrão já usado por `firebase_core_platform_interface`: só o seam de teste do pacote).
- `pubspec.lock` — atualizado por `flutter pub get`.

Backlog:

- `docs/tasks/TASKS.md` — TASK-041 marcada `[x]`, progresso atualizado.

Testes existentes ajustados (assinatura nova de `AuthRepository`/comportamento novo do guard real):

- `test/core/navigation/session_auth_guard_test.dart` — reescrito para mockar `SessionService`
  em vez de `AuthRepository` (o guard trocou de colaborador), com um caso novo cobrindo o redirect
  por sessão revogada.
- `test/features/authentication/domain/usecases/send_password_reset_email_use_case_test.dart`,
  `test/features/authentication/presentation/bloc/forgot_password_bloc_test.dart`,
  `test/features/authentication/presentation/bloc/login_bloc_test.dart`,
  `test/features/authentication/presentation/bloc/sign_up_bloc_test.dart`,
  `test/features/authentication/presentation/pages/forgot_password_page_test.dart`,
  `test/features/authentication/presentation/pages/login_page_test.dart`,
  `test/features/authentication/presentation/pages/sign_up_page_test.dart`,
  `test/features/invites/presentation/pages/accept_invite_page_test.dart`,
  `test/features/onboarding/presentation/bloc/onboarding_bloc_test.dart`,
  `test/features/onboarding/presentation/pages/onboarding_wizard_page_test.dart` — cada um
  implementa `_AuthRepositoryStub implements AuthRepository` manualmente (não `Mock`); todos
  ganharam o novo método `refreshSession()` (implementação trivial `throw UnimplementedError()`,
  já que nenhum desses testes o exercita).
- `test/widget_test.dart`, `test/app/bootstrap_test.dart` — o `AppRouter` real agora exige sessão;
  os dois únicos testes que montam `VestiProApp`/`bootstrap()` com o DI de produção (sem sessão
  autenticada) passaram a esperar a tela de login real em vez do placeholder "about app" —
  exatamente o comportamento correto e documentado como pendência pelas TASK-012/034/038.
  `test/widget_test.dart` também passou a inicializar o Firebase fake compartilhado (ver "Decisões
  técnicas"); `test/app/bootstrap_test.dart` foi refatorado para reusar o mesmo helper em vez de
  manter sua própria cópia da fake host API.

## Arquitetura utilizada

Clean/feature-first, mesma estrutura já usada em `lib/core/auth/`: contrato em `domain/`,
implementação + DTO/mapper em `data/`, DI via `injectable`/`get_it`, nenhum tipo do
`firebase_auth`/`flutter_secure_storage` escapando de `lib/core/auth/data/`. `SessionAuthGuard`
depende só do contrato `SessionService`, nunca de `AuthRepository` ou do SDK diretamente.

## Regras de negócio implementadas

- Sessão restaurada automaticamente entre reinícios enquanto o token do Firebase Auth for válido
  (comportamento nativo do SDK, sempre existiu — não duplicado por esta task).
- `logout()` chama `signOut()` e limpa o `SecureSessionStore` de forma incondicional, mesmo que o
  `signOut()` remoto falhe — nenhuma operação autenticada deveria conseguir "sobreviver" ao clique.
- `ensureSessionIsActive()` força refresh do ID token; só termina a sessão para os códigos que
  significam revogação real (`user-disabled`, `user-token-expired`, `invalid-user-token`,
  `user-not-found`) — qualquer falha de conectividade/inesperada mantém a última sessão válida
  (testado explicitamente: dispositivo offline nunca perde sessão só por não conseguir confirmar).
- `SessionAuthGuard` chama `ensureSessionIsActive()` em toda navegação a rota protegida, então uma
  revogação (ex.: desativação de usuário, TASK-046) tem efeito no próximo request autenticado, sem
  depender do usuário reabrir o app manualmente.
- `LoginRoute` carrega `returnTo` (a rota originalmente pedida) e `reason` (motivo do fim de
  sessão) como query parameters — mecanismo pronto para uma futura navegação pós-login real e uma
  mensagem "Sua sessão foi encerrada"; **ler esses parâmetros e renderizar UI não está no escopo
  desta task** (nenhum agente de front-end foi acionado; `LoginPage` continua com o mesmo destino
  placeholder pós-login que já usava desde a TASK-034).

## Regras Firebase implementadas

- `refreshIdToken()` usa `User.getIdToken(true)` (force refresh) do Firebase Auth — nenhuma regra
  de servidor nova nesta task (a desativação real de usuário que vai gerar o código
  `user-token-expired`/`invalid-user-token` em produção é a TASK-046, ainda pendente).
- Nenhuma alteração em Firestore/Storage Security Rules.

## Analytics implementado

Nenhum evento novo — fora do escopo definido na task (sessão/logout/revogação não estavam na
lista de eventos mínimos comerciais de `AGENTS.md`).

## Crashlytics implementado

Nenhuma integração nova — os `try/catch` de `SessionServiceImpl` devolvem `Failure`s tipadas pelo
mesmo `AppResult` já usado em todo `lib/core/auth/`; não há `catch` genérico silencioso.

## Impacto offline

`ensureSessionIsActive()` nunca desloga por causa de uma falha de conectividade — testado
explicitamente (`session_service_impl_test.dart`, "does not end the session on a connectivity
failure while refreshing"). A sessão restaurada do Firebase Auth já funciona offline (cache local
do SDK); esta task não introduz nenhuma dependência de rede na restauração de sessão.

## Impacto multi-tenant

Nenhum campo de tenant é lido/escrito por esta task — `SessionService`/`SecureSessionStore` operam
inteiramente no nível de usuário (Firebase Auth), abaixo de qualquer conceito de Organization.
`ActiveOrganizationGuard` continua sendo um guard separado, inalterado.

## Testes criados

- `test/core/auth/data/datasources/secure_flutter_session_store_test.dart` (5 testes).
- `test/core/auth/data/services/session_service_impl_test.dart` (11 testes).
- `test/core/navigation/session_auth_guard_test.dart` (4 testes, reescrito).

## Comandos executados

```bash
flutter pub add --dev flutter_secure_storage_platform_interface   # (via edição do pubspec.yaml)
flutter pub get
flutter pub run build_runner build
flutter analyze
flutter test test/core/auth test/core/navigation
flutter test test/widget_test.dart test/app
dart format --set-exit-if-changed .
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` reformatou 4 arquivos na primeira execução (apenas estilo);
execução seguinte → `Formatted 573 files (0 changed) in 1.92 seconds.`

## Resultado do analyzer

`flutter analyze` → `No issues found! (ran in 10.9s)`

## Resultado dos testes

`flutter test` (suíte completa) → `00:32 +964: All tests passed!` (964 testes, 0 falhas — nenhum
`[E]` no log).

## Decisões técnicas

- **Bug descoberto e corrigido durante esta task**: a primeira versão de `SessionServiceImpl`
  assinava `authRepository.authStateChanges` no construtor para manter `SecureSessionStore`
  sincronizado automaticamente a cada mudança de sessão. Isso fazia qualquer teste de widget que
  resolvesse `SessionService` via DI real (mesmo sem nenhuma intenção de testar sessão) chamar
  `flutter_secure_storage` de verdade — e, sob `flutter_test` neste ambiente Windows, essa chamada
  trava indefinidamente (não lança exceção, nunca completa; confirmado isolando a chamada em um
  teste diagnóstico). Isso travou `test/widget_test.dart`/`test/app/bootstrap_test.dart` por vários
  minutos sem sinal de progresso. Corrigido removendo a assinatura automática: toda escrita em
  `SecureSessionStore` agora é consequência de uma chamada explícita já testada
  (`logout()`, ou o caminho de sucesso/revogação de `ensureSessionIsActive()`), nunca de um
  listener em segundo plano disparado só por a instância existir. Isso também é arquiteturalmente
  melhor: resolver um serviço via DI nunca deveria, por si só, ter efeito colateral de I/O.
- `AuthGuard.redirect` passou a `FutureOr<String?>` em vez de `String?`, no mesmo padrão que
  `AuthorizationGuard` já usava — evita duas convenções de guard diferentes dentro do mesmo
  `AppRouter`.
- `AppRouter._redirect` ganhou um `if (!context.mounted) return null;` depois do primeiro `await`
  para não reusar `context` de forma insegura entre guards (lint `use_build_context_synchronously`
  evitado por design, não por `// ignore:`).
- `SessionAuthGuard` só chama `ensureSessionIsActive()` quando já há um `currentUser` — uma
  requisição sem sessão nenhuma nunca paga o custo (nem o risco) de um refresh de token.
- Optei por **não** ligar `SecureSessionStore`/`SessionService` a nenhuma tela nova: a task só
  lista `flutter-senior-architect` como agente obrigatório, e tanto `returnTo` quanto `reason` são
  metadados que uma parte de UI ainda não construída poderia consumir — construir essa UI agora
  seria antecipar trabalho fora do escopo declarado (mesmo racional já usado pela TASK-034 ao não
  trocar o guard default).
- `SecureFlutterSessionStore` recebe `FlutterSecureStorage` por injeção de construtor (via
  `AppInjectionModule`), no mesmo padrão que `FirebaseAuthDataSource` já usa para `FirebaseAuth` —
  nunca instanciando o SDK diretamente dentro da classe.
- **Segundo problema descoberto ao validar `test/widget_test.dart`**: depois de corrigir o bug
  acima, o teste passou a falhar rápido (não mais travar) com `Error while creating FirebaseAuth`
  → `Firebase.app()` → "no App has been created". `test/widget_test.dart` nunca chamava
  `Firebase.initializeApp` (só `configureDependencies`), o que era seguro só porque, antes desta
  task, nada no grafo de DI tocava Firebase de verdade quando `VestiProApp` renderizava sem sessão.
  Agora que `SessionAuthGuard` é o guard real, renderizar `VestiProApp` genuinamente exige Firebase
  inicializado antes — exatamente como `bootstrap()` já garante em produção. Corrigido extraindo a
  fake host API que `test/app/bootstrap_test.dart` já tinha para `test/support/fake_firebase_core.dart`
  (compartilhada, evitando duplicar a classe) e usando-a também em `test/widget_test.dart`.

## Riscos conhecidos

- `LoginPage` ainda não lê `returnTo`/`reason` da URL — o usuário sempre volta para o mesmo destino
  placeholder (`AboutAppRoute` + organização placeholder) depois de logar, e uma sessão revogada
  não mostra nenhuma mensagem visível ainda ("Sua sessão foi encerrada" existe como
  `SessionEndedReason.message`, mas nada a renderiza). Fica para a task que construir a navegação
  pós-login real.
- A detecção de revogação depende de o usuário navegar para uma rota protegida (o guard é o único
  chamador de `ensureSessionIsActive()` hoje); não há verificação periódica em segundo plano
  enquanto o app permanece na mesma tela. Nenhuma infraestrutura de app-lifecycle/timer existia no
  projeto para justificar adicionar isso agora sem sobre-engenharia — outras chamadas futuras
  (qualquer repositório sensível) podem chamar `SessionService.ensureSessionIsActive()` do mesmo
  jeito que `PermissionAuthorizationGuard` reusa `PermissionService`.
- `SecureFlutterSessionStore` nunca foi exercitado com o plugin nativo real (Keychain/Keystore/
  DPAPI) em execução de app real — apenas com o seam de teste do próprio pacote e, indiretamente,
  pela ausência de erro nos fluxos que a chamam. Comportamento na TASK-046 (desativação real de
  usuário) deve ser validado end-to-end quando aquela task ligar `deactivateUser` a
  `revokeRefreshTokens`.

## Pendências

- Nenhuma pendência de código para o escopo declarado da task. UI de "sessão encerrada"/retorno
  pós-login e verificação periódica em background são extensões legítimas para tasks futuras, não
  regressões desta.

## Evidências

- `flutter analyze` → `No issues found!`
- `flutter test` → `00:32 +964: All tests passed!`
- `flutter test test/core/auth test/core/navigation` → `00:01 +56: All tests passed!` (execução
  isolada da parte nova/alterada desta task).
- `flutter test test/widget_test.dart test/app` → `00:01 +14: All tests passed!`.

## Commit

Commit local único cobrindo implementação, testes, documentação e atualização do backlog
(sem `lib/main.dart`, que tem alteração local não relacionada em andamento).

## Push

Realizado para `origin/main` (autorizado nesta conversa).

## Hash do commit

`25e5881`

## Branch

main
