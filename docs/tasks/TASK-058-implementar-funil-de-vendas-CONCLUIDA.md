# TASK-058 — Concluída (2026-08-24)

## Resumo

Implementado o funil de vendas configurável por organização (EPIC-07): estágios (`PipelineStage`)
administráveis (criar/reordenar/renomear), uma página `SalesPipelinePage` com board de
drag-and-drop na Web e lista agrupada com ação explícita "Mover" no mobile, e uma página
`PipelineStageAdminPage` para a administração dos estágios. As duas plataformas movem oportunidades
através do mesmo `SalesPipelineBloc`/mesmos casos de uso de domínio — nenhuma lógica de negócio
duplicada entre Web e mobile. Mover uma oportunidade para um estágio terminal (ganho/perdido) é
bloqueado como movimentação simples e sempre passa pelo fluxo de motivo obrigatório
(`MarkOpportunityWonUseCase`/`MarkOpportunityLostUseCase`).

TASK-057 havia modelado `Opportunity` apenas com um repositório contrato (sem implementação
concreta). Esta task também entrega a primeira implementação concreta de `OpportunityRepository`
(`SharedPreferencesOpportunityRepository`), necessária para o funil poder listar oportunidades.

## Agentes utilizados

- `flutter-senior-architect` (domínio, dados, BLoC, RBAC, testes)
- `flutter-ui-design-specialist` (Design System, responsividade Web/mobile, estados de UI)

## Arquivos criados

Domínio:

- `lib/features/opportunities/domain/value_objects/pipeline_stage_terminal_type.dart`
- `lib/features/opportunities/domain/entities/pipeline_stage.dart` (+ `.freezed.dart` gerado)
- `lib/features/opportunities/domain/entities/pipeline_column.dart`
- `lib/features/opportunities/domain/pipeline_board_builder.dart`
- `lib/features/opportunities/domain/repositories/pipeline_stage_repository.dart`
- `lib/features/opportunities/domain/usecases/pipeline_stage_use_case_helpers.dart`
- `lib/features/opportunities/domain/usecases/create_pipeline_stage_use_case.dart`
- `lib/features/opportunities/domain/usecases/rename_pipeline_stage_use_case.dart`
- `lib/features/opportunities/domain/usecases/reorder_pipeline_stages_use_case.dart`
- `lib/features/opportunities/domain/usecases/list_pipeline_stages_use_case.dart`
- `lib/features/opportunities/domain/usecases/list_pipeline_opportunities_use_case.dart`

Dados:

- `lib/features/opportunities/data/dtos/pipeline_stage_dto.dart`
- `lib/features/opportunities/data/mappers/pipeline_stage_mapper.dart`
- `lib/features/opportunities/data/repositories/shared_preferences_pipeline_stage_repository.dart`
- `lib/features/opportunities/data/repositories/shared_preferences_opportunity_repository.dart`

Apresentação:

- `lib/features/opportunities/presentation/bloc/sales_pipeline_event.dart`
- `lib/features/opportunities/presentation/bloc/sales_pipeline_state.dart`
- `lib/features/opportunities/presentation/bloc/sales_pipeline_bloc.dart`
- `lib/features/opportunities/presentation/bloc/pipeline_stage_admin_event.dart`
- `lib/features/opportunities/presentation/bloc/pipeline_stage_admin_state.dart`
- `lib/features/opportunities/presentation/bloc/pipeline_stage_admin_bloc.dart`
- `lib/features/opportunities/presentation/pages/pipeline_stage_admin_page.dart`
- `lib/features/opportunities/presentation/pages/sales_pipeline_page.dart`

Testes:

- `test/features/opportunities/domain/pipeline_board_builder_test.dart`
- `test/features/opportunities/domain/usecases/create_pipeline_stage_use_case_test.dart`
- `test/features/opportunities/domain/usecases/reorder_pipeline_stages_use_case_test.dart`
- `test/features/opportunities/presentation/bloc/sales_pipeline_bloc_test.dart`
- `test/features/opportunities/presentation/pages/sales_pipeline_page_test.dart`
- `test/features/opportunities/presentation/pages/pipeline_stage_admin_page_test.dart`

## Arquivos alterados

- `lib/features/opportunities/domain/repositories/opportunity_repository.dart` — adiciona
  `listByOrganization` (necessário para o board agrupar por estágio).
- `lib/features/opportunities/domain/usecases/update_opportunity_stage_use_case.dart` — anotado
  `@injectable`; doc atualizada explicando que nunca decide sozinho sobre estágio terminal.
- `lib/features/opportunities/domain/usecases/mark_opportunity_won_use_case.dart` /
  `mark_opportunity_lost_use_case.dart` — novo parâmetro opcional `stageId` (move a oportunidade
  para o estágio terminal no mesmo update que fecha o negócio); anotados `@injectable`.
- `lib/features/opportunities/opportunities.dart` — novos exports do barril público.
- `lib/core/permissions/capability.dart` — novas capabilities `opportunityView`,
  `opportunityManage`, `pipelineStageManage`.
- `lib/core/permissions/role_permission_matrix.dart` — concede as novas capabilities a
  `SALES_MANAGER`/`SALES_REP` (`opportunityView`/`opportunityManage`) e `pipelineStageManage` só a
  `SALES_MANAGER` (OWNER/ADMIN já têm tudo pelo conjunto completo/quase completo).
- `lib/app/injection.config.dart` — regenerado (`build_runner`) com os novos registros de DI.
- `test/features/opportunities/domain/usecases/mark_opportunity_won_use_case_test.dart` /
  `mark_opportunity_lost_use_case_test.dart` — novo caso cobrindo o parâmetro `stageId`.
- `docs/tasks/TASKS.md` — checkbox da TASK-058 marcado e progresso atualizado.

## Arquitetura utilizada

Clean Architecture feature-first, seguindo exatamente o precedente de `leads`/`customers`:
`domain` (entidades freezed, value objects, casos de uso, `pipeline_board_builder.dart` como função
pura testável isoladamente) → `data` (DTO Firestore-shaped + mapper + repositório local
`SharedPreferences`, mesmo padrão de `SharedPreferencesLeadRepository`, usado como stand-in até o
motor de sync/outbox de EPIC-14) → `presentation` (BLoC + página), com DI via `injectable`/`get_it`.

`SalesPipelineBloc` é o único ponto de entrada de domínio para mover uma oportunidade — tanto o
board Web (drag-and-drop) quanto a lista mobile (ação "Mover") despacham os mesmos eventos
(`SalesPipelineOpportunityMoveRequested` / `SalesPipelineOpportunityClosedWithReason`), evitando
qualquer duplicação de regra entre plataformas.

## Regras de negócio implementadas

- Estágio (`PipelineStage`) é escopado por `organizationId`, com `order` denso (0-based) sempre
  mantido contíguo, `colorHex` validado (`#RRGGBB`) e `terminalType` (`none`/`won`/`lost`) imutável
  após a criação.
- No máximo um estágio `won` e um `lost` por organização (`CreatePipelineStageUseCase` rejeita
  duplicidade).
- Renomear/reordenar/criar estágio é ação administrativa: gated por `Capability.pipelineStageManage`
  (OWNER/ADMIN/SALES_MANAGER).
- Mover uma oportunidade para um estágio **não terminal** usa `UpdateOpportunityStageUseCase`
  (sem tocar `status`); `SalesPipelineBloc` bloqueia essa mesma ação quando o estágio-alvo é
  terminal, retornando falha (`opportunity_move_requires_reason`) sem chamar nenhum caso de uso.
- Mover para um estágio terminal exige motivo e passa por `MarkOpportunityWonUseCase`/
  `MarkOpportunityLostUseCase`, que agora também atualizam `stageId` no mesmo update.
- Contagem/valor "ativo" por coluna: estágio normal soma apenas oportunidades com `status == open`;
  estágio terminal soma apenas as que já têm o status coincidente (`won`/`lost`) — nunca todas as
  que historicamente carregam aquele `stageId`.

## Regras Firebase implementadas

Nenhuma nova regra de Firestore/Storage/Functions nesta task — `PipelineStage`/`Opportunity`
continuam com persistência local (`SharedPreferences`) como stand-in, seguindo o precedente já
aceito em TASK-055/TASK-056/TASK-048 até o motor de sync (EPIC-14). O DTO (`PipelineStageDto`)
já está no formato Firestore-shaped para quando a coleção
`organizations/{organizationId}/pipelineStages/{stageId}` for implementada.

## Analytics implementado

Nenhum evento de Analytics novo nesta task (fora do escopo declarado da task; nenhum evento
comercial mínimo documentado em `AGENTS.md` cobre "mover oportunidade" nesta primeira versão).

## Crashlytics implementado

Nenhuma instrumentação nova — os `AppFailure`/exceptions seguem o mesmo caminho já coberto pelo
`ExceptionMapper`/`ErrorReportingPolicy` central existente.

## Impacto offline

`SharedPreferencesOpportunityRepository`/`SharedPreferencesPipelineStageRepository` persistem
localmente e sobrevivem ao fechamento do app, com `Opportunity.syncStatus = pending` após cada
mutação (mesmo padrão de Lead/Customer). Um motor de sync real ainda não existe (EPIC-14):
esta task não piora nem resolve isso, apenas segue o precedente já aceito no restante do CRM.

## Impacto multi-tenant

Toda leitura/escrita é sempre escopada por `organizationId` explícito, nunca inferido do estado da
UI. `listByOrganization` (Opportunity/PipelineStage) filtra estritamente pelo `organizationId`
informado.

## Testes criados

- `pipeline_board_builder_test.dart`: ordenação por `order`, regra de "ativo" por estágio
  normal/terminal, agrupamento por `stageId`.
- `create_pipeline_stage_use_case_test.dart`: `order` sequencial, `colorHex` inválido, duplicidade
  de estágio terminal.
- `reorder_pipeline_stages_use_case_test.dart`: conjunto de ids parcial/desconhecido rejeitado sem
  tocar o repositório.
- `mark_opportunity_won_use_case_test.dart` / `mark_opportunity_lost_use_case_test.dart`: novo caso
  cobrindo `stageId`.
- `sales_pipeline_bloc_test.dart` (**teste obrigatório**): carga inicial monta colunas; **bloqueia
  movimentação direta para estágio terminal sem motivo** (não chama nenhum caso de uso); fecha com
  motivo via `MarkOpportunityWonUseCase`.
- `sales_pipeline_page_test.dart` (**testes obrigatórios**): RBAC (`ForbiddenPage` sem
  `opportunity.view`); **drag-and-drop no Web** movendo o card e atualizando contagem/valor das duas
  colunas; **ação explícita "Mover" no mobile** (sem gesto) com o mesmo resultado.
- `pipeline_stage_admin_page_test.dart` (**teste obrigatório de RBAC**): usuário sem
  `pipelineStage.manage` vê `ForbiddenPage` e nenhum controle de criar/reordenar/renomear é
  renderizado; `SALES_MANAGER` vê os controles.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` — reformatou os arquivos recém-criados (quebras de linha) na
primeira execução; segunda execução sem alterações pendentes (exit code 0).

## Resultado do analyzer

`flutter analyze` — `No issues found!` (projeto inteiro, 0 erros/warnings/infos).

## Resultado dos testes

`flutter test` (suíte completa do projeto) — **1284 testes, todos passando**, incluindo os 6 novos
arquivos de teste desta task e os 2 arquivos de teste existentes estendidos
(`mark_opportunity_won_use_case_test.dart`, `mark_opportunity_lost_use_case_test.dart`). Nenhuma
regressão em `role_permission_matrix_test.dart` (que faz asserção exata do conjunto de capabilities
de `SALES_ASSISTANT`) nem em qualquer outro teste existente.

## Decisões técnicas

- **Visibilidade "carteira/equipe" simplificada**: em vez de replicar o `PortfolioVisibilityService`
  completo (usado por `customers`), o funil segue o precedente mais simples de `ListLeadsUseCase`
  (TASK-056): `responsibleUserIds` é apenas um filtro explícito passado pelo chamador, sem resolução
  automática de escopo por papel. Documentado como decisão consciente (ver "Pendências").
- **`terminalType` imutável após criação**: `RenamePipelineStageUseCase` só edita `name`/`colorHex`,
  nunca `terminalType`, para nunca reinterpretar retroativamente oportunidades já fechadas naquele
  estágio.
- **"Ativo" por coluna depende do tipo do estágio**: coluna normal conta `status == open`; coluna
  terminal conta apenas o status coincidente (`won`/`lost`) — nunca todas as oportunidades com aquele
  `stageId`, para não inflar/zerar indevidamente após reaberturas futuras.
- **Reordenação da tela de admin usa `ReorderableListView` nativo** (drag padrão do Flutter,
  funciona em mobile e Web) — a exigência de "sem gesto" do TASK-058 é especificamente sobre mover
  **oportunidades** no board, não sobre a tela administrativa de estágios.
- **Paleta de cores fechada** (8 predefinidas) em vez de campo hex livre, para garantir contraste
  legível nos dois temas do Design System.

## Riscos conhecidos

- Sem um motor de sync real (EPIC-14), conflitos concorrentes de reordenação/edição de estágio entre
  dois administradores offline não são resolvidos além do "last write wins" implícito do
  `SharedPreferences` local — mesmo risco já aceito para `Lead`/`Customer`.
- Nenhuma tela ainda cria `Opportunity` diretamente (só `ConvertLeadToOpportunityUseCase`, de
  TASK-055/057, e agora este funil para movê-la) — o board pode ficar vazio até essa lacuna ser
  coberta por uma task futura.

## Pendências

- Resolução automática de visibilidade "carteira/equipe" (equivalente ao
  `PortfolioVisibilityService` de clientes) para oportunidades — fora do escopo desta task, listada
  como decisão consciente acima.
- Nenhuma rota foi registrada em `app_router.dart` para `SalesPipelinePage`/`PipelineStageAdminPage`
  — mesmo estado em que `LeadListPage` já ficou após TASK-056; roteamento fica para uma task de
  navegação/shell futura.

## Evidências

Saída completa de `flutter analyze` (`No issues found!`) e de `flutter test` (`+1284: All tests
passed!`) capturada durante a execução desta task.

## Commit

Ver hash abaixo.

## Push

Não realizado nesta sessão (sem autorização explícita para push).

## Hash do commit

Ver seção de commit desta task na resposta final.

## Branch

`main`
