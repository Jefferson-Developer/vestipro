# TASK-025 — Concluída (2026-08-22)

## Resumo

Criada a camada de layouts responsivos do Design System (`lib/core/design_system/layouts/`):
o widget central de resolução de breakpoint (`AppResponsiveBuilder`, mais o auxiliar
`AppResponsiveValue<T>`), o shell de navegação adaptativo (`AppAdaptiveShell` — bottom navigation
no mobile, `NavigationRail` no tablet e sidebar permanente colapsável no desktop/largeDesktop, todos
compartilhando o mesmo estado de rota ativa) e o esqueleto padrão de página administrativa
(`AppAdminPageLayout` — cabeçalho + conteúdo + filtros em painel lateral fixo no desktop ou
`AppBottomSheet` no mobile/tablet). Um `README.md` documenta o guia de uso de cada tier de
breakpoint. Um bug real de overflow (`RenderFlex overflowed by 4.0 pixels`) durante a animação de
expandir a sidebar foi corrigido durante esta sessão, e os golden tests — que ainda não tinham
arquivos `.png` de referência gerados — foram gerados e validados.

## Agentes utilizados

- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/design_system/layouts/layouts.dart` (barrel do módulo)
- `lib/core/design_system/layouts/app_responsive_builder.dart` (`AppResponsiveBuilder`, `AppResponsiveValue<T>`)
- `lib/core/design_system/layouts/app_nav_destination.dart` (`AppNavDestination`)
- `lib/core/design_system/layouts/app_adaptive_shell.dart` (`AppAdaptiveShell`)
- `lib/core/design_system/layouts/app_admin_page_layout.dart` (`AppAdminPageLayout`)
- `lib/core/design_system/layouts/README.md` (guia de breakpoints e dos três widgets)
- `test/core/design_system/layouts/app_responsive_builder_test.dart`
- `test/core/design_system/layouts/app_adaptive_shell_test.dart`
- `test/core/design_system/layouts/app_admin_page_layout_test.dart`
- `test/core/design_system/layouts/goldens/design_system_layouts_golden_test.dart`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_mobile.png`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_tablet.png`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_desktop.png`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_large_desktop.png`
- `test/core/design_system/layouts/goldens/app_admin_page_layout_mobile.png`
- `test/core/design_system/layouts/goldens/app_admin_page_layout_desktop.png`
- `docs/tasks/TASK-025-criar-layouts-responsivos-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/design_system/design_system.dart` — passou a exportar `layouts/layouts.dart` no barrel
  único do Design System.
- `docs/tasks/TASKS.md` — checkbox da TASK-025 marcado e progresso atualizado para 25/220.

## Arquitetura utilizada

- Camada puramente de apresentação do Design System (`lib/core/design_system/layouts/`), sem
  acesso a Firestore/BLoC/roteamento. `AppAdaptiveShell` recebe `destinations`, `selectedIndex`,
  `onDestinationSelected` e `body` já resolvidos pelo chamador (tipicamente um
  `StatefulShellRoute` do `go_router`), sem conhecer rotas nem RBAC.
- `AppResponsiveBuilder` resolve o breakpoint a partir da largura disponível do próprio widget
  (`LayoutBuilder` + `AppBreakpoints.resolve`), nunca de `MediaQuery` — mesmo padrão já usado por
  `AppDataTable`/`AppProductGrid`/`AppSizeGrid` das tasks anteriores.
- `AppAdaptiveShell` e `AppAdminPageLayout` reutilizam componentes existentes do Design System
  (`AppIconButton`, `AppBottomSheet`, tokens de `foundations`/`theme`) sem duplicar nada.

## Regras de negócio implementadas

Nenhuma — camada de UI pura, sem regra de negócio, preço, RBAC ou persistência (conforme escopo do
agente `flutter-ui-design-specialist`). A filtragem de quais itens de menu aparecem é
responsabilidade da camada de domínio (prevista para a TASK-029).

## Regras Firebase implementadas

Nenhuma.

## Analytics implementado

Nenhum (fora de escopo desta task).

## Crashlytics implementado

Nenhum (fora de escopo desta task).

## Impacto offline

Nenhum — widgets puramente visuais, sem estado de sincronização.

## Impacto multi-tenant

Nenhum — o shell não lê `organizationId` nem decide RBAC; apenas exibe os itens já filtrados pelo
chamador.

## Testes criados

- `app_responsive_builder_test.dart`: resolução de cada tier a partir da largura própria do widget
  (não da janela), reconstrução ao redimensionar, e todos os casos de fallback de
  `AppResponsiveValue<T>`.
- `app_adaptive_shell_test.dart`: troca de layout (bottom nav/rail/sidebar) nas quatro faixas de
  breakpoint, comportamento em largura intermediária (700px, entre tablet e desktop) sem overflow,
  estado de rota ativa compartilhado entre mobile/tablet/desktop, overflow de destinos no mobile
  ("Mais"), destinos secundários e colapso/expansão da sidebar.
- `app_admin_page_layout_test.dart`: painel lateral fixo em desktop/largeDesktop vs. botão de
  filtro + `AppBottomSheet` em mobile/tablet, e ausência de qualquer entrada de filtro quando
  `filtersBuilder` não é informado.
- `goldens/design_system_layouts_golden_test.dart`: golden tests do shell em mobile, tablet,
  desktop e largeDesktop, e do `AppAdminPageLayout` em mobile (botão de filtro) e desktop (painel
  lateral).

## Comandos executados

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --update-goldens test/core/design_system/layouts/goldens/design_system_layouts_golden_test.dart
flutter test
```

## Resultado do formatter

`Formatted 253 files (0 changed) in 1.10 seconds.` — sem alterações pendentes.

## Resultado do analyzer

`Analyzing VestiPro... No issues found! (ran in 8.1s)`.

## Resultado dos testes

`flutter test` completo: **422 testes, todos passando** (exit code 0). Os golden tests de
`layouts/` não tinham arquivos `.png` de referência no disco; foram gerados com
`--update-goldens` e revalidados normalmente (sem a flag) em seguida.

## Decisões técnicas

- Corrigido um overflow real de `RenderFlex` (`A RenderFlex overflowed by 4.0 pixels on the
  right.`) em `_buildSidebarItem` (`app_adaptive_shell.dart`): ao expandir a sidebar,
  `_isSidebarCollapsed` virava `false` (via `setState`) um frame antes do `AnimatedContainer`
  terminar de animar a largura de 72px para 240px, fazendo a `Row` de ícone+label tentar renderizar
  com apenas ~32px disponíveis. A correção substitui a decisão baseada só no booleano por um
  `LayoutBuilder` que mede a largura real disponível a cada frame (constante
  `_kMinExpandedSidebarItemContentWidth` = ícone + espaçamento) e só mostra o label quando há
  espaço suficiente, eliminando o overflow durante toda a animação sem alterar o resultado final
  (ícone completo colapsado, ícone + label expandido).
- Optado por manter `AppResponsiveBuilder` resolvendo contra a largura do próprio widget (via
  `LayoutBuilder`), e reservar `context.breakpoint` (já existente da TASK-020) só para decisões
  genuinamente de nível de janela (ex.: o próprio `AppAdaptiveShell`), conforme documentado no
  `README.md` da pasta.
- `AppAdaptiveShell` nunca importa `go_router`: recebe `body` já resolvido e delega navegação via
  callback, mantendo o shell reutilizável independentemente de como o roteamento está montado.

## Riscos conhecidos

- Os golden tests são sensíveis a mudanças de fonte/engine do Flutter; qualquer bump de versão do
  SDK pode exigir regeneração com `--update-goldens` (mesmo padrão de risco das goldens já
  existentes em `test/core/design_system/components/goldens/`).
- `AppAdaptiveShell` ainda não foi integrado a uma tela real com `go_router`/RBAC (isso é esperado
  apenas a partir da TASK-029 em diante); a integração real pode revelar ajustes finos de espaçamento
  quando os itens de menu definitivos do produto forem conhecidos.

## Pendências

Nenhuma pendência dentro do escopo desta task. A composição do shell com rotas reais e RBAC fica
para as tasks de features (a partir de TASK-029) que já foram referenciadas na documentação dos
widgets.

## Evidências

- `test/core/design_system/layouts/goldens/app_adaptive_shell_mobile.png`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_tablet.png`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_desktop.png`
- `test/core/design_system/layouts/goldens/app_adaptive_shell_large_desktop.png`
- `test/core/design_system/layouts/goldens/app_admin_page_layout_mobile.png`
- `test/core/design_system/layouts/goldens/app_admin_page_layout_desktop.png`

## Commit

Ver hash abaixo.

## Push

Autorizado e executado nesta sessão.

## Hash do commit

Preenchido após o commit (ver resposta final da sessão que executou esta task).

## Branch

`main`
