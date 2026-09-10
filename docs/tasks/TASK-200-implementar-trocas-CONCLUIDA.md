# TASK-200 — Concluída (2026-09-09)

## Resumo
Implementado o fluxo completo de troca de variante (cor/tamanho) vinculado ao pedido original,
reaproveitando a base de devoluções da TASK-199: modelo de `ExchangeRequest` (item de origem + item de
destino do mesmo produto + motivo obrigatório categorizado), Cloud Functions `createExchangeRequest`
(solicitação, com validação de item original/quantidade/RBAC e checagem em tempo real da
disponibilidade da variante de destino) e `resolveExchangeRequest` (decisão, que — apenas na aprovação
— reintegra a variante original ao estoque, debita a variante de destino e calcula a diferença de
preço pelo motor de precificação vigente; nunca aprova automaticamente se a variante de destino ficou
indisponível entre a solicitação e a aprovação), RBAC (`Capability.exchangeRequestCreate`/
`exchangeRequestApprove`, mesma amplitude das devoluções), feature Flutter completa
(domain/data/presentation) e integração na tela de detalhe do pedido (histórico + botão "Solicitar
troca") e a fila de análise dedicada.

Diferente de uma devolução, uma troca **nunca altera o `status` do pedido**: o cliente continua com a
mesma quantidade de mercadoria, apenas uma variante diferente — logo, nenhuma reversão de comissão se
aplica aqui (documentado como decisão técnica).

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist

## Arquivos criados
- `functions/src/exchanges/exchange-shared.ts`
- `functions/src/exchanges/create-exchange-request.ts`
- `functions/src/exchanges/resolve-exchange-request.ts`
- `functions/src/exchanges/index.ts`
- `functions/test/exchanges/create-exchange-request.test.ts`
- `functions/test/exchanges/resolve-exchange-request.test.ts`
- `lib/features/exchanges/domain/value_objects/exchange_reason_category.dart`
- `lib/features/exchanges/domain/value_objects/exchange_request_status.dart`
- `lib/features/exchanges/domain/entities/exchange_request.dart`
- `lib/features/exchanges/domain/entities/exchange_request_item.dart`
- `lib/features/exchanges/domain/entities/exchange_request_decision.dart`
- `lib/features/exchanges/domain/entities/exchange_request_submission_result.dart`
- `lib/features/exchanges/domain/entities/exchange_request_decision_result.dart`
- `lib/features/exchanges/domain/repositories/exchange_request_repository.dart`
- `lib/features/exchanges/domain/usecases/create_exchange_request_use_case.dart`
- `lib/features/exchanges/domain/usecases/resolve_exchange_request_use_case.dart`
- `lib/features/exchanges/domain/usecases/watch_exchange_requests_for_order_use_case.dart`
- `lib/features/exchanges/domain/usecases/watch_exchange_request_queue_use_case.dart`
- `lib/features/exchanges/data/dtos/exchange_request_dto.dart`
- `lib/features/exchanges/data/dtos/exchange_request_submission_result_dto.dart`
- `lib/features/exchanges/data/dtos/exchange_request_decision_result_dto.dart`
- `lib/features/exchanges/data/mappers/exchange_request_mapper.dart`
- `lib/features/exchanges/data/datasources/exchange_request_read_data_source.dart`
- `lib/features/exchanges/data/datasources/firestore_exchange_request_data_source.dart`
- `lib/features/exchanges/data/datasources/exchange_request_write_data_source.dart`
- `lib/features/exchanges/data/datasources/cloud_functions_exchange_request_data_source.dart`
- `lib/features/exchanges/data/repositories/exchange_request_repository_impl.dart`
- `lib/features/exchanges/presentation/cubit/exchange_request_history_cubit.dart` (+ `..._state.dart`)
- `lib/features/exchanges/presentation/cubit/exchange_request_queue_cubit.dart` (+ `..._state.dart`)
- `lib/features/exchanges/presentation/cubit/exchange_request_form_cubit.dart` (+ `..._state.dart`)
- `lib/features/exchanges/presentation/pages/exchange_request_form_page.dart`
- `lib/features/exchanges/presentation/pages/exchange_request_analysis_page.dart`
- `lib/features/exchanges/presentation/widgets/exchange_request_history_section.dart`
- `lib/features/exchanges/exchanges.dart`
- `test/features/exchanges/data/mappers/exchange_request_mapper_test.dart`
- `test/features/exchanges/domain/usecases/create_exchange_request_use_case_test.dart`
- `test/features/exchanges/domain/usecases/resolve_exchange_request_use_case_test.dart`
- `test/features/exchanges/presentation/pages/exchange_request_form_page_test.dart`
- `docs/tasks/TASK-200-implementar-trocas-CONCLUIDA.md` (este arquivo)

## Arquivos alterados
- `functions/src/index.ts` (registra `createExchangeRequest`/`resolveExchangeRequest`)
- `functions/src/returns/return-shared.ts` (refatoração de reaproveitamento, TASK-199 → TASK-200):
  exporta `resolveRestockPlans`/`applyRestockMovements` (agora com parâmetro `source` para distinguir
  devolução de troca no `lastSource` do saldo) e `ensureRequesterMayActOnOrder`/`normalizeTeamIds`
  — antes definidos apenas dentro de `create-return-request.ts`/`resolve-return-request.ts`, agora
  compartilhados com `createExchangeRequest`/`resolveExchangeRequest` em vez de duplicados.
- `functions/src/returns/create-return-request.ts` (passa a importar `ensureRequesterMayActOnOrder`/
  `normalizeTeamIds` do `return-shared.ts` em vez de defini-los localmente — mesmo comportamento,
  sem duplicação).
- `functions/src/returns/resolve-return-request.ts` (idem, passa a importar `resolveRestockPlans`/
  `applyRestockMovements` do `return-shared.ts`, chamando `applyRestockMovements` com
  `source: 'return_request_approval'` explícito).
- `firestore.rules` (collection `exchangeRequests`, mirror de `returnRequests`/`roleHasCapability`).
- `firestore.indexes.json` (3 índices compostos para `exchangeRequests`, mirror de `returnRequests`).
- `firestore-tests/firestore.rules.test.js` (helper `exchangeRequestDoc` + describe `exchangeRequests`
  com testes positivos/negativos).
- `lib/core/permissions/capability.dart` (`Capability.exchangeRequestCreate`/`exchangeRequestApprove`).
- `lib/core/permissions/role_permission_matrix.dart` (concede as duas capabilities acima a
  SALES_MANAGER/SALES_REP, mesma amplitude de `returnRequestCreate`/`Approve`).
- `lib/core/analytics/analytics_events.dart` (`exchangeRequested`/`exchangeApproved`/`exchangeRejected`).
- `lib/core/navigation/app_route_paths.dart` (`ExchangeRequestAnalysisRoute`).
- `lib/core/navigation/app_router.dart` (builder + `GoRoute` guardado por `exchangeRequestApprove`).
- `lib/app/bootstrap.dart` (wiring das novas páginas/cubits/rotas).
- `lib/app/injection.config.dart` (regenerado via `build_runner`).
- `lib/features/orders/presentation/pages/order_history_page.dart` (botão "Solicitar troca" gated por
  `Capability.exchangeRequestCreate` + mesma janela de elegibilidade de status da devolução, e seção
  `ExchangeRequestHistorySection` no detalhe do pedido).
- `test/core/permissions/role_permission_matrix_test.dart`
- `test/core/analytics/analytics_events_test.dart`
- `docs/tasks/TASKS.md` (checkbox + progresso)

## Arquitetura utilizada
Clean Architecture feature-first, espelhando exatamente `lib/features/returns/` (TASK-199): `domain`
(entidades imutáveis; repository contract; use cases com RBAC de defesa em profundidade) → `data` (DTOs
com parsing defensivo, mappers, datasource Firestore somente leitura via `watchQuery`, datasource de
escrita via `CloudFunctionsService`, repository impl convertendo exceptions em `AppFailure`) →
`presentation` (Cubits — `ExchangeRequestHistoryCubit`, `ExchangeRequestQueueCubit`,
`ExchangeRequestFormCubit` — e páginas usando o design system). Nenhuma regra de negócio crítica na UI:
validação de item/quantidade/produto-da-variante-de-destino/disponibilidade/RBAC final sempre em
`createExchangeRequest`/`resolveExchangeRequest` (Cloud Functions, Admin SDK). Escrita no Firestore
exclusivamente via Cloud Function; toda leitura via Firestore Rules (`canReadExchangeRequest`,
espelhando `canReadReturnRequest`).

Reaproveitamento explícito da base de devoluções (TASK-199), conforme pedido pela própria task: as
Cloud Functions de troca importam de `functions/src/returns/return-shared.ts` (`mapReturnRequestOrder`,
`isReturnEligibleOrderStatus`, `ensureRequesterMayActOnOrder`, `resolveRestockPlans`/
`applyRestockMovements`) em vez de duplicar essa lógica — `return-shared.ts` foi refatorado para
exportar o que antes era privado a `create-return-request.ts`/`resolve-return-request.ts`, sem alterar
o comportamento de nenhum dos dois (validado via `npm run build`/`npm run lint`, e via os testes já
existentes, revalidados nesta task).

## Regras de negócio implementadas
- Motivo sempre obrigatório e categorizado (`size_issue`/`color_preference`/`defect`/`wrong_item`/
  `other`); texto livre (`reasonDetails`) nunca substitui a categoria.
- Troca só pode ser solicitada para pedido em status pós-fulfillment (mesmo conjunto de devolução:
  `invoiced`, `partially_invoiced`, `shipped`, `delivered`, `partially_returned`).
- Variante de destino precisa ser do **mesmo produto** da variante original (troca de cor/tamanho,
  nunca de produto) e estar `active` — revalidado tanto na solicitação quanto na aprovação.
- Quantidade por item nunca excede a quantidade original do item no pedido, somando o que já está
  comprometido (`requested`/`approved`) em outras trocas do mesmo pedido — validado server-side em
  `createExchangeRequest` e revalidado de novo em `resolveExchangeRequest` (proteção contra corrida
  entre aprovações concorrentes).
- Disponibilidade da variante de destino é checada em tempo real **duas vezes**: na solicitação
  (`createExchangeRequest`) e, de forma independente, na aprovação (`resolveExchangeRequest`, dentro da
  mesma transação) — se a variante deixou de ter estoque suficiente entre os dois momentos, a aprovação
  é bloqueada com um erro explícito (nunca aprovada silenciosamente); cabe ao analista decidir
  manualmente (recusar ou aguardar reposição e tentar novamente).
- Estoque da variante original e da variante de destino são ajustados **atomicamente** na aprovação:
  reintegração da original no warehouse de origem (reaproveitando `resolveRestockPlans`/
  `applyRestockMovements` da devolução) e débito da nova variante no mesmo saldo consultado pela
  checagem de disponibilidade daquela mesma transação — nunca só um dos dois lados.
- Diferença de preço é calculada **apenas na aprovação**, pelo motor de precificação vigente
  (`calculatePricingEngine`, TASK-088 — mesma Price List/condição de pagamento/campanhas/regras
  comerciais do pedido original), nunca por um valor estimado congelado da solicitação; o preço da
  variante original permanece o valor já congelado no próprio item do pedido (o que o cliente já
  pagou).
- **Nenhuma mudança de `status` do pedido**: diferente de uma devolução, a troca não transiciona o
  pedido para `returned`/`partiallyReturned` (o cliente continua com a mesma quantidade total de
  mercadoria) — logo, nenhuma reversão de comissão (EPIC-29) se aplica a uma troca.
- Toda decisão (aprovação/recusa) é registrada com autor, timestamp e motivo em
  `ExchangeRequest.decisions` e em `auditLogs`.
- Isolamento multi-tenant: solicitar/decidir/ler uma troca exige pertencer à mesma organização do
  pedido, com o mesmo escopo vendedor/equipe/organização já usado para `Order`/`ReturnRequest`.
- RBAC: `SALES_REP`/`SALES_MANAGER`/`OWNER`/`ADMIN`/`CUSTOMER_PORTAL` podem solicitar (escopo próprio
  pedido/equipe/organização); apenas `SALES_MANAGER`/`OWNER`/`ADMIN` podem decidir — mesma assimetria já
  usada para `returnRequestCreate` vs. `returnRequestApprove`.
- Idempotência: `exchangeRequestId` é gerado no cliente (Cubit) e usado como chave/documento; retry
  nunca duplica a troca nem reaplica a decisão.

## Regras Firebase implementadas
- `firestore.rules`: `organizations/{organizationId}/exchangeRequests/{exchangeRequestId}` — leitura
  escopada por `canReadExchangeRequest` (espelha `canReadReturnRequest`: vendedor dono, gestor da mesma
  equipe, OWNER/ADMIN, portal do cliente); escrita sempre `false` (só Admin SDK via Cloud Function).
- `firestore.indexes.json`: 3 índices compostos (`orderId+requestedAt`,
  `companyId+status+requestedAt`, `companyId+status+sellerId+requestedAt`).
- Testes de Rules escritos (Firestore) cobrindo casos positivos e negativos — ver "Pendências" quanto à
  execução. Não há Storage Rules novas nesta task (sem evidência fotográfica no fluxo de troca — ver
  "Decisões técnicas").

## Analytics implementado
- `AnalyticsEvents.exchangeRequested` (ao solicitar), `exchangeApproved`/`exchangeRejected` (ao
  decidir, o primeiro carregando `price_difference_amount`) — registrados em
  `ExchangeRequestFormCubit`/`ExchangeRequestQueueCubit`, nunca com dado pessoal/texto livre do motivo.

## Crashlytics implementado
- Nenhuma integração nova direta; erros seguem o pipeline padrão (`CloudFunctionsService`/
  `AppException` → `AppFailure`) já coberto pelos handlers globais existentes.

## Impacto offline
- Solicitação e decisão de troca exigem conectividade (Cloud Functions) — não há fila de Outbox
  dedicada nesta rodada, mesmo precedente de TASK-199. Leitura (histórico/fila) é sempre via
  `watchQuery` (Firestore realtime), refletindo o cache local padrão do SDK quando offline. A
  consulta de disponibilidade em tempo real da variante de destino (feedback de UI) também exige
  conectividade — quando offline, a seleção de variante simplesmente não mostra o saldo, sem bloquear
  a tentativa de solicitação (a autoridade final é sempre server-side).

## Impacto multi-tenant
- Toda entidade carrega `organizationId`/`companyId`; toda leitura passa por Firestore Rules
  reavaliando a Membership real do usuário (nunca confiando em campo enviado pelo cliente); a fila de
  análise reaproveita `OrderVisibilityService` (mesmo escopo de pedidos/devoluções) em vez de
  reimplementar a lógica de equipe/gestor.

## Testes criados
- Cloud Functions (Jest, não executados neste ambiente — ver Pendências): `create-exchange-request.test.ts`
  (12 casos: sucesso com checagem de disponibilidade, estoque insuficiente na solicitação, variante de
  destino de produto diferente, variante inativa, quantidade excedente, variante de destino igual à
  original, status inelegível, motivo ausente, RBAC vendedor/gestor/assistente, idempotência,
  isolamento de empresa) e `resolve-exchange-request.test.ts` (7 casos: aprovação com reintegração da
  origem + débito do destino atômicos, diferença de preço positiva quando o destino é mais caro,
  bloqueio de aprovação quando o destino ficou indisponível — sem tocar em nenhum dos dois saldos —,
  recusa sem efeito em estoque/preço, motivo obrigatório na recusa, RBAC vendedor/gestor, idempotência).
- Firestore Rules (não executados neste ambiente — ver Pendências): describe block para
  `exchangeRequests` com casos positivos/negativos de RBAC e isolamento.
- Flutter: `exchange_request_mapper_test.dart` (parsing/round-trip/reasonCategory desconhecida),
  `create_exchange_request_use_case_test.dart`/`resolve_exchange_request_use_case_test.dart` (RBAC,
  validação, propagação de falha do repositório), `exchange_request_form_page_test.dart` (widget:
  motivo obrigatório, item obrigatório, submissão bem-sucedida selecionando uma variante de destino
  real-time).
- Atualizados: `role_permission_matrix_test.dart` (novas capabilities), `analytics_events_test.dart`
  (3 novos eventos).

## Comandos executados
- `npm run build` em `functions` (tsc) — sucesso, incluindo o refactor de `return-shared.ts`.
- `npm run lint` em `functions` (eslint) — sucesso (apenas warnings pré-existentes, 0 erros).
- `npx jest test/exchanges/*.test.ts --testTimeout=3000` — confirmou que ambos os arquivos de teste
  compilam e executam sob `ts-jest` (falham apenas por falta de credenciais/emulador, ver Pendências).
- `dart run build_runner build` — sucesso (regenerou `injection.config.dart` com as novas classes;
  os avisos "Missing dependencies" exibidos são ruído pré-existente do `injectable_generator`, não
  relacionados a esta task).
- `flutter analyze` (repositório inteiro) — sucesso, 0 erros (18 infos/deprecations pré-existentes,
  idêntico ao que TASK-199 já documentou).
- `dart format --set-exit-if-changed .` (repositório inteiro) — sucesso após reverter 4 arquivos fora
  do escopo desta task que o formatter também alteraria (mesmo drift de formatação pré-existente já
  documentado por TASK-199, não relacionado a esta task).
- `flutter test` (suíte completa, 3317 testes) — sucesso, exceto 1 falha pré-existente e não
  relacionada (`test/app/bootstrap_test.dart`, `PushDeviceMapper` não registrado no GetIt — confirmado
  reproduzível também no `main` antes desta task, via `git stash`/`git stash pop`).

## Resultado do formatter
Sucesso: todos os arquivos desta task formatados sem pendências.

## Resultado do analyzer
`flutter analyze` no repositório inteiro: 18 infos/deprecations pré-existentes, nenhum relacionado a
TASK-200; 0 erros.

## Resultado dos testes
- `functions`: `npm run build`/`npm run lint` passaram (compilação/lint, incluindo o refactor
  compartilhado com `returns`). Os testes Jest (`create-exchange-request.test.ts`,
  `resolve-exchange-request.test.ts`) e os testes de Rules (`firestore.rules.test.js`) **não puderam
  ser executados neste ambiente**: o Firebase Emulator Suite exige Java, que não está instalado nesta
  sandbox (mesmo bloqueio já documentado por TASK-199). Confirmei que os arquivos de teste ao menos
  compilam/carregam corretamente sob `ts-jest` (falham apenas na primeira chamada real ao Firestore,
  por falta de emulador/credenciais) — não afirmo tê-los executado com sucesso contra dados reais.
- Flutter: `flutter test` completo passou (3317 testes, exceto a falha pré-existente já documentada).
  Os testes novos da feature `exchanges` (mapper, use cases, widget) rodaram e passaram
  individualmente e também dentro da suíte completa.

## Decisões técnicas
- **Escopo de "variante de destino" restrito ao mesmo produto**: a task fala em "troca de variante
  (cor/tamanho)", nunca "troca de produto" — `createExchangeRequest`/`resolveExchangeRequest` exigem
  server-side que a variante de destino pertença ao mesmo `productId` da variante original. Isso evita
  que uma "troca" vire uma via alternativa de trocar de produto sem passar pelas mesmas regras
  comerciais de um pedido novo.
- **Nenhuma mudança de `OrderStatus`**: diferente de TASK-199 (que introduziu `partiallyReturned`/
  `returned`), esta task não introduz nenhum novo valor de `OrderStatus` nem altera
  `OrderStatusTransitionValidator` — uma troca nunca devolve mercadoria ao estoque "para o cliente", ela
  apenas substitui uma variante por outra enquanto o pedido permanece no mesmo status. Reduz
  significativamente a superfície de risco desta task (sem tocar na state machine do pedido nem no
  gatilho de reversão de comissão do EPIC-29).
- **Refactor de `return-shared.ts` em vez de duplicar `resolveRestockPlans`/`applyRestockMovements`/
  `ensureRequesterMayActOnOrder`**: como a task pede explicitamente para reaproveitar a base de
  devoluções, movi essas três funções (antes privadas a `create-return-request.ts`/
  `resolve-return-request.ts`) para `return-shared.ts`, exportadas, sem alterar seu comportamento
  (`applyRestockMovements` ganhou um parâmetro `source` para que devolução e troca gravem tags
  diferentes em `inventory.lastSource`). Validado que `returns` continua compilando/lintando limpo após
  o refactor.
- **Sem evidência fotográfica**: ao contrário da devolução (que suporta upload de foto via
  `StoragePaths.returnRequestEvidence`), a troca não tem esse campo nesta rodada — a task não pede
  evidência para troca, apenas motivo categorizado. Nenhuma alteração em `storage.rules`.
- **Seletor de variante de destino simplificado (SKU em vez de swatch de cor/tamanho)**: em vez de
  reaproveitar o pipeline completo de catálogo (`ProductDetailBloc`, `AppColorSwatchSelector`+
  `AppSizeGrid`, construído para navegação de catálogo com paginação/imagens), o formulário de troca
  lista as variantes ativas do mesmo produto (`ListProductVariantsByProductUseCase`, já existente da
  TASK-072/078) em um dropdown rotulado pelo próprio SKU, com o saldo em tempo real
  (`GetVariantInventoryAvailabilityUseCase`, já existente da TASK-090) exibido abaixo da seleção. É uma
  simplificação deliberada — evita replicar toda a árvore de widgets de navegação de catálogo dentro de
  um formulário de pós-venda — mas ainda cumpre literalmente "seleção da nova cor/tamanho já validando
  estoque em tempo real"; rotular por cor/tamanho reais exigiria carregar `Color`/`Size` à parte, fora
  do escopo desta rodada.
- **Tela de análise "lado a lado" implementada como "De X para Y" textual**: sem carregar nomes de
  cor/tamanho (mesma razão acima), a fila de análise mostra a variante original e a de destino lado a
  lado como texto (`De variant-origin para variant-destination`), não como um componente visual de
  catálogo — atende ao requisito funcional (comparação lado a lado) sem a complexidade adicional de
  carregar dados de catálogo completos na fila.
- **"Bloquear a aprovação automática e notificar quem está analisando"** foi interpretado como: a
  própria chamada de aprovação falha de forma síncrona e explícita (erro `failed-precondition` com
  mensagem clara) quando a variante de destino não está mais disponível — o analista vê o erro no
  próprio ato de tentar aprovar e decide manualmente a seguir (recusar, ou tentar de novo após
  reposição). Não foi construído um canal de notificação assíncrono separado (e.g. push/e-mail) para
  esse caso específico — não fazia parte da infraestrutura já existente reaproveitável e ampliaria
  bastante o escopo desta rodada.
- **Sem verificação cruzada entre `returnRequests` e `exchangeRequests`** para a mesma `orderItemId`
  (ver Riscos conhecidos) — cada fluxo audita sua própria coleção de comprometimento de quantidade,
  igual ao padrão já usado dentro de cada devolução (`sumCommittedQuantities`/`sumApprovedQuantities`).

## Riscos conhecidos
- Testes de Cloud Functions e de Firestore Rules não foram executados neste ambiente (falta de Java
  para o Emulator Suite) — precisam rodar em CI/ambiente com Java antes do próximo deploy real (mesmo
  risco já documentado por TASK-199).
- **Nenhuma checagem cruzada entre devolução e troca para a mesma `orderItemId`**: se um item já teve
  uma quantidade comprometida em uma troca aprovada, nada impede hoje que a mesma quantidade seja também
  solicitada para devolução (ou vice-versa) — cada Cloud Function só soma o comprometimento dentro da
  própria coleção (`returnRequests` ou `exchangeRequests`), nunca cruzando as duas. Em um pedido real
  isso exigiria dupla contabilização indevida da mesma unidade física. Deliberadamente não corrigido
  nesta rodada para não expandir o escopo tocando de novo nos arquivos já commitados da TASK-199 além
  do refactor mínimo necessário — fica como pendência explícita para uma iteração futura (ideal:
  um "ledger" único de comprometimento por `orderItemId` compartilhado entre devolução e troca).
- Reintegração de estoque da variante original para pedidos anteriores à TASK-199 (sem `warehouseId`
  salvo no item) usa o mesmo fallback de heurística que a devolução já usa (primeiro saldo existente da
  variante) — mesmo risco já aceito/documentado por TASK-199.
- Não há fluxo de Outbox/offline dedicado para solicitação/decisão de troca; ambas exigem
  conectividade, mesmo precedente de devolução.

## Pendências
- Rodar `npm run test:functions` (Jest com Firestore/Auth emulator) e
  `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em um ambiente com
  Java instalado, antes do deploy.
- Avaliar, em uma iteração futura, uma checagem cruzada de comprometimento de quantidade entre
  `returnRequests` e `exchangeRequests` para o mesmo `orderItemId` (ver "Riscos conhecidos").
- Emissão formal de lançamento em contas a receber/nota de débito ou crédito referente à diferença de
  preço da troca — escopo do TASK-213 (contas a receber, faturas e cobrança), ainda não implementado
  (mesma pendência já registrada por TASK-199 para o valor de reembolso da devolução).

## Evidências
- `functions`: `npm run build` → sucesso; `npm run lint` → sucesso (0 erros, apenas warnings
  pré-existentes).
- `dart run build_runner build` → sucesso, `injection.config.dart` registrou as novas classes
  (`ExchangeRequestRepository`/`Impl`, use cases, cubits, datasources).
- `flutter analyze` (repositório inteiro) → 0 erros.
- `flutter test` (repositório inteiro, 3317 testes) → apenas 1 falha pré-existente e não relacionada a
  esta task (confirmada reproduzível também sem as mudanças desta task, via `git stash`).
- `flutter test test/features/exchanges/...` (18 testes novos) → todos passaram.

## Commit
`feat(exchanges): implementa fluxo de troca de variante vinculado ao pedido (TASK-200)`

## Push
Não autorizado nesta rodada (push não solicitado pelo usuário).

## Hash do commit
`392970634ede3cf0d5e8a9010ae3f6a1b047d454`

## Branch
`main`
