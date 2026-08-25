# TASK-078 — Concluída (2026-08-25)

## Resumo

Implementada a tela de detalhe de produto do catálogo premium (EPIC-10): galeria de fotos com
zoom (`photo_view`) sincronizada com a cor selecionada, seleção de cor (swatch do Design System),
grade de tamanhos com estoque por variante (`AppSizeGrid`, uma linha para a cor selecionada) e um
CTA "Adicionar ao pedido" sempre acessível durante a rolagem, em qualquer breakpoint (fixado como
`bottomNavigationBar` do `Scaffold`). Um novo `ProductDetailBloc` carrega produto, variantes, cores
e template de grade concorrentemente e resolve a disponibilidade em seguida, compondo um único
`ProductDetailState` consistente para toda a tela.

## Agentes utilizados

- `flutter-senior-architect` (domínio, use cases, BLoC, DI, testes).
- `flutter-ui-design-specialist` (composição da tela com componentes existentes do Design System,
  estados de loading/empty/erro, acessibilidade).

## Arquivos criados

- `lib/features/products/domain/usecases/list_product_variants_by_product_use_case.dart`
- `lib/features/products/domain/usecases/get_size_grid_template_by_id_use_case.dart`
- `lib/features/catalog/presentation/bloc/product_detail_event.dart`
- `lib/features/catalog/presentation/bloc/product_detail_state.dart`
- `lib/features/catalog/presentation/bloc/product_detail_bloc.dart`
- `lib/features/catalog/presentation/pages/product_detail_page.dart`
- `lib/features/catalog/presentation/widgets/product_detail_gallery.dart`
- `test/features/products/domain/usecases/list_product_variants_by_product_use_case_test.dart`
- `test/features/products/domain/usecases/get_size_grid_template_by_id_use_case_test.dart`
- `test/features/catalog/presentation/bloc/product_detail_bloc_test.dart`
- `test/features/catalog/presentation/pages/product_detail_page_test.dart`

## Arquivos alterados

- `lib/features/products/products.dart` — exporta os dois novos use cases.
- `lib/features/catalog/catalog.dart` — exporta bloc/event/state/page/widget novos.
- `lib/app/injection.config.dart` — regenerado por `build_runner` (registro DI dos dois novos use
  cases e do `ProductDetailBloc`).
- `docs/tasks/TASKS.md` — checkbox da TASK-078 marcado; `Progresso: 78 / 220`.

## Arquitetura utilizada

Clean/feature-first + BLoC, seguindo exatamente o padrão já estabelecido por `ProductGridBloc`
(TASK-077) e `CommercialSizeGridBloc` (TASK-073):

- `ProductDetailBloc` depende só de use cases (`GetProductByIdUseCase`,
  `ListProductVariantsByProductUseCase`, `ListProductColorsUseCase`,
  `GetSizeGridTemplateByIdUseCase`, `GetVariantAvailabilityUseCase`, `AnalyticsService`), nunca de
  repositório/Firestore diretamente.
- `ListProductVariantsByProductUseCase` e `GetSizeGridTemplateByIdUseCase` são novos porque não
  existia, até esta task, um caminho de leitura para "variantes de um produto" e "um size grid
  template por id" reaproveitável fora dos fluxos administrativos — ambos apenas delegam para
  contratos de repositório já existentes (`ProductVariantRepository.listByProduct`,
  `SizeGridTemplateRepository.getById`), sem duplicar regra alguma.
- `ProductDetailPage`/`ProductDetailGallery` são widgets puros de apresentação: reutilizam
  `AppColorSwatchSelector` e `AppSizeGrid` do Design System (`design_system/components/catalog/`)
  sem alterá-los, exatamente como a task pedia ("reutilizar... sem poluir a grade").
- Product, variantes, cores e template são buscados concorrentemente (cada `Future` inicia
  imediatamente ao ser criado; só o `await` é sequencial) — sem `Future.wait` heterogêneo, para
  manter um tipo de retorno testável por use case. A disponibilidade é buscada depois, pois depende
  dos ids de variante já carregados.

## Regras de negócio implementadas

- **Preço somente leitura, nunca calculado na tela**: não existe motor de precificação/tabela de
  preço (EPIC-11, TASK-083/084) ainda — a tela nunca fabrica um valor. `ProductDetailState.
  isPriceAvailable` é sempre `false` e a UI mostra o aviso explícito "Preço sob consulta com o time
  comercial" (nunca um campo vazio silencioso), exatamente o mesmo precedente documentado em
  `ProductGridPage` (TASK-077) para o grid.
- **Troca de cor sem estado inconsistente**: a grade de tamanhos é recalculada a partir de
  `state.variantForCell(colorId: selectedColorId, sizeId: ...)` a cada mudança de cor — não existe
  "tamanho selecionado" residual que possa apontar para uma variante inexistente na nova cor.
  Quantidades já digitadas ficam indexadas por `variantId` (cor+tamanho), então nunca se perdem nem
  vazam entre cores.
- **Preservação de quantidades digitadas**: `quantitiesByVariantId` é estado do bloc, não da UI —
  sobrevive a rebuilds, troca de cor e (dentro da sessão do bloc) a uma queda de conexão durante a
  digitação, coberto por teste de bloc dedicado.
- **Falha parcial de disponibilidade nunca gera confiança falsa**: se
  `GetVariantAvailabilityUseCase` falhar, a tela não trava nem finge "tudo pronta entrega" — usa
  `VariantAvailability.fromVariant` (derivação pura de dado já buscado no próprio
  `ProductVariant`, não um cálculo client-side de estoque) como fallback e liga
  `hasAvailabilityWarning`, que a UI mostra como aviso explícito ("Não foi possível confirmar a
  disponibilidade agora...").
- **Produto sem variante ativa tem tratamento visual explícito**: `AppEmptyState` "Grade
  indisponível" em vez de tela quebrada ou grid vazio silencioso; o CTA fica desabilitado (nada a
  adicionar).
- **Produto sem foto**: `ProductDetailGallery` mostra um placeholder explícito ("Sem imagem
  disponível") em vez de área em branco.
- **CTA sempre acessível**: implementado como `bottomNavigationBar` do `Scaffold`
  (`_AddToOrderBar`), o que o mantém fixo durante toda a rolagem em qualquer breakpoint sem
  necessidade de lógica de scroll customizada.
- **Nenhuma lógica de pedido duplicada**: o CTA dispara `ProductDetailAddToOrderRequested` (que
  só loga analytics) e chama `onAddToOrder` — um callback que o hospedeiro da página decide como
  tratar (igual ao padrão `onProductSelected` de `ProductGridPage`). Como EPIC-13 (Pedidos) ainda
  não existe no backlog, não há integração real ainda — documentado em Pendências.

## Regras Firebase implementadas

Nenhuma alteração de Firestore/Storage Rules ou Cloud Functions: a tela consome apenas contratos de
repositório já existentes (implementações locais `SharedPreferences*` hoje). Sem impacto de
segurança/backend nesta task.

## Analytics implementado

- `product_viewed` — logado uma vez por carregamento bem-sucedido, com `organization_id`,
  `product_id` e `source` (`origin` recebido: `grid`/`search`/`favorites`/`share`), reaproveitando
  o evento já existente na taxonomia (`AnalyticsEvents.productViewed`).
- `product_added_to_order` — logado ao tocar o CTA com pelo menos uma quantidade digitada, com
  `organization_id`, `product_id`, `items_count` (soma de todas as cores) e `colors_count`.
  Reaproveita o evento já existente na taxonomia (`AnalyticsEvents.productAddedToOrder`), sem criar
  duplicata.

## Crashlytics implementado

Nenhum ponto de captura de exceção novo foi necessário: toda falha de use case já retorna
`AppResult`/`Failure` tratado explicitamente pelo bloc (sem `try/catch` solto na UI).

## Impacto offline

Nenhuma mudança na camada offline/outbox: a tela é somente leitura sobre dados já sincronizados
localmente (repositórios `SharedPreferences*` atuais). O caso "estoque indisponível" (conexão caiu
durante a consulta de disponibilidade) é tratado com fallback explícito, coberto por teste de bloc.

## Impacto multi-tenant

`organizationId` é sempre resolvido pelo estado da tela (recebido via evento `ProductDetailStarted`,
nunca lido de um campo de formulário) e propagado para todo use case, no mesmo padrão de
`ProductGridBloc`/`CommercialSizeGridBloc`. Nenhuma alteração em regras de isolamento de tenant.

## Testes criados

- **Use case (`ListProductVariantsByProductUseCase`)**: lista só as variantes do produto pedido,
  produto sem variantes retorna lista vazia, `organizationId`/`productId` são aparados antes da
  consulta.
- **Use case (`GetSizeGridTemplateByIdUseCase`)**: retorna o template da organização, falha
  `NotFoundFailure` quando não existe, falha quando pertence a outra organização.
- **BLoC (`ProductDetailBloc`, via `bloc_test`)**: carregamento completo com seleção automática da
  primeira cor com variantes (+ `product_viewed` disparado uma vez com o `origin` correto); falha
  total quando o produto não carrega; falha parcial de disponibilidade (fallback +
  `hasAvailabilityWarning`); produto sem variantes ativas expõe `hasNoPurchasableVariants` e grade
  vazia; quantidades preservadas ao trocar de cor e voltar; quantidade ignorada para variante
  indisponível; `product_added_to_order` logado com o total certo; CTA sem quantidade digitada não
  loga nada.
- **Página (`ProductDetailPage`, widget test)**: placeholder de galeria sem foto, swatches de cor
  corretos, grade de tamanhos, aviso de preço sempre visível, CTA desabilitado sem quantidade;
  digitar quantidade habilita o CTA e, ao tocar, loga `product_added_to_order` e repassa as linhas
  via `onAddToOrder`; grade vazia explícita para produto sem variantes; estado de erro com retry
  funcional.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 1247 files (0 changed)` na execução final de verificação (arquivos novos/alterados já
haviam sido formatados em passos anteriores).

## Resultado do analyzer

`No issues found! (ran in 13.0s)`.

## Resultado dos testes

`flutter test` (suíte completa): `All tests passed!` — `+1640` (1640 testes, 0 falhas, sem `skip`)
— 18 testes novos em relação à baseline da TASK-077 (1622).

## Decisões técnicas

- **Sem preço nesta tela, por design**: não há EPIC-11 (Price List/motor de precificação)
  implementado ainda no backlog — `ProductDetailState.isPriceAvailable` é sempre `false` e a UI
  mostra um aviso explícito de "preço sob consulta", em vez de inventar um valor ou deixar um campo
  vazio. Mesma decisão documentada em `ProductGridPage` (TASK-077); ficará plugável quando
  TASK-083/084 existirem.
- **Grade de tamanhos como uma única linha (cor selecionada)**: diferente da `CommercialSizeGrid`
  administrativa (TASK-073), que mostra uma matriz cor×tamanho inteira para lançamento de pedido em
  lote, o detalhe de produto é uma experiência de "escolher uma cor, ver o estoque daquela cor" —
  por isso `AppSizeGrid` é usado com uma única `AppSizeGridRow` (a cor selecionada), reaproveitando
  o mesmo componente sem alterá-lo. Quantidades de outras cores continuam preservadas no estado
  (`quantitiesByVariantId`), só não aparecem visualmente até o vendedor voltar a selecionar aquela
  cor — comportamento intencional para não misturar cores na mesma grade visual.
- **Cores resolvidas mesmo com falha parcial**: `ProductDetailState.colorOptions` deriva a lista de
  cores a partir de `Product.colorIds` cruzado com as cores que efetivamente têm variante — nunca
  de uma leitura direta de `colors`. Se `ListProductColorsUseCase` falhar ou vier incompleto, uma
  cor referenciada por uma variante ainda aparece (com o id cru como rótulo) em vez de sumir
  silenciosamente; isso ativa `hasAvailabilityWarning`/`hasWarning` interno junto com a falha de
  disponibilidade, evitando um flag dedicado extra para cada fonte de degradação possível.
- **`Future` concorrente sem `Future.wait` heterogêneo**: como cada chamada de use case já inicia
  sua `Future` de forma eager ao ser invocada, `product`, `variants`, `colors` e `template` correm
  concorrentemente mesmo sendo `await`ados em sequência — evita a ginástica de tipos de
  `Future.wait<Object?>` misto e mantém cada resultado com seu tipo próprio, mais fácil de testar.
- **CTA como `bottomNavigationBar`**: satisfaz literalmente "permanece acessível durante toda a
  rolagem... em qualquer breakpoint" sem exigir lógica de scroll customizada (listener, `Sliver`
  pinned, etc.), consistente com o padrão Flutter idiomático para uma barra de ação fixa.
- **Nenhuma rota registrada em `AppRouter`**: mesmo precedente de `ProductGridPage`/
  `CatalogHomePage`/`ProductSearchPage` — nenhuma página de catálogo/produto está integrada ainda;
  fica para uma task de shell/navegação dedicada (mesma pendência já registrada nas conclusões de
  TASK-076/077).
- **Sem golden tests de tela inteira**: mesma decisão já registrada na conclusão da TASK-077 — os
  goldens do projeto hoje cobrem componentes isolados do Design System (`AppColorSwatchSelector`,
  `AppSizeGrid`, `AppProductGrid`), não telas inteiras; a cobertura de estados desta tela foi feita
  via widget test (assserts de texto/widget), não golden de pixel.
- **Sem `flutter test integration_test`**: o fluxo "abrir produto → trocar cor → preencher grade →
  adicionar ao pedido" está coberto ponta a ponta pelo bloc test de preservação de quantidade +
  pelo widget test de CTA, mas não como teste de integração de app completo (exigiria um shell de
  navegação real, que ainda não existe — ver pendência de `AppRouter` acima).

## Riscos conhecidos

- Preço ausente até EPIC-11 existir — comportamento intencional, não lacuna de implementação.
- `ProductDetailPage` não está registrada no `AppRouter`, mesmo padrão das páginas de catálogo já
  concluídas; precisa de uma task de navegação para ficar acessível fim a fim no app.
- "Adicionar ao pedido" não integra com um rascunho de pedido real: EPIC-13 (Pedidos) ainda não
  existe no backlog. `onAddToOrder` é o ponto de extensão pronto para quando essa integração for
  implementada.
- `ListProductColorsUseCase` busca todas as cores da organização e filtra no bloc por
  `product.colorIds` — aceitável hoje (mesmo padrão já usado por `CommercialSizeGridBloc`/
  `ProductColorPaletteBloc`) mas pode exigir uma consulta mais direcionada (`getByIds`) se o catálogo
  de cores da organização crescer muito.

## Pendências

- Plugar preço real por variante quando TASK-084 existir, em `ProductDetailState`/
  `_ProductDetailContent`, sem alterar o Design System.
- Ligar `ProductDetailPage.onAddToOrder` a um caso de uso real de "adicionar item ao rascunho de
  pedido" quando EPIC-13 existir.
- Integração de `ProductDetailPage` ao `AppRouter` e aos pontos de entrada reais (grid — TASK-077,
  busca, favoritos — TASK-079, compartilhamento — TASK-081).
- Golden tests de tela inteira e teste de integração ponta a ponta (`integration_test`) podem ser
  adicionados quando a suíte de goldens/integration do projeto crescer para cobrir telas completas.

## Evidências

- `flutter test` completo: 1640 testes, 0 falhas.
- `flutter analyze`: nenhum problema encontrado.
- `dart format --set-exit-if-changed .`: nenhum arquivo alterado.

## Commit

Único commit local com implementação + documentação + atualização do backlog.

## Push

Não realizado — não autorizado nesta rodada.

## Hash do commit

Ver `git log -1` após o commit desta task.

## Branch

main
