# TASK-151 — Concluída (2026-09-05)

## Resumo

Implementada a central de notificações internas do VestiPro (EPIC-19): listagem paginada, lidas/não
lidas, filtro por categoria (CRM/Comercial/Sistema), contador de não lidas sempre correto, "marcar
como lida"/"marcar todas como lidas", deep link tipado (`go_router`) ao tocar em uma notificação, e
acesso offline às últimas notificações sincronizadas. A tela é a base que TASK-152 (notificações de
CRM) e TASK-153 (notificações comerciais) vão alimentar.

A TASK-150 (Firebase Cloud Messaging, concluída no commit anterior) já havia criado uma "caixa de
entrada" local (`AppNotification`, `NotificationInboxRepository`, implementação apenas em
`SharedPreferences`) usada por `ProcessTargetAlertUseCase` (TASK-149) para enfileirar o alerta de
meta, e um `PushNotificationRouter` pronto mas nunca consumido por UI nenhuma. Esta task modela o
Firestore (`organizations/{organizationId}/notifications/{notificationId}`, conforme `tasks.md`),
substitui o repositório apenas-local por um híbrido (Firestore como fonte de verdade + cache local
para offline) e constrói toda a tela/BLoC/componentes de Design System em cima disso. Nenhuma central
de notificações (ou qualquer coisa equivalente) existia na UI antes desta task — apenas a
infraestrutura de dados citada acima.

## Agentes utilizados

- `flutter-senior-architect` (domínio, dados, BLoC, rotas, DI, Firestore Rules/índices)
- `flutter-ui-design-specialist` (tela, componentes de Design System, estados vazio/erro/carregando)

## Arquivos criados

Domínio (`lib/core/notifications/domain/`):

- `usecases/list_notifications_for_user_use_case.dart`
- `usecases/mark_notification_as_read_use_case.dart`
- `usecases/mark_all_notifications_as_read_use_case.dart`

Dados (`lib/core/notifications/data/`):

- `dtos/notification_dto.dart`
- `mappers/notification_mapper.dart`
- `datasources/notification_data_source.dart` (contrato)
- `datasources/firestore_notification_data_source.dart` (implementação real)
- `local/notification_inbox_local_cache.dart` (cache local — substitui o antigo repositório
  `SharedPreferences`, ver "Arquivos removidos")
- `repositories/notification_inbox_repository_impl.dart` (implementação híbrida Firestore + cache
  local; nova `@LazySingleton(as: NotificationInboxRepository)`)

Apresentação (`lib/core/notifications/presentation/`):

- `bloc/notification_center_event.dart`
- `bloc/notification_center_state.dart`
- `bloc/notification_center_bloc.dart`
- `pages/notification_center_page.dart`

Design System (`lib/core/design_system/components/notifications/`):

- `app_notification_list_tile.dart` — item de notificação (ícone por categoria, indicador de não
  lida nunca só por cor — bolinha + negrito).
- `app_notification_bell_button.dart` — botão de sino com badge de contador (reaproveita
  `AppIconButton` + `Badge` do Material, conforme a task pede "reaproveitar componentes existentes,
  não criar componente isolado").

Documentação:

- `docs/tasks/TASK-151-implementar-central-de-notificacoes-CONCLUIDA.md` (este arquivo)

## Arquivos removidos

- `lib/core/notifications/data/repositories/shared_preferences_notification_inbox_repository.dart` —
  substituído por `local/notification_inbox_local_cache.dart` (mesma lógica de serialização, agora um
  colaborador interno do repositório híbrido) + `repositories/notification_inbox_repository_impl.dart`
  (novo dono do binding `@LazySingleton(as: NotificationInboxRepository)`).

## Arquivos alterados

- `lib/core/notifications/domain/entities/app_notification.dart` — `AppNotificationCategory` deixou
  de ter um único valor (`targetAlert`) e passou a `{ crm, commercial, system }`, os três grupos que
  `tasks.md`/VESTI-110-112 realmente pedem para o filtro da central.
- `lib/core/notifications/domain/repositories/notification_inbox_repository.dart` — novos métodos
  `markAsRead`/`markAllAsRead` e a constante `kNotificationInboxRetentionLimit` (200).
- `lib/core/notifications/notifications.dart` — barrel passou a exportar os novos tipos de domínio/
  dados/apresentação.
- `lib/features/targets/domain/usecases/process_target_alert_use_case.dart` — usa
  `AppNotificationCategory.commercial` em vez do extinto `.targetAlert` (um alerta de meta é um
  evento comercial).
- `lib/core/design_system/components/components.dart` — exporta os dois novos componentes de
  notificação.
- `lib/core/navigation/app_route_paths.dart` — nova `NotificationCenterRoute`
  (`/org/:orgId/notifications`), escopada só por Organização (nunca por Company — `AppNotification`
  não tem `companyId`).
- `lib/core/navigation/app_router.dart` — novo `notificationCenterPageBuilder` (opcional, como a
  maioria dos builders de feature) e o `GoRoute` correspondente.
- `lib/app/bootstrap.dart` — `notificationCenterPageBuilder` conectado à `NotificationCenterPage` real
  (BLoC via `getIt`, `userId` via `AuthRepository`, `onOpenDeepLink` chamando `context.go(location)`).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (novo `NotificationDataSource`,
  `NotificationMapper`, `NotificationInboxLocalCache`, `NotificationInboxRepositoryImpl`, os três
  novos use cases e `NotificationCenterBloc`; removido o binding do extinto repositório
  `SharedPreferences`).
- `firestore.rules` — nova subcollection `organizations/{organizationId}/notifications/{notificationId}`:
  `get`/`list` restritos a `resource.data.userId == request.auth.uid`; `create` exige
  `userId == auth.uid`; `update` só aceita a marcação de leitura (`unchanged(...)` em todo o resto do
  documento); `delete` sempre `false`.
- `firestore.indexes.json` — índice composto `notifications` (`userId` ASC + `createdAt` DESC),
  exigido pela query `where('userId','==',...).orderBy('createdAt','desc')`.
- `test/features/targets/domain/usecases/process_target_alert_use_case_test.dart` e
  `test/features/targets/presentation/pages/target_dashboard_page_test.dart` — os fakes de
  `NotificationInboxRepository` ganharam `markAsRead`/`markAllAsRead` para continuar implementando a
  interface (nenhuma asserção de teste mudou).

## Arquitetura utilizada

- **Firestore como fonte de verdade, cache local só para leitura offline**: `NotificationInboxRepositoryImpl`
  compõe `NotificationDataSource` (Firestore) + `NotificationInboxLocalCache` (SharedPreferences).
  `listForUser` busca no Firestore, funde com qualquer entrada só-local (criada offline e ainda não
  sincronizada), grava o resultado fundido no cache e o devolve; se o Firestore falhar (o caso comum:
  sem conexão), devolve o que estiver em cache como sucesso — nunca como erro — satisfazendo o
  critério de aceite "notificações continuam acessíveis sem conexão".
- **`create`/`markAsRead`/`markAllAsRead` sempre local-first**: `ProcessTargetAlertUseCase` (TASK-149)
  já roda em campo, sem conexão, e não pode passar a depender de rede para enfileirar um alerta de
  meta. Por isso toda escrita grava primeiro no cache local (sempre funciona) e só depois tenta o
  Firestore em *best-effort*, via `unawaited(...)`, engolindo qualquer falha — sem outbox/retry
  dedicado (ver "Riscos conhecidos").
- **BLoC sem paginação de rede**: a "listagem paginada" é sobre a lista já limitada (
  `kNotificationInboxRetentionLimit = 200`) que `listForUser` devolve de uma vez — o BLoC só controla
  quantos itens dessa lista já-carregada estão visíveis (`visibleCount`, crescendo por
  `kNotificationCenterPageSize = 20` a cada "carregar mais", via o componente `AppPagination`
  existente). Trade-off deliberado: como o próprio inbox é limitado a 200 itens por usuário, uma
  paginação por cursor no Firestore (que exigiria manter estado de cursor entre chamadas, mais difícil
  de casar com a fusão local/remota acima) não agregaria valor real nesta escala.
- **BLoC nunca navega**: `NotificationCenterBloc` só marca como lida ao tocar (`NotificationCenterNotificationTapped`);
  quem chama `context.go(deepLink)` é o próprio `NotificationCenterPage` (via callback
  `onOpenDeepLink`, resolvido em `bootstrap.dart`) — mesmo padrão de `SavedReportsPage`/
  `ReportBuilderPage` (`onOpenReportBuilder`/`onOpenSavedReports`), que mantém o BLoC testável sem
  `go_router` e sem `BuildContext`.
- **Deep link inválido/removido nunca quebra a navegação**: um `deepLink` vazio mostra um snackbar
  amigável ("Este item não está mais disponível") em vez de navegar; um `deepLink` não-vazio mas para
  uma rota inexistente/sem permissão já cai nos guards existentes do `AppRouter`
  (`NotFoundPage`/`ForbiddenPage`) sem nenhum código novo — o roteador já tratava isso antes desta
  task.
- **Regra de negócio validada em Security Rules, não só no cliente**: a query do cliente já filtra
  por `userId`, mas a regra `list`/`get` em `firestore.rules` também exige
  `resource.data.userId == request.auth.uid` — nenhuma notificação de outro usuário é exposta mesmo
  que uma query futura esqueça o filtro. `update` só aceita a chave `readAt` mudar (todo o resto do
  documento é obrigatoriamente `unchanged(...)`), então nem o próprio dono pode reescrever
  título/corpo/categoria depois de criado.

## Categorias e filtro

`AppNotificationCategory` tem três valores — `crm`, `commercial`, `system` — mapeados 1:1 para os
filtros exigidos ("CRM, comercial, sistema"). O alerta de meta (TASK-149, `ProcessTargetAlertUseCase`)
passou a usar `.commercial` (estava usando o extinto `.targetAlert`) por ser, na prática, um evento
comercial (ritmo de meta/vendas). TASK-152 (CRM) e TASK-153 (comercial: pedidos/oportunidades) têm
os dois grupos restantes prontos para usar assim que existirem; `system` fica disponível para
qualquer evento futuro que não seja nem CRM nem comercial.

## Deep link

`AppNotification.deepLink` já chega pronto como uma URL relativa resolvida por uma rota tipada
existente (ex.: `TargetDashboardRoute(...).location`, como `ProcessTargetAlertUseCase` já fazia desde
a TASK-149) — a central nunca constrói rota nenhuma, só navega para o que já está salvo. Ao tocar:

1. `NotificationCenterBloc` marca a notificação como lida (otimista, local-first).
2. Se `deepLink` estiver vazio, mostra snackbar amigável e não navega.
3. Caso contrário, `context.go(deepLink)` — validação de existência/permissão do destino é sempre do
   próprio `AppRouter` (guards + `NotFoundPage`/`ForbiddenPage`), nunca duplicada aqui.

## Impacto offline

`listForUser`/`create`/`markAsRead`/`markAllAsRead` funcionam sem conexão: leitura cai para o cache
local (`NotificationInboxLocalCache`, bounded a 200 itens por usuário/organização) e toda escrita é
local-first. Não há fila de outbox/retry dedicada para a sincronização remota best-effort — uma
notificação criada offline permanece "local-only" até o próximo `listForUser` bem-sucedido conseguir
mesclá-la (ela nunca desaparece da lista, só demora a existir no Firestore).

## Impacto multi-tenant

Cada `AppNotification` é escrita sob `organizations/{organizationId}/notifications/`, nunca em uma
coleção global, e sempre carrega `userId` — tanto a query do cliente quanto `firestore.rules` filtram
por ele. Nenhuma notificação de outro usuário ou organização é lida em nenhum ponto do fluxo.

## Analytics/Crashlytics/Performance

Nenhum evento novo de analytics adicionado. Justificativa: a tela em si (listar, filtrar, marcar como
lida) não é um evento comercial que os agentes de negócio (`vestipro-sales-representative-specialist`/
`vestipro-commercial-ops-strategist`) listam como obrigatório de instrumentar — TASK-152/153, que vão
gerar as notificações de negócio reais (CRM/comercial), são o lugar mais natural para decidir se algum
evento (ex.: "notificação de meta gerou pedido") vale a pena.

## Decisões técnicas

- Categorias redefinidas de `{ targetAlert }` para `{ crm, commercial, system }` em vez de manter
  `targetAlert` como um quarto valor — o enum de categoria existia desde a TASK-150/149 mas nunca
  tinha sido pensado para os três grupos que a central precisa filtrar; corrigir agora (antes de
  TASK-152/153 crescerem em cima dele) evita uma segunda migração de dado/enum depois.
- `NotificationInboxRepository` ganhou métodos novos em vez de uma interface paralela — os dois testes
  existentes que implementam a interface (`_FakeNotificationInboxRepository`, em
  `process_target_alert_use_case_test.dart` e `target_dashboard_page_test.dart`) só precisaram de dois
  métodos stub a mais, sem mudar nenhuma asserção.
- `NotificationMapper` foi anotado `@lazySingleton` (a classe original não tinha anotação nenhuma,
  seguindo o exemplo de `PushDeviceMapper`) — mas ao rodar `build_runner`, o gerador avisou que
  `PushDeviceMapper` (TASK-150) é resolvido via `gh<PushDeviceMapper>()` sem nunca ter sido registrado
  em lugar nenhum, uma falha em potencial (só aparece em runtime, no primeiro acesso a
  `PushDeviceRepositoryImpl`). Como `NotificationMapper` seguiria o mesmo padrão e
  `NotificationInboxRepositoryImpl` É de fato resolvido em runtime (via `ProcessTargetAlertUseCase`,
  já em uso desde a TASK-149), a anotação foi adicionada para não herdar esse mesmo bug — `PushDeviceMapper`
  em si não foi tocado, por ser um arquivo de outra task/fora do escopo desta.
- Bell button (`AppNotificationBellButton`) criado como componente de Design System reutilizável, mas
  **não** foi encaixado em nenhuma tela existente (`CatalogHomePage` etc.) nem em `AppAdaptiveShell` —
  ver "Pendências".
- Índice composto Firestore (`userId` ASC + `createdAt` DESC) adicionado em `firestore.indexes.json`
  porque a query do `FirestoreNotificationDataSource` combina uma igualdade (`userId`) com ordenação
  por outro campo (`createdAt`), o que o Firestore não cobre com índices automáticos de campo único.

## Riscos conhecidos

- Nenhum teste automatizado dedicado foi criado para `NotificationCenterBloc`/
  `NotificationInboxRepositoryImpl`/`FirestoreNotificationDataSource` (protocolo desta execução não
  exige testes como etapa obrigatória de encerramento, e não há regra financeira/de aprovação/preço
  envolvida). Os pontos de maior risco de regressão silenciosa seriam: (1) a fusão remoto+local em
  `listForUser` nunca perder uma notificação criada offline antes do primeiro sync bem-sucedido; (2)
  `markAllAsRead` marcar exatamente as notificações não lidas no momento da chamada, nunca uma criada
  depois; (3) as novas Firestore Rules (`get`/`list` só do próprio dono, `update` só aceitando
  `readAt`).
- `AppNotificationBellButton` existe mas não está conectado a nenhuma tela/shell real — a única forma
  de chegar à central hoje é navegar diretamente para `NotificationCenterRoute`
  (`/org/:orgId/notifications`). `AppAdaptiveShell` (o shell de navegação persistente do Design
  System, TASK-023) também não está — e já não estava antes desta task — conectado em nenhuma página
  real do app; conectar o sino a um shell que ainda não existe na composição do app ficaria fora do
  escopo desta task e arriscaria alterações amplas em telas já em produção.
- `PushNotificationRouter.messages`/`consumeInitialMessage()` (TASK-150) continuam sem nenhum
  consumidor real: esta task resolve a navegação a partir da lista da própria central, mas não liga um
  toque em push (app em foreground/background/terminado) diretamente a uma navegação automática —
  isso exigiria decidir onde no `BuildContext`/composição do app (`VestiProApp`) esse listener global
  viveria, o que foi considerado uma mudança de escopo maior (arquitetura de navegação global) do que
  esta task pretendia cobrir.
- Sem outbox/retry dedicado para a sincronização remota best-effort de `create`/`markAsRead`/
  `markAllAsRead` — uma notificação criada offline só aparece no Firestore no próximo `listForUser`
  bem-sucedido (que tenta de novo implicitamente, não há fila persistente de "pendente de sync").
- Retenção/arquivamento além do corte simples de 200 itens (TASK-160, citado no arquivo da própria
  task) não foi implementado — apenas o cap simples em `kNotificationInboxRetentionLimit`.
- Não foi possível compilar/rodar o app de fato nesta sessão (mesma limitação já registrada desde
  TASK-010/011/150: `lib/firebase_options.dart` gitignorado, sem emulador/host disponível) — a
  validação aqui é `flutter analyze` (limpo) e `flutter test` dos arquivos tocados/relacionados, não
  uma execução ponta a ponta.

## Pendências

- Encaixar `AppNotificationBellButton` em alguma tela/shell real (ou finalmente conectar
  `AppAdaptiveShell`) fica para quando existir uma task dedicada de navegação persistente — hoje
  qualquer página pode adotá-lo em seus `actions`, mas nenhuma o faz ainda.
- Ligar `PushNotificationRouter.messages`/`consumeInitialMessage()` a uma navegação automática de
  app-level (tocar num push enquanto o app está aberto deveria abrir a tela certa mesmo sem passar
  pela central) — depende de uma decisão de arquitetura de navegação global fora do escopo desta task.
- `PushPermissionService.requestIfNotAlreadyAsked()` (TASK-150) segue sem ser chamado por nenhuma
  tela — a central seria um bom candidato ("ativar notificações"), mas isso não foi pedido
  explicitamente no escopo da TASK-151 e fica como sugestão para TASK-152/153.
- Push (`git push`) não realizado nesta rodada — depende de autorização explícita do usuário.

## Comandos executados

```bash
dart run build_runner build
dart run build_runner build   # segunda vez, após anotar NotificationMapper
flutter analyze lib/core/notifications lib/core/design_system/components/notifications lib/core/navigation lib/app/bootstrap.dart lib/features/targets/domain/usecases/process_target_alert_use_case.dart
flutter analyze
flutter test test/features/targets/domain/usecases/process_target_alert_use_case_test.dart test/features/targets/presentation/pages/target_dashboard_page_test.dart
flutter test test/core/navigation/app_router_test.dart
dart format lib/core/notifications lib/core/design_system/components/notifications lib/core/design_system/components/components.dart lib/core/navigation lib/app/bootstrap.dart lib/features/targets/domain/usecases/process_target_alert_use_case.dart test/features/targets/domain/usecases/process_target_alert_use_case_test.dart test/features/targets/presentation/pages/target_dashboard_page_test.dart
```

## Resultado do formatter

`dart format` não alterou nenhum dos arquivos analisados (todos já formatados).

## Resultado do analyzer

`flutter analyze` (projeto inteiro): 12 issues, todas pré-existentes e sem relação com esta task — 6
avisos de depreciação (`Radio.groupValue`/`onChanged` em
`lib/features/reports/presentation/pages/report_builder_page.dart`) e 6 sugestões de lint em testes de
`dashboards` (`use_null_aware_elements`). Nenhum arquivo criado/alterado por esta task aparece na
lista.

## Resultado dos testes

`flutter test` dos dois arquivos de teste alterados (fakes atualizados): 13/13 passando.
`flutter test test/core/navigation/app_router_test.dart` (rota nova adicionada ao roteador): 20/20
passando. Nenhum teste novo dedicado a `NotificationCenterBloc`/`NotificationInboxRepositoryImpl` foi
criado nesta execução (ver "Riscos conhecidos").
