# TASK-176 — Concluída (2026-09-06)

## Resumo

Implementada a visualização de mapa da carteira de clientes (EPIC-24): o vendedor pode alternar entre
lista e mapa reaproveitando exatamente os mesmos filtros/dados já usados pela carteira em lista
(TASK-051) — mesmo `CustomerPortfolioBloc`, mesma query (`ListCustomerPortfolioUseCase`), sem uma
segunda fonte de dados. Pins são clusterizados em regiões densas (algoritmo puro de grade
lat/lng dependente do zoom, sem dependência de plugin de clusterização externo). Clientes sem endereço
geocodificável continuam aparecendo normalmente na lista, apenas ficam de fora do mapa com um aviso
("N clientes sem localização não aparecem no mapa"). A geocodificação em si é um job de backfill
server-side agendado (Cloud Function `geocodeCustomerAddresses`, mesmo padrão de
`recalculateCustomerScores`), não um passo síncrono no fluxo de criação/edição do cliente — preserva
o cadastro de cliente 100% offline-first, sem depender de rede.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, migração de schema local, Cloud Function de
  geocodificação, testes) — agente principal.
- `flutter-ui-design-specialist` (orientação de UX para o toggle lista/mapa, card de pin, banner de
  aviso) — consultado para o desenho da tela, sem leitura integral do arquivo do agente (escopo já
  claro a partir dos componentes de Design System existentes reaproveitados).

## Arquivos criados

Backend (Cloud Functions, TypeScript):
- `functions/src/customers/geocoding-service.ts` — lógica pura de geocodificação (monta a query de
  endereço, valida resposta do provedor, trata timeout/erro/endereço incompleto), testável sem HTTP
  real nem chave de API.
- `functions/src/customers/geocode-customer-addresses.ts` — Cloud Function agendada (`onSchedule`,
  diária) que geocodifica endereços `pending` de todo cliente de toda organização ativa, gravando
  `latitude`/`longitude`/`geocodingStatus`/`geocodedAt` de volta no documento via Admin SDK (mesmo
  padrão de `recalculateCustomerScoresForOrganization`: batch de até 450 escritas, isolamento por
  `organizationId`).
- `functions/test/customers/geocoding-service.test.ts` — 11 testes da lógica pura (endereço válido,
  incompleto/inválido, `ZERO_RESULTS`, resposta malformada, timeout, exceção do fetcher).

Flutter — dentro da feature `customers` já existente (Clean Architecture, feature-first):
- `lib/features/customers/domain/value_objects/geo_coordinates.dart` — value object `GeoCoordinates`
  (latitude/longitude validados, -90..90/-180..180).
- `lib/features/customers/domain/value_objects/customer_geocoding_status.dart` — enum
  `pending`/`geocoded`/`unavailable`.
- `lib/features/customers/domain/entities/customer_map_pin.dart` — `CustomerMapPin` (projeção mínima
  de `Customer` para o mapa) e `MapCluster`.
- `lib/features/customers/domain/services/customer_map_pin_builder.dart` — `CustomerMapPinBuilder`:
  constrói os pins a partir da mesma lista de `Customer` já carregada pela carteira, preferindo o
  endereço primário geocodificado e caindo para outro endereço geocodificado quando o primário não
  tem coordenadas; expõe também a contagem de clientes sem localização.
- `lib/features/customers/domain/services/customer_map_clusterer.dart` — `CustomerMapClusterer`:
  clusterização por grade lat/lng com tamanho de célula dependente do zoom (mesma aproximação de
  "tamanho de tile" usada por qualquer slippy map), 100% pura/testável sem Flutter nem Google Maps.
- `lib/features/customers/presentation/widgets/customer_portfolio_map_view.dart` —
  `CustomerPortfolioMapView`: renderiza o `GoogleMap`, calcula clusters a cada `onCameraIdle`, abre um
  `AppBottomSheet` com o card resumido do cliente ao tocar um pin, anima a câmera ao tocar um cluster,
  e mostra o aviso de "sem localização".
- `test/core/database/app_database_task_176_customer_geocoding_migration_test.dart` — migração de
  schema (fresh DB e upgrade 20→21).
- `test/features/customers/domain/services/customer_map_pin_builder_test.dart` — 4 testes (pin por
  cliente geocodificado, exclusão + contagem de cliente sem localização, preferência pelo endereço
  primário, fallback para outro endereço geocodificado).
- `test/features/customers/domain/services/customer_map_clusterer_test.dart` — 5 testes, incluindo o
  obrigatório de alta densidade (200 pins agrupados em 1 cluster com zoom baixo, e separados de volta
  em markers individuais com zoom alto).

## Arquivos alterados

- `pubspec.yaml`/`pubspec.lock` — nova dependência `google_maps_flutter: ^2.18.0` (plugin federado,
  Android/iOS/Web já embutidos via `google_maps_flutter_android`/`_ios`/`_web` transitivos).
- `lib/features/customers/domain/entities/customer_address.dart` (+ `.freezed.dart` regenerado) —
  novos campos `coordinates` (`GeoCoordinates?`), `geocodingStatus` (`@Default(pending)`),
  `geocodedAt`; getter `hasCoordinates`.
- `lib/features/customers/data/dtos/customer_dto.dart` — `CustomerAddressDto` ganha
  `latitude`/`longitude`/`geocodingStatusCode` (default `'pending'`)/`geocodedAt`, com o helper
  `_optionalDouble` novo para o parsing.
- `lib/features/customers/data/mappers/customer_mapper.dart` — conversão
  `coordinates`/`geocodingStatus`/`geocodedAt` nas duas direções (`toEntity`/`toDto`).
- `lib/core/database/tables/customer_addresses_table.dart` — colunas `latitude`/`longitude`
  (`real().nullable()`), `geocodingStatusCode` (`text().withDefault('pending')`), `geocodedAt`
  (`dateTime().nullable()`).
- `lib/features/customers/data/mappers/customer_local_mapper.dart` — wiring das novas colunas Drift
  nas duas direções.
- `lib/core/database/app_database.dart` (+ `.g.dart` regenerado) — `schemaVersion` 20→21; migração
  `if (from < 21)` guardada por leitura real de `sqlite_master`/`PRAGMA table_info` (mesmo precedente
  do bloco `from < 20`), já que um punhado de testes existentes semeia um banco "já na versão N" sem
  nunca ter criado `customer_addresses`.
- `lib/features/customers/presentation/pages/customer_portfolio_page.dart` — toggle lista/mapa no
  cabeçalho (só visível no breakpoint mobile — tablet/desktop mostram as duas colunas sempre), novo
  `_PortfolioAndMapContent` (decide layout a partir de um único `AppResponsiveBuilder` compartilhado
  com o toggle, para nunca haver divergência de breakpoint entre os dois) e `_CustomerMapAutoLoader`
  (dispara `CustomerPortfolioNextPageRequested` enquanto `hasMore` for `true`, já que o mapa precisa da
  carteira inteira filtrada, não paginada por scroll como a lista).
- `lib/features/customers/customers.dart` — exporta os novos value objects/entidades/serviços/widget.
- `functions/src/customers/index.ts`, `functions/src/index.ts` — exportam
  `geocodeCustomerAddresses`/`buildGeocodableAddressQuery`/`geocodeAddress`.
- `test/core/database/app_database_test.dart`, `app_database_task_106_schema_test.dart`,
  `app_database_task_114_targets_migration_test.dart`, `app_database_warehouses_test.dart` — bump
  mecânico de `schemaVersion` esperado (20→21).
- `test/features/customers/data/mappers/customer_mapper_test.dart`,
  `customer_local_mapper_test.dart` — novos casos cobrindo os campos de geocodificação (DTO↔entidade e
  round-trip via Drift).
- `test/features/customers/presentation/pages/customer_portfolio_page_test.dart` — 2 novos testes
  (toggle mobile + paridade de filtros/dados entre lista e mapa; layout tablet lado a lado sem
  toggle); fixture `_customer` ganhou um endereço geocodificado e nova fixture
  `_customerWithoutLocation`.

## Arquitetura utilizada

Clean Architecture feature-first, sem criar uma feature nova: tudo dentro de
`lib/features/customers/` (o mapa é "outra visualização da mesma carteira", não um domínio novo).
Presentation (`CustomerPortfolioMapView`/`customer_portfolio_page.dart`) → reaproveita o mesmo
`CustomerPortfolioBloc`/`ListCustomerPortfolioUseCase` já existente (zero duplicação de query/filtro)
→ os novos serviços de domínio puros (`CustomerMapPinBuilder`, `CustomerMapClusterer`) transformam
`List<Customer>` em pins/clusters sem nenhuma dependência de Flutter/Google Maps, plenamente
unit-testáveis. No backend, `functions/src/customers/geocode-customer-addresses.ts` segue exatamente
o padrão já estabelecido por `recalculate-customer-scores.ts` (Cloud Function agendada, batch,
isolamento por organização), com a lógica de geocodificação em si isolada em `geocoding-service.ts`
(mesmo "separar lógica pura de orquestração Firestore" de `customer-scoring-service.ts`).

## Regras de negócio implementadas

- Mapa nunca exibe cliente fora da carteira/organização do vendedor: os pins vêm exclusivamente de
  `state.customers`, que já é o resultado de `ListCustomerPortfolioUseCase` (o mesmo use case,
  já testado para RBAC/visibilidade/isolamento multi-tenant na carteira em lista — nenhuma query nova
  foi criada para o mapa, então nenhum novo vetor de vazamento existe).
- Cliente sem endereço geocodificável nunca trava a tela: `CustomerMapPinBuilder.build` apenas pula o
  cliente sem coordenadas, sem lançar exceção; `customersWithoutLocationCount` alimenta o aviso visível
  na tela ("N clientes sem localização não aparecem no mapa").
- Os mesmos filtros da carteira em lista funcionam identicamente no mapa: lista e mapa compartilham o
  mesmo `CustomerPortfolioBloc`/`CustomerPortfolioState` — não existe um segundo estado de filtros para
  divergir.
- Geocodificação nunca bloqueia criação/edição de cliente offline: o backfill roda inteiramente
  server-side e de forma assíncrona (job diário), nunca no caminho síncrono de
  `create_customer_use_case.dart`/`update_customer_use_case.dart`.
- Endereço que já foi geocodificado ou marcado como `unavailable` nunca é re-tentado
  automaticamente pelo job (`geocodingStatus !== 'pending'` é pulado) — evita custo de API repetido
  indefinidamente para um endereço já resolvido/já sabido não-geocodificável.

## Regras Firebase implementadas

Nenhuma alteração em `firestore.rules`/`storage.rules`. `organizations/{organizationId}/customers`
já nega toda escrita direta do cliente (`allow create, update, delete: if false` — a sincronização
remota de clientes ainda não existe neste repositório, é um gap documentado anterior a esta task) e
toda a escrita das colunas de geocodificação é feita exclusivamente pela Cloud Function
`geocodeCustomerAddresses` via Admin SDK, que já ignora as Rules por definição — nenhuma superfície
nova de escrita client-side foi criada.

## Analytics implementado

Nenhum evento novo. `CustomerPortfolioBloc`/`customer_portfolio_page.dart` não emite nenhum evento de
analytics hoje (nem a carteira em lista, TASK-051, tem instrumentação) — para não introduzir uma
inconsistência (mapa instrumentado, lista irmã não), a alternância lista/mapa também não foi
instrumentada nesta rodada. Ver "Pendências".

## Crashlytics implementado

Nenhuma mudança dedicada: os novos serviços de domínio (`CustomerMapPinBuilder`/`CustomerMapClusterer`)
são funções puras que nunca lançam exceção em uso normal; a Cloud Function de geocodificação nunca
propaga falha de um endereço individual (`geocodeAddress` sempre resolve para
`{status: 'unavailable'}` em vez de lançar), então não há novo caminho de erro para reportar.

## Impacto offline

Nulo/positivo: a geocodificação é 100% server-side e assíncrona (job agendado), então criar/editar um
cliente offline continua funcionando exatamente como antes (Outbox/local-first intocado). A tela de
mapa em si exige rede para carregar os tiles do Google Maps (comportamento inerente de qualquer app de
mapa), mas a carteira (lista) permanece disponível offline via cache local, como já era.

## Impacto multi-tenant

Central ao escopo: o mapa não introduz nenhuma nova query — reaproveita `ListCustomerPortfolioUseCase`
(já isolado por `organizationId`/carteira/RBAC, coberto por `list_customer_portfolio_use_case_test.dart`
pré-existente). No backend, `geocodeCustomerAddressesForOrganization` só processa
`organizations/{organizationId}/customers`, com uma checagem de defesa em profundidade
(`customerDoc.data().organizationId !== organizationId` é ignorado), mesmo padrão de
`recalculate-customer-scores.ts`.

## Testes criados

- `functions/test/customers/geocoding-service.test.ts` — 11 testes (query de endereço válido/
  incompleto, fallback de país, `ZERO_RESULTS`, resposta malformada, timeout, exceção do fetcher).
- `test/core/database/app_database_task_176_customer_geocoding_migration_test.dart` — schema novo
  (fresh DB) e migração real de uma base semeada em schema 20 para 21, preservando linha existente e
  confirmando o backfill automático do `DEFAULT 'pending'` pelo próprio `ALTER TABLE`.
- `test/features/customers/domain/services/customer_map_pin_builder_test.dart` — 4 testes.
- `test/features/customers/domain/services/customer_map_clusterer_test.dart` — 5 testes, incluindo o
  cenário obrigatório de alta densidade (200 pins).
- `test/features/customers/data/mappers/customer_mapper_test.dart` — 2 novos testes (mapeamento de
  endereço geocodificado + round-trip; default pending/sem coordenadas).
- `test/features/customers/data/mappers/customer_local_mapper_test.dart` — endereço geocodificado
  round-tripando pelas colunas reais do Drift (`_fullCustomer`'s `address-2`).
- `test/features/customers/presentation/pages/customer_portfolio_page_test.dart` — 2 novos testes:
  toggle mobile (lista por padrão, mapa após tocar o ícone, aviso de "sem localização" para o cliente
  sem endereço geocodificado — evidência de paridade lista/mapa) e layout tablet lado a lado sem
  toggle.
- Isolamento multi-tenant/RBAC do mapa: deliberadamente não duplicado em um teste próprio — já coberto
  por `list_customer_portfolio_use_case_test.dart` (mesma query, reaproveitada sem alteração).

## Comandos executados

```bash
flutter pub add google_maps_flutter
dart run build_runner build   # (2x: campos da entidade, depois colunas/migração Drift)
dart format --set-exit-if-changed <arquivos desta task>
flutter analyze
flutter test test/features/customers/ test/core/database/
flutter test   # suíte completa do app
cd functions && npx tsc --noEmit
cd functions && npx eslint src/customers src/index.ts test/customers
cd functions && npx jest test/customers
cd functions && npx jest   # suíte completa do backend
```

## Resultado do formatter

`dart format --set-exit-if-changed` nos arquivos desta task — 8 de 24 arquivos precisaram de ajuste
(reformatados); após reformatar, `dart format` fica limpo (nenhuma pendência).

## Resultado do analyzer

`flutter analyze` (projeto inteiro) — 15 issues, todos pré-existentes em arquivos não tocados por esta
task (confirmado idêntico antes/depois desta task); nenhum issue novo introduzido pela TASK-176.

## Resultado dos testes

- `flutter test test/features/customers/ test/core/database/` — 171 + 50 passando (todos verdes).
- `flutter test` (suíte completa) — 3045/3047 passando; as 2 falhas
  (`test/app/bootstrap_test.dart`, `test/core/analytics/analytics_events_test.dart`) são
  pré-existentes e **não relacionadas** a esta task — confirmado rodando a mesma suíte via
  `git stash`/`git stash pop` no código antes desta task: as mesmas 2 falhas já ocorriam (limitação de
  ambiente do Firebase Crashlytics/GetIt em teste, nada tocado por TASK-176).
- `cd functions && npx tsc --noEmit` — sem erros.
- `cd functions && npx eslint src/customers src/index.ts test/customers` — sem erros.
- `cd functions && npx jest test/customers` — 47/47 passando (incluindo os 11 novos testes de
  `geocoding-service.test.ts`).
- `cd functions && npx jest` (suíte completa) — 293 passaram, 164 falharam em 26 suites, todas por
  `Could not load the default credentials` (falta de Firestore Emulator/Java no ambiente) — mesma
  limitação documentada em `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md` e nas
  tasks anteriores (TASK-173); nenhuma das suites novas desta task (`geocoding-service.test.ts`)
  depende do emulador, e nenhuma suite pré-existente passou a falhar por causa desta task.

## Decisões técnicas

- **Reaproveitar 100% da infraestrutura da carteira em lista** em vez de criar um bloc/use case/página
  novos para o mapa: o mapa lê `state.customers` do mesmo `CustomerPortfolioBloc` já provido pela
  página, e um `_CustomerMapAutoLoader` apenas dispara `CustomerPortfolioNextPageRequested` enquanto
  `hasMore` for `true` (o mapa precisa da carteira inteira filtrada de uma vez; a lista continua
  paginando por scroll normalmente). Isso torna a paridade de filtros estrutural (mesma instância de
  estado), não uma regra a manter sincronizada manualmente.
- **Geocodificação como job de backfill server-side, nunca no caminho de criação/edição do cliente**
  (a especificação aceita as duas opções — "na criação/edição... OU como job de backfill"): evita que
  o cadastro offline-first de cliente passe a depender de rede/API paga para completar.
- **Clusterização por grade lat/lng dependente do zoom, sem plugin externo de clusterização**: mantém
  o algoritmo 100% puro/testável (`CustomerMapClusterer`) e evita uma dependência adicional cuja
  compatibilidade com a versão do Flutter/`google_maps_flutter` deste projeto não estava garantida.
  Cluster marker usa cor diferenciada + `InfoWindow` com contagem e anima a câmera ao tocar (zoom-in),
  em vez de um ícone customizado desenhado via `Canvas` — trade-off consciente de polimento visual por
  simplicidade/testabilidade (ver Pendências).
- **Ação "iniciar visita" do card do pin não implementada**: a especificação da TASK-176 pede
  "ver detalhes"/"iniciar visita" no card; não existe hoje nenhum domínio de "visita" no repositório
  (isso é exatamente o escopo de TASK-177/TASK-178, ainda não implementadas) — implementar apenas
  "Ver detalhes" (reaproveitando `onCustomerSelected`, já usado pela lista) evita simular uma ação que
  ainda não tem para onde navegar.
- **Toggle lista/mapa e composição responsiva usam `AppResponsiveBuilder` (não `context.breakpoint`)**:
  inicialmente a implementação usava `context.breakpoint` (baseado em `MediaQuery`) para decidir a
  visibilidade do botão de alternância; em teste de widget (`tester.binding.setSurfaceSize`), o
  `MediaQuery` não refletiu o tamanho de superfície definido, enquanto `AppResponsiveBuilder`
  (`LayoutBuilder`) refletiu corretamente — <e é também o padrão já usado por `CustomerDetailPage`
  para as mesmas composições responsivas>. Corrigido para computar o breakpoint uma única vez
  (`AppResponsiveBuilder` ao redor de todo o corpo da página) e passá-lo tanto para as ações do
  cabeçalho quanto para o conteúdo, eliminando qualquer chance de os dois discordarem.

## Riscos conhecidos

- **Chave de API do Google Maps não configurada neste ambiente** — necessária em produção para o SDK
  realmente renderizar tiles: `AndroidManifest.xml`
  (`<meta-data android:name="com.google.android.geo.API_KEY" .../>`), iOS
  (`GMSServices.provideAPIKey(...)` no `AppDelegate.swift`) e Web (`<script>` com a chave em
  `web/index.html`). Nenhum arquivo de plataforma foi alterado nesta rodada — inserir uma chave falsa
  não teria valor funcional e arriscaria parecer uma chave real configurada. O app compila e todos os
  testes Dart passam sem essa chave (só afeta a renderização real dos tiles em runtime, mesmo
  precedente de TASK-173 com o Identity Platform do Firebase Auth).
- **Cloud Function `geocodeCustomerAddresses` requer `GOOGLE_MAPS_GEOCODING_API_KEY`** (Firebase
  Functions secret, via `defineSecret`) configurado no projeto real antes do primeiro deploy — sem
  isso, a função falhará ao chamar a API (erro tratado: cada endereço individual vira `unavailable`,
  nunca derruba a função inteira).
- **Build nativo real (Android/iOS) não validado neste ambiente** (Windows, sem Xcode/Android SDK
  completo para um build real) — `flutter analyze`/`flutter test` confirmam que o código Dart compila
  e os testes passam, mas a integração real do plugin nativo (Podfile/Gradle) deve ser validada em
  CI/dispositivo antes do release.
- **Overflow pré-existente e não relacionado descoberto durante os testes**: ao pumpar
  `CustomerPortfolioPage` em largura desktop real (≥1024, onde `AppAdminPageLayout` passa a mostrar o
  painel de filtros permanente em vez do botão), os botões "Aplicar filtros"/"Limpar" de
  `_PortfolioFilters` estouram a largura do painel (`RenderFlex overflowed by 7.5 pixels`) — bug
  pré-existente da TASK-051, nunca exercitado por nenhum teste até agora porque nenhum teste desta
  página pumpava em largura desktop. Meus testes de TASK-176 usam largura tablet (900px) para evitar
  esse caminho não relacionado; não corrigido aqui por estar fora do escopo desta task — recomendo
  abrir uma task de correção rápida para `_PortfolioFilters`.
- Clusterização usa uma aproximação de grade fixa por zoom (não a agregação hierárquica real de
  bibliotecas dedicadas de clusterização) — funciona bem para o tamanho típico de uma carteira de
  vendedor (dezenas a poucas centenas de clientes), mas não foi validada para milhares de pins
  simultâneos (cenário de BI/gestão, fora do escopo desta task, que é sobre a carteira do vendedor).

## Pendências

- Configurar a chave de API do Google Maps por ambiente (dev/staging/prod) nos arquivos de plataforma
  Android/iOS/Web e o secret `GOOGLE_MAPS_GEOCODING_API_KEY` da Cloud Function — trabalho de
  infraestrutura/ops, não de código.
- Ação "Iniciar visita" no card do pin — depende do domínio de visita ainda não implementado
  (TASK-177/TASK-178).
- Ícone customizado de cluster com o número de clientes desenhado no próprio marker (hoje usa cor +
  `InfoWindow`) — polimento visual futuro, possivelmente com `flutter-ui-design-specialist`.
- Bug de overflow pré-existente em `_PortfolioFilters` no painel de filtros desktop (ver "Riscos
  conhecidos") — recomendo uma task de correção dedicada.
- Golden tests literais (imagem) não foram criados — este repositório não tem precedente de golden
  test por página de feature (só a galeria de componentes do Design System usa
  `matchesGoldenFile`); segui o mesmo padrão já usado por `customer_detail_page_test.dart`
  (`tester.binding.setSurfaceSize` + verificação estrutural por breakpoint) para cobrir o requisito de
  "mobile tela cheia vs tablet/desktop lado a lado".

## Evidências

Ver "Comandos executados" e "Resultado dos testes" acima — saídas reais coletadas durante a execução
desta task (nenhum resultado foi presumido ou inventado).

## Commit

Local apenas (push não autorizado nesta rodada) — ver hash abaixo.

## Push

Não realizado (sem autorização nesta rodada).

## Hash do commit

Ver mensagem de commit `feat(customers): implementa mapa de clientes (TASK-176)`.

## Branch

`main`
