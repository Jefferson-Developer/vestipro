# TASK-017 — Concluída (2026-08-22)

## Resumo

Criada a abstração central `AnalyticsService` e a taxonomia inicial de eventos/propriedades de
usuário do Firebase Analytics para o VestiPro (`lib/core/analytics/`), seguindo o mesmo padrão
defensivo já estabelecido para `CrashReporter` (TASK-016): interface testável, implementação real
(`FirebaseAnalyticsService`) que nunca lança exceção, e um fake in-memory (`FakeAnalyticsService`)
para uso em testes de BLoCs/use cases futuros. Nenhum evento foi disparado por nenhuma feature
nesta task — apenas a infraestrutura, conforme a própria TASK-017 exige, já que login/organização/
cliente/produto/pedido ainda não existem como fluxos reais.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/core/analytics/analytics_service.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/core/analytics/analytics_user_properties.dart`
- `lib/core/analytics/firebase_analytics_service.dart`
- `lib/core/analytics/fake_analytics_service.dart`
- `lib/core/analytics/configure_analytics.dart`
- `lib/core/analytics/analytics.dart` (barrel export)
- `docs/architecture/analytics.md`
- `test/core/analytics/analytics_events_test.dart`
- `test/core/analytics/fake_analytics_service_test.dart`
- `test/core/analytics/firebase_analytics_service_test.dart`
- `test/core/analytics/configure_analytics_test.dart`
- `docs/tasks/TASK-017-configurar-firebase-analytics-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/injection_module.dart` (registra `FirebaseAnalytics` como `@lazySingleton`, chamando
  `configureAnalytics` na primeira resolução, mesmo padrão de `firebaseCrashlytics`)
- `lib/app/injection.config.dart` (regenerado via `build_runner`; passa a resolver
  `FirebaseAnalytics` e `AnalyticsService` -> `FirebaseAnalyticsService`)
- `docs/architecture/README.md` (link para o novo `analytics.md`, ao lado dos demais documentos de
  arquitetura)
- `docs/tasks/TASKS.md` (checkbox da TASK-017 marcado e progresso atualizado para 17/220)

## Arquitetura utilizada

Infraestrutura pura em `lib/core/analytics/` (sem camada de feature/BLoC): interface
`AnalyticsService` (abstração testável/mockável), implementação real
`FirebaseAnalyticsService` (`@LazySingleton(as: AnalyticsService)`), catálogos de constantes
`AnalyticsEvents`/`AnalyticsUserProperties` (evitam strings mágicas espalhadas pelo código), fake
`FakeAnalyticsService` para testes, e função de configuração `configureAnalytics` (mesmo padrão de
`configureCrashlytics`/`configureFirestore`/`configureStorage`/`configureFunctions`). Nenhuma regra
de negócio de feature foi tocada; nenhuma UI acessa o SDK do Firebase Analytics diretamente.

## Regras de negócio implementadas

- Nomes de evento e de propriedade de usuário centralizados em `AnalyticsEvents`/
  `AnalyticsUserProperties` — nenhuma string mágica é permitida em código de feature futuro.
- `AnalyticsService.logEvent`/`setUserProperty` documentam explicitamente que nunca devem receber
  dados pessoais sensíveis (nome completo, e-mail, telefone, CPF/CNPJ) — apenas identificadores
  técnicos e métricas de negócio.
- Nenhum evento foi efetivamente disparado por nenhuma feature (não existe ainda login/organização/
  cliente/produto real); a task entrega apenas infraestrutura, conforme restrição explícita da
  própria TASK-017.

## Regras Firebase implementadas

- `configureAnalytics` desabilita a coleta do Analytics inteiramente para o ambiente
  `development` (nenhum evento de execução local de desenvolvedor chega ao console real).
- Para `staging` e `production` a coleta permanece habilitada (valida o pipeline de eventos antes
  do release, mesma lógica já usada para Crashlytics/TASK-016), mas `staging` marca todo evento com
  a propriedade de usuário `is_test_account = 'true'` — decisão necessária porque, pela ADR-0002
  (TASK-010), existe um único projeto Firebase real para todos os flavors (sem projeto separado
  nem emulador de Analytics para isolar tráfego de teste). `production` limpa explicitamente essa
  propriedade (`null`).
- Registrado em `lib/app/injection_module.dart` com o mesmo padrão "lazy-DI-triggered wiring" já
  usado para Firestore/Storage/Functions/Crashlytics: a configuração só ocorre quando algo resolve
  `FirebaseAnalytics` pela primeira vez, nunca eagerly no bootstrap.

## Analytics implementado

Infraestrutura completa (`AnalyticsService`, `AnalyticsEvents`, `AnalyticsUserProperties`,
`FirebaseAnalyticsService`, `FakeAnalyticsService`, `configureAnalytics`) e taxonomia mínima da
seção 14 de `tasks.md`: `login_completed`, `organization_created`, `customer_created`,
`product_viewed`, `catalog_filtered`, `order_created`, `order_submitted`, `order_sync_failed`,
`crm_activity_created`, `insight_opened`, `insight_action_clicked`, `report_exported`,
`offline_pack_downloaded`, `product_added_to_order`. Nenhum ponto de disparo real ainda existe
(depende de features futuras).

## Crashlytics implementado

Nenhuma alteração — fora do escopo desta task (já implementado na TASK-016).

## Impacto offline

Nenhum. `AnalyticsService`/`FirebaseAnalyticsService` não persistem nem sincronizam dados locais;
o próprio SDK `firebase_analytics` já enfileira eventos internamente quando offline (comportamento
padrão do SDK, fora do controle desta abstração).

## Impacto multi-tenant

Nenhuma regra de isolamento de tenant foi alterada. `AnalyticsService.setUserProperty` já expõe o
ponto de extensão para associar `organization_id`/`role` aos eventos (via
`AnalyticsUserProperties`), a ser efetivamente chamado por uma feature de autenticação/RBAC futura
— nenhuma chamada real foi adicionada nesta task, pois essas features ainda não existem.

## Testes criados

- `test/core/analytics/analytics_events_test.dart`: a taxonomia de `AnalyticsEvents.values`
  corresponde exatamente à lista documentada, sem duplicidade.
- `test/core/analytics/fake_analytics_service_test.dart`: `FakeAnalyticsService` grava
  corretamente `logEvent`/`setUserId`/`setUserProperty`, exercitado a partir de um ponto de
  disparo de exemplo simulando login/logout.
- `test/core/analytics/firebase_analytics_service_test.dart`: `FirebaseAnalyticsService` repassa
  as chamadas ao SDK, remove valores `null` do mapa de parâmetros (exigência do próprio SDK) e
  nunca lança exceção quando o SDK falha.
- `test/core/analytics/configure_analytics_test.dart`: `configureAnalytics` habilita/desabilita a
  coleta e aplica/limpa `is_test_account` corretamente por ambiente (`development`/`staging`/
  `production`).

## Comandos executados

```bash
flutter pub run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/core/analytics
```

## Resultado do formatter

`dart format --set-exit-if-changed .` reformatou os 4 arquivos recém-criados na primeira execução
(quebra de linha automática) e retornou `Formatted 146 files (4 changed)` sem erro de exit code —
os arquivos já estavam no estado formatado esperado após essa execução.

## Resultado do analyzer

`flutter analyze`: `No issues found! (ran in 5.5s)`.

## Resultado dos testes

`flutter test`: 164 testes, todos passaram (`All tests passed!`), incluindo os 13 novos testes de
`test/core/analytics/`.

## Decisões técnicas

- `AnalyticsService.logEvent` aceita `Map<String, Object?>?` (permite `null` para valor
  ausente/desconhecido), enquanto o SDK `firebase_analytics` exige `Map<String, Object>?` sem
  valores nulos; `FirebaseAnalyticsService` filtra as entradas `null` antes de repassar ao SDK, em
  vez de vazar essa restrição do SDK para todo ponto de disparo futuro.
- Filtragem de tráfego de teste via propriedade `is_test_account` (em vez de projeto Firebase
  separado) por ser a única opção compatível com a decisão já tomada na TASK-010/ADR-0002 (projeto
  único). `development` continua com a coleta totalmente desabilitada, igual à decisão já tomada
  para Crashlytics na TASK-016.
- `FakeAnalyticsService` foi implementado como uma classe reutilizável em `lib/core/analytics/`
  (não apenas inline em um arquivo de teste), pois é este próprio arquivo de task que pede
  explicitamente um fake "para uso em testes" reutilizável por BLoCs/use cases futuros — sem
  depender de `flutter_test`/`mocktail`, importável diretamente de qualquer teste de feature.
- Nenhum código de disparo de evento real foi adicionado (nenhuma chamada a
  `AnalyticsService.logEvent` fora dos próprios testes), respeitando a restrição explícita da
  TASK-017 de não simular disparo de evento sem o fluxo de origem existir.

## Riscos conhecidos

- Como não há projeto Firebase separado por ambiente (ADR-0002), a filtragem de tráfego de teste
  depende inteiramente de todo dashboard/relatório futuro (EPIC-17/EPIC-18) filtrar
  `is_test_account = 'true'` antes de calcular métricas comerciais reais — documentado em
  `docs/architecture/analytics.md`, mas é uma responsabilidade que recai sobre tasks futuras de BI.
- Não há emulador local de Firebase Analytics; portanto, o comportamento real de
  `FirebaseAnalyticsService`/`configureAnalytics` não foi validado contra o SDK real (apenas
  mockado via `mocktail`), assim como já era o caso do Crashlytics na TASK-016.

## Pendências

- Nenhuma pendência de implementação nesta task. A associação real de `organization_id`/`role` aos
  eventos (via `setUserProperty`) e o disparo real dos eventos da taxonomia dependem de features
  futuras (autenticação, RBAC, clientes, produtos, pedidos, CRM, insights, relatórios) que ainda
  não existem.

## Evidências

- `flutter test test/core/analytics`: 13 testes, todos passaram.
- `flutter test`: 164 testes, todos passaram.
- `flutter analyze`: sem problemas.
- `lib/app/injection.config.dart` (gerado) confirma o registro de `FirebaseAnalytics` (lazy
  singleton via `appInjectionModule.firebaseAnalytics`) e de `AnalyticsService` resolvendo para
  `FirebaseAnalyticsService`.

## Commit

Commit criado após a conclusão da documentação.

## Push

Não executado — sem autorização de push nesta rodada (apenas commit local autorizado).

## Hash do commit

A confirmar após `git commit` (ver resposta final da task).

## Branch

`main`
