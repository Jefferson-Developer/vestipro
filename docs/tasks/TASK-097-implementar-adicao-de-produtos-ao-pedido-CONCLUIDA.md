# TASK-097 — Concluída (2026-08-30)

## Resumo

Liga o catálogo (grid visual + detalhe de produto, TASK-077/078) ao pedido em rascunho (TASK-096):
o vendedor toca "Adicionar produtos" na tela do pedido, navega para uma nova tela de catálogo
escopada ao rascunho (com indicador "N produtos no pedido atual"), abre o detalhe de um produto,
escolhe cor/tamanho/quantidade (grade comercial já existente) e confirma — o item é persistido
localmente no rascunho via `AddItemsToOrderDraftUseCase`, e a lista de itens do pedido (com edição
de quantidade e remoção) e o subtotal recalculam em tempo real ao voltar. O evento de Analytics
`product_added_to_order` passou a carregar a origem (`source`: grid/busca/favoritos).

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/features/orders/domain/services/order_item_editor.dart`
- `lib/features/orders/domain/usecases/add_items_to_order_draft_use_case.dart`
- `lib/features/orders/presentation/bloc/order_items_counter_cubit.dart`
- `lib/features/orders/presentation/bloc/order_items_counter_state.dart`
- `lib/features/orders/presentation/bloc/order_product_addition_cubit.dart`
- `lib/features/orders/presentation/bloc/order_product_addition_state.dart`
- `lib/features/orders/presentation/pages/order_product_catalog_page.dart`
- `lib/features/orders/presentation/pages/order_product_addition_page.dart`
- `lib/features/orders/presentation/widgets/order_items_counter_indicator.dart`
- `test/features/orders/domain/services/order_item_editor_test.dart`
- `test/features/orders/domain/usecases/add_items_to_order_draft_use_case_test.dart`
- `test/features/orders/presentation/bloc/order_product_addition_cubit_test.dart`
- `test/features/orders/presentation/widgets/order_items_counter_indicator_test.dart`

## Arquivos alterados

- `lib/app/bootstrap.dart` — wire das duas novas rotas e do callback `onContinueToProducts`.
- `lib/app/injection.config.dart` — regenerado (`build_runner`) para os novos casos de uso/blocs
  `@injectable`.
- `lib/core/navigation/app_route_paths.dart` — `OrderProductCatalogRoute` e
  `OrderProductDetailRoute`.
- `lib/core/navigation/app_router.dart` — `GoRoute`s + builders para as duas rotas novas, ambas
  protegidas por `Capability.orderCreate`.
- `lib/features/catalog/presentation/bloc/product_detail_bloc.dart` — evento
  `product_added_to_order` agora carrega `source` (origem: grid/busca/favoritos).
- `lib/features/catalog/presentation/bloc/product_detail_state.dart` — `ProductDetailOrderLine`
  passa a carregar `unitPrice` (o preço já resolvido pela tabela vigente, nunca recalculado).
- `lib/features/orders/orders.dart` — exports dos novos arquivos.
- `lib/features/orders/presentation/bloc/order_draft_bloc.dart` — eventos
  `OrderDraftItemQuantityChanged`/`OrderDraftItemRemoved` (edição/remoção de item em memória +
  autosave) e resolução opcional (best-effort) do nome do produto para exibição.
- `lib/features/orders/presentation/bloc/order_draft_event.dart` — os dois eventos acima.
- `lib/features/orders/presentation/bloc/order_draft_state.dart` — cache `productsById` +
  `productNameFor`.
- `lib/features/orders/presentation/pages/order_draft_page.dart` — seção "Itens do pedido" (lista
  editável, subtotal em tempo real) e `onContinueToProducts` agora é `Future<void> Function(Order)`
  que recarrega o rascunho ao voltar do catálogo.
- `test/features/catalog/presentation/bloc/product_detail_bloc_test.dart` — asserção do novo
  parâmetro `source`.
- `test/features/catalog/presentation/pages/product_detail_page_test.dart` — assinatura do novo
  campo `unitPrice`.
- `test/features/orders/presentation/bloc/order_draft_bloc_test.dart` — novos casos de
  adição/atualização/remoção de item.

## Arquitetura utilizada

Clean/feature-first mantida: `AddItemsToOrderDraftUseCase` (domain) delega para
`OrderDraftRepository` (Drift, já existente) e usa `OrderItemEditor` (serviço de domínio puro, sem
Flutter/Firebase/Drift) para a regra de merge de itens — a mesma regra é reaproveitada pelo
`OrderDraftBloc` para editar quantidade/remover item em memória, e pelo caso de uso para a adição
vinda do catálogo (rota diferente, sem bloc compartilhado). A tela de catálogo escopada ao pedido
(`OrderProductCatalogPage`) reaproveita `CatalogFilterPage`/`ProductDetailPage` (TASK-077/078/082)
sem duplicar grid, grade comercial, disponibilidade ou resolução de preço — apenas compõe/agrega.
Navegação sempre via rotas tipadas (`OrderProductCatalogRoute`/`OrderProductDetailRoute`),
protegidas pelo mesmo guard de autorização (`order.create`) que já protege o rascunho.

## Regras de negócio implementadas

- O preço de cada `OrderItem` adicionado é sempre o já resolvido pelo motor de precificação
  (`ResolvePriceForVariantUseCase`, reaproveitado do fluxo existente do catálogo) no momento em que
  o vendedor viu e confirmou o preço — nunca recalculado/achatado depois.
- Mesclar uma variante já presente no pedido soma as quantidades e atualiza o preço unitário para o
  valor recém-resolvido (documentado em `OrderItemEditor`).
- Quantidade zero ou negativa remove o item (mesma convenção já usada na grade do
  `ProductDetailBloc`).
- Subtotal nunca fica negativo mesmo com desconto/acréscimo hipotético.
- Totais exibidos no pedido (`Order.itemsSubtotal`) são explicitamente rotulados como estimativa dos
  itens, não o total oficial (que fica para o resumo comercial da TASK-099).

## Regras Firebase implementadas

Nenhuma — toda a adição/edição/remoção de item do rascunho permanece 100% local (Drift), sem
nenhuma chamada Firestore/Storage nova.

## Analytics implementado

- `product_added_to_order` (já existente) passou a incluir `source` (origem: `grid`/`search`/
  `favorites`), no mesmo padrão já usado por `product_viewed`.

## Crashlytics implementado

Nenhuma mudança — falhas seguem passando pelos `Failure`/`AppResult` já tratados e exibidos (nunca
silenciosos), consistente com o restante do fluxo de pedido.

## Impacto offline

Toda a adição/edição/remoção de item continua 100% local: `AddItemsToOrderDraftUseCase` só lê/grava
no `OrderDraftRepository` (Drift), nunca a rede. O indicador "N produtos no pedido atual" recarrega
a partir do rascunho local a cada retorno da tela de detalhe.

## Impacto multi-tenant

Nenhuma mudança de modelo de dados; `organizationId`/`companyId` seguem exigidos e validados em
`AddItemsToOrderDraftUseCase`, e as novas rotas ficam sob o mesmo guard de autorização
(`order.create`) do rascunho já existente.

## Testes criados

- `order_item_editor_test.dart`: merge de itens, atualização/remoção de quantidade, subtotal nunca
  negativo.
- `add_items_to_order_draft_use_case_test.dart`: persiste produto+variante+preço corretos, mescla
  item existente, falha sem salvar quando o rascunho não existe, validações e propagação de falha
  de salvamento.
- `order_product_addition_cubit_test.dart`: sucesso/falha ao chamar o caso de uso.
- `order_items_counter_indicator_test.dart`: estado vazio (não renderiza nada) e estado com itens
  (mostra contagem e repassa o toque).
- `order_draft_bloc_test.dart`: novos casos para `OrderDraftItemQuantityChanged` (atualiza e
  remove ao zerar) e `OrderDraftItemRemoved`.
- `product_detail_bloc_test.dart`/`product_detail_page_test.dart`: novas asserções para `source` e
  `unitPrice`.

## Comandos executados

```bash
dart run build_runner build
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 1598 files (0 changed) in 3.33 seconds.` — exit code 0.

## Resultado do analyzer

`1 issue found.` — apenas um lint informativo (`prefer_initializing_formals`) em um arquivo de
teste; nenhum erro/warning.

## Resultado dos testes

`flutter test` completo: **2059 testes, todos passando** (`All tests passed!`).

## Decisões técnicas

- Navegação catálogo→pedido feita por rotas go_router dedicadas (`OrderProductCatalogRoute`/
  `OrderProductDetailRoute`), não por Navigator/rota ad hoc — cada uma persiste o item diretamente
  no Drift ao confirmar, e a tela do rascunho recarrega (`OrderDraftStarted`) ao voltar, evitando
  compartilhar instância de bloc entre rotas diferentes.
- Nome de produto exibido na lista de itens do rascunho é resolvido de forma otimista/opcional
  (`GetProductByIdUseCase` como dependência opcional do `OrderDraftBloc`, mesmo padrão de
  `ProductDetailBloc.resolvePriceForVariant`) — nunca bloqueia a tela se falhar.
- Exibição rica por variante (cor/tamanho) na lista de itens do rascunho foi deliberadamente
  deixada simples nesta task: a TASK-098 ("Implementar tela de grade no pedido") é quem entrega a
  grade comercial completa dentro do pedido.

## Riscos conhecidos

- A lista de itens do rascunho (`OrderDraftPage`) mostra apenas nome do produto + quantidade/preço/
  subtotal, sem detalhe de cor/tamanho por linha — piora de UX temporária até a TASK-098.
- `OrderItemEditor.withAddedItems` mescla por `variantId`; se o mesmo produto tiver múltiplas linhas
  para variantes distintas isso já funciona corretamente (uma linha por variante), mas não há dedupe
  alternativo por SKU/EAN.

## Pendências

- Nenhuma pendência bloqueante identificada para o escopo desta task.

## Evidências

- `flutter test` local: 2059/2059 passando.
- `flutter analyze`: 1 issue (info, não bloqueante).

## Commit

Commit único cobrindo toda a implementação (feature + testes).

## Push

Não realizado nesta rodada (proibido explicitamente pelo escopo da tarefa).

## Hash do commit

`b37fe49` — `feat(orders): implement adding products to order draft from catalog`

## Branch

`main`
