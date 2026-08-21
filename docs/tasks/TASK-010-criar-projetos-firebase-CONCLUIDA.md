# TASK-010 — Concluída (2026-08-20)

## Resumo

Firebase provisionado para o VestiPro com um único projeto real, `vestipro` (produção), conforme
decisão explícita do responsável pelo produto (ADR-0002). `lib/firebase_options.dart` gerado via
FlutterFire CLI para Android/iOS/Web, Firebase Emulator Suite configurado (Auth, Firestore,
Storage, Functions) para uso exclusivo dos flavors `dev`/`staging`, e correção de uma regressão de
build Android causada pelo Gradle plugin do Google Services nesses flavors.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `docs/adr/0002-topologia-firebase.md`
- `firestore.rules`
- `storage.rules`
- `firestore.indexes.json`
- `functions/package.json`
- `functions/index.js`
- `functions/package-lock.json` (gerado por `npm install`)
- `lib/firebase_options.dart` (gerado por `flutterfire configure`; gitignorado, não commitado)
- `docs/tasks/TASK-010-criar-projetos-firebase-CONCLUIDA.md`

## Arquivos alterados

- `firebase.json` (adicionadas as chaves `firestore`, `storage`, `functions` e `emulators`,
  preservando a configuração `flutter` já gerada pelo FlutterFire CLI)
- `android/app/build.gradle.kts` (plugins Google Services/Crashlytics/Performance adicionados pelo
  FlutterFire CLI + filtro de tasks para restringir o Google Services ao flavor `prod`)
- `android/settings.gradle.kts` (versões dos plugins Google Services/Crashlytics/Performance,
  adicionadas pelo FlutterFire CLI)
- `android/app/google-services.json` (regerado pelo FlutterFire CLI; gitignorado, não commitado)
- `README.md` (seção "Backend e Firebase": topologia, configuração local, Emulator Suite)
- `docs/tasks/TASKS.md` (checkbox da TASK-010 e progresso)

## Arquitetura utilizada

Nenhuma camada de domínio/data foi tocada. Escopo estritamente de infraestrutura Firebase e
configuração de build, como definido na TASK-010 (EPIC-01).

## Regras de negócio implementadas

Nenhuma regra de negócio funcional. Regra de infraestrutura fixada via ADR-0002: apenas produção
tem projeto Firebase real; `dev`/`staging` nunca inicializam contra dados reais.

## Regras Firebase implementadas

- `firestore.rules` e `storage.rules`: placeholder "deny all" (`allow read, write: if false;`) até
  as regras reais de RBAC/multi-tenant chegarem nas TASK-030/TASK-031. Nunca deployado (nenhum
  `firebase deploy` foi executado nesta task).
- `functions/`: codebase vazio de propósito, apenas para o Functions emulator subir; funções reais
  entram na TASK-015.
- Filtro de Gradle (`android/app/build.gradle.kts`) desabilita a task `process<Variant>GoogleServices`
  para qualquer variante que não seja `Prod`, evitando que o build de `dev`/`staging` dependa de um
  client Firebase inexistente para `br.com.dinosoft.vestipro.dev`/`.staging`.

## Analytics implementado

Nenhum. SDKs não inicializados nesta task (fica para a TASK-011 em diante).

## Crashlytics implementado

Nenhum. Plugin Gradle wireado (`com.google.firebase.crashlytics`) pelo FlutterFire CLI, mas sem
inicialização de SDK — isso é escopo da TASK-016.

## Impacto offline

Nenhum.

## Impacto multi-tenant

Nenhuma regra multi-tenant funcional. A separação dev/staging vs. produção agora depende do
Emulator Suite (não de projetos Firebase distintos) — decisão e riscos documentados no ADR-0002.

## Testes criados

Nenhum teste Dart novo (task de infraestrutura, sem código de app). Validação feita via comandos
diretos, listados abaixo.

## Comandos executados

```bash
firebase projects:list
firebase apps:list --project vestipro
flutterfire configure -y -p vestipro -o lib/firebase_options.dart --platforms=android,ios,web \
  -a br.com.dinosoft.vestipro -i br.com.dinosoft.vestipro \
  -w 1:184451052714:web:79e186deec496ef95a4cd3 \
  --android-out=android/app/google-services.json
cd functions && npm install
firebase emulators:start --only auth,functions --project vestipro
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor prod -t lib/main_prod.dart
```

## Resultado do formatter

`Formatted 68 files (0 changed)`.

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

`flutter test`: 37 testes, todos passaram.

## Decisões técnicas

- ADR-0002: um único projeto Firebase real (`vestipro`, produção); `dev`/`staging` usam somente o
  Firebase Emulator Suite local. Decisão explícita do responsável pelo produto nesta conversa,
  divergindo da recomendação padrão de três projetos do texto original da TASK-010.
- `firebase.json` ganhou as chaves `firestore`/`storage`/`functions`/`emulators` como campos
  irmãos da chave `flutter` já gerada pelo FlutterFire CLI, sem alterar o conteúdo desta última.
- `firestore.rules`/`storage.rules` como "deny all" — mais seguro que qualquer alternativa
  permissiva, coerente com "não enfraquecer segurança" mesmo antes do RBAC real (TASK-030/031).
- `functions/` criado vazio (sem funções reais) apenas para o emulador de Functions ter um
  codebase válido, exigido pelo próprio critério de teste da TASK-010; a task de negócio
  (TASK-015) é responsável por preencher esse codebase.
- Corrigida uma regressão real: o FlutterFire CLI aplica os plugins Gradle de Google
  Services/Crashlytics/Performance de forma global, o que quebrava `assembleDevDebug` e
  `assembleStagingDebug` (o plugin do Google Services exige um client em `google-services.json`
  para o `applicationId` exato do build, e só existe client para `br.com.dinosoft.vestipro`, sem
  sufixo). Corrigido restringindo a task `process<Variant>GoogleServices` ao flavor `Prod` via
  `tasks.whenTaskAdded` em `android/app/build.gradle.kts`. As três variantes (`dev`, `staging`,
  `prod`) foram build-testadas depois da correção.

## Riscos conhecidos

- `ios/Runner/GoogleService-Info.plist` não foi gerado nem injetado no projeto Xcode: o
  FlutterFire CLI só faz essa escrita em host macOS (usa a gem Ruby `xcodeproj`), e a máquina de
  desenvolvimento atual é Windows. `lib/firebase_options.dart` já contém as opções reais do app iOS
  (obtidas via API do Firebase), então o Dart compila; falta apenas o arquivo `.plist` físico e o
  passo de bundling no Xcode antes do primeiro build iOS real, em uma máquina macOS.
- Os emuladores de Firestore e Storage exigem um JRE (Java) instalado no `PATH`, que não está
  presente nesta máquina — confirmado ao rodar `firebase emulators:start`. Auth e Functions
  emulators foram validados com sucesso (subiram sem erro). Firestore/Storage emulator ficam sem
  validação de boot local até um JRE ser instalado; decisão explícita do responsável pelo produto
  de não instalar Java nesta sessão.
- `functions/node_modules` foi instalado localmente (~250 pacotes) só para permitir o teste do
  Functions emulator; está gitignorado e precisará de `npm install` em qualquer outra máquina.
- Encontrados arquivos não relacionados ao projeto em `assets/images/` (`AnyDesk.exe`, `gcapi.dll`,
  `service.conf.lock`, `system.conf.lock`), não rastreados pelo Git. Já eram um risco conhecido
  registrado em `docs/tasks/TASK-002-configurar-ambientes-dev-staging-prod-CONCLUIDA.md`; o
  responsável pelo produto confirmou nesta conversa que reconhece a origem desses arquivos e pediu
  para ignorá-los. Nenhuma ação foi tomada sobre eles nesta task.

## Pendências

- Gerar/injetar `ios/Runner/GoogleService-Info.plist` em host macOS antes do primeiro build iOS
  real (`flutterfire configure -p vestipro --platforms=ios`).
- Instalar um JRE para validar `firebase emulators:start --only firestore,storage` localmente
  (pendência aceita explicitamente pelo responsável pelo produto).
- TASK-011 deve implementar a inicialização condicional do Firebase (emulador para `dev`/`staging`,
  projeto real para `prod`), respeitando o ADR-0002.
- Push depende de autorização explícita do usuário.

## Evidências

- `firebase apps:list --project vestipro` confirmou os 3 apps (android/ios/web) já registrados no
  projeto real.
- `lib/firebase_options.dart` gerado com `FirebaseOptions` válidas para os 3 apps (web, android,
  ios) — verificado por leitura direta do arquivo.
- `firebase emulators:start --only auth,functions --project vestipro` subiu com sucesso: "All
  emulators ready! It is now safe to connect your app." (Auth em 9099, Functions em 5001, UI em
  4000).
- `flutter build apk --debug --flavor dev|staging|prod` gerou `app-dev-debug.apk`,
  `app-staging-debug.apk` e `app-prod-debug.apk` com sucesso após a correção do filtro de Gradle.

## Commit

Commit criado após a conclusão da documentação.

## Push

Não executado, pois não houve autorização explícita para push nesta conversa.

## Hash do commit

`f288ee1`

## Branch

`main`
