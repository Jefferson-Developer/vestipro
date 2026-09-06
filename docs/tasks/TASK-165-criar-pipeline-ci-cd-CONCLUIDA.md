# TASK-165 — Criar pipeline CI/CD — CONCLUÍDA

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Data de conclusão:** 2026-09-06
**Agente utilizado:** `flutter-senior-architect` (execução direta, sem sub-delegação — escopo é
infraestrutura de CI/CD, não UI nem regra de negócio de feature).

## Resumo

O repositório não tinha nenhum pipeline de CI (`.github/workflows/` não existia). As TASK-161/162/163
já tinham deixado uma base sólida para consumir: `flutter test` (2943 testes), `firestore-tests/` e
`storage-tests/` (Security Rules positivo/negativo/multi-tenant), `functions/test/` (Cloud Functions
críticas: preço, número de pedido, aprovações) e `integration_test/` (datasources Flutter), com um
orquestrador único já preparado explicitamente para isto (`package.json` na raiz,
`npm run test:integration`, TASK-162 — ver seu comentário "pensado para ser plugado diretamente num
job de CI na TASK-165").

Esta task criou o pipeline de GitHub Actions que fecha esse gap: `.github/workflows/ci.yml` com 7
jobs (quality, functions-static, dependency-audit, integration-tests, build-android, build-web,
all-checks-passed), uma composite action (`.github/actions/setup-firebase-config`) para reconstruir
os dois arquivos gitignorados de configuração Firebase que o build exige, e `.github/dependabot.yml`
para manter as dependências (`pub`, `npm` × 3 subprojetos, `github-actions`) atualizadas.

## Levantamento feito antes de codar (evitando redundância)

- Confirmado que não existe nenhum arquivo em `.github/` (`git ls-files | grep "^\.github"` vazio) —
  nada a substituir, só a criar.
- Lido `docs/architecture/static-quality.md`/`testing.md`, `scripts/check.ps1`, `README.md`
  (seções "Qualidade estática", "Android/iOS/Web", "Backend e Firebase") e `AGENTS.md` para não
  inventar comandos novos: o pipeline reutiliza exatamente os comandos já documentados/usados
  localmente (`scripts/check.ps1`, `flutter test --coverage`, os comandos de build por flavor do
  próprio `README.md`).
- Lido `docs/tasks/TASK-162-*-CONCLUIDA.md` e o `package.json`/`firestore-tests/`/`storage-tests/`
  que ele criou: já existia `npm run test:integration`, desenhado explicitamente para esta task —
  reaproveitado sem reescrever nenhuma suíte.
- Confirmado (via `git check-ignore -v` e leitura de `TASK-010-*-CONCLUIDA.md`/ADR-0002) que
  `lib/firebase_options.dart` e `android/app/google-services.json` são gitignorados de propósito —
  isso significa que **todo** job que compila/analisa/testa Dart (o app inteiro importa
  `firebase_options.dart` via `lib/app/bootstrap.dart`) precisa desses arquivos reconstruídos a
  partir de secrets no runner de CI, não apenas os jobs de build.
- Confirmado que este ambiente de execução não tem Java instalado (`java -version` →
  `command not found`), mesma limitação já documentada em TASK-162/163 — os testes que dependem do
  Firebase Emulator Suite (incluindo o novo job `integration-tests`) não puderam ser executados de
  ponta a ponta nesta sessão; reportado explicitamente abaixo, não inventado.

## Arquivos criados

- `.github/workflows/ci.yml` — pipeline principal, 7 jobs (ver "Arquitetura do pipeline" abaixo).
- `.github/actions/setup-firebase-config/action.yml` — composite action que decodifica
  `FIREBASE_OPTIONS_DART_BASE64`/`GOOGLE_SERVICES_JSON_BASE64` (secrets do repositório) para
  `lib/firebase_options.dart`/`android/app/google-services.json` no runner; falha cedo e com
  mensagem explícita se `FIREBASE_OPTIONS_DART_BASE64` não estiver configurado.
- `.github/dependabot.yml` — 5 entradas (`pub` na raiz; `npm` em `functions/`, `firestore-tests/`,
  `storage-tests/`; `github-actions` na raiz), semanal.
- `docs/backlog/BACKLOG-004-vulnerabilidade-alta-undici-testes-firebase-js.md` — novo item de
  backlog registrando uma vulnerabilidade alta real (`undici`, transitiva via `firebase`/
  `@firebase/rules-unit-testing`) encontrada ao ligar `npm audit --audit-level=high` pela primeira
  vez em `firestore-tests/`/`storage-tests/` (ver "Riscos e pendências").
- `docs/tasks/TASK-165-criar-pipeline-ci-cd-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `docs/tasks/TASKS.md` — checkbox da TASK-165 marcado `[x]`; progresso `164/220` → `165/220`.
- `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md` — marcado como resolvido pela
  automação criada aqui (job `integration-tests`), com nota honesta de que a execução real (verde)
  não pôde ser confirmada neste ambiente sem Java.
- `docs/backlog/README.md` — índice atualizado (BACKLOG-002 marcado resolvido; BACKLOG-004
  adicionado).
- `README.md` — nova seção "CI/CD" (tabela de jobs, secrets necessários, link para este documento).
- `test/features/dashboards/domain/usecases/load_collection_dashboard_entries_use_case_test.dart`,
  `test/features/dashboards/domain/usecases/load_geographic_dashboard_use_case_test.dart`,
  `test/features/insights/domain/rules/cross_sell_insight_rule_test.dart`,
  `test/features/insights/domain/rules/growing_customer_insight_rule_test.dart`,
  `test/features/insights/domain/rules/up_sell_insight_rule_test.dart` — **apenas reformatados**
  por `dart format --set-exit-if-changed .` (indentação; nenhuma linha de asserção/lógica mudou,
  confirmado por `git diff` linha a linha). Necessário porque o `main` atual já falhava o novo gate
  de formatter que esta task está introduzindo em CI — sem isso, o job `quality` nasceria vermelho
  por um motivo alheio a esta task. Escopo estritamente de formatação, zero mudança de
  comportamento/teste.

## Arquitetura do pipeline (`.github/workflows/ci.yml`)

Dispara em `pull_request` (branches `main`) e `push` (branches `main`), com `concurrency` para
cancelar execuções supersedidas. 7 jobs:

1. **`quality`** — `dart format --set-exit-if-changed .` + `flutter analyze` + marcadores TODO/FIXME
   (via `./scripts/check.ps1`, reaproveitado tal como já é rodado localmente — nenhum comando novo
   inventado), depois `flutter test --coverage` (cobre tanto "flutter test" quanto "flutter test
   --coverage" do escopo original em uma única execução — rodar os 2943 testes duas vezes seria
   redundante e mais lento sem nenhum ganho de sinal), `lcov`/`genhtml` para relatório HTML, e
   `actions/upload-artifact` publicando `coverage/lcov.info` + `coverage/html` como artefato
   (evidência de TASK-161 pedida no critério de aceite). Por fim, `flutter pub outdated --show-all`
   como step informativo (`continue-on-error: true`, não bloqueia — consistente com
   `docs/architecture/testing.md`, que já trata metas de cobertura como alvo e não gate automático;
   dependências desatualizadas por si só não são um problema de segurança, diferente de
   vulnerabilidades).
2. **`functions-static`** — `eslint`/`tsc --noEmit` de `functions/`. Separado do job de integração
   porque `functions/test/*.test.ts` mistura teste unitário mockado com teste de integração real
   contra o Emulator (mesma observação já documentada em TASK-162) — rodar `npm test` aqui sem
   Emulator quebraria os testes que dependem dele.
3. **`dependency-audit`** — `npm audit --audit-level=high` em matriz sobre os 3 subprojetos Node
   (`functions`, `firestore-tests`, `storage-tests`). `--audit-level=high` (não `moderate`) é uma
   escolha deliberada: hoje há 14 vulnerabilidades moderadas em `functions/` sem fix disponível nas
   SDKs do Google Cloud, que tornariam o gate permanentemente vermelho por ruído sem correção
   possível a curto prazo; alta/crítica continua bloqueando de verdade (ver achado real abaixo).
4. **`integration-tests`** — Java 17 (Temurin) + Firebase CLI + Node 20 + Flutter, `npm ci` nos 3
   subprojetos Node, depois `npm run test:integration` (o orquestrador da TASK-162, que por sua vez
   roda `firebase emulators:exec` 4 vezes: Rules Firestore, Rules Storage, Functions críticas,
   `integration_test` client-side via Chrome). Só roda depois de `quality`/`functions-static`
   passarem (`needs`), para não gastar tempo de Emulator numa PR já quebrada nos gates rápidos.
5. **`build-android`** — matriz `dev`/`staging`/`prod`, reproduzindo exatamente os comandos já
   documentados no `README.md` (`flutter build appbundle --debug --flavor dev|staging`,
   `--release --flavor prod`), com Java 17 (exigido pelo Gradle) e a config Firebase materializada
   (incluindo `google-services.json`, exigido mesmo para dev/staging — ver TASK-010).
6. **`build-web`** — matriz `development`/`staging`/`production`, `flutter build web -t
   lib/main_web.dart --dart-define=ENVIRONMENT=<env>`, também reaproveitando o comando exato do
   `README.md`.
7. **`all-checks-passed`** — agregador (`needs` todos os anteriores, `if: always()`) que falha se
   qualquer um deles falhar/for cancelado — pensado para ser o único *required status check*
   configurado na proteção da branch `main` (em vez de listar 6 jobs manualmente na configuração do
   GitHub, que fica frágil a cada novo job adicionado).

### `setup-firebase-config` (composite action)

`lib/firebase_options.dart` e `android/app/google-services.json` são gitignorados de propósito
(ADR-0002/TASK-010) — não existem em um checkout limpo do runner de CI. Como
`lib/app/bootstrap.dart` importa `firebase_options.dart` diretamente e é importado por todo
`main_*.dart`, **até `flutter analyze`/`flutter test` exigem esse arquivo**, não só os builds. A
action decodifica os dois arquivos de secrets base64 do repositório (`FIREBASE_OPTIONS_DART_BASE64`
sempre; `GOOGLE_SERVICES_JSON_BASE64` só onde precisa, isto é, `build-android`) e falha cedo com
mensagem explícita se o secret obrigatório não estiver configurado, em vez de deixar o erro de
import aparecer de forma confusa nos steps seguintes.

## Testes obrigatórios da task — cobertura

| Requisito | Como é coberto |
|---|---|
| PR com `dart format` pendente é bloqueada | Job `quality`, step `./scripts/check.ps1` (`dart format --set-exit-if-changed .`) |
| PR com `flutter analyze`/`flutter test` falhando é bloqueada | Job `quality` |
| `firebase emulators:exec` roda e reporta falha corretamente | Job `integration-tests` (`npm run test:integration`) |
| Os três builds por ambiente (dev/staging/prod) são executados/verificados | Jobs `build-android` e `build-web`, matriz de 3 |
| Relatório de cobertura é gerado e anexado como artefato | Job `quality`, `actions/upload-artifact` (`flutter-coverage-report`) |

## Comandos executados e resultados reais

Tudo abaixo foi **de fato executado** nesta sessão (nunca inventado); o ambiente tem Flutter/Node/
Firebase CLI mas **não tem Java**, então os passos que dependem do Emulator Suite real não puderam
ser confirmados em execução (ver "Riscos").

```
dart format --set-exit-if-changed .
→ 1ª execução: "Formatted 2317 files (5 changed)" — 5 arquivos de teste pré-existentes, não
  relacionados a esta task, precisaram de reformatação (ver "Arquivos alterados"); mudança aplicada
  e incluída no commit. Execução seguinte, já limpa, confirmada antes de encerrar a task.

flutter analyze
→ EXIT=1, 12 issues, todas "info" (6 depreciações RadioGroup/groupValue pré-existentes em
  lib/features/reports/presentation/pages/report_builder_page.dart, já documentadas na TASK-164; +6
  infos "use_null_aware_elements" em arquivos de teste de dashboards/insights). Nenhum arquivo
  tocado por esta task aparece nessa lista — dívida técnica pré-existente, fora do escopo de
  TASK-165 (não é UI/regra de negócio deste pipeline). Reportado, não corrigido.

flutter test
→ 2943 testes, 2 falhas pré-existentes, nenhuma introduzida por esta sessão (nenhum arquivo lib/
  foi tocado):
  - test/app/bootstrap_test.dart ("bootstrap initializes Firebase exactly once...") — já
    documentada em docs/tasks/TASK-164-otimizar-performance-CONCLUIDA.md ("StateError:
    PushDeviceMapper not registered").
  - test/core/analytics/analytics_events_test.dart ("exposes exactly the initial taxonomy, with no
    duplicates") — nova neste levantamento: a lista "esperada" no teste tem 70 eventos, a real
    (AnalyticsEvents) tem 73 — alguma task anterior adicionou 3 eventos novos sem atualizar este
    teste de taxonomia congelada. Não investigado/corrigido aqui (exigiria decidir, por
    feature/evento, qual dos 3 é uma adição legítima vs. duplicata real — julgamento de negócio
    fora do escopo de "criar o pipeline de CI").

flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=development
flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=staging
flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=production
→ "√ Built build\web" nas 3 execuções (usando o lib/firebase_options.dart já presente localmente
  nesta máquina de desenvolvimento — gitignorado, não commitado; mesmo arquivo que o secret
  FIREBASE_OPTIONS_DART_BASE64 precisa reconstruir em CI).

flutter build appbundle --debug --flavor dev -t lib/main_dev.dart
→ "√ Built build\app\outputs\bundle\devDebug\app-dev-debug.aab"
flutter build appbundle --debug --flavor staging -t lib/main_staging.dart
→ "√ Built build\app\outputs\bundle\stagingDebug\app-staging-debug.aab"
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
→ "√ Built build\app\outputs\bundle\prodRelease\app-prod-release.aab (83.3MB)" — usando o fallback
  de debug signing já existente em android/app/build.gradle.kts (comentário "Release signing will
  be configured in the release pipeline task" — TASK-166, não alterado aqui).

npm audit --audit-level=high  (dentro de functions/)
→ EXIT=0 (14 vulnerabilidades moderadas, nenhuma alta/crítica)

npm audit --audit-level=high  (dentro de firestore-tests/)
→ EXIT=1 (1 vulnerabilidade alta: undici <=6.27.0, via firebase/@firebase/rules-unit-testing)

npm audit --audit-level=high  (dentro de storage-tests/)
→ EXIT=1 (mesma vulnerabilidade alta)

npx -y js-yaml .github/workflows/ci.yml
npx -y js-yaml .github/actions/setup-firebase-config/action.yml
npx -y js-yaml .github/dependabot.yml
→ os 3 parseiam sem erro (validação de sintaxe YAML; não substitui rodar o workflow real no GitHub
  Actions, que este ambiente não tem acesso para fazer).
```

## Decisões técnicas

- **`npm run test:integration` (TASK-162) reaproveitado sem reescrita.** O texto original da task
  fala em `firebase emulators:exec "flutter test integration_test"` como se toda a suíte vivesse do
  lado Flutter; na prática o repositório já consolidou Rules/Functions em suítes Node/Jest
  dedicadas. Reescrever isso dentro do workflow duplicaria uma decisão já tomada e documentada.
- **`flutter test --coverage` roda uma única vez**, cobrindo tanto "flutter test" quanto "flutter
  test --coverage" do escopo original — rodar a suíte completa duas vezes não agregaria nenhum sinal
  novo, só tempo de CI.
- **`--audit-level=high`, não `moderate`, no `npm audit`.** Rodar com `moderate` tornaria o gate
  permanentemente vermelho por dívida das próprias SDKs do Google Cloud (14 itens em `functions/`,
  sem fix disponível hoje) sem nenhuma ação possível de curto prazo — isso desvalorizaria o sinal do
  gate. `high`/`critical` continuam bloqueando de verdade, e já encontraram um problema real (ver
  BACKLOG-004).
- **`setup-firebase-config` como composite action reutilizável, não um step duplicado em cada
  job.** 4 dos 6 jobs de build/teste precisam do mesmo arquivo; centralizar evita 4 cópias do mesmo
  `base64 --decode` divergindo com o tempo.
- **`google-services.json` só é materializado no job `build-android`.** É um arquivo de config
  nativo do Gradle/Android, não importado por nenhum código Dart — desnecessário para
  `quality`/`integration-tests`/`build-web`.
- **`flutter-version-file: .fvmrc`** (em vez de fixar a versão do Flutter direto no YAML): o
  repositório já mantém `.fvmrc` como fonte única da versão (`README.md`: "registrada também no
  `.fvmrc`, para reprodutibilidade entre máquinas de desenvolvimento e CI" — texto que já
  antecipava esta task). Atualizar `.fvmrc` no futuro atualiza o CI automaticamente, sem editar o
  workflow.
- **5 arquivos de teste reformatados (whitespace apenas) incluídos neste commit.** Sem isso, o
  próprio job `quality` que esta task está criando nasceria vermelho no primeiro push a `main` por
  um motivo sem relação com CI/CD — contraria o critério de aceite "Pipeline roda de ponta a ponta
  sem intervenção manual em uma PR limpa". Mudança puramente mecânica (confirmada via `git diff`),
  sem risco.
- **`analysis_options.yaml` e as 12 infos do analyzer/2 testes falhando não foram alterados.** São
  dívida técnica pré-existente de outras tasks/features (UI de relatório, taxonomia de analytics,
  registro de `PushDeviceMapper`), não deste pipeline; "consertar" qualquer um deles exigiria decisão
  de negócio ou mudança de UI fora do escopo de "criar pipeline CI/CD" e do agente atual. O gate
  reporta a realidade em vez de escondê-la (ex.: não usei `--no-fatal-infos` no analyzer nem afrouxei
  o antigo teste de taxonomia).

## Riscos e pendências conhecidas

- **Nenhum job foi executado de fato no GitHub Actions.** Este ambiente não tem acesso ao GitHub
  Actions real; a validação possível foi (a) reproduzir localmente cada comando que cada job roda
  (todos passaram ou falharam exatamente pelos motivos pré-existentes já documentados acima, nunca
  por erro de sintaxe/lógica do workflow) e (b) validar a sintaxe YAML dos 3 arquivos novos via
  `js-yaml`. Uma primeira execução real no GitHub, após o primeiro push autorizado, é necessária
  para confirmar comportamento de runner (versões de Chrome/Android SDK pré-instaladas, etc.).
- **Java + Firebase Emulator Suite: nenhum teste que dependa deles pôde rodar nesta sessão** —
  mesma limitação já documentada em TASK-162/TASK-163 (`java -version` → `command not found` neste
  sandbox). O job `integration-tests` do pipeline usa `actions/setup-java`, que resolve isso em CI
  (runners do GitHub não têm essa limitação), mas isso não pôde ser confirmado por execução real
  aqui.
- **`FIREBASE_TOKEN` pode ou não ser necessário.** `firebase emulators:exec` para um projeto real
  (`vestipro`, via `.firebaserc`) pode exigir autenticação não-interativa do Firebase CLI mesmo só
  para Rules/Auth/Firestore/Storage/Functions locais — incerto sem rodar de fato em CI (não há
  Java/Emulator disponível aqui para confirmar). O workflow já expõe `FIREBASE_TOKEN` como env var
  opcional (`secrets.FIREBASE_TOKEN`, vazio é no-op); se o job `integration-tests` falhar por erro
  de autenticação na primeira execução real, gerar o token via `firebase login:ci` e cadastrar o
  secret é o próximo passo, sem precisar alterar o workflow.
- **Dois secrets do repositório GitHub precisam ser cadastrados manualmente antes do pipeline
  funcionar de ponta a ponta:** `FIREBASE_OPTIONS_DART_BASE64` e `GOOGLE_SERVICES_JSON_BASE64` (ver
  seção "CI/CD" do `README.md`). Não foram cadastrados por mim — não tenho acesso ao GitHub deste
  repositório nesta sessão, e são valores específicos da conta/projeto Firebase real do time.
- **Configurar a branch `main` para exigir o status check `all-checks-passed`** (Settings → Branches
  → Branch protection rules → Require status checks to pass) também é uma ação manual pendente no
  GitHub, fora do alcance desta sessão (só criar os arquivos do repositório está ao meu alcance sem
  push/acesso à configuração remota do GitHub).
- **`flutter analyze` (12 infos) e 2 testes falhando (`bootstrap_test.dart`,
  `analytics_events_test.dart`) já deixam o gate `quality` vermelho hoje**, mesmo sem nenhuma
  mudança de código desta task — dívida pré-existente e não introduzida aqui, mas significa que o
  primeiro push deste pipeline para `main` provavelmente vai reportar falha real até essas 3
  questões serem corrigidas por uma task dedicada (não registrei um novo BACKLOG-XXX para essas
  duas em específico porque já estão documentadas: TASK-164 para `bootstrap_test`/depreciações
  RadioGroup; a divergência de taxonomia em `analytics_events_test.dart` fica sinalizada aqui como
  achado novo para quem pegar a próxima task de qualidade decidir se atualiza o teste ou remove os
  eventos duplicados).
- **BACKLOG-004 (nova):** `npm audit --audit-level=high` falha hoje em `firestore-tests/` e
  `storage-tests/` por uma vulnerabilidade alta real e pré-existente (`undici`, transitiva via
  `firebase`/`@firebase/rules-unit-testing`) — corrigi-la exige bump de major version revalidado
  contra o Emulator Suite (Java), não fiz esse bump às cegas nesta sessão.
- **Achado de segurança fora do escopo desta task, mas urgente:**
  `docs/backlog/BACKLOG-003-reverter-firestore-rules-modo-teste.md` (pré-existente, não criado por
  mim) documenta que as Firestore Security Rules do projeto real `vestipro` estão publicadas em
  "modo teste" (liberação total de leitura/escrita para qualquer pessoa até 22/09/2026) — não é uma
  regressão desta task nem foi tocado por ela (reverter exigiria `firebase deploy` contra produção,
  fora de qualquer escopo de CI/CD local), mas registro aqui por transparência, dado que li o
  arquivo durante o levantamento desta task e a severidade justifica destacar para quem for ler
  esta conclusão.

## Impacto multi-tenant/offline/segurança

Nenhuma regra de negócio, entidade, RBAC ou sync foi tocada — escopo estritamente de automação de
CI/CD sobre testes/builds já existentes. `integration-tests` roda inteiramente contra o Firebase
Emulator Suite local (nunca o projeto `vestipro` real); `FIREBASE_TOKEN`, se necessário, autentica
apenas a CLI para orquestrar o Emulator, não concede acesso a dados reais.
