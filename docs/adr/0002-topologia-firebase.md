# ADR-0002 - Topologia de projetos Firebase

## Status

Aceita em 2026-08-20.

## Contexto

A TASK-010 precisa provisionar a infraestrutura Firebase (Authentication, Firestore, Storage,
Functions, Analytics, Crashlytics, Remote Config, Performance, App Check, Cloud Messaging) que vai
sustentar o VestiPro, isolada por ambiente sempre que possível, e habilitar o Firebase Emulator
Suite para desenvolvimento local sem tocar em dados reais.

O backlog (`docs/tasks/TASK-010-criar-projetos-firebase.md`) recomendava três projetos Firebase
distintos (`vestipro-dev`, `vestipro-staging`, `vestipro-prod`) como padrão de mercado para
isolamento real de dados entre ambientes.

Ao iniciar a execução, já existia um projeto Firebase real e único, `vestipro` (project number
`184451052714`), criado fora do fluxo de código, com apps Android, iOS e Web já registrados nele e
`android/app/google-services.json` já baixado localmente. Não havia projetos separados de
dev/staging. O responsável pelo produto confirmou explicitamente que a intenção é ter **apenas um
ambiente Firebase, o de produção**, em vez dos três projetos recomendados pelo backlog.

## Decisão

- Existe um único projeto Firebase real: `vestipro`, tratado como o ambiente de **produção**.
  Não serão criados projetos `vestipro-dev` nem `vestipro-staging`.
- Os apps Android, iOS e Web já registrados no projeto `vestipro` (ver `firebase.json` e
  `firebase apps:list`) são os apps oficiais de produção:
  - Android: `1:184451052714:android:db447cc0d912f83e5a4cd3` (`br.com.dinosoft.vestipro`)
  - iOS: `1:184451052714:ios:fcbf7552d8d61bc75a4cd3` (`br.com.dinosoft.vestipro`)
  - Web: `1:184451052714:web:79e186deec496ef95a4cd3`
- Os flavors `dev` e `staging` do app (criados na TASK-002) **nunca** apontam para o projeto
  `vestipro` real. Eles usam exclusivamente o Firebase Emulator Suite local (Auth, Firestore,
  Storage, Functions) configurado em `firebase.json`.
- Apenas o flavor `prod` (`lib/main_prod.dart`) inicializa o Firebase apontando para o projeto real
  `vestipro`. A conexão condicional ao Emulator Suite por ambiente (`AppEnvironment`) será
  implementada na TASK-011, que integra o Firebase Core na inicialização do app; esta ADR apenas
  fixa a decisão de infraestrutura que a TASK-011 deve respeitar.
- `lib/firebase_options.dart` é gerado por `flutterfire configure` como um único arquivo (não há
  arquivos por ambiente, pois há apenas um projeto Firebase real). O arquivo é gitignorado
  (`/lib/firebase_options*.dart`) e deve ser gerado localmente por quem for rodar o app com Firebase
  real, conforme instruções no `README.md`.

## Consequências

- Isolamento de dados entre desenvolvimento/staging e produção passa a depender inteiramente do
  Emulator Suite, e não de projetos Firebase distintos. Se algum dia um desenvolvedor inicializar o
  Firebase real (não o emulador) usando um flavor `dev`/`staging`, ele vai ler/escrever dados de
  produção — a mitigação é a TASK-011 nunca permitir isso por padrão (emulador é o padrão para
  `dev`/`staging`; produção exige o flavor `prod` explícito).
- Não há Firestore/Storage/Auth de staging para testar mudanças de regras ou dados antes de
  produção; validação de regras e fluxos deve ocorrer no Emulator Suite antes de qualquer deploy
  para `vestipro`.
- Reduz custo e complexidade de manter três projetos Firebase, ao custo do isolamento real descrito
  acima — decisão explícita do responsável pelo produto, não uma limitação técnica.
- Toda alteração de Firestore/Storage Security Rules (TASK-030/TASK-031) e de Cloud Functions
  (TASK-015) deploya direto em produção; não há projeto de staging para ensaiar.
- O app iOS (`GoogleService-Info.plist`) não pôde ser gerado nesta task porque o `flutterfire_cli`
  só escreve/injeta esse arquivo no Xcode project quando executado em host macOS (usa a gem Ruby
  `xcodeproj`); a máquina de desenvolvimento atual é Windows. `lib/firebase_options.dart` já contém
  as opções do app iOS (obtidas via API remota do Firebase, não do plist), então o Dart compila
  normalmente; falta apenas gerar/anexar o `.plist` ao projeto Xcode em um host macOS antes do
  primeiro build iOS real. Isso fica registrado como pendência, no mesmo padrão do risco já
  documentado em `docs/tasks/TASK-002-configurar-ambientes-dev-staging-prod-CONCLUIDA.md`.

## Fontes consultadas

- `firebase projects:list`, `firebase apps:list --project vestipro` (CLI autenticado na máquina de
  desenvolvimento).
- https://firebase.google.com/docs/cli
- https://firebase.google.com/docs/emulator-suite
- https://firebase.google.com/docs/flutter/setup
- Confirmação explícita do responsável pelo produto nesta conversa: apenas ambiente de produção no
  Firebase; dev/staging via Emulator Suite.
