# TASK-152 — Concluída (2026-09-05)

## Resumo

Implementados lembretes de CRM (EPIC-19): follow-ups/tarefas atrasados ou próximos do vencimento
(TASK-060) agora geram uma notificação interna (categoria `crm`, TASK-151) endereçada ao vendedor
responsável — e, quando aplicável, ao gestor com visibilidade da equipe — com deep link tipado para
a tela do cliente relacionado, deduplicação/cooldown por tarefa e uma janela temporária de horário
permitido de envio.

### Decisão de arquitetura: sem Cloud Function (bloqueio real de dependência)

O escopo técnico original da task descreve "Cloud Function agendada (ou trigger em
criação/atualização de tarefa/follow-up de TASK-060)". Ao investigar o estado real do repositório
antes de codar (passo obrigatório do fluxo), verifiquei que:

- `CrmTask`/`CrmActivity` (TASK-060) não têm repositório Firestore — a única implementação
  registrada é `SharedPreferencesCrmTaskRepository`, **local ao dispositivo**. Não existe
  `crmTasks` (ou equivalente) em `firestore.rules` nem em nenhum `functions/src/*`. Uma Cloud
  Function não teria nada para ler.
- `firestore.rules` da subcollection `notifications` (TASK-151) já **hoje** só permite
  `create` quando `request.resource.data.userId == request.auth.uid` — ou seja, mesmo com Admin
  SDK bypassando Rules, o precedente estabelecido no código (`ProcessTargetAlertUseCase`,
  TASK-149) é o cliente gerar e gravar sua própria notificação, nunca um servidor empurrando
  notificação para outro usuário.

Diante disso seria uma invenção de infraestrutura fora do escopo desta task (e incoerente com o
resto do código) implementar uma Cloud Function contra uma collection que não existe. Em vez disso,
segui exatamente o mesmo padrão já estabelecido por `ProcessTargetAlertUseCase`/
`TargetAlertDispatchRepository` (TASK-149): avaliação **client-side**, disparada quando o próprio
usuário carrega sua lista de tarefas (`CrmTaskListBloc`), gravando a notificação para si mesmo. Essa
decisão está documentada nos comentários de código (`GenerateCrmTaskRemindersUseCase`,
`ProcessCrmTaskReminderUseCase`) para que uma futura migração de `CrmTask` para Firestore
(EPIC-14/sync) possa trocar o gatilho por uma Cloud Function real sem redesenhar as regras de
negócio (evaluator/dedup/conteúdo continuam os mesmos).

### Decisão: RBAC (responsável + gestor, nunca outro vendedor)

`CrmTaskListBloc` já carregava a lista de tarefas escopada por `visibleResponsibleUserIds`
(as próprias tarefas do usuário, mais as da equipe quando `canManageOthers` é `true`). O novo
`GenerateCrmTaskRemindersUseCase` reaproveita exatamente esse escopo: o destinatário da
notificação é sempre o usuário autenticado atual (`state.userId`), nunca lido de
`CrmTask.responsibleUserId` cegamente — o que satisfaz a regra "apenas o responsável, e o gestor
com visibilidade de equipe, recebe a notificação" por construção, sem precisar de lógica de RBAC
adicional (e é compatível com a regra de Firestore citada acima). O conteúdo da mensagem varia
("seu follow-up" vs. "follow-up da sua equipe") conforme `task.responsibleUserId == recipientUserId`.

### Decisão: janela de horário (quiet hours) temporária

A task pede para reaproveitar a mesma regra de TASK-155 (quiet hours) sem duplicar. TASK-155 ainda
não existe no backlog (é posterior a esta). Implementei uma janela mínima e isolada em
`CrmReminderSettings` (padrão 8h-18h, hora local do dispositivo), documentada explicitamente como
temporária — quando TASK-155 for implementada, deve substituir `isWithinAllowedSendingWindow` por
uma chamada à política compartilhada, em vez de manter as duas.

### Decisão: envio de push (TASK-150)

Não há, em nenhum lugar do código hoje (nem para metas/TASK-149, nem para nenhuma outra categoria),
uma Cloud Function que efetivamente envie push via FCM — `functions/src` não tem nenhum uso de
`firebase-admin/messaging`. TASK-150 criou apenas a camada de registro de token
(`PushDeviceRepository`) e o roteador de notificação recebida no cliente. Portanto "push via
TASK-150 quando aplicável" já está coberto pelo mesmo nível de suporte que qualquer outra
notificação interna tem hoje: nenhuma. Isso é uma lacuna pré-existente do produto, não introduzida
nem escondida por esta task.

## Agentes utilizados

- `flutter-senior-architect` (domínio, dedup/cooldown, DI, deep link)
- `flutter-ui-design-specialist` (revisão do fluxo de UI existente — nenhuma tela nova foi
  necessária; o gatilho é o `CrmTaskListBloc` já existente)

## Arquivos criados

Domínio (`lib/features/crm/domain/`):

- `value_objects/crm_task_reminder_classification.dart` — enum `dueSoon`/`overdue`/`none`.
- `value_objects/crm_reminder_settings.dart` — janela "due soon", cooldown e janela de horário
  temporária (ver decisão acima).
- `services/crm_task_reminder_evaluator.dart` — classificação pura de um `CrmTask`.
- `repositories/crm_reminder_dispatch_repository.dart` — contrato de dedup/cooldown, chaveado por
  tarefa + destinatário + classificação (mesmo padrão de `TargetAlertDispatchRepository`).
- `usecases/process_crm_task_reminder_use_case.dart` — avalia uma tarefa, resolve deep link,
  aplica dedup/cooldown/janela de horário e grava a notificação via `NotificationInboxRepository`.
- `usecases/generate_crm_task_reminders_use_case.dart` — orquestra o processamento em lote das
  tarefas já carregadas para um destinatário.

Dados (`lib/features/crm/data/`):

- `repositories/shared_preferences_crm_reminder_dispatch_repository.dart` — dedup/cooldown local
  (mesma estratégia de `SharedPreferencesTargetAlertDispatchRepository`, coerente com
  `CrmTask` também ser local-only hoje).

Testes:

- `test/features/crm/domain/services/crm_task_reminder_evaluator_test.dart`
- `test/features/crm/domain/usecases/process_crm_task_reminder_use_case_test.dart` (dedup/cooldown,
  deep link, conteúdo próprio-vs-equipe, janela de horário)

## Arquivos alterados

- `lib/features/crm/crm.dart` — exporta as novas classes.
- `lib/features/crm/presentation/bloc/crm_task_list_bloc.dart` — nova dependência opcional
  `GenerateCrmTaskRemindersUseCase? generateCrmTaskReminders` (opcional para não quebrar
  `crm_task_list_page_test.dart`, que constrói o bloc manualmente sem essa dependência); `_load()`
  agora dispara os lembretes após emitir a lista carregada.
- `lib/core/analytics/analytics_events.dart` — novo evento `crm_reminder_triggered`.
- `lib/app/injection.config.dart` — regenerado via `dart run build_runner build` para registrar as
  novas classes `@injectable`/`@LazySingleton`.
- `test/core/analytics/analytics_events_test.dart` — inclui `crm_reminder_triggered` na lista
  esperada da taxonomia.
- `docs/tasks/TASKS.md` — checkbox da TASK-152 marcado e progresso atualizado para 152/220.

## Deep link

Prioridade: `customerId` → `CustomerDetailRoute` (TASK-052, existe e é a tela de destino de quase
toda tarefa de CRM); senão `opportunityId` + `companyId` → `OpportunityCenterRoute` (TASK-132);
senão `NotificationCenterRoute` (sempre válida) como fallback, para nunca haver deep link quebrado.
Não existe hoje rota dedicada de detalhe de lead/oportunidade nem de lista de tarefas de CRM
(`CrmTaskListPage` não está registrada em `AppRouter`) — por isso o destino mais preciso disponível
é o cliente.

## Validações executadas

- `dart run build_runner build` (regenerar `injection.config.dart`).
- `dart format` nos arquivos alterados/criados.
- `flutter analyze` (projeto inteiro) — mesmos 12 avisos pré-existentes de sempre, nenhum novo.
- `flutter test test/features/crm test/core/analytics/analytics_events_test.dart` — todos passam
  (27 + 1 testes).
- `flutter test` (suíte completa) — 2 falhas, ambas confirmadas pré-existentes e não relacionadas
  (reproduzidas também com as mudanças desta task removidas via `git stash`):
  - `test/app/bootstrap_test.dart` — `PushDeviceMapper` não registrado no `GetIt` (lacuna de DI de
    TASK-150, alheia a esta task).
  - `test/core/analytics/analytics_events_test.dart` — falhava apenas até eu atualizar a lista
    esperada com o novo evento (correção incluída acima, teste passa depois).

## Riscos conhecidos e pendências

- **CRM local-only**: enquanto `CrmTask`/`CrmActivity` não tiverem repositório Firestore, o lembrete
  só é gerado quando o próprio dispositivo do responsável (ou do gestor, ao abrir a lista da
  equipe) roda `CrmTaskListBloc` — não há push proativo em background. Isso é uma limitação
  herdada da arquitetura atual (mesma de TASK-149), não introduzida por esta task.
- **Quiet hours temporário**: janela fixa 8h-18h, hora local do dispositivo, sem preferência por
  usuário — a ser substituída quando TASK-155 existir (ver decisão acima).
- **Preferências de comunicação (TASK-154)**: ainda não existem no código; portanto o lembrete
  sempre gera o registro interno (categoria `crm`) hoje. Quando TASK-154 implementar a
  desativação por categoria, `ProcessCrmTaskReminderUseCase` deve consultá-la antes de criar a
  notificação (e, especialmente, antes de qualquer envio de push futuro).
- **Push real (FCM)**: nenhuma notificação da aplicação (nem meta, nem CRM) dispara push de fato
  hoje — só popula a central interna. Enviar push real depende de uma Cloud Function usando
  `firebase-admin/messaging`, ainda não implementada em nenhum domínio.
- **Visibilidade de gestor**: cobre exatamente o que `CrmTaskListBloc.visibleResponsibleUserIds`/
  `canManageOthers` já expõe hoje; não foi criada nenhuma nova regra de visibilidade de equipe
  específica para lembretes.
