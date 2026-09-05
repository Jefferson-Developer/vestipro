# TASK-149 — Implementar agendamento de relatórios — CONCLUÍDA

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Depende de:** TASK-144 (construtor de relatórios), TASK-145 (visualizações salvas), TASK-146/147/148
(exportação CSV/XLSX/PDF), TASK-015 (Cloud Functions)

## Resumo

Implementado o agendamento periódico (diário/semanal/mensal) de uma `SavedReport` (TASK-145): o usuário
autorizado configura frequência, horário, formato de exportação (CSV/XLSX/PDF, reaproveitando os
encoders já existentes das TASK-146/147/148) e destinatários; uma Cloud Function agendada
(`runReportSchedules`) executa o ciclo, gera o arquivo por destinatário reavaliando o RBAC de cada um
independentemente e registra o resultado (sucesso/falha) de forma nunca silenciosa.

## Modelo de dados

- `organizations/{organizationId}/reportSchedules/{scheduleId}` — `savedReportId`/`savedReportName`
  (denormalizado), `frequency` (`daily`/`weekly`/`monthly`), `weekday`/`dayOfMonth` (conforme
  frequência), `hour`/`minute` (sempre interpretados em `America/Sao_Paulo`, UTC-3 fixo — Brasil não
  observa horário de verão desde 2019), `format`/`locale`, `recipientUserIds`, `status`
  (`active`/`paused`), `nextRunAt`, `lastRunAt`/`lastRunCycleKey`/`lastRunStatus`/`lastRunError`,
  auditoria e `version`.
- `organizations/{organizationId}/reportScheduleDeliveries/{deliveryId}` — log append-only de uma
  entrega por destinatário por ciclo (`status`: `delivered`/`failed`/`skipped`, `reason`, `downloadUrl`,
  `expiresAt`, `rowCount`). Serve como histórico de falhas/sucesso visível ao criador (via capability
  `report.schedule`) e ao próprio destinatário, e é o ponto de extensão que a futura TASK-151 (Central
  de Notificações, ainda não implementada) deverá consumir como fila de "notificação interna" — não
  existe hoje envio por e-mail (nenhuma infraestrutura de e-mail existe no projeto ainda; nenhuma
  dependência de e-mail foi adicionada para não simular um canal que não funciona de verdade).

## Arquivos criados

Flutter:
- `lib/features/reports/domain/entities/report_schedule.dart`
- `lib/features/reports/domain/services/report_schedule_next_run_calculator.dart` (cálculo puro de
  `nextRunAt`/`cycleKeyFor`, espelhado 1:1 em `functions/src/reports/report-schedules-shared.ts`)
- `lib/features/reports/domain/services/firestore_report_schedule_reference_checker.dart` (substitui o
  placeholder `NoActiveScheduleReportScheduleReferenceChecker` da TASK-145, agora removido)
- `lib/features/reports/domain/repositories/report_schedule_repository.dart`
- `lib/features/reports/domain/usecases/report_schedule_use_cases.dart`
  (`CreateReportSchedule`, `PauseReportSchedule`, `DeleteReportSchedule`, `ListReportSchedules`)
- `lib/features/reports/data/dtos/report_schedule_dto.dart`
- `lib/features/reports/data/datasources/report_schedule_remote_data_source.dart` +
  `firestore_report_schedule_remote_data_source.dart`
- `lib/features/reports/data/repositories/report_schedule_repository_impl.dart`
- `lib/features/reports/presentation/bloc/report_schedules_{bloc,event,state}.dart`
- `lib/features/reports/presentation/pages/report_schedules_page.dart` (tela mínima: listar, criar via
  diálogo, pausar, excluir)

Cloud Functions:
- `functions/src/reports/report-schedules-shared.ts` (`computeNextRunAt`, `cycleKeyFor` — puro, sem
  `firebase-admin`, testável sem Emulator)
- `functions/src/reports/run-report-schedules.ts` (`onSchedule`, a cada 15 minutos,
  `southamerica-east1`/`America/Sao_Paulo`): reivindica (transação) cada ciclo vencido, avançando
  `nextRunAt`/`lastRunCycleKey` antes de qualquer entrega (idempotência: um retry do Cloud Scheduler
  nunca reprocessa o mesmo ciclo), depois entrega a cada destinatário reexecutando
  `runReportAggregation` sob o role/escopo *do destinatário*, nunca do criador — respeitando
  `REPORT_ROLES`/`REPORT_EXPORT_ROLES` já definidos nas tasks anteriores.

Testes:
- `test/features/reports/domain/services/report_schedule_next_run_calculator_test.dart`
- `test/features/reports/domain/usecases/report_schedule_use_cases_test.dart`
- `functions/test/reports/report-schedules-shared.test.ts`
- Testes de `firestore.rules` (positivos/negativos) adicionados em
  `firestore-tests/firestore.rules.test.js` para `reportSchedules` e `reportScheduleDeliveries`.

## Arquivos alterados

- `lib/core/permissions/capability.dart` e `role_permission_matrix.dart` — nova `Capability.reportSchedule`
  (`report.schedule`), concedida a OWNER/ADMIN/SALES_MANAGER.
- `lib/core/analytics/analytics_events.dart` — `report_schedule_created`/`_paused`/`_deleted`.
- `lib/features/reports/domain/services/report_schedule_reference_checker.dart` — assinatura passa a
  exigir `organizationId` (o único call site, `DeleteSavedReport`, já tinha esse valor em mãos).
- `lib/features/reports/domain/usecases/saved_report_use_cases.dart` — `DeleteSavedReport` agora chama
  a verificação real de agendamento ativo (antes sempre resolvia `false`).
- `lib/features/reports/reports.dart` — novos exports no barrel.
- `functions/src/reports/index.ts` e `functions/src/index.ts` — export de `runReportSchedules`.
- `firestore.rules` — `roleHasCapability` ganha `'report.schedule'` para `SALES_MANAGER`; novos blocos
  `match /reportSchedules/{scheduleId}` e `match /reportScheduleDeliveries/{deliveryId}`.
- `firestore-tests/firestore.rules.test.js` — helpers `reportScheduleDoc`/`reportScheduleDeliveryDoc` e
  os novos `describe` blocks.
- `test/core/analytics/analytics_events_test.dart`, `test/core/permissions/role_permission_matrix_test.dart`,
  `test/features/reports/domain/usecases/saved_report_use_cases_test.dart`,
  `test/features/reports/presentation/bloc/saved_reports_bloc_test.dart` — ajustados à nova assinatura/
  novos eventos/capability.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (novos registros DI, remoção do
  binding do placeholder).

## Decisões técnicas

- **Idempotência via "claim antes de executar".** A Cloud Function reivindica o ciclo (avança
  `nextRunAt`, grava `lastRunCycleKey`) dentro de uma transação, *antes* de gerar qualquer exportação —
  garantindo que nenhum retry do Cloud Scheduler duplica envio, mesmo que a geração/entrega em si
  falhe no meio do caminho (o ciclo é perdido, nunca duplicado — trade-off deliberado e documentado no
  código).
- **RBAC do destinatário, nunca do criador.** Cada entrega reexecuta `runReportAggregation` com o
  `roleName`/`teamIds` reais do destinatário no momento do envio; um destinatário inativo, sem
  `REPORT_ROLES` ou sem `REPORT_EXPORT_ROLES` é pulado e registrado como `skipped`, nunca recebe dado
  fora do próprio escopo.
- **Falha nunca silenciosa.** Falha de um destinatário não aborta os demais; o resultado agregado do
  ciclo (`success`/`partialFailure`/`failure`) fica em `ReportSchedule.lastRunStatus`/`lastRunError`,
  visível na lista de agendamentos.
- **Sem canal de e-mail simulado.** Como não existe nenhuma infraestrutura de e-mail no projeto (nem
  TASK-150/TASK-151 ainda existem), a "entrega" é o arquivo gerado em Storage (mesmo padrão de link
  assinado das TASK-146/147/148) + um registro em `reportScheduleDeliveries`, documentado como a fila
  que a futura Central de Notificações deverá consumir.
- **`firestore.rules`: campos de agendamento sempre presentes (mesmo `null`).** `unchanged(field)` usa
  indexação por colchetes, que falha se a chave não existir — por isso o DTO grava
  `weekday`/`dayOfMonth`/`lastRunAt`/`lastRunCycleKey`/`lastRunStatus`/`lastRunError` sempre, mesmo
  quando `null`, nunca omitindo a chave condicionalmente.

## Validações executadas

- `dart run build_runner build --delete-conflicting-outputs` (regenerou `injection.config.dart` com
  sucesso).
- `flutter analyze` (repositório inteiro) — 0 erros; apenas avisos pré-existentes não relacionados.
- `flutter test` (suíte completa, 2828 testes) — todos passando.
- `dart format` no escopo tocado — sem pendências.
- `cd functions && npm run build` (tsc) — sem erros.
- `cd functions && npx eslint src/reports/run-report-schedules.ts src/reports/report-schedules-shared.ts
  test/reports/report-schedules-shared.test.ts` — sem apontamentos.
- `cd functions && npx jest test/reports` — 6 suítes, 44 testes, todos passando (incluindo os 8 novos
  testes de `computeNextRunAt`/`cycleKeyFor`).

## Pendência conhecida (não foi possível validar nesta rodada)

- Os testes de `firestore.rules` para `reportSchedules`/`reportScheduleDeliveries` foram escritos em
  `firestore-tests/firestore.rules.test.js` (positivos e negativos, seguindo exatamente o padrão já
  usado para `savedReports`) e revisados manualmente linha a linha contra as regras escritas, mas **não
  puderam ser executados** neste ambiente: `firebase emulators:exec --only firestore` requer Java, que
  não está instalado nesta máquina (`Could not spawn java -version`). Antes do próximo deploy, rodar:
  ```
  firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
  ```
  em um ambiente com Java disponível, para confirmar as regras na prática.
- Não existe nesta task uma tela para visualizar o histórico de entregas
  (`reportScheduleDeliveries`) — apenas gestão do agendamento em si (criar/pausar/excluir), conforme o
  escopo literal da task ("tela mínima de gestão de agendamentos"). Um histórico de entregas navegável
  fica como possível follow-up, natural de integrar com a TASK-151 (Central de Notificações).
