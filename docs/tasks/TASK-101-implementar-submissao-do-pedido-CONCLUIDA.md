# TASK-101 — Concluída (2026-08-31)

## Resumo
Implementada a submissão real de pedidos (EPIC-13): a Cloud Function idempotente
`submitOrder`, que gera o número único de pedido server-side (contador transacional
por organização/empresa), revalida server-side as mesmas condições de TASK-100
(cliente ativo, tabela de preço vigente, condição de pagamento, desconto dentro da
política, disponibilidade de estoque), grava a transição `-> submitted` com sua
`OrderStatusHistoryEntry`, movimenta estoque (consumo de reserva quando informada,
decremento direto quando não) e nunca duplica um pedido sob reenvio/concorrência.
No client, foi criada a cadeia Clean completa (entidade, repositório, use case,
datasource/repositório de dados) para chamar essa Function, e o CTA "Enviar
pedido" de `OrderDraftPage` (deixado propositalmente não wireado pela TASK-100)
foi conectado em `bootstrap.dart`, reconciliando o rascunho local com o resultado
autoritativo do servidor após o envio.

## Agentes utilizados
- `flutter-senior-architect`

## Arquivos criados
- `functions/src/orders/submit-order.ts` — Cloud Function `submitOrder`.
- `functions/test/orders/submit-order.test.ts` — 10 testes contra o Firestore Emulator real (via `firebase emulators:exec`).
- `lib/features/orders/domain/entities/order_submission_result.dart`
- `lib/features/orders/domain/repositories/order_submission_repository.dart`
- `lib/features/orders/domain/usecases/submit_order_use_case.dart`
- `lib/features/orders/data/dtos/order_submission_result_dto.dart`
- `lib/features/orders/data/datasources/order_submission_data_source.dart`
- `lib/features/orders/data/datasources/cloud_functions_order_submission_data_source.dart`
- `lib/features/orders/data/mappers/order_submission_mapper.dart`
- `lib/features/orders/data/repositories/order_submission_repository_impl.dart`
- `test/features/orders/domain/usecases/submit_order_use_case_test.dart`
- `test/features/orders/data/mappers/order_submission_mapper_test.dart`

## Arquivos alterados
- `functions/src/orders/index.ts` — passou a exportar `submitOrder` (estava vazio, reservado pela TASK-015).
- `functions/src/index.ts` — registrou `submitOrder` como Cloud Function exportada.
- `functions/src/pricing/calculate-pricing.ts` — exportou os helpers de carregamento/validação de Price List, Payment Term, itens de tabela, política de desconto e campanhas (`mapPriceList`, `ensureActivePriceList`, `mapPaymentTerm`, `ensureValidPaymentTerm`, `mapPriceListItem`, `mapDiscountPolicy`, `mapCampaign`, `ensureCompanyScope`, `normalizeCurrency`, `optionalString`, `serializeDate`, `normalizeItem`, `requireNonEmptyString`), sem alterar nenhum comportamento existente, para que `submitOrder` reutilize exatamente a mesma lógica do motor de precificação (TASK-088) em vez de duplicá-la.
- `lib/features/orders/orders.dart` — barrel com as novas exportações da submissão.
- `lib/app/bootstrap.dart` — wireou `onSubmitOrder` em `OrderDraftPage`, adicionando a função `_submitOrder` (chama `SubmitOrderUseCase`, reconcilia o rascunho local via `SaveOrderDraftUseCase`, mostra `SnackBar` de sucesso/falha e navega para `CatalogHomeRoute` — não existe ainda tela de confirmação/listagem de pedidos, isso é escopo da TASK-102).
- `lib/app/injection.config.dart` — regenerado via `build_runner` para registrar os novos componentes de DI.
- `docs/tasks/TASKS.md` — checkbox da TASK-101 marcado e progresso incrementado para 101/220.

## Arquitetura utilizada
Clean Architecture feature-first, mantendo o padrão já estabelecido pela feature de
pricing (TASK-088/TASK-099): `OrderDraftPage` (UI) → `SubmitOrderUseCase` (domain) →
`OrderSubmissionRepository` (contrato) → `OrderSubmissionRepositoryImpl` (data) →
`CloudFunctionsOrderSubmissionDataSource` → `CloudFunctionsService` → Cloud Function
`submitOrder`. Nenhuma regra de negócio ficou na UI; `OrderDraftPage` não foi
alterada (o contrato `onSubmitOrder` já existia da TASK-100) — toda a orquestração
de negócio vive em `SubmitOrderUseCase`/Cloud Function, e o wiring em
`bootstrap.dart` é só orquestração de navegação/reconciliação local, mesmo padrão
já usado por `onContinueToProducts`.

## Regras de negócio implementadas
- **Idempotência por `orderId`**: o Firestore usa `orders/{orderId}` (o próprio
  `Order.id`, uuid já gerado localmente na criação do rascunho, TASK-096) como
  chave de idempotência e id do documento — reenvio (duplo toque, retry de rede)
  sempre resolve para o mesmo resultado, nunca cria um segundo pedido. Verificado
  sob concorrência real (duas chamadas simultâneas com a mesma chave) no Firestore
  Emulator.
- **Número de pedido único e sequencial**, gerado exclusivamente pela Cloud
  Function via um contador transacional por `organizationId`/`companyId`
  (`orderNumberSequences/{companyId}`), nunca pelo client.
- **Revalidação server-side** das mesmas condições de TASK-100: cliente ativo
  (status `active`), tabela de preço vigente (status `active` + dentro de
  `validFrom`/`validTo`, verificação que `calculatePricing` ainda não fazia — foi
  adicionada aqui), condição de pagamento ativa e compatível com a tabela, e
  desconto dentro da política (reaproveitando `calculatePricingEngine`,
  TASK-088).
- **Trilha de status**: toda submissão bem-sucedida grava exatamente uma
  `OrderStatusHistoryEntry` (`previousStatus: null -> newStatus: submitted`).
- **Movimentação de estoque**: quando o item carrega um `reservationId` (TASK-092),
  a reserva é consumida (mesma lógica de `consumeStockReservation`: decrementa
  `physicalQuantity`/`reservedQuantity` juntos e marca a reserva `consumed`).
  Sem `reservationId`, decrementa diretamente o saldo físico do depósito com saldo
  vendável suficiente. Nenhum ponto do fluxo de rascunho (TASK-096/097/098) cria
  reservas ainda, então hoje todo pedido segue o caminho de decremento direto — o
  suporte a reserva fica pronto para quando um fluxo futuro passar a reservar
  durante a montagem do pedido.
- **Determinismo sob falha**: toda a leitura+validação+escrita roda dentro de uma
  única `db.runTransaction` (com `maxAttempts: 10`, acima do padrão de 5, por
  tocar 3 documentos contenciosos ao mesmo tempo) — uma falha em qualquer ponto
  reverte tudo; nunca fica um pedido meio-criado.
- **Autorização**: apenas OWNER/ADMIN/SALES_MANAGER/SALES_REP (mesmo conjunto de
  `Capability.orderCreate`) podem submeter, e apenas o próprio vendedor
  (`sellerId === request.auth.uid`) — nunca confiando em `organizationId`/
  `sellerId` do client como autorização.

## Regras Firebase implementadas
Nenhuma alteração em `firestore.rules` nesta task: a escrita de
`organizations/{organizationId}/orders/{orderId}` é feita exclusivamente pela
Cloud Function via Admin SDK (que ignora as Rules), e não existe ainda leitura
client-side desses documentos (a listagem/detalhe de pedidos é escopo da
TASK-102) — regras de leitura com RBAC de visibilidade (vendedor vê só os
próprios, gestor vê da equipe) ficam propositalmente para lá, quando o padrão de
consulta real existir.

## Analytics implementado
`SubmitOrderUseCase` loga `AnalyticsEvents.orderSubmitted` (evento já existente na
taxonomia, `lib/core/analytics/analytics_events.dart`) com
`organization_id`/`company_id`/`order_id`/`order_number`/`status`/`total`/
`item_count`, somente em caso de sucesso — mesmo padrão de só logar o funil
comercial positivo já usado por `orderCreated`/`productAddedToOrder`.

## Crashlytics implementado
Nenhuma mudança direta — falhas de submissão (validação/permissão/precondição)
são erros de negócio esperados, tratados como `AppFailure`/`HttpsError`, não como
crash. `configureGlobalErrorHandlers` (já existente) continua cobrindo qualquer
erro inesperado não tratado.

## Impacto offline
Pedido enviado offline continua em `pending_sync`/`draft` localmente até a Function
confirmar `submitted` — `_submitOrder` (bootstrap.dart) só atualiza o rascunho
local (`status`/`syncStatus: synced`/nova `OrderStatusHistoryEntry`) depois de uma
resposta de sucesso da Function; uma falha de conectividade nunca altera o estado
local, e o resultado (sucesso ou falha) é sempre mostrado via `SnackBar` — nunca
silencioso. Um retry automático de fila (Outbox completo) é EPIC-14, ainda não
implementado; por ora, o vendedor precisa tocar "Enviar pedido" novamente quando
a conexão voltar, o que é seguro graças à idempotência por `orderId`.

## Impacto multi-tenant
Toda leitura/escrita da Function é escopada por `organizationId` (via
`organizations/{organizationId}/...`) e revalida `companyId` em cada entidade
lida (cliente, tabela de preço, condição de pagamento, itens de tabela,
campanhas) — nunca confia no `organizationId`/`companyId` do client como
autorização, sempre teatro contra a Membership real do chamador.

## Testes criados
- `functions/test/orders/submit-order.test.ts` (10 testes, Firestore Emulator
  real via `firebase emulators:exec`): submissão bem-sucedida com número
  sequencial + trilha de histórico; número sequencial diferente para um segundo
  pedido; reenvio idempotente (mesmo `orderId`) sem duplicar pedido/estoque;
  duas submissões *concorrentes* com a mesma chave resolvendo em um único
  pedido; bloqueio quando cliente inativo (sem persistir nada); bloqueio quando
  tabela de preço vencida; bloqueio quando quantidade excede estoque disponível;
  bloqueio por RBAC (SALES_ASSISTANT); bloqueio ao tentar submeter em nome de
  outro vendedor; sucesso sem movimentação de estoque quando a variante não tem
  saldo rastreado.
- `test/features/orders/domain/usecases/submit_order_use_case_test.dart` (4
  testes): idempotencyKey = `Order.id`; falha sem chamar o repositório quando
  não há itens; analytics logado só em sucesso; propagação de falha sem logar
  analytics.
- `test/features/orders/data/mappers/order_submission_mapper_test.dart` (3
  testes): mapeamento DTO -> entidade e parsing/validação do DTO.

## Comandos executados
- `cd functions && npm run build`
- `cd functions && npm run lint`
- `export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH" && npx firebase emulators:exec --only firestore --project demo-vestipro-submit-order-test "cd functions && npm test -- --runTestsByPath test/orders/submit-order.test.ts"`
- `export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH" && npx firebase emulators:exec --only firestore --project demo-vestipro-full-test "cd functions && npm test"` (suíte completa das Functions)
- `dart run build_runner build` (regeneração de DI/freezed)
- `flutter analyze`
- `flutter test test/features/orders` / `flutter test test/app/bootstrap_test.dart test/widget_test.dart` / `flutter test` (suíte completa)
- `dart format --set-exit-if-changed lib/features/orders lib/app/bootstrap.dart test/features/orders/domain/usecases/submit_order_use_case_test.dart test/features/orders/data/mappers/order_submission_mapper_test.dart`

## Resultado do formatter
`dart format --set-exit-if-changed` → "Formatted 72 files (0 changed)", exit 0
(uma primeira passada sem `--set-exit-if-changed` já havia corrigido a
formatação de 4 arquivos novos).

## Resultado do analyzer
`flutter analyze` → 2 issues, ambas `info` pré-existentes/no mesmo padrão já
usado no restante do código (`use_null_aware_elements` no data source de
submissão — mesmo estilo `if (x != null) 'key': x,` já usado em
`cloud_functions_order_pricing_data_source.dart`; e um `prefer_initializing_formals`
em um teste de outra task não tocado aqui). Nenhum erro/warning.

## Resultado dos testes
- Cloud Functions: `submit-order.test.ts` → **10/10 passaram** contra o Firestore
  Emulator real (incluindo o teste de concorrência real com duas transações
  simultâneas). Suíte completa de `functions/` → **136/139 passaram**; as 3
  falhas restantes (`apply-stock-balance-adjustment.test.ts` — comparação de
  `correlationId` não excluído do `toEqual`; `create-organization.test.ts` — duas
  asserções desatualizadas quanto a `stockReservationExpiresInMinutes`) são
  **pré-existentes**, em arquivos não tocados por esta task, confirmadas antes e
  depois das minhas alterações.
- Flutter: `flutter test test/features/orders` → **119/119 passaram**
  (incluindo os testes de TASK-100 que exercitam o mesmo contrato `onSubmitOrder`
  sem qualquer alteração). Suíte completa (`flutter test`) → **2109/2109
  passaram**.

## Decisões técnicas
- **`orderId` = `idempotencyKey` = id do documento Firestore.** Reaproveita o
  uuid já gerado localmente pelo rascunho (TASK-096) em vez de o client gerar uma
  chave extra por tentativa — mais simples e alinhado ao padrão já usado por
  `createStockReservation`/`consumeStockReservation` (reservationId como doc id).
- **Segmento do cliente resolvido server-side** (a partir de `customers/{id}`),
  não recebido do client, ao contrário de `calculatePricing` (TASK-088) que ainda
  aceita `customerSegment` do client — decisão deliberadamente mais estrita aqui,
  já que a submissão é o ponto definitivo/autoritativo, não uma cotação.
- **Verificação de vigência da tabela de preço adicionada em `submitOrder`**,
  porque `ensureActivePriceList` (reaproveitado de `calculatePricing`) só checa
  `status`, nunca `validFrom`/`validTo` — um gap pré-existente na TASK-088 que
  esta task não corrige lá (fora de escopo), mas compensa aqui, já que TASK-100
  exige explicitamente essa revalidação na submissão.
- **Consumo de estoque com granularidade de um único depósito por item**: quando
  não há `reservationId`, a Function escolhe o primeiro saldo
  (`variantId`+`warehouseId`) com saldo vendável suficiente para a quantidade
  inteira do item — nunca fraciona um item entre múltiplos depósitos. Sem saldo
  algum rastreado para a variante, a submissão segue sem bloquear (mesmo
  precedente "ausência de dado nunca bloqueia" já usado pelo
  `OrderSubmissionValidator` client-side da TASK-100).
- **`maxAttempts: 10`** na transação do `submitOrder` (acima do padrão de 5 do
  SDK) — necessário porque a transação toca 3 documentos contenciosos ao mesmo
  tempo (pedido, contador de numeração, saldo de estoque); confirmado
  empiricamente pelo teste de concorrência real.
- **`onSubmitOrder` continua fazendo a submissão de fato** (em vez de eu mover
  essa responsabilidade para dentro de `OrderDraftBloc`), porque o próprio
  docstring do parâmetro na TASK-100 e o teste `order_draft_page_submission_test.dart`
  já fixam esse contrato: o callback é chamado diretamente com o `Order`
  no tap, sem esperar um evento de bloc. Mudar isso quebraria um teste já
  concluído/aceito sem necessidade — a lógica de negócio real está toda em
  `SubmitOrderUseCase`/Cloud Function, `bootstrap.dart` só orquestra.
- **Destino pós-sucesso é `CatalogHomeRoute`**, por não existir ainda tela de
  confirmação/listagem de pedidos (TASK-102).
- **Não adicionei `orderNumber` à entidade `Order`/schema Drift/DTO** nesta task:
  o número já é persistido no documento Firestore pela Function (pronto para
  TASK-102 ler), mas modelar isso no client (freezed + Drift + migração de
  schema) tocaria em quase todas as tasks já concluídas da EPIC-13 só para um
  campo que nada no client ainda precisa exibir — decisão deliberada de escopo,
  documentada como pendência abaixo.

## Riscos conhecidos
- Nenhuma Firestore Rule cobre `organizations/{organizationId}/orders` ainda —
  hoje isso é seguro (só a Function, via Admin SDK, escreve; nada no client lê),
  mas a TASK-102 precisa endereçar isso com RBAC de visibilidade antes de expor
  qualquer leitura client-side.
- O consumo de reserva de estoque (`reservationId` por item) está implementado e
  testado na Function, mas nenhum ponto do fluxo de rascunho cria reservas hoje —
  o caminho fica coberto só quando um fluxo futuro passar a reservar durante a
  montagem do pedido.
- Ambiente local não tinha Java instalado para o Firestore Emulator (mesma
  limitação já registrada em TASKS anteriores, ex. TASK-013); usei o JBR
  (JetBrains Runtime) já presente com o Android Studio
  (`C:\Program Files\Android\Android Studio\jbr`) como Java real para rodar o
  emulador — funcionou de ponta a ponta, mas não é uma instalação formal de JRE
  no ambiente.

## Pendências
- Modelar `orderNumber` na entidade `Order`/DTO/mapper local (client) fica para
  a TASK-102, quando a listagem realmente precisar buscá-lo/exibi-lo/filtrar por
  ele.
- Tela de confirmação/detalhe de pedido pós-submissão (hoje só um `SnackBar` +
  navegação para o catálogo) — natural de nascer junto com a TASK-102.
- Regras Firestore de leitura para `orders` com RBAC de visibilidade — TASK-102.
- Fluxo de aprovação para pedidos com `pricingApprovalRequired: true` (persistido
  no documento, mas sem transição automática para `under_review` nesta task) —
  TASK-103.

## Evidências
- Saída completa do `submit-order.test.ts` (10/10) e da suíte completa de
  `functions/` (136/139, 3 falhas pré-existentes não relacionadas) capturadas
  durante a execução desta task.
- `flutter test` completo: 2109/2109 aprovados.

## Commit
`feat(orders): implement order submission flow` — implementação, documentação de
conclusão e atualização de `TASKS.md` no mesmo commit, conforme instruído.

## Push
Não realizado — autorização desta rodada é apenas para commit local.

## Hash do commit
122f84f

## Branch
main
