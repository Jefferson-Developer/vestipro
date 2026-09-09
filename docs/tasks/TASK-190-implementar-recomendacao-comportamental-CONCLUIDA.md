# TASK-190 — Concluída (2026-09-08)

## Resumo

Implementado o modelo de recomendação de produtos baseada em comportamento do EPIC-28: uma Cloud
Function agendada semanal (`calculateProductRecommendations`) que calcula co-ocorrência de itens
dentro do mesmo pedido ("market basket analysis") a partir de `Order` documents já persistidos
(`order_submitted`/`product_added_to_order`, seção 23 de `tasks.md`), gerando três tipos de
recomendação: `product` ("clientes que compraram X também compraram Y", para catálogo/detalhe de
produto), `customer` (personalizada por cliente, agregando a co-ocorrência de tudo que o cliente já
comprou — um item-based collaborative filtering explicável) e `segment` (mais vendidos da empresa,
usado como fallback e como prateleira genérica). Cliente novo/sem histórico sempre recebe um
documento com fallback claro para mais vendidos, ou um estado explícito de dado insuficiente — nunca
uma lista vazia sem explicação nem um número fabricado. Lado Flutter: feature nova
`lib/features/product_recommendations/` (Clean Architecture completa, somente leitura) com uma seção
reutilizável (`ProductRecommendationsSection`) integrada de fato no catálogo (`ProductDetailPage`,
seção "Comprado com frequência junto") e na tela do cliente (`CustomerDetailPage`, ação rápida
"Recomendações" que abre uma sheet), sempre exibindo a justificativa (`reasonLabel`) de cada
sugestão.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

Cloud Functions (`functions/src/recommendations/`):
- `recommendation-shared.ts` — motor puro: `buildBaskets`, `computeCoOccurrence`,
  `computeBestSellers`, `buildProductScopeRecommendation`, `buildCustomerScopeRecommendation`,
  `buildSegmentScopeRecommendation`, `productRecommendationDocumentId`. Documenta em comentário os
  sinais usados (co-ocorrência de itens em pedidos reais), por que `product_viewed` (Firebase
  Analytics) não é usado nesta v1, e a cadência de retraining (semanal).
- `recommendation-data-source.ts` — `ProductRecommendationPersistence` (porta) +
  `createFirestoreProductRecommendationDataSource` (adapter Firestore, compõe
  `AggregationDataSource` da TASK-133 para `loadOrderFacts`/`loadProductLabels`/
  `listActiveCompanyIds`/`listActiveOrganizationIds` — nunca duplica o parser de pedidos), mais
  `listActiveCustomers` (novo, lê `customers` da empresa já filtrando visibilidade de carteira).
- `calculate-product-recommendations.ts` — `calculateProductRecommendations` (`onSchedule`, semanal,
  segunda-feira 04:30 America/Sao_Paulo), mais
  `calculateProductRecommendationsForCompany`/`calculateProductRecommendationsScheduledHandler`
  (testáveis via `ProductRecommendationPersistence`, mesmo padrão "porta + adapter Firestore + fake
  em memória" de `calculate-demand-forecasts.ts`/TASK-185).
- `index.ts` (barrel do módulo).

Testes de Cloud Functions (`functions/test/recommendations/`):
- `recommendation-shared.test.ts` (puro, sem Firestore) — 14 testes.
- `calculate-product-recommendations.test.ts` (fake de persistência em memória, sem emulador) — 7
  testes.

Flutter (`lib/features/product_recommendations/`):
- `domain/value_objects/product_recommendation_scope_type.dart`,
  `domain/value_objects/product_recommendation_reason_code.dart`
- `domain/entities/product_recommendation.dart`, `domain/entities/product_recommendation_item.dart`
- `domain/repositories/product_recommendation_repository.dart`
- `domain/usecases/get_product_recommendations_use_case.dart`
- `data/dtos/product_recommendation_dto.dart`, `data/mappers/product_recommendation_mapper.dart`,
  `data/datasources/product_recommendation_data_source.dart`,
  `data/datasources/firestore_product_recommendation_data_source.dart`,
  `data/repositories/product_recommendation_repository_impl.dart`
- `presentation/bloc/product_recommendations_event.dart`,
  `presentation/bloc/product_recommendations_state.dart`,
  `presentation/bloc/product_recommendations_bloc.dart`
- `presentation/widgets/product_recommendations_section.dart`
- `product_recommendations.dart` (barrel)

Testes Flutter (`test/features/product_recommendations/`):
- `domain/value_objects/product_recommendation_scope_type_test.dart`,
  `domain/value_objects/product_recommendation_reason_code_test.dart`
- `domain/usecases/get_product_recommendations_use_case_test.dart`
- `data/dtos/product_recommendation_dto_test.dart`
- `data/mappers/product_recommendation_mapper_test.dart`

## Arquivos alterados

- `functions/src/index.ts` — exporta `calculateProductRecommendations`.
- `firestore.rules` — bloco `match` novo para `productRecommendations` (leitura de `product`/
  `segment` via `isActiveMember`; leitura de `customer` via a mesma regra de visibilidade de
  carteira de `customers`, reaproveitando `managerCanReadCustomer`/`isSalesRep`/`isOwnerOrAdmin`
  sobre campos denormalizados `primarySalesRepId`/`teamId`), escrita sempre `false` pelo client.
  **Corrigido também um bug pré-existente de sintaxe** em `canReadCustomer` (dois parênteses de
  fechamento faltando desde antes desta task — ver "Decisões técnicas" e "Riscos conhecidos"), sem o
  qual o arquivo inteiro não compilava.
- `firestore-tests/firestore.rules.test.js` — `describe` novo `productRecommendations` (positivo/
  negativo para `product`/`segment`/`customer` scope, isolamento multi-tenant, bloqueio de escrita
  client-side), mesmo padrão já usado para `demandForecasts`.
- `lib/core/analytics/analytics_events.dart` — evento novo `productRecommendationsViewed`.
- `test/core/analytics/analytics_events_test.dart` — lista de eventos esperados atualizada
  (incluindo, incidentalmente, dois eventos da TASK-189 — `reportExplanationGenerated`/
  `reportExplanationGenerationFailed` — que já existiam em `analytics_events.dart` mas nunca haviam
  sido adicionados a esta lista fixa; ver "Riscos conhecidos").
- `lib/app/bootstrap.dart` — `productDetailPageBuilder` passa `userId`/`createRecommendationsBloc`/
  `onRecommendationTap` (navega para outro `ProductDetailRoute`); `CustomerDetailPage(...)` passa
  `createProductRecommendationsBloc`.
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra as novas classes
  `@injectable`/`@lazySingleton`/`@LazySingleton`).
- `lib/features/catalog/presentation/pages/product_detail_page.dart` — parâmetros opcionais novos
  (`userId`, `createRecommendationsBloc`, `onRecommendationTap`) e seção "Comprado com frequência
  junto" (só renderiza quando os três estão disponíveis e o produto tem `companyId`) — todos os
  parâmetros novos são opcionais, nenhum outro chamador desta página (fluxo de pedido, testes)
  precisou mudar.
- `lib/features/customers/presentation/pages/customer_detail_page.dart` — parâmetro opcional novo
  `createProductRecommendationsBloc`, threaded por `_CustomerDetailBody`/`_CustomerDetailContent`/
  `_StackedCustomerDetail`/`_DesktopCustomerDetail`/`_CustomerHeader`/`_QuickActions` (mesmo padrão
  já usado por `createApproachSuggestionCubit`/TASK-187); novo botão "Recomendações" (só aparece
  quando o factory é fornecido) que abre `_showProductRecommendationsSheet`.

## Arquitetura utilizada

Feature-first + Clean Architecture, seguindo o mesmo padrão de `replenishment`/`demand_forecast`:
Presentation (`ProductRecommendationsSection` + `ProductRecommendationsBloc`) → Use case
(`GetProductRecommendationsUseCase`) → Repository contract (`ProductRecommendationRepository`) →
Repository impl (`ProductRecommendationRepositoryImpl`) → Datasource
(`FirestoreProductRecommendationDataSource`, leitura por `getById` no documento determinístico
`{companyId}_{scopeType}_{scopeId}` — nunca uma query com índice composto). Assim como
`DemandForecastRepository`, é **somente leitura** — não existe nenhuma ação do cliente sobre uma
recomendação, apenas consumo do que o job semanal já calculou.

O cálculo em si nunca duplica o parser de pedidos: `ProductRecommendationPersistence` compõe
literalmente `createFirestoreAggregationDataSource` (TASK-133) para `loadOrderFacts`/
`loadProductLabels`/`listActiveCompanyIds`/`listActiveOrganizationIds`, e computa o modelo de
co-ocorrência (baskets → pares de produtos → confiança) inteiramente em memória a partir de uma
única leitura de `DEFAULT_LOOKBACK_DAYS` (180) dias de pedidos por empresa.

## Regras de negócio implementadas

- Cálculo 100% server-side (`calculateProductRecommendations`, agendada semanalmente); o cliente
  (`ProductRecommendationRepositoryImpl`) apenas lê o resultado já persistido, nunca recalcula.
- **Escopo `product`** ("clientes que compraram X também compraram Y"): nunca cai para fallback de
  mais vendidos — um produto sem co-ocorrência real simplesmente não tem documento algum
  (`insufficientData: true` no cálculo → nenhuma escrita), evitando atribuir uma justificativa falsa
  a um produto nunca comprado junto com outro. A UI, ao não encontrar documento, mostra a seção como
  "sem recomendações por enquanto" — nunca esconde silenciosamente sem explicação.
- **Escopo `customer`** (personalizado): sempre gera um documento para **todo** cliente ativo da
  empresa (inclusive sem nenhum pedido) — personalizado quando há sinal (co-ocorrência dos produtos
  já comprados), com fallback explícito para mais vendidos (`fallbackApplied: true`) quando não há
  candidato pessoal, e com `insufficientData: true` (lista vazia, nunca inventada) apenas quando nem
  os mais vendidos da empresa existem ainda (`tasks.md`/TASK-190: "recomendação vazia ou baseada em
  mais vendidos gerais, nunca inventada").
- **Escopo `segment`**: um único documento por empresa (`company-best-sellers`) com os produtos mais
  vendidos, usado tanto como prateleira genérica quanto como fonte do fallback do escopo `customer`.
- Toda sugestão carrega `reasonCode`/`reasonLabel` — nunca uma lista sem justificativa (ex.:
  "Clientes que compraram Camiseta Básica também compraram Calça Jeans (2 de 5 pedido(s) com
  Camiseta Básica).").
- Isolamento por organização/empresa: `calculateProductRecommendationsForCompany` sempre recebe
  `organizationId`/`companyId` explícitos e nunca lê pedidos de outra combinação — testado
  explicitamente (`calculateProductRecommendationsScheduledHandler › never leaks one organization/
  company scope into another`).
- Reexecução para a mesma empresa é idempotente: o id do documento (determinístico, sem dimensão de
  tempo) sempre sobrescreve o mesmo documento, nunca duplica.
- Nenhum dado pessoal sensível é usado no cálculo — apenas `customerId`/`productId`/quantidades de
  pedidos já persistidos (conforme seção 23 de `tasks.md`).

## Regras Firebase implementadas

`firestore.rules`: coleção nova (`organizations/{organizationId}/productRecommendations/{docId}`).
`scopeType: 'product'`/`'segment'` (sem dado de cliente) são legíveis por qualquer membro ativo da
organização (`isActiveMember`, mesmo padrão de leitura de `products`); `scopeType: 'customer'` é
gated pela mesma regra de visibilidade de carteira já aplicada a `customers` (TASK-045/051):
`isOwnerOrAdmin` OU `SALES_MANAGER` da mesma equipe (`managerCanReadCustomer`) OU o `SALES_REP`
dono da carteira (`primarySalesRepId == request.auth.uid`) — reaproveitando essas funções já
existentes sobre os campos `primarySalesRepId`/`teamId` denormalizados no próprio documento de
recomendação no momento da geração (evitando um segundo `get()` do documento de cliente). Nenhuma
escrita client-side é permitida; só a Admin SDK (`calculateProductRecommendations`) escreve.

Nenhum índice composto novo foi necessário: `loadOrderFacts` reaproveita o índice já existente de
`orders` (TASK-133), e a leitura por escopo é sempre um `getById` no documento determinístico (nunca
uma query).

## Analytics implementado

Um evento novo em `lib/core/analytics/analytics_events.dart`:
- `productRecommendationsViewed` — logado por `GetProductRecommendationsUseCase` a cada consulta
  bem-sucedida (inclusive quando não há recomendação gerada ainda), com `organization_id`/
  `scope_type`/`scope_id`/`fallback_applied`/`insufficient_data` — nunca os nomes/ids dos produtos
  recomendados.

## Crashlytics implementado

Nenhum código novo de captura de exceção não tratada foi necessário — exceções de rede/servidor são
convertidas em `AppFailure`/`Failure` (mesmo padrão de `DemandForecastRepositoryImpl`) e nunca
escapam como exceção não tratada; o `CrashReporter` global já configurado em `bootstrap.dart`
continua cobrindo qualquer erro não previsto nesta feature.

## Impacto offline

Nenhum. Assim como `ReplenishmentSuggestionsPage`/`DemandForecastPage`, a recomendação de produtos é
um dado consultivo server-computado, consumido apenas quando online — não há Outbox nem cache Drift
para esta feature, deliberadamente (mesma decisão já documentada em TASK-184/185). A seção
simplesmente mostra o estado de carregamento/erro quando offline; nenhuma decisão comercial de campo
(pedido, preço, estoque) depende desta seção funcionar offline.

## Impacto multi-tenant

Toda leitura é escopada por `organizationId` via `FirestoreCollectionDataSource`
(`organizations/{organizationId}/productRecommendations`) e adicionalmente pelo `companyId`/
`scopeType`/`scopeId` embutidos no próprio id do documento — `firestore.rules` reforça o isolamento
por tenant independentemente do que o client pediu. No pipeline server-side,
`calculateProductRecommendationsForCompany` sempre recebe `organizationId`/`companyId` explícitos
por chamada (nunca inferidos de um contexto global), e o teste
`calculateProductRecommendationsScheduledHandler › never leaks one organization/company scope into
another` confirma que dois tenants com o mesmo `productId` nunca se misturam. Para o escopo
`customer`, o isolamento vai além do tenant: a regra de Firestore também restringe por carteira
(vendedor/equipe), igual à visibilidade do próprio `Customer`.

## Testes criados

TypeScript (`functions/`, **executados neste ambiente, sem emulador**):
- `recommendation-shared.test.ts` — 14 testes: baskets descartam pedidos não reconhecidos como
  receita e deduplicam itens; co-ocorrência simétrica e contagem de compras; mais vendidos
  (ranking/desempate/exclusão/limite); recomendação por produto (ranqueada por confiança, exclui
  pares abaixo do mínimo, `insufficientData` para produto nunca vendido); recomendação por cliente
  (personalizada excluindo já comprados, fallback para mais vendidos de cliente novo, nunca
  recomenda algo já comprado mesmo via fallback, `insufficientData` quando nem mais vendidos
  existem); segmento (mais vendidos como escopo próprio); id determinístico do documento.
- `calculate-product-recommendations.test.ts` — 7 testes com `ProductRecommendationPersistence` fake
  em memória: geração completa (segmento + produto + cliente) a partir de pedidos reais; nunca
  persiste documento de escopo `product` sem co-ocorrência qualificada; sempre escreve documento de
  escopo `customer` mesmo com zero pedidos na empresa; nunca gera recomendação para cliente sem
  campos de visibilidade de carteira; idempotência de reexecução; isolamento multi-tenant; execução
  continua quando uma empresa falha.

Dart (`test/features/product_recommendations/`, **executados neste ambiente**):
- `domain/value_objects/product_recommendation_scope_type_test.dart`,
  `domain/value_objects/product_recommendation_reason_code_test.dart` — round-trip de todo valor
  conhecido, `ArgumentError` para desconhecido.
- `domain/usecases/get_product_recommendations_use_case_test.dart` — sucesso sem checagem de RBAC
  para escopo `product`/`segment`; sucesso com RBAC (`customerView`) para escopo `customer`; RBAC
  negado (sem chamar repositório nem logar analytics); sucesso com recomendação nula (nunca gerada);
  validação de `scopeId` em branco sem chamar Membership.
- `data/dtos/product_recommendation_dto_test.dart` — payload válido, payload `insufficientData` com
  itens vazios, campo obrigatório ausente lança `ValidationException`, item malformado lança
  `ValidationException`, round-trip `toJson`→`fromJson`.
- `data/mappers/product_recommendation_mapper_test.dart` — mapeamento completo com itens e sem
  itens (`insufficientData`).

Não foram criados testes de widget para `ProductDetailPage`/`CustomerDetailPage` cobrindo
especificamente a nova seção/sheet de recomendações — os testes já existentes dessas páginas foram
executados e continuam passando inalterados (a integração é sempre opcional/aditiva), mas nenhum
novo teste widget cobre a seção em si (ver "Pendências").

## Comandos executados

```bash
cd functions && npx tsc --noEmit
cd functions && npx jest recommendations
cd functions && npx eslint src/recommendations test/recommendations
cd functions && npm run build
cd functions && npx jest
dart run build_runner build
flutter analyze lib/features/product_recommendations test/features/product_recommendations lib/core/analytics/analytics_events.dart
flutter test test/features/product_recommendations test/core/analytics/analytics_events_test.dart
flutter analyze lib/features/catalog/presentation/pages/product_detail_page.dart
flutter test test/features/catalog/presentation/pages/product_detail_page_test.dart
flutter analyze lib/features/customers/presentation/pages/customer_detail_page.dart
flutter test test/features/customers/presentation/pages/customer_detail_page_test.dart
flutter analyze lib/app/bootstrap.dart
flutter analyze
flutter test
dart format --set-exit-if-changed lib/features/product_recommendations test/features/product_recommendations lib/features/catalog/presentation/pages/product_detail_page.dart lib/features/customers/presentation/pages/customer_detail_page.dart lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart test/core/analytics/analytics_events_test.dart lib/app/injection.config.dart
npx firebase-tools deploy --only firestore:rules --dry-run
node -e "JSON.parse(require('fs').readFileSync('firestore.indexes.json','utf8'))"
```

## Resultado do formatter

`dart format --set-exit-if-changed` reformatou 9 arquivos recém-criados/editados na primeira
execução (quebras de linha automáticas em construtores/DTOs), sem mudanças de conteúdo; segunda
execução limpa (0 arquivos alterados) em todos os arquivos Dart tocados por esta task.

## Resultado do analyzer

`flutter analyze` (projeto inteiro): **18 issues, todas pré-existentes** (mesmo conjunto de
`use_null_aware_elements`/`deprecated_member_use` em arquivos não tocados por esta task, já
documentado nas conclusões de TASK-184/185 — a diferença de contagem, 17→18, vem apenas de arquivos
adicionados por tasks anteriores, TASK-189/`report_explanation`, nunca de código desta task).
**Nenhum erro, nenhuma issue nova.**

## Resultado dos testes

- `npx jest recommendations` (functions): **21/21 passando** (2 suites).
- `npx tsc --noEmit` / `npm run build` (functions): sem erros.
- `npx eslint src/recommendations test/recommendations`: sem erros/warnings.
- `npx jest` (functions, suíte completa): mesmo resultado de sempre, sem regressão nos módulos
  existentes (recomendação nova passando integralmente).
- `flutter test test/features/product_recommendations test/core/analytics/analytics_events_test.dart`:
  **17/17 passando.**
- `flutter test test/features/catalog/presentation/pages/product_detail_page_test.dart`: **5/5
  passando** (nenhuma regressão pela integração opcional).
- `flutter test test/features/customers/presentation/pages/customer_detail_page_test.dart`: **6/6
  passando** (nenhuma regressão pela integração opcional).
- `flutter test` (suíte completa do projeto): **3242/3243 passando** — a única falha
  (`test/app/bootstrap_test.dart`, "bootstrap initializes Firebase exactly once and renders
  VestiProApp") é **pré-existente e não relacionada a esta task**: confirmado rodando a mesma suíte
  via `git stash` sobre o `HEAD` original (antes de qualquer mudança desta task) — falha idêntica
  (`PushDeviceMapper is not registered inside GetIt`), reproduzível sem nenhuma das mudanças desta
  task (mesma falha já documentada nas conclusões de TASK-184/185).
- `npx firebase-tools deploy --only firestore:rules --dry-run`: **compilou com sucesso** após a
  correção do bug pré-existente em `canReadCustomer` (ver "Decisões técnicas"/"Riscos conhecidos") —
  confirma que o novo bloco `productRecommendations` e as novas funções auxiliares são sintaticamente
  válidos, e que o arquivo `firestore.rules` inteiro voltou a compilar.
- `node -e "JSON.parse(...)"` sobre `firestore.indexes.json` → `OK` (JSON válido, arquivo não
  alterado por esta task).

## Decisões técnicas

**(a) Sinal usado: co-ocorrência de itens dentro do mesmo pedido (`orders`), não
`product_viewed`.** O escopo técnico da task cita três sinais: "produtos vistos, adicionados ao
pedido, comprados por clientes semelhantes". `product_added_to_order`/`order_submitted` já são
dados de negócio persistidos em Firestore (`Order.items`, TASK-101) e reaproveitados diretamente
via `AggregationDataSource.loadOrderFacts` (TASK-133) — nenhuma duplicação de parser. `product_viewed`
já existe como evento (`AnalyticsEvents.productViewed`), mas é emitido apenas para o Firebase
Analytics (client SDK) e **não é persistido em nenhuma coleção Firestore consultável por uma Cloud
Function** — usá-lo exigiria primeiro linkar o projeto ao BigQuery e construir um pipeline de
exportação/streaming, uma decisão de infraestrutura de projeto (Firebase Console/GCP) fora do
alcance deste ambiente e desta task. Isso é documentado extensivamente no próprio código
(`recommendation-shared.ts`) para que uma v2 do modelo possa incorporar esse sinal quando essa
infraestrutura existir — sem fingir que ele já foi usado.

**(b) "Similaridade entre clientes" é feita via item-based collaborative filtering, explicável.** Em
vez de calcular clusters/segmentos de clientes (o que exigiria uma dimensão de segmentação própria
ainda não modelada de forma consistente para este fim), o escopo `customer` agrega a co-ocorrência
de **todos os produtos que o próprio cliente já comprou** contra o modelo de co-ocorrência global —
um clássico item-based CF. A explicação ("Você já comprou X; clientes com o mesmo perfil de compra
também levaram Y") é sempre visível, nunca uma caixa preta, e evita inventar uma noção de
"similaridade" sem lastro nos dados reais disponíveis hoje.

**(c) Escopo `product` nunca cai para fallback de mais vendidos.** Diferente do escopo `customer`
(onde o fallback é explicitamente pedido pela task para "cliente novo"), atribuir "clientes que
compraram X também compraram Y" a um produto Y que na verdade é só um mais-vendido genérico, sem
nenhuma coocorrência real com X, seria uma justificativa fabricada — violando diretamente
"nenhuma sugestão é inventada". Por isso, um produto sem coocorrência qualificada simplesmente não
tem documento `productRecommendations` (`insufficientData: true` → nada é persistido), e a UI trata
a ausência de documento como "sem recomendações por enquanto", nunca escondendo silenciosamente a
seção.

**(d) `customer` scope sempre gera documento para todo cliente ativo, mesmo sem nenhum pedido.**
Diferente de `product` (onde a ausência de coocorrência significa "sem documento"), o critério de
aceite da task para "cliente novo" exige explicitamente um fallback visível, nunca uma ausência
silenciosa — por isso o pipeline itera `listActiveCustomers` (nova, análoga ao "ler a coleção inteira
por empresa" já aceito em `recalculate-customer-scores.ts`) e sempre escreve um documento, com
`fallbackApplied`/`insufficientData` explícitos conforme o caso.

**(e) Documento determinístico sem dimensão de tempo (`{companyId}_{scopeType}_{scopeId}`), ao
contrário de `DemandForecast` (que inclui `anchorMonthKey`).** Uma recomendação de produto não tem
"períodos" — é sempre "a mais recente" para aquele escopo; reexecuções semanais simplesmente
sobrescrevem o mesmo documento (idempotente), nunca acumulam histórico. Isso também elimina a
necessidade de qualquer índice composto novo: a leitura é sempre um `getById` direto.

**(f) Integração real no catálogo (`ProductDetailPage`) e na tela do cliente
(`CustomerDetailPage`), não apenas uma feature isolada.** Diferente de TASK-184/185 (que deixaram a
integração de menu como pendência aceita), o critério de aceite desta task exige explicitamente que
a recomendação "apareça no catálogo/tela do cliente" — por isso a seção foi de fato embutida em
ambas as páginas, através de parâmetros **opcionais** (nunca quebrando um chamador existente):
`ProductDetailPage` ganha uma seção inline "Comprado com frequência junto" (escopo `product`,
sempre visível ao abrir o produto); `CustomerDetailPage` ganha uma ação rápida "Recomendações"
(mesmo padrão de sheet-sob-demanda já usado por "Sugerir abordagem"/TASK-187) que abre o escopo
`customer`. A escolha de sheet-sob-demanda em vez de seção sempre visível na tela do cliente evita
inflar ainda mais uma página já densa (múltiplas seções, dois layouts responsivos) e mantém o
padrão de interação já estabelecido para as demais features de IA/EPIC-28 nesta página.

**(g) Correção incidental de um bug pré-existente de sintaxe em `firestore.rules`.** Ao rodar
`npx firebase-tools deploy --only firestore:rules --dry-run` para validar o bloco novo desta task
(já que o Firebase Emulator Suite não está disponível neste ambiente), descobri que o arquivo
inteiro **já não compilava antes desta task** — `canReadCustomer` (TASK-045/051, não tocada nesta
task) tinha dois parênteses de fechamento faltando. Confirmei isso rodando o mesmo dry-run sobre o
`HEAD` original via `git stash` (mesmo erro, nas mesmas linhas). Corrigi apenas a estrutura de
parênteses (`);` → `));`), sem alterar nenhuma condição/operador — a intenção original é
inequívoca pela indentação existente — e confirmei que o arquivo inteiro volta a compilar com
sucesso, incluindo o bloco novo desta task. Não fiz nenhuma outra alteração de lógica de RBAC nesse
trecho; ver "Riscos conhecidos" para a recomendação de revisão dedicada.

## Riscos conhecidos

- **[Crítico, pré-existente, não introduzido por esta task]** Antes da correção descrita na decisão
  "(g)", `firestore.rules` **não compilava** (bug de sintaxe em `canReadCustomer`, dois parênteses de
  fechamento faltando) — ou seja, o arquivo de regras de segurança do projeto inteiro estava
  quebrado e não podia ser implantado (`firebase deploy --only firestore:rules` falharia), sem que
  nenhuma task anterior tivesse detectado isso (o Firebase Emulator Suite nunca esteve disponível
  neste ambiente para validar). A correção aplicada nesta task é puramente estrutural (parênteses),
  preservando a lógica original — ainda assim, recomendo fortemente que a equipe rode os testes de
  `firestore-tests/firestore.rules.test.js` (bloco `customers  (TASK-045 visibility contract)`) num
  ambiente com Java/Firebase Emulator Suite antes de qualquer deploy real, para confirmar
  comportamentalmente que `canReadCustomer` continua se comportando exatamente como antes.
- A camada de co-ocorrência lê até `DEFAULT_LOOKBACK_DAYS` (180) dias de pedidos por empresa em
  memória a cada execução semanal — para uma organização com um volume de pedidos muito grande, isso
  pode ficar lento; não há paginação/particionamento adicional hoje (mesmo tipo de trade-off já
  aceito por TASK-133/184/185).
- `listActiveCustomers` lê a coleção `customers` inteira da organização (filtrando `companyId`/
  `status`/`deletedAt` em memória, sem índice composto novo) — aceitável hoje (mesmo padrão de
  `recalculate-customer-scores.ts`), mas pode ficar lento para uma organização com uma base de
  clientes muito grande.
- `firestore-tests/firestore.rules.test.js` (novo `describe` para `productRecommendations`) não pôde
  ser executado neste ambiente por falta de Java (`firebase emulators:exec`) — mesma limitação
  pré-existente já aceita pelo restante do repositório (TASK-094/TASK-133/TASK-184/TASK-185). O
  `npx firebase-tools ... --dry-run` confirma apenas que o arquivo **compila**, não que o
  comportamento das regras está correto em runtime — deve rodar em CI/ambiente com o Firebase
  Emulator Suite antes de qualquer deploy real.
- Nenhum teste de widget cobre especificamente `ProductRecommendationsSection`/a nova seção em
  `ProductDetailPage`/a nova sheet em `CustomerDetailPage` — os testes existentes dessas páginas
  continuam passando (a integração é aditiva/opcional), mas o comportamento visual da seção em si
  (loading/erro/vazio/com itens) não tem cobertura de widget dedicada.
- O modelo v1 não usa `product_viewed` (ver decisão "a") — uma futura v2 mais completa exigiria
  linkar o projeto ao BigQuery/exportação de Analytics, decisão de infraestrutura fora do alcance
  desta task.

## Pendências

- Criar testes de widget para `ProductRecommendationsSection` (loading/erro/vazio/com itens/
  fallback) e para a integração em `ProductDetailPage`/`CustomerDetailPage` — não executado nesta
  rodada por priorização de tempo/risco (motor de cálculo + pipeline server-side + integração real
  em duas páginas já foi o volume priorizado).
- Rodar os testes de Firebase Emulator Suite (`firestore.rules.test.js`, incluindo o `describe` de
  `customers` já existente, para confirmar a correção do bug pré-existente) em um ambiente com Java/
  Emulator Suite disponível, antes de qualquer deploy real.
- Avaliar, quando a infraestrutura de BigQuery/exportação de Analytics existir, incorporar
  `product_viewed` como sinal adicional de uma v2 do modelo.
- Nenhum item de menu "central de IA/recomendações" existe hoje — a seção só aparece nos dois pontos
  de entrada natural (detalhe de produto, ação rápida do cliente) descritos nesta task.

## Evidências

- `cd functions && npx tsc --noEmit` → sem erros.
- `cd functions && npx jest recommendations` → `Test Suites: 2 passed, 2 total`, `Tests: 21 passed,
  21 total`.
- `cd functions && npx eslint src/recommendations test/recommendations` → sem erros/warnings.
- `cd functions && npm run build` → sem erros.
- `dart run build_runner build` → `injection.config.dart` regenerado, registrando
  `ProductRecommendationMapper`, `FirestoreProductRecommendationDataSource`,
  `ProductRecommendationRepositoryImpl`, `GetProductRecommendationsUseCase`,
  `ProductRecommendationsBloc` (confirmado via `grep ProductRecommendation
  lib/app/injection.config.dart`).
- `flutter test test/features/product_recommendations test/core/analytics/analytics_events_test.dart`
  → `+17: All tests passed!`.
- `flutter test test/features/catalog/.../product_detail_page_test.dart` → `+5: All tests passed!`.
- `flutter test test/features/customers/.../customer_detail_page_test.dart` → `+6: All tests
  passed!`.
- `flutter test` (suíte completa) → `+3242 -1`, única falha confirmada pré-existente via `git stash`.
- `flutter analyze` (projeto inteiro) → `18 issues found`, todas `info`, nenhuma nova, nenhum
  `error`.
- `npx firebase-tools deploy --only firestore:rules --dry-run` → antes da correção: erro de
  compilação em `canReadCustomer` (confirmado idêntico via `git stash` sobre o `HEAD` original);
  depois da correção: `+ cloud.firestore: rules file firestore.rules compiled successfully`.
- `node -e "JSON.parse(...)"` sobre `firestore.indexes.json` → `OK` (JSON válido).

## Commit

`feat(recommendations): implementa recomendacao de produtos baseada em comportamento (TASK-190)`

## Push

Não realizado nesta rodada — sem autorização explícita para push nesta conversa (conforme
`AGENTS.md`: "Nunca faça push sem autorização explícita nesta conversa").

## Hash do commit

`4c0ea7c3d074a3ed5067c174027600496a4e5124`

## Branch

`main`
