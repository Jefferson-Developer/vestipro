# TASK-100 — Concluída (2026-08-31)

## Resumo

Implementado o `OrderSubmissionValidator` (EPIC-13): serviço de domínio que impede o envio de um
pedido inconsistente, validando cliente ativo, tabela de preço vigente, quantidade
disponível/coerente com o estoque, condição de pagamento válida e desconto dentro da política do
vendedor (RBAC, via `OrderPricingSummary.blocked`/`approvalRequired` já calculados server-side pelo
motor de precificação, TASK-088). A tela "Novo pedido" ganhou um painel "Antes de enviar, resolva:"
com cada pendência apontando para a parte do pedido que precisa de ajuste, e um CTA "Enviar pedido"
que só habilita quando não há nenhuma pendência bloqueante — revalidando automaticamente sempre que
cliente, tabela de preço, condição de pagamento ou itens mudam. A submissão real (Cloud Function
idempotente, TASK-101) ainda não foi wireada: o `onSubmitOrder` do `OrderDraftPage` fica `null` até
lá, mantendo o CTA desabilitado mesmo quando a validação client-side passa — mesmo precedente já
usado por `onContinueToProducts`.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura de domínio/dados/BLoC, DI, testes)
- Perspectiva de `flutter-ui-design-specialist` coberta diretamente (painel de pendências, CTA,
  feedback visual, acessibilidade) sem subagente separado, conforme instrução do orquestrador.

## Arquivos criados

- `lib/features/orders/domain/entities/order_submission_issue.dart` — `OrderSubmissionIssueSeverity`,
  `OrderSubmissionIssueTarget`, `OrderSubmissionIssueType`, `OrderSubmissionIssue`.
- `lib/features/orders/domain/entities/order_submission_context.dart` — snapshot best-effort de
  `Customer`/`PriceList`/`PaymentTerm`/disponibilidade por variante.
- `lib/features/orders/domain/services/order_submission_validator.dart` — `OrderSubmissionValidator`
  (`@lazySingleton`), regra a regra.
- `lib/features/orders/domain/usecases/get_order_submission_context_use_case.dart` —
  `GetOrderSubmissionContextUseCase` (`@injectable`), resolve o contexto acima a partir do `Order`.
- `lib/features/orders/presentation/bloc/order_submission_validation_cubit.dart` —
  `OrderSubmissionValidationCubit` (`@injectable`).
- `lib/features/orders/presentation/bloc/order_submission_validation_state.dart` —
  `OrderSubmissionValidationState`/`OrderSubmissionValidationStatus` (`canSubmit`, `blockingIssues`,
  `warnings`).
- `lib/features/orders/presentation/widgets/order_submission_pendencies_panel.dart` —
  `OrderSubmissionPendenciesPanel` ("Antes de enviar, resolva:" + "Avisos").
- `test/features/orders/domain/services/order_submission_validator_test.dart` — 19 testes unitários.
- `test/features/orders/presentation/pages/order_draft_page_submission_test.dart` — 5 testes de
  widget (CTA habilita/desabilita, RBAC, revalidação automática).

## Arquivos alterados

- `lib/features/orders/presentation/pages/order_draft_page.dart` — novo cubit de validação
  (`createOrderSubmissionValidationCubit`), painel de pendências, CTA "Enviar pedido"
  (`onSubmitOrder`, opcional), debounce de revalidação, `GlobalKey`s para scroll-to-target.
- `lib/features/orders/presentation/widgets/order_pricing_summary_section.dart` — novo callback
  opcional `onStateChanged` (aditivo, sem mudança de comportamento quando não usado) para reuso do
  `OrderPricingSummary` já resolvido pelo card comercial, evitando uma segunda chamada
  `calculatePricing` para o mesmo draft.
- `lib/features/orders/orders.dart` — exporta os novos símbolos do barrel.
- `lib/app/bootstrap.dart` — wiring de `createOrderSubmissionValidationCubit` via `getIt`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (3 novas registrations:
  `OrderSubmissionValidator`, `GetOrderSubmissionContextUseCase`,
  `OrderSubmissionValidationCubit`).
- `test/features/orders/presentation/pages/order_draft_page_test.dart` — novo parâmetro obrigatório
  `createOrderSubmissionValidationCubit` wireado com mocks/stubs adicionais
  (`PriceListRepository`/`PaymentTermRepository`), já que a validação roda automaticamente assim que
  a tela fica pronta.
- `docs/tasks/TASKS.md` — checkbox da TASK-100 marcado e progresso atualizado para 100/220.

## Arquitetura utilizada

Presentation (`OrderDraftPage`/`OrderSubmissionPendenciesPanel`) → `OrderSubmissionValidationCubit`
→ `GetOrderSubmissionContextUseCase` (compõe `GetCustomerByIdUseCase`, `PriceListRepository`,
`PaymentTermRepository`, `GetVariantAvailabilityUseCase`) → repositórios já existentes. A regra de
negócio (o que bloqueia/o que só avisa) vive inteiramente em `OrderSubmissionValidator`
(domain/services), puro Dart, sem Flutter/Firebase/Drift. A UI nunca decide sozinha se o pedido pode
ser enviado — apenas reflete `OrderSubmissionValidationState.canSubmit`.

## Regras de negócio implementadas

- Pedido sem item: bloqueante.
- Cliente não confirmado/inativo/bloqueado/prospect: bloqueante (mensagens diferenciadas,
  orientadas à ação, sem detalhe técnico).
- Tabela de preço não confirmada ou fora da janela de vigência (`PriceList.isApplicableAt`):
  bloqueante.
- Condição de pagamento não confirmada, inativa, ou incompatível com a tabela de preço
  (`PaymentTerm.isActive`/`isCompatibleWithPriceList`): bloqueante.
- Item cuja variante ficou indisponível, ou quantidade solicitada maior que a disponível
  (`VariantAvailability`): bloqueante. Uma variante sem disponibilidade resolvida ainda nunca
  bloqueia (mesmo precedente "never blocking on this lookup" já usado em `OrderDraftState`).
- Desconto fora da política do vendedor (`OrderPricingSummary.blocked`, já calculado server-side
  pelo `calculatePricing`/TASK-088, que já considera a política de desconto do vendedor): bloqueante
  — cobre a exigência de RBAC desta task sem duplicar a regra client-side.
- Desconto que só exige aprovação (`OrderPricingSummary.approvalRequired`): aviso não bloqueante
  (fluxo de aprovação fica para TASK-103, conforme especificado).
- Validação client-side é explicitamente só para UX — a mesma validação será reexecutada
  server-side na submissão (TASK-101), documentado nos comentários do validador.

## Regras Firebase implementadas

Nenhuma — esta task é 100% client-side (UX). A Cloud Function `submitOrder` que reexecuta estas
mesmas regras server-side é escopo de TASK-101, ainda pendente.

## Analytics implementado

Nenhum evento novo — a task não pede analytics específico para pendências de validação, e nenhum
evento comercial da lista mínima (`AGENTS.md`) se aplica diretamente a "avaliar pendências". Não
adicionado para evitar acoplamento fora de escopo.

## Crashlytics implementado

Não aplicável — nenhum fluxo novo lança exceção não tratada; falhas de lookup (`GetOrderSubmissionContextUseCase`)
são absorvidas (best-effort) e nunca propagam.

## Impacto offline

A validação roda 100% sobre dados locais/já resolvidos (repositórios que já suportam modo
offline-first, mesmo padrão de `OrderDraftBloc`/`OrderPricingSummarySection`). Uma pendência de
lookup que falhar (ex.: cliente offline) apenas deixa o campo correspondente `null`, e o validador
trata isso como pendência bloqueante-mas-acionável ("Tente novamente"), nunca como crash. A
submissão real permanecerá disponível para rascunhos offline (mantendo `pending_sync`), conforme
TASK-101 documenta.

## Impacto multi-tenant

Toda consulta (`GetCustomerByIdUseCase`, `PriceListRepository.getById`,
`PaymentTermRepository.getById`, `GetVariantAvailabilityUseCase`) é sempre escopada por
`order.organizationId`, nunca confiando em um valor vindo de fora do `Order` já persistido/validado
pelas tasks anteriores (TASK-095/096).

## Testes criados

- `order_submission_validator_test.dart` (19 testes): cada regra isolada + combinação de múltiplas
  pendências simultâneas + caso "RBAC bloqueia desconto fora do limite" + caso "aviso não bloqueia
  sozinho".
- `order_draft_page_submission_test.dart` (5 testes de widget): CTA habilita e chama `onSubmitOrder`
  quando tudo está válido; CTA permanece desabilitado com painel visível quando a tabela de preço
  venceu; CTA permanece desabilitado (RBAC) quando o desconto está bloqueado; aviso de aprovação não
  bloqueia o CTA; revalidação automática ao remover o único item do pedido.

## Comandos executados

```
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/orders lib/app/bootstrap.dart lib/app/injection.config.dart \
  test/features/orders/presentation/pages/order_draft_page_test.dart \
  test/features/orders/presentation/pages/order_draft_page_submission_test.dart \
  test/features/orders/domain/services/order_submission_validator_test.dart
flutter analyze
flutter test test/features/orders
flutter test test/app/bootstrap_test.dart test/app/injection_test.dart
```

## Resultado do formatter

5 arquivos reformatados automaticamente (ajustes de estilo, sem mudança de comportamento); os
demais 61 arquivos verificados já estavam formatados.

## Resultado do analyzer

`flutter analyze` — 1 issue encontrada, pré-existente e não relacionada a esta task
(`prefer_initializing_formals` em `test/features/orders/domain/usecases/add_items_to_order_draft_use_case_test.dart:193`,
arquivo não tocado nesta task).

## Resultado dos testes

- `flutter test test/features/orders` — **119/119 passaram** (inclui os 24 testes novos desta task
  e todos os testes pré-existentes de EPIC-13, sem regressão).
- `flutter test test/app/bootstrap_test.dart test/app/injection_test.dart` — **8/8 passaram**
  (confirma que o DI regenerado continua íntegro e a app ainda inicializa).

## Decisões técnicas

- **Reuso do `OrderPricingSummary` já resolvido** (via novo callback `onStateChanged` em
  `OrderPricingSummarySection`) em vez de o `OrderSubmissionValidationCubit` chamar
  `GetOrderPricingSummaryUseCase` de novo — evita uma segunda chamada `calculatePricing`
  (Cloud Function) a cada edição do rascunho.
- **Não reimplementar a regra de desconto/permissão do vendedor client-side**: o validador consome
  `OrderPricingSummary.blocked`/`approvalRequired`, que já vêm do motor de precificação server-side
  (TASK-088) considerando a política de desconto do vendedor — reimplementar essa regra aqui
  arriscaria divergir da fonte única de verdade (regra "pricing definitivo server-side" do
  `AGENTS.md`).
- **`onSubmitOrder` opcional e ainda não wireado no `bootstrap.dart`**: a submissão real (Cloud
  Function idempotente) é escopo de TASK-101; deixar o callback `null` por enquanto mantém o CTA
  desabilitado sem código morto/`TODO`, mesmo precedente já usado por `onContinueToProducts`.
- **Deep-link para o ponto do pedido que precisa de ajuste** implementado via `GlobalKey` +
  `Scrollable.ensureVisible` dentro do próprio `SingleChildScrollView` da tela (sem nova rota),
  já que cliente/tabela de preço/condição de pagamento, itens e resumo comercial já convivem na
  mesma tela.
- **`GetOrderSubmissionContextUseCase` best-effort/failure-swallowing**: uma falha de lookup nunca
  derruba a tela; o validador decide o que uma pendência `null` significa (mesmo precedente de
  `OrderDraftBloc._resolveProductNames`).

## Riscos conhecidos

- O CTA "Enviar pedido" ainda não dispara nenhuma submissão real (aguardando TASK-101) — está
  visível e corretamente gated, mas inerte até o `onSubmitOrder` ser wireado no `bootstrap.dart`.
- A cobertura de "revalidação automática ao alterar cliente/condição de pagamento" foi testada via
  o caso de alteração de item (mesma função de diff interna `_validationRelevantFieldsChanged`
  cobre os três campos); não há um teste de widget dedicado trocando cliente/condição de pagamento
  isoladamente, por já compartilharem a mesma lógica testada.
- `OrderSubmissionValidationCubit` dispara uma consulta best-effort (`GetOrderSubmissionContextUseCase`)
  a cada reavaliação debounced — aceitável para o volume esperado desta tela, mas vale monitorar em
  telemetria de custo de Cloud Functions/Firestore reads se o padrão de uso divergir do esperado.

## Evidências

- Saídas de `flutter analyze`, `flutter test test/features/orders` (119/119) e
  `flutter test test/app/bootstrap_test.dart test/app/injection_test.dart` (8/8) capturadas durante
  a execução desta task (ver seção "Resultado dos testes").

## Commit

Pendente — a ser criado na etapa de commit desta task.

## Push

Não realizado (instrução explícita: apenas commit local nesta rodada).

## Hash do commit

Pendente — preenchido após o commit.

## Branch

`main`
