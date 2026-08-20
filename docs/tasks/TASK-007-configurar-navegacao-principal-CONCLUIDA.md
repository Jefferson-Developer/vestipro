# TASK-007 — Concluída (2026-08-20)

## Resumo

Estabelecido `go_router` como único mecanismo de navegação do VestiPro. Criado
`lib/core/navigation/` com rotas tipadas, guards de autenticação e organização ativa (stubs
plugáveis para TASK-041 e TASK-026/TASK-037), rotas de fallback 404/403, e integração do módulo de
exemplo (`AboutAppPage`) como primeira rota real sob a convenção `/org/:orgId/...`.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura de rotas, guards, DI da navegação).

## Arquivos criados

- `lib/core/navigation/app_route_paths.dart`
- `lib/core/navigation/auth_guard.dart`
- `lib/core/navigation/active_organization_guard.dart`
- `lib/core/navigation/app_router.dart`
- `lib/core/navigation/navigation.dart`
- `lib/core/navigation/widgets/not_found_page.dart`
- `lib/core/navigation/widgets/forbidden_page.dart`
- `docs/architecture/navigation.md`
- `test/core/navigation/app_router_test.dart`
- `docs/tasks/TASK-007-configurar-navegacao-principal-CONCLUIDA.md`

## Arquivos alterados

- `pubspec.yaml` (adicionada dependência SDK `flutter_web_plugins`, necessária para
  `usePathUrlStrategy()`).
- `lib/app/bootstrap.dart` (`MaterialApp` → `MaterialApp.router`, `AppRouter` wired ao módulo de
  exemplo, `usePathUrlStrategy()` chamado no bootstrap; `VestiProApp` aceita `router` opcional para
  testes).
- `android/app/src/main/AndroidManifest.xml` (esqueleto comentado de intent-filter para deep link
  universal, documentado como pendência).
- `ios/Runner/Info.plist` (esqueleto comentado de associated domains para deep link universal,
  documentado como pendência).
- `docs/architecture/README.md` (link para `navigation.md`).
- `docs/tasks/TASKS.md` (checkbox da TASK-007 marcado, progresso atualizado).

## Arquitetura utilizada

- `lib/core/navigation/` não importa nada de `lib/features/*`: `AppRouter` recebe o builder da
  página do módulo de exemplo via parâmetro construído pela raiz de composição
  (`lib/app/bootstrap.dart`), preservando a regra de que `core` não depende de `features`.
- Rotas tipadas (`AboutAppRoute`, `ForbiddenRoute`, `NotFoundRoute`) expõem `pathPattern` (para
  `GoRoute.path`) e `location` (path resolvido); nenhuma string de rota está espalhada em widgets.
- Guards (`AuthGuard`, `ActiveOrganizationGuard`) são interfaces com stub "sempre libera"
  (`AlwaysAllowAuthGuard`, `AlwaysAllowActiveOrganizationGuard`), compostos no `redirect` central do
  `GoRouter` — nenhuma feature reimplementa proteção de rota localmente.

## Regras de negócio implementadas

- Convenção `/org/:orgId/...` para toda rota autenticada, documentada em
  `docs/architecture/navigation.md` para uso por todas as features futuras.
- IDs (não objetos) como parâmetro de rota (`:orgId`), preservando deep link e reload no Web.
- Capacidade de preservar filtros via query parameters prevista e documentada (a ser usada por
  features de listagem futuras).

## Regras Firebase implementadas

Não aplicável a esta task (guards ainda são stubs sem dependência de Firebase Auth/Firestore).

## Analytics implementado

Não aplicável a esta task (sem eventos de navegação definidos ainda; guards reais de TASK-041 e
TASK-026/TASK-037 são o ponto de extensão futuro).

## Crashlytics implementado

Não aplicável a esta task.

## Impacto offline

Nenhum: navegação client-side não depende de rede; guards stub não fazem I/O.

## Impacto multi-tenant

Convenção `/org/:orgId/...` embute o escopo de tenant na própria URL desde já, preparando o
isolamento multi-tenant que TASK-026/TASK-037 tornarão real via `ActiveOrganizationGuard`.

## Testes criados

- `test/core/navigation/app_router_test.dart`:
  - Rota 404 exibida para caminho inexistente (`errorBuilder`).
  - Rota "sem permissão" exibida quando um guard nega acesso.
  - Parâmetro de path `:orgId` resolvido corretamente e propagado ao builder da página.
  - Navegação liberada por padrão com os guards stub (comportamento "sempre libera").
- `test/widget_test.dart` (existente) continua validando que `VestiProApp` renderiza o módulo de
  exemplo através do novo `MaterialApp.router`.

Verificação manual documentada (preservação de deep link após reload no Flutter Web): não é
possível reproduzir um reload real de navegador dentro de `flutter test`; a capacidade está
documentada em `docs/architecture/navigation.md` (`usePathUrlStrategy()` + IDs como parâmetro de
rota) e depende de validação manual em `flutter run -d chrome` ou `flutter build web` publicado,
que não foi executada nesta sessão.

## Comandos executados

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

Primeira execução reformatou 5 arquivos novos (import/trailing style); segunda execução:
`Formatted 66 files (0 changed) in 0.38 seconds.`

## Resultado do analyzer

`No issues found! (ran in 3.5s)`

## Resultado dos testes

`flutter test`: 28 testes, todos passando (`All tests passed!`), incluindo os 4 novos testes de
`app_router_test.dart`.

## Decisões técnicas

- `AppRouter` recebe `aboutAppPageBuilder` por injeção (não importa `settings` nem `getIt`
  diretamente), mantendo `core/navigation` livre de dependência de features — a ligação real
  acontece em `lib/app/bootstrap.dart`.
- `NotFoundRoute` foi mantida como tipo de referência mas não registrada como `GoRoute` própria:
  qualquer caminho não declarado (incluindo `/not-found`) já cai no `errorBuilder`, evitando duas
  formas concorrentes de chegar à mesma página.
- `VestiProApp` aceita `router` opcional para permitir testes injetarem guards/builders fake sem
  passar por `configureDependencies`.

## Riscos conhecidos

- Guards são stubs "sempre libera": nenhuma proteção real existe até TASK-041 (auth) e
  TASK-026/TASK-037 (organização). Isso é esperado e documentado como ponto de extensão.
- Deep link nativo (Android/iOS) permanece desativado até existir domínio de produção definido.

## Pendências

- Ativar intent-filters/associated domains reais quando o domínio de produção do VestiPro for
  definido (esqueleto comentado deixado em `AndroidManifest.xml` e `Info.plist`).
- Conectar `AuthGuard` real na TASK-041 e `ActiveOrganizationGuard` real na TASK-026/TASK-037.
- Validação manual de reload no Flutter Web publicado (não executada nesta sessão).

## Evidências

Saídas de `dart format`, `flutter analyze` e `flutter test` reproduzidas nas seções acima.

## Commit

Criado nesta task (arquivos da task adicionados explicitamente, sem `git add -A`).

## Push

Não realizado — sem autorização explícita nesta conversa.

## Hash do commit

`429b319387d78be205cad12dd5d167bba18eb52e`

## Branch

`main`
