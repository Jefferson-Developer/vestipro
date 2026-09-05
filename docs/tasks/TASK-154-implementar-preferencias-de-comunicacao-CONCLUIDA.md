# TASK-154 — Implementar preferências de comunicação (CONCLUÍDA)

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** Concluída
**Data:** 2026-09-05

## Resumo

Modelado e implementado `CommunicationPreferences`: um documento por usuário
(`organizations/{organizationId}/communicationPreferences/{userId}`) que controla,
por categoria (`crm`, `commercial`, `system` — reaproveitando o
`AppNotificationCategory` já existente do TASK-151) e por canal (`push`, `email`,
`inApp`/central de notificações), a frequência desejada
(`immediate`/`dailyDigest`/`disabled`). O documento é a fonte única de verdade e é
lido/observado em tempo real via Firestore, o que satisfaz "alteração em um
dispositivo reflete nos demais" sem qualquer sincronização local própria.

Os quatro geradores de notificação já existentes (TASK-152/TASK-153) agora
consultam a preferência do destinatário — através de um novo
`ShouldDispatchNotificationUseCase` central — antes de gravar qualquer
`AppNotification` na central interna:

- `ProcessCrmTaskReminderUseCase` (categoria `crm`)
- `ProcessOrderCommercialAlertUseCase` (categoria `commercial`)
- `ProcessInsightCommercialAlertUseCase` (categoria `commercial`)
- `ProcessTargetAlertUseCase` (categoria `commercial`)

## Decisões de escopo

- **Canal efetivamente aplicado hoje:** nenhum gerador existente envia push ou
  e-mail de fato (TASK-150 só cobre registro de token/roteamento; não existe
  Cloud Function de envio de push nem de e-mail nesta base). Por isso
  `ShouldDispatchNotificationUseCase` usa `CommunicationChannel.inApp` como
  canal padrão — é o único canal que hoje realmente decide se uma notificação é
  criada. Os canais `push`/`email` já são modelados e persistidos (a UI permite
  configurá-los) para não exigir migração de esquema quando um envio real for
  implementado em task futura.
- **`dailyDigest` (resumo diário):** é um valor válido e persistido, mas não
  existe hoje motor de lote/agendamento que efetivamente componha um resumo
  diário (isso está fora do escopo desta task — nenhuma Cloud Function nova foi
  criada para isso). O gate (`ShouldDispatchNotificationUseCase`) trata qualquer
  valor diferente de `disabled` como "permitido agora"; a semântica de
  agendamento real do resumo diário fica documentada como lacuna conhecida para
  uma task futura de digest (ligada ao TASK-155/quiet hours ou nova task de
  EPIC-19).
- **Regra de categoria crítica de sistema:** `SaveCommunicationPreferencesUseCase`
  rejeita (com `ValidationFailure`, nunca persiste) qualquer alteração que
  deixaria a categoria `system` com todos os canais desativados
  simultaneamente — a UI reverte a seleção automaticamente e mostra um
  snackbar de erro, porque o estado exibido só muda quando o `Cubit` recebe
  sucesso do use case.
- **Padrão seguro documentado:** ausência de preferência salva
  (`CommunicationPreferences.defaults`) resulta em `push`/`inApp` = imediato e
  `email` = desativado, igual para as três categorias — aplicado tanto no
  `CommunicationPreferencesRepositoryImpl.get`/`watch` (quando não há
  documento) quanto no `CommunicationPreferencesMapper` (quando uma categoria
  específica está ausente de um documento antigo).
- **Testes de Firestore Rules em Emulator:** seguindo o mesmo precedente já
  estabelecido pelas TASK-150/151/152/153 (nenhuma delas adicionou testes em
  `firestore-tests/firestore.rules.test.js` para `pushDevices`/`notifications`),
  as novas regras de `communicationPreferences` foram documentadas em
  comentário extenso no próprio `firestore.rules`, mas não ganharam suíte no
  Emulator nesta rodada — mesma lacuna conhecida pré-existente na área de
  notificações, não introduzida por esta task.

## Arquivos criados

### Domínio (`lib/core/notifications/domain`)
- `entities/communication_preferences.dart` — `CommunicationChannel`,
  `CommunicationFrequency`, `CategoryCommunicationPreference`,
  `CommunicationPreferences` (com `defaults`, `frequencyFor`, `allows`,
  `withChannelFrequency`, `hasSystemCategoryFullyDisabled`).
- `repositories/communication_preferences_repository.dart`
- `usecases/get_communication_preferences_use_case.dart`
- `usecases/watch_communication_preferences_use_case.dart`
- `usecases/save_communication_preferences_use_case.dart` (valida a regra da
  categoria `system`)
- `usecases/should_dispatch_notification_use_case.dart` (gate consumido pelos 4
  geradores; falha aberto — nunca silencia uma notificação por erro de leitura)

### Dados (`lib/core/notifications/data`)
- `dtos/communication_preferences_dto.dart`
- `mappers/communication_preferences_mapper.dart`
- `datasources/communication_preferences_data_source.dart`
- `datasources/firestore_communication_preferences_data_source.dart`
- `repositories/communication_preferences_repository_impl.dart`

### Apresentação (`lib/core/notifications/presentation`)
- `bloc/communication_preferences_state.dart`
- `bloc/communication_preferences_cubit.dart` (assina `watch()` durante todo o
  ciclo de vida da tela — sem "atualizar" manual)
- `pages/communication_preferences_page.dart` (seções por categoria, chips de
  frequência por canal reaproveitando `AppFilterChip`/`AppAdminPageLayout`)

### Testes
- `test/support/fake_communication_preferences_repository.dart` (fake
  reutilizado pelos testes dos 4 geradores + novos testes de domínio)
- `test/core/notifications/domain/entities/communication_preferences_test.dart`
- `test/core/notifications/domain/usecases/save_communication_preferences_use_case_test.dart`
- `test/core/notifications/domain/usecases/should_dispatch_notification_use_case_test.dart`
- `test/core/notifications/data/repositories/communication_preferences_repository_impl_test.dart`
  (inclui simulação de dois dispositivos observando o mesmo `watch()` e teste
  de isolamento por organização/usuário)
- `test/core/notifications/presentation/pages/communication_preferences_page_test.dart`
  (estados de sucesso e erro/reversão do formulário)

## Arquivos alterados

- `lib/core/notifications/notifications.dart` — exporta as novas entidades/
  repositório/use cases/bloc/página.
- `lib/core/analytics/analytics_events.dart` — novo evento
  `communication_preferences_updated`.
- `lib/core/navigation/app_route_paths.dart` /
  `lib/core/navigation/app_router.dart` — nova rota
  `CommunicationPreferencesRoute` (`/org/:orgId/settings/notifications/preferences`).
- `lib/core/notifications/presentation/pages/notification_center_page.dart` —
  novo botão de ação "Preferências" (ícone `tune`) que abre a nova tela.
- `lib/app/bootstrap.dart` — builders de rota (`communicationPreferencesPageBuilder`)
  e o callback `onOpenPreferences` da central de notificações.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build`
  (registra os novos `@injectable`/`@LazySingleton`).
- `lib/features/crm/domain/usecases/process_crm_task_reminder_use_case.dart`,
  `lib/features/orders/domain/usecases/process_order_commercial_alert_use_case.dart`,
  `lib/features/insights/domain/usecases/process_insight_commercial_alert_use_case.dart`,
  `lib/features/targets/domain/usecases/process_target_alert_use_case.dart` —
  cada um passou a receber `ShouldDispatchNotificationUseCase` e consulta o
  gate antes de criar a `AppNotification`.
- `firestore.rules` — nova seção
  `organizations/{organizationId}/communicationPreferences/{userId}` (get/create/
  update escopados por `userId == request.auth.uid`; `list`/`delete` negados).
- Testes existentes dos 4 geradores + `target_dashboard_page_test.dart` —
  ajustados para o novo parâmetro de construtor e cada um dos 4 geradores
  ganhou um novo teste "não notifica quando a preferência está desativada".

## Validações executadas

- `dart run build_runner build` — regenerou `lib/app/injection.config.dart`
  com sucesso (os únicos avisos de "missing dependencies" impressos já
  existiam antes desta task, confirmado reproduzindo o build com `git stash`
  sobre o HEAD anterior).
- `flutter analyze` (projeto inteiro) — 0 erros; os únicos infos remanescentes
  (deprecação de `RadioListTile.groupValue` em `report_builder_page.dart` e
  `use_null_aware_elements` em testes de dashboards) já existiam antes desta
  task.
- `dart format` sobre todos os arquivos criados/alterados.
- `flutter test` sobre:
  - `test/core/notifications/**` (15 testes novos/existentes, todos passando)
  - Os 4 testes de use case de geração de notificação + o teste de widget do
    `TargetDashboardPage` (52 testes no total, todos passando).

## Pendências/riscos conhecidos

- Nenhum motor de envio real de push/e-mail existe ainda nesta base — os
  canais `push`/`email` ficam persistidos e configuráveis, mas só o canal
  `inApp` (central) é hoje efetivamente gateado por
  `ShouldDispatchNotificationUseCase`. Quando um envio real de push/e-mail for
  implementado, ele deve chamar o mesmo gate passando o canal correspondente.
- `dailyDigest` não tem motor de lote — comportamento documentado acima.
- Testes de Firestore Rules em Emulator para `communicationPreferences` não
  foram adicionados, seguindo o mesmo precedente das tasks anteriores do
  mesmo EPIC.
