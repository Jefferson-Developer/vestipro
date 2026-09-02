# TASK-133 — Criar camada de agregação server-side — CONCLUÍDA

**Epic:** EPIC-17 — Dashboards e BI
**Agentes:** `flutter-senior-architect`

## Resumo

Implementada a camada de agregação server-side que os dashboards do EPIC-17 (TASK-134 a TASK-143)
devem consumir: cinco dimensões de snapshot pré-calculado (`salesDaily`, `customerMonthly`,
`productMonthly`, `sellerMonthly`, `regionMonthly`), geradas por Cloud Functions idempotentes, mais o
`AggregationRepository` no app Flutter que as consome com cache local e TTL — nenhum dashboard futuro
precisa (nem deve) varrer `orders`/`customers`/`products` diretamente.

## Decisão de escopo (por que não inclui a população de `insight*Snapshots`)

Várias tasks do EPIC-16 já concluídas (TASK-123 a TASK-131) documentaram, em suas próprias seções de
pendências, que dependem de "TASK-133 — camada de agregação server-side" para popular as coleções
`insightCustomerSnapshots`/`insightRevenueComparisons`/`insightCustomerGrowthSnapshots`/
`insightCrossSellSnapshots`/`insightUpSellSnapshots`/`insightInsufficientMixSnapshots`/
`insightStockPositionSnapshots`/`insightChurnRiskSnapshots`/`insightAbandonedOrderSnapshots`/
`insightSalesRepBelowTargetSnapshots` que `generateInsightsScheduled` (TASK-121) já sabe ler.

O texto desta task (`docs/tasks/TASK-133-criar-camada-de-agregacao-server-side.md`) — a fonte
normativa do que "concluir a TASK-133" significa — define escopo técnico e critérios de aceite
inteiramente em torno das cinco agregações de BI para os dashboards do EPIC-17
(`salesDaily`/`customerMonthly`/`productMonthly`/`sellerMonthly`/`regionMonthly`); não lista as dez
coleções `insight*Snapshots` do EPIC-16 nem cita seus nomes. É esse texto — e não o que uma task
anterior antecipou informalmente — que define "pronto" aqui.

Popular as dez coleções `insight*Snapshots` corretamente exigiria reimplementar, para cada uma, a
mesma lógica de negócio específica que cada regra de insight (`domain/rules/*_insight_rule.dart`)
já espera como entrada (grupos de similaridade para cross-sell/up-sell/mix insuficiente, pesos de
score de churn, projeção de meta por vendedor, detecção de pedido abandonado via Outbox etc.) — dez
mini-motores de dados, não uma agregação genérica de faturamento por dimensão. Fazer isso de forma
apressada dentro desta task arriscaria entregar algo quebrado ou incoerente com o contrato que cada
regra já valida em seus próprios testes.

**Decisão:** este PR entrega a camada de agregação de BI descrita no escopo técnico literal da task
(cinco dimensões de dashboard) e deixa claro, aqui, que a população real das dez coleções
`insight*Snapshots` continua pendente — não como um item "opcional" desta task, mas como um
follow-up que merece sua própria task dedicada (ou uma expansão explícita do EPIC-16), com uma regra
de negócio por vez, do mesmo jeito que as próprias regras de insight foram implementadas uma a uma
(TASK-122 a TASK-131). Nenhuma insight rule é marcada como "desbloqueada" por este PR.

## O que foi implementado

### Cloud Functions (`functions/src/aggregations/`)

- `aggregation-shared.ts` — tipos compartilhados: `AggregationDimension`, `OrderAggregationFact`
  (fato extraído uma única vez por pedido e reaproveitado pelas cinco dimensões),
  `REVENUE_RECOGNIZED_ORDER_STATUSES` (todo status exceto `rejected`/`cancelled`/`draft`/
  `pending_sync` conta como atividade comercial real), `netRevenueOf` (fórmula definitiva de receita
  líquida por pedido — ver nota abaixo), builders de chave de período (`formatDayKey`/
  `formatMonthKey`/`dayRange`/`monthRange`) e o builder do id determinístico de documento
  (`buildAggregateDocId`, `${companyId}_${scopeId}_${periodKey}` — chave de upsert idempotente).
- `aggregation-builders.ts` — funções puras (sem Firestore) que constroem os snapshots de cada
  dimensão a partir de uma lista de `OrderAggregationFact` + labels denormalizados opcionais
  (nome do cliente/vendedor/produto, categoria, coleção, segmento, região).
- `aggregation-data-source.ts` — porta `AggregationDataSource` (mesmo padrão de
  `StockAlertPersistence` em `functions/src/inventory/sync-stock-alerts.ts`: injeta a persistência,
  testa a orquestração sem emulador) + implementação real com Firestore.
- `recompute-sales-daily-on-order-write.ts` — trigger `onDocumentWritten` em
  `organizations/{orgId}/orders/{orderId}`: recomputa o snapshot `salesDaily` **do dia afetado**
  inteiro (nunca incrementa um contador) a cada escrita de pedido — near-real-time, idempotente e
  auto-corretivo.
- `recompute-monthly-aggregates.ts` — `onCall` (`recomputeMonthlyAggregates`, RBAC
  OWNER/ADMIN/SALES_MANAGER, mesmo allow-list de `recomputeStockTurnoverMetrics`) para reprocessamento
  manual de um mês/empresa, mais `onSchedule` noturno (`recomputeMonthlyAggregatesScheduled`, 03:00
  America/Sao_Paulo) que recomputa **mês atual + mês anterior** de toda organização/empresa ativa —
  o mês anterior entra de novo para acomodar pedidos offline que só sincronizam (e só então recebem
  status final) alguns dias depois da virada do mês.
- Estratégia near-real-time vs. batch documentada inline nos dois arquivos acima (ver comentários de
  cabeçalho de `recomputeSalesDailyForOrderChange`/`recomputeMonthlyAggregatesForCompany`): `salesDaily`
  é recomputado por escrita (barato, um único dia); as quatro dimensões mensais (`customerMonthly`/
  `productMonthly`/`sellerMonthly`/`regionMonthly`) fazem join com clientes/vendedores/produtos e são
  recomputadas em lote — caro demais para rodar a cada pedido.
- Isolamento por job: falha ao recomputar uma empresa/mês nunca interrompe as demais (try/catch por
  iteração no scheduled handler; try/catch isolado no trigger de `salesDaily`).
- Logging estruturado via `firebase-functions/v2`'s `logger` (tempo de execução, quantidade de
  snapshots gerados, falhas) em toda função.

### Regra de faturamento (decisão documentada)

Não existe hoje, em nenhum lugar do código, um campo/getter definitivo de "total do pedido" —
`Order.itemsSubtotal` (`lib/features/orders/domain/entities/order.dart`) é explicitamente parcial
("antes de discountAmount/surchargeAmount/shippingAmount/taxAmount"). `netRevenueOf` define a fórmula
usada por toda agregação por pedido (`salesDaily`/`customerMonthly`/`sellerMonthly`/`regionMonthly`):
`itemsSubtotal - discountAmount + surchargeAmount + shippingAmount` — a soma de todo componente
monetário hoje persistido no pedido. Se uma task futura de pedidos modelar um total definitivo, os
agregadores devem ser atualizados para usá-lo.

`productMonthly` é a exceção: agrupa por item, não por pedido (um pedido com três produtos distintos
contribui para três snapshots), e **não aloca** desconto/acréscimo/frete do pedido por item — não há
detalhamento de desconto por item persistido em `OrderItem` hoje. Por isso `revenueNet == revenueGross`
nessa dimensão (documentado em código e coberto por teste).

### Coleções Firestore e Security Rules

Ao invés do caminho ilustrativo do texto da task (`organizations/{orgId}/aggregates/salesDaily/{date}`
— que não é um caminho Firestore válido, pois mistura coleção/documento sem alternância consistente),
segui a convenção já estabelecida no repositório para dados pré-computados (`stockTurnoverMetrics`,
`insight*Snapshots`): cinco subcoleções, cada uma diretamente sob `organizations/{orgId}`, com id de
documento determinístico:

- `salesDailyAggregates/{companyId}_{companyId}_{YYYY-MM-DD}`
- `customerMonthlyAggregates/{companyId}_{customerId}_{YYYY-MM}`
- `productMonthlyAggregates/{companyId}_{productId}_{YYYY-MM}`
- `sellerMonthlyAggregates/{companyId}_{sellerId}_{YYYY-MM}`
- `regionMonthlyAggregates/{companyId}_{region}_{YYYY-MM}`

`firestore.rules`: as cinco coleções ganharam um bloco `match` cada, logo após `stockTurnoverMetrics`
— leitura (`get`/`list`) gated por `report.viewSensitive` (mesma capability que já protege
`stockTurnoverMetrics`, por serem a mesma classe de dado sensível: faturamento agregado), escrita
sempre `false` (só a Admin SDK escreve, via Cloud Functions).

`firestore.indexes.json`: cinco índices compostos novos (`companyId` ASC + `scopeId` ASC + `periodKey`
ASC), um por coleção — necessários para `listByPeriodRange` (igualdade + igualdade + intervalo/orderBy
num terceiro campo). `listByPeriod` (igualdade + igualdade em `companyId`/`periodKey`) não precisa de
índice novo. As queries das próprias Cloud Functions reaproveitam o índice composto que já existe em
`orders` (`companyId` ASC + `deletedAt` ASC + `createdAt` DESC) — nenhum índice novo foi necessário do
lado das Functions.

### App Flutter (`lib/features/dashboards/`)

Estrutura feature-first nova (só `domain/` + `data/`, sem `presentation/` — a primeira tela real
começa em TASK-134):

- `domain/value_objects/aggregation_dimension.dart`, `domain/entities/aggregation_snapshot.dart`,
  `domain/repositories/aggregation_repository.dart` (contrato: `getSnapshot`/`listByPeriod`/
  `listByPeriodRange`, sempre devolvendo `null`/lista vazia — nunca erro — quando o snapshot ainda não
  existe para o período).
- `data/dtos/aggregation_snapshot_dto.dart`, `data/mappers/aggregation_snapshot_mapper.dart`,
  `data/datasources/aggregation_remote_data_source.dart` (+ implementação Firestore reaproveitando
  `FirestoreCollectionDataSource<T>`/`FirestoreConverter<T>` já existentes em `core/database/`),
  `data/repositories/aggregation_repository_impl.dart`.

**Decisão de cache — em memória, não Drift.** Ao contrário de `VariantStockBalanceRepositoryImpl`
(cache Drift com TTL, usado para decisões de estoque offline-first), `AggregationRepositoryImpl` usa
cache **em memória** com TTL de 5 minutos. Justificativa documentada no próprio arquivo: nenhuma
decisão comercial offline (pedido, preço, estoque) depende de um dashboard renderizar offline —
diferente do saldo de variante, que trava se o vendedor consegue adicionar uma linha ao pedido em
campo. Um dashboard reaberto após o app fechar simplesmente recarrega quando voltar a ficar online.
Criar uma nova tabela Drift/migração de schema sem nenhum consumidor de UI real ainda (esta task não
inclui `presentation/`) foi deliberadamente adiado para a primeira task de dashboard que efetivamente
precisar de persistência offline, quando o padrão de leitura concreto dela for conhecido.

**Decisão de DI — registro adiado.** Nenhuma classe nova (`AggregationRepositoryImpl`,
`AggregationSnapshotMapper`, `FirestoreAggregationDataSource`) está anotada com `@LazySingleton`/
`@injectable` nem registrada em `lib/app/injection.config.dart`. Não existe ainda nenhum consumidor de
apresentação (`presentation/`) para este repositório — a primeira tela de dashboard (TASK-134) é quem
deve registrar e rodar `build_runner` então, quando houver de fato uma aresta real no grafo de DI a
justificar. Isso evita tocar em código gerado de DI de todo o projeto (`build_runner build`, que
processa o repositório inteiro) sem nenhum consumidor a validar a mudança nesta task.

## Testes

### Cloud Functions (`npm test` em `functions/`)

- `test/aggregations/aggregation-builders.test.ts` — lógica pura de cada dimensão: agregação
  correta, exclusão de pedidos `rejected`/`cancelled`, isolamento por empresa/organização, período
  vazio, fan-out por produto sem alocar desconto do pedido, idempotência do builder puro. **25
  testes, todos passando sem emulador.**
- `test/aggregations/recompute-sales-daily-on-order-write.test.ts` — `resolveAffectedSalesDay`
  (create/update/delete) e `recomputeSalesDailyForOrderChange` com um `AggregationDataSource` fake em
  memória (mesmo padrão de `InMemoryStockAlertPersistence`): recompute correto, idempotência,
  auto-cura ao surgir um segundo pedido no mesmo dia, isolamento multi-tenant, dia sem pedidos não
  grava nada.
- `test/aggregations/recompute-monthly-aggregates.test.ts` — `recomputeMonthlyAggregatesForCompany`
  e `recomputeMonthlyAggregatesScheduledHandler` (este via `jest.mock` do factory de datasource, para
  exercitar o loop de "toda organização/empresa ativa, mês atual + anterior" sem Firestore real):
  geração correta das quatro dimensões mensais, idempotência, período vazio, isolamento multi-tenant,
  isolamento por job (uma empresa falhando não trava as demais).
- `test/aggregations/recompute-monthly-aggregates.emulator.test.ts` — mesmo formato de
  `functions/test/inventory/recompute-stock-turnover-metrics.test.ts` (TASK-094): callable real contra
  o Firebase Emulator Suite (idempotência, isolamento multi-tenant, período vazio, RBAC). **Falhou
  neste ambiente de execução** pela mesma limitação pré-existente já documentada em TASK-094: sem Java
  instalado, `firebase emulators:exec` aborta com `Could not spawn `java -version``. Confirmado que
  esse é o mesmo padrão de falha de todo teste de emulador já existente no repositório (rodei
  `npm test` completo em `functions/`: 17 suites falham exatamente da mesma forma, incluindo
  `create-organization.test.ts`, de uma task já mesclada — não é uma regressão desta task). Deve ser
  executado em CI/ambiente com o Firebase Emulator Suite disponível antes do deploy.

Comando executado com sucesso (sem emulador): `npx jest aggregations` (excluindo o arquivo
`.emulator.test.ts` manualmente ao interpretar o resultado) → **25/25 passando**. `npm run build` e
`npm run lint` (functions) passam sem erro.

### Firestore Security Rules

`firestore-tests/firestore.rules.test.js` ganhou o describe `organizations/{organizationId}/
salesDailyAggregates/{aggregateId} (TASK-133)` — representativo das cinco coleções (todas com a
mesma regra): OWNER/SALES_MANAGER com `report.viewSensitive` leem a própria organização; SALES_REP
sem a capability não lê nem lista; nenhum papel lê a Org B (cross-tenant); nenhum papel escreve/
atualiza/exclui pelo client. Também **não executável neste ambiente** (mesma falta de Java —
confirmado rodando `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`,
que aborta com o mesmo erro).

### App Flutter

- `test/features/dashboards/domain/aggregation_snapshot_dto_test.dart` — parsing do DTO (payload
  válido, campo obrigatório ausente lança `ValidationException`, campos numéricos ausentes default
  para zero) + mapper DTO→entidade.
- `test/features/dashboards/data/repositories/aggregation_repository_impl_test.dart` — cache fresco
  evita nova busca remota; TTL expirado força novo fetch; snapshot inexistente devolve
  `AppSuccess(null)` (nunca falha); falha remota mapeada para `AppFailure` sem lançar exceção;
  `listByPeriod` mapeia e cacheia por chave própria.

Comando executado: `flutter test test/features/dashboards/` → **9/9 passando**. `flutter test`
completo do projeto → **2534/2534 passando** (nenhuma regressão). `flutter analyze` (projeto inteiro)
→ nenhum problema. `dart format --set-exit-if-changed lib functions` → nenhum arquivo alterado.

## Critérios de aceite (checagem)

- Todas as métricas necessárias às TASK-134 a TASK-143 têm snapshot definido/documentado: as cinco
  dimensões cobrem faturamento por dia/empresa (`salesDaily`), por cliente (`customerMonthly`), por
  produto/categoria/coleção (`productMonthly`, com `categoryId`/`collectionId`/`collectionName`
  denormalizados em `labels`), por vendedor (`sellerMonthly`) e por região (`regionMonthly`).
  Dashboards que precisarem de estoque/giro reaproveitam `stockTurnoverMetrics` (TASK-094, já
  existente); dashboards de funil/metas reaproveitam as entidades já existentes de CRM/`targets`
  (fora do escopo de agregação de faturamento desta task) — cabe à task de cada dashboard específico
  decidir se algum desses precisa de uma agregação adicional própria.
- Nenhuma consulta de dashboard varre coleções brutas: `AggregationRepository` só expõe leitura das
  cinco coleções pré-computadas.
- Estratégia near-real-time vs. batch documentada explicitamente por métrica (ver seção acima e
  comentários em `recompute-sales-daily-on-order-write.ts`/`recompute-monthly-aggregates.ts`).
- Testes de idempotência e isolamento multi-tenant aprovados **sem emulador** (25 testes com fakes em
  memória); os mesmos cenários também têm testes de Emulator Suite reais escritos (Cloud Functions e
  Security Rules), não executáveis neste ambiente sandbox por falta de Java — mesma limitação
  pré-existente já aceita pelo restante do repositório.

## Arquivos criados/alterados

- `functions/src/aggregations/aggregation-shared.ts` (novo)
- `functions/src/aggregations/aggregation-builders.ts` (novo)
- `functions/src/aggregations/aggregation-data-source.ts` (novo)
- `functions/src/aggregations/recompute-sales-daily-on-order-write.ts` (novo)
- `functions/src/aggregations/recompute-monthly-aggregates.ts` (novo)
- `functions/src/aggregations/index.ts` (novo)
- `functions/src/index.ts` (alterado — exporta as três novas funções)
- `functions/test/aggregations/*.ts` (novo — 4 arquivos de teste + fake de datasource)
- `firestore.rules` (alterado — 5 blocos `match` novos)
- `firestore.indexes.json` (alterado — 5 índices compostos novos)
- `firestore-tests/firestore.rules.test.js` (alterado — describe novo de `salesDailyAggregates`)
- `lib/features/dashboards/**` (novo — domain + data, sem presentation)
- `test/features/dashboards/**` (novo)

## Pendências e riscos

- **Não implementado nesta task:** população das dez coleções `insight*Snapshots` do EPIC-16 (ver
  seção "Decisão de escopo" acima) — recomenda-se abrir uma task dedicada por regra (ou um EPIC-16.1)
  ao invés de tentar uma solução genérica única.
- Testes de Firebase Emulator Suite (Cloud Functions e Security Rules) não puderam ser executados
  neste ambiente por falta de Java — devem rodar em CI/ambiente com o Emulator Suite disponível antes
  de qualquer deploy real.
- `AggregationRepositoryImpl`/`AggregationSnapshotMapper`/`FirestoreAggregationDataSource` ainda não
  estão registrados no container de DI (`build_runner`) — a primeira task de dashboard que consumir
  este repositório deve adicionar as anotações `@LazySingleton`/`@injectable` e regenerar
  `injection.config.dart`.
- `productMonthly` não aloca desconto/acréscimo/frete do pedido por item (documentado em código e
  neste arquivo) — se uma task futura passar a persistir desconto por item em `OrderItem`, os
  agregadores de produto devem ser revisitados.
- `region` é derivado exclusivamente de `deliveryAddress.state` do pedido (não há campo de região
  dedicado no domínio hoje); pedidos sem esse campo preenchido corretamente caem em `'UNKNOWN'`.
