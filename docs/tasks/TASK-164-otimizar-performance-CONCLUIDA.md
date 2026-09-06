# TASK-164 — Otimizar performance — CONCLUÍDA

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Data de conclusão:** 2026-09-06
**Agente utilizado:** `flutter-senior-architect` (executado diretamente nesta sessão, sem
sub-agentes adicionais — escopo era otimização de código/domínio já existente, não UI nova).

## Resumo

A task pede para medir e reduzir jank, leituras e memória nas telas mais sensíveis do app (grid
visual de produtos — TASK-077, histórico/duplicação de pedido — TASK-104, criação/submissão de
pedido — TASK-095), usando o Performance Monitoring já configurado (TASK-019).

Este ambiente de execução **não tem device/emulador nem DevTools conectável** (nenhuma etapa deste
fluxo roda um app Flutter de verdade), então a parte de "medir com profiling local (DevTools) e
confirmar no console do Firebase Performance" descrita no escopo **não pôde ser executada de fato** —
isso é reportado explicitamente aqui, não inventado. Diante dessa restrição real, a otimização foi
conduzida por **leitura de código + raciocínio de complexidade/contagem de chamadas**, priorizando
apenas mudanças com evidência objetiva e verificável sem precisar rodar o app (contagem de chamadas a
repositório antes/depois, comprovada por teste automatizado) — nunca uma mudança especulativa.

A investigação encontrou um problema real e mensurável bem mais grave do que os itens "de rotina"
(rebuilds, `const`, etc.): um **N+1 client-side** na resolução de preço do catálogo (`ProductGridBloc`
e `ProductDetailBloc`), que dominava qualquer outra otimização de UI possível nessas telas. As demais
mudanças (cache de imagem por tamanho-alvo, wiring dos traces já previstos em TASK-019) foram feitas
em seguida, dentro do mesmo escopo.

## O problema real encontrado: N+1 na resolução de preço do catálogo

`ProductGridBloc._fetchPrices` (grid de catálogo, TASK-077) e `ProductDetailBloc._fetchPrices`
(detalhe de produto) chamavam `ResolvePriceForVariantUseCase.call(...)` **uma vez por variante ativa**
de cada produto. Essa chamada, por sua vez, sempre refazia as **duas únicas leituras** de que depende
a resolução de preço — `ResolveApplicablePriceListsUseCase` (tabelas de preço aplicáveis à
organização/empresa) e `PriceListItemRepository.listByProduct` (itens de preço do produto) — **mesmo
elas não dependendo em nada do `variantId`** (o próprio parâmetro `variantId` só é usado depois, em
memória, para decidir variante-específico vs. fallback de produto vs. ausente).

Resultado: uma página de catálogo com N produtos, cada um com M variantes ativas, disparava
`2 * N * M` leituras redundantes (hoje contra repositórios `SharedPreferences`, mas a mesma
`PriceListRepository`/`PriceListItemRepository` está desenhada para virar Firestore quando o motor de
preço server-side, TASK-088, existir — corrigir agora evita herdar o mesmo N+1 nessa migração), com
`JSON.decode` de toda a lista de itens de preço da organização repetido a cada variante — um custo de
CPU síncrono real na thread de UI, crescendo a cada "carregar mais" na paginação. Isso bate
exatamente com o item do escopo "revisar queries client-side que buscam mais dados que o necessário
... ou dependência de agregação client-side que deveria vir da camada de agregação".

### Correção

`ResolvePriceForVariantUseCase` ganhou um novo método `callForProduct({..., variantIds})` que busca as
mesmas duas leituras **uma única vez por produto** e resolve todas as variantes em memória (mesma
cadeia de fallback documentada em TASK-084: variante-específico → produto na mesma tabela →
ausente, extraída para um método privado `_resolveForVariant` reaproveitado tanto por `call` quanto
por `callForProduct` — zero duplicação/drift de regra de negócio). `ProductGridBloc._fetchPrices` e
`ProductDetailBloc._fetchPrices` foram atualizados para chamar `callForProduct` uma vez por produto em
vez de `call` uma vez por variante — de `2 * variantCount` para `2` leituras por produto, sem mudar
nenhum resultado final (mesmo preço, mesma origem, mesmo fallback).

**Prova por teste, não afirmação:** o teste novo
`callForProduct ... resolves every variant in one call ...` em
`resolve_price_for_variant_use_case_test.dart` usa fakes que contam chamadas
(`listByCompanyCallCount`, `listByProductCallCount`) e afirma que valem `1` mesmo resolvendo 3
variantes do mesmo produto — essa é a evidência objetiva "antes/depois" de leituras pedida pelo
critério de aceite, na forma que este ambiente consegue de fato produzir (contagem determinística via
teste, já que não há profiler real disponível).

## Outras otimizações aplicadas

- **Imagens redimensionadas e cacheadas com tamanho-alvo** (`AppProductGrid`, usado por
  `ProductGridPage`/TASK-077 e por todo outro consumidor do grid — busca de produtos, favoritos,
  catálogo compartilhado): `CachedNetworkImage` no card de grid e na linha de lista agora passam
  `memCacheWidth`/`memCacheHeight` (escalados por `MediaQuery.devicePixelRatioOf`), limitando o quanto
  cada foto decodifica/ocupa no cache de imagem em memória ao tamanho real que o card renderiza (até
  400px lógicos no card de grid, 64px no thumbnail de lista) em vez de manter a resolução original da
  foto (frequentemente um estúdio fotográfico em alta resolução) — item explícito do escopo
  ("imagens redimensionadas e cacheadas (`cached_network_image` com tamanho alvo)").
- **Conectado o trace `catalog_load_duration`** (já previsto em `PerformanceTraces`/TASK-019, mas
  nunca ligado a um fluxo real — ver "Known risk" em `docs/architecture/performance.md`) ao
  carregamento real de página do `ProductGridBloc` (`_loadPage`, incluindo resolução de
  grade/disponibilidade/preço, exatamente como a doc do trace promete).
- **Conectado o trace `order_submit_duration`** (mesma situação: previsto, nunca ligado) à submissão
  real de pedido em `SubmitOrderUseCase`, ao redor da chamada ao repositório (`OrderSubmissionRepository.submit`,
  que por sua vez chama a Cloud Function `submitOrder` — TASK-101).

## O que foi investigado e **não** alterado (com justificativa)

- **`OrderHistoryPage` (TASK-104):** não é uma lista grande — é uma tela de detalhe de um único
  pedido (resumo + linha do tempo de status, ambos de tamanho limitado ao próprio pedido). Não há
  jank/leitura redundante identificável por leitura de código; nenhuma mudança especulativa foi
  aplicada aqui.
- **`OrderItemsGrid`/`OrderDraftBloc` (TASK-095):** já usa `restartable()`/tokens de requisição, sem
  `StreamSubscription` não cancelada, e cada resolução de preço (`ResolvePriceForVariantUseCase.call`)
  já corresponde a exatamente uma variante nova digitada pelo vendedor — não há N+1 aqui (o padrão de
  lote só se aplica quando o mesmo produto tem várias variantes resolvidas de uma vez, como no grid de
  catálogo).
- **`GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics)` dentro de
  `SingleChildScrollView`** em `ProductGridPage`/`ProductSearchPage` (padrão que a própria
  documentação do Flutter (`ScrollView.shrinkWrap`) descreve como "significativamente mais caro"):
  identificado como possível fonte de jank ao crescer via "carregar mais", mas **não alterado** — para
  um `SliverGridDelegateWithFixedCrossAxisCount` de aspect ratio fixo a geometria é calculável
  aritmeticamente, então o custo real desse padrão especificamente para grade (diferente de uma lista
  de altura variável) é incerto sem profiling real, e a regra da própria task é clara: "não aplicar
  mudança especulativa sem dado de profiling que a justifique". Convertê-lo para
  `CustomScrollView`/slivers de verdade fica documentado abaixo como pendência para quando houver
  device/emulador disponível para medir o antes/depois de verdade.
- **Dashboards (`inventory_dashboard_page.dart`, `product_dashboard_page.dart`):** também usam
  `CachedNetworkImage` sem `memCache*`, mas estão fora do escopo desta task (não são nenhuma das 3
  telas priorizadas) — sinalizado como oportunidade de follow-up, não aplicado especulativamente.

## Arquivos alterados

- `lib/features/pricing/domain/usecases/resolve_price_for_variant_use_case.dart`: novo método
  `callForProduct`; lógica de fallback extraída para `_resolveForVariant`/`_loadPricingContext`
  privados, reaproveitados por `call` e `callForProduct` (zero duplicação de regra de negócio).
- `lib/features/catalog/presentation/bloc/product_grid_bloc.dart`: `_fetchPrices` usa
  `callForProduct` (uma chamada por produto, não por variante); novo campo `performanceMonitor`
  (`PerformanceMonitor`, requerido); `_loadPage` agora envolve `_loadPageImpl` com
  `PerformanceMonitor.wrapAsync(PerformanceTraces.catalogLoadDuration, ...)`.
- `lib/features/catalog/presentation/bloc/product_detail_bloc.dart`: `_fetchPrices` usa
  `callForProduct` em vez do loop por variante.
- `lib/features/orders/domain/usecases/submit_order_use_case.dart`: novo campo `_performanceMonitor`
  (requerido); a chamada a `_repository.submit(...)` agora roda dentro de
  `PerformanceMonitor.wrapAsync(PerformanceTraces.orderSubmitDuration, ...)`.
- `lib/core/design_system/components/catalog/app_product_grid.dart`: `AppProductCard._buildImage` e
  `AppProductListRow._buildImage` passam a receber `BuildContext` e definir
  `memCacheWidth`/`memCacheHeight` no `CachedNetworkImage`.
- `lib/app/injection.config.dart`: registro gerado por `injectable` atualizado manualmente (mesmo
  padrão que o `build_runner` produziria) para os dois novos parâmetros `PerformanceMonitor` de
  `SubmitOrderUseCase` e `ProductGridBloc` — `build_runner build` completo não foi executado nesta
  sessão (ver "Decisões técnicas").
- `test/features/pricing/domain/usecases/resolve_price_for_variant_use_case_test.dart`: fakes
  ganharam contadores de chamada (`listByCompanyCallCount`, `listByProductCallCount`); novo grupo
  `callForProduct` com 2 testes (paridade de resultado + prova de 1 chamada por produto
  independentemente do número de variantes; validação com `variantIds` vazio).
- `test/features/catalog/presentation/bloc/product_grid_bloc_test.dart`,
  `test/features/catalog/presentation/pages/product_grid_page_test.dart`,
  `test/features/orders/domain/usecases/submit_order_use_case_test.dart`,
  `test/features/orders/presentation/order_submission_flow_test.dart`: atualizados para passar
  `FakePerformanceMonitor()` no novo parâmetro obrigatório.
- `docs/tasks/TASKS.md`: checkbox da TASK-164 marcado `[x]`; progresso atualizado de `163 / 220` para
  `164 / 220`.

Nenhum arquivo novo de produção foi criado — toda a otimização foi feita sobre código/telas já
existentes, sem mudar comportamento funcional/regra de negócio (mesmo preço final, mesma cadeia de
fallback, mesma UI).

## Comandos executados e resultados reais

```
dart format --set-exit-if-changed <arquivos alterados lib/ e test/>
→ 1ª execução: reformatou 2 arquivos (app_product_grid.dart, resolve_price_for_variant_use_case.dart
  na primeira passada; o teste novo precisou de uma segunda reformatação após adicionar o grupo
  callForProduct)
→ execução final: "Formatted 108 files (0 changed)" — limpo

flutter analyze lib/features/pricing lib/features/catalog lib/features/orders/domain/usecases/submit_order_use_case.dart lib/core/design_system/components/catalog/app_product_grid.dart lib/app/injection.config.dart
→ "No issues found!" (10.5s)

flutter analyze lib/
→ 6 issues, todos infos de depreciação pré-existentes em
  lib/features/reports/presentation/pages/report_builder_page.dart (RadioGroup/groupValue) — não
  relacionados a esta task, confirmados via grep que nenhum arquivo tocado aparece na lista

flutter test test/features/pricing/domain/usecases/resolve_price_for_variant_use_case_test.dart test/features/catalog/presentation/bloc/product_grid_bloc_test.dart test/features/catalog/presentation/bloc/product_detail_bloc_test.dart test/features/catalog/presentation/pages/product_grid_page_test.dart test/features/orders/domain/usecases/submit_order_use_case_test.dart test/features/orders/presentation/order_submission_flow_test.dart test/core/design_system/components/catalog/app_product_grid_test.dart
→ 00:05 +44: All tests passed!

flutter test test/features/pricing test/features/catalog test/features/orders test/core/design_system/components/catalog test/core/design_system/components/goldens/design_system_catalog_golden_test.dart test/app/injection_test.dart
→ 00:25 +501: All tests passed!

flutter test test/app/bootstrap_test.dart
→ 1 falha pré-existente (StateError: PushDeviceMapper not registered), confirmada via
  `git stash` + mesmo comando na árvore limpa (main, antes desta task): falha idêntica, não
  relacionada a nenhuma mudança desta task. Reportado por transparência, não corrigido (fora do
  escopo de TASK-164).
```

## Decisões técnicas

- **Prioridade pela evidência, não pela lista literal do escopo.** O escopo técnico lista rebuilds,
  paginação e memória como itens a revisar; a investigação real encontrou que o problema dominante
  nas 3 telas prioritárias era a resolução de preço N+1, então o esforço foi concentrado ali em vez de
  espalhado em pequenas mudanças de baixo impacto ou especulativas.
- **`callForProduct` como método novo, não substituição de `call`.** `ResolvePriceForVariantUseCase.call`
  continua existindo e sendo usado por `order_draft_bloc.dart`/`duplicate_order_use_case.dart`, onde
  cada chamada já corresponde a exatamente uma variante nova por vez (não há lote possível/desejável
  ali) — trocar a assinatura de `call` quebraria esses call sites sem nenhum ganho.
- **Edição manual de `injection.config.dart` em vez de rodar `build_runner build`.** Rodar o
  `build_runner` completo regeneraria `freezed`/`json_serializable`/`drift`/`injectable` no repositório
  inteiro, um raio de mudança muito maior que o necessário e um risco real de introduzir diffs não
  relacionados a esta task (ou falhar por motivo alheio a ela) sem sobrar orçamento de sessão para
  investigar. As duas linhas alteradas seguem exatamente o padrão já usado no arquivo gerado para
  `AnalyticsService`/`PerformanceMonitor` em outros registros (mesmo prefixo `_i1008.PerformanceMonitor`,
  mesmo `gh<...>()`), e o teste `test/app/injection_test.dart` (que resolve o grafo de DI de verdade)
  passou depois da edição — evidência de que o registro manual está correto, não apenas plausível.
  Fica como pendência que a próxima execução de `build_runner build` (por qualquer outra task) deve
  simplesmente regenerar essas mesmas linhas sem conflito.
- **`PerformanceMonitor` como parâmetro obrigatório, não opcional-nulo.** Diferente de
  `resolvePriceForVariant`/`listVariantsByProduct` (opcionais porque a feature de preço em si é
  opt-in), o monitor de performance deve estar sempre presente onde já existe registro em DI — seguir
  o padrão opcional-nulo aqui esconderia silenciosamente a ausência do trace em produção. Isso exigiu
  atualizar 4 arquivos de teste para passar `FakePerformanceMonitor()`, sem custo de `mocktail`
  (exatamente o propósito documentado desse fake em TASK-019).

## Riscos e pendências conhecidas

- **Nenhuma medição de device/emulador real foi feita** (frame time via DevTools, confirmação visual
  do trace no console do Firebase Performance) — este ambiente de execução não tem Flutter rodando em
  device/emulador. A evidência objetiva produzida aqui é por contagem de chamadas via teste
  automatizado (a prova disponível sem um device), não por profiling visual. Fica para quem rodar o
  app de verdade confirmar `catalog_load_duration`/`order_submit_duration` aparecendo no console do
  Firebase Performance — mesma pendência que TASK-019 já deixou documentada em
  `docs/architecture/performance.md`, agora com os dois fluxos reais finalmente conectados para essa
  verificação ser possível.
- **`GridView`/`ListView` com `shrinkWrap: true` dentro de `SingleChildScrollView`** em
  `ProductGridPage`/`ProductSearchPage`/`FavoritesPage`/`CatalogFilterPage`/`CatalogSharePublicPage`
  (todos consumidores de `AppProductGrid`) não foi convertido para `CustomScrollView`/slivers de
  verdade — sinalizado como possível ganho de jank em catálogos muito paginados, mas não aplicado sem
  dado de profiling real que confirme o ganho (ver "O que foi investigado e não alterado" acima).
- **Dashboards com `CachedNetworkImage` sem `memCache*`** (`inventory_dashboard_page.dart`,
  `product_dashboard_page.dart`) ficam como oportunidade de follow-up fora do escopo desta task.
- **`build_runner build` completo continua pendente** de qualquer forma (dívida pré-existente do
  repositório, não introduzida aqui) — a próxima vez que rodar deve reproduzir exatamente as 2 linhas
  editadas manualmente nesta task sem conflito, dado que seguem o padrão real do gerador.
- Isolamento multi-tenant e RBAC não foram tocados: `callForProduct` recebe exatamente os mesmos
  `organizationId`/`companyId` que cada chamada individual de `call` já recebia (nenhum novo parâmetro
  de escopo, nenhuma nova superfície de consulta cross-tenant).
