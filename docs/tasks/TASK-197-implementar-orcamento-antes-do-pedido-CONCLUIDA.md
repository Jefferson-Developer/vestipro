# TASK-197 — Concluida (2026-09-09)

## Resumo
Implementado fluxo de orcamento/cotacao antes do pedido, com geracao via Cloud Function, snapshot de precos, validade explicita, expiracao agendada e conversao em pedido com revalidacao de preco e disponibilidade antes da persistencia.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist

## Arquivos criados
- `functions/src/orders/generate-quote.ts`
- `functions/src/orders/convert-quote-to-order.ts`
- `functions/src/orders/expire-quotes.ts`
- `functions/src/orders/quote-shared.ts`
- `lib/features/orders/domain/entities/quote.dart`
- `lib/features/orders/domain/value_objects/quote_status.dart`
- `lib/features/orders/domain/repositories/order_quote_repository.dart`
- `lib/features/orders/domain/usecases/generate_order_quote_use_case.dart`
- `lib/features/orders/domain/usecases/convert_quote_to_order_use_case.dart`
- `lib/features/orders/data/datasources/order_quote_data_source.dart`
- `lib/features/orders/data/datasources/cloud_functions_order_quote_data_source.dart`
- `lib/features/orders/data/dtos/quote_dto.dart`
- `lib/features/orders/data/dtos/quote_conversion_result_dto.dart`
- `lib/features/orders/data/repositories/order_quote_repository_impl.dart`
- `lib/features/orders/presentation/order_quote_flow.dart`
- `test/features/orders/data/dtos/quote_dto_test.dart`
- `test/features/orders/domain/usecases/generate_order_quote_use_case_test.dart`
- `test/features/orders/domain/usecases/convert_quote_to_order_use_case_test.dart`

## Arquivos alterados
- `functions/src/index.ts`
- `functions/src/orders/index.ts`
- `lib/app/bootstrap.dart`
- `lib/features/orders/orders.dart`
- `lib/features/orders/presentation/pages/order_draft_page.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first em Flutter: datasource Cloud Functions, repository, use cases e composicao no bootstrap. Backend em Cloud Functions com regra critica server-side.

## Regras de negócio implementadas
- Orcamento e gerado a partir do rascunho com snapshot de precos.
- Orcamento nao reserva estoque e nao dispara aprovacao de pedido.
- Validade padrao de 7 dias, limitada server-side entre 1 e 90 dias.
- Orcamento expirado e bloqueado para conversao direta.
- Conversao revalida preco e disponibilidade atuais e informa divergencias antes de prosseguir.
- Pedido convertido usa preco atual, sequencia real de pedido e baixa de estoque no momento da conversao.

## Regras Firebase implementadas
- `generateQuote`
- `convertQuoteToOrder`
- `expireQuotes` agendada a cada 60 minutos.
- Escrita em `organizations/{organizationId}/quotes`.
- Auditoria `quote.generated` e `quote.converted`.

## Analytics implementado
- Evento `quote_generated` no use case Flutter.

## Crashlytics implementado
Nao houve integracao nova direta; erros seguem os fluxos existentes de `AppFailure`/Cloud Functions.

## Impacto offline
O rascunho continua offline-first. Geracao/conversao do orcamento dependem de Cloud Functions e, portanto, de conectividade para preco/estoque autoritativos.

## Impacto multi-tenant
Functions validam membership ativo, perfil permitido, escopo de company em cliente/tabela/condicao/regras e nao confiam apenas em dados enviados pelo cliente.

## Testes criados
- DTO de `Quote`.
- `GenerateOrderQuoteUseCase`.
- `ConvertQuoteToOrderUseCase`.

## Comandos executados
- `dart format --set-exit-if-changed lib/features/orders lib/app/bootstrap.dart`
- `npm run build` em `functions`
- `flutter analyze`
- `dart format --set-exit-if-changed lib/features/orders/data/datasources/cloud_functions_order_quote_data_source.dart`
- `dart format --set-exit-if-changed test/features/orders/domain/usecases/generate_order_quote_use_case_test.dart test/features/orders/domain/usecases/convert_quote_to_order_use_case_test.dart`
- `dart format --set-exit-if-changed lib/features/orders lib/app/bootstrap.dart test/features/orders/domain/usecases/generate_order_quote_use_case_test.dart test/features/orders/domain/usecases/convert_quote_to_order_use_case_test.dart`
- `flutter test test/features/orders/domain/usecases/generate_order_quote_use_case_test.dart test/features/orders/domain/usecases/convert_quote_to_order_use_case_test.dart`
- `flutter test test/features/orders/data/dtos/quote_dto_test.dart test/features/orders/domain/usecases/generate_order_quote_use_case_test.dart test/features/orders/domain/usecases/convert_quote_to_order_use_case_test.dart`

## Resultado do formatter
Sucesso na ultima execucao: `Formatted 160 files (0 changed)`.

## Resultado do analyzer
`flutter analyze` retornou 18 infos pre-existentes fora do escopo, sem erros ou warnings introduzidos pela task.

## Resultado dos testes
Sucesso: 4 testes direcionados passaram.

## Decisões técnicas
- A conversao nao reutiliza cegamente o snapshot da cotacao; recalcula preco e checa disponibilidade antes de criar o pedido.
- O snapshot permanece como registro comercial do que foi enviado ao cliente.
- A UI adiciona CTA simples no rascunho e feedback via snackbar, sem colocar regra de negocio no widget.

## Riscos conhecidos
- Nao foram criados testes de emulator para as novas Cloud Functions nesta rodada.
- A exportacao/compartilhamento em PDF do orcamento ficou como reaproveitamento futuro do EPIC-18; a task adiciona geracao e feedback, mas nao uma tela dedicada de preview PDF.

## Pendências
- Cobertura emulator para `generateQuote`, `convertQuoteToOrder` e `expireQuotes`.
- Evoluir tela dedicada/listagem de orcamentos quando o backlog pedir gestao mais completa de cotacoes.

## Evidências
- `npm run build` em `functions`: sucesso.
- `flutter test` direcionado: 4 testes passaram.

## Commit
`feat(orders): add quote before order flow`

## Push
Nao autorizado nesta rodada (`2 tasks sem push`).

## Hash do commit
Hash final informado no resumo da rodada e consultavel via `git log`.

## Branch
`main`
