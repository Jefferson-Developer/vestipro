# TASK-094 — Concluída (2026-08-29)

## Resumo
Implementação do cálculo server-side de sell-through, cobertura de estoque e giro por escopo (produto/variante/coleção/warehouse) e período, persistido como snapshot pré-computado em `stockTurnoverMetrics`, e exposto ao app via caso de uso `GetStockTurnoverMetricsUseCase` com DTO estável para consumo por dashboards (EPIC-17) e engine de insights (EPIC-16, TASK-128).

## Agentes utilizados
- flutter-senior-architect

## Arquivos criados
- `functions/src/inventory/stock-turnover-shared.ts`
- `functions/src/inventory/recompute-stock-turnover-metrics.ts`
- `functions/test/inventory/stock-turnover-shared.test.ts`
- `functions/test/inventory/recompute-stock-turnover-metrics.test.ts`
- `lib/features/inventory/domain/value_objects/stock_turnover_scope_type.dart`
- `lib/features/inventory/domain/value_objects/stock_coverage_status.dart`
- `lib/features/inventory/domain/entities/stock_turnover_metric_scope.dart`
- `lib/features/inventory/domain/entities/stock_turnover_metric_snapshot.dart`
- `lib/features/inventory/domain/repositories/stock_turnover_repository.dart`
- `lib/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart`
- `lib/features/inventory/data/dtos/stock_turnover_metric_snapshot_dto.dart`
- `lib/features/inventory/data/mappers/stock_turnover_metric_snapshot_mapper.dart`
- `lib/features/inventory/data/datasources/stock_turnover_data_source.dart`
- `lib/features/inventory/data/datasources/firestore_stock_turnover_data_source.dart`
- `lib/features/inventory/data/repositories/stock_turnover_repository_impl.dart`
- `test/features/inventory/data/dtos/stock_turnover_metric_snapshot_dto_test.dart`
- `test/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case_test.dart`

## Arquivos alterados
- `functions/src/index.ts` (export da Cloud Function `recomputeStockTurnoverMetrics`)
- `firestore.rules` (regras de `stockTurnoverDailyFacts` e `stockTurnoverMetrics`)
- `lib/features/inventory/inventory.dart` (exports da barrel file da feature)
- `lib/app/injection.config.dart` (regenerado via `build_runner` para registrar as novas classes `@injectable`)
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Feature-first + Clean Architecture no app (`domain/data`, sem presentation nesta task — indicadores são consumidos por outras features) e Cloud Function callable dedicada em `functions/src/inventory`, reaproveitando os helpers de `invite-shared` (RBAC) e `callable-meta` (correlationId) já existentes no backend.

## Regras de negócio implementadas
- Sell-through = vendido / (estoque inicial + recebido); giro = vendido / estoque médio do período; cobertura em dias = estoque final / venda média diária.
- Cálculo sempre server-side e pré-computado por período (`periodStart`/`periodEnd` configuráveis na chamada, nunca hardcoded), nunca recalculado no client a partir do histórico bruto.
- Casos de borda explícitos via `coverageStatus`: `noStockBaseline` (sem estoque inicial + recebido), `noRecentSales` (sem venda média no período) e `ready`; nenhuma divisão por zero.
- Snapshot agregado simultaneamente nos 4 escopos (produto, variante, coleção, warehouse) a partir dos mesmos fatos diários (`stockTurnoverDailyFacts`).
- Apenas `OWNER`/`ADMIN`/`SALES_MANAGER` podem disparar o recálculo (callable `recomputeStockTurnoverMetrics`).

## Regras Firebase implementadas
- Export da Cloud Function callable `recomputeStockTurnoverMetrics` em `functions/src/index.ts`.
- Firestore Rules: `stockTurnoverDailyFacts` bloqueada para o cliente (somente backend); `stockTurnoverMetrics` com leitura restrita a quem tem `report.viewSensitive` ou `inventory.adjust`, escrita sempre `false` (somente Cloud Function via Admin SDK).

## Analytics implementado
Não aplicável nesta task.

## Crashlytics implementado
Não aplicável nesta task.

## Impacto offline
Sem impacto no fluxo offline atual; os indicadores são somente-leitura, calculados no backend e consumidos sob demanda pelo app quando online.

## Impacto multi-tenant
Toda leitura/escrita é escopada em `organizations/{organizationId}`; o repositório e o data source exigem `organizationId` explícito e a Cloud Function valida o vínculo ativo do usuário à organização antes de recalcular.

## Testes criados
- `functions/test/inventory/stock-turnover-shared.test.ts` — cálculo de sell-through/cobertura/giro cobrindo período válido, ausência de venda (sem divisão por zero) e ausência de baseline de estoque.
- `functions/test/inventory/recompute-stock-turnover-metrics.test.ts` — geração do snapshot a partir de fatos simulados de saldo/venda via Firestore Emulator (RBAC, período inválido, agregação nos 4 escopos).
- `test/features/inventory/data/dtos/stock_turnover_metric_snapshot_dto_test.dart` — round-trip do DTO.
- `test/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case_test.dart` — teste de contrato validando consumo do snapshot por um mock de dashboard e de insight.

## Comandos executados
- `dart run build_runner build` (regeneração de `injection.config.dart`)
- `dart format --output=none --set-exit-if-changed <arquivos da task>`
- `flutter analyze lib/features/inventory test/features/inventory`
- `flutter test test/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case_test.dart test/features/inventory/data/dtos/`
- `npm run build` (functions)
- `npx eslint src/inventory/recompute-stock-turnover-metrics.ts src/inventory/stock-turnover-shared.ts test/inventory/recompute-stock-turnover-metrics.test.ts test/inventory/stock-turnover-shared.test.ts` (functions)
- `npm test -- inventory/stock-turnover-shared inventory/recompute-stock-turnover-metrics` (functions)

## Resultado do formatter
Sucesso (13 arquivos, nenhuma alteração necessária).

## Resultado do analyzer
Sucesso (`flutter analyze` sem issues no escopo da feature).

## Resultado dos testes
- Testes Dart: sucesso (2/2).
- `stock-turnover-shared.test.ts`: sucesso (3/3).
- `recompute-stock-turnover-metrics.test.ts`: **falhou neste ambiente** — o teste depende do Firestore Emulator, e este ambiente de execução não tem Java instalado (`firebase emulators:exec` aborta com "Could not spawn `java -version`"). Confirmado que essa é uma limitação de ambiente pré-existente e não específica desta task: o mesmo padrão de teste em `apply-stock-balance-adjustment.test.ts` (de uma task já concluída e mesclada anteriormente) falha exatamente da mesma forma neste ambiente. `npm run build` e `eslint` do arquivo passam sem erro, e a lógica de agregação em si está coberta e validada por `stock-turnover-shared.test.ts` (sem emulador).

## Decisões técnicas
- Os fatos diários (`stockTurnoverDailyFacts`) são tratados como entrada somente-backend (bloqueados para o client), assumindo que serão populados por um processo de ETL/job futuro a partir dos eventos de venda e movimentação de estoque; esta task cobre o cálculo/agregação a partir desses fatos, não a geração deles.
- O DTO/entidade de saída (`StockTurnoverMetricSnapshot`) foi desenhado como contrato estável e desacoplado do cálculo interno, para consumo direto por EPIC-16 (insights) e EPIC-17 (dashboards) sem acesso à implementação do agregador.
- O `injection.config.dart` estava desatualizado (as classes `@injectable`/`@LazySingleton` da feature ainda não apareciam no container gerado); foi regenerado via `build_runner` para que o caso de uso fique de fato injetável na aplicação.

## Riscos conhecidos
- O teste de agregação via Firestore Emulator não pôde ser executado neste ambiente (sem Java); deve ser executado em CI/ambiente com o Firebase Emulator Suite disponível antes do deploy.
- Não há job agendado de geração dos `stockTurnoverDailyFacts` nem de disparo periódico do `recomputeStockTurnoverMetrics`; ambos ficam como trabalho futuro (ex.: Cloud Scheduler) fora do escopo desta task.

## Pendências
- Job/pipeline que popula `stockTurnoverDailyFacts` a partir dos eventos reais de venda/estoque.
- Agendamento periódico (Cloud Scheduler) do recálculo de métricas, quando o volume de dados justificar automação além do disparo manual/callable.
- Consumo destes indicadores pelos dashboards (EPIC-17) e pela engine de insights (EPIC-16/TASK-128), que dependem desta task mas ainda não foram implementados.

## Evidências
- Teste TypeScript validando cálculo de sell-through/cobertura/giro sem divisão por zero.
- Teste Dart de contrato validando consumo do snapshot por mocks de dashboard e de insight.
- Build limpo do `functions` (`tsc`) e `flutter analyze` sem issues.

## Commit
Realizado nesta rodada (ver hash abaixo).

## Push
Não autorizado nesta rodada.

## Hash do commit
`a40061f`

## Branch
`main`
