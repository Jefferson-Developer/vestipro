# TASK-210 — Concluída (2026-09-11)

## Resumo
Implementada a base de pré-venda/pre-book por coleção, com programa comercial, janela de venda,
janelas de entrega, público elegível, regras de compromisso, disponibilidade futura, criação de pedido
`pre_book`, decisão de aprovação por exceção e painel de captação por coleção.

## Agentes utilizados
`flutter-senior-architect`, `flutter-ui-design-specialist`,
`vestipro-sales-representative-specialist`, `vestipro-commercial-ops-strategist`.

## Arquivos criados
- `lib/features/pre_book/domain/entities/pre_book_program.dart`
- `lib/features/pre_book/domain/usecases/allocate_pre_book_future_stock_use_case.dart`
- `lib/features/pre_book/domain/usecases/create_pre_book_order_use_case.dart`
- `lib/features/pre_book/domain/usecases/evaluate_pre_book_revision_use_case.dart`
- `lib/features/pre_book/presentation/pages/pre_book_program_page.dart`
- `lib/features/pre_book/pre_book.dart`
- `test/features/pre_book/domain/usecases/allocate_pre_book_future_stock_use_case_test.dart`
- `test/features/pre_book/domain/usecases/create_pre_book_order_use_case_test.dart`
- `test/features/pre_book/domain/usecases/evaluate_pre_book_revision_use_case_test.dart`
- `test/features/pre_book/presentation/pages/pre_book_program_page_test.dart`
- `docs/tasks/TASK-210-implementar-pre-venda-e-pre-book-por-colecao-CONCLUIDA.md`

## Arquivos alterados
- `lib/core/analytics/analytics_events.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Feature-first + Clean Architecture. Entidades e regras ficam em `domain`; UI consome estado pronto e
não acessa Firestore, Storage ou Drift. O pedido usa `Order.orderType = pre_book` sem alterar o
aggregate gerado por Freezed.

## Regras de negócio implementadas
- Programa de pre-book com coleção, janela comercial, janelas de entrega, status, elegibilidade,
  meta, regras de cancelamento, política de preço e regras de compromisso.
- Pedido `pre_book` só é criado dentro da janela comercial, salvo exceção que exige aprovação.
- Pedido de pre-book usa disponibilidade futura e bloqueia variante que só possui pronta entrega.
- Data prometida vem da janela aprovada ou da previsão futura dentro da janela.
- Mudança de quantidade ou janela/data após aprovação exige nova aprovação quando configurado.
- Métricas básicas: reservado, vendido, cancelado, gap de meta, progresso e risco de produção/entrega.

## Regras Firebase implementadas
Nenhuma regra nova nesta task. A autorização final, precificação definitiva e persistência do pedido
continuam dependentes das validações server-side já existentes.

## Analytics implementado
Adicionados os eventos `pre_book_program_opened` e `pre_book_order_created` ao catálogo central.

## Crashlytics implementado
Sem integração nova. Não houve captura de exceção remota nesta camada de domínio/UI.

## Impacto offline
A modelagem preserva o pedido local como draft `pre_book` e carrega snapshot de compromisso para
sincronização/auditoria posterior. Mutação remota segue dependente do fluxo de pedido/outbox existente.

## Impacto multi-tenant
Programa valida `organizationId` e, quando informado, `companyId` contra o pedido base antes de criar
o draft de pre-book.

## Testes criados
- Criação de pedido pre-book dentro e fora da janela comercial.
- Alocação de estoque futuro e bloqueio de consumo de pronta entrega.
- Reaprovação por alteração de quantidade/data após aprovação.
- Widget exibindo datas futuras, estado da janela, indisponibilidade e bloqueio fora da janela.

## Comandos executados
- `Get-Content -Raw C:\Users\Administrador\.codex\skills\proximas-tasks\SKILL.md`
- `Get-Content -Raw AGENTS.md`
- `Get-Content -Raw docs\tasks\TASKS.md`
- `Get-Content -Raw docs\tasks\TASK-210-implementar-pre-venda-e-pre-book-por-colecao.md`
- `rg -n "pré-venda|pre-venda|pre-book|pre_book|estoque futuro|EPIC-32" tasks.md`
- `Get-Content -Raw .claude\agents\flutter-senior-architect.md`
- `Get-Content -Raw .claude\agents\flutter-ui-design-specialist.md`
- `Get-Content -Raw .claude\agents\vestipro-sales-representative-specialist.md`
- `Get-Content -Raw .claude\agents\vestipro-commercial-ops-strategist.md`
- `git status --short --branch`
- `rg --files lib test | rg "(pre|book|reservation|future|stock|order|approval|line_sheets|collections)"`
- `dart format lib\features\pre_book lib\core\analytics\analytics_events.dart test\features\pre_book`
- `flutter test test\features\pre_book`
- `flutter analyze`
- `dart format --set-exit-if-changed lib\features\pre_book lib\core\analytics\analytics_events.dart test\features\pre_book`

## Resultado do formatter
Sucesso. Verificação final sem alterações pendentes.

## Resultado do analyzer
Executado, retornou código 1 por 18 infos preexistentes fora dos arquivos da TASK-210.

## Resultado dos testes
Sucesso: `00:01 +6: All tests passed!`

## Decisões técnicas
- Mantido `orderType` como string livre (`pre_book`) para respeitar o modelo atual de `Order`.
- Datas prometidas e status de disponibilidade ficam em `PreBookOrderLine`, evitando alterar
  `OrderItem` e arquivos gerados nesta task.
- Painel de captação foi criado como widget parametrizado para facilitar plug futuro em repositório,
  rota e dashboard executivo.

## Riscos conhecidos
A submissão final para backend ainda precisa revalidar preço, autorização, janela, disponibilidade
futura e aprovação no fluxo server-side antes de persistir o pedido definitivo.

## Pendências
Nenhuma pendência bloqueante da TASK-210.

## Evidências
Testes específicos de domínio e widget passando em `test/features/pre_book`.

## Commit
Commit local criado.

## Push
Não realizado, conforme solicitado.

## Hash do commit
Será preenchido após o commit local.

## Branch
`main`
