# TASK-019 — Concluída (2026-08-22)

## Resumo

Criada a abstração `PerformanceMonitor` sobre Firebase Performance Monitoring
(`firebase_performance`), com implementação real (`FirebasePerformanceMonitor`) e fake para
testes (`FakePerformanceMonitor`), catálogo centralizado de nomes de trace (`PerformanceTraces`)
cobrindo sincronização offline, submissão de pedido e carregamento de catálogo, toggle de coleção
por ambiente (`configurePerformance`) e registro lazy em DI, seguindo exatamente o mesmo padrão já
usado por `AnalyticsService`/`CrashReporter`/`FeatureFlagService`.

Uma tentativa de conectar `PerformanceTraces.dependencyInjectionSetupDuration` a um ponto real
(`configureDependencies` em `lib/app/bootstrap.dart`) foi implementada, executada e revertida após
reproduzir — via `flutter test` real, não suposição — que `Trace.start()` do SDK real pode ficar
pendente indefinidamente quando o canal nativo de Performance Monitoring não responde (ex.:
`flutter test` sem plugin nativo registrado), travando `test/app/bootstrap_test.dart`. Um guard de
timeout (`performanceTraceOperationTimeout`, 3s) foi adicionado a `FirebasePerformanceMonitor` como
mitigação permanente para esse risco, mas a conexão real com um fluxo de produção foi deixada como
pendência documentada (ver `docs/architecture/performance.md`, seção "Known risk"), a ser resolvida
pela primeira task que implementar sync/pedido/catálogo de fato.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/performance/performance_monitor.dart`
- `lib/core/performance/firebase_performance_monitor.dart`
- `lib/core/performance/fake_performance_monitor.dart`
- `lib/core/performance/performance_traces.dart`
- `lib/core/performance/configure_performance.dart`
- `lib/core/performance/performance.dart` (barrel)
- `lib/core/performance/README.md`
- `docs/architecture/performance.md`
- `test/core/performance/performance_traces_test.dart`
- `test/core/performance/fake_performance_monitor_test.dart`
- `test/core/performance/firebase_performance_monitor_test.dart`
- `test/core/performance/configure_performance_test.dart`
- `docs/tasks/TASK-019-configurar-firebase-performance-monitoring-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/injection_module.dart` — novo provider lazy `firebasePerformance` (mesmo padrão de
  `firebaseCrashlytics`/`firebaseAnalytics`/`firebaseRemoteConfig`), toggling coleção via
  `configurePerformance` com `unawaited`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registro de `FirebasePerformance`
  e `PerformanceMonitor`/`FirebasePerformanceMonitor` no container `GetIt`).
- `docs/tasks/TASKS.md` — checkbox da TASK-019 marcado e `Progresso` atualizado para 19/220 (apenas
  essas duas linhas; um diff pré-existente e não relacionado — documentação do comando
  `/proximas-tasks` — foi deixado intocado no working tree, fora deste commit).

`lib/app/bootstrap.dart` foi editado e depois revertido ao estado original nesta mesma sessão (git
diff vazio) — ver "Decisões técnicas"/"Riscos conhecidos".

## Arquitetura utilizada

Mesmo padrão de `AnalyticsService`/`CrashReporter`/`FeatureFlagService`: interface abstrata em
`domain`-like local (`core/performance`), implementação real anotada `@LazySingleton(as: ...)`,
implementação fake para testes, catálogo de constantes centralizado, função `configure*` de
toggle por ambiente chamada pelo provider lazy do `injection_module.dart`. Nenhuma feature acessa
`FirebasePerformance` diretamente.

## Regras de negócio implementadas

- Nomes de trace centralizados em `PerformanceTraces`, nunca string literal no call site.
- `PerformanceMonitor` nunca lança exceção — falha ao medir nunca pode ser a causa de falha do
  fluxo medido (mesma regra de `CrashReporter`/`AnalyticsService`).
- `wrapAsync` sempre finaliza a trace, mesmo quando a operação encapsulada lança, e sempre propaga
  o resultado/exceção original inalterado.
- Guard de timeout (`performanceTraceOperationTimeout`, 3s) em todo `start()`/`stop()` do SDK real,
  para nunca travar o fluxo medido.

## Regras Firebase implementadas

- `configurePerformance`: coleção desabilitada em `development`, habilitada em
  `staging`/`production` — mesma política de `configureCrashlytics`/`configureAnalytics`.
- Traces automáticas nativas do SDK dependem apenas do toggle de coleção (nenhuma configuração
  Dart adicional é necessária); documentado em `docs/architecture/performance.md` que elas cobrem
  pouco do tráfego real do VestiPro (dio/Firestore/Functions não passam pelo stack HTTP nativo
  instrumentado automaticamente), por isso toda trace relevante é manual via `PerformanceMonitor`.

## Analytics implementado

Não aplicável a esta task (infraestrutura de Performance Monitoring, não de Analytics de produto).

## Crashlytics implementado

Não aplicável a esta task.

## Impacto offline

Nenhum: infraestrutura de telemetria, sem estado local/Outbox.

## Impacto multi-tenant

Nenhuma trace registra dado pessoal/sensível; atributos futuros (ex.: `organizationId`) devem ser
truncados/anonimizados, conforme documentado na abstração e em `performance.md`.

## Testes criados

- `test/core/performance/performance_traces_test.dart` — catálogo sem duplicidade e coerente com a
  documentação.
- `test/core/performance/fake_performance_monitor_test.dart` — `FakePerformanceMonitor` registra
  start/stop/atributos e propaga resultado/exceção de `wrapAsync`.
- `test/core/performance/firebase_performance_monitor_test.dart` — `FirebasePerformanceMonitor`
  (mockando `FirebasePerformance`/`Trace` via `mocktail`): `wrapAsync` inicia/finaliza a trace,
  finaliza mesmo quando a ação lança, aplica atributos, nunca lança quando o SDK falha (start,
  stop, ou ambos); `startTrace`/`stopTrace` manuais; `stopTrace` é no-op sem trace correspondente.
- `test/core/performance/configure_performance_test.dart` — toggle por ambiente e nunca lança
  quando o SDK falha.

## Comandos executados

```bash
flutter pub run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test test/core/performance
flutter test test/app/bootstrap_test.dart test/app/injection_test.dart
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` → `Formatted 167 files (0 changed)` (sem alterações
pendentes após os ajustes automáticos aplicados durante o desenvolvimento).

## Resultado do analyzer

`flutter analyze` → `No issues found!`

## Resultado dos testes

- `flutter test test/core/performance` → 18 testes, todos passaram.
- `flutter test test/app/bootstrap_test.dart test/app/injection_test.dart` → todos passaram (usado
  para confirmar que o revert da instrumentação eager em `bootstrap.dart` eliminou o hang
  reproduzido anteriormente).
- `flutter test` (suíte completa) → 206 testes, `All tests passed!`.

## Decisões técnicas

- `configurePerformance` é `async` e totalmente guardado (`try`/`catch` interno), diferente do
  padrão fire-and-forget sem `catch` de `configureCrashlytics`/`configureAnalytics` — decisão
  necessária para permitir chamá-lo de forma segura tanto do provider lazy (`unawaited`) quanto de
  um eventual call site que precise aguardá-lo antes de iniciar uma trace (mesmo padrão de
  `configureRemoteConfig`).
- `FirebasePerformanceMonitor.wrapAsync` cria uma instância local de `Trace` por chamada (não usa o
  mapa interno de traces nomeadas), para que chamadas concorrentes com o mesmo nome de trace nunca
  colidam.
- `performanceTraceOperationTimeout` (3s) foi adicionado depois de reproduzir empiricamente que
  `Trace.start()`/`Trace.stop()` reais podem nunca resolver quando o canal nativo não responde —
  risco não coberto pelo simples `try`/`catch` (um hang não é uma exceção).
- A tentativa de conectar `dependency_injection_setup_duration` a `bootstrap.dart` foi revertida
  (ver "Riscos conhecidos") em vez de mantida com o guard de timeout, porque isso ainda adicionaria
  latência real (até 3s) a todo `bootstrap()`/todo teste que o exercita, e o valor de medir a
  configuração de DI (tipicamente sub-milissegundo) não justifica esse custo/risco residual quando
  comparado a aguardar um fluxo real (sync/pedido/catálogo) para a primeira conexão de verdade.

## Riscos conhecidos

- Nenhuma das quatro traces do catálogo está conectada a um fluxo real hoje — são strings
  centralizadas e testadas, mas nenhuma aparece de fato no console Firebase ainda. Isso é esperado
  para `sync_incremental_duration`/`order_submit_duration`/`catalog_load_duration` (os fluxos que
  elas medem não existem ainda), mas é uma pendência real para
  `dependency_injection_setup_duration`, criada especificamente para validar o mecanismo
  ponta a ponta e que não foi conectada por segurança (ver "Decisões técnicas").
- Verificação manual no console Firebase de que uma trace real aparece (item de "Testes
  obrigatórios" da task) **não foi realizada** — requer executar o app em um dispositivo/emulador
  real ou modo profile, o que este ambiente não permite. Isso está documentado como pendência
  explícita, não omitido.
- `firebase_performance: ^0.11.4+6` demonstrou, neste ambiente, que uma chamada real ao canal
  nativo sem handler registrado pode nunca resolver (em vez de rejeitar rapidamente como a maioria
  dos outros plugins Firebase usados no projeto) — importante para qualquer task futura que vá
  chamar `PerformanceMonitor` fora de um contexto de DI lazy/sob demanda.

## Pendências

- Conectar `PerformanceTraces.syncIncrementalDuration` ao motor de sync (EPIC-14), quando implementado.
- Conectar `PerformanceTraces.orderSubmitDuration` à submissão de pedido (TASK-101), quando implementada.
- Conectar `PerformanceTraces.catalogLoadDuration` ao carregamento de catálogo (EPIC-10), quando implementado.
- Conectar (ou remover, se não fizer mais sentido) `PerformanceTraces.dependencyInjectionSetupDuration`
  a um ponto real, e validar manualmente no console Firebase pelo menos uma trace — tarefa de
  fast-follow, idealmente feita junto com a primeira das três acima, quando já houver acesso a
  execução real do app (dispositivo/emulador/profile mode).

## Evidências

Saídas de `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` (206 testes,
`All tests passed!`) obtidas nesta sessão — ver "Comandos executados"/"Resultado dos testes".

## Commit

Único commit, contendo apenas os arquivos desta task (implementação, testes, documentação e as duas
linhas de `docs/tasks/TASKS.md` referentes à TASK-019). O diff pré-existente e não relacionado em
`AGENTS.md`/`docs/tasks/TASKS.md` (documentação do comando `/proximas-tasks`) e o arquivo
`.claude/commands/proximas-tasks.md` foram deixados intocados no working tree.

## Push

Não realizado nesta rodada (sem autorização de push).

## Hash do commit

Ver resposta final da tarefa.

## Branch

`main`
