# TASK-061 — Concluida (2026-08-24)

## Resumo
Implementado o catalogo configuravel de motivos de ganho/perda por organizacao, com validacao obrigatoria nas transicoes terminais de oportunidade, seletor no funil, tela administrativa e agregacao simples por periodo para relatorios futuros.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- Subagente Harvey em modo somente leitura para checklist da TASK-061

## Arquivos criados
- `lib/features/opportunities/domain/value_objects/opportunity_outcome_type.dart`
- `lib/features/opportunities/domain/entities/opportunity_outcome_reason.dart`
- `lib/features/opportunities/domain/entities/opportunity_outcome_reason.freezed.dart`
- `lib/features/opportunities/domain/entities/opportunity_outcome_reason_usage.dart`
- `lib/features/opportunities/domain/repositories/opportunity_outcome_reason_repository.dart`
- `lib/features/opportunities/domain/usecases/create_opportunity_outcome_reason_use_case.dart`
- `lib/features/opportunities/domain/usecases/update_opportunity_outcome_reason_use_case.dart`
- `lib/features/opportunities/domain/usecases/deactivate_opportunity_outcome_reason_use_case.dart`
- `lib/features/opportunities/domain/usecases/list_opportunity_outcome_reasons_use_case.dart`
- `lib/features/opportunities/domain/usecases/list_top_opportunity_outcome_reasons_use_case.dart`
- `lib/features/opportunities/domain/usecases/opportunity_outcome_reason_use_case_helpers.dart`
- `lib/features/opportunities/data/dtos/opportunity_outcome_reason_dto.dart`
- `lib/features/opportunities/data/mappers/opportunity_outcome_reason_mapper.dart`
- `lib/features/opportunities/data/repositories/shared_preferences_opportunity_outcome_reason_repository.dart`
- `lib/features/opportunities/presentation/bloc/opportunity_outcome_reason_admin_bloc.dart`
- `lib/features/opportunities/presentation/bloc/opportunity_outcome_reason_admin_event.dart`
- `lib/features/opportunities/presentation/bloc/opportunity_outcome_reason_admin_state.dart`
- `lib/features/opportunities/presentation/pages/opportunity_outcome_reason_admin_page.dart`
- `test/features/opportunities/data/mappers/opportunity_outcome_reason_mapper_test.dart`
- `test/features/opportunities/domain/usecases/opportunity_outcome_reason_use_cases_test.dart`
- `test/features/opportunities/presentation/pages/opportunity_outcome_reason_admin_page_test.dart`

## Arquivos alterados
- `lib/app/injection.config.dart`
- `lib/features/opportunities/data/dtos/opportunity_dto.dart`
- `lib/features/opportunities/data/mappers/opportunity_mapper.dart`
- `lib/features/opportunities/data/repositories/shared_preferences_opportunity_repository.dart`
- `lib/features/opportunities/domain/entities/opportunity.dart`
- `lib/features/opportunities/domain/entities/opportunity.freezed.dart`
- `lib/features/opportunities/domain/usecases/mark_opportunity_won_use_case.dart`
- `lib/features/opportunities/domain/usecases/mark_opportunity_lost_use_case.dart`
- `lib/features/opportunities/opportunities.dart`
- `lib/features/opportunities/presentation/bloc/sales_pipeline_bloc.dart`
- `lib/features/opportunities/presentation/bloc/sales_pipeline_event.dart`
- `lib/features/opportunities/presentation/bloc/sales_pipeline_state.dart`
- `lib/features/opportunities/presentation/pages/sales_pipeline_page.dart`
- `test/features/opportunities/data/mappers/opportunity_mapper_test.dart`
- `test/features/opportunities/domain/usecases/mark_opportunity_won_use_case_test.dart`
- `test/features/opportunities/domain/usecases/mark_opportunity_lost_use_case_test.dart`
- `test/features/opportunities/presentation/bloc/sales_pipeline_bloc_test.dart`
- `test/features/opportunities/presentation/pages/sales_pipeline_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first: entidade e contratos no dominio, mapper/repositorio local em data, BLoCs e paginas na presentation. O funil carrega motivos ativos por organizacao e o dominio revalida o `reasonId` antes de fechar a oportunidade.

## Regras de negócio implementadas
- Motivos sao especificos por tipo (`won`/`lost`) e organizacao.
- Motivo de ganho nao fecha perda e motivo de perda nao fecha ganho.
- Motivo inativo nao pode ser selecionado em novas movimentacoes.
- Motivo historico permanece legivel via snapshot textual em `wonReason`/`lostReason`.
- Oportunidades fechadas guardam `wonReasonId`/`lostReasonId` e observacao opcional.
- Catalogo permite criar, editar descricao e desativar; exclusao fisica nao foi implementada.
- Agregacao conta motivos mais frequentes por periodo, tipo e `closedAt`.

## Regras Firebase implementadas
Nao houve alteracao em Firestore Rules, Storage Rules ou Cloud Functions nesta task. A implementacao local preserva escopo por `organizationId` e mantem o contrato para futura sincronizacao remota.

## Analytics implementado
Nao houve evento novo de analytics nesta task.

## Crashlytics implementado
Nao houve integracao nova com Crashlytics. Falhas seguem por `Failure` e estados de erro dos BLoCs.

## Impacto offline
O catalogo de motivos e os novos campos de oportunidade sao persistidos localmente via SharedPreferences, mantendo uso offline do funil.

## Impacto multi-tenant
Todas as consultas e chaves locais sao segmentadas por `organizationId`; o catalogo nao e compartilhado entre organizacoes.

## Testes criados
- Mapper de `OpportunityOutcomeReason`.
- Casos de uso do catalogo: criar, duplicidade, desativar/listar ativo/historico.
- Agregacao de motivos mais frequentes por periodo e tipo.
- Fechamento won/lost exigindo `reasonId`, validando tipo e inatividade.
- Tela administrativa de motivos com permissao, criacao e desativacao.
- Funil fechando oportunidade em estagio terminal com motivo ativo selecionado.

## Comandos executados
- `dart format .`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test test/features/opportunities`
- `flutter analyze`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` executado com sucesso: 929 arquivos analisados, 0 alterados.

## Resultado do analyzer
Primeira execucao apontou 3 infos de estilo, corrigidas. Execucao obrigatoria final: `flutter analyze` sem issues.

## Resultado dos testes
`flutter test test/features/opportunities` executado com sucesso: 67 testes passaram. `flutter test` completo executado com sucesso: 1305 testes passaram.

## Decisões técnicas
- Novos campos em `Opportunity` foram opcionais para preservar compatibilidade com registros antigos que tinham apenas motivo em texto livre.
- O snapshot textual do motivo foi mantido para leitura historica mesmo se o catalogo for editado/desativado.
- `Capability.pipelineStageManage` foi reutilizada para administrar motivos, por representar o mesmo escopo operacional OWNER/ADMIN/SALES_MANAGER do funil.
- A agregacao usa o repositorio atual de oportunidades e inclui motivos inativos para manter relatorios historicos.

## Riscos conhecidos
- Persistencia remota e regras Firebase especificas para o catalogo ainda dependem de uma task futura de sincronizacao/Rules.
- A pagina administrativa foi criada e exportada, mas a rota definitiva depende da navegacao de configuracoes.

## Pendências
- Integrar a tela de motivos ao menu/rota de configuracoes quando esse fluxo for priorizado.
- Implementar sincronizacao remota/Rules/Functions especificas do catalogo em backlog futuro.

## Evidências
- Analyzer final sem issues.
- Suite focada de oportunidades passou.
- Suite completa Flutter passou com 1305 testes.

## Commit
Pendente ate a criacao do commit local desta task.

## Push
Nao autorizado pelo usuario nesta rodada (`sem push`).

## Hash do commit
Pendente ate a criacao do commit local desta task.

## Branch
`main`
