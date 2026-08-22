# TASK-018 — Concluída (2026-08-22)

## Resumo

Criado o módulo `lib/core/feature_flags/` com `FeatureFlagService` sobre `firebase_remote_config`,
um registro central de flags (`FeatureFlagRegistry`) com metadados obrigatórios (descrição,
responsável, data de criação, data de revisão), uma implementação real (`FirebaseFeatureFlagService`)
e uma fake para testes (`FakeFeatureFlagService`). `configureRemoteConfig` aplica a política de fetch
por ambiente e os defaults locais no bootstrap. A flag de exemplo `feature_insights_enabled` foi
validada ponta a ponta: definida no registro, lida via `FeatureFlagService` e usada para exibir
condicionalmente um atalho "Insights" no módulo de referência (`AboutAppPage`).

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/feature_flags/feature_flag_definition.dart`
- `lib/core/feature_flags/feature_flag_registry.dart`
- `lib/core/feature_flags/feature_flag_service.dart`
- `lib/core/feature_flags/firebase_feature_flag_service.dart`
- `lib/core/feature_flags/fake_feature_flag_service.dart`
- `lib/core/feature_flags/configure_remote_config.dart`
- `lib/core/feature_flags/feature_flags.dart` (barrel)
- `docs/architecture/feature-flags.md`
- `test/core/feature_flags/feature_flag_registry_test.dart`
- `test/core/feature_flags/fake_feature_flag_service_test.dart`
- `test/core/feature_flags/firebase_feature_flag_service_test.dart`
- `test/core/feature_flags/configure_remote_config_test.dart`
- `docs/tasks/TASK-018-configurar-firebase-remote-config-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/injection_module.dart` — provider `@lazySingleton FirebaseRemoteConfig`, chamando
  `configureRemoteConfig` de forma fire-and-forget (`unawaited`), mesmo padrão de
  `firebaseFirestore`/`firebaseStorage`/`firebaseFunctions`/`firebaseCrashlytics`/`firebaseAnalytics`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registro de `FirebaseRemoteConfig`
  e `FeatureFlagService` no grafo de DI).
- `lib/app/bootstrap.dart` — `VestiProApp` resolve `showInsightsShortcut` através de
  `_resolveShowInsightsShortcut()` (que envolve a resolução de `FeatureFlagService` em `try/catch`,
  retornando `false` em caso de falha) e passa o valor para `AboutAppPage`.
- `lib/features/settings/presentation/pages/about_app_page.dart` — `AboutAppPage`/`AboutAppView`/
  `_AboutAppBar` recebem `showInsightsShortcut`; novo widget `_InsightsShortcutButton` (placeholder)
  exibido condicionalmente na app bar.
- `test/features/settings/presentation/pages/about_app_page_test.dart` — dois novos testes de widget
  (`showInsightsShortcut` falso/verdadeiro) e `_buildPage` passou a aceitar o parâmetro.
- `docs/architecture/README.md` — link para `feature-flags.md`.
- `docs/tasks/TASKS.md` — checkbox da TASK-018 marcado e progresso atualizado para 18/220.

## Arquitetura utilizada

Serviço de infraestrutura em `lib/core/` (não é uma feature), seguindo o mesmo padrão de
`AnalyticsService`/`CrashReporter`/`CloudFunctionsService`: abstração (`FeatureFlagService`),
implementação real via Firebase (`FirebaseFeatureFlagService`, `@LazySingleton(as: ...)`), fake para
testes (`FakeFeatureFlagService`) e uma função `configure*` chamada uma única vez pelo provider de DI
na primeira resolução do SDK. Nenhuma UI acessa `FirebaseRemoteConfig` diretamente; `AboutAppPage`
recebe `showInsightsShortcut` como parâmetro de construtor resolvido no composition root
(`VestiProApp.build`), sem tocar em `getIt`.

## Regras de negócio implementadas

- Toda flag lida via `FeatureFlagService` precisa estar registrada em `FeatureFlagRegistry` com
  `owner`, `createdAt`, `reviewBy`, `type` e `defaultValue` — ler uma chave não registrada lança
  `ArgumentError` (fail-fast), tanto na implementação real quanto na fake.
- `FirebaseFeatureFlagService` nunca confia no valor bruto do SDK antes de `setDefaults`/fetch real
  (`ValueSource.valueStatic`): nesse caso, e em qualquer exceção do SDK, retorna sempre o default
  definido em código no registro — nunca o comportamento padrão do app depende só do console remoto.
- Reservado para funcionalidade/experiência: nenhuma regra crítica (autorização, preço, numeração de
  pedido, aprovação) foi ou deve ser implementada sobre este serviço (documentado em
  `feature-flags.md` e nos comentários da interface).
- Processo de retirada de flags temporárias documentado em `docs/architecture/feature-flags.md`.

## Regras Firebase implementadas

Não há Security Rules/Cloud Functions nesta task. `configureRemoteConfig` define a política de fetch
por ambiente (`minimumFetchInterval`: `Duration.zero` em `development`, 15 min em `staging`, 1h em
`production`; `fetchTimeout` de 10s) e aplica os defaults do registro via `setDefaults` antes de
qualquer `fetchAndActivate`. Não existe Emulator local de Remote Config (mesma limitação já
documentada para Crashlytics/TASK-016) — os três ambientes leem do mesmo projeto real, por ADR-0002.

## Analytics implementado

Nenhum evento de analytics novo nesta task (fora de escopo — TASK-018 é infraestrutura de feature
flag, não evento comercial).

## Crashlytics implementado

Nenhuma mudança em Crashlytics nesta task. Falhas de leitura/configuração do Remote Config são
registradas via `developer.log` (mesmo padrão defensivo de `FirebaseAnalyticsService`), não via
Crashlytics.

## Impacto offline

Nenhum. `FirebaseFeatureFlagService` e `configureRemoteConfig` são resilientes a falta de rede (
fallback para defaults locais, timeout de 10s adicional sobre `fetchAndActivate`), mas isso é
puramente client-side e não interage com o pipeline de sincronização (Outbox/Drift) ainda
inexistente neste ponto do backlog.

## Impacto multi-tenant

Nenhum. Flags de Remote Config nesta task são globais ao app (não segmentadas por
`organizationId`/`companyId`); a task explicitamente não usa Remote Config para nenhuma decisão de
autorização ou dado sensível a tenant.

## Testes criados

- `test/core/feature_flags/feature_flag_registry_test.dart` — sem duplicidade de chaves, todo
  registro tem `owner` e `reviewBy` posterior a `createdAt`, `remoteConfigDefaults` reflete o
  registro, `definitionOf` lança para chave não registrada.
- `test/core/feature_flags/fake_feature_flag_service_test.dart` — default do registro,
  `overrideFlag`, overrides no construtor, `reset`, chave não registrada lança.
- `test/core/feature_flags/firebase_feature_flag_service_test.dart` (mocktail) — fallback para
  `ValueSource.valueStatic`, leitura real para `valueDefault`/`valueRemote`, fallback quando o SDK
  lança, chave não registrada lança.
- `test/core/feature_flags/configure_remote_config_test.dart` (mocktail) — ordem
  `setConfigSettings` → `setDefaults` → `fetchAndActivate`, `setDefaults` recebe exatamente
  `FeatureFlagRegistry.remoteConfigDefaults`, `setDefaults` completa antes do retorno,
  `minimumFetchInterval` por ambiente (dev/prod), nenhuma etapa propaga exceção.
- `test/features/settings/presentation/pages/about_app_page_test.dart` — dois testes novos:
  atalho "Insights" oculto por padrão e exibido/funcional ponta a ponta quando
  `showInsightsShortcut: true`.

## Comandos executados

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze lib/core/feature_flags lib/app/bootstrap.dart lib/app/injection_module.dart lib/features/settings/presentation/pages/about_app_page.dart
flutter test test/app/bootstrap_test.dart test/widget_test.dart test/app/injection_test.dart test/features/settings
flutter test test/core/feature_flags
flutter test test/features/settings/presentation/pages/about_app_page_test.dart
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

## Resultado do formatter

Primeira execução: `Formatted 157 files (6 changed)` (quebra de linha automática nos arquivos
recém-criados). Segunda execução (após ajustes): `Formatted 157 files (0 changed)`.

## Resultado do analyzer

`flutter analyze` → `No issues found!` (execução completa do projeto).

## Resultado dos testes

`flutter test` (suíte completa) → `188 tests passed`, nenhuma falha. Antes de chegar a esse estado,
uma primeira tentativa de resolver `FeatureFlagService` diretamente em `VestiProApp.build()` (sem o
guard de `_resolveShowInsightsShortcut`) quebrou `test/widget_test.dart` (esse teste nunca chama
`bootstrap()`/`Firebase.initializeApp`, então `Firebase.app()` lança `[core/no-app]` ao resolver
`FirebaseRemoteConfig`); corrigido com o guard defensivo — ver "Decisões técnicas".

`flutter build web --release` → `√ Built build\web` (sem erros).

## Decisões técnicas

- `FirebaseFeatureFlagService` trata `ValueSource.valueStatic` como "ainda não configurado" e cai
  para o default do registro, em vez de confiar no valor bruto do SDK — isso torna a leitura de flag
  correta mesmo enquanto o `setDefaults` (disparado sem `await` pelo provider de DI) ainda está em
  andamento, sem exigir tornar `configureDependencies`/DI assíncrono (`@preResolve`) neste momento do
  backlog (mudança maior, fora do escopo desta task).
- `configureRemoteConfig` envolve **todas** as etapas (`setConfigSettings`, `setDefaults`,
  `fetchAndActivate`) em `try/catch` — não apenas o fetch — porque é chamada com `unawaited()` pelo
  provider de DI; uma falha não tratada em qualquer etapa se tornaria uma rejeição de `Future` não
  observada, o que o `flutter_test` reporta como falha de teste mesmo sem ninguém "aguardar" o
  resultado.
- `VestiProApp.build()` resolve `FeatureFlagService` através de `_resolveShowInsightsShortcut()`,
  que envolve a resolução inteira em `try/catch` retornando `false` em caso de erro. Isso foi
  necessário porque `test/widget_test.dart` renderiza `VestiProApp` sem passar por `bootstrap()` (ou
  seja, sem `Firebase.initializeApp`), e `FirebaseRemoteConfig.instance` chama `Firebase.app()`
  internamente, que lança `[core/no-app]` nesse cenário. O mesmo raciocínio de "uma feature flag
  nunca pode impedir o resto do app de renderizar" já documentado para o próprio `FeatureFlagService`
  foi estendido para cobrir também a falha de resolução do serviço em si.
- Não existe Remote Config Emulator no `firebase_remote_config` (confirmado lendo o pacote em
  `pub cache`) — por isso não há wiring de emulator em `configureRemoteConfig`, ao contrário de
  Firestore/Storage/Functions/Auth.
- `feature_insights_enabled` foi escolhida como flag de exemplo (uma das duas sugeridas na task),
  com destino real (esconder/exibir um atalho no módulo de referência `AboutAppPage`), em vez de um
  toggle sem uso nenhum — para validar o pipeline ponta a ponta como pedido nos critérios de aceite.

## Riscos conhecidos

- A flag de exemplo (`feature_insights_enabled`) é um placeholder: o atalho "Insights" não navega
  para nenhum módulo real (mostra apenas um `SnackBar`). Deve ser removida/substituída quando o
  módulo real de Insights (EPIC-17) existir, conforme o processo de retirada documentado em
  `docs/architecture/feature-flags.md`.
- `minimumFetchInterval` de `Duration.zero` em `development` significa que todo cold start em dev
  tenta buscar do backend real (não há Emulator) — aceitável para um ambiente de desenvolvimento de
  baixo volume, mas deve ser revisto se algum dia houver testes automatizados de UI de alto volume
  contra o projeto Firebase real de dev/staging.
- Nenhuma flag foi segmentada por tenant/role ainda; se uma futura task precisar de rollout por
  organização, será necessário estender `FeatureFlagService` (ex.: parâmetros de contexto) — não
  implementado aqui por estar fora do escopo do critério de aceite desta task.

## Pendências

Nenhuma pendência bloqueante. Fica registrado para revisão futura (via `reviewBy` no registro) a
remoção da flag `feature_insights_enabled` quando o módulo real de Insights (EPIC-17) for
implementado.

## Evidências

- `flutter analyze` → `No issues found!`
- `flutter test` → `188 tests passed`
- `flutter build web --release` → `√ Built build\web`
- `dart format --set-exit-if-changed .` → `Formatted 157 files (0 changed)` (após ajustes)

## Commit

Commit local criado nesta rodada (ver hash abaixo). Push não realizado (não autorizado nesta
rodada).

## Push

Não realizado — não autorizado nesta rodada.

## Hash do commit

A confirmar após `git commit` (ver resposta final da task).

## Branch

`main`
