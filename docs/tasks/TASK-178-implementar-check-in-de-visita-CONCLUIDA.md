# TASK-178 — Concluída (2026-09-07)

## Resumo

Implementado o check-in de visita (EPIC-24): o vendedor registra a chegada a um cliente — a partir
da rota do dia (TASK-177) — com uma observação rápida opcional e, mediante consentimento explícito
por ação, com a localização atual do dispositivo. O check-in sempre gera uma atividade de tipo
"visita" na timeline CRM do cliente (reaproveitando `RegisterCrmActivityUseCase`/timeline de
TASK-059, sem alterar essa entidade), preserva o instante local exato do check-in mesmo que a
sincronização ocorra depois, funciona totalmente offline (mesmo armazenamento local imediato já
usado por `SharedPreferencesCrmActivityRepository`) e, quando o cliente é uma parada pendente da
rota do dia, marca essa parada como concluída automaticamente. Ausência ou negação de permissão de
localização nunca bloqueia o check-in — é sempre uma evidência complementar.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, dependência nativa de geolocalização, DI,
  testes) — agente principal.
- `flutter-ui-design-specialist` — não consultado como leitura integral do arquivo do agente: o
  fluxo de check-in é um bottom sheet mínimo (observação + checkbox) reaproveitando componentes já
  existentes do Design System (`AppBottomSheet`, `AppTextField`, `AppCheckbox`, `AppButton`,
  `AppSnackbar`), mesmo precedente de TASK-177 de não escalar para consulta de design quando não há
  decisão de UX nova o suficiente.

## Arquivos criados

Nova feature `visit_checkins` (`lib/features/visit_checkins/`):
- `domain/value_objects/visit_check_in_location_status.dart` — enum `VisitCheckInLocationStatus`
  (`skippedByUser`/`captured`/`permissionDenied`/`permissionDeniedForever`/`serviceDisabled`/
  `unavailable`), todos outcomes válidos e não bloqueantes.
- `domain/entities/visit_check_in_location_capture.dart` — `VisitCheckInLocationCapture`
  (status + coordenadas opcionais + distância complementar até o cliente).
- `domain/entities/visit_check_in_result.dart` — `VisitCheckInResult` (atividade CRM + captura de
  localização do check-in).
- `domain/services/visit_check_in_location_service.dart` — contrato `VisitCheckInLocationService`
  (gateway de geolocalização do dispositivo).
- `domain/usecases/check_in_visit_use_case.dart` — `CheckInVisitUseCase`: orquestra evidência (CRM)
  + localização opcional; deliberadamente sem dependência de `visit_routes` (ver "Decisões
  técnicas").
- `data/services/geolocator_visit_check_in_location_service.dart` —
  `GeolocatorVisitCheckInLocationService` (`package:geolocator`): serviço de localização
  desabilitado, permissão negada/negada para sempre e timeout/erro são todos `AppSuccess` com o
  status correspondente — nunca um `throw`/`AppFailure`.
- `presentation/widgets/visit_check_in_sheet.dart` — `VisitCheckInSheet`: bottom sheet com
  observação opcional + checkbox "Compartilhar minha localização neste check-in" (opt-in explícito
  por ação, nunca uma preferência persistida).
- `visit_checkins.dart` — barrel da feature.

Testes:
- `test/features/visit_checkins/domain/usecases/check_in_visit_use_case_test.dart` — 6 testes:
  localização concedida, localização negada (check-in continua), nenhuma captura quando o vendedor
  não optou por compartilhar, vinculação correta à atividade CRM do cliente, preservação do
  timestamp local do check-in e propagação de falha de registro sem confundir com problema de
  localização.
- `test/features/visit_routes/presentation/bloc/visit_route_bloc_check_in_test.dart` — 4 testes do
  novo evento `VisitRouteCheckInRequested`: sucesso marca a parada concluída + loga
  `crm_activity_created`; falha de evidência não altera a parada; nenhuma ação sem rota ativa;
  nenhuma ação quando o cliente não é parada da rota.

## Arquivos alterados

- `pubspec.yaml`/`pubspec.lock` — nova dependência `geolocator: ^14.0.3` (única dependência nativa
  desta task; federada, com implementações Android/iOS/Web/Windows/Linux resolvidas
  automaticamente).
- `android/app/src/main/AndroidManifest.xml` — `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`
  (sem `ACCESS_BACKGROUND_LOCATION`: este app nunca captura localização fora do momento do
  check-in).
- `ios/Runner/Info.plist` — `NSLocationWhenInUseUsageDescription` (só "When In Use", mesma razão
  acima).
- `lib/features/visit_routes/domain/value_objects/visit_route_stop_status.dart` — nenhuma mudança
  de código: após ler o enum e o relatório da TASK-177, decidi que `pending`/`completed` já bastam
  para o escopo desta task (ver "Decisões técnicas" — nenhum terceiro estado como "pulado" foi
  pedido pela TASK-178).
- `lib/features/visit_routes/presentation/widgets/visit_route_stop_tile.dart` — troca do único
  callback `onToggleStatus` por dois: `onCheckIn` (parada pendente → dispara o fluxo real de
  check-in) e `onUndoCheckIn` (parada concluída → reverte para pendente, nunca gera check-in).
- `lib/features/visit_routes/presentation/bloc/visit_route_event.dart` — novo evento
  `VisitRouteCheckInRequested` (customerId, note, shareLocation); doc do `VisitRouteStopStatusToggled`
  atualizada para deixar explícito que ele só desfaz, nunca completa.
- `lib/features/visit_routes/presentation/bloc/visit_route_state.dart` — novo enum
  `VisitRouteCheckInStatus` (idle/submitting/success/failure) e campos `checkInStatus`,
  `lastCheckIn` (`VisitCheckInResult?`), `checkInFailure`, independentes do `VisitRouteStatus` que já
  existia (carregamento/construção da rota).
- `lib/features/visit_routes/presentation/bloc/visit_route_bloc.dart` — nova dependência
  `CheckInVisitUseCase` + `AnalyticsService`; novo handler `_onCheckInRequested` (chama o check-in
  e, só em caso de sucesso, marca a parada concluída com o `MarkVisitRouteStopStatusUseCase` já
  existente); `_onStopStatusToggled` agora só reverte parada já concluída.
- `lib/features/visit_routes/presentation/pages/visit_route_page.dart` — abre `VisitCheckInSheet`
  antes de disparar o check-in; `BlocListener` novo mostra `AppSnackbar` de sucesso/erro do
  check-in; `_RouteView`/`VisitRouteStopTile` recebem os dois callbacks novos.
- `docs/tasks/TASKS.md` — checkbox da TASK-178 marcado e `Progresso` atualizado (177/219).

## Arquitetura utilizada

Feature-first + Clean Architecture, nova feature `visit_checkins`. Grafo de dependência entre
features deliberadamente mantido acíclico: `visit_checkins` depende de `crm` (evidência) e
`customers` (`GeoCoordinates`) — nunca de `visit_routes`; `visit_routes` é quem depende de
`visit_checkins` (seu `VisitRouteBloc` chama `CheckInVisitUseCase` e, só depois, usa seu próprio
`MarkVisitRouteStopStatusUseCase` para marcar a parada). Isso evita uma dependência circular entre
as duas features — ver "Decisões técnicas" para o raciocínio completo. Presentation
(`VisitCheckInSheet`) → BLoC (`VisitRouteBloc`, na feature consumidora) → Use case
(`CheckInVisitUseCase`) → Repository contract (`CrmActivityRepository`,
`VisitCheckInLocationService`) → Repository/serviço impl (`SharedPreferencesCrmActivityRepository`
já existente, `GeolocatorVisitCheckInLocationService` novo). Domain 100% livre de
Flutter/Firebase/geolocator — só `data/services/geolocator_visit_check_in_location_service.dart`
importa o plugin. UI nunca acessa SharedPreferences/Drift diretamente — só o `VisitRouteBloc`.

## Regras de negócio implementadas

- Consentimento de localização é sempre explícito e por ação: `VisitCheckInSheet` só mostra um
  checkbox desmarcado por padrão; o serviço de geolocalização só é chamado quando
  `shareLocation == true` naquele check-in específico (nunca uma preferência persistida entre
  check-ins).
- Ausência/negação de permissão nunca bloqueia o check-in: todo outcome de
  `GeolocatorVisitCheckInLocationService` (serviço desabilitado, permissão negada/negada para
  sempre, timeout/erro inesperado) é um `AppSuccess` com o status correspondente, nunca um
  `AppFailure` — estruturalmente impossível a localização derrubar o check-in.
- Distância até o endereço cadastrado do cliente é sempre complementar: calculada só quando há
  coordenadas capturadas e do cliente (`VisitCheckInLocationCapture.withDistanceTo`,
  reaproveitando `GeoCoordinates.distanceToKm` de TASK-177 sem duplicar a fórmula), nunca usada para
  bloquear ou validar o check-in.
- Check-in sempre gera uma atividade CRM de tipo "visita" vinculada ao cliente
  (`RegisterCrmActivityUseCase`, sem nenhuma regra nova nessa entidade) — reaproveita a mesma
  timeline imutável de TASK-059.
- Timestamp local do check-in é preservado como `CrmActivity.occurredAt` explicitamente passado
  pelo `CheckInVisitUseCase` (não o momento em que o registro é eventualmente persistido/sincronizado)
  — nunca sobrescrito depois.
- Parada da rota do dia só é marcada como concluída depois que a evidência (atividade CRM) já foi
  registrada com sucesso — uma falha ao marcar a parada não desfaz nem esconde o check-in já
  registrado (`VisitRouteBloc._markStopVisited`, ambos os ramos preservam `checkInStatus: success`).
- Reverter uma parada concluída (`VisitRouteStopStatusToggled`) nunca gera check-in nem apaga a
  atividade CRM já criada — apenas corrige o progresso visual da rota.

## Regras Firebase implementadas

Nenhuma. O check-in reaproveita integralmente o caminho de escrita já existente de `CrmActivity`
(`SharedPreferencesCrmActivityRepository`, local-only até que uma task futura o conecte ao
Outbox/Firestore — ver "Riscos conhecidos"/"Pendências") e a rota do dia continua sendo um artefato
100% local de TASK-177. Nenhuma coleção Firestore, Cloud Function ou regra de
`firestore.rules`/`storage.rules` foi criada ou alterada.

## Analytics implementado

Reaproveitado o evento já existente `AnalyticsEvents.crmActivityCreated` (`crm_activity_created`),
o mesmo que `CustomerDetailBloc` já loga para qualquer outra atividade CRM registrada manualmente —
um check-in de visita *é* uma atividade CRM, só criada por um fluxo diferente, então nenhum nome de
evento novo foi introduzido (evita reabrir `test/core/analytics/analytics_events_test.dart`, cuja
lista de taxonomia é fixa). Parâmetros: `organization_id`, `customer_id`, `activity_id`,
`activity_type`, `sync_status`, `location_status` (código estável do
`VisitCheckInLocationStatus`, nunca a coordenada bruta). Disparado só após sucesso do registro da
evidência, antes de tentar marcar a parada da rota.

## Crashlytics implementado

Nenhuma mudança dedicada: `CheckInVisitUseCase`/`GeolocatorVisitCheckInLocationService` nunca
lançam exceção em uso normal (a segunda captura qualquer erro de plataforma internamente e devolve
um status válido, nunca um `throw`); os use cases só propagam falhas já tratadas dos repositórios
existentes.

## Impacto offline

Positivo: o check-in é salvo localmente de forma imediata pelo mesmo caminho que qualquer atividade
CRM já usa (`SharedPreferencesCrmActivityRepository`), sobrevivendo ao fechamento do app com
`syncStatus: pending` (comprovado em teste). A geolocalização, quando solicitada, é uma chamada de
plataforma local (GPS/rede do próprio aparelho) — não depende de conectividade para funcionar. A
marcação da parada da rota também é 100% local (`VisitRoutesTable`, TASK-177). **Limitação
conhecida, não introduzida por esta task**: `CrmActivity`/`OutboxEntityType.crmActivity` ainda não
está de fato conectado ao Outbox/sincronização remota (o próprio `SyncPushHandler` já documenta essa
lacuna como pendente até para `order`/`orderItem`/`customer`) — o check-in fica "offline-first"
(gravação local imediata, nunca perde dado), mas a sincronização com o backend quando a
conectividade retornar é trabalho de uma task de sincronização futura, não desta.

## Impacto multi-tenant

O check-in nunca introduz uma query nova: `organizationId`/`companyId` vêm sempre do
`VisitRouteState` já carregado (por sua vez originado do `VisitRouteStarted` disparado com o
tenant/vendedor autenticado) e são repassados sem alteração para `RegisterCrmActivityUseCase`
(mesmo contrato/isolamento de TASK-059) e para a busca da rota ativa
(`GetActiveVisitRouteUseCase`, já escopada por TASK-177). Nenhum novo vetor de vazamento entre
organizações foi criado.

## Testes criados

Ver "Arquivos criados" acima — 10 testes novos cobrindo os 5 cenários obrigatórios da task:
check-in com localização concedida/negada (ambos válidos), check-in totalmente offline (gravação
local imediata com `syncStatus: pending`, sincronização remota é lacuna pré-existente documentada),
vinculação correta à timeline CRM do cliente, atualização do status da parada da rota do dia e
preservação do timestamp local mesmo com "sincronização" tardia.

## Comandos executados

```bash
flutter pub add geolocator
dart run build_runner build          # 2x (1ª: CheckInVisitUseCase/serviço; 2ª: AnalyticsService no VisitRouteBloc)
dart format --set-exit-if-changed lib/features/visit_checkins lib/features/visit_routes \
  test/features/visit_checkins test/features/visit_routes
flutter analyze
flutter test test/features/visit_checkins/domain/usecases/check_in_visit_use_case_test.dart
flutter test test/features/visit_routes/presentation/bloc/visit_route_bloc_check_in_test.dart
flutter test test/features/visit_routes test/features/visit_checkins test/features/crm test/features/customers
flutter test   # suíte completa do app
```

## Resultado do formatter

`dart format --set-exit-if-changed` nos arquivos desta task — precisou de uma reformatação
automática na primeira passada (`dart format` sem `--set-exit-if-changed`, 4 de 41 arquivos
ajustados); após reformatar, roda limpo (0 changed).

## Resultado do analyzer

`flutter analyze` (projeto inteiro) — 15 issues, todos pré-existentes em arquivos não tocados por
esta task (idêntica lista/contagem já documentada por TASK-176/TASK-177); nenhum issue novo
introduzido por esta task.

## Resultado dos testes

- `test/features/visit_checkins/domain/usecases/check_in_visit_use_case_test.dart` — 6/6 passando.
- `test/features/visit_routes/presentation/bloc/visit_route_bloc_check_in_test.dart` — 4/4
  passando.
- `flutter test test/features/visit_routes test/features/visit_checkins test/features/crm
  test/features/customers` — 178/178 passando.
- `flutter test` (suíte completa) — 3079/3081 passando; as 2 falhas
  (`test/app/bootstrap_test.dart`, `test/core/analytics/analytics_events_test.dart`) são
  pré-existentes e **não relacionadas** a esta task — confirmado pela mensagem de erro real
  (`GetIt: Object/factory with type PushDeviceMapper is not registered`, gap de DI de notificações
  push já presente antes desta rodada) e pela lista de taxonomia de analytics já desatualizada
  antes desta task — mesmo precedente/contagem documentado em TASK-176/TASK-177.

## Decisões técnicas

- **`CheckInVisitUseCase` (em `visit_checkins`) não depende de `visit_routes`, ao contrário do
  desenho inicial**: a primeira versão fazia o use case buscar a rota ativa e marcar a parada
  internamente, o que criaria uma dependência circular entre features (`visit_checkins` → 
  `visit_routes` para marcar a parada, `visit_routes` → `visit_checkins` para o check-in em si).
  Resolvido invertendo o controle: `CheckInVisitUseCase` só cuida de evidência + localização; quem
  já tem a rota ativa em mãos e sabe marcar uma parada (`VisitRouteBloc`, que já injeta
  `MarkVisitRouteStopStatusUseCase` desde TASK-177) faz isso *depois* que o check-in é bem-sucedido.
  Grafo de dependências entre features permanece acíclico, e nenhuma leitura duplicada da rota
  ativa acontece (o bloc já tem `state.route` carregado).
- **Nenhum terceiro estado adicionado a `VisitRouteStopStatus`**: a TASK-178 só pede "marcar a
  parada como visitada após o check-in" — nada sobre pular/cancelar uma parada. Mantive
  `pending`/`completed` como estão (decisão que a própria TASK-177 deixou em aberto para esta
  rodada decidir).
- **Sem check-out/horário de saída**: a especificação de TASK-178 (`docs/tasks/TASK-178-*.md`) só
  descreve check-in (chegada) — não pede check-out. Implementar um fluxo de saída não solicitado
  expandiria escopo sem um critério de aceite que o exija.
- **Evidência de localização embutida na `description` da atividade CRM (texto), não um campo
  estruturado novo em `CrmActivity`**: adicionar `latitude`/`longitude`/`distanceToCustomerKm`
  como campos de primeira classe exigiria alterar uma entidade/mapper/repositório já estável e
  usado por várias outras tasks (TASK-059 e sucessoras), fora do escopo desta rodada. A
  especificação já trata a localização como "informação complementar", então uma nota textual
  (`[Localização: lat, lng · ~X km do endereço cadastrado do cliente]`) é suficiente como evidência
  auditável sem tocar num contrato compartilhado. Documentado como possível evolução futura.
  Coordenadas nunca vão para analytics — só para a `description` da própria atividade (dado do
  próprio tenant, não telemetria).
- **`VisitCheckInSheet`/entrada de check-in disponível apenas a partir da rota do dia
  (`VisitRoutePage`/`VisitRouteStopTile`)**, não também da carteira ou da ficha do cliente
  (TASK-178 lista as três como alternativas — "a partir da rota do dia... da carteira ou da ficha
  do cliente"): a rota do dia é o único ponto de entrada onde os dois critérios de aceite
  (evidência CRM + atualização do progresso da rota) são demonstráveis end-to-end sem trabalho
  adicional de propagar `companyId` para `CustomerDetailBloc` (que hoje não carrega esse campo).
  `CheckInVisitUseCase` já é reutilizável por qualquer entry point futuro (não conhece
  `visit_routes`), então plugar um botão de check-in na ficha do cliente ou na carteira é trabalho
  aditivo, não uma reescrita — ver "Pendências".
- **`geolocator` como única dependência nativa nova**, com permissão só "When In Use"
  (`NSLocationWhenInUseUsageDescription`)/`ACCESS_FINE_LOCATION`+`ACCESS_COARSE_LOCATION` (sem
  `ACCESS_BACKGROUND_LOCATION`): a especificação exige captura só no momento da ação, nunca em
  segundo plano — declarar permissão de background seria pedir mais acesso do que o app usa.
- **Todo outcome de `GeolocatorVisitCheckInLocationService` é `AppSuccess`, nunca `AppFailure`**:
  modela explicitamente que "sem localização" nunca é um erro do ponto de vista do check-in —
  `CheckInVisitUseCase` não precisa de nenhum tratamento especial de falha de localização além de
  ler o `status` retornado.
- **Reaproveitamento do evento de analytics `crmActivityCreated`** em vez de um evento novo
  (`visit_check_in_completed` ou similar): evita duplicar semântica (um check-in é uma atividade
  CRM) e evita precisar atualizar a lista fixa de taxonomia em
  `test/core/analytics/analytics_events_test.dart`, que várias tasks anteriores já mantêm estável.

## Riscos conhecidos

- **Permissão de localização nativa (`geolocator`) não validada em dispositivo real neste
  ambiente** (Windows, sem Android SDK/Xcode completos) — mesmo precedente de risco já aceito por
  TASK-176 (`google_maps_flutter`) e TASK-177 (`url_launcher`). `flutter analyze`/`flutter test`
  confirmam que o código Dart compila e os testes (com fakes) passam, mas o diálogo real de
  permissão do SO, o comportamento de "negado para sempre" e a leitura real do GPS devem ser
  validados em dispositivo/CI antes do release.
- **`CrmActivity` ainda não está conectado ao Outbox real** (ver "Impacto offline") — o check-in
  offline funciona (gravação local imediata, nunca perde dado), mas a sincronização com o backend
  quando a conectividade retornar depende de uma task futura de sincronização que esta rodada não
  tenta resolver (gap pré-existente, não introduzido aqui).
- **Localização embutida como texto na `description`** (ver "Decisões técnicas") não é
  estruturadamente consultável (não dá para filtrar/relatar "check-ins com distância > X km" sem
  parsear texto) — aceitável para o escopo desta task (evidência complementar), mas uma evolução
  futura de BI sobre check-ins provavelmente pediria campos estruturados.

## Pendências

- Adicionar a ação de check-in também na carteira e na ficha do cliente (`CustomerDetailBloc`
  precisaria passar a carregar `companyId` para o `CheckInVisitUseCase` conseguir localizar a rota
  ativa daquele entry point) — aditivo, não bloqueante.
- Conectar `CrmActivity`/`OutboxEntityType.crmActivity` ao Outbox/sincronização remota real —
  gap pré-existente do codebase, não desta task.
- Validar o fluxo real de permissão de localização (concedida/negada/negada para sempre/serviço
  desabilitado) em dispositivo Android/iOS real — ambiente atual não tem toolchain completa.
- Se o produto exigir consultar/filtrar check-ins por distância no futuro, promover
  `latitude`/`longitude`/`distanceToCustomerKm` a campos estruturados de `CrmActivity` (hoje só na
  `description`).

## Evidências

Ver "Comandos executados" e "Resultado dos testes" acima — saídas reais coletadas durante a
execução desta task (nenhum resultado foi presumido ou inventado).

## Commit

Local apenas (push não autorizado nesta rodada) — ver hash abaixo.

## Push

Não realizado (sem autorização nesta rodada).

## Hash do commit

Ver mensagem de commit `feat(visit-routes): implementa check-in de visita (TASK-178)`.

## Branch

`main`
