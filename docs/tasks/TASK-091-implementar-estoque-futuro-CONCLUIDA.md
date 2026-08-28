# TASK-091 — Concluída (2026-08-28)

## Resumo
Previsão de estoque futuro implementada no fluxo de disponibilidade por variante, combinando saldo imediato com entradas futuras ordenadas por data e expondo esse contrato para a UI de grade comercial, busca e detalhe de produto. A experiência comercial agora diferencia claramente pronta entrega de previsão futura, com quantidade, data localizada e origem rastreável da previsão.

## Agentes utilizados
- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados
- `lib/features/inventory/domain/value_objects/future_stock_source.dart`
- `lib/features/inventory/domain/entities/future_stock_entry.dart`
- `lib/features/inventory/domain/entities/variant_future_stock_summary.dart`
- `lib/features/inventory/domain/repositories/future_stock_repository.dart`
- `lib/features/inventory/domain/usecases/get_variant_future_stock_summary_use_case.dart`
- `lib/features/inventory/data/repositories/product_variant_future_stock_repository.dart`
- `test/features/inventory/domain/usecases/get_variant_future_stock_summary_use_case_test.dart`

## Arquivos alterados
- `lib/app/injection.config.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/features/catalog/presentation/bloc/product_detail_bloc.dart`
- `lib/features/catalog/presentation/pages/product_detail_page.dart`
- `lib/features/catalog/presentation/pages/product_grid_page.dart`
- `lib/features/inventory/data/repositories/inventory_variant_availability_repository.dart`
- `lib/features/inventory/inventory.dart`
- `lib/features/products/domain/entities/variant_availability.dart`
- `lib/features/products/presentation/pages/product_search_page.dart`
- `lib/features/products/presentation/widgets/commercial_size_grid.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/features/catalog/presentation/pages/product_detail_page_test.dart`
- `test/features/products/presentation/widgets/variant_availability_contract_widget_test.dart`

## Arquitetura utilizada
Clean Architecture/feature-first: novo contrato de estoque futuro no domain, composição da disponibilidade consolidada em repositório da feature `inventory` e apresentação consumindo apenas o contrato final, sem cálculo de previsão na camada de UI.

## Regras de negócio implementadas
- Estoque futuro nunca é somado ao saldo vendável imediato para fingir pronta entrega.
- Quando não há saldo imediato, mas há previsão futura, a disponibilidade passa para `futureStock` com data, quantidade e origem da previsão.
- As entradas futuras são ordenadas por data esperada para destacar primeiro a previsão mais próxima.
- A UI usa linguagem explícita de previsão, nunca de garantia contratual.
- Datas previstas são tratadas como datas de negócio e exibidas sem deslocamento de fuso horário.

## Regras Firebase implementadas
Nenhuma regra nova nesta task. O consumo reaproveita os contratos e proteções já existentes do módulo de estoque.

## Analytics implementado
- Novo evento `future_stock_viewed`, disparado quando o vendedor seleciona uma cor cuja disponibilidade relevante é estoque futuro no detalhe do produto.

## Crashlytics implementado
Nenhum fluxo específico novo. Falhas seguem trafegando pelos mecanismos já existentes da aplicação.

## Impacto offline
Sem nova persistência local nesta task. A composição reutiliza o fluxo local-first já existente da disponibilidade por variante e apenas enriquece o contrato exposto à UI.

## Impacto multi-tenant
Nenhuma flexibilização de isolamento. A previsão futura continua dependendo de repositórios já escopados por `organizationId`/`companyId`.

## Testes criados
- Use case combinando saldo atual com múltiplas entradas futuras ordenadas por data
- Widget de disponibilidade comercial com estoque futuro em `pt_BR` e `en_US`
- Badge de estoque futuro no detalhe do produto

## Comandos executados
- `dart run build_runner build`
- `flutter analyze`
- `flutter test test/features/inventory/domain/usecases/get_variant_future_stock_summary_use_case_test.dart test/features/products/presentation/widgets/variant_availability_contract_widget_test.dart test/features/catalog/presentation/pages/product_detail_page_test.dart test/features/products/presentation/widgets/commercial_size_grid_test.dart test/features/catalog/presentation/pages/product_grid_page_test.dart test/features/products/presentation/pages/product_search_page_test.dart`
- `dart format --set-exit-if-changed .`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou sem alterações pendentes.

## Resultado do analyzer
`flutter analyze` sem issues.

## Resultado dos testes
- Suite focada do escopo passou.
- `flutter test` completo do repositório passou.

## Decisões técnicas
- A composição final ficou em `InventoryVariantAvailabilityRepository`, preservando um único ponto de verdade para disponibilidade comercial.
- O repositório `ProductVariantFutureStockRepository` usa o `futureStockQuantity` já presente nas variantes como fonte inicial de previsão, reduzindo acoplamento prematuro a uma origem remota ainda não modelada.
- A formatação de data foi corrigida para evitar regressão de fuso horário em datas UTC puras, preservando a semântica comercial da previsão.
- O contrato central de analytics foi atualizado junto com seu teste global para manter a taxonomia auditável.

## Riscos conhecidos
- A origem de previsão ainda é derivada do catálogo do produto; integrações futuras com compra/produção/transferência podem exigir datasource dedicado.
- O evento de analytics é disparado na seleção de cor com estoque futuro; se o produto evoluir para uma interação explícita de expansão de previsão, o gatilho pode ser refinado.

## Pendências
- Integrar fontes transacionais reais de estoque futuro nas tasks seguintes do EPIC-12, quando compra/produção/transferência estiverem modeladas.

## Evidências
- `VariantAvailability` agora expõe `futureAvailableQuantity` e `futureSourceLabel`.
- Grade comercial, busca e detalhe de produto exibem previsão localizada sem confundir com pronta entrega.
- `future_stock_viewed` entrou na taxonomia oficial de analytics.

## Commit
Será realizado localmente sem push.

## Push
Não autorizado nesta conversa.

## Hash do commit
Pendente nesta etapa do arquivo; será preenchido após o commit local.

## Branch
`main`
