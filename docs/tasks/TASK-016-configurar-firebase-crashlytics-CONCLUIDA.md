# TASK-016 — Concluída (2026-08-22)

## Resumo

`firebase_crashlytics` (já no `pubspec.yaml`) integrado por trás de uma abstração central,
`CrashReporter` (`lib/core/services/`), com uma única implementação real, `FirebaseCrashReporter` —
nenhuma feature chama `FirebaseCrashlytics.instance` diretamente. `FirebaseError.onError` e
`PlatformDispatcher.instance.onError` (`configureGlobalErrorHandlers`, `lib/app/bootstrap.dart`) e
`VestiProBlocObserver.onError` reportam automaticamente qualquer erro classificado como inesperado
por `isUnexpectedError` (`lib/core/errors/`, nova função que reusa `mapAppExceptionToFailure` da
TASK-004): exceções de negócio esperadas (validação, permissão, não encontrado, conflito,
conectividade, servidor) nunca geram ruído no Crashlytics, só `CacheException`/`SyncException`/
`UnknownException`/`FirebaseInitializationException` e qualquer erro não classificado (framework,
async). `configureCrashlytics` desabilita a coleta em `development` (decisão documentada abaixo) e
mantém habilitada em `staging`/`production`. `FirebaseCrashReporter` é defensivo — nunca lança,
mesmo se o SDK falhar — e anexa contexto seguro (`environment`, `appVersion`, `platform`, via o
`AppClientMetadataProvider` já existente da TASK-015) na primeira vez que algo é de fato reportado,
nunca eagerly no bootstrap. Em modo debug, a tela "Sobre o app" ganhou um botão de crash de teste
para validar manualmente o pipeline ponta a ponta no console do Firebase.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/errors/error_reporting_policy.dart` (`isUnexpectedError`)
- `lib/core/services/crash_reporter.dart` (abstração `CrashReporter`)
- `lib/core/services/firebase_crash_reporter.dart` (implementação real, `@LazySingleton(as: CrashReporter)`)
- `lib/core/services/configure_crashlytics.dart` (toggle de coleta por ambiente)
- `lib/core/services/crash_reporter_test_trigger.dart` (`triggerCrashlyticsTestCrash`, debug-only)
- `lib/core/services/services.dart` (barrel público do módulo)
- `test/core/errors/error_reporting_policy_test.dart`
- `test/core/services/firebase_crash_reporter_test.dart`
- `test/core/services/configure_crashlytics_test.dart`
- `test/app/configure_global_error_handlers_test.dart`
- `docs/tasks/TASK-016-configurar-firebase-crashlytics-CONCLUIDA.md`

## Arquivos alterados

- `lib/core/errors/errors.dart` (exporta `error_reporting_policy.dart`)
- `lib/app/injection_module.dart` (`@lazySingleton FirebaseCrashlytics firebaseCrashlytics(AppEnvironment)`
  chamando `configureCrashlytics`)
- `lib/app/injection.config.dart` (regenerado por `build_runner`, registra `FirebaseCrashlytics` e
  `CrashReporter`/`FirebaseCrashReporter`)
- `lib/app/vestipro_bloc_observer.dart` (`onError` reporta erros inesperados via `CrashReporter`,
  resolvido lazily de `getIt` quando não injetado explicitamente)
- `lib/app/bootstrap.dart` (`configureGlobalErrorHandlers`: liga `FlutterError.onError` e
  `PlatformDispatcher.instance.onError` ao `CrashReporter`, chamada após `configureDependencies`)
- `lib/features/settings/presentation/pages/about_app_page.dart` (ação de crash de teste na
  `_AboutAppBar`, visível só com `kDebugMode`)
- `test/app/vestipro_bloc_observer_test.dart` (casos novos para `onError`)
- `test/features/settings/presentation/pages/about_app_page_test.dart` (caso novo para o botão de
  crash de teste)
- `README.md` (seção "Backend e Firebase": Crashlytics já conectado, e onde/por quê)
- `docs/tasks/TASKS.md` (checkbox da TASK-016 e progresso)

## Arquitetura utilizada

`lib/core/services/` (já previsto no `README.md` daquela pasta como lar de "logging e crash
reporting") segue o mesmo padrão de fronteira já estabelecido para Firestore/Storage/Functions
(TASK-013/014/015): uma função `configure*` chamada pelo provider `@lazySingleton` do SDK real em
`lib/app/injection_module.dart`, e uma interface própria (`CrashReporter`) com implementação real
`@LazySingleton(as: CrashReporter)` — mockável em teste, nunca referenciada diretamente por
features. Diferente de Firestore/Storage/Functions, não existe emulador local para Crashlytics; a
"configuração por ambiente" aqui é o toggle de coleta (`setCrashlyticsCollectionEnabled`).

**Resolução lazy em todos os pontos de integração.** `FirebaseCrashlytics`/`CrashReporter` só são
resolvidos do container de DI quando um erro é de fato reportado (dentro dos closures de
`FlutterError.onError`/`PlatformDispatcher.instance.onError`/`VestiProBlocObserver.onError`), nunca
eagerly durante `bootstrap()`. Isso preserva o comportamento dos testes de widget existentes
(`bootstrap_test.dart`) que nunca tocam o canal de plugin do Crashlytics, e seguiu o mesmo raciocínio
já usado para Firestore/Storage/Functions.

## Regras de negócio implementadas

- Nenhuma feature pode chamar `FirebaseCrashlytics.instance` diretamente — só `CrashReporter`.
- Exceções de negócio esperadas/tratadas (`ValidationException`, `ForbiddenException`,
  `UnauthorizedException`, `NotFoundException`, `ConflictException`, `NetworkException`,
  `TimeoutException`, `ServerException`) nunca são reportadas ao Crashlytics — só o que
  `isUnexpectedError` classifica como inesperado (equivalente a `UnexpectedFailure`) ou qualquer
  erro que nem chegou a ser um `AppException` (por definição, escapou do tratamento do app).
- `setUserIdentifier` documentado para receber só o `userId` técnico — nunca e-mail/nome (LGPD); sem
  uso real ainda, pois o fluxo de login (TASK-034) não existe.

## Regras Firebase implementadas

- `configureCrashlytics` desabilita `setCrashlyticsCollectionEnabled` em `development` e habilita em
  `staging`/`production` — decisão documentada no próprio arquivo e em "Decisões técnicas" abaixo.
- `FirebaseCrashlytics` registrado como `@lazySingleton`, mesmo padrão ADR-0002 de Auth/Firestore/
  Storage/Functions: só é tocado quando algo de fato resolve a dependência via DI.

## Analytics implementado

Nenhum (fora do escopo desta task; TASK-017).

## Crashlytics implementado

Ver "Resumo". Cobertura: erros de framework Flutter (`FlutterError.onError`, `fatal: true`), erros
assíncronos não tratados (`PlatformDispatcher.instance.onError`, `fatal: true`) e erros inesperados
capturados por qualquer Bloc (`VestiProBlocObserver.onError`, `fatal: false`) — todos filtrados por
`isUnexpectedError` antes de chegar ao `CrashReporter`.

## Impacto offline

Nenhum. Reportar um erro ao Crashlytics não bloqueia nenhum fluxo — o SDK enfileira localmente
quando não há rede (comportamento nativo do Crashlytics, fora do controle deste código) e
`FirebaseCrashReporter` nunca lança mesmo se a chamada falhar.

## Impacto multi-tenant

Nenhum ainda: `organizationId`/`companyId` não são anexados automaticamente porque `Organization`
(TASK-026) ainda não existe no domínio. `CrashReporter.setCustomKey` já é o ponto de extensão público
para a TASK-026/037 chamarem quando o contexto de organização existir — sem precisar de nenhuma
mudança nesta camada.

## Testes criados

- `test/core/errors/error_reporting_policy_test.dart`: `isUnexpectedError` verdadeiro para
  `CacheException`/`SyncException`/`UnknownException`/`FirebaseInitializationException` e para
  qualquer erro não classificado (`StateError`, `Exception` genérica); falso para as exceções de
  negócio esperadas (`ValidationException`, `ForbiddenException`, `UnauthorizedException`,
  `NotFoundException`, `ConflictException`, `NetworkException`, `ServerException`).
- `test/core/services/firebase_crash_reporter_test.dart` (mocktail, `FirebaseCrashlytics` mockado):
  `recordError` anexa contexto base (`environment`/`appVersion`/`platform`) uma única vez e depois
  encaminha cada chamada ao SDK; `setUserIdentifier` encaminha o id, e limpa com string vazia quando
  `null`; `setCustomKey` encaminha; e um teste dedicado provando que nenhum método lança mesmo com o
  SDK simulando falha (defensive coding pedido pelos critérios de aceite).
- `test/core/services/configure_crashlytics_test.dart`: coleta desabilitada em `development`,
  habilitada em `staging` e `production`.
- `test/app/configure_global_error_handlers_test.dart`: `FlutterError.onError` e
  `PlatformDispatcher.instance.onError` encaminham um erro inesperado ao `CrashReporter` como
  `fatal: true` sem descartar o handler anterior (e preservando o valor de retorno dele); um
  `AppException` esperado (`ValidationException`) não é encaminhado.
- `test/app/vestipro_bloc_observer_test.dart` (casos novos): `onError` reporta um erro inesperado
  como `fatal: false`; não reporta uma exceção de negócio esperada.
- `test/features/settings/presentation/pages/about_app_page_test.dart` (caso novo): o botão de crash
  de teste existe (tooltip) e, ao ser tocado, lança o `StateError` esperado (capturado via
  `tester.takeException()`).

## Comandos executados

```bash
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --target lib/main_dev.dart --output build/web-dev-check
```

## Resultado do formatter

`Formatted 135 files (0 changed)` na execução final.

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

`flutter test` → **151 testes, todos passaram** (135 pré-existentes + 16 novos desta task:
`isUnexpectedError`, `FirebaseCrashReporter`, `configureCrashlytics`,
`configureGlobalErrorHandlers`, `VestiProBlocObserver.onError` e o botão de crash de teste da
`AboutAppPage`).

`flutter build web --target lib/main_dev.dart` → `Built build\web-dev-check` (removido após a
validação, é apenas saída de build gitignorada) — evidência de que o novo código compila no target
Web.

## Decisões técnicas

- **Resolução lazy do `CrashReporter` em todo ponto de integração**, nunca em `bootstrap()`
  diretamente. `configureGlobalErrorHandlers({CrashReporter Function()? resolveCrashReporter})` só
  chama `getIt<CrashReporter>()` de dentro dos closures de `FlutterError.onError`/
  `PlatformDispatcher.instance.onError`, e só quando um erro de fato ocorre — o parâmetro
  `resolveCrashReporter` existe só para tornar a função testável sem precisar de um
  `FirebaseCrashlytics` real. Mesma lógica em `VestiProBlocObserver`, que aceita um `CrashReporter?`
  opcional no construtor (resolvido de `getIt` só dentro de `onError` quando não informado). Isso
  evita que qualquer teste de widget/bootstrap que nunca dispara um erro precise mockar o plugin do
  Crashlytics.
- **`PlatformDispatcher.instance.onError` (`dart:ui`), não `WidgetsBinding.instance.platformDispatcher`.**
  Tentativa inicial usou `WidgetsBinding.instance.platformDispatcher.onError`, que em ambiente
  `flutter_test` retorna um `TestPlatformDispatcher` cujo setter de `onError` é um no-op deliberado
  do framework de teste (`flutter_test/lib/src/window.dart`) — a atribuição nunca "pega", tornando o
  wiring inteiro impossível de testar e, mais grave, também inerte nesse cenário. Usar o singleton
  real de `dart:ui` (`PlatformDispatcher.instance`, a mesma recomendação da documentação oficial do
  Firebase Crashlytics) resolve os dois problemas: funciona igual em produção e é testável
  diretamente (`test/app/configure_global_error_handlers_test.dart`).
- **Filtro `isUnexpectedError` aplicado nos três pontos de integração** (FlutterError,
  PlatformDispatcher, BlocObserver), não só num deles — para a política de "não gerar ruído com
  exceções de negócio esperadas" ser consistente independente de onde o erro foi capturado, incluindo
  o caso raro de uma `AppException` esperada escapar sem ser tratada e chegar a um desses handlers
  globais.
- **`fatal: true` para `FlutterError`/`PlatformDispatcher`, `fatal: false` para `BlocObserver`.** Os
  dois primeiros representam um erro que, sem o handler, teria de fato encerrado/corrompido a
  execução (crash real); o terceiro é um erro inesperado que um Bloc já conseguiu isolar sem tirar o
  app do ar — mesma distinção que a própria API do `firebase_crashlytics`
  (`recordFlutterFatalError` vs. `recordFlutterError`) sugere.
- **Contexto base (`environment`/`appVersion`/`platform`) anexado dentro de `FirebaseCrashReporter`,
  não em `bootstrap()`.** Anexar eagerly no bootstrap exigiria resolver `CrashReporter`/
  `FirebaseCrashlytics` antes de qualquer erro existir, tocando o canal de plugin do Crashlytics em
  todo boot do app (inclusive em testes) só para preencher metadata. Em vez disso,
  `_ensureBaseContext()` roda uma única vez, na primeira chamada real de `recordError`, reusando o
  `AppClientMetadataProvider` já existente da TASK-015 (evita duplicar a leitura de
  `package_info_plus`).
- **`organizationId`/`companyId` não anexados agora.** A task pede esse contexto, mas
  `Organization`/multi-tenancy ainda não existem no domínio (TASK-026 em diante). `setCustomKey` é o
  ponto de extensão genérico já pronto para quando esse dado existir — decisão para não inventar um
  método `setOrganizationContext` especulativo antes de existir um chamador real.
- **Botão de crash de teste na tela "Sobre o app", não uma tela de debug nova.** A task pede um
  comando de teste debug-only; construir uma tela de debug dedicada seria escopo extra não pedido.
  `triggerCrashlyticsTestCrash()` (`lib/core/services/`) é uma função simples, guardada por
  `kDebugMode` internamente, e a `_AboutAppBar` só a expõe como ação quando `kDebugMode` é
  verdadeiro — dupla proteção, sem depender de nenhuma tela nova.

## Riscos conhecidos

- **Validação real "aparece no console do Firebase Crashlytics" não pôde ser executada nesta
  sessão** — não há aqui um device/emulador com Google Play Services, nem uma sessão autenticada no
  Firebase Console. O botão de crash de teste (`triggerCrashlyticsTestCrash`) e o wiring de
  `FlutterError.onError`/`PlatformDispatcher.instance.onError` foram validados por teste automatizado
  (unidade + widget), mas a confirmação visual no console real do projeto `vestipro` depende de
  alguém rodar o app de verdade (`flutter run --flavor dev` num device/emulador) e tocar o botão —
  mesma categoria de limitação de ambiente já registrada nas TASK-012/013/014/015 para os emuladores
  Firebase.
- Nenhuma feature real usa `CrashReporter.setUserIdentifier` ainda (depende do login, TASK-034) nem
  `setCustomKey` para contexto de organização (depende da TASK-026).

## Pendências

- Validar manualmente, num device/emulador real com o flavor `dev`, que o botão de crash de teste da
  tela "Sobre o app" gera um evento visível no console do Firebase Crashlytics do projeto `vestipro`
  (ver "Riscos conhecidos").
- TASK-026/037 (Organization) devem chamar `CrashReporter.setCustomKey('organizationId', ...)` /
  `setCustomKey('companyId', ...)` quando esse contexto passar a existir.
- TASK-034 (login) deve chamar `CrashReporter.setUserIdentifier(userId)` no login e
  `setUserIdentifier(null)` no logout.
- Push depende de autorização explícita do usuário.

## Evidências

- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!` (151 testes).
- `flutter build web --target lib/main_dev.dart` → `Built build\web-dev-check`.

## Commit

Realizado.

## Push

Não executado nesta task; depende de autorização explícita do usuário.

## Hash do commit

Registrado em um commit de documentação subsequente (`docs(tasks): record TASK-016 commit hash`),
mesmo padrão das tasks anteriores (TASK-013/014/015).

## Branch

`main`
