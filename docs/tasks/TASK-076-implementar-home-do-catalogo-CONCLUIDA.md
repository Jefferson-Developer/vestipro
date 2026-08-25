# TASK-076 — Concluída (2026-08-25)

## Resumo

Implementada a home do catálogo digital (EPIC-10), nova feature `lib/features/catalog`: uma
tela premium, responsiva e orientada por dados que compõe até 3 seções hoje —
"Coleções em destaque", "Lançamentos" e "Campanhas em destaque" — carregadas de forma
independente (uma seção falhar nunca derruba as outras), com cache local
stale-while-revalidate para pintura instantânea/uso offline, analytics dedicado e reuso
total do grid/card de produto do Design System (nenhum card alternativo criado).

A task original dependia de TASK-077 (grid visual de produtos) e TASK-066 (coleções e
estações). TASK-066 já estava concluída; TASK-077 ainda não. Investigação do repositório
mostrou que TASK-024 (Design System, já concluída) já havia entregue `AppProductGrid` +
`AppProductCardData`, o componente de card/grid de produto que a própria TASK-076 manda
reaproveitar ("TASK-024/TASK-077"). Esse componente já existente supre a dependência real
desta task; TASK-077 poderá evoluir o componente para a tela de grid completa sem exigir
mudança de arquitetura aqui.

"Mais vendidos", "recomendados" e "pronta entrega" (EPIC-16/17/12, ainda não implementados)
foram **conscientemente deixados fora** desta entrega: a task proíbe calcular esses dados no
cliente, e simular uma agregação server-side inexistente violaria essa mesma regra. O
domínio (`CatalogHomeSectionType`) já modela os 6 tipos do vocabulário de negócio e o BLoC já
orquestra "seção por use case independente" de forma genérica — adicionar esses 3 tipos no
futuro é só registrar um novo *runner*, sem tocar a arquitetura.

## Agentes utilizados

- `flutter-senior-architect` (domínio, use cases, repositórios, BLoC, extensão do
  `ProductRepository`, DI, testes).
- `flutter-ui-design-specialist` (extração do card/skeleton do Design System para
  `AppProductCard`/`AppProductCardSkeleton`, `AppProductCarousel`, layout responsivo,
  estados de loading/empty/error/stale, acessibilidade).
- `vestipro-sales-representative-specialist` (orientação de requisito: a home é o ponto de
  entrada do vendedor para navegar o catálogo — priorizar velocidade, confiança nos dados
  exibidos e nunca esconder/forjar disponibilidade).

## Arquivos criados

Domínio (`lib/features/catalog/domain`):
- `entities/catalog_home_section_type.dart`
- `entities/catalog_home_item.dart` (+ `.freezed.dart`)
- `entities/catalog_home_section.dart` (+ `.freezed.dart`)
- `entities/catalog_home_section_config.dart` (+ `.freezed.dart`, inclui
  `defaultCatalogHomeSectionConfigs`)
- `entities/catalog_campaign.dart` (+ `.freezed.dart`)
- `entities/catalog_home_snapshot.dart` (+ `.freezed.dart`)
- `repositories/catalog_campaign_repository.dart`
- `repositories/catalog_home_config_repository.dart`
- `repositories/catalog_home_cache_repository.dart`
- `usecases/get_catalog_home_config_use_case.dart`
- `usecases/get_featured_collections_section_use_case.dart`
- `usecases/get_new_arrivals_section_use_case.dart`
- `usecases/get_catalog_campaigns_section_use_case.dart`
- `usecases/load_catalog_home_cache_use_case.dart`
- `usecases/save_catalog_home_cache_use_case.dart`

Dados (`lib/features/catalog/data/repositories`):
- `shared_preferences_catalog_campaign_repository.dart` (leitura local; escrita fica para
  TASK-080)
- `remote_config_catalog_home_config_repository.dart`
- `shared_preferences_catalog_home_cache_repository.dart`

Apresentação (`lib/features/catalog/presentation`):
- `bloc/catalog_home_event.dart`, `bloc/catalog_home_state.dart`, `bloc/catalog_home_bloc.dart`
- `widgets/catalog_home_section_view.dart`
- `pages/catalog_home_page.dart`

- `lib/features/catalog/catalog.dart` (barrel)
- `lib/core/design_system/components/catalog/app_product_carousel.dart`

Testes novos:
- `test/features/catalog/domain/entities/catalog_campaign_test.dart`
- `test/features/catalog/domain/usecases/get_catalog_home_config_use_case_test.dart`
- `test/features/catalog/domain/usecases/get_featured_collections_section_use_case_test.dart`
- `test/features/catalog/domain/usecases/get_new_arrivals_section_use_case_test.dart`
- `test/features/catalog/domain/usecases/get_catalog_campaigns_section_use_case_test.dart`
- `test/features/catalog/data/repositories/shared_preferences_catalog_campaign_repository_test.dart`
- `test/features/catalog/data/repositories/remote_config_catalog_home_config_repository_test.dart`
- `test/features/catalog/data/repositories/shared_preferences_catalog_home_cache_repository_test.dart`
- `test/features/catalog/presentation/bloc/catalog_home_bloc_test.dart`
- `test/features/catalog/presentation/widgets/catalog_home_section_view_test.dart`
- `test/features/catalog/presentation/pages/catalog_home_page_test.dart`
- `test/features/catalog/catalog_test_fakes.dart` (fakes/factories compartilhados)
- `test/core/design_system/components/catalog/app_product_carousel_test.dart`

## Arquivos alterados

- `lib/features/products/domain/repositories/product_repository.dart`: novo método
  `listRecentlyLaunched` (aditivo, não quebra contrato existente).
- `lib/features/products/data/repositories/shared_preferences_product_repository.dart`:
  implementação de `listRecentlyLaunched`.
- `lib/core/design_system/components/catalog/app_product_grid.dart`: `_AppProductGridCard`/
  `_AppProductGridSkeletonCard` tornados públicos (`AppProductCard`/`AppProductCardSkeleton`)
  para reuso pelo novo `AppProductCarousel` — sem alterar comportamento/visual existente.
- `lib/core/design_system/components/components.dart`: export do novo
  `app_product_carousel.dart`.
- `lib/core/analytics/analytics_events.dart`: novas constantes `catalogHomeViewed`
  (`catalog_home_viewed`) e `catalogSectionOpened` (`catalog_section_opened`).
- `lib/core/feature_flags/feature_flag_registry.dart`: novo flag
  `configCatalogHomeSectionsJson` (`config_catalog_home_sections_json`), string, default `""`.
- `docs/architecture/feature-flags.md`: linha da tabela para o novo flag.
- `lib/app/injection.config.dart`: gerado por `build_runner` (DI dos novos tipos).
- 11 arquivos de teste de `test/features/products/...` que implementam `ProductRepository`
  como fake: adicionado o novo método `listRecentlyLaunched` (retorno vazio) para manter
  compilação após a extensão do contrato.
- `test/features/products/data/repositories/shared_preferences_product_repository_test.dart`:
  novo grupo `listRecentlyLaunched` (ordenação, filtro de status/soft-delete, limite, escopo
  por empresa).
- `test/core/analytics/analytics_events_test.dart`: taxonomia atualizada com os 2 novos
  eventos.
- `docs/tasks/TASKS.md`: checkbox da TASK-076 marcado e progresso atualizado para 76/220.

## Arquitetura utilizada

Clean Architecture feature-first, igual ao restante do projeto: `CatalogHomePage` (UI) →
`CatalogHomeBloc` → 3 use cases de seção + 1 use case de config + 2 use cases de cache →
contratos de repositório (`CollectionRepository`/`ProductRepository`, já existentes;
`CatalogCampaignRepository`, `CatalogHomeConfigRepository`, `CatalogHomeCacheRepository`,
novos) → implementações locais (`SharedPreferences`, mesmo padrão local-first de
`SharedPreferencesCollectionRepository`/`SharedPreferencesProductRepository`) e
`RemoteConfigCatalogHomeConfigRepository` (Remote Config via `FeatureFlagService`, nunca
Firebase direto). Domínio não importa Flutter/Firebase. UI nunca acessa
Firestore/Storage/Drift diretamente. `CatalogHomeSection`/`CatalogHomeItem` são o único
modelo de apresentação — a mesma forma é usada tanto para dado fresco quanto para o
snapshot cacheado, então a UI nunca precisa de dois caminhos de renderização.

## Regras de negócio implementadas

- No máximo 3 seções simultâneas hoje (dentro do limite de 4–6 da task); seções vazias nunca
  são exibidas (`CatalogHomeSection.isEmpty` filtra antes de chegar ao estado/à UI).
- Uma seção falhar nunca derruba as demais: cada seção é uma `Future` independente, capturada
  em `AppResult` (nunca lança), e o BLoC só desce para "falha total" quando **todas** as
  seções habilitadas falham e não há cache para mostrar.
- "Mais vendidos"/"recomendados"/"pronta entrega" propositalmente não implementados nesta
  task — nenhum cálculo client-side é feito para simulá-los; ver "Pendências".
- Composição das seções (tipo/título/ordem/prioridade/limite/habilitado) é orientada por
  dados (`CatalogHomeConfigRepository`, hoje via Remote Config), nunca hardcoded na página.
- Nenhuma seção simula urgência falsa: "lançamentos" usa o badge fixo "Lançamento" (dado
  real, não contagem de estoque); nenhuma mensagem de "restam poucas peças" é exibida.
- RBAC/escopo: consultas sempre passam `organizationId` (e `companyId` quando aplicável);
  `listRecentlyLaunched` filtra por empresa ativa (produto da própria empresa ou
  organização-wide) e nunca lista produto de outra organização.

## Regras Firebase implementadas

Nenhuma regra nova de Firestore/Storage — a feature usa apenas repositórios locais
(`SharedPreferences`) e `FeatureFlagService`/Remote Config, seguindo o mesmo padrão
"local-first até o backend real existir" já usado por `Collection`/`Product`. Nenhuma regra
existente foi enfraquecida.

## Analytics implementado

- `catalog_home_viewed`: disparado uma única vez por sessão de tela, assim que a home tem
  algo para mostrar (seja pelo cache instantâneo, seja pelo carregamento fresco), com
  `organization_id`, `sections_count` e `is_stale` — nenhum dado pessoal.
- `catalog_section_opened`: disparado quando o vendedor/cliente toca em um item de seção, com
  `organization_id` e `section_type`.

## Crashlytics implementado

Nenhuma instrumentação nova de Crashlytics — falhas de repositório já convertem para
`Failure`/`AppResult` pelo fluxo central existente; nenhum `print`/exceção não tratada foi
introduzido.

## Impacto offline

Novo `CatalogHomeCacheRepository` (`SharedPreferencesCatalogHomeCacheRepository`) implementa
stale-while-revalidate: a última home carregada com sucesso é serializada localmente
(já no formato "achatado" `CatalogHomeSection`/`CatalogHomeItem`) e repintada instantaneamente
no próximo acesso, com `CatalogHomeState.isStale`/`cachedAt` guiando o aviso visual "pode
estar desatualizado". Se a revalidação falhar (ex.: offline), a tela continua mostrando os
dados em cache em vez de zerar a UI.

## Impacto multi-tenant

Todo carregamento é escopado por `organizationId` (e `companyId`, quando informado); o cache
local é isolado por `organizationId`+`companyId` (chave composta), evitando vazamento de
catálogo entre tenants/empresas mesmo no dispositivo compartilhado.

## Testes criados

- Domínio: `CatalogCampaign.isVisibleAt` (janela de datas, inativo, soft-delete); os 3 use
  cases de seção (mapeamento, ordenação, filtro, propagação de falha, seção vazia);
  `GetCatalogHomeConfigUseCase` (fallback para o default seguro).
- Dados: os 3 repositórios locais/Remote-Config (round-trip, isolamento por
  organização/empresa, fallback em JSON malformado/tipo desconhecido).
- BLoC (`bloc_test`): carregamento com sucesso total, sucesso parcial (uma seção falha),
  todas as seções vazias, falha total sem cache, cache instantâneo + revalidação offline
  mantendo `isStale`, disparo único de `catalog_home_viewed`, disparo de
  `catalog_section_opened`.
- Widgets: `AppProductCarousel` (renderização, skeleton, vazio, tap); `CatalogHomeSectionView`
  (título + itens, tap); `CatalogHomePage` (skeleton inicial, seções carregadas sem título
  vazio para seção sem conteúdo, estado vazio amigável, estado de erro completo com retry,
  aviso de dado desatualizado, layout responsivo mobile-vs-desktop, rótulo de acessibilidade
  por seção).
- Regressão: `SharedPreferencesProductRepository.listRecentlyLaunched` (ordenação, filtro de
  status/soft-delete, limite, escopo por empresa); taxonomia de `AnalyticsEvents` atualizada.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

Primeiras execuções formataram arquivos novos (esperado). Execução final:
`Formatted 1226 files (0 changed)`.

## Resultado do analyzer

`No issues found! (ran in 12.6s)` (após todas as alterações, incluindo a extensão do
`ProductRepository` e o rename no Design System).

## Resultado dos testes

`flutter test` (suíte completa): `All tests passed!` — `+1604` (1604 testes, 0 falhas), sem
`skip`.

## Decisões técnicas

- Dependência declarada da task em TASK-077 foi resolvida reaproveitando o componente que
  TASK-024 já entregou (`AppProductGrid`/`AppProductCardData`), em vez de bloquear a task ou
  de criar um card duplicado — exatamente o que a própria TASK-076 pede ("reaproveitar
  TASK-024/TASK-077", "não criar card alternativo").
- `_AppProductGridCard`/`_AppProductGridSkeletonCard` (privados) foram promovidos a
  `AppProductCard`/`AppProductCardSkeleton` (públicos) só para permitir o novo
  `AppProductCarousel` reaproveitá-los — nenhuma mudança de comportamento/visual, apenas
  visibilidade.
- Modelo de apresentação único (`CatalogHomeItem`/`CatalogHomeSection`) para dado fresco e
  para cache: evita dois caminhos de renderização e torna o cache trivial de serializar
  (só primitivos).
- "Mais vendidos"/"recomendados"/"pronta entrega" ficaram fora da implementação real (sem
  *runner* registrado no BLoC) em vez de fake/estimativa client-side, por exigência explícita
  da task e por dependerem de EPIC-16/17/12 (ainda não implementados). O enum e a
  orquestração já suportam plugar essas 3 seções depois sem mudança de arquitetura.
  `SharedPreferencesCatalogCampaignRepository` foi implementado só como leitura
  (`listByOrganization`); a escrita/admin fica para TASK-080, seguindo o mesmo precedente
  incremental de `ProductRepository` (TASK-064 → TASK-065).
- `ProductRepository.listRecentlyLaunched` foi adicionado (aditivo) porque não existia
  nenhuma forma de listar produtos por organização — só `getById`/`getByIds` (por id
  explícito). Extensão exigiu atualizar 11 fakes de teste de `ProductRepository` em arquivos
  de outras tasks (apenas a assinatura do novo método, sem alterar nenhum teste existente).
- Nenhuma rota foi registrada em `AppRouter`/`app_router.dart`: seguindo o mesmo padrão já
  usado por `CollectionsPage`/`ProductSearchPage`/etc. (páginas de features anteriores
  concluídas também não estão fiadas ao router ainda), a integração de navegação real fica
  para uma task de shell/navegação dedicada.

## Riscos conhecidos

- Sem página de administração para campanhas ainda (fica em TASK-080): a seção "Campanhas em
  destaque" só aparece quando algo grava a chave local
  `catalog_campaigns_<organizationId>` (ou quando TASK-080 implementar a escrita real).
- `config_catalog_home_sections_json` ainda não tem editor no console/documentação
  operacional além da tabela em `docs/architecture/feature-flags.md` — é só leitura.
- `CatalogHomePage` não está registrada no `AppRouter`, mesmo padrão de outras páginas de
  catálogo/produto já concluídas; precisa de uma task de navegação para ficar acessível
  fim a fim no app.

## Pendências

- Implementar "mais vendidos" e "recomendados" quando EPIC-16/17 (agregação server-side)
  existir — plugar um novo *runner* em `CatalogHomeBloc._runnerFor`.
- Implementar "pronta entrega" quando EPIC-12 (disponibilidade/estoque agregado) existir.
- TASK-080: CRUD real de `CatalogCampaign` (hoje só leitura).
- TASK-077/078/081/082: grid completo de produtos, detalhe visual, compartilhamento e
  filtros avançados — a home já linka para eles via `onSectionItemTap`, mas a navegação real
  depende dessas telas existirem.
- Integração de `CatalogHomePage` ao `AppRouter` (nenhuma página de catálogo/produto está
  integrada ainda).

## Evidências

- `flutter analyze`: `No issues found!`
- `flutter test`: `All tests passed!` (1604 testes).
- `dart format --set-exit-if-changed .`: `Formatted 1226 files (0 changed)`.

## Commit

`feat(catalog): implement catalog home with independent sections and stale-while-revalidate cache`

## Push

Não realizado nesta rodada (não autorizado).

## Hash do commit

Ver seção "Commit" da resposta final — hash real do `git commit`, nunca inventado.

## Branch

main
