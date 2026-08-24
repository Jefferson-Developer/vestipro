# TASK-059 — Concluída (2026-08-24)

## Resumo

Implementadas atividades CRM vinculadas a cliente/lead/oportunidade, com registro rápido no detalhe
do cliente 360, timeline cronológica paginada, persistência local offline via `SharedPreferences` e
evento de Analytics `crm_activity_created`. A timeline usa um componente reutilizável do Design
System (`AppTimeline`) e mostra ícones por tipo, status de sync pendente e suporte visual para
follow-ups vencidos (placeholder consumível pela TASK-060).

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/design_system/components/timeline/app_timeline.dart`
- `lib/features/crm/crm.dart`
- `lib/features/crm/data/mappers/crm_activity_mapper.dart`
- `lib/features/crm/data/repositories/shared_preferences_crm_activity_repository.dart`
- `lib/features/crm/domain/entities/crm_activity.dart`
- `lib/features/crm/domain/entities/crm_activity_page_result.dart`
- `lib/features/crm/domain/repositories/crm_activity_repository.dart`
- `lib/features/crm/domain/usecases/crm_activity_use_case_helpers.dart`
- `lib/features/crm/domain/usecases/list_crm_activities_for_customer_use_case.dart`
- `lib/features/crm/domain/usecases/list_crm_activities_for_lead_use_case.dart`
- `lib/features/crm/domain/usecases/list_crm_activities_for_opportunity_use_case.dart`
- `lib/features/crm/domain/usecases/register_crm_activity_use_case.dart`
- `lib/features/crm/domain/value_objects/crm_activity_sync_status.dart`
- `lib/features/crm/domain/value_objects/crm_activity_type.dart`
- `lib/features/crm/presentation/widgets/crm_activity_timeline.dart`
- `test/features/crm/data/repositories/shared_preferences_crm_activity_repository_test.dart`
- `test/features/crm/domain/usecases/register_crm_activity_use_case_test.dart`
- `test/features/crm/presentation/widgets/crm_activity_timeline_test.dart`

## Arquivos alterados

- `lib/app/injection.config.dart`
- `lib/core/design_system/components/components.dart`
- `lib/features/customers/presentation/bloc/customer_detail_bloc.dart`
- `lib/features/customers/presentation/bloc/customer_detail_event.dart`
- `lib/features/customers/presentation/bloc/customer_detail_state.dart`
- `lib/features/customers/presentation/pages/customer_detail_page.dart`
- `test/features/customers/presentation/pages/customer_detail_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

Clean Architecture feature-first: domínio (`CrmActivity`, value objects, contratos e casos de uso),
data (`SharedPreferencesCrmActivityRepository` + mapper) e presentation (`CrmActivityTimeline` e
integração no `CustomerDetailBloc`/`CustomerDetailPage`). A UI não acessa storage diretamente; o
detalhe do cliente fala com use cases via BLoC.

## Regras de negócio implementadas

- Atividade exige pelo menos um vínculo (`customerId`, `leadId` ou `opportunityId`).
- Autor é sempre o `userId` autenticado recebido pelo fluxo do detalhe do cliente.
- Timeline de cliente ordena do mais recente para o mais antigo e suporta paginação por cursor.
- Atividade criada offline fica com `CrmActivitySyncStatus.pending`.
- Formulário rápido não permite descrição vazia.

## Regras Firebase implementadas

Nenhuma regra Firebase nova. A persistência desta task é local/offline, seguindo o padrão já usado em
clientes/leads/oportunidades até o motor de sync/outbox do EPIC-14.

## Analytics implementado

Evento `AnalyticsEvents.crmActivityCreated` com `organization_id`, `customer_id`, `activity_id`,
`activity_type` e `sync_status`, sem dados pessoais ou texto livre da atividade.

## Crashlytics implementado

Nenhuma integração nova. Falhas seguem o fluxo central de `AppFailure`/`UnexpectedFailure`.

## Impacto offline

Atividades são gravadas em `SharedPreferences` por organização e sobrevivem à reinicialização do app.
O status `pending` deixa o registro pronto para futura Outbox/sync.

## Impacto multi-tenant

Leituras e gravações são escopadas por `organizationId`. O repositório usa uma chave local por
organização e os use cases validam o tenant antes de consultar.

## Testes criados

- Caso de uso: vínculo obrigatório e criação pendente com autor autenticado.
- Repositório: ordenação cronológica, paginação e persistência offline.
- Widget: ícone por tipo, sync pendente e destaque de follow-up vencido.
- Página do detalhe do cliente: registro rápido cria atividade vinculada ao cliente e registra
  Analytics.

## Comandos executados

```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/crm/domain/usecases/register_crm_activity_use_case_test.dart test/features/crm/data/repositories/shared_preferences_crm_activity_repository_test.dart test/features/crm/presentation/widgets/crm_activity_timeline_test.dart test/features/customers/presentation/pages/customer_detail_page_test.dart
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` — 889 arquivos verificados, 0 alterações, exit code 0.

## Resultado do analyzer

`flutter analyze` — `No issues found!`.

## Resultado dos testes

`flutter test` — suíte completa com **1290 testes, todos passando**.

## Decisões técnicas

- Mantida persistência local com `SharedPreferences`, consistente com os módulos já entregues.
- Criado `AppTimeline` no Design System para a timeline ser reutilizável, e `CrmActivityTimeline`
  adapta atividades CRM para esse componente.
- A seção de timeline no detalhe do cliente falha de forma isolada: erro ao listar atividades não
  derruba os dados cadastrais do cliente.
- Uma implementação paralela gerada por subagente em `lib/features/crm_activities` foi removida por
  duplicar contratos e depender de arquivos `freezed` inexistentes.

## Riscos conhecidos

- Ainda não há Outbox/sync remoto real; conflitos entre dispositivos serão resolvidos em EPIC-14.
- Anexos são modelados como URLs, mas upload/Storage não faz parte desta task.
- Timeline de lead/oportunidade tem casos de uso e repositório, mas ainda não foi conectada em telas.

## Pendências

- Integrar atividades em telas específicas de lead e oportunidade quando essas rotas/telas existirem.
- TASK-060 consumirá o suporte visual de follow-up vencido com tarefas reais.

## Evidências

Saídas de `flutter analyze` (`No issues found!`) e `flutter test` (`All tests passed!`) capturadas
durante a execução.

## Commit

Ver hash abaixo.

## Push

Não realizado por solicitação do usuário: lote autorizado **sem push**.

## Hash do commit

Ver seção de commit desta task na resposta final.

## Branch

`main`
