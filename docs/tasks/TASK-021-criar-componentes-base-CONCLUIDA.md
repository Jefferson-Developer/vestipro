# TASK-021 — Concluída (2026-08-22)

## Resumo

Criados os componentes visuais fundamentais do Design System VestiPro em
`lib/core/design_system/components/`: botão (`AppButton`, 4 variantes + ícone dedicado
`AppIconButton`), campos de entrada (`AppTextField`, `AppNumberField`, `AppSearchField`),
seletor único/múltiplo com busca interna (`AppDropdown<T>`), chip de filtro
(`AppFilterChip`), badge de status semântico (`AppStatusBadge`), skeleton loading
(`AppSkeleton`), empty state (`AppEmptyState`) e error state (`AppErrorState`). Todos os
componentes consomem exclusivamente os tokens já definidos na TASK-020
(`foundations/`/`theme/`) — nenhuma cor, espaçamento, radius, sombra ou tipografia nova foi
introduzida. O barrel `design_system.dart` passou a exportar também
`components/components.dart`.

## Agentes utilizados

- `flutter-ui-design-specialist` (único agente exigido pela task).

## Arquivos criados

- `lib/core/design_system/components/components.dart`
- `lib/core/design_system/components/buttons/app_button.dart`
- `lib/core/design_system/components/buttons/app_icon_button.dart`
- `lib/core/design_system/components/inputs/app_input_decoration.dart`
- `lib/core/design_system/components/inputs/app_text_field.dart`
- `lib/core/design_system/components/inputs/app_number_field.dart`
- `lib/core/design_system/components/inputs/app_search_field.dart`
- `lib/core/design_system/components/selection/app_dropdown.dart`
- `lib/core/design_system/components/chips/app_filter_chip.dart`
- `lib/core/design_system/components/badges/app_status_badge.dart`
- `lib/core/design_system/components/feedback/app_skeleton.dart`
- `lib/core/design_system/components/feedback/app_empty_state.dart`
- `lib/core/design_system/components/feedback/app_error_state.dart`
- `test/core/design_system/components/test_pump_app.dart` (helper de teste, não é uma
  suíte — não termina em `_test.dart` de propósito)
- `test/core/design_system/components/buttons/app_button_test.dart`
- `test/core/design_system/components/buttons/app_icon_button_test.dart`
- `test/core/design_system/components/inputs/app_text_field_test.dart`
- `test/core/design_system/components/inputs/app_number_field_test.dart`
- `test/core/design_system/components/inputs/app_search_field_test.dart`
- `test/core/design_system/components/selection/app_dropdown_test.dart`
- `test/core/design_system/components/chips/app_filter_chip_test.dart`
- `test/core/design_system/components/badges/app_status_badge_test.dart`
- `test/core/design_system/components/feedback/app_skeleton_test.dart`
- `test/core/design_system/components/feedback/app_empty_state_test.dart`
- `test/core/design_system/components/feedback/app_error_state_test.dart`
- `test/core/design_system/components/goldens/design_system_components_golden_test.dart`
- `test/core/design_system/components/goldens/app_button_primary_light.png` (baseline golden)
- `test/core/design_system/components/goldens/app_button_primary_dark.png` (baseline golden)
- `test/core/design_system/components/goldens/app_text_field_light.png` (baseline golden)
- `test/core/design_system/components/goldens/app_text_field_dark.png` (baseline golden)
- `test/core/design_system/components/goldens/app_status_badge_light.png` (baseline golden)
- `test/core/design_system/components/goldens/app_status_badge_dark.png` (baseline golden)
- `test/core/design_system/components/goldens/app_skeleton_light.png` (baseline golden)
- `test/core/design_system/components/goldens/app_skeleton_dark.png` (baseline golden)

## Arquivos alterados

- `lib/core/design_system/design_system.dart` (passou a exportar
  `components/components.dart`, além de `foundations/` e `theme/`).
- `docs/tasks/TASKS.md` (checkbox da TASK-021 marcado e progresso atualizado para 21/220).

## Arquitetura utilizada

- Clean/feature-first: todos os componentes ficam em
  `lib/core/design_system/components/`, organizados por família (`buttons/`, `inputs/`,
  `selection/`, `chips/`, `badges/`, `feedback/`), sem qualquer dependência de
  Firestore/Drift/repository/BLoC — são widgets puramente apresentacionais recebendo
  dados e callbacks via parâmetro.
- Reuso de tokens: cada arquivo importa `foundations/foundations.dart` e `theme/theme.dart`
  diretamente (em vez do barrel `design_system.dart`) para evitar um ciclo de import
  componente → barrel → componente; o barrel principal continua sendo o único ponto de
  entrada documentado para features.
- `AppInputDecoration` (helper interno, não exportado no barrel) centraliza a
  `InputDecoration` usada por `AppTextField`, `AppNumberField`, `AppSearchField` e
  `AppDropdown`, evitando duplicação de borda/cor/padding entre eles.

## Regras de negócio implementadas

Nenhuma — por definição da task, os componentes são puramente apresentacionais (sem
acesso a repositório/Firestore/regra de autorização). Proteções implementadas ficam no
nível de UX/acessibilidade:
- Guard interno contra duplo-tap em `AppButton`/`AppIconButton` (bloqueia por
  `AppDurations.fast` após o primeiro toque, cancelável no `dispose`), além de já ignorar
  toques quando `isLoading`/`isDisabled`.
- `AppSearchField` debounça `onSearch` (padrão `AppDurations.standard`) mas dispara
  imediatamente ao limpar o campo.
- `AppErrorState` exige `retryLabel` sempre que `onRetry` for informado (assert em tempo
  de desenvolvimento), garantindo que a ação de retry nunca fique sem rótulo textual.
- Todos os textos visíveis (labels, mensagens, ações) são parâmetros obrigatórios — nenhum
  componente contém string de UI hardcoded.

## Regras Firebase implementadas

Não aplicável — componentes de UI sem qualquer acesso a Firebase.

## Analytics implementado

Não aplicável a este escopo (componentes de apresentação; eventos de analytics são
responsabilidade das telas/features que os consomem).

## Crashlytics implementado

Não aplicável a este escopo.

## Impacto offline

Nenhum: componentes puramente visuais, sem estado de sincronização próprio. `AppStatusBadge`
já suporta um variant `neutral`/`info` genérico que outras features poderão reaproveitar para
indicar status de sincronização (ex.: "pendente", "sincronizado"), mas essa integração fica
para a task que criar o indicador de sincronização específico.

## Impacto multi-tenant

Nenhum: nenhum componente lê `organizationId` ou qualquer dado de tenant; toda a informação é
passada pelo chamador via parâmetro.

## Testes criados

- `app_button_test.dart`: todas as variantes disparando `onPressed` uma vez; estado
  `disabled` ignorando toque; estado `loading` escondendo o label sem redimensionar o botão
  e bloqueando toques; guarda contra duplo-tap rápido; `leadingIcon` renderizado; tamanho
  mínimo de toque acessível (≥48).
- `app_icon_button_test.dart`: toque único, `semanticLabel` exposto ao leitor de tela,
  bloqueio de toque durante `loading`, tamanho mínimo de toque acessível.
- `app_text_field_test.dart`: texto vazio, texto longo com `onChanged`, `errorText`
  exibido, marcador `*` de campo obrigatório, campo desabilitado ignorando entrada.
- `app_number_field_test.dart`: teclado numérico, filtragem de caracteres não numéricos,
  permissão de separador decimal quando habilitado, `errorText` exibido.
- `app_search_field_test.dart`: debounce da busca após a duração configurada; botão de
  limpar aparecendo com texto e disparando busca vazia imediatamente ao ser tocado.
- `app_dropdown_test.dart`: seleção única fecha o diálogo e retorna o valor escolhido;
  seleção múltipla acumula seleções; busca interna filtra a lista de opções.
- `app_filter_chip_test.dart`: toque alterna seleção; estado selecionado exposto via
  semântica; toque no ícone de remoção dispara `onRemove`.
- `app_status_badge_test.dart`: todas as variantes renderizam label + ícone; ícone
  customizado sobrescreve o padrão do variant.
- `app_skeleton_test.dart`: construtores `.line`/`.block`/`.card` dimensionam o
  placeholder corretamente; animação de opacidade não lança exceção.
- `app_empty_state_test.dart` / `app_error_state_test.dart`: título/descrição/mensagem
  renderizados; ação configurada dispara o callback; ação ausente não é renderizada.
- Golden tests (`design_system_components_golden_test.dart`): `AppButton` (primary),
  `AppTextField`, `AppStatusBadge` (success) e `AppSkeleton` (card), cada um em tema claro
  e escuro (8 imagens de baseline geradas e versionadas em
  `test/core/design_system/components/goldens/`).

## Comandos executados

```bash
dart format lib/core/design_system test/core/design_system
flutter analyze lib/core/design_system test/core/design_system
flutter test test/core/design_system/components
flutter test --update-goldens test/core/design_system/components/goldens
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

## Resultado do formatter

`dart format --set-exit-if-changed .` → sem alterações pendentes (exit code 0) após ajustes
automáticos aplicados durante o desenvolvimento.

## Resultado do analyzer

`flutter analyze` (repositório completo) → `No issues found!`.

## Resultado dos testes

`flutter test` (suíte completa do repositório) → `296 tests passed`, nenhuma falha.
`flutter test test/core/design_system/components` (escopo da task) → `52 tests passed`.
`flutter build web --release` → build concluído com sucesso (`Built build\web`).

## Decisões técnicas

- Arquivos dentro de `components/` importam `foundations/foundations.dart` e
  `theme/theme.dart` diretamente em vez do barrel `design_system.dart`, para não criar um
  ciclo de import (barrel exporta `components/`, então `components/` não deve importar o
  barrel de volta).
- `AppDropdown<T>` abre um `Dialog` (via `showDialog`) em vez de um menu inline, para
  funcionar de forma consistente em mobile/tablet/Web, suportar foco de teclado e busca
  interna em listas longas sem overflow de menu; o botão de fechar (ícone) sempre confirma
  a seleção acumulada no modo múltiplo e cancela (sem alterar `selectedValues`) no modo
  único.
- Uso de `RadioGroup<T>` (API atual do Flutter 3.44) em vez dos parâmetros depreciados
  `RadioListTile.groupValue`/`onChanged`.
- Guard de duplo-tap implementado com `Timer` cancelável (não `Future.delayed`), para não
  deixar timers pendentes após o widget ser descartado — problema real encontrado durante os
  testes (assinatura "Timer is still pending" do `flutter_test`).
- Badge/skeleton golden tests não fixam uma largura artificial (usam a intrínseca do
  componente), pois forçar uma `SizedBox` com largura fixa causava overflow de meio pixel
  no `Row` interno do badge — um artefato do harness de teste, não um bug do componente.

## Riscos conhecidos

- Golden tests foram gerados e validados apenas no Windows local (fonte Roboto/engine
  desta máquina). Renderização de golden pode variar entre sistemas operacionais/versões de
  engine Flutter; se o CI rodar em Linux, os goldens podem precisar ser regenerados lá.
- `AppDropdown<T>` depende de `T` implementar `==`/`hashCode` coerentes (valores simples
  como `String`/`enum`/id); não valida isso em tempo de compilação.
- Sem infraestrutura de i18n (arb/l10n) ainda no projeto — todos os textos são parâmetros
  `String` diretos, como já é o padrão no restante do app; quando a infraestrutura de i18n for
  introduzida, os chamadores destes componentes precisarão passar as strings traduzidas.

## Pendências

Nenhuma pendência dentro do escopo desta task. Componentes de formulário/feedback
adicionais (ex.: stepper, upload, gráficos, tabelas) ficam para as próximas tasks do
EPIC-02 (TASK-022 a TASK-025), como já previsto no backlog.

## Evidências

- `flutter test test/core/design_system/components` → `52 tests passed`.
- `flutter test` (completo) → `296 tests passed`.
- `flutter analyze` → `No issues found!`.
- `flutter build web --release` → `Built build\web`.
- Imagens golden versionadas em `test/core/design_system/components/goldens/*.png`.

## Commit

Criado no mesmo commit que documenta esta conclusão e marca o checkbox em
`docs/tasks/TASKS.md`.

## Push

Não realizado nesta rodada (push não autorizado).

## Hash do commit

Ver seção final da resposta ao usuário (preenchido após `git commit`).

## Branch

`main`
