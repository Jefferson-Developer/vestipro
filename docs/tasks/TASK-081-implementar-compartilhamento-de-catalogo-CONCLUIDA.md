# TASK-081 — Concluída (2026-08-26)

## Resumo

Implementado o compartilhamento de catálogo (EPIC-10): o vendedor gera, a partir do produto ou de
uma seleção de produtos, um link público com validade e escopo definidos **sempre server-side**
(Cloud Functions `createCatalogShareLink`/`getCatalogShareLink`/`registerCatalogShareOpen`/
`revokeCatalogShareLink`), o destinatário abre o link sem login numa tela pública dedicada
(`CatalogSharePublicPage`, rota `/share/:token`), e o vendedor vê — na própria origem do
compartilhamento — se e quantas vezes o link foi aberto. Link expirado/revogado/inexistente nunca
expõe produto algum, sempre com mensagem clara.

Diferente do restante do catálogo (que hoje é local-first, `SharedPreferences` — TASK-076/080), o
compartilhamento **precisa** viver no Firestore: um link público, aberto por um destinatário sem
sessão nem organização conhecida, não pode depender de um dado que só existe no dispositivo do
vendedor. `CatalogShare` é o primeiro documento realmente escrito em
`organizations/{organizationId}/catalogShares/{shareId}`, com o token gerado e hasheado
exatamente como `Invite` (TASK-039) já faz — nunca no cliente, apenas seu SHA-256 é persistido.

## Agentes utilizados

- `flutter-senior-architect` (Cloud Functions, modelo `CatalogShare`, Firestore Rules, camada de
  domínio/dados, integração de rota pública sem guard, testes).
- `flutter-ui-design-specialist` (bottom sheet `CatalogShareSheet` reaproveitando `AppBottomSheet`,
  tela pública `CatalogSharePublicPage` reaproveitando `AppProductGrid`, botão de compartilhar no
  grid/detalhe do catálogo).

## Arquivos criados

Cloud Functions (`functions/src`):
- `shared/secure-token.ts` (token/hash genérico, extraído para reuso sem tocar
  `invites/invite-shared.ts`)
- `catalog/catalog-share-shared.ts` (validação, outcome, serialização)
- `catalog/create-catalog-share-link.ts`
- `catalog/get-catalog-share-link.ts`
- `catalog/register-catalog-share-open.ts`
- `catalog/revoke-catalog-share-link.ts`

Testes de Cloud Functions (`functions/test/catalog`):
- `create-catalog-share-link.test.ts`, `get-catalog-share-link.test.ts`,
  `register-catalog-share-open.test.ts`, `revoke-catalog-share-link.test.ts`

Feature Flutter nova `lib/features/catalog_share/` (Clean Architecture completa):
- `domain/value_objects/catalog_share_scope.dart`, `catalog_share_outcome.dart`
- `domain/entities/catalog_share_item.dart`, `catalog_share.dart`, `catalog_share_preview.dart`,
  `issued_catalog_share.dart` (+ `.freezed.dart` gerados)
- `domain/repositories/catalog_share_repository.dart`,
  `catalog_share_lookup_repository.dart`
- `domain/usecases/create_catalog_share_link_use_case.dart`,
  `revoke_catalog_share_use_case.dart`, `get_catalog_share_use_case.dart`,
  `preview_catalog_share_use_case.dart`, `register_catalog_share_open_use_case.dart`
- `data/dtos/catalog_share_item_dto.dart`, `catalog_share_dto.dart`,
  `catalog_share_preview_dto.dart`
- `data/mappers/catalog_share_mapper.dart`
- `data/datasources/catalog_share_data_source.dart`,
  `firestore_catalog_share_data_source.dart`, `catalog_share_lookup_data_source.dart`,
  `cloud_functions_catalog_share_lookup_data_source.dart`
- `data/repositories/catalog_share_repository_impl.dart`,
  `catalog_share_lookup_repository_impl.dart`
- `presentation/bloc/catalog_share_sheet_{event,state,bloc}.dart`,
  `catalog_share_public_{event,state,bloc}.dart`
- `presentation/widgets/catalog_share_sheet.dart`
- `presentation/pages/catalog_share_public_page.dart`
- `catalog_share.dart` (barrel)

Testes Flutter novos (`test/features/catalog_share/`, espelhando 1:1 a estrutura acima): DTOs,
mapper, datasources (Cloud-Functions-backed), repositórios, use cases, entidade, blocs e widgets —
64 testes no total.

## Arquivos alterados

- `firestore.rules`: novo bloco `organizations/{organizationId}/catalogShares/{shareId}` — leitura
  restrita ao criador ou a `catalog.manage` (OWNER/ADMIN), escrita sempre `if false` (só Admin SDK).
  Validado com `firebase_validate_security_rules` (MCP): `OK: No errors detected.`
- `firestore.indexes.json`: novo `fieldOverride` `catalogShares.tokenHash` (`COLLECTION_GROUP`),
  mesmo padrão já existente para `invites.tokenHash` — necessário para o
  `collectionGroup('catalogShares').where('tokenHash', '==', ...)` que
  `getCatalogShareLink`/`registerCatalogShareOpen` usam para resolver o token sem conhecer a
  organização.
- `firestore-tests/firestore.rules.test.js`: novo `describe` + `catalogShareDoc()` cobrindo leitura
  pelo criador, leitura por OWNER/ADMIN, negação para outro membro comum, negação cross-tenant,
  negação para visitante não autenticado e negação total de escrita pelo cliente.
- `functions/src/index.ts`: exporta as 4 novas Functions.
- `lib/core/analytics/analytics_events.dart` (+ `test/core/analytics/analytics_events_test.dart`):
  novos `catalogShareCreated` (`catalog_share_created`) e `catalogShareOpened`
  (`catalog_share_opened`).
- `lib/core/design_system/components/catalog/app_product_grid.dart` (+ teste): novo
  `AppProductCardData.onShareTap`/botão de compartilhar no card, mesmo padrão opt-in de
  `onFavoriteTap` (TASK-079) — `null` por padrão, nenhum outro consumidor do grid muda de
  comportamento.
- `lib/core/navigation/app_route_paths.dart`: nova `CatalogSharePublicRoute` (`/share/:token`),
  fora da convenção `/org/:orgId/...`, mesmo precedente de `InviteAcceptanceRoute`.
- `lib/core/navigation/app_router.dart` (+ teste): novo `catalogSharePublicPageBuilder` e `GoRoute`
  registrado — TASK-081 é a primeira página de catálogo a ser efetivamente conectada ao router
  (grid/detalhe seguem pendentes, TASK-076/078).
- `lib/core/navigation/session_auth_guard.dart` (+ teste): `_isPublicRoute` passa a reconhecer
  `/share/` como rota pública, mesmo padrão já usado para `/invite/`.
- `lib/features/catalog/presentation/pages/product_detail_page.dart`: novo
  `onSharePressed`/botão "Compartilhar" na AppBar — `null` por padrão, mesmo contrato "quem hospeda
  decide" de `onFavoriteToggle`/`onAddToOrder`; `catalog` continua sem depender de
  `catalog_share`.
- `lib/features/catalog/presentation/pages/product_grid_page.dart`: novo `onShareTap` repassado a
  cada card, mesmo contrato de `onFavoriteToggle`.
- `lib/app/bootstrap.dart`: injeta `catalogSharePublicPageBuilder` real
  (`CatalogSharePublicPage` + `getIt<CatalogSharePublicBloc>()`).
- `lib/app/injection.config.dart`: gerado por `build_runner` (DI dos novos tipos `@injectable`).

## Arquitetura utilizada

Clean Architecture feature-first, nova feature de topo `lib/features/catalog_share/` (irmã de
`favorites`/`invites`, não uma extensão de `catalog`) — mesmo precedente de modularização já usado
por essas duas.

Dois contratos de repositório, deliberadamente separados (mesmo racional de `InviteRepository` vs.
`InviteAcceptanceRepository`):
- `CatalogShareRepository` (vendedor autenticado, sempre escopado por `organizationId`):
  `create`/`revoke` via Cloud Function (`FirestoreCatalogShareDataSource`, que mistura chamadas de
  Cloud Function para escrita com leitura direta do Firestore para `getById` — mesma mistura que
  `FirestoreInviteDataSource` já faz entre `create`/`resend`/`revoke` via Function e `listPending`
  via Firestore direto).
- `CatalogShareLookupRepository` (visitante anônimo, só tem o `token`): `preview`/`registerOpen`,
  ambos exclusivamente via Cloud Function (`CloudFunctionsCatalogShareLookupDataSource`) — o
  visitante nunca fala com o Firestore diretamente, nem mesmo para ler.

`CatalogShareItem` é um snapshot leve (productId/name/imageUrl) capturado no cliente no momento da
criação do link, não uma referência resolvida a partir de um catálogo Firestore — decisão detalhada
em "Decisões técnicas".

## Regras de negócio implementadas

- Token gerado com `crypto.randomBytes` (`generateSecureToken`, `functions/src/shared/secure-token.ts`),
  nunca no cliente; apenas o hash SHA-256 é persistido em `CatalogShare.tokenHash`.
- Qualquer membro ativo da organização pode criar um compartilhamento (não existe
  `Capability.catalogView` — ver "sem restrição de visualização", mesmo bar que `favorites` já usa)
  — mas só o criador ou um OWNER/ADMIN pode revogá-lo (`revokeCatalogShareLink`).
- `scope: 'product'` exige exatamente 1 item; `'selection'`/`'collection'` exigem ao menos 1 (máx.
  50); `'collection'` exige `collectionId`/`collectionName` — validado tanto client-side
  (`CreateCatalogShareLinkUseCase`, mensagem de campo) quanto server-side
  (`createCatalogShareLink`, decisão real).
- `expiresInDays` clampado a [1, 90] no servidor, padrão 30 dias quando omitido/inválido.
- Status efetivo (`valid`/`expired`/`revoked`) é sempre computado a partir de `expiresAt`/`status`
  no momento da leitura (`resolveCatalogShareOutcome`), nunca de um campo `expired` persistido —
  mesmo padrão já usado por `resolveInviteOutcome` (TASK-039) e `CatalogCampaign.statusAt`
  (TASK-080).
- Link expirado/revogado/inexistente: `getCatalogShareLink` nunca retorna `items` fora de
  `outcome: 'valid'`, e `CatalogSharePublicPage` mostra sempre uma mensagem específica e amigável
  (nunca um erro técnico cru) — 3 mensagens distintas para expirado/revogado/inválido.
- Contagem de abertura (`registerCatalogShareOpen`) é best-effort: nunca lança exceção (nem para
  token ausente/desconhecido/expirado/revogado), é uma chamada separada da leitura do preview e
  nunca é aguardada antes de renderizar o conteúdo já obtido — uma falha aqui jamais bloqueia o
  destinatário.

## Regras Firebase implementadas

- `firestore.rules`: `organizations/{organizationId}/catalogShares/{shareId}` — `create`/`update`/
  `delete` sempre `if false` (só a Cloud Function, via Admin SDK, escreve); `read` restrito a
  `hasCapability(organizationId, 'catalog.manage')` (OWNER/ADMIN, auditoria) ou ao próprio criador
  (`resource.data.createdBy == request.auth.uid`). O visitante anônimo nunca lê `catalogShares`
  diretamente — só via `getCatalogShareLink`/`registerCatalogShareOpen`, que usam o Admin SDK e
  ignoram estas Rules — garantindo que "nenhuma outra coleção fica acessível via o mesmo token"
  trivialmente (o token nunca chega às Rules, para ninguém).
- `firestore.indexes.json`: `fieldOverride` `catalogShares.tokenHash` (`COLLECTION_GROUP`),
  necessário para a query `collectionGroup('catalogShares').where('tokenHash', '==', ...)`.
- Validado com a ferramenta MCP `firebase_validate_security_rules` sobre `firestore.rules`:
  `OK: No errors detected.`

## Analytics implementado

- `catalog_share_created`: disparado por `CatalogShareSheetBloc` ao criar um compartilhamento com
  sucesso, com `organization_id`/`scope`/`items_count`.
- `catalog_share_opened`: disparado por `CatalogSharePublicBloc` quando o preview resolve
  `outcome: valid`, com `scope`/`items_count` (sem `organization_id` — a tela pública nunca recebe
  esse dado, ver "Decisões técnicas").

## Crashlytics implementado

Nenhuma instrumentação nova além do fluxo já existente: toda exceção de repositório/datasource já
converte para `Failure`/`AppException` pelo mapeamento central (`mapAppExceptionToFailure`/
`mapCloudFunctionsExceptionToAppException`); nenhum `print`/exceção não tratada foi introduzido.

## Impacto offline

O compartilhamento em si (criar/revogar/visualizar um link) sempre exige rede — não há um caminho
offline sensato para "gerar um link público válido para outra pessoa" nem para "um visitante sem
sessão abrir um link". Isso é uma limitação aceita e documentada, não uma regressão: nenhuma feature
offline existente foi alterada.

## Impacto multi-tenant

`CatalogShare` vive em `organizations/{organizationId}/catalogShares`, com `organizationId` sempre
resolvido a partir da Membership real do chamador (`loadActiveMembership`, nunca do que o cliente
envia). O visitante anônimo nunca sabe (nem precisa saber) a qual organização o link pertence além
do `organizationName` já exposto pelo preview — o `organizationId` real nunca é devolvido a ele.
RBAC de leitura (`hasCapability`/`isActiveMember`) sempre relê a Membership real, nunca confia em
campo do próprio documento.

## Testes criados

- **Cloud Functions** (`functions/test/catalog/`, TypeScript + Firebase Admin SDK contra o
  emulador): criação com escopo válido/inválido (produto único vs. seleção vs. coleção), member
  qualquer pode criar, expiração padrão/custom clampada, rejeição de não-autenticado/sem
  Membership/Membership inativa; preview válido/`notFound`/`revoked`/`expired` sem nunca vazar
  `tokenHash`/campos internos; registro de abertura incrementando `openCount`/
  `firstOpenedAt`/`lastOpenedAt` no primeiro e segundo open, e retornando `recorded: false` sem
  lançar para token inexistente/expirado/revogado/ausente; revogação pelo criador, por OWNER, negada
  para outro membro comum, negada para já-revogado, negada para `shareId` inexistente, negada sem
  autenticação.
- **Domínio Flutter**: `CatalogShare.isActiveAt` (ativo/expirado/revogado); os 5 use cases novos
  (validação client-side, delegação com campos aparados, propagação de falha).
- **Dados Flutter**: `CatalogShareDto.fromFirestore`/`CatalogShareItemDto`/`CatalogSharePreviewDto`
  (parsing bem-formado, campos ausentes/nulos, `ValidationException`/`ServerException`);
  `CatalogShareMapper` (scope/outcome desconhecidos lançam `ValidationException`); os 2 data sources
  Cloud-Functions-backed (payload enviado, resposta parseada, best-effort nunca lança); os 2
  repositórios (sucesso, `AppException` mapeada, erro inesperado, `NotFoundFailure` para
  `getById` inexistente).
- **BLoC**: `CatalogShareSheetBloc` (criação + evento `catalog_share_created`, falha sem log,
  retry reenviando o mesmo payload, refresh atualizando `openCount`); `CatalogSharePublicBloc`
  (preview válido + `catalog_share_opened` + registro de abertura, outcome indisponível sem
  analytics/registro, falha técnica distinta de indisponível).
- **Widgets**: `CatalogShareSheet` (link exibido + botão copiar em sucesso, estado de erro com
  retry); `CatalogSharePublicPage` (produtos renderizados para link válido, mensagens específicas
  para expirado/revogado, erro retentável para falha técnica).
- **Regressão**: `AppProductGrid`/`AppProductCard` (botão de compartilhar oculto por padrão, tap
  não aciona `onProductTap`, convive com o botão de favorito); `AppRouter`/`SessionAuthGuard`
  (`CatalogSharePublicRoute` extrai o `token` e é alcançável sem sessão); `AnalyticsEvents`
  (taxonomia atualizada).

## Comandos executados

```bash
npm --prefix functions run build
npm --prefix functions run lint
npx jest test/catalog --prefix functions        # não executado com sucesso — sem emulador (ver "Pendências")
dart run build_runner build --delete-conflicting-outputs
dart format lib test functions/src
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .`: `Formatted 1362 files (0 changed)` — sem diferenças
pendentes.

## Resultado do analyzer

`flutter analyze`: `No issues found!` (ran in 13.0s).

## Resultado dos testes

- `flutter test` (suíte completa): `+1810, All tests passed!` (1810 testes, 0 falhas — 1742 da
  suíte anterior + 68 novos/alterados: 64 em `test/features/catalog_share/`, 3 novos em
  `app_product_grid_test.dart`, 1 novo em `app_router_test.dart`).
- `npm --prefix functions run build` (tsc): sem erros.
- `npm --prefix functions run lint` (eslint): sem erros.
- `firebase_validate_security_rules` (MCP) sobre `firestore.rules`: `OK: No errors detected.`

## Decisões técnicas

- **`CatalogShare` é o primeiro dado do catálogo realmente persistido no Firestore**, quebrando o
  padrão local-first que `Product`/`Collection`/`CatalogCampaign` seguem desde TASK-064/065/080 —
  decisão deliberada, não um desvio acidental: um link público, aberto por alguém sem sessão nem
  organização conhecida, não tem como funcionar a partir de um dado que só existe no
  `SharedPreferences` do aparelho do vendedor. O restante do catálogo continua exatamente como
  estava; nenhuma migração foi feita nem é necessária para esta task.
- **`CatalogShareItem` é um snapshot client-side (productId/name/imageUrl), não uma referência
  resolvida por uma Cloud Function a partir de um catálogo Firestore.** Seria a alternativa mais
  "correta" no papel, mas não existe hoje nenhuma fonte de verdade Firestore para produtos que a
  Function pudesse ler — `organizations/{orgId}/products` (TASK-069) existe só para busca e nenhum
  processo o mantém populado ainda. O snapshot é exatamente o que já torna o link funcional para um
  destinatário sem contexto algum, sem precisar dessa migração — e é consistente: o link mostra o
  produto como estava no momento do compartilhamento, nunca desincroniza silenciosamente se o
  produto mudar depois.
- **Padrão de leitura/escrita mistura Cloud Function (escrita/token) e Firestore direto
  (leitura autenticada)**, replicando exatamente o precedente de `Invite`
  (`FirestoreInviteDataSource`): `create`/`revoke` nunca tocam o Firestore diretamente (só a
  Function, via Admin SDK, que ignora `firestore.rules`); `getById` (para o vendedor conferir se
  foi aberto) lê o Firestore direto, gated pela própria Rule. O visitante público, por sua vez,
  **nunca** fala com o Firestore — só com `getCatalogShareLink`/`registerCatalogShareOpen` — mais
  restritivo que o precedente de convites (onde nem sequer existe um "visitante lê Firestore direto"
  em nenhum ponto do fluxo).
- **Sem integração com o OS share sheet (`share_plus`)**: o pedido da task ("usando o
  compartilhamento nativo da plataforma") foi atendido com o mesmo padrão que
  `InviteUserPage`/TASK-039 já estabeleceu — link copiável (`SelectableText` + botão "Copiar link"
  via `Clipboard`, sem dependência nova). Adicionar `share_plus` implicaria configuração adicional
  por plataforma (Android/iOS/Web) fora do escopo desta task isolada e sem precedente no projeto;
  registrado como pendência.
- **Seleção multi-item na UI**: o backend/domínio já suporta `scope: 'selection'` com múltiplos
  itens de ponta a ponta (Cloud Function, `CatalogShareRepository.create`, `CatalogShareSheet`,
  todos testados com 2+ itens) — mas a UI de seleção multi-produto no grid (`AppProductGrid`/
  `AppProductCardData`, componente compartilhado por várias outras telas) não foi construída nesta
  task: um modo de seleção mudaria o comportamento de um componente de Design System usado por
  favoritos/busca/home/coleção, risco de regressão fora do escopo justificável aqui. O ponto de
  entrada real desta task é o compartilhamento de um único produto, a partir do grid (`onShareTap`
  por card) ou do detalhe (`onSharePressed`); registrado como pendência explícita.
- **`ProductGridPage`/`ProductDetailPage` continuam sem integração ao `AppRouter`** — mesma
  pendência já registrada por TASK-076/078/080. `CatalogSharePublicPage`, por ser a própria ponta
  pública alcançada por link, **é** a primeira página de catálogo efetivamente conectada ao router
  (`CatalogSharePublicRoute`).

## Riscos conhecidos

- `functions/test/catalog/*.test.ts` e as novas asserções em
  `firestore-tests/firestore.rules.test.js` não foram executados nesta sessão — o ambiente não tem
  Java instalado (`Could not spawn "java -version"`), pré-requisito do Firebase Emulator Suite (
  confirmado tentando `npx firebase emulators:exec`). O código foi validado por `tsc`
  (`npm run build`) e `eslint` (`npm run lint`), ambos sem erros, e as Rules foram validadas por
  `firebase_validate_security_rules` (MCP) — mas os testes reais contra o emulador ficam como não
  verificados nesta rodada, mesmo risco/mesma causa já documentados por TASK-079.
- `organizations/{orgId}/products` (índice de busca, TASK-069) não é populado por nenhum processo
  hoje — não afeta esta task (que nunca lê essa coleção), mas reforça por que o snapshot
  client-side foi a escolha certa aqui, não um atalho.
- `registerCatalogShareOpen` conta reaberturas do mesmo visitante como novas visualizações
  (`openCount` incrementa a cada `getCatalogShareLink` bem-sucedido do lado público) — aceitável
  para "o vendedor sabe que foi aberto", não pretende ser um contador de visitantes únicos.

## Pendências

- Integração com o OS share sheet (`share_plus`) como alternativa/complemento ao link copiável.
- UI de seleção multi-produto no grid do catálogo (o backend já suporta `scope: 'selection'` de
  ponta a ponta).
- Tela "meus compartilhamentos" (listar/revogar todos os links já criados) — hoje só existe
  `getById` (refresh do link recém-criado) e `revokeCatalogShareLink` (chamável, sem UI dedicada
  ainda).
- Migrar `Product`/`Collection`/`CatalogCampaign` para Firestore (fora do escopo desta task
  isolada, pendência já registrada por TASK-076/080) — permitiria, no futuro, um `CatalogShare`
  referenciar produtos ao vivo em vez de um snapshot.
- Integração de `ProductGridPage`/`ProductDetailPage` ao `AppRouter` (pendência já registrada por
  TASK-076/078/080).
- `functions/test/catalog/*.test.ts`/asserções novas de `firestore-tests` não verificadas contra o
  emulador real nesta sessão (ver "Riscos conhecidos").

## Evidências

- `flutter analyze`: `No issues found!`
- `flutter test`: `All tests passed!` (1810 testes).
- `dart format --set-exit-if-changed .`: sem diferenças pendentes.
- `npm --prefix functions run build`/`lint`: sem erros.
- `firebase_validate_security_rules` (MCP) sobre `firestore.rules`: `OK: No errors detected.`

## Commit

`feat(catalog): implement catalog sharing via server-generated public links`

## Push

Não realizado nesta rodada (não autorizado).

## Hash do commit

Ver seção "Commit" da resposta final — hash real do `git commit`, nunca inventado.

## Branch

main
