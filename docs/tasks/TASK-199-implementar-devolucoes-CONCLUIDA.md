# TASK-199 — Concluída (2026-09-09)

## Resumo
Implementado o fluxo completo de devolução (RMA) vinculado ao pedido original: modelo de
`ReturnRequest` com motivo obrigatório categorizado, Cloud Functions `createReturnRequest` (solicitação,
com validação de quantidade/status/RBAC) e `resolveReturnRequest` (decisão, com reposição de estoque
no warehouse de origem e transição do pedido para `partiallyReturned`/`returned` — o que aciona
automaticamente a reversão de comissão já existente no EPIC-29), Firestore/Storage Rules dedicadas,
RBAC (`Capability.returnRequestCreate`/`returnRequestApprove`), feature Flutter completa
(domain/data/presentation) e integração na tela de detalhe do pedido (histórico + botão "Solicitar
devolução") e uma fila de análise dedicada.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist

## Arquivos criados
- `functions/src/returns/return-shared.ts`
- `functions/src/returns/create-return-request.ts`
- `functions/src/returns/resolve-return-request.ts`
- `functions/src/returns/index.ts`
- `functions/test/returns/create-return-request.test.ts`
- `functions/test/returns/resolve-return-request.test.ts`
- `lib/features/returns/domain/value_objects/return_reason_category.dart`
- `lib/features/returns/domain/value_objects/return_request_status.dart`
- `lib/features/returns/domain/entities/return_request.dart`
- `lib/features/returns/domain/entities/return_request_item.dart`
- `lib/features/returns/domain/entities/return_request_decision.dart`
- `lib/features/returns/domain/entities/return_request_submission_result.dart`
- `lib/features/returns/domain/entities/return_request_decision_result.dart`
- `lib/features/returns/domain/repositories/return_request_repository.dart`
- `lib/features/returns/domain/usecases/create_return_request_use_case.dart`
- `lib/features/returns/domain/usecases/resolve_return_request_use_case.dart`
- `lib/features/returns/domain/usecases/watch_return_requests_for_order_use_case.dart`
- `lib/features/returns/domain/usecases/watch_return_request_queue_use_case.dart`
- `lib/features/returns/data/dtos/return_request_dto.dart`
- `lib/features/returns/data/dtos/return_request_submission_result_dto.dart`
- `lib/features/returns/data/dtos/return_request_decision_result_dto.dart`
- `lib/features/returns/data/mappers/return_request_mapper.dart`
- `lib/features/returns/data/datasources/return_request_read_data_source.dart`
- `lib/features/returns/data/datasources/firestore_return_request_data_source.dart`
- `lib/features/returns/data/datasources/return_request_write_data_source.dart`
- `lib/features/returns/data/datasources/cloud_functions_return_request_data_source.dart`
- `lib/features/returns/data/repositories/return_request_repository_impl.dart`
- `lib/features/returns/presentation/cubit/return_request_history_cubit.dart` (+ `..._state.dart`)
- `lib/features/returns/presentation/cubit/return_request_queue_cubit.dart` (+ `..._state.dart`)
- `lib/features/returns/presentation/cubit/return_request_form_cubit.dart` (+ `..._state.dart`)
- `lib/features/returns/presentation/pages/return_request_form_page.dart`
- `lib/features/returns/presentation/pages/return_request_analysis_page.dart`
- `lib/features/returns/presentation/widgets/return_request_history_section.dart`
- `lib/features/returns/returns.dart`
- `test/features/returns/data/mappers/return_request_mapper_test.dart`
- `test/features/returns/domain/usecases/create_return_request_use_case_test.dart`
- `test/features/returns/domain/usecases/resolve_return_request_use_case_test.dart`
- `test/features/returns/presentation/pages/return_request_form_page_test.dart`
- `docs/tasks/TASK-199-implementar-devolucoes-CONCLUIDA.md` (este arquivo)

## Arquivos alterados
- `functions/src/index.ts` (registra `createReturnRequest`/`resolveReturnRequest`)
- `functions/src/orders/submit-order.ts` (denormaliza `warehouseId` em cada item do pedido, para
  reposição de estoque rastreável na devolução)
- `firestore.rules` (collection `returnRequests`, mirror de `roleHasCapability`)
- `firestore.indexes.json` (3 índices compostos para `returnRequests`)
- `firestore-tests/firestore.rules.test.js` (describe `returnRequests` com testes positivos/negativos)
- `storage.rules` (path `returnRequests/{id}/evidence/{file}`, mirror de `roleHasCapability`)
- `storage-tests/storage.rules.test.js` (describe do path de evidência)
- `lib/core/permissions/capability.dart` (`Capability.returnRequestCreate`/`returnRequestApprove`)
- `lib/core/permissions/role_permission_matrix.dart` (concede as duas capabilities acima)
- `lib/core/storage/storage_paths.dart` (`StoragePaths.returnRequestEvidence`)
- `lib/core/analytics/analytics_events.dart` (`returnRequested`/`returnApproved`/`returnRejected`)
- `lib/core/navigation/app_route_paths.dart` (`ReturnRequestAnalysisRoute`)
- `lib/core/navigation/app_router.dart` (builder + `GoRoute` guardado por `returnRequestApprove`)
- `lib/app/bootstrap.dart` (wiring das novas páginas/rotas)
- `lib/app/injection.config.dart` (regenerado via `build_runner`)
- `lib/features/orders/domain/value_objects/order_status.dart` (`OrderStatus.partiallyReturned`/`returned`)
- `lib/features/orders/domain/services/order_status_transition_validator.dart` (transições para os
  dois novos status)
- `lib/features/orders/data/mappers/order_mapper.dart` (mapeamento dos dois novos status)
- `lib/features/orders/presentation/pages/order_list_page.dart` (label/badge/ícone dos dois novos status)
- `lib/features/orders/presentation/pages/order_history_page.dart` (botão "Solicitar devolução" +
  seção de histórico de devoluções)
- `test/core/permissions/role_permission_matrix_test.dart`
- `test/core/storage/storage_paths_test.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/features/orders/domain/services/order_status_transition_validator_test.dart`
- `docs/tasks/TASKS.md` (checkbox + progresso)

## Arquitetura utilizada
Clean Architecture feature-first: `domain` (entidades imutáveis simples, sem Flutter/Firebase;
repository contract; use cases com RBAC de defesa em profundidade) → `data` (DTOs com parsing
defensivo, mappers, datasource Firestore somente leitura via `watchQuery`, datasource de escrita
via `CloudFunctionsService`, repository impl convertendo exceptions em `AppFailure`) →
`presentation` (Cubits — `ReturnRequestHistoryCubit`, `ReturnRequestQueueCubit`,
`ReturnRequestFormCubit` — e páginas usando o design system). Nenhuma regra de negócio crítica na UI:
validação de quantidade/status/RBAC final sempre em `createReturnRequest`/`resolveReturnRequest`
(Cloud Functions, Admin SDK). Escrita no Firestore exclusivamente via Cloud Function; toda leitura via
Firestore Rules (`canReadReturnRequest`, espelhando `canReadOrder`).

## Regras de negócio implementadas
- Motivo sempre obrigatório e categorizado (`defect`/`wrong_item`/`change_of_mind`/`order_error`/
  `other`); texto livre (`reasonDetails`) nunca substitui a categoria.
- Quantidade por item nunca excede a quantidade original do item no pedido — validado server-side em
  `createReturnRequest` somando o que já está comprometido (`requested`/`approved`) em outras
  devoluções do mesmo pedido, e revalidado de novo em `resolveReturnRequest` (proteção contra corrida
  entre aprovações concorrentes).
- Devolução só pode ser solicitada para pedido em status pós-fulfillment (`invoiced`,
  `partially_invoiced`, `shipped`, `delivered`, `partially_returned`).
- Reposição de estoque e qualquer efeito financeiro só ocorrem após aprovação formal — nunca na
  simples solicitação.
- Aprovação reintegra a quantidade devolvida no warehouse de origem exato (denormalizado no item do
  pedido em `submitOrder`, TASK-101); pedidos anteriores a esta task (sem `warehouseId` salvo) caem em
  fallback para o primeiro saldo existente da mesma variante.
- Aprovação transiciona o pedido para `partiallyReturned` (nem todo item coberto) ou `returned` (toda a
  quantidade original de todo item já coberta por devoluções aprovadas) — ambos os status já eram
  reconhecidos por `isReversalOrderStatus` (EPIC-29/TASK-195), então essa mesma escrita já aciona a
  reversão automática de comissão via `calculateOrderCommissionOnWrite`, sem duplicar lógica de
  estorno aqui.
- Toda decisão (aprovação/recusa) é registrada com autor, timestamp e motivo em
  `ReturnRequest.decisions` e em `auditLogs`/`Order.statusHistory`.
- Isolamento multi-tenant: solicitar/decidir/ler uma devolução exige pertencer à mesma organização do
  pedido, com o mesmo escopo vendedor/equipe/organização já usado para `Order` (`OrderVisibilityService`
  reaproveitado para a fila de análise).
- RBAC: `SALES_REP`/`SALES_MANAGER`/`OWNER`/`ADMIN` podem solicitar (escopo próprio
  pedido/equipe/organização); apenas `SALES_MANAGER`/`OWNER`/`ADMIN` podem decidir — mesma assimetria
  já usada para `orderCreate` vs. `orderApprove`.
- Idempotência: `returnRequestId` é gerado no cliente (Cubit) e usado como chave/documento; retry
  nunca duplica a devolução nem reaplica a decisão.
- Impacto financeiro rastreável via `ReturnRequest.refundAmount` (soma dos itens) — emissão formal de
  nota de crédito/contas a receber é escopo do TASK-213 (ainda não implementado), documentado como
  pendência.

## Regras Firebase implementadas
- `firestore.rules`: `organizations/{organizationId}/returnRequests/{returnRequestId}` — leitura
  escopada por `canReadReturnRequest` (espelha `canReadOrder`: vendedor dono, gestor da mesma equipe,
  OWNER/ADMIN, portal do cliente); escrita sempre `false` (só Admin SDK via Cloud Function).
- `storage.rules`: `organizations/{organizationId}/returnRequests/{returnRequestId}/evidence/{fileName}`
  — upload/exclusão exigem `return.create`; leitura para qualquer membro ativo; valida imagem até 10MB.
- `firestore.indexes.json`: 3 índices compostos (`orderId+requestedAt`,
  `companyId+status+requestedAt`, `companyId+status+sellerId+requestedAt`).
- Testes de Rules escritos (Firestore e Storage) cobrindo casos positivos e negativos — ver
  "Pendências" quanto à execução.

## Analytics implementado
- `AnalyticsEvents.returnRequested` (ao solicitar), `returnApproved`/`returnRejected` (ao decidir) —
  registrados em `ReturnRequestFormCubit`/`ReturnRequestQueueCubit`, nunca com dado pessoal/texto livre
  do motivo.

## Crashlytics implementado
- Nenhuma integração nova direta; erros seguem o pipeline padrão (`CloudFunctionsService`/
  `AppException` → `AppFailure`) já coberto pelos handlers globais existentes.

## Impacto offline
- Solicitação e decisão de devolução exigem conectividade (Cloud Functions) — não há fila de Outbox
  dedicada nesta rodada; a tela usa o padrão existente de erro/retry do `CloudFunctionsService`
  (retry automático em erros transientes). Leitura (histórico/fila) é sempre via `watchQuery`
  (Firestore realtime), refletindo o cache local padrão do SDK quando offline.

## Impacto multi-tenant
- Toda entidade carrega `organizationId`/`companyId`; toda leitura passa por Firestore Rules
  reavaliando a Membership real do usuário (nunca confiando em campo enviado pelo cliente); a fila de
  análise reaproveita `OrderVisibilityService` (mesmo escopo de pedidos) em vez de reimplementar a
  lógica de equipe/gestor.

## Testes criados
- Cloud Functions (Jest, não executados neste ambiente — ver Pendências): `create-return-request.test.ts`
  (10 casos: sucesso, quantidade excedente, duplo comprometimento, status inelegível, motivo ausente,
  RBAC vendedor/gestor/portal, idempotência, isolamento de empresa) e `resolve-return-request.test.ts`
  (10 casos: aprovação com reposição no warehouse correto, aprovação total → `returned`, recusa sem
  efeito no estoque, motivo obrigatório na recusa, RBAC vendedor/gestor, decisão já finalizada,
  idempotência, isolamento de empresa).
- Firestore/Storage Rules (não executados neste ambiente — ver Pendências): describe blocks para
  `returnRequests` e para o path de evidência, com casos positivos/negativos de RBAC e isolamento.
- Flutter: `return_request_mapper_test.dart` (parsing/round-trip/reasonCategory desconhecida),
  `create_return_request_use_case_test.dart` e `resolve_return_request_use_case_test.dart` (RBAC,
  validação, propagação de falha do repositório), `return_request_form_page_test.dart` (widget: motivo
  obrigatório, item obrigatório, submissão bem-sucedida).
- Atualizados: `role_permission_matrix_test.dart` (novas capabilities), `storage_paths_test.dart`
  (`returnRequestEvidence`), `analytics_events_test.dart` (3 novos eventos),
  `order_status_transition_validator_test.dart` (matriz com `partiallyReturned`/`returned`).

## Comandos executados
- `npm run build` em `functions` (tsc) — sucesso.
- `npm run lint` em `functions` (eslint) — sucesso (apenas warnings pré-existentes).
- `dart run build_runner build` — sucesso (regenerou `injection.config.dart`).
- `flutter analyze` (repositório inteiro) — sucesso.
- `dart format --set-exit-if-changed .` (repositório inteiro) — sucesso após reverter 4 arquivos
  fora do escopo desta task que o formatter também teria alterado (drift de formatação pré-existente,
  não relacionado a TASK-199).
- `flutter test` (suíte completa, ~3297 testes) — sucesso, exceto 1 falha pré-existente e não
  relacionada (`test/app/bootstrap_test.dart`, `PushDeviceMapper` não registrado no GetIt — confirmado
  reproduzível também no `main` antes desta task, via `git stash`).

## Resultado do formatter
Sucesso: todos os arquivos desta task formatados sem pendências.

## Resultado do analyzer
`flutter analyze` no repositório inteiro: 18 infos/deprecations pré-existentes, nenhum relacionado a
TASK-199; 0 erros.

## Resultado dos testes
- `functions`: `npm run build`/`npm run lint` passaram (compilação/lint). Os testes Jest
  (`create-return-request.test.ts`, `resolve-return-request.test.ts`) e os testes de Rules
  (`firestore.rules.test.js`, `storage.rules.test.js`) **não puderam ser executados neste ambiente**:
  o Firebase Emulator Suite (Firestore/Auth/Storage) exige Java, que não está instalado nesta sandbox
  (`Could not spawn 'java -version'`). O código foi revisado cuidadosamente e segue o mesmo padrão de
  testes já usados/aprovados em `decide-order-approval.test.ts`/`submit-order.test.ts`, mas não afirmo
  tê-los executado com sucesso — apenas que compilam (`tsc`) e passam lint.
- Flutter: `flutter test` completo passou (exceto a falha pré-existente já documentada). Os testes
  novos da feature `returns` (mapper, use cases, widget) rodaram e passaram individualmente.

## Decisões técnicas
- `ReturnRequestStatus` modela apenas `requested`/`approved`/`rejected` (3 valores), não os 5 estágios
  literais de `tasks.md` ("solicitada/em análise/aprovada/recusada/concluída"): não há transição
  intermediária "em análise" sem efeito colateral nem uma etapa "concluída" separada da aprovação —
  reposição de estoque e atualização do pedido acontecem atomicamente na própria aprovação. Documentado
  explicitamente no código (`return_request_status.dart`).
- `resolveOrderStatusAfterApproval` decide `returned` vs. `partiallyReturned` comparando a soma de
  quantidades aprovadas (todas as devoluções aprovadas do pedido, incluindo a atual) contra a
  quantidade original de cada item do pedido — nunca client-side.
- Reaproveitado o par `isReversalOrderStatus`/`calculateOrderCommissionOnWrite` já existente do EPIC-29
  em vez de duplicar lógica de estorno de comissão: a aprovação da devolução apenas escreve o novo
  `Order.status`, e o trigger já existente cuida do resto.
- `submitOrder` passou a denormalizar `warehouseId` em cada item do pedido (campo aditivo, não quebra
  nenhum teste/consumidor existente) — é o único jeito de saber, de forma confiável, para qual
  warehouse reintegrar o estoque na devolução.
- Evidência fotográfica opcional implementada com o mesmo padrão já usado em `campaign_form_page.dart`
  (`image_picker` + `ImageUploadCompressor` + `StorageDataSource`), path dedicado
  `StoragePaths.returnRequestEvidence`.
- Fila de análise (`ReturnRequestAnalysisPage`/`WatchReturnRequestQueueUseCase`) reaproveita
  `OrderVisibilityService` (TASK-102) em vez de reimplementar a resolução vendedor/equipe/organização.

## Riscos conhecidos
- Testes de Cloud Functions e de Firestore/Storage Rules não foram executados neste ambiente (falta de
  Java para o Emulator Suite) — precisam rodar em CI/ambiente com Java antes do próximo deploy real.
- Reposição de estoque para pedidos anteriores a esta task (sem `warehouseId` salvo no item) usa
  fallback para o primeiro saldo existente da mesma variante, que pode não ser o warehouse de origem
  real — aceito conscientemente, documentado no código (`resolveRestockPlans`).
- Não há fluxo de Outbox/offline dedicado para solicitação/decisão de devolução; ambas exigem
  conectividade.

## Pendências
- Rodar `npm run test:functions` (Jest com Firestore/Auth emulator) e
  `firebase emulators:exec --only firestore,storage "npm --prefix firestore-tests test"` /
  `"npm --prefix storage-tests test"` em um ambiente com Java instalado, antes do deploy.
- Emissão formal de nota de crédito/lançamento em contas a receber vinculado à devolução — escopo do
  TASK-213 (contas a receber, faturas e cobrança), ainda não implementado.
- Avaliar, em uma futura iteração, se `ReturnRequestStatus` precisa de um estágio "em análise" explícito
  (hoje implícito em `requested`).

## Evidências
- `functions`: `npm run build` → sucesso; `npm run lint` → sucesso (0 erros).
- `dart run build_runner build` → sucesso, `injection.config.dart` registrou as novas classes.
- `flutter analyze` (repositório inteiro) → 0 erros.
- `flutter test` (repositório inteiro, ~3297 testes) → apenas 1 falha pré-existente e não
  relacionada a esta task.
- `flutter test test/features/returns/...` (17 testes novos) → todos passaram.

## Commit
`feat(returns): implementa fluxo de devolucao vinculado ao pedido (TASK-199)`

## Push
Não autorizado nesta rodada (push não solicitado pelo usuário).

## Hash do commit
Hash final informado no resumo da rodada e consultável via `git log`.

## Branch
`main`
