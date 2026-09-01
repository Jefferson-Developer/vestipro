# TASK-115 — Implementar cadastro de metas (CONCLUÍDA)

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### RBAC (`lib/core/permissions/`)

- `Capability.targetManage` — nova capability única para criar/editar
  `Target` (qualquer dimensão). Concedida a `OWNER`/`ADMIN` (via conjunto
  quase-completo) e explicitamente a `SALES_MANAGER`; **não** concedida a
  `SALES_REP`/`SALES_ASSISTANT`/`FINANCE`/`READ_ONLY`.
- `CreateTargetUseCase`/`UpdateTargetUseCase` re-checam
  `PermissionService.hasPermission(..., Capability.targetManage)` no
  servidor de decisão (camada de aplicação), nunca confiando só na UI —
  mesmo padrão de defesa em profundidade de `DecideOrderApprovalUseCase`.

### Domínio (`lib/features/targets/domain/`)

- `CreateTargetUseCase` (já existente da TASK-114) ganhou: checagem de RBAC
  (`Capability.targetManage`) antes de persistir, e evento de analytics
  `target_created` após sucesso. Passou a ser `@injectable`.
- `UpdateTargetUseCase` (novo): edita `periodGranularity`, `startDate`,
  `endDate`, `metricType`, `targetValue`, `currency` e `status` de um
  `Target` já existente. `dimensionType`/`dimensionId` são deliberadamente
  imutáveis após a criação (identidade da meta, não um campo editável).
  Reaplica a mesma checagem de sobreposição de período da criação
  (`TargetRepository.listByDimension`), excluindo a própria meta da lista de
  candidatos. Registra um `AuditLogEntry` (`AuditAction.targetUpdated`) com
  `previousValue`/`newValue` via `Target.toAuditMap()`, e loga
  `target_updated` no analytics.
- Regra "alertar antes de reduzir o valor da meta abaixo do já realizado":
  `UpdateTargetUseCase` aceita um `currentAchievedValue` opcional (o
  `achievedValueCache` já conhecido pelo chamador, nunca calculado aqui —
  esse cálculo é escopo da TASK-116) e um `confirmReduceBelowAchieved`. Se
  o novo `targetValue` for menor que `currentAchievedValue` e a confirmação
  não tiver sido dada, retorna `ValidationFailure` com código
  `target_value_below_achieved`; a UI mostra um diálogo de confirmação e
  reenvia com `confirmReduceBelowAchieved: true`.
- `Target.toAuditMap()` (novo método na entidade): snapshot plano para
  `AuditLogEntry.previousValue`/`newValue`, mesmo padrão de
  `PromotionalCampaign.toAuditMap()`.
- `target_use_case_helpers.dart` ganhou `targetManageDeniedFailure()` e
  `targetValueBelowAchievedFailure(double)`.
- `AuditAction.targetUpdated` (novo, código `target.updated`).
- `AnalyticsEvents.targetCreated`/`targetUpdated` (novos, códigos
  `target_created`/`target_updated`).

### Dados (`lib/features/targets/data/`)

- `SharedPreferencesTargetRepository` (novo): implementação concreta local
  de `TargetRepository`, seguindo o mesmo precedente de
  `SharedPreferencesOpportunityRepository`/
  `SharedPreferencesPromotionalCampaignRepository` — um *local store*
  interino, não ainda Firestore/Outbox. `SyncPushHandler` (TASK-109) deixa
  documentado que nenhuma feature do app está de fato ligada ao Outbox ainda
  (nem `order`/`orderItem`/`crmActivity`/`customer`), então uma
  implementação Firestore+Outbox dedicada a `Target` ficaria fora de escopo
  desta task específica — ver "Pendências" abaixo.

### Apresentação (`lib/features/targets/presentation/`)

- `TargetFormCubit`/`TargetFormState` (novos): cubit único cobrindo
  cadastro + edição + listagem, no mesmo formato de
  `DiscountPolicyCubit`/`PromotionalCampaignCubit`. Como
  `TargetRepository` só expõe `listByDimension` (não uma listagem por
  organização), a busca da tabela também é por dimensão: o próprio seletor
  de dimensão do formulário dobra como filtro de "quais metas já
  cadastradas mostrar" — a mesma consulta que os comentários de
  `TargetRepository` já descrevem ("metas ativas de um vendedor no mês
  corrente" / "metas de uma equipe no trimestre").
- `TargetFormPage` (novo): formulário com seletor de dimensão (vendedor,
  equipe, empresa, coleção, categoria) + campo de id da dimensão, cadência
  do período + seletores de data de início/fim, métrica, valor, moeda e
  status, mais uma tabela das metas já cadastradas para a dimensão buscada.
  Protegida por `PermissionBuilder(capability: Capability.targetManage)`,
  igual a `PromotionalCampaignsPage`/`PaymentTermsPage` — um `SALES_REP`
  nunca alcança o formulário.
- `Barrel targets.dart` atualizado com os novos exports.

## Arquivos criados

- `lib/features/targets/domain/usecases/update_target_use_case.dart`
- `lib/features/targets/data/repositories/shared_preferences_target_repository.dart`
- `lib/features/targets/presentation/cubit/target_form_cubit.dart`
- `lib/features/targets/presentation/cubit/target_form_state.dart`
- `lib/features/targets/presentation/pages/target_form_page.dart`
- `test/features/targets/domain/usecases/update_target_use_case_test.dart`
- `test/features/targets/presentation/pages/target_form_page_test.dart`
- `docs/tasks/TASK-115-implementar-cadastro-de-metas-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/permissions/capability.dart` (novo `Capability.targetManage`)
- `lib/core/permissions/role_permission_matrix.dart` (`targetManage` para `SALES_MANAGER`)
- `lib/core/analytics/analytics_events.dart` (`targetCreated`/`targetUpdated`)
- `lib/features/audit_log/domain/value_objects/audit_action.dart` (`targetUpdated`)
- `lib/features/audit_log/presentation/presenters/audit_log_presenter.dart` (rótulos `Meta alterada`/`Meta`)
- `lib/features/targets/domain/entities/target.dart` (`toAuditMap()`)
- `lib/features/targets/domain/usecases/create_target_use_case.dart` (RBAC + analytics + `@injectable`)
- `lib/features/targets/domain/usecases/target_use_case_helpers.dart` (novos failure builders)
- `lib/features/targets/targets.dart` (novos exports)
- `lib/app/injection.config.dart` (gerado pelo `build_runner`, registra `CreateTargetUseCase`/`UpdateTargetUseCase`/`SharedPreferencesTargetRepository`/`TargetFormCubit`)
- `test/features/targets/domain/usecases/create_target_use_case_test.dart` (novo construtor com RBAC/analytics + testes de negação RBAC)
- `test/core/permissions/role_permission_matrix_test.dart` (assert `targetManage` por papel)
- `test/core/analytics/analytics_events_test.dart` (novos eventos na lista fixa)
- `docs/tasks/TASKS.md` (checkbox da TASK-115 e progresso 114/220 → 115/220)

## Validações executadas

- `dart run build_runner build` — sucesso, regenerou `lib/app/injection.config.dart` com os novos registros de DI.
- `flutter analyze` (projeto completo) — sem issues.
- `dart format --set-exit-if-changed .` — sem alterações pendentes.
- `flutter test test/features/targets test/core/permissions test/features/audit_log test/core/analytics` — 123 testes, todos passando.
- `flutter test` (suíte completa) — 2331 testes, todos passando.

## Decisões e riscos conhecidos

- **RBAC de edição simplificado para "tudo ou nada" por enquanto**: a task
  descreve um SALES_REP podendo "visualizar/editar a própria meta quando
  permitido por configuração da organização, restrita a campos não
  financeiros". Essa configuração de organização (toggle) não existe ainda
  em nenhum lugar do código — não há `OrganizationSettings` para esse
  propósito. Implementá-la agora seria escopo além do "cadastro de metas"
  em si (exigiria uma feature nova de configuração + uma segunda trilha de
  validação por campo). Por isso, o RBAC implementado nesta task é mais
  estrito e seguro por padrão: `SALES_REP` nunca cria nem edita nenhuma
  meta, nem mesmo a própria — apenas `OWNER`/`ADMIN`/`SALES_MANAGER`
  (`Capability.targetManage`) podem. Isso satisfaz integralmente o critério
  de aceite "SALES_REP não consegue criar/editar meta de terceiros", mas é
  um pouco mais restritivo do que a redação completa da task sugere para o
  caso "própria meta". Fica registrado como pendência explícita para uma
  task futura de auto-edição de metas (dependente de uma configuração de
  organização que ainda não existe).
- **Repositório concreto ainda é local-only (`SharedPreferences`), não
  Firestore+Outbox**: confirmei em `lib/core/sync/domain/sync_push_handler.dart`
  que nenhuma feature do app está de fato conectada ao Outbox ainda — nem
  `order`/`orderItem`/`crmActivity`/`customer`, que já têm o
  `OutboxEntityType` reservado. Construir a integração Firestore+Outbox
  específica de `Target` nesta task teria sido a primeira do projeto a
  fazer essa ligação, um esforço de infraestrutura de sincronização muito
  maior do que "cadastro de metas" — e o próprio `TargetRepository`
  (TASK-114) já documentava a expectativa de um "local store interino"
  aqui, no mesmo molde de `SharedPreferencesOpportunityRepository`. Uma
  migração para Firestore/Outbox fica registrada como trabalho futuro,
  idealmente junto da primeira task que de fato ligar qualquer entidade ao
  pipeline de sync (TASK-116 em diante, ou uma task dedicada).
- **Listagem da tabela do cadastro é por dimensão, não por organização
  inteira**: `TargetRepository` (contrato da TASK-114) só expõe
  `listByDimension`, não uma listagem geral por organização/empresa. A
  tela de cadastro por isso pede a dimensão (tipo + id) antes de buscar as
  metas já existentes — não há uma "lista de todas as metas da empresa"
  nesta tela. Ampliar o contrato para uma listagem paginada por
  organização/empresa (útil para um painel administrativo mais amplo de
  metas) fica como possível melhoria futura, fora do escopo estrito desta
  task.
- **Seleção de dimensão por id digitado, não por busca/autocomplete de
  vendedor/equipe/empresa/coleção/categoria**: o formulário usa um campo de
  texto livre para o id da dimensão (`dimensionId`), o mesmo padrão já
  usado por outras telas de cadastro do app para ids relacionados
  (produtos/coleções/categorias em `PromotionalCampaignsPage`, tabelas de
  preço em `PaymentTermsPage`). Um seletor com busca por nome (usando
  `AppDropdown`/um novo componente de busca ligado a
  `MembershipRepository`/`TeamRepository`/catálogo) melhoraria a UX, mas
  não estava listado como exigência explícita da task e ficaria mais caro
  em escopo; fica como sugestão de melhoria futura.
- **Auditoria só no `Update`, não no `Create`**: a task pede auditoria
  explicitamente para "alterações em metas ativas" (edição). A criação não
  foi auditada (só logada via analytics), seguindo a redação literal da
  task — mas nada impede estender para `Create` também numa iteração
  futura se o time de negócio quiser rastrear criação de meta no mesmo
  log administrativo.

Nenhum teste, análise ou comando foi apenas assumido: todos os comandos
listados em "Validações executadas" foram executados nesta sessão e
retornaram sucesso.
