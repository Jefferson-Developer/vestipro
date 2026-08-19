# TASK-020 — Criar foundations do Design System

**Epic:** EPIC-02 — Design System
**Status:** ⬜ Pendente
**Depende de:** TASK-003 (dependências base do pubspec) — foundations podem depender de pacotes de tipografia/ícones já resolvidos no pubspec.

## Agentes obrigatórios

- `flutter-ui-design-specialist`

## Objetivo

Criar a camada de foundations do Design System do VestiPro (`design_system/foundations/`), definindo todos os tokens visuais centrais — cor, espaçamento, radius, sombra, tipografia, breakpoints, durações e tamanhos de ícone — em tema claro e escuro. Esta task é pré-requisito de todas as demais tasks de componentes (TASK-021 a TASK-025) e de qualquer tela do produto: nenhuma página pode definir cor, espaçamento, radius, sombra ou tipografia arbitrária diretamente.

## Escopo técnico

- Criar `app_colors.dart` com tokens: `primary`, `primaryContainer`, `secondary`, `secondaryContainer`, `surface`, `surfaceContainer`, `background`, `error`, `success`, `warning`, `info`, `onPrimary`, `onSurface`, `outline`, `disabled` — para tema claro e escuro.
- Criar `app_spacing.dart` com escala base 4: `4 8 12 16 20 24 32 40 48 64`.
- Criar `app_radius.dart` com escala: `4 8 12 16 20 24 full`.
- Criar `app_shadows.dart` com níveis de elevação consistentes com o tema claro/escuro (sombra não deve "sumir" no dark mode).
- Criar `app_typography.dart` com escala: `displayLarge/Medium`, `headlineLarge/Medium`, `titleLarge/Medium`, `bodyLarge/Medium/Small`, `labelLarge/Medium/Small`, com fonte definida e suporte a `intl`/escala de texto do sistema.
- Criar `app_breakpoints.dart` com `mobile`, `tablet`, `desktop`, `largeDesktop` e helper de resolução a partir da largura disponível.
- Criar `app_durations.dart` com durações padronizadas de animação (ex.: rápida, padrão, lenta) alinhadas a "animações discretas" da seção 6 de `tasks.md`.
- Criar `app_icon_sizes.dart` com escala de tamanhos de ícone consistente com a tipografia e espaçamento.
- Criar `theme/` com `ThemeData` claro e escuro montados a partir dos tokens acima (via `ThemeExtension` ou equivalente), nunca hardcoding de cor/tamanho fora dos arquivos de foundations.
- Expor um único ponto de acesso (ex.: `AppTheme`/`context.colors`/`context.spacing`) para consumo pelos componentes e telas.

## Regras de negócio e restrições

- Nenhum valor de cor, espaçamento, radius, sombra, tipografia, duração ou tamanho de ícone pode ser definido fora desta camada de foundations.
- Os tokens devem cobrir tema claro e escuro simultaneamente, sem exceções pontuais por tela.
- A escala de espaçamento e radius deve ser exatamente a especificada em `tasks.md` seção 6.1/6 — não inventar valores intermediários.
- Contraste de cor deve atender critérios de acessibilidade (WCAG AA) em ambos os temas.
- Respeitar responsividade real prevista (mobile/tablet/desktop/largeDesktop) desde a definição dos breakpoints.

## Testes obrigatórios

- Testes unitários validando que cada token de espaçamento/radius corresponde à escala definida (4 a 64).
- Teste unitário/golden validando que `ThemeData` claro e escuro carregam sem erro e produzem cores distintas para os dois modos.
- Teste de contraste (cálculo de luminância) para os pares cor de texto/fundo mais usados (`onSurface` sobre `surface`, `onPrimary` sobre `primary`, etc.).
- Teste unitário do helper de breakpoints cobrindo limites exatos entre mobile/tablet/desktop/largeDesktop.

## Critérios de aceite

- Todos os tokens obrigatórios da seção 6 de `tasks.md` existem e são acessíveis via um único ponto de entrada do Design System.
- Tema claro e escuro funcionam e alternam sem quebrar contraste.
- Nenhum arquivo de foundations depende de widgets de tela ou de features específicas (camada isolada e reutilizável).
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros.
- Testes unitários criados nesta task passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
