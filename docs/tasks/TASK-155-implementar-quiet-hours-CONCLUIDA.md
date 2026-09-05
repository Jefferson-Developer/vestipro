# TASK-155 — Implementar quiet hours (CONCLUÍDA)

**Epic:** EPIC-19 — Notificações e Engajamento
**Depende de:** TASK-151 (central de notificações internas), TASK-154 (preferências de comunicação)

## Resumo da solução

Estendeu `CommunicationPreferences` (TASK-154) com um novo campo `quietHours: QuietHours`
(`lib/core/notifications/domain/entities/quiet_hours.dart`), modelando o horário de silêncio do
próprio usuário: `enabled`, `startMinuteOfDay`/`endMinuteOfDay` (com suporte a janela que cruza a
meia-noite, ex. 22:00-07:00), `activeWeekdays` (dias da semana) e `timezoneOffsetMinutes` — o offset
UTC real do dispositivo do usuário, nunca o do servidor.

Em vez de criar uma fila/coleção separada para notificações adiadas, a solução reaproveita a própria
`AppNotification` (TASK-151) adicionando um campo `deliverAt` opcional:

- `deliverAt == null` → visível imediatamente (comportamento de sempre, nenhuma notificação anterior
  ao TASK-155 é afetada).
- `deliverAt` no futuro → a notificação já foi persistida (nunca perdida), mas
  `NotificationInboxRepository.listForUser`/`markAllAsRead` a escondem até que
  `DateTime.now().toUtc()` alcance esse instante — sem precisar de nenhum job de "flush" separado,
  ela simplesmente aparece na próxima leitura, incluindo offline (cache local também guarda
  `deliverAt`).

Um novo use case `ResolveNotificationDeliveryTimeUseCase` decide esse `deliverAt`: `null` sempre para
notificações `critical` (exceção de segurança do TASK-154/TASK-155), e igual a
`QuietHours.nextAllowedInstant(now)` quando a notificação é `informative` e `now` cai dentro da janela
de silêncio do destinatário (`QuietHours.isActiveAt`). Os quatro geradores de notificação do EPIC-19
(`ProcessCrmTaskReminderUseCase`, `ProcessTargetAlertUseCase`, `ProcessOrderCommercialAlertUseCase`,
`ProcessInsightCommercialAlertUseCase`) agora chamam esse use case antes de montar a
`AppNotification`, do mesmo jeito que já chamavam `ShouldDispatchNotificationUseCase` (TASK-154) — os
dois gates continuam independentes (um decide *se* a categoria está silenciada, o outro decide
*quando* uma notificação permitida realmente aparece).

O guard ad-hoc de "janela de envio" (8h-18h, fixo por organização) que `ProcessCrmTaskReminderUseCase`
usava desde o TASK-152 foi removido — seu próprio comentário já documentava que seria substituído
assim que TASK-155 existisse. `CrmReminderSettings` perdeu os campos
`allowedSendingStartHour`/`allowedSendingEndHour`/`isWithinAllowedSendingWindow`.

O timezone do dispositivo é capturado via `DeviceTimezoneProvider` (`DateTime.now().timeZoneOffset`,
sem nenhuma dependência de banco de timezone/IANA — decisão documentada em `QuietHours`) e mantido
sincronizado por `SyncDeviceTimezoneUseCase`, chamado a cada mudança de sessão (`bootstrap.dart`,
`configureQuietHoursTimezoneSync`, mesmo padrão de `configurePushNotificationLifecycle` do TASK-150) —
é um no-op quando o offset já bate com o salvo, e atualiza (detectando viagem/mudança de fuso) quando
diverge.

A tela de preferências de comunicação (TASK-154) ganhou uma seção "Horário de silêncio": toggle
(`AppCheckbox`), seletores de horário de início/fim (`showTimePicker` nativo do Flutter, já que ainda
não existe um componente de time-picker no Design System) e chips de dias da semana (`AppFilterChip`,
reaproveitando o componente já usado pelas outras seções desta mesma tela).

## Entidades, use cases e contratos

- `lib/core/notifications/domain/entities/quiet_hours.dart` — `QuietHours` (novo).
- `lib/core/notifications/domain/entities/communication_preferences.dart` — campo `quietHours` +
  `withQuietHours`.
- `lib/core/notifications/domain/entities/app_notification.dart` — campo `deliverAt` + `isVisibleAt`.
- `lib/core/notifications/domain/usecases/resolve_notification_delivery_time_use_case.dart` (novo).
- `lib/core/notifications/domain/usecases/sync_device_timezone_use_case.dart` (novo).
- `lib/core/notifications/push/device_timezone_provider.dart` (novo) —
  `DeviceTimezoneProvider`/`SystemDeviceTimezoneProvider`.
- `lib/core/notifications/data/dtos/communication_preferences_dto.dart` e
  `data/mappers/communication_preferences_mapper.dart` — persistência de `quietHours`.
- `lib/core/notifications/data/dtos/notification_dto.dart` e `data/mappers/notification_mapper.dart` —
  persistência de `deliverAt`.
- `lib/core/notifications/data/local/notification_inbox_local_cache.dart` — persiste `deliverAt`
  também no cache local (offline).
- `lib/core/notifications/data/repositories/notification_inbox_repository_impl.dart` — filtra
  notificações ainda não visíveis em `listForUser`/`markAllAsRead`.
- `lib/core/notifications/data/repositories/communication_preferences_repository_impl.dart` —
  preserva `quietHours` ao salvar.
- `lib/app/bootstrap.dart` — `configureQuietHoursTimezoneSync`, chamado em `bootstrap()`.
- `lib/features/crm/domain/value_objects/crm_reminder_settings.dart` — removido o guard de janela
  ad-hoc.
- `lib/features/crm/domain/usecases/process_crm_task_reminder_use_case.dart`,
  `lib/features/targets/domain/usecases/process_target_alert_use_case.dart`,
  `lib/features/orders/domain/usecases/process_order_commercial_alert_use_case.dart`,
  `lib/features/insights/domain/usecases/process_insight_commercial_alert_use_case.dart` — passam a
  resolver `deliverAt` antes de criar a notificação.
- `lib/core/notifications/presentation/bloc/communication_preferences_cubit.dart` —
  `updateQuietHours`.
- `lib/core/notifications/presentation/pages/communication_preferences_page.dart` — seção de UI de
  horário de silêncio.
- `lib/core/notifications/notifications.dart` — novos exports do barrel.

## Regras de negócio e restrições atendidas

- Notificações críticas (segurança/sessão, pedido rejeitado, falha crítica de sincronização) nunca são
  adiadas, mesmo durante o horário de silêncio.
- Nenhuma notificação não crítica aparece durante o horário de silêncio configurado; ela é entregue
  automaticamente assim que o horário termina, sem nenhuma notificação ser perdida (persistida desde a
  criação).
- O timezone considerado é sempre o do dispositivo do destinatário (offset UTC real capturado
  client-side), nunca o do servidor/backend.
- Mudança de fuso do dispositivo (ex. viagem) é detectada e atualizada automaticamente a cada troca de
  sessão.

## Riscos e decisões conhecidas

- O timezone é armazenado como offset UTC (`DateTime.timeZoneOffset.inMinutes`), não como identificador
  IANA — decisão documentada em `QuietHours` para evitar adicionar uma dependência de banco de dados de
  timezone (`timezone`/`flutter_native_timezone`) que não existia no projeto. Suficiente para todas as
  regras de negócio e critérios de aceite desta task; um IANA completo traria correção adicional apenas
  em casos raros de troca de política de DST no meio da janela de silêncio.
- A "fila" de entrega é lógica (campo `deliverAt` + filtro de visibilidade), não uma fila/coleção
  separada com job de flush — mesma arquitetura client-driven já usada pelos quatro geradores (nenhum
  deles depende de Cloud Function agendada hoje). A notificação se torna visível na próxima leitura do
  inbox (abertura da central de notificações, ou próxima sincronização) após o fim do horário de
  silêncio.
- Push/e-mail reais ainda não são enviados por nenhum gerador (mesma limitação documentada desde
  TASK-154) — esta implementação cobre o canal que realmente existe hoje (central de notificações
  interna). Quando um envio de push real via Cloud Function for implementado, a mesma política de
  timezone salvo em `quietHours` deve ser replicada no lado servidor.

## Validações executadas

- `dart run build_runner build` — regenerou `lib/app/injection.config.dart` com os novos
  `@injectable`s (`ResolveNotificationDeliveryTimeUseCase`, `SyncDeviceTimezoneUseCase`,
  `DeviceTimezoneProvider`/`SystemDeviceTimezoneProvider`). Warnings de dependências faltando
  reportados pelo gerador são pré-existentes, não relacionados a esta task.
- `flutter analyze` (repositório inteiro) — nenhum problema novo; apenas infos pré-existentes em
  arquivos não tocados por esta task.
- `dart format` nos arquivos alterados — aplicado, sem alterações pendentes.
- `flutter test` — suíte completa de `test/core/notifications/`, mais os testes dos quatro geradores
  (CRM/targets/orders/insights), a página `target_dashboard_page_test.dart` (que constrói
  `ProcessTargetAlertUseCase` diretamente) e `test/app/bootstrap_test.dart`: 81 testes relevantes
  passando. Testes novos: `quiet_hours_test.dart`,
  `resolve_notification_delivery_time_use_case_test.dart`, `sync_device_timezone_use_case_test.dart`,
  `notification_inbox_repository_impl_test.dart`, além de casos adicionados aos mappers/páginas/geradores
  já existentes.
- Confirmado que a única falha remanescente (`bootstrap_test.dart`, primeiro teste, erro
  `PushDeviceMapper is not registered`) já existia antes desta task — reproduzida com `git stash` sobre
  o código anterior ao TASK-155, mesmo erro. Gap pré-existente, documentado desde o TASK-151
  (`NotificationMapper`'s próprio doc comment), fora do escopo desta task.

## Testes obrigatórios (da task) — cobertura

- Cálculo de horário local com timezone salvo distinto do servidor: `quiet_hours_test.dart`.
- Notificação fora do quiet hours é enfileirada e entregue no próximo horário permitido, sem se
  perder: `notification_inbox_repository_impl_test.dart`, mais os testes "deferred"/"future deliverAt"
  nos quatro geradores.
- Exceção para notificações críticas durante quiet hours: casos dedicados em
  `resolve_notification_delivery_time_use_case_test.dart`, `process_target_alert_use_case_test.dart`,
  `process_insight_commercial_alert_use_case_test.dart`, `process_order_commercial_alert_use_case_test.dart`.
- Atualização de timezone quando o dispositivo muda de fuso: `sync_device_timezone_use_case_test.dart`.
- Widget de configuração de horário (toggle, seleção de dias): novos casos em
  `communication_preferences_page_test.dart`.
