# TASK-002 — Concluída (2026-08-20)

## Resumo

Ambientes `development`, `staging` e `production` configurados para Android, iOS e Web, com entrypoints Dart separados, bootstrap comum, configuração central em `lib/core/`, nomes visuais distintos e documentação de comandos por plataforma.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/app/bootstrap.dart`
- `lib/core/environment/app_environment.dart`
- `lib/main_dev.dart`
- `lib/main_staging.dart`
- `lib/main_prod.dart`
- `lib/main_web.dart`
- `test/core/environment/app_environment_test.dart`
- `ios/Flutter/Dev.xcconfig`
- `ios/Flutter/Staging.xcconfig`
- `ios/Flutter/Prod.xcconfig`
- `ios/Flutter/Debug-dev.xcconfig`
- `ios/Flutter/Debug-staging.xcconfig`
- `ios/Flutter/Debug-prod.xcconfig`
- `ios/Flutter/Profile-dev.xcconfig`
- `ios/Flutter/Profile-staging.xcconfig`
- `ios/Flutter/Profile-prod.xcconfig`
- `ios/Flutter/Release-dev.xcconfig`
- `ios/Flutter/Release-staging.xcconfig`
- `ios/Flutter/Release-prod.xcconfig`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/staging.xcscheme`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme`
- `docs/tasks/TASK-002-configurar-ambientes-dev-staging-prod-CONCLUIDA.md`

## Arquivos alterados

- `README.md`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner/Info.plist`
- `lib/main.dart`
- `lib/app/.gitkeep` (removido)
- `lib/core/.gitkeep` (removido)
- `test/widget_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

Bootstrap comum em `lib/app/bootstrap.dart` recebe um `AppEnvironment` e inicializa o app. A configuração mínima de ambiente fica isolada em `lib/core/environment/app_environment.dart`, sem dependências externas, Firebase, storage local ou acesso a backend.

## Regras de negócio implementadas

- `development` usa label `VestiPro Dev`, flavor `dev` e identificadores com sufixo `.dev`.
- `staging` usa label `VestiPro Staging`, flavor `staging` e identificadores com sufixo `.staging`.
- `production` usa label `VestiPro`, flavor `prod` e identificador final sem sufixo.
- `main.dart` mantém o comportamento padrão de desenvolvimento para `flutter run` sem flags.
- Web usa `lib/main_web.dart` com `--dart-define=ENVIRONMENT=development|staging|production`.

## Regras Firebase implementadas

Nenhuma. A task não referencia credenciais ou projetos Firebase.

## Analytics implementado

Nenhum.

## Crashlytics implementado

Nenhum.

## Impacto offline

Nenhum. Não houve banco local, cache offline ou sync.

## Impacto multi-tenant

Separação de ambientes reduz risco de mistura entre dados de desenvolvimento, staging e produção, mas nenhuma regra multi-tenant funcional foi implementada nesta task.

## Testes criados

- `test/core/environment/app_environment_test.dart`
- Atualização de `test/widget_test.dart` para validar o ambiente renderizado.

## Comandos executados

```bash
dart format --set-exit-if-changed .
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --flavor dev -t lib\main_dev.dart
flutter build apk --debug --flavor staging -t lib\main_staging.dart
flutter build apk --debug --flavor prod -t lib\main_prod.dart
flutter build web -t lib\main_web.dart --dart-define=ENVIRONMENT=staging
flutter build web -t lib\main_web.dart --dart-define=ENVIRONMENT=production
flutter build ipa --flavor staging -t lib\main_staging.dart
flutter build ipa
```

## Resultado do formatter

Primeira execução formatou 4 arquivos Dart. Segunda execução obrigatória passou limpa: `Formatted 9 files (0 changed)`.

## Resultado do analyzer

`flutter analyze` executado com sucesso: `No issues found!`.

## Resultado dos testes

`flutter test` executado com sucesso: 6 testes passaram.

## Decisões técnicas

- Criado `main_web.dart` adicional para atender Web via `--dart-define` sem quebrar o padrão de `main.dart` como ambiente dev.
- Android usa `productFlavors` com dimension `environment` e `manifestPlaceholders` para label.
- iOS usa `.xcconfig` por ambiente, configurações `Debug/Release/Profile` por flavor e schemes compartilhados `dev`, `staging` e `prod`.
- Nenhuma credencial ou configuração Firebase foi adicionada.

## Riscos conhecidos

- Builds iOS não puderam ser validados no host Windows. `flutter build ipa --flavor staging -t lib\main_staging.dart` falhou porque esta instalação não aceita `--flavor` nesse host; `flutter build ipa` falhou porque o subcomando `ipa` não está disponível aqui.
- O `project.pbxproj` foi atualizado mecanicamente para configs de flavor e deve ser validado em macOS/Xcode na primeira execução iOS.
- Existem arquivos não relacionados e não versionados em `assets/images/` que permaneceram fora da task.

## Pendências

- Validar schemes iOS `dev`, `staging` e `prod` em macOS com Xcode.
- Push depende de autorização explícita do usuário.

## Evidências

- Android gerou `app-dev-debug.apk`, `app-staging-debug.apk` e `app-prod-debug.apk`.
- Web staging gerou bundle contendo `VestiPro Staging` e `ENVIRONMENT=staging`.
- Web production gerou bundle contendo `ENVIRONMENT=production` e `VestiPro`.
- iOS ficou bloqueado por limitação do host Windows.

## Commit

Commit criado após a conclusão da documentação.

## Push

Não executado, pois não houve autorização explícita para push nesta conversa.

## Hash do commit

Informado na resposta final após o commit.

## Branch

`main`
