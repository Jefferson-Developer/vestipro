# ADR-0001 - Dependencias base do Flutter

## Status

Aceita em 2026-08-20.

## Contexto

A TASK-003 prepara o `pubspec.yaml` para as proximas tarefas do VestiPro. O projeto precisa de
pacotes para estado, navegacao, modelos, injecao de dependencia, banco local, Firebase,
midia, conectividade, metadados do app e testes, preservando Android, iOS e Web.

## Decisao

As dependencias foram adicionadas com constraints compativeis com Flutter 3.44.7 e Dart 3.12.2,
resolvidas por `flutter pub add` e registradas em `pubspec.lock`.

Pacotes de runtime:

- Estado: `bloc` e `flutter_bloc`.
- Navegacao: `go_router`.
- Injecao de dependencia: `get_it` e `injectable`.
- Modelos e serializacao: `freezed_annotation`, `json_annotation` e `collection`.
- Banco local/offline: `drift` e `drift_flutter`.
- Persistencia e seguranca local: `shared_preferences` para preferencias nao sensiveis e
  `flutter_secure_storage` para tokens/segredos.
- Conectividade: `connectivity_plus`, tratado apenas como sinal de transporte; chamadas de rede
  ainda devem lidar com timeout e erro.
- Midia/catalogo: `cached_network_image`, `flutter_svg`, `image_picker`, `file_picker`,
  `flutter_image_compress` e `photo_view`.
- Utilitarios: `intl`, `package_info_plus`, `device_info_plus` e `uuid`.
- REST externo futuro: `dio`, reservado para integracoes ERP/API publica. Firebase continua usando
  exclusivamente SDKs FlutterFire.
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`,
  `cloud_functions`, `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`,
  `firebase_messaging`, `firebase_remote_config` e `firebase_app_check`.

Pacotes de desenvolvimento:

- Geracao: `build_runner`, `freezed`, `json_serializable`, `drift_dev` e `injectable_generator`.
- Qualidade e testes: `flutter_lints`, `bloc_test`, `mocktail` e `network_image_mock`.

## Criterios aplicados

- Preferencia por pacotes oficiais, amplamente usados ou mantidos por publicadores reconhecidos.
- Sem frameworks completos que concorram com Clean Architecture, BLoC/Cubit ou `go_router`.
- Sem segundo gerenciador de estado, segundo roteador ou SDK REST para Firebase.
- Constraints estaveis sempre que possivel; nenhum pacote `dev` ou `beta` ficou como dependencia
  direta.
- `freezed` ficou fixado em `3.2.5` e `injectable_generator` em `^3.0.2` para manter uma combinacao
  estavel e compativel de `analyzer`, evitando o prerelease `freezed 3.2.6-dev.1`.
- `flutter_secure_storage` ficou em `^10.0.0`, em vez de `^11.0.0`, porque a linha 11 exige
  Android SDK 37.0 e quebrou o build Android deste projeto com o AGP/Flutter atuais. A linha 10
  preserva Android, iOS e Web sem forcar uma migracao de Gradle/AGP nesta task.
- Compatibilidade Web foi verificada para os plugins usados em fluxos Web. Excecao planejada:
  `firebase_crashlytics` e mobilidade nativa devem ser acessados por futuras abstracoes de
  observabilidade/plataforma, pois Crashlytics e alguns recursos nativos nao tem o mesmo suporte no
  Web.
- `drift_flutter` exige arquivos Web adicionais (`sqlite3.wasm` e worker) quando o banco local for
  ativado no Web; isso deve ser tratado na task de schema/offline.

## Consequencias

- As proximas tasks podem criar BLoCs, rotas, use cases, DTOs e repositories sem renegociar pacote.
- O lockfile passa a fixar uma arvore grande de dependencias, incluindo SDKs FlutterFire ainda nao
  inicializados.
- Tasks de Firebase devem inicializar servicos apenas a partir do EPIC-01, mantendo esta task restrita
  a dependencia e decisao tecnica.
- Tokens e dados sensiveis nao devem usar `shared_preferences`; use `flutter_secure_storage`.

## Fontes consultadas

- https://pub.dev/packages/firebase_core
- https://pub.dev/packages/firebase_auth
- https://pub.dev/packages/cloud_firestore
- https://pub.dev/packages/firebase_crashlytics
- https://pub.dev/packages/drift_flutter
- https://pub.dev/packages/flutter_secure_storage
- https://pub.dev/packages/connectivity_plus
- https://pub.dev/packages/file_picker
- https://pub.dev/packages/flutter_image_compress
- https://pub.dev/packages/freezed
