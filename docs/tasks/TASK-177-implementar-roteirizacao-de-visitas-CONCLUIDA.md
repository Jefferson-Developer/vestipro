# TASK-177 — Concluída (2026-09-07)

## Resumo

Implementada a roteirização de visitas (EPIC-24): a partir da carteira geocodificada de TASK-176,
o vendedor seleciona os clientes que quer visitar no dia e recebe uma rota otimizada (heurística
nearest-neighbor sobre distância haversine entre as coordenadas já geocodificadas — sem chamada a
uma Directions API externa, sem TSP complexo), exibida em lista ordenada com distância/tempo
estimados entre paradas e visualmente no mapa (marcadores numerados + polyline). O vendedor pode
reordenar manualmente qualquer parada, marcar progresso (pendente/concluída, campo que TASK-178
poderá usar para o check-in real) e abrir a navegação em Google Maps/Waze/Apple Maps a partir de uma
URL universal (`https://`) construída internamente só a partir de coordenadas já validadas — nunca de
um link recebido de fora. A rota do dia é um artefato 100% local (nova tabela Drift
`visit_routes`, upsert por `organizationId`/`salesRepId`/dia), sobrevivendo ao fechamento e
reabertura do app sem depender de nenhuma sincronização remota.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, migração de schema local, roteamento
  tipado/DI, testes) — agente principal.
- `flutter-ui-design-specialist` — não consultado como leitura integral do arquivo do agente: a
  tela reaproveita componentes já existentes do Design System (`AppCheckbox`, `AppButton`,
  `AppIconButton`, `AppBottomSheet`, `AppEmptyState`) e o mesmo padrão de composição responsiva já
  estabelecido por `CustomerPortfolioPage`/`CustomerPortfolioMapView` (TASK-176); UX mínima, sem
  decisão de design nova o suficiente para justificar consulta.

## Arquivos criados

Domínio (`lib/features/visit_routes/domain/`):
- `value_objects/visit_route_stop_status.dart` — enum `pending`/`completed`.
- `value_objects/navigation_provider.dart` — enum `googleMaps`/`waze`/`appleMaps`.
- `entities/visit_route_stop.dart` (+ `.freezed.dart`) — `VisitRouteStop` (cliente, coordenadas,
  sequência, status, distância/eta estimados da parada anterior).
- `entities/visit_route.dart` (+ `.freezed.dart`) — `VisitRoute` (rota do dia: organização, empresa,
  vendedor, data, paradas), com `VisitRoute.dateKey` (normalização para meia-noite UTC).
- `services/route_optimization_service.dart` — `RouteOptimizationService`: heurística
  nearest-neighbor pura, sem dependência de rede, com limite configurável de paradas
  (`maxStops`, default 20).
- `services/navigation_link_builder.dart` — `NavigationLinkBuilder`: constrói a `Uri` universal
  (`https://`) para Google Maps/Waze/Apple Maps a partir apenas de um `GeoCoordinates` já validado.
- `repositories/visit_route_repository.dart` — contrato `VisitRouteRepository`.
- `usecases/build_visit_route_use_case.dart` — `BuildVisitRouteUseCase`.
- `usecases/get_active_visit_route_use_case.dart` — `GetActiveVisitRouteUseCase` (retomada).
- `usecases/reorder_visit_route_stops_use_case.dart` — `ReorderVisitRouteStopsUseCase`.
- `usecases/mark_visit_route_stop_status_use_case.dart` — `MarkVisitRouteStopStatusUseCase`.

Dados (`lib/features/visit_routes/data/`):
- `dtos/visit_route_stop_dto.dart` — shape JSON de uma parada (armazenada dentro de
  `stops_json`).
- `mappers/visit_route_local_mapper.dart` — `VisitRouteLocalMapper` (entidade ↔ linha Drift).
- `repositories/drift_visit_route_repository.dart` — `DriftVisitRouteRepository`.

Apresentação (`lib/features/visit_routes/presentation/`):
- `bloc/visit_route_event.dart`, `bloc/visit_route_state.dart`, `bloc/visit_route_bloc.dart` —
  `VisitRouteBloc` (seleção de clientes, geração/reconstrução da rota, reordenação, progresso,
  retomada).
- `pages/visit_route_page.dart` — `VisitRoutePage`: alterna entre a tela de seleção de clientes
  (reaproveitando `CustomerPortfolioBloc`/`CustomerMapPinBuilder`, mesmos dados/RBAC/tenant da
  carteira) e a rota construída (lista reordenável + mapa + navegação externa).
- `widgets/visit_route_map_preview.dart` — `VisitRouteMapPreview`: marcadores numerados + polyline
  da rota já ordenada (widget próprio, não reaproveita o clusterer de TASK-176 — ver "Decisões
  técnicas").
- `widgets/visit_route_stop_tile.dart` — `VisitRouteStopTile`: card de parada (posição,
  distância/eta, progresso, ação "Navegar").
- `visit_routes.dart` — barrel da feature.

Banco local:
- `lib/core/database/tables/visit_routes_table.dart` — `VisitRoutesTable` (uma linha por
  organização/vendedor/dia; `stops_json` guarda a lista ordenada de paradas, mesmo precedente de
  `CustomersTable.tagsJson`/`customFieldsJson`).

Testes:
- `test/core/database/app_database_task_177_visit_routes_migration_test.dart` — schema novo (fresh
  DB) e migração real 21→22.
- `test/features/visit_routes/domain/services/route_optimization_service_test.dart` — 4 testes
  (ordem nearest-neighbor com origem, sem origem, seleção vazia, limite de paradas excedido).
- `test/features/visit_routes/domain/services/navigation_link_builder_test.dart` — 4 testes (URL de
  cada provedor + garantia estrutural de que só `GeoCoordinates` validado é aceito).
- `test/features/visit_routes/domain/services/route_navigation_graceful_degradation_test.dart` — 1
  teste (navegação para um destino único continua funcionando mesmo com a otimização de rota em
  lote falhando).
- `test/features/visit_routes/domain/usecases/build_visit_route_use_case_test.dart` — 3 testes.
- `test/features/visit_routes/domain/usecases/reorder_visit_route_stops_use_case_test.dart` — 2
  testes (reordenação válida + rejeição de permutação inválida).
- `test/features/visit_routes/domain/usecases/mark_visit_route_stop_status_use_case_test.dart` — 2
  testes.
- `test/features/visit_routes/domain/usecases/get_active_visit_route_use_case_test.dart` — 2
  testes (normalização de data).
- `test/features/visit_routes/data/repositories/drift_visit_route_repository_test.dart` — 2 testes,
  incluindo o obrigatório de persistência/retomada real (fecha e reabre um arquivo sqlite real,
  simulando o app sendo fechado e reaberto).

## Arquivos alterados

- `lib/features/customers/domain/value_objects/geo_coordinates.dart` — novo método
  `distanceToKm` (haversine), reaproveitado pelo `RouteOptimizationService` sem duplicar a fórmula
  em outra feature.
- `lib/features/customers/presentation/pages/customer_portfolio_page.dart` — novo callback opcional
  `onPlanVisitRouteRequested` e ação "Roteirizar visitas" no cabeçalho da carteira (mesmo padrão de
  `onImportRequested`, `null`-safe, não quebra nenhum call site existente).
- `lib/core/database/app_database.dart` (+ `.g.dart` regenerado) — import/registro de
  `VisitRoutesTable`, `schemaVersion` 21→22, migração `if (from < 22)` (criação incondicional da
  tabela nova, mesmo precedente do `from < 4` para `FavoritesTable`), métodos
  `upsertVisitRoute`/`getVisitRoute`.
- `lib/core/navigation/app_route_paths.dart` — nova rota tipada `VisitRouteRoute`.
- `lib/core/navigation/app_router.dart` — `visitRoutePageBuilder`, `GoRoute` protegido por
  `Capability.customerView` (mesmo guard central da carteira).
- `lib/app/bootstrap.dart` (+ `.config.dart` regenerado) — import da feature, wiring de
  `visitRoutePageBuilder` (`VisitRoutePage` com `VisitRouteBloc`/`CustomerPortfolioBloc` via GetIt) e
  do `onPlanVisitRouteRequested` da carteira navegando para `VisitRouteRoute`.
- `pubspec.yaml`/`pubspec.lock` — nova dependência `url_launcher: ^6.3.1` (abrir apps externos de
  navegação via link universal `https://`, sem URL scheme customizado nem declaração nativa extra).
- `test/core/database/app_database_test.dart`, `app_database_task_106_schema_test.dart`,
  `app_database_task_114_targets_migration_test.dart`, `app_database_warehouses_test.dart`,
  `app_database_task_176_customer_geocoding_migration_test.dart` — bump mecânico de
  `schemaVersion` esperado (21→22), mesmo precedente de TASK-176.
- `docs/tasks/TASKS.md` — checkbox da TASK-177 marcado e `Progresso` atualizado (176/219).

## Arquitetura utilizada

Feature-first + Clean Architecture, feature nova `visit_routes` (não dentro de `customers`, ao
contrário do mapa de TASK-176): roteirização é um domínio conceitualmente distinto de "cliente"
(rota, parada, otimização, navegação externa), mas depende de `customers` (reaproveita
`CustomerMapPin`/`GeoCoordinates`/`CustomerMapPinBuilder`/`CustomerPortfolioBloc` como entrada —
mesmo precedente de dependência cruzada já usado por `catalog_share`, que depende de
`catalog`/`customers`). Presentation (`VisitRoutePage`) → BLoC (`VisitRouteBloc`) → Use cases
(`BuildVisitRouteUseCase`/`ReorderVisitRouteStopsUseCase`/`MarkVisitRouteStopStatusUseCase`/
`GetActiveVisitRouteUseCase`) → Repository contract (`VisitRouteRepository`) → Repository impl
(`DriftVisitRouteRepository`) → Datasource (`AppDatabase`/`VisitRoutesTable` direto, sem datasource
separado — mesmo padrão enxuto de `DriftFavoriteRepository`). Serviços de domínio puros
(`RouteOptimizationService`, `NavigationLinkBuilder`) não dependem de Flutter/Firebase/Drift, 100%
unit-testáveis. UI nunca acessa Drift/Firestore diretamente — só o `VisitRouteBloc`.

## Regras de negócio implementadas

- Rota nunca inclui cliente fora da carteira/organização do vendedor autenticado: os candidatos a
  parada vêm exclusivamente de `CustomerMapPin`s já produzidos por `CustomerMapPinBuilder` a partir
  de `CustomerPortfolioBloc.state.customers` — o mesmo resultado já tenant/RBAC-filtrado de
  `ListCustomerPortfolioUseCase` (idêntico trust boundary que TASK-176 já estabeleceu para o mapa).
  Nenhuma query nova foi criada para a roteirização, logo nenhum vetor novo de vazamento existe.
- Toda URL/intent de navegação externa é construída exclusivamente a partir de um `GeoCoordinates`
  já validado (`GeoCoordinates.validated`, -90..90/-180..180) pertencente a uma parada já persistida
  na rota do próprio vendedor — `NavigationLinkBuilder.build` não tem parâmetro de string/URL livre,
  então não existe caminho de código que repasse um link recebido de fora (deep link, payload,
  texto colado) para um app de navegação externo.
- Otimização de rota é sempre uma sugestão: `ReorderVisitRouteStopsUseCase` permite reordenar
  livremente (rejeitando apenas uma permutação inválida — que adicionaria/removeria parada).
- Falha do "serviço de roteirização" nunca impede navegação básica para um cliente individual: como
  a otimização é uma heurística 100% local (sem chamada de rede), ela estruturalmente nunca fica
  "indisponível" por rede — e a navegação para um destino único (`NavigationLinkBuilder`) nunca
  depende de `RouteOptimizationService` ter sido executado com sucesso (decisão documentada abaixo).
- Limite razoável de paradas por rota: `RouteOptimizationService.maxStops` (default 20, configurável
  por instância) rejeita explicitamente uma seleção maior, evitando uma rota absurdamente longa.
- Persistência local sobrevive ao fechamento do app: `VisitRoutesTable` upserta por
  `organizationId`/`salesRepId`/dia (chave determinística), então reabrir o app no mesmo dia sempre
  resolve a mesma rota (`GetActiveVisitRouteUseCase`/`VisitRouteStarted`).
- Campo `VisitRouteStopStatus` (pendente/concluída) persiste progresso por parada, mas não
  implementa nenhuma regra de check-in (geofencing, evidência, horário) — isso é escopo de TASK-178,
  que pode reaproveitar `MarkVisitRouteStopStatusUseCase`/`VisitRouteRepository` sem alteração.

## Regras Firebase implementadas

Nenhuma. A rota de visita é um artefato 100% local/pessoal do dispositivo (ver "Decisões técnicas")
— não existe hoje nenhuma coleção Firestore para rotas de visita, nenhuma Cloud Function nova, e
nenhuma alteração em `firestore.rules`/`storage.rules`. A única leitura remota envolvida
(`CustomerPortfolioBloc`) já é a mesma leitura tenant/RBAC-escopada que TASK-051/TASK-176 já
protegem — nenhuma superfície nova de acesso a dado remoto foi criada.

## Analytics implementado

Nenhum evento novo nesta rodada. Mesma decisão consciente de TASK-176: nem a carteira em lista
(TASK-051) nem o mapa (TASK-176) têm instrumentação de analytics hoje — instrumentar só a
roteirização introduziria uma inconsistência (uma tela do fluxo instrumentada, as irmãs não). Ver
"Pendências".

## Crashlytics implementado

Nenhuma mudança dedicada: `RouteOptimizationService`/`NavigationLinkBuilder` são funções puras que
nunca lançam exceção em uso normal (retornam `AppFailure` tipado, nunca `throw`); os use cases só
propagam falhas já tratadas do repositório (`UnexpectedFailure` capturando qualquer exceção
inesperada do Drift). Nenhum novo caminho de erro não tratado foi introduzido.

## Impacto offline

Positivo por definição: a roteirização é 100% local (Drift), nunca depende de rede para calcular a
ordem das paradas, persistir a rota do dia ou reordenar manualmente. A única dependência de rede é
inerente ao próprio mapa (tiles do Google Maps, mesma limitação já documentada por TASK-176) e à
abertura efetiva do app externo de navegação (que também é uma limitação inerente de qualquer app de
mapa, não desta feature). Fechar e reabrir o app nunca perde a rota do dia nem o progresso já
marcado.

## Impacto multi-tenant

Central ao escopo: nenhuma query nova foi criada — a lista de clientes elegíveis para rota vem
exclusivamente do mesmo `CustomerPortfolioBloc`/`ListCustomerPortfolioUseCase` já isolado por
`organizationId`/carteira/RBAC (coberto por `list_customer_portfolio_use_case_test.dart`
pré-existente). A persistência local (`VisitRoutesTable`) é sempre escopada por
`organizationId`/`companyId`/`salesRepId` e consultada só por esses três campos
(`AppDatabase.getVisitRoute`).

## Testes criados

Ver "Arquivos criados" acima — 20 testes novos cobrindo todos os 5 cenários obrigatórios da task:
cálculo de rota com N clientes, reordenação manual, geração de URL só com coordenadas validadas,
degradação graciosa da navegação de destino único e persistência/retomada real via arquivo sqlite.

## Comandos executados

```bash
flutter pub get
dart run build_runner build   # (2x: 1ª rodada acusou RouteOptimizationService sem @injectable)
flutter analyze
dart format --set-exit-if-changed <arquivos desta task>
flutter test test/features/visit_routes test/core/database/app_database_task_177_visit_routes_migration_test.dart
flutter test test/core/database
flutter test test/features/customers
flutter test   # suíte completa do app
```

## Resultado do formatter

`dart format --set-exit-if-changed` nos arquivos desta task — 14 de 44 precisaram de ajuste na
primeira passada (reformatados); após reformatar, roda limpo (0 changed).

## Resultado do analyzer

`flutter analyze` (projeto inteiro) — 15 issues, todos pré-existentes em arquivos não tocados por
esta task (idênticos antes/depois, mesma contagem/lista já documentada por TASK-176); nenhum issue
novo introduzido pela TASK-177.

## Resultado dos testes

- `flutter test test/features/visit_routes test/core/database/app_database_task_177_visit_routes_migration_test.dart`
  — 20/20 passando.
- `flutter test test/core/database` — 52/52 passando (inclui a migração 21→22 e o bump mecânico de
  `schemaVersion` nos testes pré-existentes).
- `flutter test test/features/customers` — 121/121 passando (inclui o novo botão "Roteirizar
  visitas" na carteira, sem quebrar nenhum teste existente da página).
- `flutter test` (suíte completa) — 3069/3071 passando; as 2 falhas
  (`test/app/bootstrap_test.dart`, `test/core/analytics/analytics_events_test.dart`) são
  pré-existentes e **não relacionadas** a esta task — confirmado pela mensagem de erro real
  (`GetIt: Object/factory with type PushDeviceMapper is not registered`, um gap de DI de
  notificações push já presente antes desta rodada e listado pelo próprio `build_runner` como
  aviso pré-existente) e pelo precedente idêntico já documentado em TASK-176 (mesmas 2 falhas, mesmo
  motivo).

## Decisões técnicas

- **Heurística nearest-neighbor pura (haversine), sem chamada a uma Directions API externa**: a
  especificação sugere "usando serviço de roteirização/distância (ex.: Directions API...)", mas
  também aceita explicitamente "não precisa ser um solver TSP complexo". Optei por manter a
  roteirização 100% local/offline (sem nenhuma dependência de rede, API key ou custo por chamada) —
  isso torna a exigência de "degradação graciosa quando o serviço de roteirização está
  indisponível" estruturalmente satisfeita (nunca há uma chamada de rede para falhar) em vez de
  precisar simular/tratar uma falha de infraestrutura externa que este ambiente não tem como
  provisionar (mesmo precedente de TASK-176 evitando uma chave de API falsa). Trade-off consciente:
  distância/tempo são estimativas em linha reta com velocidade média assumida (30 km/h), não a
  distância/tempo real de condução.
- **Sem dependência de geolocalização do dispositivo (`geolocator`) nesta rodada**: a especificação
  pede rota "a partir da localização atual do vendedor". Adicionar um novo plugin com permissão
  nativa (`ACCESS_FINE_LOCATION`/`NSLocationWhenInUseUsageDescription`) que este ambiente não pode
  validar em dispositivo real (sem Android SDK/Xcode completos, mesmo gap de ambiente já documentado
  por TASK-176) seria expandir escopo sem conseguir validar a permissão de fato. Em vez disso,
  `RouteOptimizationService.optimize` aceita um `origin` opcional (`GeoCoordinates?`): quando
  ausente, a rota simplesmente começa pelo primeiro cliente selecionado (ordem de seleção) e
  encadeia nearest-neighbor a partir dali — mesmo algoritmo, grau de liberdade a menos. Plugar uma
  localização real do dispositivo no futuro é só passar um `origin` não nulo ao
  `BuildVisitRouteUseCase`, sem tocar no algoritmo.
- **`url_launcher` com links universais `https://` (não URL scheme customizado)**: evita precisar
  declarar `<queries>` (Android 11+) ou `LSApplicationQueriesSchemes` (iOS) para `canLaunchUrl`
  funcionar — um link `https://www.google.com/maps/...`/`https://waze.com/ul?...`/
  `https://maps.apple.com/?...` abre o app nativo quando instalado ou cai para o navegador,
  preservando Android/iOS/Web sem alterar nenhum arquivo de plataforma.
- **Rota do dia é local-only, sem sincronização remota**: a especificação só pede persistência que
  sobreviva ao fechamento do app, não compartilhamento entre dispositivos — uma rota de visita é um
  plano pessoal e efêmero (válido para aquele dia), não um registro de negócio que outro usuário
  precisa enxergar. `VisitRoutesTable` não tem `syncStatus`/Outbox (ao contrário de `FavoritesTable`,
  que sincroniza porque um favorito é um dado do usuário compartilhável entre seus próprios
  dispositivos). Se um caso de uso futuro exigir ver a rota de um vendedor a partir do backoffice,
  isso é uma nova task de sincronização, não uma extensão trivial desta.
- **`stops_json` como coluna única (JSON) em vez de uma segunda tabela `visit_route_stops`**: uma
  rota é sempre lida/escrita por inteiro (nunca uma parada isolada de outra rota), mesmo precedente
  de `CustomersTable.tagsJson`/`customFieldsJson` já estabelecido neste código-base para listas
  embutidas que não precisam de query relacional própria.
- **`VisitRouteMapPreview` é um widget próprio, não reaproveita `CustomerPortfolioMapView`/
  `CustomerMapClusterer` de TASK-176**: aquele componente existe para *clusterizar* uma carteira
  não ordenada; esta tela mostra uma sequência já pequena e já ordenada — agrupar paradas em
  cluster esconderia exatamente a ordem que a tela existe para comunicar.
- **`VisitRoutePage` como uma única página com dois estados (seleção/rota construída)**, em vez de
  duas páginas/rotas separadas: reduz a superfície de roteamento (uma `GoRoute`, um builder em
  `bootstrap.dart`) mantendo os dois passos do fluxo (seleção → rota) claramente separados por
  composição (`_SelectionView`/`_RouteView`) dentro do mesmo `VisitRouteBloc`.
- **Reaproveitamento total da infraestrutura de carteira (TASK-051/TASK-176)** para a seleção de
  clientes: `VisitRoutePage` provê seu próprio `CustomerPortfolioBloc` e converte
  `state.customers` em `CustomerMapPin`s com o mesmíssimo `CustomerMapPinBuilder` de TASK-176 —
  zero duplicação de query/filtro/RBAC.

## Riscos conhecidos

- **Distância/tempo são estimativas em linha reta**, não a distância/tempo real de condução (ver
  "Decisões técnicas") — aceitável para o tamanho típico de uma rota diária de vendedor, mas não
  deve ser apresentado ao usuário como "tempo exato de chegada".
- **Sem localização real do dispositivo (`geolocator`) nesta rodada** — a rota começa pelo primeiro
  cliente selecionado em vez da posição atual real do vendedor quando nenhum `origin` é passado (ver
  "Decisões técnicas"); plugar geolocalização real é trabalho futuro de infraestrutura/permissão
  nativa, não uma mudança de algoritmo.
- **Build nativo real (Android/iOS) do `url_launcher` não validado neste ambiente** (Windows, sem
  Xcode/Android SDK completos) — mesmo precedente de risco já aceito por TASK-176 para
  `google_maps_flutter`; `flutter analyze`/`flutter test` confirmam que o código Dart compila e os
  testes passam, mas a abertura real de um app de navegação externo em dispositivo deve ser validada
  em CI/dispositivo antes do release.
- **Sem golden test dedicado para `VisitRoutePage`** — mesmo precedente/limitação já documentado por
  TASK-176 (este repositório não tem golden test por página de feature).

## Pendências

- Plugar `geolocator` (localização real do dispositivo) como `origin` de
  `BuildVisitRouteUseCase` quando a infraestrutura/permissão nativa for decidida — trabalho de
  ambiente/ops + decisão de produto, não um gap de arquitetura (a assinatura já aceita `origin`
  opcional).
- Ícone numerado customizado no marcador do mapa (hoje usa `InfoWindow` com o número no título, não
  desenhado no próprio marker) — mesmo tipo de polimento visual futuro já registrado por TASK-176,
  possivelmente com `flutter-ui-design-specialist`.
- Instrumentação de analytics da roteirização — pendente junto com a instrumentação da carteira em
  lista/mapa (TASK-051/TASK-176), para não introduzir uma tela instrumentada isolada.
- TASK-178 (check-in de visita) deverá decidir se `VisitRouteStopStatus.completed` é suficiente ou
  se precisa de um terceiro estado (ex.: "pulado") — o enum atual foi deliberadamente mantido mínimo
  (pendente/concluída) para não antecipar uma regra de negócio que ainda não foi especificada.

## Evidências

Ver "Comandos executados" e "Resultado dos testes" acima — saídas reais coletadas durante a execução
desta task (nenhum resultado foi presumido ou inventado).

## Commit

Local apenas (push não autorizado nesta rodada) — ver hash abaixo.

## Push

Não realizado (sem autorização nesta rodada).

## Hash do commit

Ver mensagem de commit `feat(customers): implementa roteirizacao de visitas (TASK-177)`.

## Branch

`main`
