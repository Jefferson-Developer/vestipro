# Layouts responsivos

Camada de layout do Design System: `AppResponsiveBuilder`, `AppAdaptiveShell` e
`AppAdminPageLayout`. Importe sempre via `package:vestipro/core/design_system/design_system.dart`.

## Guia de breakpoints

Os quatro tiers vêm de `foundations/app_breakpoints.dart` e nunca devem ser reimplementados como
números soltos em uma tela:

| Tier          | Largura (>=) | Uso típico                                                              |
| ------------- | ------------ | ------------------------------------------------------------------------ |
| `mobile`      | 0            | Smartphone. Uma coluna, navegação por bottom navigation, ações empilhadas, bottom sheet para filtros/formulários secundários. |
| `tablet`      | 600          | Tablet/foldable pequeno. `NavigationRail` compacto, ainda uma coluna de conteúdo principal, mas com mais respiro (grades com mais colunas, listas em 2 colunas). |
| `desktop`     | 1024         | Laptop/monitor padrão e janela Web maximizada. Sidebar permanente, painel de filtros lateral fixo, tabelas em vez de cards. |
| `largeDesktop`| 1440         | Monitor wide. Mesma estrutura do `desktop`, com mais colunas/densidade de grade (ex.: `AppProductGrid` usa 5 colunas em vez de 4). |

Regras:

- Nunca leia `MediaQuery.of(context).size.width` (ou `.sizeOf`) diretamente para decidir um layout
  condicional. Use `AppResponsiveBuilder`, que resolve o breakpoint a partir da largura disponível
  do próprio widget (`LayoutBuilder` + `AppBreakpoints.resolve(constraints.maxWidth)`), igual ao que
  `AppDataTable`, `AppProductGrid` e `AppSizeGrid` já fazem.
- Use `context.breakpoint` (getter em `theme/design_system_context.dart`) apenas quando a decisão é
  genuinamente de nível de janela/tela inteira (ex.: `AppAdaptiveShell` escolhendo entre bottom
  navigation, rail ou sidebar) — nunca dentro de um widget que pode estar aninhado num painel mais
  estreito que a tela.
- Para um valor (não widget) que varia por tier, use `AppResponsiveValue<T>` em vez de uma cadeia de
  `breakpoint == AppBreakpoint.x ? a : b`.
- Sempre teste tamanhos intermediários (ex.: 700px, entre `tablet` e `desktop`) — o layout deve
  permanecer no tier resolvido sem quebra visual abrupta nem overflow horizontal da página inteira.

## `AppResponsiveBuilder`

Substitui todo `LayoutBuilder` ad hoc que resolve breakpoint manualmente:

```dart
AppResponsiveBuilder(
  builder: (context, breakpoint) => switch (breakpoint) {
    AppBreakpoint.mobile => const _MobileFilters(),
    _ => const _DesktopFilters(),
  },
)
```

## `AppAdaptiveShell`

Shell de navegação único, com o mesmo estado de rota ativa (`selectedIndex`/
`onDestinationSelected`) para as três apresentações:

- **Mobile**: `NavigationBar` com até `maxMobileDestinations` itens essenciais; o restante (mais
  `secondaryDestinations`) fica em um `AppBottomSheet` acionado pelo item "Mais".
- **Tablet**: `NavigationRail` compacto (`labelType: selected`), com todos os `destinations` e um
  botão "Mais" para `secondaryDestinations`.
- **Desktop/largeDesktop**: sidebar permanente, colapsável (ícone apenas) ou expandida (ícone +
  label), com `secondaryDestinations` listadas após um divisor.

O shell não decide RBAC — quem monta a lista de `destinations` (já filtrada por permissão) é a
camada de domínio/feature. O shell também não conhece `go_router`: `body` é o conteúdo já resolvido
pela rota ativa, e `onDestinationSelected` é o callback de navegação do chamador.

## `AppAdminPageLayout`

Esqueleto padrão de página administrativa (cabeçalho + conteúdo + filtros), reutilizado pelas
telas de usuários, clientes, produtos e pedidos:

- Sem `filtersBuilder`: apenas cabeçalho (`title` + `actions`) e `content`.
- Com `filtersBuilder` em mobile/tablet: um botão de filtro no cabeçalho abre o mesmo formulário em
  um `AppBottomSheet`.
- Com `filtersBuilder` em desktop/largeDesktop: painel lateral fixo ao lado do `content`, sem botão
  no cabeçalho.

O mesmo `filtersBuilder` é reaproveitado nos dois casos — nunca existem dois formulários de filtro
distintos para a mesma tela.
