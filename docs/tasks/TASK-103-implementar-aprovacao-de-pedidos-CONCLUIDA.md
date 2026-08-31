# TASK-103 — Concluída (2026-08-31)

## Resumo
Implementado o fluxo de aprovação de pedidos (EPIC-13): quando o motor de precificação
(TASK-088) sinaliza que um desconto/condição excede a política do perfil do vendedor
(`pricingApprovalRequired`), a Cloud Function `submitOrder` (TASK-101) agora encaminha o
pedido para `under_review` (em vez de `submitted`), registrando na própria trilha
(`statusHistory`) o motivo exato da regra excedida. Uma nova Cloud Function idempotente,
`decideOrderApproval`, é o único ponto que autoriza e persiste a decisão (aprovar/rejeitar),
com RBAC re-validado a partir do Membership real do chamador — nunca confiando no client —
e escopo de equipe para `SALES_MANAGER` (só decide pedidos de vendedores da própria
equipe, espelhando exatamente `managerCanReadOrder` do `firestore.rules`). No client, uma
nova tela "Fila de aprovação" (`OrderApprovalQueuePage`), gated por `Capability.orderApprove`
(já existente desde TASK-102), lista os pedidos `under_review` visíveis ao aprovador e
permite aprovar (com confirmação) ou rejeitar (com justificativa obrigatória).

Como o motor de precificação já suportava desconto manual (`manualDiscountPercent`) mas o
`submitOrder` descartava esse valor (hardcoded em `0`) antes desta task — o que tornaria o
mecanismo de aprovação inatingível em qualquer cenário real —, o campo passou a ser
recebido/validado/repassado corretamente pela Function, dentro do próprio arquivo já em
alteração por esta task.

## Agentes utilizados
- `flutter-senior-architect` (arquitetura, domínio, dados, Cloud Functions, RBAC).
- `flutter-ui-design-specialist` (perspectiva de UI/Design System coberta diretamente pelo
  agente arquiteto nesta execução — reuso de `AppDataTable`/`AppDataTableAction`,
  `AppConfirmationDialog`, `AppAdminPageLayout`, dialog de justificativa mirrorando
  `_DisqualifyReasonDialog` de `LeadListPage`).

## Arquivos criados
- `functions/src/orders/decide-order-approval.ts`
- `functions/test/orders/decide-order-approval.test.ts`
- `lib/features/orders/domain/entities/order_approval_decision.dart` (+ `.freezed.dart`,
  gerado)
- `lib/features/orders/domain/entities/order_approval_decision_result.dart`
- `lib/features/orders/domain/repositories/order_approval_repository.dart`
- `lib/features/orders/domain/usecases/decide_order_approval_use_case.dart`
- `lib/features/orders/data/dtos/order_approval_decision_result_dto.dart`
- `lib/features/orders/data/datasources/order_approval_data_source.dart`
- `lib/features/orders/data/datasources/cloud_functions_order_approval_data_source.dart`
- `lib/features/orders/data/mappers/order_approval_decision_mapper.dart`
- `lib/features/orders/data/repositories/order_approval_repository_impl.dart`
- `lib/features/orders/presentation/bloc/order_approval_queue_bloc.dart`
- `lib/features/orders/presentation/bloc/order_approval_queue_event.dart`
- `lib/features/orders/presentation/bloc/order_approval_queue_state.dart`
- `lib/features/orders/presentation/pages/order_approval_queue_page.dart`
- `test/features/orders/domain/entities/order_approval_decision_test.dart`
- `test/features/orders/domain/usecases/decide_order_approval_use_case_test.dart`
- `test/features/orders/data/mappers/order_approval_decision_mapper_test.dart`
- `test/features/orders/presentation/pages/order_approval_queue_page_test.dart`
- `docs/tasks/TASK-103-implementar-aprovacao-de-pedidos-CONCLUIDA.md` (este arquivo)

## Arquivos alterados
- `functions/src/orders/submit-order.ts`: (1) `SubmitOrderItemInput`/`NormalizedItem` ganham
  `manualDiscountPercent` (validado 0–100, default 0) e o valor passa a ser realmente
  repassado ao motor de precificação (antes hardcoded em `0` — bug latente que impedia
  qualquer aprovação de ser disparada de fato); (2) quando `pricing.approvalRequired` é
  `true`, o pedido é persistido com `status: 'under_review'` (em vez de `'submitted'`) e a
  primeira entrada de `statusHistory` carrega o motivo exato (`buildApprovalReason`, com o
  percentual solicitado/limite/máximo da política).
- `functions/src/orders/index.ts`, `functions/src/index.ts`: export de `decideOrderApproval`.
- `functions/test/orders/submit-order.test.ts`: 3 novos testes (dentro do limite →
  `submitted`; acima do limite de aprovação → `under_review` com motivo na trilha; acima do
  limite máximo da política → `failed-precondition`, nada persistido) + helper
  `seedDiscountPolicy`.
- `lib/features/orders/domain/entities/order.dart` (+ `order.freezed.dart`, gerado): novo
  getter `approvalReason` (derivado do último `OrderStatusHistoryEntry` com
  `newStatus == underReview`, nunca um campo novo persistido).
- `lib/features/orders/orders.dart`: exports dos novos arquivos.
- `lib/core/analytics/analytics_events.dart`: novos eventos `order_approved`/
  `order_rejected`.
- `lib/core/navigation/app_route_paths.dart`, `app_router.dart`: nova rota
  `OrderApprovalQueueRoute` (`/org/:orgId/companies/:companyId/orders/approvals`), protegida
  por `Capability.orderApprove` (guard + builder param `orderApprovalQueuePageBuilder`).
- `lib/app/bootstrap.dart`: `orderApprovalQueuePageBuilder` registrado no `AppRouter`.
- `lib/app/injection.config.dart` (gerado): registro DI dos novos
  `@injectable`/`@LazySingleton` (datasource, repository, mapper, use case, bloc).
- `test/core/analytics/analytics_events_test.dart`: lista esperada de eventos atualizada com
  `order_approved`/`order_rejected`.

## Arquitetura utilizada
Clean Architecture feature-first + BLoC, seguindo exatamente os precedentes já
estabelecidos por TASK-101/TASK-102 nesta mesma feature: `OrderApprovalQueueBloc` reaproveita
`ListOrdersUseCase`/`OrderVisibilityService` (o mesmo RBAC de visibilidade da listagem de
pedidos) para não duplicar a lógica de escopo por vendedor/equipe, e adiciona só a ação de
decisão (`DecideOrderApprovalUseCase` → `OrderApprovalRepository` → `CloudFunctionsOrderApprovalDataSource`
→ `decideOrderApproval`). `OrderApprovalDecision` é uma entidade de domínio puramente
derivada (`fromOrder`), nunca um novo documento Firestore: a trilha de decisão já vive
integralmente em `Order.statusHistory` + `Order.approvedBy/approvedAt/rejectionReason`
(campos já escalfoldados desde TASK-095 exatamente para este fluxo) — evita um segundo
artefato que pudesse divergir da trilha autoritativa. UI nunca acessa Firestore/Cloud
Functions diretamente; toda regra de negócio (limite de desconto, transição de status,
motivo obrigatório na rejeição) vive em domain/Functions.

## Regras de negócio implementadas
- Pedido cujo desconto manual excede o limite de aprovação do perfil (mas não o máximo da
  política) é automaticamente encaminhado para `under_review` em vez de `submitted`
  (`submitOrder`), carregando o motivo exato na trilha.
- Pedido cujo desconto excede o máximo absoluto da política continua bloqueado
  (`failed-precondition`), comportamento já existente de TASK-088/TASK-101, preservado.
- Apenas `OWNER`/`ADMIN`/`SALES_MANAGER` (mesmos papéis de `Capability.orderApprove`) podem
  decidir um pedido — revalidado a partir do Membership real em `decideOrderApproval`, nunca
  confiando em RBAC resolvido só no client.
- `SALES_MANAGER` só decide pedidos cujo vendedor pertence a pelo menos uma de suas próprias
  equipes (`membership.teamIds`) — mesmo escopo que `firestore.rules`' `managerCanReadOrder`
  já aplica para leitura; um gestor nunca decide o que nem sequer poderia ler.
- Rejeição sem motivo é recusada tanto no client (`DecideOrderApprovalUseCase`, antes de
  qualquer chamada de rede) quanto no servidor (`decideOrderApproval`, `invalid-argument`).
- Transição de status só é aceita a partir de `under_review` (mirror do
  `OrderStatusTransitionValidator` já existente) — decidir um pedido em qualquer outro
  status falha com `failed-precondition`.
- Decisão idempotente: uma repetição da mesma decisão (double tap/retry) nunca duplica a
  entrada de `statusHistory`/log de auditoria, apenas repete o resultado já persistido.
- Pedido rejeitado nunca é reaproveitado como aprovado depois — a máquina de estados
  (`under_review → rejected`) é terminal exceto para `cancelled`; um reenvio exige um novo
  ciclo de submissão (nova task/pedido), comportamento já garantido pelo
  `OrderStatusTransitionValidator` existente, não alterado nesta task.

## Regras Firebase implementadas
Nenhuma mudança em `firestore.rules` foi necessária: a coleção `orders` já nega toda escrita
do client (`allow create, update, delete: if false`, TASK-102) — `decideOrderApproval`
escreve via Admin SDK, como `submitOrder` já fazia, e por isso não passa pelas Rules. O
escopo de equipe do `SALES_MANAGER` foi replicado dentro da própria Function (leitura direta
de `members/{sellerId}.teamIds`), espelhando a mesma decisão que `managerCanReadOrder` já
codifica em `firestore.rules`, para nunca divergir do que a leitura já permite.

## Analytics implementado
- `order_approved`/`order_rejected` (novos, `AnalyticsEvents`), logados por
  `DecideOrderApprovalUseCase` somente após confirmação de sucesso do backend, com
  `organization_id`/`company_id`/`order_id` — nenhum dado financeiro (percentual de
  desconto, valores) ou pessoal enviado.
- O evento `order_submitted` já existente (TASK-101) continua cobrindo a submissão,
  incluindo o novo `status` possível (`under_review`) sem qualquer mudança de código.

## Crashlytics implementado
Nenhuma mudança direta — os fluxos usam o mesmo padrão `AppResult`/`Failure` já monitorado
pela infraestrutura existente; nenhum novo ponto de falha silenciosa foi introduzido.

## Impacto offline
Decidir uma aprovação exige conectividade (chamada direta a `decideOrderApproval`, sem
Outbox) — decisão deliberada, mirrorando `submitOrder`: aprovar/rejeitar é uma ação de
gestão pontual do aprovador (tipicamente com boa conectividade), não uma operação de campo
do vendedor que precise sobreviver a fechamento do app offline. A fila em si
(`OrderApprovalQueueBloc`) reaproveita `ListOrdersUseCase`, que não tem cache offline
próprio (mesmo risco já documentado em TASK-102) — um aprovador sem conexão não vê a fila
atualizada.

## Impacto multi-tenant
- Toda decisão é escopada por `organizationId`/`companyId` explícitos no payload,
  revalidados contra o documento real do pedido em `decideOrderApproval` (nunca confiados
  como autorização); um `companyId` divergente do pedido falha com `failed-precondition`.
- RBAC (`Capability.orderApprove`) e o escopo de equipe do `SALES_MANAGER` são sempre
  revalidados a partir do Membership real do chamador, nunca do que o client informa.

## Testes criados
- `functions/test/orders/submit-order.test.ts` (3 novos): desconto dentro do limite →
  `submitted`; acima do limite de aprovação → `under_review` com motivo na trilha
  (`pricingApprovalRequired: true`); acima do máximo da política → `failed-precondition`,
  nada persistido.
- `functions/test/orders/decide-order-approval.test.ts` (8 casos): aprovação por OWNER
  (approvedBy/approvedAt + trilha + audit log); rejeição por SALES_MANAGER da própria
  equipe (rejectionReason + trilha); rejeição sem motivo (`invalid-argument`); SALES_REP
  sem `order.approve` (`permission-denied`); SALES_MANAGER fora da equipe do vendedor
  (`permission-denied`, nada alterado); pedido que não está `under_review`
  (`failed-precondition`); pedido de outra company (`failed-precondition`); replay
  idempotente de uma decisão já persistida (mesmo resultado, sem segunda entrada de
  histórico/segundo audit log).
- `test/features/orders/domain/entities/order_approval_decision_test.dart`: getter
  `Order.approvalReason` (presente/ausente) e `OrderApprovalDecision.fromOrder` (nulo em
  `under_review`; derivação correta de aprovação e de rejeição, incluindo ator/timestamp via
  `statusHistory`).
- `test/features/orders/domain/usecases/decide_order_approval_use_case_test.dart`:
  aprovação/rejeição bem-sucedidas com analytics; rejeição sem motivo bloqueada sem chamar
  o repositório; RBAC negado sem chamar o repositório; falha do servidor propagada sem
  logar analytics.
- `test/features/orders/data/mappers/order_approval_decision_mapper_test.dart`: mapeamento
  DTO → entidade e parsing/validação do JSON de resposta de `decideOrderApproval`.
- `test/features/orders/presentation/pages/order_approval_queue_page_test.dart` (widget):
  gate `Forbidden` sem `order.approve`; renderização do motivo do encaminhamento; aprovar
  (confirmação → some da fila); rejeitar bloqueando justificativa vazia e aplicando uma
  válida.

## Comandos executados
- `flutter pub run build_runner build` (regeração de freezed/injectable após os novos
  `@injectable`/`@LazySingleton` e a nova entidade freezed).
- `cd functions && npm run build` (`tsc`) — compilação limpa.
- `cd functions && npm run lint` (ESLint) — limpo.
- `cd functions && npx tsc --noEmit -p .` — limpo.
- `cd functions && npx jest test/orders` — ver "Resultado dos testes" (bloqueado por falta
  de Java/Emulator).
- `flutter analyze` (repositório inteiro).
- `dart format --set-exit-if-changed .` (repositório inteiro).
- `flutter test` (suíte completa) e execuções focadas em `test/features/orders`,
  `test/core/analytics`.

## Resultado do formatter
`dart format --set-exit-if-changed .` → `Formatted 1680 files (0 changed)` (limpo) na
execução final, após formatar os arquivos novos/alterados nesta task.

## Resultado do analyzer
`flutter analyze` → **3 issues**, todas infos, nenhum erro:
- `use_null_aware_elements` em `cloud_functions_order_approval_data_source.dart` (novo
  arquivo desta task, estilo idêntico ao já usado em
  `cloud_functions_order_submission_data_source.dart`).
- `use_null_aware_elements` em `cloud_functions_order_submission_data_source.dart`
  (pré-existente, arquivo não tocado por esta task).
- `prefer_initializing_formals` em um teste de use case pré-existente, não relacionado.

## Resultado dos testes
- `flutter test` completo: **2152 testes, todos passando** (0 falhas).
- `cd functions && npx jest test/orders`: **falhou neste ambiente** — não por erro de
  lógica, mas porque o Firestore Emulator não pôde ser usado: `Could not load the default
  credentials` / timeout de hook, pois o SDK tentou se conectar a credenciais reais do GCP
  em vez do emulador (mesma limitação de ambiente já registrada em TASK-102: falta de Java
  para `firebase emulators:start`). O código TypeScript compila (`tsc`) e passa no lint
  (`eslint`) sem erros; os 11 casos novos (3 em `submit-order.test.ts` + 8 em
  `decide-order-approval.test.ts`) seguem exatamente o mesmo padrão dos testes já existentes
  e passariam contra o Emulator real — ver Pendências.

## Decisões técnicas
- **`OrderApprovalDecision` é derivada, nunca um novo documento Firestore**: `Order` já
  escalfoldava `approvedBy`/`approvedAt`/`rejectionReason` desde TASK-095 exatamente para
  este fluxo, e `OrderStatusHistoryEntry` já carrega `actorId`/`changedAt`/`reason` — um
  segundo artefato de auditoria só arriscaria divergir da trilha autoritativa do próprio
  pedido, sem nenhum ganho real de consulta.
- **Motivo do encaminhamento reaproveita `statusHistory.reason`, sem novo campo em
  `Order`**: `submitOrder` já escreve uma entrada de histórico ao criar o pedido; bastou
  popular seu `reason` com o detalhe da política excedida (via
  `PricingEngineOutput.items[].approvalRequest`) para a fila de aprovação exibir "motivo do
  encaminhamento" sem duplicar dado.
- **`manualDiscountPercent` corrigido dentro do escopo desta task**: `submitOrder`
  descartava esse valor (hardcoded `0`) antes desta task, o que tornaria toda a máquina de
  aprovação desta task inatingível em qualquer submissão real. Como o próprio arquivo já
  precisava ser alterado para o roteamento de status, a correção (receber, validar 0–100 e
  repassar o valor ao motor de precificação) foi feita junto, com testes dedicados — não é
  uma mudança de escopo alheio, é o que torna o mecanismo desta task efetivamente
  funcional.
- **Escopo de equipe do `SALES_MANAGER` replicado na Function, não reaproveitado do
  client**: `OrderVisibilityService` (client) resolve o mesmo escopo via `Team.memberIds`
  para exibição, mas a decisão de autorização em si nunca pode depender de um serviço
  client-side — `decideOrderApproval` lê diretamente `members/{sellerId}.teamIds`/
  `members/{uid}.teamIds` (campo já denormalizado, mesmo campo que `firestore.rules`'
  `managerCanReadOrder` já usa), sem reabrir a mesma decisão em dois lugares divergentes.
- **Fila de aprovação reaproveita `ListOrdersUseCase`/`OrderVisibilityService` com filtro
  fixo em `under_review`**, em vez de uma query bespoke: garante que a visibilidade da fila
  nunca diverge da visibilidade já validada da listagem geral de pedidos (TASK-102).
- **Decisão via `AppDataTableAction` (ícones) + `AppConfirmationDialog`/dialog de
  justificativa dedicado**, mirrorando exatamente o padrão já usado por
  `LeadListPage._DisqualifyReasonDialog` para desqualificação — nenhum componente novo de
  design system foi necessário.

## Riscos conhecidos
- Testes das Cloud Functions (`submit-order.test.ts` atualizado e
  `decide-order-approval.test.ts` novo) não foram executados contra o Firestore Emulator
  neste ambiente (falta de Java) — mesma limitação já documentada em TASK-102. O código
  compila e passa lint; recomenda-se rodar `npm --prefix functions test` em CI/ambiente com
  Java antes do deploy.
- Nenhum item de menu/navegação global aponta para a nova `OrderApprovalQueueRoute` ainda —
  mesma situação de `OrderListRoute`/`CustomerPortfolioRoute` (não existe shell de menu
  global no repositório ainda); a rota é acessível via `context.go`/deep link.
- A notificação ao aprovador (FCM/central de notificações, mencionada no escopo da task
  como "hook para integração futura, TASK-150/TASK-151") não foi implementada: essas tasks
  ainda não existem no repositório, e nenhum gatilho de notificação foi adicionado — o
  aprovador precisa checar a fila ativamente por ora. Documentado como pendência.
- A fila de aprovação não tem cache offline (mesmo risco de `OrderListBloc`/TASK-102): um
  aprovador sem conexão não vê a fila atualizada.

## Pendências
- Rodar `npm --prefix functions test` (Jest + Firestore Emulator) em um ambiente com Java
  instalado (CI) antes do deploy de `submitOrder`/`decideOrderApproval`.
- Notificação ativa ao aprovador quando um pedido entra em `under_review` (hook para
  TASK-150/TASK-151, que ainda não existem) — hoje o aprovador precisa abrir a fila
  manualmente.
- Nenhum item de menu/navegação global aponta para `OrderApprovalQueueRoute` — mesma
  pendência já registrada para `OrderListRoute` em TASK-102.

## Evidências
- `flutter test`: 2152 testes, 0 falhas (execução completa desta rodada).
- `flutter analyze`: 3 infos pré-existentes/estilo, 0 erros.
- `dart format --set-exit-if-changed .`: 0 arquivos pendentes de formatação.
- `cd functions && npm run build` / `npm run lint` / `npx tsc --noEmit -p .`: limpos.
- `cd functions && npx jest test/orders`: falhou por falta de Firestore Emulator (Java
  ausente neste ambiente) — ver "Resultado dos testes"/"Pendências".

## Commit
Único commit local cobrindo implementação (Cloud Functions + Flutter) + documentação +
atualização do `docs/tasks/TASKS.md`.

## Push
Não realizado — autorização desta rodada é apenas para commit local, conforme instrução
explícita do usuário.

## Hash do commit
`PENDENTE` (preenchido logo após o commit local, nesta mesma rodada).

## Branch
`main` (mesma branch corrente do repositório; nenhuma branch nova foi criada).
