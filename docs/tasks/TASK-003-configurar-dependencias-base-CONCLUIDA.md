# TASK-003 - Concluida (2026-08-20)

## Resumo

Dependencias base do VestiPro configuradas em `pubspec.yaml` e travadas em `pubspec.lock`, cobrindo
BLoC/Cubit, navegacao, injecao de dependencia, modelos, Drift, Firebase, midia, utilitarios e testes.
Tambem foi criado o ADR `docs/adr/0001-dependencias-base.md` com os criterios de escolha e excecoes
de compatibilidade.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `docs/adr/0001-dependencias-base.md`
- `docs/tasks/TASK-003-configurar-dependencias-base-CONCLUIDA.md`

## Arquivos alterados

- `pubspec.yaml`
- `pubspec.lock`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

A task ficou restrita a fundacao tecnica. As dependencias escolhidas preservam a arquitetura
feature-first + Clean Architecture prevista para as proximas tasks: UI com BLoC/Cubit, rotas com
`go_router`, DI com `get_it`/`injectable`, modelos com `freezed`/`json_serializable`, repositorios
aptos a usar FlutterFire e banco local futuro com Drift.

## Regras de negocio implementadas

Nenhuma regra de negocio foi implementada. A decisao relevante foi reservar `shared_preferences`
apenas para preferencias nao sensiveis e `flutter_secure_storage` para tokens/segredos.

## Regras Firebase implementadas

Nenhuma regra Firebase foi criada ou alterada. Os SDKs FlutterFire foram adicionados para uso a partir
do EPIC-01, sem inicializacao de Firebase nesta task.

## Analytics implementado

Nenhum evento foi implementado. `firebase_analytics` foi adicionado como dependencia base para as
tasks futuras.

## Crashlytics implementado

Nenhuma captura foi implementada. `firebase_crashlytics` foi adicionado como dependencia base, com a
observacao no ADR de que o acesso deve passar por futura abstracao de observabilidade, especialmente
para preservar Web.

## Impacto offline

`drift` e `drift_flutter` foram adicionados para a fundacao offline. Nenhum schema, cache, outbox ou
sync foi criado nesta task. O ADR registra que o suporte Web do Drift exigira `sqlite3.wasm` e worker
quando o banco local for ativado.

## Impacto multi-tenant

Nenhuma regra multi-tenant foi implementada. A task apenas prepara bibliotecas para futuros
repositories, use cases e SDKs backend que deverao manter isolamento por tenant.

## Testes criados

Nenhum teste novo foi necessario, pois nao houve regra de dominio nem UI nova. Os testes existentes
foram executados apos a mudanca de dependencias.

## Comandos executados

```bash
flutter --version
dart --version
flutter pub add flutter_bloc bloc get_it injectable go_router freezed_annotation json_annotation collection drift drift_flutter shared_preferences flutter_secure_storage connectivity_plus cached_network_image flutter_svg intl image_picker file_picker flutter_image_compress photo_view package_info_plus device_info_plus uuid dio firebase_core firebase_auth cloud_firestore firebase_storage cloud_functions firebase_analytics firebase_crashlytics firebase_performance firebase_messaging firebase_remote_config firebase_app_check
flutter pub add --dev build_runner freezed json_serializable drift_dev injectable_generator flutter_lints bloc_test mocktail network_image_mock
flutter pub add --dev freezed:^3.2.5
flutter pub add --dev freezed:^3.2.5 injectable_generator:^3.0.0
flutter pub add --dev injectable_generator:^3.0.2
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
flutter build apk --debug --flavor dev -t lib\main_dev.dart
sdkmanager --list
flutter pub add flutter_secure_storage:^10.0.0
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
flutter build apk --debug --flavor dev -t lib\main_dev.dart
```

## Resultado do formatter

`dart format --set-exit-if-changed .` executado com sucesso na rodada final:
`Formatted 9 files (0 changed)`.

## Resultado do analyzer

`flutter analyze` executado com sucesso na rodada final: `No issues found!`.

## Resultado dos testes

`flutter test` executado com sucesso na rodada final: 6 testes passaram.

## Decisoes tecnicas

- `flutter pub add` foi usado para deixar `pubspec.yaml` e `pubspec.lock` consistentes.
- `dio` foi adicionado e documentado apenas para REST externo futuro; Firebase deve usar FlutterFire.
- `freezed` foi fixado em `3.2.5` e `injectable_generator` em `3.0.2` para evitar prerelease e manter
  compatibilidade de `analyzer`.
- `flutter_secure_storage` ficou em `^10.0.0` porque `^11.0.0` exigiu Android SDK 37.0 e quebrou o
  build Android atual; a linha 10 passou no APK debug.
- Nenhum framework alternativo de arquitetura, estado ou navegacao foi adicionado.

## Riscos conhecidos

- `firebase_crashlytics` nao declara suporte Web no pub.dev; uso futuro deve passar por abstracao de
  `CrashReporter` com no-op/alternativa Web.
- Plugins FlutterFire exibiram aviso de migracao futura para Built-in Kotlin no build Android. O build
  atual passou, mas a migracao deve ser acompanhada quando os plugins atualizarem.
- Build iOS nao foi validado neste host Windows.
- Existem arquivos nao relacionados e nao versionados em `assets/images/` que permaneceram fora desta
  task.

## Pendencias

- Validar iOS em macOS/Xcode.
- Reavaliar `flutter_secure_storage ^11` quando o projeto migrar para Android SDK/AGP compativel com
  API 37.0.
- Push depende de autorizacao explicita do usuario.

## Evidencias

- Flutter: `Flutter 3.44.7`, `Dart 3.12.2`.
- `flutter pub get`: concluiu com `Got dependencies!`.
- Web: `flutter build web` gerou `build\web`.
- Android: `flutter build apk --debug --flavor dev -t lib\main_dev.dart` gerou
  `build\app\outputs\flutter-apk\app-dev-debug.apk`.

## Commit

Commit criado apos a conclusao da documentacao.

## Push

Nao executado, pois nao houve autorizacao explicita para push nesta conversa.

## Hash do commit

Informado na resposta final apos o commit.

## Branch

`main`
