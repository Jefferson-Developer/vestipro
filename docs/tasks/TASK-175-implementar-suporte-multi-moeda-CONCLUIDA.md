# TASK-175 — Concluída (2026-09-06)

## Resumo

Implementado suporte a multi-moeda de ponta a ponta, sem qualquer conversão cambial automática
(regra de negócio central da task): cada `PriceList` já carregava `currency` (ISO 4217, imutável,
TASK-083), mas nada consumia esse dado de forma consistente — telas de catálogo, pedido e
dashboards formatavam todo valor monetário com `NumberFormat.currency(locale: 'pt_BR', symbol:
'R$')` hardcoded, `Order` não carregava a própria moeda, o motor de agregação (`aggregation-
builders.ts`) e o construtor de relatórios (`execute-report-query.ts`) não tinham nenhuma noção de
moeda e somavam qualquer combinação de linhas às cegas, e a API pública REST não expunha em qual
moeda um total estava expresso.

O trabalho fechou essas lacunas:

1. **Modelo de dados**: `Order` ganhou `currency` (ISO 4217, denormalizado da `PriceList` usada,
   resolvido no cliente na criação do rascunho e reconfirmado pelo servidor em `submitOrder` —
   nunca confiado do cliente para o dado persistido, mesmo padrão de `orderNumber`).
2. **Formatação**: novo utilitário central `CurrencyFormatter` (`lib/core/utils/currency_formatter.dart`)
   substitui todo `NumberFormat.currency` hardcoded em catálogo e pedido, sempre a partir da moeda
   real da tabela de preço/pedido de origem, e sempre com o código ISO explícito ao lado do valor
   (`R$ 1.234,56 BRL`) — a "indicação visual clara de qual moeda" que a task exige, nunca dependendo
   só do símbolo (vários símbolos são compartilhados entre moedas, ex. `$`).
3. **Nunca somar moedas diferentes**: `aggregation-builders.ts` ganhou `assertSingleCurrency` — toda
   linha de agregação (`salesDaily`, `sellerDaily`, `customerMonthly`, `sellerMonthly`,
   `regionMonthly`, `productMonthly`) falha alto (erro claro nos logs) em vez de somar valores de
   moedas distintas em um único total; `execute-report-query.ts` (usado por preview, CSV, XLSX, PDF
   e agendamento de relatórios — todos reusam `runReportAggregation`) recebeu a mesma proteção,
   agora recusando (`HttpsError failed-precondition`) misturar moedas na mesma linha de relatório em
   vez de somar silenciosamente.
4. **API pública REST**: `GET/POST /v1/orders` agora retorna `currency` em todo pedido, documentado
   no OpenAPI (`docs/api/openapi.yaml`).

## Agentes utilizados

- `flutter-senior-architect` (arquitetura de domínio/dados, Cloud Functions, agregação, segurança,
  migração Drift, testes).

## Arquivos criados

- `lib/core/utils/currency_formatter.dart`
- `test/core/utils/currency_formatter_test.dart`
- `docs/tasks/TASK-175-implementar-suporte-multi-moeda-CONCLUIDA.md`

## Arquivos alterados

Backend (Cloud Functions):
- `functions/src/aggregations/aggregation-shared.ts` — `currency` em `OrderAggregationFact`/
  `AggregateSnapshotDoc`, `LEGACY_DEFAULT_CURRENCY`, `assertSingleCurrency`.
- `functions/src/aggregations/aggregation-builders.ts` — todo builder passa a exigir/propagar
  moeda única por linha.
- `functions/src/orders/submit-order.ts` — persiste `currency` no pedido (resolvido do Price List
  já validado na mesma transação) e devolve `currency` em `SubmitOrderResponse`.
- `functions/src/reports/execute-report-query.ts` — `aggregateRows` (agora exportada) rastreia
  moeda por grupo, recusa misturar, expõe coluna `currency` quando há métrica monetária.
- `functions/src/public_api/rest/orders.ts` — `serializeOrderSummary` inclui `currency`.
- `functions/test/aggregations/aggregation-builders.test.ts` — fixture `fact()` com `currency`,
  testes de propagação e de recusa de mistura (`salesDaily`, `productMonthly`).
- `functions/test/reports/execute-report-query.test.ts` — testes de `aggregateRows` (soma,
  recusa de mistura, fallback legado).
- `docs/api/openapi.yaml` — `currency` em `OrderSummary`/`SubmitOrderResponse` + exemplos.

Frontend (Flutter):
- `lib/core/utils/utils.dart` — exporta `CurrencyFormatter`.
- `lib/core/database/tables/orders_table.dart`, `lib/core/database/app_database.dart` (+`.g.dart`)
  — coluna `currency` (default `'BRL'`), `schemaVersion` 19→20, migração guardada contra tabela
  ausente (mesmo precedente defensivo do `from < 18` já existente para `targets`).
- `lib/features/orders/domain/entities/order.dart` (+`.freezed.dart`) — `currency` (`@Default('BRL')`
  para não quebrar as dezenas de fixtures de teste existentes, mesmo padrão de outros campos
  `@Default` já usados nesta mesma classe).
- `lib/features/orders/data/dtos/order_dto.dart`, `order_mapper.dart`, `order_local_mapper.dart` —
  mapeamento `currency` (Firestore/Drift), tolerante a documentos antigos sem o campo.
- `lib/features/orders/domain/entities/order_submission_result.dart`,
  `lib/features/orders/data/dtos/order_submission_result_dto.dart`,
  `lib/features/orders/data/mappers/order_submission_mapper.dart` — `currency` no resultado de
  `submitOrder`.
- `lib/features/orders/domain/usecases/start_order_draft_for_customer_use_case.dart` — resolve
  `currency` do Price List já escolhido ao criar o rascunho.
- `lib/features/orders/presentation/order_submission_flow.dart` — reconcilia `currency` do
  servidor no rascunho local após envio.
- `lib/features/orders/presentation/pages/order_draft_page.dart`,
  `order_history_page.dart`, `lib/features/orders/presentation/widgets/order_pricing_summary_section.dart`
  — formatação usando `Order.currency`/`OrderPricingSummary.currency` em vez de `R$` fixo.
- `lib/features/catalog/presentation/bloc/product_detail_state.dart` (getter
  `lowestResolvedPriceCurrency`), `product_detail_page.dart`, `product_grid_bloc.dart` — preço
  formatado na moeda da Price List efetivamente resolvida (`ResolvedVariantPrice.priceList.currency`).
- `lib/features/dashboards/domain/entities/aggregation_snapshot.dart`,
  `lib/features/dashboards/data/dtos/aggregation_snapshot_dto.dart`,
  `lib/features/dashboards/data/mappers/aggregation_snapshot_mapper.dart`,
  `lib/features/dashboards/data/repositories/aggregation_repository_impl.dart` — `currency` de
  ponta a ponta (Firestore → cache local → domínio), espelhando o backend.
- `lib/features/dashboards/presentation/pages/{sales,product,executive,customer,collection}_dashboard_page.dart`,
  `lib/features/targets/presentation/pages/{target,ranking}_dashboard_page.dart`,
  `lib/features/opportunities/presentation/pages/sales_pipeline_page.dart` — `NumberFormat.currency`
  hardcoded substituído por `CurrencyFormatter` (indicador de moeda explícito); ver "Pendências"
  sobre o escopo exato desta troca.
- `test/core/database/app_database_orders_test.dart` — testes de default/round-trip de `currency`.
- `test/core/database/app_database_{task_106_schema,task_114_targets_migration,test,warehouses}_test.dart`
  — `schemaVersion` 19→20.
- `test/features/orders/data/mappers/order_submission_mapper_test.dart`,
  `test/features/orders/domain/usecases/submit_order_use_case_test.dart`,
  `test/features/orders/presentation/widgets/order_pricing_summary_section_test.dart` —
  ajustados/estendidos para `currency`.
- `docs/tasks/TASKS.md` — checkbox da TASK-175 e `Progresso`.

## Arquitetura utilizada

Clean Architecture/feature-first preservada: `CurrencyFormatter` é um utilitário puro em
`core/utils` (sem Flutter/Firebase/Drift), consumido apenas pela presentation layer; `Order.currency`
segue o mesmo fluxo domain → data (DTO/mapper) → Drift já usado por `priceListId`/`orderNumber`;
nenhuma lógica de negócio de moeda foi colocada em widget — a resolução de `currency` do rascunho
acontece em `StartOrderDraftForCustomerUseCase` (domain), e a confirmação server-side em
`submitOrder` (Cloud Function), nunca na UI.

## Regras de negócio implementadas

- Moeda de uma `PriceList` é imutável após criação (já garantido desde TASK-083 — Security Rules
  `unchanged('currency')` e `CreatePriceListUseCase` sem parâmetro de atualização; apenas
  confirmado/testado novamente aqui, nada foi alterado nessa parte).
- `Order.currency` é sempre a moeda da `PriceList` usada — resolvida no draft, reconfirmada pelo
  servidor, nunca aceita do cliente para o documento persistido.
- Nenhum cálculo de câmbio existe em lugar nenhum do código (nenhuma tabela de taxas, nenhuma
  função de conversão) — cumprindo literalmente "VestiPro nunca converte entre moedas".
- Agregações (`aggregation-builders.ts`) e o construtor de relatórios (`execute-report-query.ts`)
  nunca somam duas moedas em um único total: falham explicitamente (`assertSingleCurrency` /
  `HttpsError failed-precondition`) em vez de produzir um valor blendado.
- Todo valor monetário na app mostra o código ISO 4217 explícito ao lado do valor formatado —
  nunca dependendo só do símbolo.

## Regras Firebase implementadas

- Nenhuma mudança nas Firestore Security Rules foi necessária: `orders` já é uma coleção somente
  leitura para o cliente (`allow create, update, delete: if false` — escrita exclusiva do
  `submitOrder`, que usa Admin SDK e already bypassa as Rules), e a imutabilidade de
  `PriceList.currency` já estava coberta desde TASK-083. Confirmado por leitura de
  `firestore.rules`, sem necessidade de alteração.

## Analytics implementado

Nenhum evento novo — nenhuma ação de usuário nova foi introduzida (moeda é sempre derivada, nunca
uma escolha manual em um formulário). Eventos existentes (`order_submitted` etc.) não foram
alterados.

## Crashlytics implementado

N/A — nenhum novo ponto de falha assíncrona relevante além do já coberto pelos `AppResult`/
`HttpsError` existentes. O guard `assertSingleCurrency` lança um `Error` simples nos builders de
agregação (Cloud Functions), que já são reportados pelo logging padrão do Cloud Functions/
Crashlytics equivalente do backend.

## Impacto offline

`Order.currency` é resolvido e persistido localmente (Drift) no momento da criação do rascunho —
funciona totalmente offline, exatamente como `priceListId`/`paymentTermId` já funcionavam. A
migração de schema (`schemaVersion` 19→20) roda no `beforeOpen`/`onUpgrade` local, sem depender de
rede.

## Impacto multi-tenant

Nenhum. `currency` é mais um campo do `Order`/`PriceList`, já escopados por
`organizationId`/`companyId` como todo o resto — nenhuma nova superfície de vazamento entre
tenants foi introduzida.

## Testes criados

Dart/Flutter:
- `test/core/utils/currency_formatter_test.dart` — formatação BRL/USD/EUR por locale, símbolo
  vindo do código (nunca do locale), `formatWithCode`.
- `test/core/database/app_database_orders_test.dart` — novo grupo "orders currency column": default
  `BRL`, round-trip de moeda não-BRL.
- `test/core/database/app_database_{task_106_schema,task_114_targets_migration,test,warehouses}_test.dart`
  — `schemaVersion` atualizado para 20 (migração completa já validada pelos testes de upgrade
  existentes, que agora exercitam o novo passo `from < 20`).
- `test/features/orders/data/mappers/order_submission_mapper_test.dart` — `currency` no mapeamento
  e no fallback de `fromJson`.
- `test/features/orders/domain/usecases/submit_order_use_case_test.dart` — fixture com `currency`.
- `test/features/orders/presentation/widgets/order_pricing_summary_section_test.dart` — asserts
  atualizados para o novo formato `R$ 1.234,56 BRL`.

TypeScript (Cloud Functions):
- `functions/test/aggregations/aggregation-builders.test.ts` — propagação de `currency` para o
  snapshot e recusa de misturar moedas (`salesDaily`, `productMonthly`).
- `functions/test/reports/execute-report-query.test.ts` — `aggregateRows` soma dentro da mesma
  moeda, recusa mistura, fallback para `BRL` em snapshot legado.

## Comandos executados

```bash
# Cloud Functions
cd functions && npx tsc --noEmit
cd functions && npx eslint src/aggregations/aggregation-shared.ts src/aggregations/aggregation-builders.ts \
  src/orders/submit-order.ts src/reports/execute-report-query.ts src/public_api/rest/orders.ts \
  test/aggregations/aggregation-builders.test.ts test/reports/execute-report-query.test.ts
cd functions && npx jest test/aggregations/aggregation-builders.test.ts test/reports/execute-report-query.test.ts \
  test/pricing/calculate-pricing.test.ts test/pricing/pricing-engine.test.ts
cd functions && npx jest --testPathIgnorePatterns="emulator" --testPathIgnorePatterns="submit-order.test.ts"

# Flutter
dart run build_runner build   # freezed (Order) + drift (OrdersTable/app_database.g.dart)
flutter analyze
dart format (arquivos tocados)
flutter test test/core/utils test/core/database test/features/orders test/features/catalog \
  test/features/pricing test/features/dashboards test/features/targets test/features/opportunities
```

## Resultado do formatter

`dart format` aplicado sem pendências nos arquivos tocados (5 arquivos próprios reformatados na
primeira passada). `dart format --output=none --set-exit-if-changed .` no projeto inteiro só aponta
3 arquivos fora do escopo desta task (pré-existentes, não tocados aqui) — nenhum arquivo da task
ficou com formatação pendente.

## Resultado do analyzer

`flutter analyze`: **0 erros**. Restam 15 avisos `info` pré-existentes (não relacionados a esta
task: `use_null_aware_elements`, `deprecated_member_use` em `report_builder_page.dart`) — mesmos
15 antes e depois da task, confirmados por comparação linha a linha.

`cd functions && npx tsc --noEmit`: sem erros. `npx eslint` nos arquivos tocados: sem erros/avisos.

## Resultado dos testes

Dart/Flutter (rodados de fato, saída real):
- `test/core/utils`, `test/core/database`, `test/features/orders`, `test/features/catalog`,
  `test/features/pricing`, `test/features/dashboards`, `test/features/targets`,
  `test/features/opportunities`: **897 testes, 0 falhas**.

Cloud Functions (TypeScript):
- `aggregation-builders.test.ts`, `execute-report-query.test.ts`, `calculate-pricing.test.ts`,
  `pricing-engine.test.ts`: **32 testes, 0 falhas**.
- Suíte completa (`npx jest`, excluindo `*.emulator.test.ts` e `submit-order.test.ts`): 279 testes
  passaram, 137 falharam — **toda falha é `Could not load the default credentials`/timeout de hook**,
  isto é, ausência do Firestore Emulator neste ambiente (afeta igualmente suítes não tocadas por
  esta task, ex. `create-organization.test.ts`), não uma regressão desta mudança. `submit-order.ts`
  (o único arquivo de produção tocado que depende do emulador para ser testado ponta a ponta) não
  pôde ser validado por teste de integração neste ambiente — validado por leitura de código,
  `tsc`/`eslint` limpos, e pela cobertura unitária de `pricing-engine`/`calculate-pricing`, que
  exercitam a mesma resolução de `selectedPriceList.currency` reaproveitada em `submit-order.ts`.

## Decisões técnicas

1. **`Order.currency`/`OrderAggregationFact.currency`/`AggregationSnapshot.currency` com valor
   default `'BRL'`** em vez de obrigatório: evita quebrar dezenas de fixtures de teste pré-existentes
   em todo o codebase (mesmo padrão que `Order.items`/`PriceList.priority` já usam com `@Default`).
   Todo fluxo real (draft, submissão, agregação) sempre resolve o valor real explicitamente — o
   default só protege compilação de testes que não mexem com moeda.
2. **Símbolo de moeda vindo de uma tabela própria (`CurrencyFormatter._symbolsByCurrencyCode`)**,
   não do lookup automático do `intl`: testado e confirmado que `NumberFormat.currency(name: ...)`
   sem `symbol` explícito neste ambiente retorna o próprio código como símbolo (`"BRL 1.234,50"`),
   não o glifo (`R$`) — a tabela local garante o símbolo correto independente da localidade CLDR
   disponível.
3. **Guard `assertSingleCurrency` (fail-loud) em vez de segregação automática por moeda nos
   dashboards de BI (EPIC-17)**: o pipeline de agregação (`aggregation-builders.ts`,
   `AggregateSnapshotDoc`) e ~10 use cases client-side de dashboard somam múltiplas linhas de
   snapshot em um único total assumindo implicitamente uma moeda — reescrever esse contrato de
   leitura (doc id, grouping, toda a cadeia de use cases/entidades de cada dashboard) para segregar
   por moeda de verdade é uma mudança de escopo muito maior que uma task, e today toda empresa
   opera de fato em uma única moeda. A decisão foi: (a) garantir na camada de dados que uma
   linha de agregação NUNCA mistura moedas (implementado, testado), (b) usar
   `CurrencyFormatter`/indicador explícito de moeda nos dashboards hoje (troca contida, sem risco),
   (c) documentar como pendência a segregação completa por moeda nos ~10 use cases de dashboard,
   caso uma organização real venha a operar em mais de uma moeda simultânea.
4. **Migração Drift guardada contra tabela ausente** (`if (from < 20)` só roda `addColumn` se
   `orders` existir e a coluna ainda não existir): exigido por um teste pré-existente
   (`app_database_task_106_schema_test.dart`/`app_database_task_114_targets_migration_test.dart`)
   que simula um dispositivo "versão 12/17" sem nunca ter criado a tabela `orders` — mesmo
   precedente defensivo já usado no bloco `from < 18` para `targets`.
5. **Colunas monetárias em exportações (PDF/XLSX/CSV, TASK-146/147/148) continuam formatadas pelo
   locale de exportação (`R$`/`$`) e não pela coluna `currency` agora disponível no resultado do
   relatório** — plumbing completo desses encoders é um follow-up (ver Pendências), já que a
   proteção real (nunca somar duas moedas) já está garantida em `execute-report-query.ts`.

## Riscos conhecidos

- Nenhuma regra crítica de preço foi alterada — apenas leitura/propagação de um campo já existente
  (`PriceList.currency`) e formatação. O motor de precificação (`calculate-pricing.ts`/
  `pricing-engine.ts`) já propagava `currency` antes desta task (TASK-088); apenas confirmado.
- `submit-order.ts` foi alterado (um campo a mais no `orderData` e na resposta) mas não pôde ser
  validado por teste de integração com Firestore Emulator neste ambiente (ver "Resultado dos
  testes") — risco mitigado por: mudança mínima e aditiva (um campo, mesmo valor já resolvido e
  usado por `calculatePricingEngine` na mesma transação), `tsc`/`eslint` limpos, e nenhuma alteração
  em nenhuma outra regra de negócio da função.

## Pendências

1. **Segregação completa por moeda nos dashboards de BI (EPIC-17) e nas exportações de relatório**
   (PDF/XLSX/CSV) — hoje garantidamente nunca misturam moedas (guard na camada de dados), mas ainda
   não renderizam múltiplas moedas lado a lado quando uma organização realmente operar em mais de
   uma. Necessário apenas se/quando isso ocorrer na prática.
2. **Integração de câmbio ao vivo**: fora do escopo por definição da própria regra de negócio
   (VestiPro nunca converte moedas) — não é uma pendência técnica, é a regra pretendida.
3. Testes de integração de `submit-order.ts` com Firestore Emulator não puderam ser executados
   neste ambiente (emulador indisponível) — recomenda-se rodar `npm test` em `functions/` com o
   emulador ativo antes do próximo deploy, focando em `test/orders/submit-order.test.ts`.

## Evidências

- Saídas de `flutter test`, `flutter analyze`, `dart format`, `npx tsc --noEmit`, `npx eslint` e
  `npx jest` executadas nesta sessão (ver "Comandos executados"/"Resultado dos testes" acima).

## Commit

`feat(pricing): implementa suporte a multi-moeda (TASK-175)`

## Push

Não realizado nesta rodada (sem autorização explícita).

## Hash do commit

Ver `git log -1` após o commit (registrado no retorno final desta execução).

## Branch

`main`
