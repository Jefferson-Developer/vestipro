# TASK-020 — Concluída (2026-08-22)

## Resumo

Criada a camada de foundations do Design System do VestiPro em
`lib/core/design_system/foundations/` (cor, espaçamento, radius, sombra, tipografia,
breakpoints, durações e tamanhos de ícone), tema claro/escuro montado a partir desses
tokens em `lib/core/design_system/theme/` (`AppTheme`), e um ponto único de acesso via
`lib/core/design_system/design_system.dart` + extensão `context.colors` /
`context.shadows` / `context.breakpoint`. `lib/app/bootstrap.dart` foi atualizado para
consumir `AppTheme.light`/`AppTheme.dark` (com `themeMode: ThemeMode.system`) em vez do
`ThemeData` improvisado que existia antes desta task, eliminando a última definição de
tema fora da camada de foundations.

## Agentes utilizados

- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/design_system/design_system.dart`
- `lib/core/design_system/foundations/app_breakpoints.dart`
- `lib/core/design_system/foundations/app_colors.dart`
- `lib/core/design_system/foundations/app_durations.dart`
- `lib/core/design_system/foundations/app_icon_sizes.dart`
- `lib/core/design_system/foundations/app_radius.dart`
- `lib/core/design_system/foundations/app_shadows.dart`
- `lib/core/design_system/foundations/app_spacing.dart`
- `lib/core/design_system/foundations/app_typography.dart`
- `lib/core/design_system/foundations/foundations.dart`
- `lib/core/design_system/theme/app_theme.dart`
- `lib/core/design_system/theme/design_system_context.dart`
- `lib/core/design_system/theme/theme.dart`
- `test/core/design_system/foundations/app_breakpoints_test.dart`
- `test/core/design_system/foundations/app_colors_test.dart`
- `test/core/design_system/foundations/app_durations_test.dart`
- `test/core/design_system/foundations/app_icon_sizes_test.dart`
- `test/core/design_system/foundations/app_radius_test.dart`
- `test/core/design_system/foundations/app_shadows_test.dart`
- `test/core/design_system/foundations/app_spacing_test.dart`
- `test/core/design_system/foundations/app_typography_test.dart`
- `test/core/design_system/theme/app_theme_test.dart`
- `docs/tasks/TASK-020-criar-design-system-foundations-CONCLUIDA.md`

## Arquivos alterados

- `lib/app/bootstrap.dart` (passou a montar `MaterialApp.router` com
  `theme: AppTheme.light`, `darkTheme: AppTheme.dark`, `themeMode: ThemeMode.system`, em
  vez de um `ThemeData(colorScheme: ColorScheme.fromSeed(...))` definido ali mesmo)
- `docs/tasks/TASKS.md` (checkbox da TASK-020 marcado e `Progresso` atualizado para
  `20 / 220`)

## Regras implementadas

- Nenhum valor de cor, espaçamento, radius, sombra, tipografia, duração ou tamanho de
  ícone vive fora de `lib/core/design_system/foundations/`; `AppTheme` é o único lugar
  que monta `ThemeData`/`ColorScheme`.
- Tokens cobrem tema claro (`AppColors.light`) e escuro (`AppColors.dark`)
  simultaneamente, sem exceção pontual por tela.
- Escala de espaçamento (`4 8 12 16 20 24 32 40 48 64`) e radius (`4 8 12 16 20 24 full`)
  seguem exatamente `tasks.md` seção 6/6.1 — sem valores intermediários inventados.
- Contraste WCAG AA (>= 4.5:1) verificado por cálculo de luminância real para
  `onSurface`/`surface` e `onPrimary`/`primary`, nos dois temas.
- Breakpoints (`mobile`/`tablet`/`desktop`/`largeDesktop`) resolvidos por
  `AppBreakpoints.resolve(width)`, com limites exatos testados.
- `AppTypography` usa tamanhos relativos de fonte (sem `TextStyle` fixo que ignore
  `MediaQuery.textScaler`), preservando a escala de texto do sistema/`intl`.
- Camada de foundations não depende de nenhum widget de tela ou feature: apenas
  `package:flutter/material.dart` e tokens entre si.

## Firebase

Não aplicável a esta task (camada puramente de UI/tema, sem acesso a
Firestore/Storage/Functions/Auth).

## Offline/Multi-tenant

Não aplicável: a camada de foundations não lê nem depende de estado de rede,
organização ou dados do usuário.

## Analytics

Não aplicável a esta task (nenhum evento de produto é gerado por tokens de tema).

## Crashlytics

Não aplicável a esta task.

## Testes criados

38 testes unitários/widget novos em `test/core/design_system/`:

- `app_spacing_test.dart`: escala exata, tokens nomeados e ordenação estrita.
- `app_radius_test.dart`: escala exata, `full` como token distinto e maior que a escala.
- `app_breakpoints_test.dart`: limites exatos entre `mobile`/`tablet`/`desktop`/
  `largeDesktop`.
- `app_colors_test.dart`: contraste WCAG AA (>= 4.5:1) via cálculo de luminância
  relativa para `onSurface`/`surface` e `onPrimary`/`primary` em ambos os temas; `light`
  e `dark` com tokens distintos; `copyWith`/`lerp` do `ThemeExtension`.
- `app_durations_test.dart`: ordenação `fast < standard < slow` e limite máximo de
  animação discreta (400ms).
- `app_icon_sizes_test.dart`: escala exata e ordenação estrita.
- `app_shadows_test.dart`: `resolve` por `Brightness`; elevação crescente `sm→xl`;
  opacidade do tema escuro sempre maior que a do tema claro em cada nível.
- `app_typography_test.dart`: `fontFamily` único em toda a escala; tamanhos decrescentes
  de `display` a `label`; `textTheme` aplica a cor `onSurface` do `AppColors` recebido.
- `app_theme_test.dart`: `ThemeData` claro/escuro carregam sem erro, com `brightness`
  correto e cores distintas para os mesmos papéis; `context.colors`/`context.shadows`/
  `context.breakpoint` resolvendo corretamente contra tema/tamanho de tela ativos.

## Comandos executados

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 189 files (0 changed)` — sem alterações pendentes.

## Resultado do analyzer

`No issues found!`

## Resultado dos testes

`flutter test` (suíte completa do projeto): `+243 All tests passed!` (nenhuma falha).

## Decisões técnicas

- `AppColors` é um `ThemeExtension<AppColors>` registrado em `ThemeData.extensions`,
  permitindo ler o token set semântico completo via `Theme.of(context).extension<
  AppColors>()` além dos papéis padrão do Material (`ColorScheme`).
- `AppTheme` usa `ColorScheme.fromSeed` apenas para preencher os papéis Material 3 que o
  Design System não nomeia explicitamente (tertiary, outlineVariant, scrim, etc.) e então
  sobrescreve com `.copyWith(...)` todos os papéis que o VestiPro define — a paleta da
  marca sempre prevalece.
- `AppTypography.fontFamily` usa `'Roboto'`, a fonte que o engine do Flutter empacota e
  garante em toda plataforma (Android/iOS/Web/desktop) sem exigir nenhum asset de fonte
  novo no `pubspec.yaml` — não havia dependência de fonte de marca resolvida em
  TASK-003, então declarar um asset de fonte próprio ficaria fora do escopo desta task.
  Pode ser substituído depois por uma fonte de marca sem alterar nenhuma outra tela: só
  este arquivo muda.
- Tokens que não variam com o tema (`AppSpacing`, `AppRadius`, `AppTypography`,
  `AppDurations`, `AppIconSizes`, `AppBreakpoints`) são classes `abstract final` com
  campos `static const`, evitando instanciação sem sentido; tokens que variam com o
  brightness ativo (`AppColors`, `AppShadows`) são resolvidos via
  `context.colors`/`context.shadows`.
- `lib/app/bootstrap.dart` foi atualizado para consumir `AppTheme` porque era o único
  lugar do app que montava um `ThemeData` — deixá-lo intacto teria criado uma segunda
  fonte de verdade de tema logo na primeira task do Design System.

## Riscos conhecidos

- A paleta de cores (`AppColors`) é uma proposta inicial alinhada ao seed já em uso no
  projeto (`0xFF245C73`); pode ser refinada por um time de branding/design sem impacto
  estrutural, já que todo consumo passa pelos tokens, nunca por valores literais.
- `AppTypography.fontFamily = 'Roboto'` é uma decisão temporária até que uma fonte de
  marca (com licenciamento e assets) seja definida e adicionada ao `pubspec.yaml`.

## Pendências

- TASK-021 a TASK-025 (componentes base, formulário/feedback, dados, catálogo) devem
  consumir exclusivamente os tokens criados aqui, nunca redefinir cor/espaçamento/radius/
  sombra/tipografia.

## Evidências

- `flutter analyze`: `No issues found!`
- `dart format --set-exit-if-changed .`: `Formatted 189 files (0 changed)`
- `flutter test`: `+243 All tests passed!`

## Commit

Local, sem push (não autorizado nesta rodada).

## Push

Não realizado — não autorizado nesta rodada.

## Hash do commit

Ver mensagem de retorno da task (registrado após `git commit`).

## Branch

`main`
