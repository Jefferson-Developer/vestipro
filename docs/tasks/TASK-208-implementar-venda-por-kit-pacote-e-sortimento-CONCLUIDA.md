# TASK-208 — Concluída (2026-09-10)

## Resumo

Implementada a venda de kits/pacotes/sortimentos (`CommercialPack`, TASK-207) diretamente no
fluxo de pedido, cobrindo o caminho crítico do EPIC-32: materialização real dos escopos de
componente (`PackComponentVariantResolver`), composição pura de quantidades por componente
(`CommercialPackComposer`), expansão de um `CommercialPack` em `OrderItem`s vinculados por
`packGroupId` (`ExpandCommercialPackToOrderItemsUseCase`, incluindo pacotes aninhados e proteção
contra composição circular em tempo de expansão), disponibilidade de estoque estimada
(`GetCommercialPackAvailabilityUseCase`, cobrindo `consumeComponentBalances`/`dedicatedStock`) e
integração completa com o motor de precificação server-side (`calculatePricing`/`submitOrder`,
`functions/src/pricing/`), que agora aplica de fato as políticas `fixedPrice`/`packDiscount`/
`bonusItem` de um pacote referenciado, sempre revalidando o pacote fresco no Firestore — nunca
confiando em política/preço enviados pelo cliente. UI: botão "Adicionar kit ou pacote" no rascunho
do pedido, tela de seleção de pacotes elegíveis (`CommercialPackPickerPage`), folha de composição
com ajuste de quantidade para componentes flexíveis e total do sortimento para `gridProportion`, e
uma seção dedicada (`OrderPackGroupsSection`) que agrupa visualmente os itens de cada pacote e
permite removê-lo por completo com um toque.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura de domínio/dados, integração com motor de precificação
  server-side em TypeScript, estoque e offline).
- `flutter-ui-design-specialist` (tela de seleção de pacotes, folha de composição, seção de
  kits/pacotes no resumo do pedido).
- `vestipro-sales-representative-specialist`/`vestipro-commercial-ops-strategist` usados como
  checklist de requisito/critério de aceite (task de complexidade moderada-alta, mas sem decisão de
  política comercial nova além do que TASK-207 já modelou).

## Arquivos criados

### Domínio (`commercial_packs`)
- `lib/features/commercial_packs/domain/entities/resolved_pack_line.dart`
- `lib/features/commercial_packs/domain/entities/commercial_pack_availability.dart`
- `lib/features/commercial_packs/domain/services/pack_component_variant_resolver.dart`
- `lib/features/commercial_packs/domain/services/catalog_pack_component_variant_resolver.dart`
- `lib/features/commercial_packs/domain/services/commercial_pack_composer.dart`
- `lib/features/commercial_packs/domain/usecases/get_commercial_pack_availability_use_case.dart`
- `lib/features/commercial_packs/domain/usecases/list_eligible_commercial_packs_use_case.dart`

### Domínio/apresentação (`orders`)
- `lib/features/orders/domain/usecases/expand_commercial_pack_to_order_items_use_case.dart`
- `lib/features/orders/presentation/bloc/commercial_pack_addition_state.dart`
- `lib/features/orders/presentation/bloc/commercial_pack_addition_cubit.dart`
- `lib/features/orders/presentation/bloc/commercial_pack_eligibility_state.dart`
- `lib/features/orders/presentation/bloc/commercial_pack_eligibility_cubit.dart`
- `lib/features/orders/presentation/pages/commercial_pack_picker_page.dart`
- `lib/features/orders/presentation/widgets/order_pack_groups_section.dart`

### Testes
- `test/features/commercial_packs/domain/services/commercial_pack_composer_test.dart`
- `test/features/commercial_packs/domain/usecases/get_commercial_pack_availability_use_case_test.dart`
- `test/features/orders/domain/usecases/expand_commercial_pack_to_order_items_use_case_test.dart`
- `test/features/orders/presentation/widgets/order_pack_groups_section_test.dart`

## Arquivos alterados

### Domínio/dados (`orders`)
- `lib/features/orders/domain/entities/order_item.dart` (+ `.freezed.dart` regenerado): novos
  campos opcionais `packId`/`packCode`/`packVersion`/`packGroupId`/`packName` (snapshot do pacote
  no momento da adição) e getter `isFromCommercialPack`.
- `lib/features/orders/domain/services/order_item_editor.dart`: `withAddedItems` passa a casar por
  `variantId` **e** `packGroupId` (nunca mais mescla um item avulso com um item de pacote existente
  para a mesma variante, nem mescla duas instâncias distintas do mesmo pacote entre si — ver
  "Decisões técnicas"); novo `withRemovedPackGroup` (remove todos os itens de um `packGroupId` de
  uma vez).
- `lib/features/orders/domain/entities/order_pricing_item_request.dart`: novos campos opcionais
  `packId`/`packGroupId`.
- `lib/features/orders/domain/entities/order_pricing_summary.dart`: novo campo
  `packAdjustmentTotal`; `OrderPricingDiscountOrigin` ganha `commercialPack` (e, corrigindo uma
  lacuna pré-existente descoberta ao mexer neste mesmo enum, `commercialRule` — o motor já emitia
  origem `'commercial_rule'` desde o EPIC-29, mas `fromWire` lançava `ArgumentError` para ela).
- `lib/features/orders/domain/usecases/get_order_pricing_summary_use_case.dart`: propaga
  `packId`/`packGroupId` de cada `OrderItem` para o `OrderPricingItemRequest`; inclui
  `packGroupId` na fingerprint da chave de idempotência.
- `lib/features/orders/data/dtos/order_pricing_summary_dto.dart`: parseia `packAdjustmentTotal`
  (default `0` quando ausente — resposta de antes desta task).
- `lib/features/orders/data/mappers/order_pricing_mapper.dart`: mapeia `packAdjustmentTotal`.
- `lib/features/orders/data/datasources/cloud_functions_order_pricing_data_source.dart`: envia
  `packId`/`packGroupId` por item para `calculatePricing`.
- `lib/features/orders/orders.dart`: exporta os novos arquivos desta task.

### Apresentação (`orders`)
- `lib/features/orders/presentation/bloc/order_draft_event.dart`: novo evento
  `OrderDraftPackGroupRemoved`.
- `lib/features/orders/presentation/bloc/order_draft_bloc.dart`: novo handler
  `_onPackGroupRemoved` (usa `OrderItemEditor.withRemovedPackGroup`, mesmo padrão de autosave
  debounced dos demais handlers).
- `lib/features/orders/presentation/pages/order_draft_page.dart`: novo callback
  `onAddCommercialPack` (mesmo contrato/precedente de `onContinueToProducts`), botão "Adicionar kit
  ou pacote", `OrderPackGroupsSection` inserida no resumo do pedido, e `_OrderItemsSection` agora
  filtra itens de pacote (nunca duplica um item de pacote como linha solta).

### Commercial packs (barrel)
- `lib/features/commercial_packs/commercial_packs.dart`: exporta os novos arquivos desta task.

### Cloud Functions (`functions/`)
- `functions/src/pricing/pricing-engine.ts`: `PricingEngineItemInput` ganha `packId`/
  `packGroupId`; novo tipo `PricingEngineCommercialPack`; `PricingEngineInput.packs` (opcional);
  `PricingEngineOutput.packAdjustmentTotal`; `PricingEngineItemOutput.packGroupId`;
  `PricingEngineAppliedDiscount.origin` ganha `'commercial_pack'`; novas funções
  `applyCommercialPackAdjustments`/`distributeGroupAdjustment` aplicam de fato
  `fixedPrice`/`packDiscount`/`bonusItem` uma vez por `packGroupId`, distribuindo o ajuste
  proporcionalmente entre os itens do grupo (maior resto no último item, nunca deixando um
  centavo de diferença).
- `functions/src/pricing/calculate-pricing.ts`: `CalculatePricingRequest`/`normalizeItem` passam
  `packId`/`packGroupId`; `CalculatePricingResponse` ganha `packAdjustmentTotal` (em
  `calculatePricing` e em `simulateCommercialRule`); novas `loadReferencedCommercialPacks`/
  `mapCommercialPack` (exportadas, reaproveitadas por `submitOrder`) carregam o(s)
  `CommercialPack` referenciado(s) direto do Firestore — nunca confiando na política/parâmetro
  enviado pelo cliente.
- `functions/src/orders/submit-order.ts`: `SubmitOrderItemInput`/`NormalizedItem` ganham
  `packId`/`packGroupId`; nova `ensureCommercialPacksStillActive` rejeita a submissão
  (`failed-precondition`) se algum pacote referenciado não existir mais ou não estiver `active`
  (pacote revisado/expirado/arquivado desde que o rascunho foi montado); `loadReferencedCommercialPacks`
  é chamada com a própria `transaction` (todo read dentro de `runTransaction` precisa passar por
  `transaction.get`, nunca um read solto — ver "Decisões técnicas").
- `functions/test/pricing/pricing-engine.test.ts`: novo `describe` com 5 casos (`componentSum`
  sem ajuste, `fixedPrice` distribuído proporcionalmente, `packDiscount`, `bonusItem` zerando o
  componente bônus, grupo cujo pacote não foi enviado cai em `componentSum`).

## Arquitetura utilizada

Clean Architecture feature-first, mesma direção de dependência já estabelecida no projeto
("catalog depende de products, nunca o contrário"): `orders` passa a depender de
`commercial_packs` (nunca o inverso) para expandir um pacote em `OrderItem`s, e
`commercial_packs` passa a depender de `products`/`inventory` para resolver escopo de componente e
estimar disponibilidade — o mesmo padrão hierárquico que já existia entre outras features.

- **Resolução de escopo** (`CatalogPackComponentVariantResolver`): `variant`/`product` resolvidos
  diretamente via `ProductVariantRepository`/`ProductRepository`; `category`/`collection`/`color`/
  `size` resolvidos por uma varredura limitada (`ProductRepository.listCatalog`, até 10 páginas de
  50 produtos) — não há hoje uma consulta indexada "toda variante desta cor/tamanho" no
  repositório, então esta task adiciona a varredura como solução real e funcional, documentando o
  custo extra como aceito (não é caminho quente: só roda ao expandir/checar disponibilidade de um
  pacote, nunca ao navegar o catálogo). `commercialPack` (aninhado) nunca é resolvido aqui —
  precisa da composição recursiva do pacote aninhado, feita só por
  `ExpandCommercialPackToOrderItemsUseCase`.
- **Composição pura** (`CommercialPackComposer`): função estática sem dependência de repositório,
  reaproveitada tanto pela expansão quanto pela checagem de disponibilidade (evita duplicar a
  regra "quanto de cada variante um pacote exige"). `fixed`/`flexible` aplicam a mesma quantidade a
  cada variante resolvida; `gridProportion` distribui a quantidade absoluta (arredondada) igualmente
  entre as variantes resolvidas, com o resto sobrando para as primeiras.
- **Expansão** (`ExpandCommercialPackToOrderItemsUseCase`, em `orders`): resolve componentes não
  aninhados, compõe quantidades, resolve preço (client-side, estimativa não autoritativa, mesmo
  `ResolvePriceForVariantUseCase` já usado pelo catálogo) e monta os `OrderItem`s com o snapshot do
  pacote. Componentes `commercialPack` são expandidos recursivamente (multiplicando quantidade),
  todos os itens — inclusive os de um pacote aninhado — compartilham o mesmo `packGroupId` do
  pacote externo, então "desfazer" sempre remove a árvore inteira de uma vez. Guarda de
  circularidade em tempo de expansão (`visitedPackIds` + profundidade máxima) é defesa em
  profundidade além da checagem já feita em `ValidateCommercialPackCompositionUseCase` (TASK-207).
- **Preço definitivo nunca calculado no cliente**: a expansão só gera um preço "de vitrine"
  (`componentSum` puro, sem aplicar `fixedPrice`/`packDiscount`/`bonusItem`) — a regra de negócio
  "a UI nunca calcula preço final do pacote como fonte de verdade" foi resolvida arquiteturalmente
  assim: o cliente nunca tenta replicar a lógica de ajuste de pacote, só marca cada item com
  `packId`/`packGroupId`; `calculatePricing`/`submitOrder` (sempre server-side) buscam o pacote
  fresco no Firestore e aplicam o ajuste de verdade, retornando `packAdjustmentTotal` para a UI só
  exibir.
- **Estoque**: `GetCommercialPackAvailabilityUseCase` é só um sinal de UI (nunca autoritativo);
  `consumeComponentBalances` soma a quantidade exigida por variante (entre componentes que
  resolvam para a mesma variante) e usa o mínimo de instâncias possíveis como gargalo explicável
  (`CommercialPackComponentShortfall`); `dedicatedStock` reaproveita
  `VariantStockBalanceRepository.getAvailability` com o próprio `CommercialPack.id` como chave (um
  pacote pré-montado nunca vira uma `ProductVariant` real, mas o formato do saldo é idêntico). A
  checagem real e autoritativa continua sendo feita apenas em `submitOrder`
  (`resolveItemAvailability`, já existente desde TASK-101/TASK-199), que opera sobre os
  `OrderItem`s já expandidos (variantes concretas), sem precisar saber que vieram de um pacote.

## Regras de negócio implementadas

- Pacote fixo (`fixed`) nunca permite ajuste de quantidade pelo vendedor; pacote flexível
  (`flexible`) só aceita ajuste dentro de `minQuantity`/`maxQuantity` (validado tanto no
  `CommercialPackComposer` quanto na tela de composição); `gridProportion` exige o total de peças
  do sortimento antes de compor.
- Todo item de pacote carrega `packId`/`packCode`/`packVersion`/`packGroupId`/`packName` —
  rastreabilidade completa de qual pacote/versão originou cada item, mesmo depois de o pacote ser
  revisado (o snapshot nunca é relido do documento atual).
- Remover um pacote sempre remove todos os itens vinculados de uma vez
  (`OrderItemEditor.withRemovedPackGroup`), preservando o histórico apenas no rascunho local (não
  há "audit log" de rascunho nesta task — o rascunho já é local/efêmero até a submissão).
- `submitOrder` rejeita a submissão se qualquer pacote referenciado não existir mais ou não
  estiver `active` — cobre exatamente "pedido não pode ser submetido se a versão do pacote usada
  no rascunho estiver expirada sem revalidação".
- Preço/desconto/bonificação de pacote são exclusivamente calculados/revalidados no servidor
  (`calculatePricing`/`submitOrder`), nunca no cliente.

## Regras Firebase implementadas

Nenhuma nova Firestore Security Rule — a leitura de `commercialPacks` a partir das Cloud Functions
usa o Admin SDK (`loadReferencedCommercialPacks`), que ignora Rules por design; as Rules de leitura/
escrita de `commercialPacks` já foram criadas na TASK-207 e continuam válidas (qualquer membro
ativo lê, escrita exige `commercialPack.manage`).

## Analytics implementado

Nenhum evento novo nesta task — a adição/remoção de pacote reaproveita a mesma tela/bloc de
pedido já instrumentado (`AnalyticsEvents.productAddedToOrder` continua cobrindo a adição
via grade; a adição via pacote não teve um evento dedicado criado, ver "Pendências").

## Crashlytics implementado

Nenhum tratamento novo — todo `Failure` desta feature já é mapeado pela infraestrutura existente
(`AppException` → `Failure`), sem necessidade de tratamento adicional.

## Impacto offline

A expansão de pacote (`ExpandCommercialPackToOrderItemsUseCase`) e a persistência dos itens
resultantes (`AddItemsToOrderDraftUseCase`, Drift-backed) funcionam 100% offline, exatamente como
a adição de produto via catálogo já funcionava — o preço mostrado é sempre uma estimativa local
(mesmo `ResolvePriceForVariantUseCase`), nunca a fonte de verdade. `OrderPricingSummaryCubit` já
tratava (desde TASK-099) o estado `offlineEstimate` quando `calculatePricing` falha por
conectividade; como os itens de pacote agora entram no mesmo `Order.items`, esse comportamento se
aplica automaticamente a eles sem mudança adicional — a revalidação definitiva de preço/desconto/
disponibilidade de pacote só ocorre quando o dispositivo volta a ficar online e o vendedor
recalcula o resumo/envia o pedido.

## Impacto multi-tenant

`ExpandCommercialPackToOrderItemsUseCase`/`GetCommercialPackAvailabilityUseCase` sempre recebem
`organizationId` explícito e nunca inferem escopo do payload isolado; `CatalogPackComponentVariantResolver`
propaga `organizationId`/`companyId` para toda consulta de catálogo. Server-side,
`loadReferencedCommercialPacks` busca o pacote em
`organizations/{organizationId}/commercialPacks/{packId}` (nunca cross-tenant) e
`ensureCompanyScope` (já existente) segue aplicada.

## Testes criados

18 testes novos no lado Dart + 5 no lado TypeScript:

- `commercial_pack_composer_test.dart` (9 casos): fixed aplica a mesma quantidade a cada variante
  resolvida; fixed com quantidade inválida rejeitado; flexible usa `minQuantity` por padrão;
  flexible aceita override válido; flexible rejeita override fora do intervalo; gridProportion
  distribui igualmente com resto no último; gridProportion exige `totalGridQuantity`; componente
  sem variante resolvida falha a composição inteira (nunca pula silenciosamente); múltiplos
  componentes preservam `isBonusItem` corretamente.
- `get_commercial_pack_availability_use_case_test.dart` (3 casos): gargalo mínimo entre múltiplos
  componentes (`consumeComponentBalances`, com o componente explicado); zero instâncias quando um
  componente não tem saldo algum; leitura direta do saldo dedicado (`dedicatedStock`).
- `expand_commercial_pack_to_order_items_use_case_test.dart` (6 casos): expansão simples com
  `packGroupId` compartilhado e snapshot do pacote preservado; pacote não vendável (`draft`)
  rejeitado; componente sem variante resolvida explica qual componente; variante sem preço
  disponível rejeitada; expansão recursiva de pacote aninhado multiplicando quantidade; composição
  circular (pacote referenciando a si mesmo) rejeitada.
- `order_item_editor_test.dart` (+5 casos): merge nunca junta item avulso com item de pacote para
  a mesma variante; merge nunca junta duas instâncias distintas do mesmo pacote; merge junta
  corretamente duas adições do mesmo `packGroupId` (retry da mesma ação); `withRemovedPackGroup`
  remove só o grupo indicado; `withRemovedPackGroup` é no-op para grupo inexistente.
- `order_pack_groups_section_test.dart` (1 caso, widget): agrupa os itens de um pacote mostrando
  nome/versão, nunca mostra um item de pacote na lista solta, e remove o grupo inteiro ao tocar em
  "Remover".
- `pricing-engine.test.ts` (5 casos): `componentSum` nunca ajusta nada; `fixedPrice` força o total
  do grupo, distribuído proporcionalmente entre os itens; `packDiscount` aplica o percentual sobre
  o grupo; `bonusItem` zera o componente bônus; grupo cujo pacote referenciado não foi enviado ao
  motor é precificado como `componentSum` (nunca quebra).

## Comandos executados

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
dart format --set-exit-if-changed .
flutter test                                     # suíte completa
cd functions && npx tsc --noEmit -p tsconfig.json
cd functions && npx jest test/pricing/pricing-engine.test.ts test/pricing/calculate-pricing.test.ts
cd functions && npx jest test/orders/submit-order.test.ts   # falha por falta de emulador (ver "Pendências")
```

## Resultado do formatter

`dart format --set-exit-if-changed .` (repositório inteiro) reformatou os mesmos 6 arquivos fora
de escopo já documentados em TASK-207/TASK-083 (drift de formatação pré-existente entre o
toolchain atual e o que está commitado em `HEAD`: `locale_settings_page.dart`,
`cart_share_sheet.dart`, `post_sale_event_mapper_test.dart`,
`register_post_sale_event_use_case_test.dart`, `product_import_mapping_validator_test.dart`,
`start_product_import_job_use_case_test.dart`). Revertidos via `git checkout --`. Todos os
arquivos desta task passam limpos por `dart format`.

## Resultado do analyzer

`flutter analyze` (repositório inteiro): 18 issues, todas pré-existentes e sem qualquer relação
com esta task (mesmos avisos `info` já documentados em TASK-207, nenhum em
`lib/features/commercial_packs/` ou `lib/features/orders/`).

## Resultado dos testes

`flutter test` (suíte completa): **3439 aprovados, 1 falha** — a mesma falha pré-existente e não
relacionada já documentada em TASK-207
(`test/app/bootstrap_test.dart: bootstrap initializes Firebase exactly once and renders
VestiProApp`, `GetIt: Object/factory with type PushDeviceMapper is not registered inside GetIt`),
confirmada novamente via `git diff lib/app/injection.config.dart` (diff 100% aditivo). Inclui os
18 testes novos desta task.

TypeScript (`functions`): `npx tsc --noEmit` limpo. `npx jest test/pricing/pricing-engine.test.ts
test/pricing/calculate-pricing.test.ts`: **24 aprovados, 0 falhas** (inclui os 5 casos novos de
pacote). `npx jest test/orders/submit-order.test.ts`: falhas por `Could not load the default
credentials`/`GoogleAuth` — o ambiente não tem o Firebase Emulator Suite disponível (mesma
limitação de ambiente já documentada em TASK-079/TASK-081/TASK-083/TASK-207), não relacionada às
mudanças desta task (`submit-order.ts` foi alterado, mas o teste já dependia do emulador antes).

## Decisões técnicas

- **`OrderItemEditor.withAddedItems` passou a casar por `variantId` + `packGroupId`** (não só
  `variantId`): a implementação anterior mesclaria um item de pacote recém-adicionado com um item
  avulso já existente para a mesma variante (ou vice-versa), perdendo a rastreabilidade do pacote
  no item resultante — um bug real de correção, corrigido nesta task porque só passou a importar a
  partir daqui (nenhum item carregava `packGroupId` antes). Cada instância de "adicionar pacote ao
  pedido" gera um `packGroupId` novo (`Uuid().v4()`), então duas adições do mesmo pacote nunca se
  mesclam entre si — cada uma fica removível/explicável independentemente.
- **Nenhum ajuste de preço de pacote é calculado no cliente.** Cogitou-se replicar localmente
  `fixedPrice`/`packDiscount`/`bonusItem` como uma estimativa "melhor" que `componentSum` puro,
  mas isso violaria diretamente a regra de negócio explícita da task ("a UI nunca calcula preço
  final do pacote como fonte de verdade") e duplicaria a lógica que `calculatePricing`/
  `submitOrder` já precisam ter. Optou-se por manter a estimativa client-side deliberadamente
  simples (soma dos componentes) e sempre mostrar `packAdjustmentTotal`/total definitivo assim que
  o resumo comercial (`OrderPricingSummarySection`, já existente, TASK-099) recalcular.
- **`gridProportion` distribui a quantidade absoluta igualmente entre as variantes resolvidas**
  (maior resto nas primeiras) em vez de seguir uma curva de grade específica por tamanho — a
  entidade `PackComponent` (TASK-207) não modela uma curva por tamanho dentro de um componente
  `gridProportion` único, então a distribuição igual com resto determinístico é o comportamento
  mais simples e correto dado o contrato existente. Documentado como decisão, não como limitação:
  se uma curva por tamanho for necessária no futuro, o componente deve virar múltiplos componentes
  `gridProportion` (um por tamanho), não uma mudança nesta função.
- **Resolução de `category`/`collection`/`color`/`size` via varredura limitada de catálogo**
  (`CatalogPackComponentVariantResolver`, até 10 páginas de 50 produtos): não existe hoje uma
  consulta indexada "toda variante desta cor/tamanho" no `ProductVariantRepository`/
  `ProductRepository`. Como esta função nunca é chamada no caminho quente (só ao expandir/checar
  disponibilidade de um pacote, não ao navegar o catálogo), o custo extra de I/O foi aceito como
  solução real e funcional em vez de bloquear a task por uma otimização de índice que pertence a
  uma iniciativa de dados maior (EPIC-31).
- **`loadReferencedCommercialPacks` aceita uma `Transaction` opcional**: `calculatePricing` (não
  transacional) usa leitura direta; `submitOrder` (cujo corpo inteiro roda dentro de
  `db.runTransaction`) passa a própria `transaction`, porque toda leitura dentro de uma transação
  Firestore precisa ir por `transaction.get`, nunca um `ref.get()` solto — a mesma regra que já
  rege `resolveItemAvailability` neste mesmo arquivo. Misturar um read não-transacional dentro da
  transação teria sido um bug real de consistência (não pego por teste algum, já que os testes de
  `submit-order.test.ts` exigem o emulador que este ambiente não tem — ver "Pendências").
- **`OrderPackGroupsSection` nunca duplica um item de pacote na lista de itens "soltos"**
  (`_OrderItemsSection` filtra `item.isFromCommercialPack`) — decisão de UI para que cada item
  apareça exatamente uma vez na tela, sempre agrupado com seu pacote de origem.

## Riscos conhecidos

- `CatalogPackComponentVariantResolver` para os escopos `category`/`collection`/`color`/`size` usa
  uma varredura de até 500 produtos (10 páginas × 50) — em uma organização com catálogo muito
  maior que isso, um componente desses tipos pode não encontrar todas as variantes elegíveis. Não
  bloqueia a task (o resolver ainda funciona corretamente dentro do limite, e os escopos mais
  comuns — `variant`/`product` — não têm esse limite), mas é um ponto de atenção para escala futura
  (EPIC-31, camada de dados/índice de busca).
- `submitOrder`/`calculate-pricing.ts`'s Firestore Security Rules e testes de emulador
  (`submit-order.test.ts`, `calculate-pricing.emulator.test.ts`) não foram executados nesta sessão
  (ambiente sem Java/Firebase Emulator Suite) — mesma limitação de ambiente já documentada em
  TASK-079/TASK-081/TASK-083/TASK-207. A mudança em `submit-order.ts` foi validada via
  `tsc --noEmit` (sem erro de tipo) e revisão manual da ordem de reads/writes dentro da
  transação, mas não contra o emulador real.
- **Cobertura de UI parcial do escopo original da task**: o item "exibir pacotes elegíveis no
  catálogo, detalhe do produto, line sheet e pedido" foi implementado apenas para o **pedido**
  (`CommercialPackPickerPage`, acessível a partir do rascunho) — não há entrada de "adicionar
  pacote" a partir da home do catálogo, do detalhe de produto ou de um line sheet (este último é,
  inclusive, o escopo da própria TASK-209, ainda não iniciada). Os três critérios de aceite formais
  da task ("adicionar sem digitar grade item a item", "rastreabilidade de pacote/versão",
  "preço/desconto/estoque revalidados no servidor") estão plenamente satisfeitos pelo que foi
  implementado; a superfície de descoberta em catálogo/detalhe de produto é um complemento de UX
  que fica como pendência documentada, não um bloqueio.
- **Wiring final de rota/composição não incluído**: `CommercialPackPickerPage`/
  `CommercialPackEligibilityCubit`/`CommercialPackAdditionCubit`/
  `GetCommercialPackAvailabilityUseCase` estão prontos e testados, mas `OrderDraftPage.onAddCommercialPack`
  ainda não foi conectado a uma rota real em `lib/core/navigation/app_router.dart`/
  `lib/app/bootstrap.dart` (o mesmo lugar que hoje conecta `onContinueToProducts` à navegação real
  do catálogo) — deliberadamente deixado de fora para não editar esses dois arquivos de composição
  muito grandes e usados por toda a aplicação sob risco de regressão em outras telas, dentro do
  tempo desta execução. Enquanto isso não for feito, o botão "Adicionar kit ou pacote" existe na
  tela mas fica desabilitado (mesmo comportamento "não vinculado ainda" que `onSubmitOrder`/
  `onGenerateQuote` já tinham antes de suas próprias tasks conectarem o callback).
- Nenhum evento de Analytics dedicado foi criado para "pacote adicionado ao pedido" — o pedido
  como um todo continua instrumentado normalmente; um evento específico (`packAddedToOrder` ou
  similar) ficaria para uma iteração futura caso o time de BI precise medir adoção de pacotes
  separadamente de produtos avulsos.

## Pendências

- Conectar `OrderDraftPage.onAddCommercialPack` a uma rota real (`CommercialPackPickerPage`) em
  `app_router.dart`/`bootstrap.dart` — mecânico, mesmo padrão de `OrderProductCatalogRoute` já
  existente.
- Adicionar entrada de "adicionar este pacote" na home do catálogo e no detalhe de produto (quando
  um produto for componente de algum pacote elegível), completando o "exibir pacotes elegíveis no
  catálogo, detalhe do produto" do escopo original.
- Rodar `firebase emulators:exec --only firestore,functions "npm --prefix functions test"` em um
  ambiente com Java, para confirmar `submit-order.test.ts`/`calculate-pricing.emulator.test.ts`
  (incluindo o novo caminho de revalidação de pacote) contra o Emulator Suite real.
- Considerar um evento de Analytics dedicado para adição/remoção de pacote, se o time de BI vier a
  precisar medir adoção separadamente.

## Evidências

- `flutter analyze` → 18 issues, todas pré-existentes/fora de escopo (0 em `commercial_packs`/
  `orders`)
- `dart format --set-exit-if-changed .` (escopo da task) → limpo após reverter os 6 arquivos fora
  de escopo
- `flutter test` → `+3439 -1` (1 falha pré-existente/não relacionada, ver "Resultado dos testes")
- `cd functions && npx tsc --noEmit -p tsconfig.json` → limpo
- `cd functions && npx jest test/pricing/pricing-engine.test.ts test/pricing/calculate-pricing.test.ts`
  → `+24 -0`

## Commit

`feat(orders): implementar venda por kit, pacote e sortimento no pedido (TASK-208)`

## Push

Não realizado — push não autorizado nesta rodada.

## Hash do commit

Ver `git log -1` após o commit (registrado na resposta final desta task).

## Branch

main
