# TASK-213 — Concluída (2026-09-11)

## Resumo

Implementada a visão operacional de contas a receber, faturas/invoices e lembretes de cobrança
(EPIC-32), vinculada a pedido e cliente. Fatura (`Invoice`) e parcela (`Receivable`) são
importadas/sincronizadas de forma idempotente por identificador externo (ERP/gateway), pagamentos
são registrados como eventos auditáveis (`PaymentAllocation`), e o saldo agregado alimenta
automaticamente o perfil de crédito da TASK-212 (`creditProfiles.openBalance/overdueBalance`).
Vendedor e gestor veem apenas um status acionável mascarado (em dia/aberto/vencido); FINANCE/OWNER/
ADMIN veem faturas, títulos e aging reais, e podem registrar manualmente a confirmação de um
pagamento. Lembretes de cobrança são gerados diariamente por uma Cloud Function agendada, sempre
respeitando as preferências de comunicação e quiet hours do vendedor responsável.

## Agentes utilizados

- `flutter-senior-architect` (Cloud Functions, arquitetura de dados, RBAC, Firestore Rules/Indexes,
  reconciliação com o perfil de crédito, lembretes server-side).
- `flutter-ui-design-specialist` (seção "Situação financeira" no cliente 360º e no pedido, estados
  de loading/vazio/erro/permissão, formulário de confirmação de pagamento).
- `vestipro-commercial-ops-strategist` (definição de status mascarado x detalhado, aging resumido,
  papéis autorizados, integração com crédito).
- `vestipro-sales-representative-specialist` (garantir que o vendedor entenda a situação financeira
  do cliente sem acessar valores sensíveis).

## Arquivos criados

Backend (Cloud Functions), `functions/src/receivables/`:

- `receivables-shared.ts` — modelos `Invoice`, `Receivable`, `PaymentAllocation` e regras puras:
  `computeReceivableStatus` (aberta/vencida/parcial/paga/cancelada), `computeAgingBucket`,
  `computeInvoiceStatus` (agregação por fatura), `computeBillingStatus`/`describeBillingStatus`
  (status mascarado), `classifyReceivableReminder` (dueSoon/overdue) e `computeExternalEntityId`
  (id determinístico para idempotência de import).
- `import-invoice.ts` — callable `importReceivableInvoice` (idempotente por `externalId`,
  `finance.manage`, nunca regride `paidAmount` já confirmado).
- `register-payment-allocation.ts` — callable `registerPaymentAllocation` (idempotente por
  `externalReference`, `finance.manage`, nunca permite pagamento acima do saldo em aberto).
- `check-billing-status.ts` — callable `checkBillingStatus` (preview mascarado para qualquer membro
  ativo; detalhe sensível só para `finance.view`, mesmo padrão de `validateOrderCredit`).
- `reconcile-receivables-to-credit-profile.ts` — trigger `onDocumentWritten` que recalcula
  `openBalance`/`overdueBalance` em `creditProfiles/{customerId}` a partir do ledger de recebíveis.
- `generate-billing-reminders.ts` — scheduled function `generateBillingReminders` (diária), gera
  lembrete ao vendedor responsável (`Receivable.sellerId`) respeitando `communicationPreferences`
  (categoria `commercial`/canal `inApp`) e `quietHours`, reaproveitando os ports server-side já
  existentes em `daily-rep-summary-notification.ts`.
- `index.ts` — barrel.
- `functions/test/receivables/receivables-shared.test.ts` — 27 testes unitários (status, aging,
  agregação de fatura, classificação de lembrete, status mascarado, idempotência do id externo).

Frontend (Flutter), feature `lib/features/receivables/`:

- `receivables.dart` (barrel).
- `domain/value_objects/receivable_status.dart`, `aging_bucket.dart`, `billing_status.dart`.
- `domain/entities/receivable.dart`, `billing_status_check.dart`.
- `domain/repositories/receivables_repository.dart`.
- `domain/usecases/receivables_use_cases.dart` (Check/Watch/RegisterPaymentAllocation).
- `data/dtos/receivable_dto.dart`, `billing_status_check_dto.dart`.
- `data/mappers/receivables_mapper.dart`.
- `data/datasources/receivables_read_data_source.dart` + `firestore_receivables_read_data_source.dart`.
- `data/datasources/receivables_write_data_source.dart` + `cloud_functions_receivables_write_data_source.dart`.
- `data/repositories/receivables_repository_impl.dart`.
- `presentation/bloc/customer_billing_cubit.dart` + `customer_billing_state.dart`.
- `presentation/widgets/customer_billing_panel.dart` (painel completo + aging + registrar pagamento
  + status mascarado; reaproveitado tanto no cliente 360º quanto no pedido via parâmetro `orderId`
  opcional).
- `test/features/receivables/domain/entities/receivable_test.dart`,
  `domain/value_objects/aging_bucket_test.dart` — 7 testes.

## Arquivos alterados

- `functions/src/index.ts` — exporta `importReceivableInvoice`, `registerPaymentAllocation`,
  `checkBillingStatus`, `reconcileReceivablesToCreditProfile`, `generateBillingReminders`.
- `firestore.rules` — novos blocos `invoices`, `receivables`, `paymentAllocations` (leitura restrita
  a `finance.view`, escrita sempre `false`), `paymentAllocationEvents` e `billingReminderDispatches`
  (sem leitura/escrita client-side, uso interno das Cloud Functions).
- `firestore.indexes.json` — dois índices compostos para `receivables`
  (`customerId+dueDate` e `customerId+orderId+dueDate`), necessários para o watch em tempo real do
  painel financeiro.
- `lib/features/customers/presentation/pages/customer_detail_page.dart` — a seção "Indicadores
  comerciais sensíveis" ganha uma nova subseção "Situação financeira" com `CustomerBillingPanel`,
  logo abaixo do `CustomerCreditPanel` (TASK-212); `createBillingPanelCubit` roteado por toda a
  cadeia de widgets já existente (`CustomerDetailPage` → `CustomerDetailView` →
  `_CustomerDetailBody` → `_CustomerDetailContent` → `_DesktopCustomerDetail`/
  `_StackedCustomerDetail` → `_SensitiveCommercialSection`).
- `lib/features/orders/presentation/pages/order_history_page.dart` — nova seção "Situação
  financeira" (escopada ao pedido via `orderId`) logo após a timeline de pós-venda;
  `createBillingPanelCubit`/`userId`/`permissionService` roteados por
  `OrderHistoryPage` → `_OrderHistoryPermissionsGate` → `_OrderHistoryScaffold` →
  `_OrderHistoryContent`.
- `lib/app/bootstrap.dart` — registra `createBillingPanelCubit` nas rotas do cliente 360º e do
  histórico do pedido.
- `lib/app/injection.config.dart` — regenerado via `build_runner` para as novas classes
  `@injectable`/`@LazySingleton`.
- `test/features/customers/presentation/pages/customer_detail_page_test.dart` — adiciona
  `_FakeReceivablesRepository` e o novo `createBillingPanelCubit` exigido pelo widget.

## Regras de negócio implementadas

- `ReceivableStatus`: `open` | `overdue` | `partially_paid` | `paid` | `cancelled` — checados nessa
  ordem exata (cancelada sempre vence; parcialmente paga nunca vira "vencida" mesmo com a data
  passada).
- `Invoice.status` é agregado a partir de suas parcelas (`computeInvoiceStatus`): só "paga" quando
  toda parcela não cancelada está paga; "vencida" se qualquer parcela estiver vencida.
- Importação de fatura/parcela é idempotente por `externalId` (id determinístico via hash) — um
  reenvio (retry de webhook/importação) nunca duplica registro nem regride `paidAmount` já
  confirmado.
- Registro de pagamento (`registerPaymentAllocation`) é idempotente por `externalReference`
  (evento auditável, nunca um "set" cego) e nunca permite valor acima do saldo em aberto do título.
- A UI nunca marca fatura como paga sozinha: toda confirmação passa por uma Cloud Function
  `finance.manage` (FINANCE/ADMIN/OWNER) que revalida o saldo real antes de aplicar.
- Vendedor/gestor sem `finance.view` só recebem `BillingStatus` mascarado (`up_to_date`/`has_open`/
  `has_overdue`) e uma mensagem genérica, nunca um valor monetário — mesmo padrão RBAC de dois
  níveis já usado em `CreditStatus` (TASK-212).
- Saldo do perfil de crédito (`creditProfiles.openBalance/overdueBalance`) é recalculado a partir do
  ledger real de recebíveis a cada escrita em `receivables`, sem nunca tocar `creditLimit`,
  `blockPolicy`, `manualBlock` ou `override` (campos exclusivos do fluxo FINANCE da TASK-212).
- Lembrete de cobrança nunca é enviado para categoria/canal desativado pelo destinatário
  (`communicationPreferences.commercial.inApp`) e sempre respeita `quietHours` (atraso de
  `deliverAt`, nunca supressão silenciosa) — reaproveita os ports já testados de
  `daily-rep-summary-notification.ts` em vez de duplicar a lógica de quiet hours em TypeScript.

## Regras Firebase implementadas

- `firestore.rules`: `invoices`, `receivables` e `paymentAllocations` — leitura só `finance.view`;
  toda escrita `false` (mediada por Cloud Function/Admin SDK). `paymentAllocationEvents` e
  `billingReminderDispatches` — sem leitura/escrita client-side (uso interno de idempotência).
- Cloud Functions re-verificam sempre a Membership real do chamador (nunca confiam em
  `organizationId`/role vindos do cliente), mesmo padrão de `updateCreditProfile`/`submitOrder`.
- `firestore.indexes.json` — índices compostos adicionados para as duas formas de consulta do
  painel (`customerId+dueDate` e `customerId+orderId+dueDate`).

## Analytics implementado

Nenhum evento de Analytics novo — decisão deliberada, mesma linha de TASK-212: dado financeiro
sensível (valor de fatura, motivo de inadimplência) não deve vazar por Analytics, e nenhum evento
comercial mínimo já catalogado exigia extensão para esta feature.

## Crashlytics implementado

Sem mudança dedicada — os fluxos novos reutilizam o tratamento de erro genérico já existente
(`AppResult`/`AppFailure`, `mapAppExceptionToFailure`) que já alimenta Crashlytics/logging
centralizados do app.

## Impacto offline

O preview de status mascarado (`CheckBillingStatusUseCase`) é best-effort: uma falha/timeout
(offline) nunca bloqueia a tela de cliente/pedido, apenas mostra "não foi possível verificar".
O painel financeiro completo (FINANCE) depende de leitura em tempo real do Firestore (mesmo padrão
de `CustomerCreditPanel`) — sem cache offline dedicado, pois é dado sensível de baixa frequência de
consulta offline, mesma decisão já aceita para `creditProfiles`.

## Impacto multi-tenant

Toda leitura/escrita de fatura/título/pagamento é escopada por `organizationId`, revalidada
server-side a partir da Membership real do chamador — nunca a partir de campos enviados pelo
cliente. O trigger de reconciliação e o gerador de lembretes iteram por organização
(`organizations/{organizationId}/...`), nunca cruzam dados entre tenants.

## Testes criados

- `functions/test/receivables/receivables-shared.test.ts` — 27 testes: status (aberta/vencida/
  parcial/paga/cancelada, inclusive parcial+vencida), aging (bucket current/1-30/31-60/61-90/90+),
  agregação de status da fatura a partir das parcelas, classificação de lembrete (dueSoon/overdue/
  none), status mascarado (nunca contém valor monetário na mensagem) e idempotência do id externo
  determinístico (mesmo id para reimport; nunca colide invoice x receivable nem entre organizações).
- `test/features/receivables/domain/entities/receivable_test.dart` — outstandingAmount (diferença e
  nunca negativo), `isSettled`, round-trip de `ReceivableStatus.fromCode/code`.
- `test/features/receivables/domain/value_objects/aging_bucket_test.dart` — bucket correto para
  título liquidado, não vencido e cada faixa de dias em atraso.
- `test/features/customers/presentation/pages/customer_detail_page_test.dart` — atualizado com
  `_FakeReceivablesRepository` para a nova dependência obrigatória da página.

## Comandos executados

```bash
cd functions && npx jest test/receivables               # 27/27 passou
cd functions && npx tsc --noEmit -p .                    # sem erros
cd functions && npx eslint src/receivables test/receivables src/index.ts   # limpo
flutter analyze                                          # projeto inteiro
dart format lib/features/receivables lib/features/customers/... lib/features/orders/... lib/app/bootstrap.dart test/features/customers/... test/features/receivables
dart format --set-exit-if-changed <mesmos arquivos>      # 0 alterações na segunda passada
dart run build_runner build                              # regenerou lib/app/injection.config.dart
flutter test test/features/receivables                   # 7/7
flutter test test/features/customers/presentation/pages/customer_detail_page_test.dart   # 6/6
flutter test test/features/orders test/features/customers # 349/349
```

## Resultado do formatter

`dart format` aplicado sem pendências nos arquivos tocados (4 arquivos reformatados na primeira
passada — reflow padrão pós-edição —, 0 na segunda).

## Resultado do analyzer

`flutter analyze` no projeto inteiro: 0 erros. 19 infos pré-existentes/estilo (7 já existiam antes
desta task; 1 novo `use_null_aware_elements` no novo `cloud_functions_receivables_write_data_source.dart`,
mesmo padrão já usado sem correção em `campaign_assist`/`crm`/`product_import`/`customer_import`).

## Resultado dos testes

- Cloud Functions (Jest, lógica pura de recebíveis): 27/27 passaram.
- Cloud Functions (typecheck `tsc --noEmit`): sem erros.
- Cloud Functions (ESLint): limpo.
- Flutter (`test/features/receivables`): 7/7 passaram.
- Flutter (`customer_detail_page_test.dart`): 6/6 passaram.
- Flutter (`orders` + `customers` completos, regressão da nova seção/threading): 349/349 passaram.

## Decisões técnicas

- `Invoice`/`Receivable`/`PaymentAllocation` modelados como três coleções server-side distintas
  (não aninhadas), espelhando exatamente o pedido da task e o padrão já usado por
  `paymentTransactions`/`paymentWebhookEvents` (TASK-193).
- Import de fatura é uma callable `finance.manage` idempotente por hash determinístico do
  `externalId` — não um webhook HTTP com assinatura própria (como `handlePaymentWebhook`,
  TASK-193): a integração real com um ERP/gateway específico está fora do escopo desta task
  (`erpIntegrationManage`, TASK-169, já cobre a parte de configuração de credenciais/mapeamento);
  o entry point idempotente é o suficiente para o requisito "sincronização... com idempotência por
  identificador externo".
- A UI do Flutter não modela `Invoice` como entidade própria — o painel financeiro completo lista
  `Receivable`s diretamente (parcela 1/2/3, vencimento, status, aging), sem precisar buscar o
  documento de fatura para exibir um rótulo. Isso evita duplicar toda a pilha de
  datasource/DTO/mapper só para um campo de agrupamento visual; o backend continua modelando
  `Invoice` por completo (obrigatório pelo escopo técnico da task).
- `checkBillingStatus` é uma única callable (não duas) que decide server-side quanto detalhe
  devolver, mesma forma de `validateOrderCredit` (TASK-212) — nunca dois endpoints diferentes por
  role.
- Reconciliação para o perfil de crédito roda em um trigger `onDocumentWritten` (recomputa o
  agregado inteiro a cada escrita), não um incremento — mesmo "nunca corrigir com patch, sempre
  recomputar da fonte" já usado por `recalculateCustomerScores`.
- Lembrete de cobrança é server-side (scheduled function), não client-side como os lembretes de CRM
  (TASK-152): ao contrário de `CrmTask` (que só existe localmente até hoje), `Receivable` já vive no
  Firestore, então uma função agendada pode ler o estado real sem depender do app estar aberto —
  mesmo raciocínio documentado em `GenerateCrmTaskRemindersUseCase`.
- `CustomerBillingPanel` é o mesmo widget para cliente 360º e pedido (parâmetro `orderId` opcional),
  evitando duplicar a divisão "detalhe completo x status mascarado" em dois componentes.

## Riscos conhecidos

- A callable `importReceivableInvoice` autentica como um membro `finance.manage` — não existe hoje
  um caminho de autenticação máquina-a-máquina dedicado para ERP/gateway (diferente do webhook HTTP
  assinado de `handlePaymentWebhook`). Se um ERP real precisar empurrar fatura sem um usuário
  humano por trás, será necessário estender esta task ou reaproveitar `apiKeyManage` (TASK-171).
- Não existe hoje uma tela dedicada de "carteira de recebíveis" agregada (lista de todos os títulos
  em aberto/vencidos da organização) — o painel criado é por cliente/pedido, dentro do 360º e do
  histórico do pedido, mesma limitação já aceita em TASK-212 para o crédito.
- O lembrete de cobrança só notifica o `sellerId` do pedido de origem — se um título não tiver
  pedido/vendedor associado (ex.: fatura avulsa importada sem `orderId`), nenhum lembrete é gerado
  (deliberado: não há para quem notificar com segurança sem um vendedor responsável).

## Pendências

Nenhuma pendência bloqueante. Evolução futura possível (fora do escopo aprovado): dashboard
agregado de aging de contas a receber por organização/carteira (métrica "aging de contas a
receber" já prevista em `tasks.md`, seção de indicadores, mas pertence a uma task de BI/dashboard).

## Evidências

- `functions/test/receivables/receivables-shared.test.ts` (27/27 passou).
- `test/features/receivables/**` (7/7 passou).
- `flutter analyze` limpo (0 erros) no projeto inteiro.
- `flutter test test/features/orders test/features/customers` (349/349 passou).

## Commit

Local, sem push (não autorizado nesta rodada).

## Push

Não realizado (proibido nesta rodada).

## Hash do commit

Ver commit da task no histórico do Git (mensagem `feat(receivables): implementar contas a receber,
faturas e lembretes de cobrança`).

## Branch

`main`
