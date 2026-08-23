# TASK-032 — Concluída (2026-08-23)

## Resumo

Implementada a ativação do Firebase App Check (`firebase_app_check`, já presente no `pubspec.yaml`
mas nunca inicializado no código) como a terceira camada da trinca de Segurança e Multi-Tenancy
iniciada por `firestore.rules` (TASK-030) e `storage.rules` (TASK-031). Foi criado o módulo
`lib/core/security/` com `configureAppCheck`, que ativa o provider correto por plataforma e por
ambiente, seguindo exatamente o padrão já usado para os demais SDKs Firebase do projeto (`configure*`
+ provider `@lazySingleton` em `lib/app/injection_module.dart`, disparado só quando algo resolve a
dependência via DI, nunca em `bootstrap.dart`). Como o projeto usa um único projeto Firebase real
(ADR-0002 — `development`/`staging` só falam com o Emulator Suite, que não faz enforcement de App
Check), a decisão foi: `development`/`staging` sempre ativam o Debug provider em toda plataforma;
`production` ativa Play Integrity (Android) e App Attest com fallback DeviceCheck (iOS/macOS), e só
ativa reCAPTCHA v3 na Web quando um site key real for configurado via `--dart-define` (App Check
ainda não foi registrado no Firebase Console do projeto `vestipro` — passo manual, fora do escopo de
código, documentado como pendência). Para garantir que a ativação do App Check sempre aconteça antes
de qualquer chamada real a Firestore/Storage/Functions, os providers `firebaseFirestore`,
`firebaseStorage` e `firebaseFunctions` (`lib/app/injection_module.dart`) passaram a declarar
`FirebaseAppCheck` como parâmetro (não usado no corpo), forçando o `injectable` a resolver o App
Check primeiro. `injection.config.dart` foi regenerado via `build_runner`.

## Agentes utilizados

- `flutter-senior-architect` (único exigido pela task).

## Arquivos criados

- `lib/core/security/configure_app_check.dart` — função `configureAppCheck`, constantes
  `appCheckWebRecaptchaSiteKey` e `appCheckDebugToken` (ambas lidas de `--dart-define`, nunca
  hardcoded).
- `lib/core/security/security.dart` — barrel do novo módulo.
- `test/core/security/configure_app_check_test.dart` — 7 testes unitários (ver "Testes criados").
- `docs/tasks/TASK-032-configurar-firebase-app-check-CONCLUIDA.md` — este arquivo.

## Arquivos alterados

- `lib/app/injection_module.dart` — novo provider `@lazySingleton FirebaseAppCheck firebaseAppCheck`
  (chama `configureAppCheck` via `unawaited`, mesmo padrão de `firebaseRemoteConfig`/
  `firebasePerformance`); `firebaseFirestore`, `firebaseStorage` e `firebaseFunctions` passaram a
  receber `FirebaseAppCheck appCheck` como parâmetro extra (não usado no corpo, só para ordenar a
  resolução do `injectable`).
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` (registra
  `FirebaseAppCheck` antes de `FirebaseFirestore`/`FirebaseStorage`/`FirebaseFunctions`; sem nenhuma
  mudança manual).
- `README.md` — novo parágrafo em "Firebase Emulator Suite" explicando a ativação do App Check por
  ambiente/plataforma e o status pendente do reCAPTCHA v3 Web.
- `docs/tasks/TASKS.md` — checkbox da TASK-032 marcado e `Progresso` atualizado para `32 / 220`.

## Arquitetura utilizada

Mesmo padrão arquitetural já estabelecido para todo SDK Firebase do projeto: uma função
`configure<Produto>(instância, {required AppEnvironment environment})` isolada em `lib/core/<módulo>`
(aqui, um módulo novo, `lib/core/security/`, coerente com o EPIC-03 — Segurança e Multi-Tenancy), sem
nenhuma dependência de Flutter/widget, chamada a partir de um provider `@lazySingleton` em
`lib/app/injection_module.dart`. Nenhuma feature/UI chama `FirebaseAppCheck.instance` diretamente.
Domain permanece livre de Firebase.

## Regras de negócio implementadas

- App Check nunca substitui RBAC/Security Rules — é sempre uma camada adicional de proteção contra
  abuso, nunca o único mecanismo de autorização (restrição explícita da task, refletida na doc do
  código e no README).
- `development`/`staging` sempre ativam o Debug provider (Android/iOS/Web), nunca enforcement estrito
  sem debug provider — restrição explícita da task já satisfeita por construção (a função não tem
  nenhum branch que ative um provider real fora de `production`).
- Nenhum token de debug foi commitado: os dois valores potencialmente sensíveis
  (`appCheckDebugToken`, `appCheckWebRecaptchaSiteKey`) são lidos exclusivamente de
  `String.fromEnvironment` (`--dart-define`), com fallback vazio — nunca hardcoded no repositório.
- Web em `production` sem site key configurado não ativa nenhum provider Web (evita ativar com chave
  vazia/bogus, que quebraria toda chamada Web assim que o enforcement for ligado no Console).

## Regras Firebase implementadas

Nenhuma alteração em `firestore.rules`/`storage.rules` nesta task — enforcement de App Check por
produto (Firestore, Storage, Cloud Functions callable) é uma configuração exclusiva do Firebase
Console (Monitor vs. Enforce), não expressável em Security Rules nem no cliente Flutter; documentado
na doc do código (`configure_app_check.dart`) como rollout recomendado (Monitor primeiro, Enforce
depois de confirmar que o tráfego legítimo já carrega token válido). Ainda não foi executado porque
App Check não está registrado no Console para o projeto `vestipro` (ver "Pendências").

## Analytics implementado

N/A — task não envolve evento de produto/Analytics.

## Crashlytics implementado

N/A — `configureAppCheck` nunca lança (todo erro é só logado via `dart:developer`, mesmo padrão de
`configureRemoteConfig`/`configurePerformance`); não há necessidade de reportar ao Crashlytics uma
falha de ativação de App Check, já que o app continua funcionando normalmente (Security Rules/RBAC
seguem autorizando) mesmo sem token.

## Impacto offline

Nenhum. App Check só afeta chamadas de rede reais a Firestore/Storage/Functions; nenhum fluxo de
Outbox/sync existe ainda no app (chega em EPICs futuros). O Emulator Suite (usado por
`development`/`staging`) não faz enforcement de App Check, então nenhum teste local/offline é
afetado.

## Impacto multi-tenant

Nenhuma mudança de isolamento cross-tenant nesta task — isso já é garantido por
`firestore.rules`/`storage.rules` (TASK-030/031) e pelo RBAC (TASK-029). App Check é ortogonal:
verifica *o que* está chamando (build genuína vs. bot/app adulterado), não *quem* está chamando
(Membership/capability), então não interfere no isolamento por `organizationId` já existente.

## Testes criados

`test/core/security/configure_app_check_test.dart` — 7 casos, usando um fake escrito à mão
(`_FakeFirebaseAppCheck extends Fake implements FirebaseAppCheck`) em vez de `mocktail` `Mock`,
porque `FirebaseAppCheck.activate` tem parâmetros nomeados depreciados com valores default
(`androidProvider`/`appleProvider`) que tornariam a verificação via `mocktail` bem mais frágil do que
simplesmente sobrescrever os dois métodos e capturar o que foi passado:

- Habilita `setTokenAutoRefreshEnabled(true)` para todo ambiente.
- `development` ativa o Debug provider (Android/iOS/Web).
- `staging` ativa o Debug provider (Android/iOS/Web) — mesmo comportamento de `development`, citando
  a razão (ADR-0002: staging nunca toca o projeto real).
- `production` ativa `AndroidPlayIntegrityProvider`/`AppleAppAttestWithDeviceCheckFallbackProvider`.
- `production` sem `APP_CHECK_WEB_RECAPTCHA_SITE_KEY` configurado não ativa nenhum provider Web.
- Nunca lança quando `setTokenAutoRefreshEnabled` falha (defensivo).
- Nunca lança quando `activate` falha (defensivo).

## Comandos executados

```bash
dart run build_runner build
flutter test test/core/security/configure_app_check_test.dart
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 383 files (0 changed) in 1.72 seconds.`

## Resultado do analyzer

`No issues found! (ran in 10.8s)`

## Resultado dos testes

`flutter test`: `All tests passed!` (639 testes — os 632 já existentes na TASK-031 + os 7 novos desta
task, sem regressão).

## Decisões técnicas

- **Ativação via DI lazy (não em `bootstrap.dart`).** Todo outro SDK Firebase do projeto
  (Firestore/Storage/Functions/Crashlytics/Analytics/Performance/RemoteConfig) já segue esse padrão
  — configurar só quando algo de fato resolve a dependência via `getIt`, nunca eager no bootstrap —
  precisamente para que testes de widget que nunca tocam um SDK específico (como
  `test/app/bootstrap_test.dart`) não precisem mockar o canal de plataforma daquele plugin. Seguir o
  mesmo padrão para App Check manteve essa propriedade: `bootstrap_test.dart` continua passando sem
  qualquer mock de `firebase_app_check`.
- **`FirebaseAppCheck` como parâmetro não usado de `firebaseFirestore`/`firebaseStorage`/
  `firebaseFunctions`**, em vez de ativar o App Check só via seu próprio provider isolado. Sem essa
  dependência declarada, nada garantiria que a ativação do App Check aconteceu antes da primeira
  chamada real a Firestore/Storage/Functions (a ordem de registro no `injectable.init()` não implica
  ordem de resolução lazy). Declarando `FirebaseAppCheck appCheck` como parâmetro dos três providers,
  o código gerado (`injection.config.dart`) sempre chama `gh<FirebaseAppCheck>()` antes de invocar o
  corpo de `firebaseFirestore`/`firebaseStorage`/`firebaseFunctions` — confirmado no diff do
  `build_runner` (ver `git diff lib/app/injection.config.dart` no histórico desta sessão).
- **`development` e `staging` tratados de forma idêntica (ambos Debug provider em toda
  plataforma)**, em vez de diferenciar "monitoramento" vs. "enforcement brando" como a redação
  original da task sugeria. Isso reflete a realidade de infraestrutura já fixada pela ADR-0002: só
  existe um projeto Firebase real (`vestipro`, tratado como produção); `development`/`staging`
  falam exclusivamente com o Emulator Suite, que não tem nenhum conceito de enforcement de App
  Check. Diferenciar os dois ambientes no código não teria efeito observável nenhum hoje — a
  diferenciação real de "enforcement progressivo" só existe no nível de produto (Firestore/Storage/
  Functions) dentro do único projeto real, e é uma configuração de Console, não de cliente.
- **Web em `production` sem site key configurado não ativa nenhum provider Web**, em vez de usar um
  valor placeholder óbvio (ex.: `'CHANGE_ME'`). Ativar com uma chave inválida faria toda chamada Web
  falhar de forma dura assim que o enforcement for ligado para qualquer produto no Console — pior do
  que simplesmente não ter token de App Check enquanto Security Rules/RBAC continuam autorizando
  normalmente.
- **`AppleAppAttestWithDeviceCheckFallbackProvider` (não `AppleAppAttestProvider` puro)** — pedido
  explícito da task ("App Attest com fallback DeviceCheck quando aplicável a versões de SO
  suportadas"), e evita quebrar builds em iOS/macOS anteriores a iOS 14/macOS 14 (App Attest não
  disponível nessas versões).
- **Debug token/site key só via `--dart-define` (`APP_CHECK_DEBUG_TOKEN`,
  `APP_CHECK_WEB_RECAPTCHA_SITE_KEY`), nunca hardcoded** — mesmo padrão já usado no projeto para
  qualquer valor sensível/configurável por build; documentado extensivamente no doc comment de
  `configure_app_check.dart` para não ser confundido com segredo real (site keys reCAPTCHA são
  públicos por design; o debug token de App Check é sensível o suficiente para nunca ser comitado,
  mas segue o mesmo mecanismo de `--dart-define` para consistência).

## Riscos conhecidos

- **App Check ainda não foi registrado no Firebase Console para o projeto `vestipro`.** Sem esse
  passo manual (Project settings → App Check → registrar os 3 apps com Play Integrity/App
  Attest/reCAPTCHA), a ativação em `production` chama `activate()` com os providers corretos, mas o
  backend real ainda não reconhece nenhum enforcement — hoje isso é inofensivo (nenhum produto está
  em modo Enforce), mas precisa acontecer antes de qualquer rollout de enforcement real.
- **Nenhum enforcement (Monitor/Enforce) foi configurado no Console** — está fora do alcance desta
  sessão (requer acesso ao Firebase Console, não à CLI/repositório). O rollout recomendado
  (Monitor → Enforce, por produto) está documentado no doc comment de `configureAppCheck` e deve ser
  seguido manualmente quando o time de infraestrutura tiver acesso ao Console.
- **`APP_CHECK_WEB_RECAPTCHA_SITE_KEY` ainda não existe** (depende do registro acima) — a Web em
  `production` roda hoje sem App Check até esse valor ser provisionado e passado via
  `--dart-define` no pipeline de build Web.
- **Testado apenas via unit test (fake) e leitura de código das três plataformas** — a task pedia
  teste manual/documentado de inicialização em Android/iOS/Web reais; como este ambiente de execução
  é uma máquina Windows sem emulador Android/simulador iOS/navegador anexado a este fluxo, não foi
  possível rodar o app de fato em nenhuma das três plataformas para observar o log do debug token.
  Ver "Pendências".
- **`AndroidDebugProvider`/`AppleDebugProvider`/`WebDebugProvider` cobrem `development`/`staging`
  incondicionalmente** — se algum dia `staging` ganhar um projeto Firebase real próprio (revisão da
  ADR-0002), esta função precisa ser revisitada para diferenciar `staging` de `development` (hoje
  tratados de forma idêntica porque ambos só falam com o Emulator Suite).

## Pendências

- Registrar App Check no Firebase Console para o projeto `vestipro` (Play Integrity, App Attest,
  reCAPTCHA v3) — passo manual de infraestrutura, fora do alcance desta sessão (sem acesso ao
  Console).
- Depois do registro acima, provisionar `APP_CHECK_WEB_RECAPTCHA_SITE_KEY` no pipeline de build Web e
  confirmar a ativação do reCAPTCHA v3 real.
- Configurar o enforcement progressivo (Monitor → Enforce) por produto no Console, seguindo o rollout
  documentado em `lib/core/security/configure_app_check.dart`.
- Executar o teste manual real em dispositivo/simulador Android, iOS e navegador Web (pedido
  explícito da task) quando houver acesso a essas plataformas — hoje só a lógica de ativação foi
  validada via teste unitário com fake.
- TASK-033 (auditoria administrativa) continua pendente, como já esperado pela ordem do backlog.

## Evidências

- `lib/core/security/configure_app_check.dart` e `lib/core/security/security.dart`.
- `lib/app/injection_module.dart` (novo provider `firebaseAppCheck` + parâmetro de ordenação nos três
  providers existentes) e `lib/app/injection.config.dart` (regenerado).
- `test/core/security/configure_app_check_test.dart` e sua execução (`flutter test
  test/core/security/configure_app_check_test.dart` → `All tests passed!`, 7/7).
- `flutter analyze` → `No issues found!`; `flutter test` → `All tests passed!` (639 testes).
- `README.md`, seção "Firebase Emulator Suite" (novo parágrafo sobre App Check).

## Commit

Realizado.

## Push

Não autorizado nesta execução — apenas commit local, conforme instrução explícita desta rodada.

## Hash do commit

`Ver resposta final da task (preenchido após o git commit real).`

## Branch

`main`
