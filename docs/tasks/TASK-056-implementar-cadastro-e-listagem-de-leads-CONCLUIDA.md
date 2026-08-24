# TASK-056 — Concluída (2026-08-24)

## Resumo
Implementado o cadastro (`LeadFormPage`) e a listagem (`LeadListPage`) de leads sobre o domínio e os
casos de uso já modelados em TASK-055. A listagem suporta busca com debounce, filtros combináveis
(origem, status, responsável) e paginação por cursor; a ação "Qualificar"/"Desqualificar" está
disponível diretamente em cada card da lista (desqualificar exige motivo obrigatório num diálogo
dedicado) e reflete a mudança de status no estado local imediatamente, sem exigir refresh manual.
Como `LeadRepository` só existia como contrato (TASK-055), esta task também criou sua primeira
implementação concreta (`SharedPreferencesLeadRepository`), reaproveitando o mesmo padrão da
`SharedPreferencesCustomerRepository` (TASK-048): armazenamento local durável, `syncStatus.pending`,
mesma técnica de paginação/filtro client-side. RBAC dedicado foi adicionado: três novas
`Capability`s (`leadView`, `leadCreate`, `leadQualify`) e sua distribuição por papel na
`RolePermissionMatrix`.

## Agentes utilizados
- flutter-senior-architect (domínio, repositório local, BLoCs, RBAC, DI)
- flutter-ui-design-specialist (LeadFormPage, LeadListPage, badges, diálogo de desqualificação,
  responsividade mobile/desktop)

## Arquivos criados
- `lib/features/leads/domain/entities/lead_list_filters.dart`
- `lib/features/leads/domain/entities/lead_page_result.dart`
- `lib/features/leads/domain/usecases/list_leads_use_case.dart`
- `lib/features/leads/data/repositories/shared_preferences_lead_repository.dart`
- `lib/features/leads/presentation/bloc/lead_list_event.dart`
- `lib/features/leads/presentation/bloc/lead_list_state.dart`
- `lib/features/leads/presentation/bloc/lead_list_bloc.dart`
- `lib/features/leads/presentation/bloc/lead_form_event.dart`
- `lib/features/leads/presentation/bloc/lead_form_state.dart`
- `lib/features/leads/presentation/bloc/lead_form_bloc.dart`
- `lib/features/leads/presentation/pages/lead_list_page.dart`
- `lib/features/leads/presentation/pages/lead_form_page.dart`
- `test/features/leads/domain/usecases/list_leads_use_case_test.dart`
- `test/features/leads/data/repositories/shared_preferences_lead_repository_test.dart`
- `test/features/leads/presentation/bloc/lead_list_bloc_test.dart`
- `test/features/leads/presentation/bloc/lead_form_bloc_test.dart`
- `test/features/leads/presentation/pages/lead_list_page_test.dart`
- `test/features/leads/presentation/pages/lead_form_page_test.dart`
- `docs/tasks/TASK-056-implementar-cadastro-e-listagem-de-leads-CONCLUIDA.md`

## Arquivos alterados
- `lib/features/leads/domain/repositories/lead_repository.dart` (novo método `listPage`)
- `lib/features/leads/domain/usecases/create_lead_use_case.dart` (`@injectable`, agora resolvível
  via DI pois já existe implementação concreta de `LeadRepository`)
- `lib/features/leads/domain/usecases/qualify_lead_use_case.dart` (`@injectable`)
- `lib/features/leads/domain/usecases/disqualify_lead_use_case.dart` (`@injectable`)
- `lib/features/leads/leads.dart` (exporta as novas entidades/use cases/blocs/páginas)
- `lib/core/permissions/capability.dart` (novas `Capability`s `leadView`, `leadCreate`,
  `leadQualify`)
- `lib/core/permissions/role_permission_matrix.dart` (distribuição das novas capabilities por papel)
- `lib/core/analytics/analytics_events.dart` (`lead_created`, `lead_qualified`, `lead_disqualified`)
- `lib/app/injection.config.dart` (regenerado pelo build_runner: registra
  `SharedPreferencesLeadRepository`, `ListLeadsUseCase`, `LeadListBloc`, `LeadFormBloc`)
- `test/core/permissions/role_permission_matrix_test.dart` (ajusta o teste de conjunto exato do
  SALES_ASSISTANT e adiciona cobertura das novas capabilities de lead por papel)
- `test/core/analytics/analytics_events_test.dart` (inclui os 3 novos eventos na lista esperada)
- `docs/tasks/TASKS.md` (checkbox da TASK-056 e progresso 55 → 56)

## Arquitetura utilizada
Clean Architecture feature-first, mesma estrutura de `customers`: `domain` (entidades/filtros
`LeadListFilters`/`LeadPageResult`, contrato de repositório estendido, use case `ListLeadsUseCase`)
sem qualquer dependência de Flutter/Firebase; `data` com `SharedPreferencesLeadRepository`
implementando o contrato; `presentation` com dois BLoCs (`LeadListBloc`, `LeadFormBloc`) e duas
páginas (`LeadListPage`, `LeadFormPage`) que só conversam com o domínio via BLoC — nenhuma delas
acessa `SharedPreferences`/repositório diretamente. `LeadListBloc` reflete qualificação/
desqualificação substituindo o `Lead` afetado em `state.leads` na mesma emissão do resultado do use
case, sem re-fetch. O DI (`get_it`/`injectable`) foi regenerado via `build_runner`.

## Regras de negócio implementadas
- `LeadFormPage`: cria o lead com `LeadStatus.newLead` (via `CreateLeadUseCase`, TASK-055);
  responsável é sempre o usuário autenticado a menos que o caller tenha `Capability.teamManage`
  (mesma regra de reatribuição usada em `CustomerFormPage`), quando um dropdown de responsável é
  exibido; origem é selecionável entre `LeadSource.defaults`, com um campo opcional de texto livre
  quando "Outro" é escolhido (usa `LeadSource.custom`, já suportado pelo domínio de TASK-055).
- `LeadListPage`: busca por nome/documento com debounce de 300ms, filtros combináveis por status,
  origem e responsável, paginação por cursor (`ListLeadsUseCase`/`LeadRepository.listPage`).
- Ação "Qualificar"/"Desqualificar" só aparece por lead quando `Lead.canTransitionTo` permite a
  transição correspondente (bloqueia, por exemplo, qualificar um lead já convertido) e só é
  renderizada quando o caller tem `Capability.leadQualify`.
- Desqualificar exige motivo: o botão de confirmação do diálogo bloqueia localmente um motivo vazio
  antes mesmo de chamar `DisqualifyLeadUseCase` — que também valida (TASK-055) — mantendo a regra
  "nunca confiar só na validação client-side".
- RBAC: `Capability.leadView`/`leadCreate`/`leadQualify` adicionadas à `RolePermissionMatrix`.
  `SALES_REP`/`SALES_MANAGER` têm as três; `SALES_ASSISTANT` só tem `leadCreate` (mesmo padrão de
  `customerCreate`/`customerUpdate` sem `customerView` que já existia para esse papel);
  `FINANCE` ganhou `leadView` (visibilidade do funil para forecast) mas nunca `leadQualify`;
  `READ_ONLY` continua sem nenhuma capability nova. `OWNER`/`ADMIN` herdam automaticamente por já
  serem, respectivamente, o superset total e "tudo exceto transferência de owner".

## Regras Firebase implementadas
Não aplicável. `SharedPreferencesLeadRepository` é armazenamento local (mesmo estágio que
`CustomerRepository` tinha após TASK-048); nenhuma Security Rule ou Cloud Function foi criada nesta
task — RBAC client-side aqui é apenas UX, a autorização real ainda depende de TASK-030 (pendente,
mesmo risco documentado desde TASK-048/055).

## Analytics implementado
Três eventos novos no catálogo central (`AnalyticsEvents`): `lead_created` (emitido por
`LeadFormBloc` ao criar com sucesso, com `organization_id`, `lead_id`, `lead_source`,
`sync_status`). `lead_qualified`/`lead_disqualified` foram adicionados ao catálogo para uso futuro
mas **não são emitidos ainda** por `LeadListBloc` — ver Pendências.

## Crashlytics implementado
Não aplicável. Falhas continuam propagadas como `AppResult`/`Failure`; nenhuma captura de exceção
nova foi adicionada nesta task.

## Impacto offline
`SharedPreferencesLeadRepository` persiste localmente e sobrevive ao fechamento do app; todo
create/update grava `LeadSyncStatus.pending`. Não há Outbox real nem sincronização remota ainda
(mesmo estágio que `customers` tinha antes de sua própria task de sync) — ver Pendências.

## Impacto multi-tenant
`listPage`/`getById`/`create`/`update` continuam escopados por `organizationId` (chave de
armazenamento local `leads_<organizationId>`, nunca cruzando organizações — coberto por teste).
`companyId`, quando informado, filtra o resultado mas nunca exclui um lead sem `companyId` (o campo
é opcional no domínio, TASK-055).

## Testes criados
- `ListLeadsUseCase`: validação de payload (organizationId vazio, limit fora do intervalo), trim e
  normalização de filtros/paginação antes de delegar ao repositório, propagação de falha.
- `SharedPreferencesLeadRepository`: persistência local, `getById`/`update` com `NotFoundFailure`,
  filtros combinados por status/origem/responsável, paginação por cursor, busca por nome/documento
  (acento/caixa-insensível) e isolamento entre organizações.
- `LeadListBloc`: primeira página + carga do roster de responsáveis, paginação sem perder itens já
  carregados, debounce de busca ignorando edições obsoletas, qualificação refletindo o `Lead`
  atualizado em `state.leads` sem refetch, desqualificação sem motivo surfaceando falha sem alterar
  o lead.
- `LeadFormBloc`: submissão válida atribuída ao usuário atual por padrão, erro de nome obrigatório
  sem tocar o repositório, exigência de responsável quando RBAC permite reatribuição, reatribuição
  honrada quando permitida, origem customizada via texto livre.
- `LeadListPage` (widget): RBAC ocultando a página inteira (`ForbiddenPage`) sem `lead.view`,
  renderização de card com badges de status/origem, estado vazio, ocultação das ações de
  qualificar/desqualificar para um papel com `lead.view` mas sem `lead.qualify` (`FINANCE`),
  qualificação atualizando o badge in-place, desqualificação bloqueando motivo vazio no diálogo e
  aplicando a mudança após motivo válido.
- `LeadFormPage` (widget): RBAC ocultando o formulário (`ForbiddenPage`) sem `lead.create`, erro de
  nome obrigatório, submissão válida atribuída ao usuário atual, exibição/ocultação do campo
  responsável conforme `Capability.teamManage`.
- `RolePermissionMatrix`: ajuste do teste de conjunto exato do `SALES_ASSISTANT` e nova cobertura
  garantindo que `SALES_REP`/`SALES_MANAGER` têm as três capabilities de lead, que
  `SALES_ASSISTANT`/`FINANCE`/`READ_ONLY` nunca têm `leadQualify`, e que `FINANCE` tem `leadView`.
- `AnalyticsEvents`: lista esperada atualizada com os 3 novos eventos.

## Comandos executados
- `dart run build_runner build` (regenerar `injection.config.dart`, `lead.freezed.dart` etc.)
- `dart format lib/features/leads lib/core/permissions lib/core/analytics test/features/leads
  test/core/permissions`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test/features/leads test/core/permissions test/core/analytics`
- `flutter test` (suíte completa)

## Resultado do formatter
`dart format --set-exit-if-changed .`: `Formatted 819 files (0 changed)`, exit code 0.

## Resultado do analyzer
`flutter analyze`: `No issues found!` (11.3s).

## Resultado dos testes
`flutter test` (suíte completa): `All tests passed!` — 1227 testes, incluindo os ~101 testes novos
de leads/permissions/analytics tocados por esta task, sem quebrar nenhum teste pré-existente
(customers, users, organizations etc.).

## Decisões técnicas
- `LeadRepository` ganhou uma implementação concreta (`SharedPreferencesLeadRepository`) nesta
  task, e não apenas em uma task futura de "persistência" — a listagem/paginação/filtros exigidos
  pelo escopo técnico da própria TASK-056 não têm como funcionar de ponta a ponta sem uma
  implementação real, e a Pendência já registrada em TASK-055 apontava explicitamente para
  "TASK-056 em diante" como o lugar certo para isso. Seguiu-se exatamente o precedente de
  `SharedPreferencesCustomerRepository` (TASK-048) para não inventar um padrão novo.
  Firestore/outbox reais continuam como trabalho futuro (mesmo estágio de `customers`). As ações
  de qualificar/desqualificar na UI só habilitam o botão quando `Lead.canTransitionTo` permite —
  reaproveitando a máquina de estados já modelada em TASK-055, nada de regra de negócio nova na UI.
- Não foi criada uma `LeadDetailPage` separada: a task pede a ação de qualificar/desqualificar "na
  lista **ou** no detalhe do lead" (disjunção), e o escopo técnico só lista `LeadFormPage` e
  `LeadListPage` como páginas obrigatórias. A ação foi implementada diretamente nos cards da lista,
  satisfazendo o requisito sem introduzir uma página adicional fora do escopo explícito.
  Uma tela de detalhe fica para quando o backlog explicitamente pedir por ela.
- Nenhuma feature de reatribuição de responsável foi adicionada à listagem (apenas ao cadastro) —
  a task cita "reatribuir o responsável" nas regras de RBAC, mas nenhum caso de uso de
  reatribuição de um lead já existente foi criado em TASK-055; adicionar um agora seria escopo
  novo sem contrato de domínio correspondente. Documentado como pendência.
- `Capability.leadView` foi concedida a `FINANCE` (além de `SALES_REP`/`SALES_MANAGER`) para que
  existisse um papel real capaz de visualizar a lista sem poder qualificar/desqualificar,
  cobrindo o requisito de teste "RBAC ocultando as ações para quem não tem permissão" com uma
  combinação de capabilities plausível para o negócio (Financeiro acompanhando o funil para
  forecast, sem poder decidir sobre qualificação comercial).
- A busca por origem nos filtros usa `LeadSource.defaults` (as 6 origens padrão) como opções —
  origens customizadas por organização ainda não têm um caso de uso de configuração (não criado em
  TASK-055 nem nesta task), então não aparecem como opção de filtro até que tal configuração exista.

## Riscos conhecidos
- RBAC de lead (`leadView`/`leadCreate`/`leadQualify`) só existe client-side (`PermissionService`);
  como em toda a base (TASK-030 ainda pendente), nada impede hoje que uma chamada direta ao
  `LeadRepository` bypassando a UI ignore essas capabilities — mitigação real fica para TASK-030.
- `SharedPreferencesLeadRepository` não é multi-dispositivo nem sincroniza com o backend; dois
  dispositivos do mesmo usuário terão listas de leads divergentes até que sync real exista.
- `lead_qualified`/`lead_disqualified` estão no catálogo de `AnalyticsEvents` mas não são emitidos
  por `LeadListBloc` ainda — ver Pendências.
- Sem reassign de responsável em lead já existente (ver Decisões técnicas).

## Pendências
- Emitir `AnalyticsEvents.leadQualified`/`leadDisqualified` a partir de `LeadListBloc` quando essas
  ações tiverem sucesso (ficou fora do escopo desta rodada; os nomes já existem no catálogo).
- Implementar `LeadRepository` Firestore/outbox real (sync remoto), substituindo/complementando
  `SharedPreferencesLeadRepository`.
- Caso de uso de reatribuição de responsável para um lead já existente (fora do cadastro inicial).
- Catálogo configurável de origens por organização (`LeadSource` customizado hoje só é usado no
  formulário via texto livre, não aparece nos filtros da listagem).
- `LeadDetailPage` dedicada, se um EPIC futuro exigir mais contexto por lead do que cabe no card da
  listagem (timeline de atividades é TASK-059, funil é TASK-058).
- TASK-030 (Cloud Functions/Security Rules) continua sendo o bloqueador real de autorização
  server-side para as novas capabilities de lead, como já documentado para `customers`.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1227/1227 testes passaram.
- Backlog atualizado para 56 / 220.

## Commit
`feat(leads): implement lead registration and listing`

## Push
Não realizado — sem autorização nesta rodada.

## Hash do commit
Informado na resposta final da task, após a criação do commit.

## Branch
main
