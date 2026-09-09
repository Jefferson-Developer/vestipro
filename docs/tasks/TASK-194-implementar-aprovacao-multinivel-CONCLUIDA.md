# TASK-194 — Concluida (2026-09-09)

## Resumo
Implementada aprovacao multinivel para pedidos/descontos com snapshot server-side da politica ativa no pedido, decisao por nivel, historico imutavel, auditoria e notificacao do proximo aprovador.

## Agentes utilizados
flutter-senior-architect, flutter-ui-design-specialist, vestipro-commercial-ops-strategist.

## Arquivos criados
- `functions/src/orders/approval-chain.ts`
- `functions/test/orders/approval-chain.test.ts`
- `docs/tasks/TASK-194-implementar-aprovacao-multinivel-CONCLUIDA.md`

## Arquivos alterados
- `functions/src/orders/submit-order.ts`
- `functions/src/orders/decide-order-approval.ts`
- `functions/test/orders/decide-order-approval.test.ts`
- `lib/features/orders/domain/entities/order_approval_decision_result.dart`
- `lib/features/orders/data/dtos/order_approval_decision_result_dto.dart`
- `lib/features/orders/data/mappers/order_approval_decision_mapper.dart`
- `lib/features/orders/presentation/bloc/order_approval_queue_bloc.dart`
- `lib/features/orders/presentation/pages/order_approval_queue_page.dart`
- `test/features/orders/presentation/pages/order_approval_queue_page_test.dart`
- `firestore.rules`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture preservada no Flutter: UI apenas exibe estado e chama use case; decisao critica permanece na Cloud Function. No backend, a politica de aprovacao e convertida em `approvalChain` congelada no pedido durante `submitOrder`.

## Regras de negocio implementadas
- `ApprovalPolicy` por organizacao/empresa via `organizations/{organizationId}/approvalPolicies`.
- `approvalChain` vinculada ao pedido com `policyId`, `policyVersion`, faixa de desconto, nivel atual, niveis ordenados e decisoes append-only.
- Aprovacao intermediaria mantem o pedido em `under_review`, avanca `currentLevelIndex` e notifica o proximo papel.
- Rejeicao em qualquer nivel encerra a cadeia e grava `rejectionReason`.
- Decisor fora do papel do nivel atual e bloqueado server-side, com excecao de OWNER/ADMIN.
- Pedidos antigos sem `approvalChain` continuam usando o fluxo legado de nivel unico.

## Regras Firebase implementadas
`orders` continuam sem escrita direta pelo cliente. `approvalPolicies` foram protegidas por rules: leitura para OWNER/ADMIN/SALES_MANAGER/FINANCE e escrita direta negada.

## Analytics implementado
Mantido o uso existente de `AnalyticsEvents.orderApproved` e `AnalyticsEvents.orderRejected` no use case Flutter.

## Crashlytics implementado
Nao houve nova integracao direta. Erros seguem os contratos existentes de failures/exceptions.

## Impacto offline
Sem nova mutacao offline. Submissao offline continua pelo fluxo existente; a cadeia e calculada quando o pedido e aceito server-side.

## Impacto multi-tenant
Toda leitura/escrita fica em `organizations/{organizationId}` e valida `companyId` no pedido. Policies podem ser globais da organizacao ou especificas da empresa.

## Testes criados
- Unitario puro de selecao de faixa/politica da cadeia.
- Testes de Function para avancar nivel, bloquear papel fora de ordem e rejeitar em nivel intermediario.
- Widget test cobrindo exibicao da trilha de aprovacao.

## Comandos executados
- `npm run build`
- `dart format --set-exit-if-changed ...`
- `npm test -- --runTestsByPath test/orders/approval-chain.test.ts`
- `flutter test test\features\orders\presentation\pages\order_approval_queue_page_test.dart`
- `npm run lint`
- `flutter analyze`
- `npm test -- --runTestsByPath test/orders/decide-order-approval.test.ts`
- `firebase emulators:exec --only firestore "npm test -- --runTestsByPath test/orders/decide-order-approval.test.ts"`

## Resultado do formatter
Passou.

## Resultado do analyzer
Executado. Retornou 18 infos/deprecations preexistentes fora dos arquivos alterados nesta task.

## Resultado dos testes
- `approval-chain.test.ts`: passou, 2 testes.
- `order_approval_queue_page_test.dart`: passou, 4 testes.
- `decide-order-approval.test.ts`: nao executou corretamente sem emulador/credenciais; falhou antes da logica por falta de credenciais Firestore.
- `firebase emulators:exec`: bloqueado por `spawn java ENOENT`; Java nao esta instalado/no PATH.

## Decisões técnicas
A cadeia fica denormalizada no pedido para impedir alteracao retroativa quando a `ApprovalPolicy` mudar. O fluxo legado foi mantido para documentos antigos sem `approvalChain`.

## Riscos conhecidos
Validacao de RBAC no Emulator Suite precisa ser executada em ambiente com Java/Firestore Emulator.

## Pendências
Executar os testes de Function dependentes do Firestore Emulator quando Java estiver disponivel no ambiente.

## Evidências
Build TypeScript passou; lint Functions passou sem erros; formatter passou; teste unitario da cadeia e widget test passaram.

## Commit
`feat(orders): add multilevel approval chain`

## Push
Nao autorizado.

## Hash do commit
Registrado no commit local desta task; ver `git log -1 --shortstat`.

## Branch
main
