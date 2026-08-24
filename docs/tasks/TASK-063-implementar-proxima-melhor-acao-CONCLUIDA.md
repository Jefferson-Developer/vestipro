# TASK-063 — Concluída (2026-08-24)

## Resumo
- Implementada recomendação inicial de próxima melhor ação baseada em regras explicáveis para CRM.
- O detalhe 360 do cliente agora exibe um card acionável quando houver recomendação.
- Criado widget reutilizável para a futura home do representante consumir a mesma lista de ações.

## Agentes utilizados
- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- Subagente Codex `Avicenna` para checagem read-only da task e riscos.

## Arquivos criados
- `lib/features/crm/domain/entities/next_best_action.dart`
- `lib/features/crm/domain/entities/next_best_action_context.dart`
- `lib/features/crm/domain/services/next_best_action_service.dart`
- `lib/features/crm/domain/usecases/list_pending_tasks_for_customer_use_case.dart`
- `lib/features/crm/domain/value_objects/next_best_action_priority.dart`
- `lib/features/crm/domain/value_objects/next_best_action_type.dart`
- `lib/features/crm/presentation/widgets/next_best_action_card.dart`
- `test/features/crm/domain/services/next_best_action_service_test.dart`
- `test/features/crm/presentation/widgets/next_best_action_card_test.dart`
- `docs/tasks/TASK-063-implementar-proxima-melhor-acao-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md`
- `lib/app/injection.config.dart`
- `lib/features/crm/crm.dart`
- `lib/features/customers/presentation/bloc/customer_detail_bloc.dart`
- `lib/features/customers/presentation/bloc/customer_detail_state.dart`
- `lib/features/customers/presentation/pages/customer_detail_page.dart`
- `test/features/customers/presentation/pages/customer_detail_page_test.dart`

## Arquitetura utilizada
- Clean Architecture feature-first.
- Regras no domínio CRM em `NextBestActionService`.
- BLoC do detalhe 360 orquestra carregamento de cliente, atividades e tarefas vencidas.
- UI renderiza o contrato `NextBestAction` sem hardcode das regras comerciais.
- Serviço desenhado para permitir troca futura por engine de insights da TASK-121 mantendo o contrato de apresentação.

## Regras de negócio implementadas
- Cliente sem contato há mais de 30 dias sugere ligação.
- Health score em risco sugere visita consultiva.
- Follow-up/tarefa vencida sugere concluir ou reagendar.
- Prioridade inicial: follow-up vencido, health score em risco, sem contato.
- Toda recomendação gerada carrega ação sugerida, motivo, evidência, cliente e prioridade.
- Vendedor não recebe recomendação para cliente fora da própria carteira; gestor/equivalente usa permissão de gestão de time.
- Linguagem neutra, sem falsa urgência.

## Regras Firebase implementadas
- Nenhuma regra Firebase nova nesta task.
- A recomendação usa dados já disponíveis no cliente e nos repositórios CRM existentes.

## Analytics implementado
- Nenhum evento novo.
- O CTA de registrar atividade reutiliza o fluxo existente, que já registra `crmActivityCreated`.

## Crashlytics implementado
- Nenhuma alteração de Crashlytics.

## Impacto offline
- Recomendações são calculadas em leitura a partir de dados locais/cacheados de cliente, atividades CRM e tarefas.
- O CTA de ligação/visita abre o registro de atividade existente, preservando comportamento offline/pending sync.

## Impacto multi-tenant
- Regras filtram por `organizationId` e `customerId`.
- Tarefas pendentes são filtradas por tenant, cliente e responsável quando o usuário não gerencia outros.
- A recomendação respeita carteira/RBAC antes de ser exibida.

## Testes criados
- Unitários para regras de sem contato, limite de data, health score em risco, follow-up vencido e RBAC/carteira.
- Widget test para `NextBestActionCard` cobrindo motivo, evidência, prioridade e CTA.
- Teste do detalhe 360 cobrindo abertura do sheet pre-preenchido pelo CTA.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format` focado nos arquivos alterados
- `flutter test test\features\crm\domain\services\next_best_action_service_test.dart test\features\crm\presentation\widgets\next_best_action_card_test.dart test\features\customers\presentation\pages\customer_detail_page_test.dart`
- `flutter analyze`
- `dart format --set-exit-if-changed .`
- `flutter test`

## Resultado do formatter
- Formatter focado passou.
- Formatter final: `Formatted 942 files (0 changed)`.

## Resultado do analyzer
- Analyzer intermediário apontou import não usado e lints de coleção nula; corrigido.
- Analyzer final: `No issues found!`.

## Resultado dos testes
- Testes focados finais: 12 testes passaram.
- Suite completa Flutter: 1318 testes passaram.

## Decisões técnicas
- Recomendação não foi persistida; é calculada sob demanda para funcionar offline e simplificar a troca futura por insights.
- O contrato `NextBestAction` inclui `suggestedAction`, `reason`, `evidence`, `customerId`, `customerName`, `priority`, `relatedTaskId` e `suggestedActivityType`.
- O card usa rótulos compactos em largura estreita para evitar overflow em mobile.
- Como ainda não existe rota/tela real de home do representante, foi criado e exportado `RepresentativeNextBestActionSection` para integração futura sem mudar o contrato.

## Riscos conhecidos
- A home do representante ainda não existe no roteamento atual; a seção reutilizável está pronta, mas não há tela real onde conectá-la.
- O CTA de follow-up vencido não navega para uma tarefa específica porque ainda não há rota tipada de tarefas/follow-ups no `AppRouter`.
- Enquanto atividades/tarefas forem predominantemente locais, recomendações refletem o melhor estado offline disponível no dispositivo.

## Pendências
- Integrar `RepresentativeNextBestActionSection` à home do representante quando a rota/tela existir.
- Criar deep link/rota tipada para tarefas CRM para resolver follow-ups diretamente pelo card.

## Evidências
- `dart format --set-exit-if-changed .` passou sem alterações.
- `flutter analyze` passou sem issues.
- `flutter test` completo passou com 1318 testes.
- Backlog atualizado para `63 / 220 tasks concluídas`.

## Commit
Pendente até a criação do commit local desta task.

## Push
Não autorizado pelo usuário nesta rodada (`sem push`).

## Hash do commit
Pendente até a criação do commit local desta task.

## Branch
`main`
