# TASK-082 — Concluída (2026-08-26)

## Resumo

Implementados os modos de visualização e o conjunto de filtros avançados do catálogo (EPIC-10):
`CatalogFilter` (coleção, estação, marca, categoria, cor, tamanho, disponibilidade, lançamento,
tags, material/tecido) e `CatalogViewMode` (grid, lista, lookbook, por coleção, por campanha,
favoritos, novidades, mais vendidos, recomendados, pronta entrega) no domínio, um novo
`CatalogFilterBloc` que traduz o filtro ativo numa consulta paginada por cursor via
`ListCatalogProductsUseCase` (estendido com `filter`), persistência local do último modo/filtro por
(organização, usuário), painel de filtros reaproveitando `AppAdminPageLayout` (bottom sheet no
mobile/tablet, painel lateral permanente no desktop), chips de filtro ativo individualmente
removíveis, e uma nova rota Flutter Web (`CatalogBrowseRoute`) que reflete modo/filtro na URL.

Dos 10 modos de visualização listados na especificação, 5 são de fato buscados por
`CatalogFilterBloc` (grid, lista, por coleção, novidades, pronta entrega — todos variações reais da
mesma consulta paginada); `favorites`/`lookbook` são atalhos de navegação para as telas já
existentes e testadas (`FavoritesPage`/TASK-079, `LookbookPage`/TASK-080) em vez de duplicá-las;
`bestSellers`/`recommended` não têm nenhuma fonte de dados real no VestiPro hoje (não existe
agregação de vendas nem motor de recomendação) e por isso expõem um status explícito
`unavailable` em vez de um ranking inventado no cliente — exatamente o que a própria regra de
negócio da task exige ("nunca inferidos apenas no cliente"); `byCampaign` fica modelado no enum
para completude, mas sem um caminho de busca escopado por campanha implementado nesta task (ver
"Decisões técnicas" e "Pendências"). Faixa de preço foi deliberadamente deixada fora do domínio: não
existe nenhuma tabela de preço no VestiPro ainda (EPIC-11, TASK-083 em diante, pendente no
backlog), então não há dado real para filtrar.

## Agentes utilizados

- `flutter-senior-architect` (domínio `CatalogFilter`/`CatalogViewMode`, extensão de
  `ProductRepository.listCatalog`, `CatalogFilterBloc`, persistência local, rota Flutter Web,
  testes).
- `flutter-ui-design-specialist` (painel de filtros reaproveitando `AppDropdown`/`AppTextField`/
  `AppCheckbox`, chips reaproveitando `AppFilterChip`, layout de lista `AppProductListRow` no
  Design System, seletor de modo de visualização).

## Arquivos criados

Domínio (`lib/features/products/domain/`, já que `CatalogFilter` filtra campos de `Product` e é
consumido diretamente por `ProductRepository` — mantém a direção de dependência existente,
`catalog` depende de `products`, nunca o contrário):
- `entities/catalog_filter.dart`
- `value_objects/catalog_filter_key.dart`

Domínio (`lib/features/catalog/domain/`):
- `value_objects/catalog_view_mode.dart`
- `entities/catalog_preferences.dart`
- `repositories/catalog_preferences_repository.dart`
- `usecases/load_catalog_preferences_use_case.dart`
- `usecases/save_catalog_preferences_use_case.dart`

Dados (`lib/features/catalog/data/`):
- `repositories/shared_preferences_catalog_preferences_repository.dart`

Apresentação (`lib/features/catalog/presentation/`):
- `bloc/catalog_filter_bloc.dart`, `catalog_filter_event.dart`, `catalog_filter_state.dart`
- `pages/catalog_filter_page.dart`
- `widgets/catalog_filter_panel.dart`, `catalog_active_filter_chips.dart`,
  `catalog_view_mode_selector.dart`

Testes novos (espelhando a estrutura acima):
- `test/features/products/domain/entities/catalog_filter_test.dart`
- `test/features/catalog/data/repositories/shared_preferences_catalog_preferences_repository_test.dart`
- `test/features/catalog/domain/usecases/load_catalog_preferences_use_case_test.dart`
- `test/features/catalog/domain/usecases/save_catalog_preferences_use_case_test.dart`
- `test/features/catalog/presentation/bloc/catalog_filter_bloc_test.dart`
- `test/features/catalog/presentation/pages/catalog_filter_page_test.dart`

## Arquivos alterados

- `lib/features/products/domain/repositories/product_repository.dart` (+
  `data/repositories/shared_preferences_product_repository.dart`): `listCatalog` ganha um parâmetro
  opcional `filter` (`CatalogFilter?`), aplicado **antes** da paginação (para `hasMore`/`cursor`
  continuarem corretos sobre o conjunto já filtrado) e com ordenação por `launchDate` quando
  `launchOnly` está ativo (mesma ordem de `listRecentlyLaunched`).
- `lib/features/catalog/domain/usecases/list_catalog_products_use_case.dart`: repassa `filter`.
- `lib/features/products/products.dart` / `lib/features/catalog/catalog.dart`: novos exports.
- `lib/core/design_system/components/catalog/app_product_grid.dart` (+ teste): novo
  `AppProductGridLayout` (`grid`/`list`) e os widgets `AppProductListRow`/
  `AppProductListRowSkeleton` — layout `grid` continua sendo o padrão, nenhum outro consumidor
  muda de comportamento.
- `lib/core/navigation/app_route_paths.dart`: nova `CatalogBrowseRoute`
  (`/org/:orgId/catalog/browse`), com `queryParameters` refletindo `mode` +
  `CatalogFilter.toQueryParameters()` (mesmo padrão de `CustomerPortfolioRoute`).
- `lib/core/navigation/app_router.dart` (+ teste): novo `catalogBrowsePageBuilder` opcional e
  `GoRoute` registrado.
- `lib/app/bootstrap.dart`: injeta `CatalogFilterPage` real na nova rota, convertendo
  `queryParameters` em `CatalogViewMode`/`CatalogFilter` (deep link vence sobre preferência
  local) e atualizando a URL via `context.go` a cada mudança de modo/filtro.
- `lib/app/injection.config.dart`: gerado por `build_runner` (DI dos novos tipos `@injectable`/
  `@LazySingleton`).
- 21 arquivos de teste que já implementavam `ProductRepository` (fakes locais em
  `test/features/{catalog,favorites,products}/...`) ganharam o parâmetro `CatalogFilter? filter`
  no `listCatalog` sobrescrito — alteração mecânica exigida pelo Dart para uma interface estendida
  com um novo parâmetro nomeado, sem nenhuma mudança de comportamento nesses testes.

## Arquitetura utilizada

Clean Architecture feature-first, mesma direção de dependência já estabelecida
(`catalog` → `products`, nunca o contrário): `CatalogFilter`/`CatalogFilterKey` vivem em
`features/products/domain` porque filtram campos de `Product` e são consumidos diretamente por
`ProductRepository.listCatalog`; `CatalogViewMode`/`CatalogPreferences`/`CatalogFilterBloc` vivem em
`features/catalog`, que já depende de `products` extensivamente (mesmo padrão de
`ListCatalogProductsUseCase`).

`CatalogFilter.matches(Product)` é um método puro na própria entidade (sem repositório/serviço
externo) cobrindo as dimensões resolvíveis só a partir de `Product` (coleção, estação, marca,
categoria, cor, tags, material, lançamento); `disponibilidade`/`tamanho` exigem dados de outros
repositórios (`VariantAvailabilityRepository`/`SizeGridTemplateRepository`) e por isso são aplicados
por `CatalogFilterBloc` **depois** de buscar a página (mesmo padrão que `ProductGridBloc` já usa
para buscar disponibilidade separadamente) — ver "Decisões técnicas" para o trade-off de paginação
que isso implica.

## Regras de negócio implementadas

- Filtro aplicado no repositório **antes** da paginação — `hasMore`/`cursor` sempre corretos sobre
  o conjunto já filtrado (testado em `shared_preferences_product_repository_test.dart`).
- Combinação sem nenhum resultado sempre mostra o estado vazio explícito do `AppProductGrid`
  (`emptyTitle`/`emptyDescription`), nunca uma grade em branco sem contexto.
- Preferência de modo/filtro persistida por `(organizationId, userId)` — nunca vaza entre
  organizações nem entre usuários do mesmo dispositivo (testado explicitamente).
- Um link/URL com modo/filtro explícito sempre vence sobre a preferência local salva
  (`CatalogFilterStarted.initialViewMode`/`initialFilter`) — um link compartilhado sempre mostra o
  que prometeu.
- Trocar de modo de visualização mantém o filtro ativo (testado).
- "Mais vendidos"/"recomendados" nunca são inferidos no cliente — status explícito `unavailable`
  em vez de um ranking fabricado, já que não existe agregação de vendas nem motor de recomendação
  no VestiPro hoje.
- "Pronta entrega" (filtro e modo de visualização) usa exclusivamente o dado real de
  `VariantAvailabilityRepository`, nunca um sinal inventado.
- Faixa de preço não é modelada (nem no domínio, nem na UI) — não existe tabela de preço no
  VestiPro ainda; um controle que não faz nada seria pior do que a ausência do controle.

## Regras Firebase implementadas

Nenhuma — toda a feature é local-first (`SharedPreferences`), seguindo o mesmo padrão que
`Product`/`Collection`/`CatalogCampaign` já usam desde TASK-064/065/080 (nenhuma dessas coleções
está de fato em produção no Firestore ainda).

## Analytics implementado

- `catalog_filtered` (já existia na taxonomia, declarado ainda sem uso — esta task é a primeira
  consumidora real): disparado por `CatalogFilterBloc` a cada `CatalogFilterApplied`/
  `CatalogFilterChipRemoved`, com `organization_id`, `view_mode`, `active_filter_count` e
  `active_filter_keys` (nomes de dimensão, nunca valores livres como marca/material — sem dados
  pessoais).
- `product_viewed`: mesma convenção de `ProductGridBloc`/`FavoritesBloc`, com
  `source: 'catalog_filter_<viewMode.code>'`.

## Crashlytics implementado

Nenhuma instrumentação nova além do fluxo já existente: toda falha de repositório/use case já
converte para `Failure`/`AppException` pelo mapeamento central; nenhum `print`/exceção não tratada
foi introduzido.

## Impacto offline

Filtro/modo de visualização e a consulta paginada em si continuam 100% locais
(`SharedPreferencesProductRepository`), como o resto do catálogo — funcionam sem rede. A
persistência de preferência (`SharedPreferencesCatalogPreferencesRepository`) também é local.

## Impacto multi-tenant

`CatalogPreferences` é persistida com chave `catalog_preferences_{organizationId}_{userId}` —
nunca vaza entre organizações nem entre usuários do mesmo dispositivo (3 testes dedicados: nenhuma
preferência salva, preferência round-trip completo, isolamento por organização, isolamento por
usuário). O filtro em si (`CatalogFilter`) nunca referencia dado de outra organização — toda
consulta passa `organizationId` explicitamente, resolvido pelo host (nunca inventado pela página).

## Testes criados

- **`CatalogFilter`** (domínio): `isEmpty`/`activeCount`, `normalized` (trim/remoção de vazios),
  `copyWith`, `removing` (remoção de chip único, inclusive de um valor específico dentro de um
  conjunto), round-trip completo de `toQueryParameters`/`fromQueryParameters`, `matches` para cada
  dimensão (coleção, categoria com sub, marca case-insensitive, cor por interseção, tags por
  interseção, material por substring, lançamento), e confirmação de que `matches` nunca inspeciona
  disponibilidade/tamanho, igualdade/hash ignorando ordem de conjunto.
- **`SharedPreferencesProductRepository.listCatalog` com filtro**: uma única dimensão, combinação
  de múltiplas dimensões (AND entre dimensões, OR dentro de um conjunto), combinação sem
  correspondência (página vazia, nunca quebrada), ordenação por lançamento.
- **`SharedPreferencesCatalogPreferencesRepository`**: nada salvo ainda, round-trip completo,
  isolamento por organização, isolamento por usuário.
- **`LoadCatalogPreferencesUseCase`/`SaveCatalogPreferencesUseCase`**: trim de ids, propagação de
  falha, encaminhamento correto dos dados.
- **`CatalogFilterBloc`**: sem preferência persistida (padrão grid/vazio), restaura a última
  preferência persistida, link/URL explícito vence sobre a preferência persistida, aplica um único
  filtro, combina múltiplos filtros, remove um chip sem afetar os demais, combinação sem resultado
  mostra estado vazio, troca de modo mantém o filtro ativo, `bestSellers`/`recommended` mostram
  `unavailable`, `readyStock` estreita a página pela disponibilidade real, paginação "carregar
  mais" sem perder itens já exibidos, `product_viewed` com a origem correta.
- **`CatalogFilterPage`**: renderiza a primeira página, botão de filtro abre bottom sheet no
  mobile, painel lateral permanente no desktop, chip de filtro ativo removível, notifica o host a
  cada mudança de modo/filtro (contrato de URL), navegação por teclado (Tab) entre campos do
  painel de filtros.
- **`AppProductGrid`**: novo `AppProductGridLayout.list` — renderiza `AppProductListRow` em vez de
  `AppProductCard`, skeletons de lista durante carregamento, `onProductTap` preservado.
- **`AppRouter`**: `CatalogBrowseRoute` repassa `queryParameters` para a página injetada; fallback
  para "não encontrado" quando nenhum builder está registrado.
- **Regressão**: os 21 fakes de `ProductRepository` espalhados pela suíte foram atualizados
  mecanicamente para o novo parâmetro `filter` (sem mudança de comportamento).

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .`: sem diferenças pendentes nos arquivos desta task. (O
comando também reformatou 3 arquivos fora do escopo — `active_organization_guard.dart`,
`onboarding_wizard_page.dart`, `about_app_content.dart` — por uma divergência de versão do
formatter já pré-existente no ambiente, não causada por esta task; revertidos com
`git checkout --` para não deixar drift fora do escopo, conforme AGENTS.md.)

## Resultado do analyzer

`flutter analyze`: `No issues found!` (ran in ~15s).

## Resultado dos testes

`flutter test` (suíte completa): `+1867, All tests passed!` (1867 testes, 0 falhas — 1810 da
suíte anterior + 57 novos/alterados nesta task).

## Decisões técnicas

- **`CatalogFilter`/`CatalogFilterKey` vivem em `features/products/domain`, não em
  `features/catalog/domain`.** `ProductRepository.listCatalog` (que vive em `products`) precisa
  referenciar o tipo do filtro; colocá-lo em `catalog` criaria uma dependência invertida
  (`products` → `catalog`), quebrando a direção que todo o resto do catálogo já segue. `matches`
  também vive como método da própria entidade em vez de um serviço separado — mais simples, e é
  reaproveitado tanto pelo repositório local quanto, potencialmente, por qualquer futura fonte de
  dados remota sem precisar duplicar a lógica de correspondência.
- **`bestSellers`/`recommended` mostram `unavailable`, não uma tela vazia comum.** A regra de
  negócio da própria task exige que esses modos nunca sejam inferidos no cliente; como não existe
  nenhum dado de vendas/recomendação no VestiPro (sem feature de Pedidos ainda), a alternativa
  honesta é um status explícito, não uma lista vazia indistinguível de "sem produtos" nem um
  ranking fabricado a partir de heurísticas client-side.
- **`byCampaign` fica modelado no enum mas sem busca escopada por campanha nesta task.** Diferente
  de `byCollection` (que é literalmente `CatalogFilter.collectionId`, uma dimensão que o próprio
  painel de filtros já expõe), "produtos de uma campanha" exigiria resolver
  `CatalogCampaign.relatedProductIds` primeiro (via `ListCampaignRelatedProductsUseCase`, já usado
  por `LookbookBloc`) — um caminho de busca genuinamente diferente (não paginado por cursor) que
  `CatalogFilterBloc` não implementa. Como nenhuma tela entregue nesta task chega a selecionar esse
  modo (`CatalogViewModeSelector` o exclui deliberadamente do seletor genérico, documentado em seu
  próprio doc comment), isso não é um caminho quebrado alcançável pelo usuário — é uma lacuna
  documentada, não um atalho silencioso. Navegação por campanha continua via `LookbookPage`/
  `CampaignsPage` (TASK-080).
- **`favorites`/`lookbook` nunca passam por `CatalogFilterBloc`.** Reimplementar a busca de
  favoritos ou do lookbook aqui duplicaria `FavoritesBloc`/`LookbookBloc` inteiros (cada um já com
  sua própria paginação, cache e testes) — violação direta da regra "não duplicar" do projeto.
  `CatalogViewModeSelector` trata esses dois como atalhos de navegação
  (`onOpenFavorites`/`onOpenLookbook`), o mesmo contrato "quem hospeda decide" que
  `onProductSelected`/`onShareTap` já usam em `ProductGridPage`.
- **`onOpenFavorites`/`onOpenLookbook` não foram conectados no `bootstrap.dart`.** Não existe hoje
  nenhuma `FavoritesRoute`/`LookbookRoute` no `AppRouter` — `FavoritesPage`/`LookbookPage` nunca
  foram integradas ao router (pendência já registrada repetidamente por TASK-076/078/080/081).
  `CatalogViewModeSelector` já lida com esse caso graciosamente (sem callback, apenas despacha o
  evento de troca de modo, que o bloc trata defensivamente).
- **Disponibilidade e tamanho são aplicados *depois* da página buscada, não dentro da query do
  repositório.** `ProductRepository`/`SharedPreferencesProductRepository` não conhecem
  `VariantAvailabilityRepository`/`SizeGridTemplateRepository` (mantendo cada repositório com uma
  única responsabilidade); `CatalogFilterBloc` já busca disponibilidade para renderizar os cards
  de qualquer forma, então aplicar o filtro sobre esse mesmo dado é praticamente gratuito. O
  trade-off aceito: uma página pode retornar menos itens do que o `limit` pedido quando esses
  filtros estão ativos (itens filtrados depois de já paginados) — o usuário simplesmente toca
  "carregar mais" de novo; mesmo trade-off que "erro em página intermediária preservando itens já
  exibidos" já aceita em `ProductGridBloc`.
- **Botões do painel de filtros empilhados verticalmente, não lado a lado.** O painel lateral fixo
  do desktop (`AppAdminPageLayout`) tem ~232px de largura útil — estreito demais para "Limpar
  filtros"/"Aplicar filtros" como duas metades de um `Row` sem estourar (`RenderFlex overflowed`,
  pego pelos testes de widget). Cada botão em largura total (`AppButton(expand: true)`) resolve
  tanto no mobile quanto no desktop.

## Riscos conhecidos

- `CatalogFilterPage`/a nova `CatalogBrowseRoute` não estão hoje conectadas a nenhum ponto de
  entrada existente do catálogo (`CatalogHomePage`'s "ver tudo", banners de coleção/campanha) —
  wiring de ponto de entrada explícito fica como pendência (ver abaixo). A rota e a página em si
  estão prontas e testadas de ponta a ponta.
- `byCampaign` não tem busca real implementada (ver "Decisões técnicas") — não é alcançável pelo
  usuário nesta entrega, mas um futuro caller que selecione esse modo sem mais trabalho veria uma
  grade vazia sem explicação, não uma falha.

## Pendências

- Conectar `CatalogFilterPage`/`CatalogBrowseRoute` a um ponto de entrada real (ex.: botão "ver
  tudo"/"filtrar" na `CatalogHomePage`).
- Implementar busca real escopada por campanha para `CatalogViewMode.byCampaign` (via
  `ListCampaignRelatedProductsUseCase`) quando uma tela de campanha precisar dela.
- Modelar e aplicar o filtro de faixa de preço quando a Price List (EPIC-11, TASK-083 em diante)
  existir.
- Implementar `bestSellers`/`recommended` de verdade quando existir agregação de vendas
  (Pedidos, EPIC-13) e/ou um motor de recomendação.
- Conectar `FavoritesRoute`/`LookbookRoute` ao `AppRouter` para que
  `onOpenFavorites`/`onOpenLookbook` tenham navegação real (pendência já registrada por
  TASK-076/078/080/081).

## Evidências

- `flutter analyze`: `No issues found!`
- `flutter test`: `All tests passed!` (1867 testes).
- `dart format --set-exit-if-changed .`: sem diferenças pendentes nos arquivos desta task.

## Commit

`feat(catalog): implement filterable browsing view modes and advanced filters`

## Push

Não realizado nesta rodada (não autorizado).

## Hash do commit

Ver seção "Commit" da resposta final — hash real do `git commit`, nunca inventado.

## Branch

main
