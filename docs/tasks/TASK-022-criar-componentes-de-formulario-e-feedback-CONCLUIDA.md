# TASK-022 — Concluída (2026-08-22)

## Resumo

Criados os componentes de overlay e feedback do Design System previstos no escopo técnico da
TASK-022: modal genérico (`AppModal`), bottom sheet reutilizável (`AppBottomSheet`), snackbar
padronizado com enfileiramento (`AppSnackbar`), tooltip reutilizável com fallback de toque longo
(`AppTooltip`) e o diálogo de confirmação destrutiva (`AppConfirmationDialog`), único caminho
oficial para ações irreversíveis no restante do backlog. Todos consomem exclusivamente tokens já
existentes (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppIconSizes`,
`AppDurations`, `AppBreakpoints`) e reaproveitam `AppButton`/`AppIconButton` já criados na
TASK-021 — nenhum componente base foi duplicado.

## Agentes utilizados

- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/design_system/components/overlays/app_modal.dart`
- `lib/core/design_system/components/overlays/app_bottom_sheet.dart`
- `lib/core/design_system/components/overlays/app_tooltip.dart`
- `lib/core/design_system/components/overlays/app_confirmation_dialog.dart`
- `lib/core/design_system/components/feedback/app_snackbar.dart`
- `test/core/design_system/components/overlays/app_modal_test.dart`
- `test/core/design_system/components/overlays/app_bottom_sheet_test.dart`
- `test/core/design_system/components/overlays/app_tooltip_test.dart`
- `test/core/design_system/components/overlays/app_confirmation_dialog_test.dart`
- `test/core/design_system/components/feedback/app_snackbar_test.dart`
- `test/core/design_system/components/goldens/design_system_overlays_golden_test.dart`
- `test/core/design_system/components/goldens/app_modal_light.png`
- `test/core/design_system/components/goldens/app_modal_dark.png`
- `test/core/design_system/components/goldens/app_bottom_sheet_light.png`
- `test/core/design_system/components/goldens/app_bottom_sheet_dark.png`
- `test/core/design_system/components/goldens/app_confirmation_dialog_light.png`
- `test/core/design_system/components/goldens/app_confirmation_dialog_dark.png`
- `docs/tasks/TASK-022-criar-componentes-de-formulario-e-feedback-CONCLUIDA.md`

## Arquivos alterados

- `lib/core/design_system/components/components.dart` (exporta os 5 novos componentes e
  atualiza o comentário do barrel para mencionar overlays)
- `docs/tasks/TASKS.md` (checkbox da TASK-022 marcado e progresso atualizado para 22/220)

## Arquitetura utilizada

Design System puro (widgets sem estado de negócio), seguindo exatamente o padrão já estabelecido
nas TASK-020/TASK-021: `abstract final class` com métodos estáticos `show(...)` para os overlays
imperativos (`AppModal`, `AppBottomSheet`, `AppConfirmationDialog`, `AppSnackbar`), widget
declarativo simples para `AppTooltip`, tokens lidos via `context.colors`/`context.breakpoint`
(extension `DesignSystemContext`), e reaproveitamento de `AppButton`/`AppIconButton` para toda
ação de rodapé/close. `AppModal` e `AppBottomSheet` são construídos sobre `showDialog`/
`showModalBottomSheet`, herdando de graça o atalho padrão de Esc e a restauração de foco que o
Flutter já provê para toda rota (`ModalRoute`). `AppConfirmationDialog` é construído sobre o mesmo
mecanismo de `showDialog`, mas com layout próprio (não reaproveita `AppModal` para não acoplar a
API de confirmação booleana à API genérica de ações do modal).

## Regras de negócio implementadas

Nenhuma — por definição, estes componentes **não podem** conter regra de negócio (ver seção
"Regras de negócio e restrições" da task). O que foi implementado são as garantias estruturais que
a task exige:

- `AppConfirmationDialog.show` só resolve `true` quando o botão de confirmação é tocado; qualquer
  outra forma de saída (cancelar, tocar a barreira, Esc) resolve `false` — nunca dispara a ação
  destrutiva por engano.
- `AppSnackbar.show` nunca sobrepõe mensagens: é um wrapper fino sobre
  `ScaffoldMessenger.showSnackBar`, que já enfileira e mostra uma mensagem por vez.
- `AppTooltip`/`AppTooltip.helpIcon` são documentados como complementares — nunca o único canal
  para preço/estoque/condição/restrição.
- `AppBottomSheet` é documentado como não podendo ser o único passo de confirmação para ações
  destrutivas (deve ser combinado com `AppConfirmationDialog`).

## Regras Firebase implementadas

Não aplicável — Design System puro, sem acesso a Firestore/Storage/Functions.

## Analytics implementado

Não aplicável neste escopo (Design System). Eventos de analytics ao redor de abrir/fechar
overlays ficam a cargo de cada feature que os utiliza.

## Crashlytics implementado

Não aplicável neste escopo.

## Impacto offline

Nenhum — componentes de apresentação puros, sem leitura/escrita de dados.

## Impacto multi-tenant

Nenhum — componentes de apresentação puros, sem acesso a `organizationId`/dados de tenant.

## Testes criados

- `app_modal_test.dart`: abertura com título/corpo, fechamento pelo botão de fechar, fechamento
  pela ação primária, fechamento por Esc (Web/desktop) e devolução de foco ao elemento de origem.
- `app_bottom_sheet_test.dart`: abertura com título/conteúdo dinâmico, fechamento pelo botão de
  fechar, fechamento por gesto de arrastar para baixo, e resolução do valor com que o conteúdo
  encerra a sheet.
- `app_confirmation_dialog_test.dart`: resolve `false` ao tocar a barreira (nunca confirma por
  acidente), resolve `false` ao tocar "Cancelar", resolve `true` apenas ao tocar o botão de
  confirmação.
- `app_tooltip_test.dart`: exibição da mensagem via toque longo (fallback mobile) para `AppTooltip`
  e para o `AppTooltip.helpIcon`.
- `app_snackbar_test.dart`: renderização da mensagem, enfileiramento de duas mensagens em sequência
  sem sobreposição, e renderização/disparo do botão de ação opcional.
- `design_system_overlays_golden_test.dart`: golden tests de `AppModal`, `AppBottomSheet` e
  `AppConfirmationDialog` em tema claro e escuro (6 imagens de referência).

## Comandos executados

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --update-goldens test/core/design_system/components/goldens/design_system_overlays_golden_test.dart
flutter test test/core/design_system
flutter test
```

## Resultado do formatter

Sucesso. `dart format --set-exit-if-changed .` não encontrou diferenças pendentes na revisão
final (226 arquivos verificados, 0 alterados).

## Resultado do analyzer

Sucesso. `flutter analyze` → "No issues found!".

## Resultado dos testes

Sucesso. Suíte completa (`flutter test`): 319 testes, todos passando (exit code 0), incluindo os
22 novos testes de widget e os 6 golden tests desta task.

## Decisões técnicas

- `AppModal`/`AppConfirmationDialog` usam `showDialog` (não um `AppModal` genérico reaproveitado
  pelo diálogo de confirmação) para manter a API de confirmação simples e fortemente tipada
  (`Future<bool>`), evitando que a decisão booleana "confirmar/cancelar" precise ser montada por
  cada chamador a partir de `AppModalAction`.
- `AppSnackbar` não implementa fila própria: delega inteiramente para o enfileiramento nativo do
  `ScaffoldMessenger`, evitando duplicar uma lógica que o framework já resolve corretamente.
- `AppBottomSheet` envolve seu conteúdo visível num `RepaintBoundary` próprio (com `contentKey`
  opcional) porque a rota do `showModalBottomSheet` ocupa a altura inteira disponível (para
  suportar arraste), tornando a captura de golden/screenshot do `BottomSheet` do framework enorme
  e majoritariamente vazia; capturar o `RepaintBoundary` interno produz um recorte fiel apenas ao
  cartão visível.
- Esc-to-dismiss e devolução de foco não exigiram código extra: são comportamento padrão de
  qualquer `ModalRoute` no Flutter (`showDialog`/`showModalBottomSheet`), validado por teste de
  widget dedicado em vez de reimplementado manualmente.

## Riscos conhecidos

- Os golden tests são sensíveis à versão do engine Flutter/fontes de teste; como todos os goldens
  já existentes no repositório (TASK-021) seguem a mesma convenção, o risco é o mesmo já aceito
  para aquele conjunto.
- `AppModal`/`AppConfirmationDialog` não fixam foco inicial em um botão específico (ex.: "Cancelar"
  focado por padrão em diálogos destrutivos) — não era exigido pelos critérios de aceite desta
  task, mas pode ser um refinamento futuro de acessibilidade.

## Pendências

Nenhuma pendência dentro do escopo desta task. Uso destes componentes nas telas reais (exclusão de
cliente/produto, desativação de usuário, cancelamento de pedido, alteração de role) é escopo de
tasks futuras que consomem o Design System.

## Evidências

- `flutter analyze`: "No issues found!".
- `flutter test`: "+319: All tests passed!" (exit code 0).
- Golden PNGs gerados e revisados visualmente em
  `test/core/design_system/components/goldens/app_modal_*.png`,
  `app_bottom_sheet_*.png` e `app_confirmation_dialog_*.png`.

## Commit

`feat(design-system): add overlay and feedback components`

## Push

Sim — autorizado nesta rodada.

## Hash do commit

Preenchido após o commit real (ver resposta final).

## Branch

`main`
