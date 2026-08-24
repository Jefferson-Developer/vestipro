# TASK-057 — Concluída (2026-08-24)

## Resumo

Modelada a entidade `Opportunity` (EPIC-07 — CRM), base do pipeline de vendas descrito na seção 8
de `tasks.md`. A entidade cobre valor estimado, probabilidade de fechamento, previsão de receita
(derivada, nunca editável diretamente), responsável, estágio (`stageId`, referência de string para
o funil configurável de TASK-058), status geral (aberta/ganha/perdida) e origem rastreável
(`customerId` e/ou `leadId`, nunca ambos nulos). Foram criados os casos de uso
`CreateOpportunityUseCase`, `UpdateOpportunityStageUseCase`, `MarkOpportunityWonUseCase`,
`MarkOpportunityLostUseCase` e `RecalculateRevenueForecastUseCase`, o contrato
`OpportunityRepository` (somente contrato, sem implementação concreta — mesmo padrão adotado por
`LeadRepository` em TASK-055), e a camada de dados (`OpportunityDto`/`OpportunityMapper`) pronta
para uma futura implementação Firestore.

O comentário de `ConvertLeadToOpportunityUseCase` (TASK-055) foi atualizado para refletir que
`Opportunity` já existe, mantendo o mesmo comportamento (a integração completa — criar a
Opportunity e já vincular o Lead em uma única chamada orquestrada — fica para quando a UI do funil
de TASK-058 precisar de um único ponto de entrada).

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task; escopo é modelagem de
  domínio/dados, sem UI).

## Arquivos criados

- `lib/features/opportunities/opportunities.dart`
- `lib/features/opportunities/domain/entities/opportunity.dart`
- `lib/features/opportunities/domain/entities/opportunity.freezed.dart` (gerado por build_runner)
- `lib/features/opportunities/domain/opportunity_status_transition_rules.dart`
- `lib/features/opportunities/domain/repositories/opportunity_repository.dart`
- `lib/features/opportunities/domain/value_objects/opportunity_status.dart`
- `lib/features/opportunities/domain/value_objects/opportunity_sync_status.dart`
- `lib/features/opportunities/domain/usecases/opportunity_use_case_helpers.dart`
- `lib/features/opportunities/domain/usecases/create_opportunity_use_case.dart`
- `lib/features/opportunities/domain/usecases/update_opportunity_stage_use_case.dart`
- `lib/features/opportunities/domain/usecases/mark_opportunity_won_use_case.dart`
- `lib/features/opportunities/domain/usecases/mark_opportunity_lost_use_case.dart`
- `lib/features/opportunities/domain/usecases/recalculate_revenue_forecast_use_case.dart`
- `lib/features/opportunities/data/dtos/opportunity_dto.dart`
- `lib/features/opportunities/data/mappers/opportunity_mapper.dart`
- `test/features/opportunities/domain/entities/opportunity_test.dart`
- `test/features/opportunities/domain/usecases/create_opportunity_use_case_test.dart`
- `test/features/opportunities/domain/usecases/update_opportunity_stage_use_case_test.dart`
- `test/features/opportunities/domain/usecases/mark_opportunity_won_use_case_test.dart`
- `test/features/opportunities/domain/usecases/mark_opportunity_lost_use_case_test.dart`
- `test/features/opportunities/domain/usecases/recalculate_revenue_forecast_use_case_test.dart`
- `test/features/opportunities/data/mappers/opportunity_mapper_test.dart`
- `docs/tasks/TASK-057-modelar-opportunity-CONCLUIDA.md`

## Arquivos alterados

- `docs/tasks/TASKS.md` (checkbox da TASK-057 e progresso 56 → 57)
- `lib/features/leads/domain/usecases/convert_lead_to_opportunity_use_case.dart` (comentário de
  classe atualizado: `Opportunity` deixou de ser "ainda pendente"; comportamento/assinatura
  inalterados)
- `lib/app/injection.config.dart` (regenerado pelo build_runner: registra `OpportunityMapper`
  como `@lazySingleton`)

## Arquitetura utilizada

Clean Architecture feature-first, mesmo padrão de `lib/features/leads/` (TASK-055/056):

- **Domain**: entidade imutável (`freezed`), FSM de status em arquivo dedicado
  (`opportunity_status_transition_rules.dart`, mapa de transições permitidas, mesmo padrão de
  `lead_status_transition_rules.dart`), value objects de enum simples, casos de uso stateless que
  dependem apenas do contrato `OpportunityRepository`, helpers de validação/erro compartilhados
  (`opportunity_use_case_helpers.dart`).
- **Data**: `OpportunityDto` (shape Firestore, com `organizationId` duplicado no payload para
  Security Rules/queries) e `OpportunityMapper` (`@lazySingleton`, sem repositório concreto ainda —
  mesma decisão tomada em TASK-055 para `Lead`).
- Nenhum caso de uso é `@injectable`: seguindo o precedente de TASK-055 (onde `CreateLeadUseCase`
  só ganhou `@injectable` em TASK-056, quando passou a existir uma implementação concreta de
  repositório consumida por um BLoC), os casos de uso de `Opportunity` permanecem construtores
  simples até que uma implementação concreta de `OpportunityRepository` e uma UI consumidora
  existam (provável TASK-058, funil de vendas).

## Regras de negócio implementadas

- Probabilidade de fechamento validada entre 0 e 100 em `CreateOpportunityUseCase`.
- `revenueForecast` é sempre derivado (`estimatedValue * probability / 100`), nunca aceito como
  entrada do chamador — calculado na criação e recomputado por `RecalculateRevenueForecastUseCase`
  sempre que `estimatedValue`/`probability` mudarem por fora do fluxo normal. Nunca negativo
  (decorrência de `estimatedValue >= 0` e `probability` em `0..100`).
- Regra de origem rastreável: `customerId` e/ou `leadId` nunca ambos nulos — validada em
  `CreateOpportunityUseCase`.
- FSM de status (`OpportunityStatus`): `open -> won`, `open -> lost` permitidos; `won` e `lost` são
  terminais (nenhuma transição de saída permitida através dos casos de uso normais). Reabertura é
  documentada como fora do escopo desta task — deve ser, no futuro, uma ação explícita e auditada,
  nunca uma edição de rotina.
- `MarkOpportunityWonUseCase`/`MarkOpportunityLostUseCase` exigem motivo obrigatório
  (`wonReason`/`lostReason`), rejeitando payload vazio antes mesmo de consultar o repositório. Um
  catálogo configurável completo de motivos fica para TASK-061 (texto livre aceito por ora, mesmo
  padrão de `DisqualifyLeadUseCase`).
- `UpdateOpportunityStageUseCase` bloqueia mudança de estágio (`stageId`) quando a Opportunity não
  está `open` (`Opportunity.canChangeStage`), impedindo edição de rotina em oportunidades
  ganhas/perdidas.
- `organizationId` sempre recebido como parâmetro explícito dos casos de uso, nunca lido de campo
  de formulário — resolução pela sessão autenticada é responsabilidade do chamador (BLoC/página),
  a ser conectado quando a UI existir.

## Regras Firebase implementadas

Nenhuma regra do Firestore/Storage foi criada nesta task (não há implementação concreta de
`OpportunityRepository` ainda — apenas o contrato e o shape do DTO). `OpportunityDto` já modela o
documento com `organizationId` duplicado no payload para permitir que Security Rules validem o
tenant sem confiar em valor vindo do cliente, seguindo o padrão de `LeadDto`.

## Analytics implementado

Nenhum (sem UI/fluxo de usuário nesta task; eventos de analytics ficam para a task que conectar
casos de uso a BLoCs/páginas, mesmo padrão de TASK-055 → TASK-056 para Lead).

## Crashlytics implementado

Nenhum específico desta task (sem código de infraestrutura/rede novo; falhas de domínio já
retornam `AppFailure`/`Failure` tipados, como no restante do projeto).

## Impacto offline

Entidade e casos de uso já preparados para offline-first: `OpportunitySyncStatus`
(`pending/syncing/synced/failed/conflict`) espelha `LeadSyncStatus`, e toda mutação marca
`syncStatus: pending` e incrementa `version`, pronta para um futuro repositório
Drift/outbox-backed. Nenhuma implementação concreta de repositório foi criada, então não há
impacto real em sincronização ainda.

## Impacto multi-tenant

`organizationId` é campo imutável da entidade e parâmetro obrigatório de todo caso de uso; nenhuma
regra de negócio depende de valor de tenant vindo implicitamente da UI. `OpportunityDto` duplica
`organizationId` no payload Firestore para permitir validação por Security Rules quando a
implementação concreta existir.

## Testes criados

- `opportunity_test.dart`: igualdade por valor, FSM de status (`open -> won`/`lost` permitido,
  bloqueio de saída de `won`/`lost`), `canChangeStage`, e `calculateRevenueForecast` nos limites
  (probabilidade 0%, 100% e um valor intermediário).
- `create_opportunity_use_case_test.dart`: cálculo correto do forecast, origem só-lead aceita,
  rejeição de `customerId`/`leadId` ambos nulos, rejeição de valor estimado negativo, rejeição de
  probabilidade fora de `0..100` (incluindo negativa), aceitação dos limites 0% e 100%.
- `update_opportunity_stage_use_case_test.dart`: transição de estágio bem-sucedida quando aberta;
  bloqueio quando ganha; bloqueio quando perdida.
- `mark_opportunity_won_use_case_test.dart` / `mark_opportunity_lost_use_case_test.dart`: exigência
  de motivo, sucesso a partir de `open`, bloqueio a partir de estado já terminal (incluindo o
  terminal oposto).
- `recalculate_revenue_forecast_use_case_test.dart`: recomputa forecast desatualizado; é no-op
  quando o valor armazenado já está correto (não chama `update`).
- `opportunity_mapper_test.dart`: round-trip DTO ↔ entidade, mapeamento de status `won` com motivo
  e `closedAt`, erro para status/syncStatus desconhecidos.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 841 files (0 changed) in 2.81 seconds.` — sem alterações pendentes (passou
`--set-exit-if-changed`, exit code 0).

## Resultado do analyzer

`Analyzing VestiPro... No issues found! (ran in 11.8s)`

## Resultado dos testes

`00:44 +1264: All tests passed!` — suíte completa (1264 testes), incluindo os 37 novos testes de
`Opportunity` (7 arquivos: entidade, 5 casos de uso, mapper).

## Decisões técnicas

- `revenueForecast` é armazenado (não só computado em runtime) para permitir consulta/agregação
  direta em relatórios de pipeline futuros, mas a única fonte de verdade da fórmula é
  `Opportunity.calculateRevenueForecast()`; `RecalculateRevenueForecastUseCase` existe justamente
  para manter esse valor sincronizado sem duplicar a fórmula em múltiplos lugares.
- `stageId` é modelado como `String` livre (não enum), pois o catálogo de estágios do funil é
  configurável e será definido em TASK-058 — modelar um enum fixo aqui duplicaria/anteciparia
  aquele trabalho.
- `wonReason`/`lostReason` foram modelados como dois campos distintos (em vez de um único
  `outcomeReason`) porque só um se aplica por vez (mutuamente exclusivos pelo FSM de status) e
  campos nomeados deixam relatórios de motivo de ganho vs. perda (TASK-061) mais diretos de
  consultar.
- Repositório e casos de uso não são `@injectable` ainda, seguindo exatamente o precedente de
  TASK-055 (`Lead`): a anotação só é adicionada quando existe implementação concreta do repositório
  e um consumidor real (BLoC), evitando registrar no DI algo que ainda não pode ser resolvido em
  runtime.
- `ConvertLeadToOpportunityUseCase` não foi refatorado para criar a Opportunity internamente
  (mantém a assinatura de receber `opportunityId` pronto): unificar os dois passos em uma única
  chamada exigiria decidir também `stageId`/`estimatedValue`/`probability`/`expectedCloseDate`
  iniciais, que são responsabilidade natural de `CreateOpportunityUseCase` e não fazem sentido como
  parâmetros do fluxo de conversão de Lead. Documentado no comentário da classe como uma possível
  orquestração futura, não implementada aqui para não expandir o escopo de TASK-057.

## Riscos conhecidos

- Sem implementação concreta de `OpportunityRepository` (Firestore/Drift), `Opportunity` ainda não
  é persistível de ponta a ponta — mesma situação que `Lead` teve entre TASK-055 e TASK-056.
- O fluxo de reabertura de uma Opportunity ganha/perdida foi deixado como lacuna documentada
  (não solicitado pela lista de casos de uso da task); se um usuário precisar reverter uma decisão
  de fechamento antes que esse fluxo exista, não há caminho no domínio.

## Pendências

- Implementação concreta de `OpportunityRepository` (provável Firestore + outbox, mirando o padrão
  de outras entidades já sincronizadas) — fora do escopo desta task de modelagem.
- Cadastro/listagem/kanban de Opportunity, incluindo RBAC (`Capability`), Analytics e o catálogo
  configurável de estágios — escopo de TASK-058.
- Catálogo configurável de motivos de perda/ganho — escopo de TASK-061 (por ora `wonReason`/
  `lostReason` aceitam texto livre).
- Ação explícita e auditada de reabertura de Opportunity ganha/perdida — não solicitada pela task,
  documentada como decisão futura.

## Evidências

Saída integral dos comandos de build/format/analyze/test capturada durante a execução desta task
(ver seções "Comandos executados", "Resultado do formatter", "Resultado do analyzer" e "Resultado
dos testes" acima).

## Commit

Local apenas, sem push (não autorizado nesta rodada). Ver hash abaixo.

## Push

Não realizado — push não autorizado nesta rodada.

## Hash do commit

Informado na resposta final da task, após a criação do commit.

## Branch

`main`
