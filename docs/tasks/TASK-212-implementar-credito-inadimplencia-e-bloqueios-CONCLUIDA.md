# TASK-212 — Concluída (2026-09-11)

## Resumo

Implementado controle de limite de crédito, inadimplência e bloqueios financeiros por cliente
(EPIC-32). A decisão crítica — bloquear ou enviar um pedido para aprovação por crédito/
inadimplência — é sempre server-side e auditável (Cloud Functions `validateOrderCredit`,
`updateCreditProfile`, `grantCreditOverride`, e integração direta em `submitOrder`), nunca
decidida ou confiável a partir do cliente. O vendedor vê status acionável (liberado, próximo do
limite, bloqueado, aprovação necessária, dado desatualizado) sem acessar valores financeiros;
FINANCE/OWNER/ADMIN veem o perfil completo e podem editar limite/política/bloqueio manual e
conceder/revogar exceções temporárias, sempre com auditoria.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, Cloud Functions, RBAC, Firestore Rules, integração com
  `submitOrder`/fluxo de aprovação multinível).
- `flutter-ui-design-specialist` (painel de crédito no cliente 360º, alertas no pedido, estados de
  permissão/loading/vazio).
- `vestipro-commercial-ops-strategist` (definição de política de bloqueio, papéis autorizados,
  auditoria e critérios de aceite gerenciais).
- `vestipro-sales-representative-specialist` (garantir que o vendedor entenda o motivo operacional
  sem acessar dado financeiro além do permitido).

## Arquivos criados

Backend (Cloud Functions):

- `functions/src/credit/credit-shared.ts` — modelo `CustomerCreditProfile` e regra pura
  `evaluateOrderCredit` (bloqueio manual, inadimplência, limite, override, dado desatualizado).
- `functions/src/credit/validate-order-credit.ts` — callable `validateOrderCredit` (preview
  mascarado por RBAC).
- `functions/src/credit/update-credit-profile.ts` — callable `updateCreditProfile`
  (`finance.manage`, auditado).
- `functions/src/credit/grant-credit-override.ts` — callable `grantCreditOverride` (grant/revoke,
  motivo + validade obrigatórios, auditado).
- `functions/src/credit/index.ts` — barrel.
- `functions/test/credit/credit-shared.test.ts` — 15 testes unitários da regra de crédito.

Frontend (Flutter), feature `lib/features/credit/`:

- `credit.dart` (barrel).
- `domain/value_objects/credit_status.dart`, `credit_block_policy.dart`.
- `domain/entities/credit_check_result.dart`, `customer_credit_profile.dart`,
  `customer_credit_manual_block.dart`, `customer_credit_override.dart`.
- `domain/repositories/credit_repository.dart`.
- `domain/usecases/credit_use_cases.dart` (Validate/Watch/Update/GrantOverride/RevokeOverride).
- `data/dtos/credit_check_result_dto.dart`, `customer_credit_profile_dto.dart`.
- `data/mappers/credit_mapper.dart`.
- `data/datasources/credit_read_data_source.dart` + `firestore_credit_read_data_source.dart`.
- `data/datasources/credit_write_data_source.dart` + `cloud_functions_credit_write_data_source.dart`.
- `data/repositories/credit_repository_impl.dart`.
- `presentation/bloc/customer_credit_cubit.dart` + `customer_credit_state.dart`.
- `presentation/widgets/customer_credit_panel.dart` (painel completo + edição + exceção).

## Arquivos alterados

- `functions/src/orders/submit-order.ts` — lê `creditProfiles/{customerId}` na mesma transação,
  bloqueia (`failed-precondition`) quando `evaluateOrderCredit` retorna `blocked`, e mescla
  `approvalRequired` de crédito ao fluxo de aprovação multinível já existente (chain dedicado com
  aprovador `SALES_MANAGER` quando nenhuma `ApprovalPolicy` de desconto já se aplica); persiste
  `creditCheck` (status/motivo não sensível) no pedido.
- `functions/src/index.ts` — exporta `validateOrderCredit`, `updateCreditProfile`,
  `grantCreditOverride`.
- `firestore.rules` — novo bloco `creditProfiles`: leitura restrita a `finance.view`
  (OWNER/ADMIN/FINANCE), escrita sempre `false` (só via Cloud Functions).
- `lib/features/orders/domain/entities/order_submission_issue.dart` — novos tipos
  `creditBlocked`, `creditRequiresApproval`, `creditAlert`.
- `lib/features/orders/domain/services/order_submission_validator.dart` — `_validateCredit`
  (bloqueante só para `blocked`; `approvalRequired`/`nearLimit`/`dataStale` são avisos).
- `lib/features/orders/presentation/bloc/order_submission_validation_cubit.dart` — passa a
  resolver `ValidateOrderCreditUseCase` (best-effort, junto do contexto já resolvido) e repassa ao
  validator.
- `lib/features/customers/presentation/pages/customer_detail_page.dart` — a seção "Indicadores
  comerciais sensíveis" (já existente, gated por `report.viewSensitive`) ganha o
  `CustomerCreditPanel` real no lugar do placeholder "Margem e crédito em breve" (mantido só para
  margem, fora de escopo).
- `lib/app/bootstrap.dart` — registra `createCreditPanelCubit` na rota do cliente 360º.
- `lib/app/injection.config.dart` — regenerado via `build_runner` para as novas classes
  `@injectable`/`@LazySingleton`.
- Testes ajustados para o novo parâmetro/dependência: `order_submission_validator_test.dart` (+6
  casos novos), `order_draft_page_test.dart`, `order_draft_page_submission_test.dart`,
  `customer_detail_page_test.dart` (+asserts de status mascarado).

## Arquitetura utilizada

Clean Architecture feature-first, mesmo padrão de `buyer_collaboration` (TASK-211): leitura via
Firestore direto (gated por Security Rules), escrita exclusivamente via Cloud Functions callable.
Nenhuma regra de negócio de crédito vive em widget; a UI só decide *o que exibir* a partir do
resultado já calculado pelo backend.

## Regras de negócio implementadas

- `CreditBlockPolicy`: `none` | `alert` | `require_approval` | `block`.
- Bloqueio manual, saldo vencido e limite excedido seguem a mesma árvore de decisão
  (`evaluateOrderCredit`), com uma exceção (`override`) válida e não expirada sempre liberando.
- `submitOrder` revalida crédito na própria transação, contra o total definitivo calculado pelo
  motor de precificação — nunca confia num total enviado pelo cliente.
- Pedido bloqueado nunca é persistido; pedido que só precisa de aprovação por crédito entra em
  `under_review` e usa a mesma cadeia de aprovação multinível já existente (TASK-103), com um
  fallback de nível único (`SALES_MANAGER`) quando nenhuma política de desconto já criou uma cadeia.
- Override exige `reason` e `expiresAt` futuro; nunca indefinido.
- Editar o perfil de crédito nunca apaga uma exceção já concedida (campo `override` preservado).

## Regras Firebase implementadas

- `firestore.rules`: `creditProfiles/{customerId}` — leitura só `finance.view`; toda escrita
  `false` (mediada por Cloud Function/Admin SDK).
- Cloud Functions re-verificam sempre a Membership real do chamador (nunca confiam em
  `organizationId`/role vindos do cliente), mesmo padrão de `submitOrder`/`decideOrderApproval`.

## Analytics implementado

Nenhum evento de Analytics novo foi adicionado nesta task — deliberado: `tasks.md` exige que
"Analytics não deve conter valores financeiros sensíveis nem motivo detalhado de inadimplência", e
nenhum evento comercial mínimo já catalogado (`AnalyticsEvents`) exigia extensão para cobrir esta
feature sem risco de vazar dado sensível.

## Crashlytics implementado

Sem mudança dedicada — os fluxos novos reutilizam o tratamento de erro genérico já existente
(`AppResult`/`AppFailure`, `mapAppExceptionToFailure`) que já alimenta o Crashlytics/logging
centralizados do app.

## Impacto offline

O preview de crédito (`ValidateOrderCreditUseCase`) é best-effort: uma falha/timeout (offline)
nunca bloqueia a tela do pedido — o pedido continua editável e a revalidação definitiva acontece em
`submitOrder` no momento da sincronização real, conforme `tasks.md` ("app pode alertar com o último
snapshot conhecido, mas submissão sempre revalida ao sincronizar").

## Impacto multi-tenant

Toda leitura/escrita de crédito é escopada por `organizationId`/`companyId`, revalidados
server-side a partir da Membership real do chamador — nunca a partir de campos enviados pelo
cliente.

## Testes criados

- `functions/test/credit/credit-shared.test.ts` — 15 testes: liberado dentro do limite, bloqueado/
  aprovação por limite excedido, bloqueado/alerta por inadimplência, dado desatualizado, override
  válido/expirado, ausência de perfil, bloqueio manual, mensagens sem valor financeiro.
- `test/features/orders/domain/services/order_submission_validator_test.dart` — +6 casos cobrindo
  `creditBlocked` (bloqueante), `creditRequiresApproval`/`creditAlert` (aviso) e ausência de
  `creditCheck`.
- Testes de widget existentes (`order_draft_page_test.dart`,
  `order_draft_page_submission_test.dart`, `customer_detail_page_test.dart`) atualizados para a
  nova dependência/seção, incluindo verificação de que `SALES_MANAGER` só vê o status mascarado.

## Comandos executados

```bash
cd functions && npx jest test/credit                     # 15/15 passou
cd functions && npx tsc --noEmit -p .                     # sem erros
cd functions && npx eslint src/credit src/orders/submit-order.ts   # limpo
cd functions && npx jest                                  # 607 passaram (39 suites falharam por
                                                            # falta de emulator/credenciais no
                                                            # ambiente — pré-existente, não
                                                            # relacionado a esta task)
flutter analyze lib/features/credit lib/features/orders lib/features/customers lib/app/bootstrap.dart
flutter analyze                                            # projeto inteiro
dart format lib/features/credit ... (arquivos tocados)
flutter test test/features/orders/domain/services/order_submission_validator_test.dart   # 23/23
flutter test test/features/orders test/features/customers  # 349/349
flutter test test/features/customers/presentation/pages/customer_detail_page_test.dart   # 6/6
dart run build_runner build   # regenerou lib/app/injection.config.dart
```

## Resultado do formatter

`dart format` aplicado sem pendências nos arquivos tocados (11 arquivos reformatados na primeira
passada, 0 na segunda).

## Resultado do analyzer

`flutter analyze` no projeto inteiro: 0 erros, 18 infos pré-existentes (nenhum nos arquivos desta
task).

## Resultado dos testes

- Cloud Functions (Jest, lógica pura de crédito): 15/15 passaram.
- Cloud Functions (typecheck `tsc --noEmit`): sem erros.
- Cloud Functions (suíte completa): 607 passaram / 252 falharam — falhas 100% por
  "Could not load the default credentials"/timeout de emulador Firestore, ambiente sem
  `firebase emulators:start` ativo; pré-existente, reproduzido também fora do escopo desta task
  (ex.: `test/returns`, `test/privacy`).
- Flutter (`order_submission_validator_test.dart`): 23/23 passaram.
- Flutter (`orders` + `customers` completos): 349/349 passaram.

## Decisões técnicas

- Override de bloqueio é modelado como exceção no próprio `CustomerCreditProfile` (não como
  aprovação pontual de um pedido específico): mais simples, auditável e reaproveitável para
  qualquer pedido futuro dentro da validade concedida.
- Quando só o crédito exige aprovação (sem desconto fora de política), a cadeia de aprovação usa um
  nível único fixo (`SALES_MANAGER`) em vez de estender `ApprovalPolicy` (que é indexada por faixa
  de desconto) — evita modificar `decideOrderApproval`/`RolePermissionMatrix.orderApprove` e mantém
  o escopo desta task contido.
- RBAC de visibilidade financeira reaproveita as capabilities já existentes `finance.view`/
  `finance.manage` (FINANCE/OWNER/ADMIN) em vez de criar novas — evita duplicar granularidade sem
  necessidade real hoje.
- `CustomerCreditPanel` foi encaixado no placeholder "Margem e crédito em breve" já reservado em
  `_SensitiveCommercialSection` (gated por `report.viewSensitive`), preservando margem como
  "em breve" (fora de escopo desta task).

## Riscos conhecidos

- A cadeia de aprovação de crédito fixa o aprovador em `SALES_MANAGER`; se uma organização quiser
  exigir `FINANCE` como aprovador de crédito, isso exigiria estender
  `ROLES_ALLOWED_TO_DECIDE_ORDER_APPROVAL` em `decide-order-approval.ts` (fora do escopo desta
  task, deliberadamente não alterado).
- Moeda do perfil de crédito assume a moeda padrão da organização (`CurrencyFormatter.legacyDefaultCurrency`,
  BRL) — não há hoje um conceito de crédito multi-moeda por Price List; se isso for necessário,
  precisará de modelagem adicional.
- Não existe hoje uma tela dedicada de "gestão de carteira de crédito" (lista de todos os clientes
  com pendência) — o painel criado é por cliente, dentro do 360º.

## Pendências

Nenhuma pendência bloqueante. Possível evolução futura (fora do escopo aprovado): dashboard
agregado de pedidos bloqueados por crédito (a métrica "pedidos bloqueados por crédito" já está
prevista em `tasks.md` seção de indicadores, mas pertence a uma task de BI/dashboard, não a esta).

## Evidências

- `functions/test/credit/credit-shared.test.ts` (15/15 passou).
- `test/features/orders/domain/services/order_submission_validator_test.dart` (23/23 passou).
- `flutter analyze` limpo nos diretórios tocados e no projeto inteiro.

## Commit

Local, sem push (não autorizado nesta rodada).

## Push

Não realizado (proibido nesta rodada).

## Hash do commit

Ver commit da task no histórico do Git (mensagem `feat(credit): implementar crédito, inadimplência
e bloqueios financeiros`).

## Branch

`main`
