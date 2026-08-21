# TASK-011 — Concluída (2026-08-21)

## Resumo

`Firebase.initializeApp` passou a ser chamado uma única vez, dentro do bootstrap central
(`lib/app/bootstrap.dart`), usado por todos os entrypoints (`main_dev.dart`, `main_staging.dart`,
`main_prod.dart`, `main_web.dart`, `main.dart`). Falha de inicialização é capturada, registrada via
`FirebaseInitializationException` (novo tipo em `lib/core/errors/`) e resulta em uma tela de erro
amigável (`FirebaseBootstrapErrorApp`) com opção de tentar novamente, em vez de crash ou tela branca.
Nenhuma feature inicializa o Firebase por conta própria.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/app/firebase_bootstrap_error_app.dart`
- `test/app/bootstrap_test.dart`
- `test/app/firebase_bootstrap_error_app_test.dart`
- `docs/tasks/TASK-011-integrar-firebase-core-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/bootstrap.dart` (bootstrap virou `Future<void>`, chama `WidgetsFlutterBinding.ensureInitialized()`
  e `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` antes de configurar DI e
  subir o app; erro de inicialização é reportado e renderiza `FirebaseBootstrapErrorApp`)
- `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`,
  `lib/main_web.dart` (entrypoints passam a `await bootstrap(...)`)
- `lib/core/errors/app_exception.dart` (novo `FirebaseInitializationException`)
- `lib/core/errors/exception_mapper.dart` (novo case mapeando para `UnexpectedFailure`, necessário
  para manter o `switch` exaustivo sobre o `sealed class AppException`)
- `pubspec.yaml` / `pubspec.lock` (dev dependency `firebase_core_platform_interface`, usada apenas em
  teste para mockar o host API nativo do Firebase Core)
- `test/core/errors/errors_test.dart` (cobre o novo `FirebaseInitializationException` na
  instanciação da hierarquia e no mapeamento para `Failure`)
- `README.md` (seção "Backend e Firebase" atualizada: a inicialização condicional por *emulador*
  fica a cargo de cada task que configura o respectivo SDK — TASK-012 a TASK-015 —, já que
  `firebase_core` isoladamente não tem noção de emulador, apenas os SDKs filhos)

## Arquitetura utilizada

Nenhuma mudança de camada de domínio/data. O bootstrap continua sendo o único ponto de entrada de
infraestrutura de app (DI, observers, Firebase), como já estabelecido nas TASK-004/005/006.

## Regras de negócio implementadas

Nenhuma regra de negócio funcional. Regra de infraestrutura: nenhuma feature pode chamar
`Firebase.initializeApp` fora de `bootstrap()` — reforçado via comentário no próprio bootstrap e
pela ausência de qualquer outro import de `firebase_core` no restante de `lib/`.

## Regras Firebase implementadas

- `Firebase.initializeApp` chamado exatamente uma vez por execução do app, com
  `DefaultFirebaseOptions.currentPlatform` (único projeto real `vestipro`, por ADR-0002).
- Nenhuma conexão a emulador foi adicionada nesta task: `firebase_core` não tem uma API de
  "usar emulador" — isso existe por SDK filho (`FirebaseAuth.instance.useAuthEmulator(...)`,
  `FirebaseFirestore.instance.useFirestoreEmulator(...)` etc.), que só são configurados a partir da
  TASK-012. Deixar essa responsabilidade nas tasks TASK-012/013/014/015 evita configurar emulador
  para SDKs que ainda não existem no app.

## Analytics implementado

Nenhum (fora do escopo desta task; TASK-017).

## Crashlytics implementado

Nenhum. Falha de inicialização é reportada via `dart:developer.log` (mesmo padrão já usado por
`VestiProBlocObserver`), já que Crashlytics só é configurado na TASK-016 — consistente com o que a
própria TASK-011 previa ("mesmo que, nesta task, apenas via log estruturado").

## Impacto offline

Nenhum. Falha de rede durante `Firebase.initializeApp` (ex.: app completamente offline no primeiro
boot) é tratada pelo mesmo caminho de erro genérico e exibe a tela de retry.

## Impacto multi-tenant

Nenhum. Escopo estritamente de inicialização do SDK Firebase, anterior a qualquer resolução de
`organizationId`.

## Testes criados

- `test/app/bootstrap_test.dart`:
  - `bootstrap initializes Firebase exactly once and renders VestiProApp`: mocka o host API nativo
    do `firebase_core_platform_interface` (`TestFirebaseCoreHostApi`) para simular uma inicialização
    bem-sucedida, executa `bootstrap()` de ponta a ponta e confirma que `initializeApp` foi chamado
    exatamente uma vez e que `VestiProApp` foi renderizado.
  - `bootstrap shows the friendly error screen instead of crashing when Firebase fails to
    initialize`: mocka o mesmo host API para lançar `PlatformException`, executa `bootstrap()` e
    confirma que a tela amigável (`FirebaseBootstrapErrorApp`) é exibida em vez de crash.
- `test/app/firebase_bootstrap_error_app_test.dart`: cobre a tela de erro isoladamente (mensagem
  amigável, botão de retry funcional, detalhe técnico visível fora de produção e oculto em produção).
- `test/core/errors/errors_test.dart`: atualizado para cobrir `FirebaseInitializationException` na
  hierarquia de exceções e no mapeamento para `UnexpectedFailure`.

## Comandos executados

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor prod -t lib/main_prod.dart
flutter build web --target lib/main_dev.dart --output build/web-dev
```

## Resultado do formatter

`Formatted 71 files (0 changed)`.

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

`flutter test`: todos os testes passaram (37 pré-existentes + 4 novos/atualizados nesta task).

## Decisões técnicas

- `bootstrap()` deixou de ser síncrono e passou a `Future<void>`, exigindo `await bootstrap(...)` em
  todos os entrypoints — necessário porque `Firebase.initializeApp` é assíncrono e precisa concluir
  (ou falhar) antes de decidir entre subir `VestiProApp` ou `FirebaseBootstrapErrorApp`.
- `FirebaseBootstrapErrorApp` foi implementado como um `MaterialApp` independente (não reaproveita
  `AppRouter`/DI), porque o app router e o GetIt só são configurados depois que o Firebase inicializa
  com sucesso — se a tela de erro dependesse deles, um Firebase indisponível quebraria também a
  própria tela de erro.
- Detalhe técnico da exceção só é exibido fora de produção (`!environment.isProduction`), para nunca
  vazar mensagem de exceção interna para o usuário final em produção, mesmo antes do RBAC/Crashlytics
  existirem.
- Testado o caminho real do SDK (não apenas documentado) usando o mock oficial do
  `firebase_core_platform_interface` (`TestFirebaseCoreHostApi`), a mesma técnica usada pelos testes
  do próprio FlutterFire — evita depender de rede real ou de um projeto Firebase real em teste,
  respeitando a regra de isolamento de testes do projeto (`docs/architecture/testing.md`).
- Uma primeira versão do teste de falha tentava simular a falha "sem nenhum mock registrado" — essa
  abordagem **travou indefinidamente** (o canal de plataforma do Firebase Core, sem handler
  registrado no binding de teste, nunca completa a `Future`), causando timeout de 10 minutos em
  `flutter test`. Corrigido registrando explicitamente um `TestFirebaseCoreHostApi` que lança
  `PlatformException`, garantindo uma falha determinística e rápida.
- README atualizado para não prometer mais que TASK-011 conecta emuladores por serviço (Auth/
  Firestore/Storage/Functions): `firebase_core` isoladamente não tem esse conceito, só os SDKs
  filhos o têm, então essa responsabilidade fica com cada task correspondente (TASK-012 a TASK-015).

## Riscos conhecidos

- `lib/firebase_options.dart` continua gitignorado (ADR-0002); qualquer clone novo do repositório
  precisa rodar `flutterfire configure -p vestipro --platforms=android,ios,web` localmente antes de
  compilar — sem esse arquivo, o projeto não compila em nenhuma plataforma, já que `bootstrap.dart`
  agora importa `DefaultFirebaseOptions` diretamente. Isso já era uma consequência aceita da
  TASK-010/ADR-0002, não uma regressão introduzida aqui.
- Validação foi feita via build de sucesso (`flutter build apk`/`flutter build web`) e testes com
  mock do SDK nativo, não via execução real em dispositivo/emulador Android, simulador iOS ou
  navegador — não há emulador Android nem host macOS disponíveis nesta máquina/sessão. O mesmo
  padrão de limitação já estava documentado em `TASK-010-criar-projetos-firebase-CONCLUIDA.md`.
- Build iOS real segue pendente de host macOS (herdado da TASK-010, não afetado por esta task).

## Pendências

- Executar o app em um dispositivo/emulador Android e em um navegador real para confirmar
  visualmente a inicialização (esta sessão não tem emulador Android nem browser interativo
  disponível para validação end-to-end; a validação aqui é por build + teste automatizado).
- Push depende de autorização explícita do usuário.

## Evidências

- `flutter build apk --debug --flavor dev -t lib/main_dev.dart` → `Built build\app\outputs\flutter-apk\app-dev-debug.apk`.
- `flutter build apk --debug --flavor staging -t lib/main_staging.dart` → `Built build\app\outputs\flutter-apk\app-staging-debug.apk`.
- `flutter build apk --debug --flavor prod -t lib/main_prod.dart` → `Built build\app\outputs\flutter-apk\app-prod-debug.apk`.
- `flutter build web --target lib/main_dev.dart --output build/web-dev` → `Built build\web-dev`.
- `flutter test` → `All tests passed!`.

## Commit

Commit criado após a conclusão da documentação.

## Push

Não executado nesta task; depende de autorização explícita do usuário.

## Hash do commit

`ddb9f6c`

## Branch

`main`
