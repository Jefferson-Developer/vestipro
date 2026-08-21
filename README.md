# VestiPro

Plataforma omnichannel de força de vendas para o mercado de moda B2B (Flutter + Firebase): CRM,
catálogo de produtos por cor/grade, tabelas de preço, pedidos, operação offline real, inteligência
comercial e BI — multi-tenant desde a fundação, com foco em ser **o sistema de força de vendas
mobile mais completo do mercado de moda**.

Este projeto segue um protocolo único de execução de backlog, descrito em [`AGENTS.md`](AGENTS.md).
O backlog técnico e o status de progresso ficam em [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md);
cada task individual está documentada em `docs/tasks/TASK-XXX-*.md`. A especificação funcional
completa do produto está em [`tasks.md`](tasks.md).

## Versão do Flutter

Este projeto foi inicializado e validado com:

- Flutter 3.44.7 stable
- Dart 3.12.2

A versão recomendada também está registrada em [`.fvmrc`](.fvmrc), para reprodutibilidade entre
máquinas de desenvolvimento e CI.

## Como rodar

```bash
flutter pub get
flutter run
```

Para Web:

```bash
flutter run -d chrome
```

## Qualidade estática

Antes de concluir uma task com código Dart/Flutter, execute:

```powershell
.\scripts\check.ps1
```

O script valida `dart format --set-exit-if-changed .`, `flutter analyze` e comentários `TODO`/`FIXME`
sem referência de task, issue ou URL. As regras e limites de revisão ficam em
[`docs/architecture/static-quality.md`](docs/architecture/static-quality.md).

## Ambientes

O VestiPro possui três ambientes isolados, com nomes visuais e identifiers distintos:

- `development` / `dev`: VestiPro Dev
- `staging`: VestiPro Staging
- `production` / `prod`: VestiPro

`flutter run` sem flags usa o ambiente `development`.

### Android

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --release --flavor prod -t lib/main_prod.dart
```

### iOS

Os schemes compartilhados são `dev`, `staging` e `prod`, com `.xcconfig` próprios em `ios/Flutter/`.

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

flutter build ipa --flavor staging -t lib/main_staging.dart
flutter build ipa --flavor prod -t lib/main_prod.dart
```

Builds iOS exigem macOS com Xcode.

### Web

Flutter Web não usa flavors nativos; o ambiente é escolhido por `--dart-define`.

```bash
flutter run -d chrome -t lib/main_web.dart --dart-define=ENVIRONMENT=development
flutter run -d chrome -t lib/main_web.dart --dart-define=ENVIRONMENT=staging
flutter run -d chrome -t lib/main_web.dart --dart-define=ENVIRONMENT=production

flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=staging
flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=production
```

## Como continuar o backlog

```
/proxima-task
```

ou, em qualquer ferramenta (Claude Code ou Codex CLI):

```
Rode a próxima task pendente do backlog em docs/tasks/TASKS.md
```

Isso abre `docs/tasks/TASKS.md`, localiza a primeira task pendente e executa o fluxo obrigatório
completo descrito em `AGENTS.md` (agentes especializados, testes, documentação, commit).

## Agentes especializados

- `.claude/agents/flutter-senior-architect.md` — arquitetura, domain, data, Firebase, multi-tenancy,
  RBAC, offline-first, motor de precificação, engine de insights, agregações de BI, segurança,
  testes, CI/CD.
- `.claude/agents/flutter-ui-design-specialist.md` — interface, Design System, componentes,
  responsividade, acessibilidade, UX premium de moda.

## Estrutura de pastas

```text
lib/
├── app/
├── core/            # analytics, auth, database, design_system, errors, navigation, network,
│                     # offline, permissions, services, sync, utils
├── features/         # authentication, onboarding, organizations, users, crm, customers, products,
│                     # catalog, inventory, pricing, orders, dashboards, reports, insights, targets,
│                     # notifications, settings
└── main.dart
```

`core/` possui apenas a configuração mínima de ambiente criada na TASK-002; `features/` ainda não
possui feature real. A arquitetura completa (Clean Architecture por feature, BLoC, injeção de
dependência, navegação com `go_router`, offline-first com Drift) está descrita em
`.claude/agents/flutter-senior-architect.md` e será adicionada progressivamente pelas próximas tasks.

## Backend e Firebase

Firebase: Authentication, Cloud Firestore, Storage, Cloud Functions, Analytics, Crashlytics,
Performance Monitoring, Cloud Messaging, Remote Config, App Check.

### Topologia

Existe **um único projeto Firebase real: `vestipro`**, tratado como ambiente de **produção**. Não
há projetos `vestipro-dev`/`vestipro-staging`. Os flavors `dev` e `staging` do app usam
exclusivamente o Firebase Emulator Suite local; apenas o flavor `prod` conecta no projeto real.
Decisão completa e motivos em [`docs/adr/0002-topologia-firebase.md`](docs/adr/0002-topologia-firebase.md).
`Firebase.initializeApp` roda uma única vez, em `lib/app/bootstrap.dart`, chamado por todos os
entrypoints (TASK-011); falhas de inicialização exibem uma tela de erro amigável em vez de crash ou
tela branca. A conexão condicional a cada emulador (Auth, Firestore, Storage, Functions) é
responsabilidade de cada task que configura o respectivo SDK (TASK-012 a TASK-015). O Auth já está
conectado (TASK-012): `FirebaseAuthDataSource` (`lib/core/auth/data/datasources/`) chama
`useAuthEmulator` para todo flavor que não seja `prod` assim que é resolvido pelo container de DI —
não em `bootstrap.dart`, para não travar testes de widget que nunca tocam `firebase_auth` (ver
`resolveFirebaseEmulatorHost`/`FirebaseEmulatorPorts` em `lib/core/environment/`, reutilizáveis pelas
TASK-013/014/015). O Firestore também já está conectado (TASK-013): o provider `FirebaseFirestore`
de `lib/app/injection_module.dart` chama `configureFirestore` (`lib/core/database/`), que habilita
persistência nativa e conecta ao emulador fora do `prod`, só quando algo resolve essa dependência via
DI. Acesso genérico ao Firestore (datasource base tipado, paginação por cursor, mapeamento de erros,
modelo inicial de collections) está documentado em
[`docs/architecture/firestore-schema.md`](docs/architecture/firestore-schema.md). O Storage também já
está conectado (TASK-014): o provider `FirebaseStorage` de `lib/app/injection_module.dart` chama
`configureStorage` (`lib/core/storage/`), que conecta ao emulador fora do `prod` da mesma forma.
`FirebaseStorageDataSource` centraliza upload (com progresso e cancelamento via
`StorageUploadCancelToken`), download e exclusão; `StoragePaths` centraliza a convenção de path por
organização (`organizations/{organizationId}/products|orders|users/...`); `ImageUploadCompressor`
comprime fotos de produto antes do upload usando `flutter_image_compress`. Nenhuma feature usa o
Storage ainda (só entra a partir do EPIC-08/TASK-068). O Functions também já está conectado
(TASK-015): o codebase TypeScript em [`functions/`](functions/README.md) hospeda toda regra crítica
que não pode depender só do cliente (autorização fina, preço, número de pedido, aprovações, regras
financeiras — ver `AGENTS.md`), estruturado por domínio (`src/health`, e os reservados `src/auth`,
`src/pricing`, `src/orders`, `src/insights`, `src/admin`, populados pelas tasks correspondentes) e
com uma função de exemplo (`healthCheck`, callable) validando o pipeline de ponta a ponta. O provider
`FirebaseFunctions` de `lib/app/injection_module.dart` chama `configureFunctions`
(`lib/core/functions/`), que conecta ao emulador fora do `prod` da mesma forma que Firestore/Storage.
`CloudFunctionsService` (`lib/core/functions/cloud_functions_service.dart`) é o único ponto do app
autorizado a chamar `cloud_functions`: adiciona correlation id, versão do app/plataforma (sob a
chave `_meta`, para nunca colidir com o payload de cada função), retry com backoff só para códigos de
erro transitórios, medição de tempo de resposta (seam para a TASK-019/Performance Monitoring) e
converte toda `FirebaseFunctionsException` para a hierarquia `AppException`/`Failure` existente.

### Configuração local

Os arquivos gerados pelo FlutterFire CLI contêm chaves de API e nunca são commitados
(`.gitignore`): `lib/firebase_options.dart`, `android/app/google-services.json` e
`ios/Runner/GoogleService-Info.plist`. Para gerá-los localmente:

```bash
dart pub global activate flutterfire_cli
flutterfire configure -p vestipro --platforms=android,ios,web
```

O app iOS (`GoogleService-Info.plist`) só é escrito/injetado no projeto Xcode quando o comando
roda em **host macOS** (o FlutterFire CLI usa a gem Ruby `xcodeproj`); em outros sistemas apenas
`lib/firebase_options.dart` é gerado com as opções do iOS (sem o arquivo `.plist` físico).

### Firebase Emulator Suite

```bash
firebase emulators:start --only auth,firestore,storage,functions
```

| Emulador   | Porta |
|------------|-------|
| Auth       | 9099  |
| Firestore  | 8080  |
| Storage    | 9199  |
| Functions  | 5001  |
| UI         | 4000  |

Os emuladores de **Firestore e Storage exigem um JRE (Java) instalado e no `PATH`** — Auth e
Functions não. `firestore.rules` e `storage.rules` ficam com acesso negado por padrão
(`allow read, write: if false;`) até as regras reais de RBAC/multi-tenant chegarem nas
TASK-030/TASK-031. `functions/` já tem a função de exemplo `healthCheck` (TASK-015); as pastas de
domínio (`pricing`, `orders`, `insights`, `auth`, `admin`) continuam vazias de propósito até as
tasks correspondentes.

## Documentação

- Protocolo de execução do backlog: [`AGENTS.md`](AGENTS.md)
- Backlog e status: [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md)
- Especificação funcional completa: [`tasks.md`](tasks.md)
