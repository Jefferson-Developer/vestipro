# TASK-079 — Concluída (2026-08-26)

## Resumo

A entidade, persistência local (Drift), sincronização best-effort com Firestore, use cases,
BLoC/Cubit, telas e regras de segurança de Favoritos já haviam sido implementados e testados no
commit `ac6ff43` (rodada anterior). Nesta execução, o código existente foi auditado antes de
qualquer nova implementação (conforme protocolo `/proxima-task`), a suíte de testes completa foi
executada de fato, e foram encontrados e corrigidos dois defeitos reais que a suíte previamente
não havia pego em conjunto (os testes de favoritos não tinham sido rodados isoladamente após o
commit anterior):

1. `AppDatabase.listPendingFavoriteSync` só selecionava linhas com `syncStatus == 'pending'`. Uma
   sincronização que falhava (marcada `failed` por `_markFailedIfStillPending`) nunca mais era
   tentada de novo — quebrando o critério de aceite "favorito criado offline sincroniza ao
   reconectar" sempre que a primeira tentativa de sync falhasse antes da reconexão.
2. `FavoritesBloc._loadPage` emitia um `FavoritesState` extra só para gravar `hasLoggedViewed`
   depois do estado de sucesso, gerando uma emissão a mais do que o contrato esperado pelos
   consumidores/testes do bloc.

Ambos foram corrigidos, a suíte de favoritos passou a rodar 100% verde, e a suíte completa do
projeto (1678 testes) passa sem falhas.

## Agentes utilizados

- `flutter-senior-architect` (checklist de arquitetura/offline/sync/testes, lido nesta rodada para
  validar as correções antes de aplicá-las).

## Arquivos criados

- `docs/tasks/TASK-079-implementar-favoritos-CONCLUIDA.md`

## Arquivos alterados

- `lib/core/database/app_database.dart` — `listPendingFavoriteSync` agora inclui `syncStatus in
  ('pending', 'failed')`, permitindo que uma sincronização que falhou seja re-tentada na próxima
  vez que o escopo é observado (`watchFavoriteProductIds`).
- `lib/features/favorites/presentation/bloc/favorites_bloc.dart` — `_loadPage` passou a decidir
  `hasLoggedViewed` e disparar o analytics `favorites_viewed` antes de emitir, incluindo o campo no
  mesmo `emit` do estado de sucesso/vazio, em vez de um `emit` adicional só para essa flag; método
  `_logViewedIfNeeded` (agora morto) removido.
- `test/core/design_system/components/catalog/app_product_grid_test.dart`,
  `test/features/favorites/data/repositories/drift_favorite_repository_test.dart`,
  `test/features/favorites/presentation/bloc/favorites_bloc_test.dart`,
  `test/features/favorites/presentation/cubit/favorite_status_cubit_test.dart` — reformatados por
  `dart format` (sem mudança de lógica; apenas whitespace/quebra de linha).

Nenhum arquivo fora do escopo de favoritos foi commitado: `dart format .` também tocou
`lib/core/navigation/active_organization_guard.dart`,
`lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart` e
`lib/features/settings/presentation/widgets/about_app_content.dart` (drift de formatação
pré-existente, não relacionado a favoritos) — essas mudanças foram revertidas com
`git checkout --` antes do commit para não sair do escopo da task.

## Arquitetura utilizada

Feature-first + Clean Architecture, já estabelecida em `ac6ff43`:
`lib/features/favorites/{domain,data,presentation}`, seguindo o mesmo padrão de entidade
sincronizável (`FavoriteProduct` com `organizationId`, `companyId`, `userId`, `createdAt`,
`syncStatus`) e repositório local-first (`DriftFavoriteRepository`) com push best-effort para
Firestore via `FavoriteRemoteDataSource`, no mesmo espírito do Outbox (`pending -> synced|failed`,
sem `Outbox` genérico ainda — EPIC-14).

## Regras de negócio implementadas

- Favoritar/desfavoritar é otimista e local-first; nunca bloqueia na UI.
- Idempotência por chave primária (`organizationId`, `userId`, `productId`) via
  `insertOnConflictUpdate` — repetir o toque nunca duplica.
- Produto favoritado que não existe mais é descartado do grid e contado em `unavailableCount`, sem
  card quebrado.
- Escopo estrito por `organizationId` + `userId` em toda leitura/escrita local e nas Firestore
  Rules.
- Sincronização retomada oportunisticamente sempre que o escopo é observado — agora cobrindo tanto
  `pending` (nunca tentado) quanto `failed` (tentado e com erro), o que fecha a lacuna corrigida
  nesta rodada.

## Regras Firebase implementadas

Já existentes em `ac6ff43`, não alteradas nesta rodada: `firestore.rules`
(`organizations/{organizationId}/favorites/{favoriteId}`, `favoriteId = {userId}_{productId}`,
leitura/escrita restrita ao próprio `userId`) e `firestore-tests/firestore.rules.test.js` cobrindo
isolamento entre usuários da mesma organização e entre organizações diferentes.

## Analytics implementado

Já existente em `ac6ff43`: `product_favorited`, `product_unfavorited`, `favorites_viewed`
(`lib/core/analytics/analytics_events.dart`). Nesta rodada, `favorites_viewed` passou a ser
disparado antes do `emit` (mesma condição `!hasLoggedViewed && produtos não vazios`), sem alterar
quando/quantas vezes o evento é logado — apenas removendo a emissão de estado supérflua.

## Crashlytics implementado

Nenhuma mudança. Falha de sincronização em background continua sem reporte ao Crashlytics, por
design (mesmo precedente de outros repositórios local-first do projeto: é esperado até existir um
Outbox genérico).

## Impacto offline

Corrigido nesta rodada: uma falha de sincronização remota agora é recuperável de fato — a
próxima vez que a tela/observador do escopo (`watchFavoriteProductIds`) é iniciado, a linha
`failed` volta a ser tentada, não apenas as `pending`. O dado local nunca é perdido em nenhum dos
dois cenários (adicionar ou remover offline).

## Impacto multi-tenant

Nenhuma regressão. Testes de repositório e de Firestore Rules seguem cobrindo isolamento entre
organizações e entre usuários da mesma organização; nenhuma query nova foi introduzida sem os
filtros `organizationId`/`userId` já existentes.

## Testes criados

Nenhum teste novo criado nesta rodada (a suíte de `ac6ff43` já cobria todos os cenários exigidos
pela task). Os 4 arquivos de teste de favoritos/grid foram apenas reformatados; o comportamento
coberto continua o mesmo, agora passando de fato:

- `test/features/favorites/data/repositories/drift_favorite_repository_test.dart` (11 casos:
  favoritar, idempotência, desfavoritar/no-op, paginação, offline, retry após reconexão, falha não
  perde dado, isolamento multi-tenant, isolamento entre usuários).
- `test/features/favorites/presentation/bloc/favorites_bloc_test.dart` (4 casos: hidratação,
  produto indisponível, lista vazia, sem usuário logado).
- `test/features/favorites/presentation/cubit/favorite_status_cubit_test.dart` (5 casos).
- `test/features/favorites/presentation/pages/favorites_page_test.dart` (3 casos de widget).
- `test/core/design_system/components/catalog/app_product_grid_test.dart`.

## Comandos executados

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/features/favorites/
```

## Resultado do formatter

Na primeira execução, `dart format` reformatou 7 arquivos: 4 pertencentes a favoritos/grid
(mantidos) e 3 fora do escopo da task (revertidos com `git checkout --`, pois eram drift de
formatação pré-existente e não relacionado a esta task). Após aplicar as correções de código desta
rodada, `favorites_bloc.dart` também precisou de reformatação (aplicada). Execução final: `Formatted
1275 files (4 changed)` — apenas os 4 arquivos de favoritos permaneceram alterados no working tree.

## Resultado do analyzer

`flutter analyze` → `No issues found! (ran in 12.5s)`.

## Resultado dos testes

Antes das correções: `flutter test` → `+1675 -3` (3 falhas, todas em favoritos: 1 na sincronização
de reconexão do repositório, 2 no `FavoritesBloc` por excesso de emissões de estado).

Após as correções: `flutter test test/features/favorites/` → `+23, All tests passed!`.
`flutter test` (suíte completa) → `+1678, All tests passed!`.

## Decisões técnicas

- Corrigir os dois defeitos em vez de apenas ajustar os testes para o comportamento observado: em
  ambos os casos o comportamento observado violava um critério de aceite explícito da task (sync
  recuperável após falha; contrato de estados do bloc), então a correção ficou no código de
  produção.
- `listPendingFavoriteSync` passou a incluir `failed` e manteve fora `syncing`, já que esse valor do
  enum `FavoriteSyncStatus` nunca é de fato persistido por este repositório (não há concorrência de
  sync neste mecanismo simplificado, que roda sob demanda a cada observação do escopo).
- O evento de analytics `favorites_viewed` passou a ser dependência (`await`) antes do único `emit`,
  preservando "loga uma vez por sessão de tela" sem precisar de um estado transitório extra.

## Riscos conhecidos

- O mecanismo de sync deste feature é "drena pendências a cada `watchFavoriteProductIds`", não um
  Outbox genérico com backoff/retry incremental (registrado como aceitável até EPIC-14, conforme
  comentário já existente no código). Uma sessão que nunca reabre a tela de favoritos/catálogo após
  ficar offline não tem um gatilho automático de reconexão — mesma limitação documentada
  originalmente, não introduzida nem agravada por esta correção.
- Testes de Firestore Rules (`firestore-tests/firestore.rules.test.js`) não foram executados nesta
  rodada (exigem Firebase Emulator); nenhuma regra foi alterada, então o risco é baixo, mas fica
  registrado como não verificado nesta sessão.

## Pendências

- Nenhuma pendência de implementação/teste em aberto para o escopo funcional da task.
- Não verificado nesta rodada: `firebase emulators:exec "flutter test integration_test"` (regras
  Firestore de favoritos não foram alteradas, e já tinham cobertura de teste dedicada no commit
  anterior).

## Evidências

- `flutter test test/features/favorites/` → `+23, All tests passed!`.
- `flutter test` (suíte completa) → `+1678, All tests passed!`.
- `flutter analyze` → `No issues found!`.

## Commit

Local, sem push (não autorizado nesta rodada).

## Push

Não realizado — sem autorização explícita nesta conversa.

## Hash do commit

Ver `git log -1` após o commit desta rodada (registrado na resposta final da task).

## Branch

`main`
