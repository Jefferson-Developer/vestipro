# TASK-024 — Concluída (2026-08-22)

## Resumo

Criados os quatro componentes de catálogo/venda por grade do Design System exigidos pela task, em
`lib/core/design_system/components/catalog/`: grid de produtos (`AppProductGrid`), grade de
tamanhos com entrada rápida de quantidade (`AppSizeGrid`), seletor de cor/swatch
(`AppColorSwatchSelector`) e stepper de quantidade reutilizável (`AppQuantityStepper`). Todos
consomem exclusivamente tokens de `design_system/foundations/`, são totalmente controlados pelo
chamador (nenhum calcula preço/desconto/disponibilidade real) e tratam explicitamente
loading/empty/error/disponibilidade sem depender só de cor.

## Agentes utilizados

- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/design_system/components/catalog/app_product_grid.dart`
- `lib/core/design_system/components/catalog/app_size_grid.dart`
- `lib/core/design_system/components/catalog/app_color_swatch_selector.dart`
- `lib/core/design_system/components/catalog/app_quantity_stepper.dart`
- `test/core/design_system/components/catalog/app_product_grid_test.dart`
- `test/core/design_system/components/catalog/app_size_grid_test.dart`
- `test/core/design_system/components/catalog/app_color_swatch_selector_test.dart`
- `test/core/design_system/components/catalog/app_quantity_stepper_test.dart`
- `test/core/design_system/components/goldens/design_system_catalog_golden_test.dart`
- `test/core/design_system/components/goldens/app_product_grid_mobile.png` (+ `_tablet`, `_desktop`)
- `test/core/design_system/components/goldens/app_size_grid_mobile.png` (+ `_tablet`, `_desktop`)
- `test/core/design_system/components/goldens/app_color_swatch_selector_mobile.png` (+ `_tablet`,
  `_desktop`)
- `docs/tasks/TASK-024-criar-componentes-de-catalogo-CONCLUIDA.md`

## Arquivos alterados

- `lib/core/design_system/components/components.dart` — exporta os 4 novos componentes de catálogo.
- `docs/tasks/TASKS.md` — marca TASK-024 como concluída e atualiza o progresso para 24/220.

## Arquitetura utilizada

Clean/feature-first + Design System puro (widgets `StatelessWidget`/`StatefulWidget` sem acesso a
Firestore/Storage/Drift/BLoC). Todos os quatro componentes são "fully controlled": o estado
(produtos, células da grade, cor selecionada, quantidade) sempre vem do chamador via parâmetros, e
cada componente só emite eventos (`onProductTap`, `onQuantityChanged`, `onSelected`, `onChanged`) —
nunca decide regra de negócio.

- `AppProductGrid`: `GridView.builder` com `SliverGridDelegateWithFixedCrossAxisCount` responsivo
  (2/3/4/5 colunas via `AppBreakpoints`), card com `AspectRatio(3/4)` fixo para a imagem (evita
  layout shift) usando `CachedNetworkImage` com skeleton/fallback, e footer `AppPagination` em modo
  "carregar mais" para lazy load. Estados `idle/loading/empty/error` mirrorando `AppDataTable`.
- `AppSizeGrid`: matriz cor × tamanho com rótulos de linha fixos à esquerda, colunas de tamanho
  roláveis horizontalmente e coluna de total por linha fixa à direita; cada célula é um
  `StatefulWidget` (`_AppSizeGridCellField`) com `TextEditingController`/`FocusNode` próprios,
  mantendo o texto digitado mesmo que o widget pai seja reconstruído por um evento não relacionado
  (ex.: banner de conectividade) enquanto o campo estiver focado. Navegação entre células via
  `onEditingComplete` + `FocusScope.of(context).nextFocus()` (deliberadamente não usa `onSubmitted`
  para isso, pois o comportamento padrão de "unfocus" do `TextField` para
  `TextInputAction.next`/`done` desfaria a navegação — ver comentário no código).
- `AppColorSwatchSelector`: `Wrap` de swatches circulares; cada opção carrega
  `previewImageUrl`/`availability` para que o chamador atualize sua própria galeria/disponibilidade
  ao reagir ao callback — o componente nunca renderiza galeria.
- `AppQuantityStepper`: `AppIconButton` (+/-) reaproveitados + campo numérico central, com
  clamping em `[minQuantity, maxQuantity]` e reconciliação do texto digitado apenas quando o campo
  perde o foco (nunca durante a digitação).

## Regras de negócio implementadas

Nenhuma. Por design, os quatro componentes não calculam preço, desconto, total de pedido ou
disponibilidade real — apenas exibem valores já decididos pela camada de domínio e emitem eventos
de intenção do usuário (quantidade digitada, cor selecionada, produto tocado, "carregar mais").

## Regras Firebase implementadas

Nenhuma (componentes de UI puros, sem acesso a Firestore/Storage/Functions).

## Analytics implementado

Nenhum (fora do escopo desta task; instrumentação de analytics é responsabilidade da tela/feature
que compõe estes componentes).

## Crashlytics implementado

Nenhum (idem acima).

## Impacto offline

Nenhuma alteração de comportamento offline. `AppSizeGrid` foi especificamente desenhado para nunca
perder um valor já digitado pelo usuário em caso de rebuild por instabilidade de conexão (ver teste
"preserves a typed value even if the widget rebuilds with stale data").

## Impacto multi-tenant

Nenhum — componentes de Design System não têm conhecimento de organização/tenant.

## Testes criados

- `app_product_grid_test.dart`: card com imagem/nome/preço, fallback sem imagem, truncamento de
  título longo, ausência de preço/estoque, skeleton de loading, empty state, error state com retry,
  integração com "carregar mais" (lazy load) e callback de tap.
- `app_size_grid_test.dart`: matriz preenchida com totais por linha/coluna/geral, emissão exata da
  quantidade digitada, avanço de foco entre células, preservação de valor digitado após rebuild com
  dados desatualizados, célula indisponível (texto/ícone, nunca só cor) e célula com estoque futuro.
- `app_color_swatch_selector_test.dart`: seleção reporta a opção completa (não só o id), um harness
  reproduz o padrão real de atualização de galeria pelo chamador, marcação de selecionado via
  Semantics, indisponibilidade comunicada por texto/ícone (nunca só cor) e bloqueio de seleção, e
  indicador de estoque futuro sem bloquear seleção.
- `app_quantity_stepper_test.dart`: incremento/decremento por `step`, bloqueio em `minQuantity`/
  `maxQuantity`, valor digitado diretamente com clamping em ambos os limites, e no-op quando
  desabilitado.
- `design_system_catalog_golden_test.dart`: goldens de `AppProductGrid`, `AppSizeGrid` e
  `AppColorSwatchSelector` em mobile (375), tablet (800) e desktop (1200).

## Comandos executados

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test --update-goldens test/core/design_system/components/goldens/design_system_catalog_golden_test.dart
```

## Resultado do formatter

Sucesso — `Formatted 244 files (0 changed) in 0.95 seconds.`

## Resultado do analyzer

Sucesso — `No issues found!` (analisado o projeto completo).

## Resultado dos testes

Sucesso — suíte completa: `390` testes, todos aprovados (`All tests passed!`), incluindo os 27
testes de widget novos (catálogo) e os 9 goldens novos (mobile/tablet/desktop).

## Decisões técnicas

- `AppProductGrid`/`AppSizeGrid` não implementam scroll próprio (assumem que serão compostos dentro
  de uma página já rolável), no mesmo contrato já documentado por `AppDataTable`.
- `AppSizeGrid` usa `onEditingComplete` (não `onSubmitted`) para avançar o foco entre células,
  porque o comportamento padrão de "unfocus" do Flutter para `TextInputAction.next`/`done` corria
  uma race condition com a chamada manual de `nextFocus()`, fazendo o foco voltar a `null` no fim
  do submit.
- Golden fixtures de `AppProductGrid` deliberadamente não usam `imageUrl` real: exercitar o caminho
  de rede/cache em disco do `CachedNetworkImage` (via `flutter_cache_manager`) exige canais de
  plataforma (`path_provider`) indisponíveis em `flutter test`; o estado de fallback sem foto já é,
  em si, um estado relevante para o golden.
- `childAspectRatio` do grid de produtos foi calibrado (`0.46`) com margem para o pior caso de
  conteúdo (nome em 2 linhas + marca + cores + preço "de/por" + disponibilidade), e as linhas de
  preço/disponibilidade usam `Flexible` + `ellipsis` para nunca estourar horizontalmente em cards
  estreitos (mobile, 2 colunas).

## Riscos conhecidos

- Os goldens de `AppProductGrid` cobrem apenas o estado sem foto (ver decisão técnica acima); o
  caminho real de carregamento de imagem de rede é validado apenas pelos testes de widget (com
  `network_image_mock`), não por golden.
- `AppSizeGrid` não fixa o cabeçalho de colunas durante o scroll horizontal (rótulos de linha e
  totais ficam fixos, mas o cabeçalho de tamanhos rola junto); suficiente para os critérios de
  aceite da task, mas pode ser refinado numa iteração futura de UX se necessário.

## Pendências

Nenhuma pendência conhecida para o escopo desta task.

## Evidências

- `flutter test` → `390` testes aprovados.
- `flutter analyze` → `No issues found!`.
- `dart format --set-exit-if-changed .` → `0 changed`.
- Goldens gerados em `test/core/design_system/components/goldens/app_product_grid_*.png`,
  `app_size_grid_*.png` e `app_color_swatch_selector_*.png` (mobile/tablet/desktop).

## Commit

Ver hash abaixo.

## Push

Autorizado nesta rodada — ver resultado no retorno final da task.

## Hash do commit

Ver retorno final da task (preenchido após `git commit`).

## Branch

`main`
