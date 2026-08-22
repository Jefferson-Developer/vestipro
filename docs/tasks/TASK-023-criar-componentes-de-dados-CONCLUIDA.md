# TASK-023 — Concluída (2026-08-22)

## Resumo

Criados os componentes de apresentação de dados do Design System previstos no escopo técnico da
TASK-023: tabela administrativa responsiva com conversão automática para cards no mobile
(`AppDataTable`), paginação reutilizável em modo numérico e "carregar mais" compatível com cursor
(`AppPagination`), card de métrica/KPI com indicação de tendência (`AppKpiCard`) e o componente
base de gráfico gerencial de linha/barra com alternativa textual acessível (`AppManagementChart`).
Todos consomem exclusivamente tokens já existentes (`AppColors`, `AppSpacing`, `AppRadius`,
`AppTypography`, `AppIconSizes`, `AppBreakpoints`) e reaproveitam componentes já criados nas
TASK-021/TASK-022 (`AppButton`, `AppIconButton`, `AppEmptyState`, `AppErrorState`, `AppSkeleton`,
`AppConfirmationDialog`) — nenhum componente base foi duplicado.

## Agentes utilizados

- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/design_system/components/tables/app_data_table.dart`
- `lib/core/design_system/components/tables/app_pagination.dart`
- `lib/core/design_system/components/cards/app_kpi_card.dart`
- `lib/core/design_system/components/charts/app_management_chart.dart`
- `test/core/design_system/components/tables/app_data_table_test.dart`
- `test/core/design_system/components/tables/app_pagination_test.dart`
- `test/core/design_system/components/cards/app_kpi_card_test.dart`
- `test/core/design_system/components/charts/app_management_chart_test.dart`
- `test/core/design_system/components/goldens/design_system_data_golden_test.dart`
- `test/core/design_system/components/goldens/app_data_table_mode_light.png`
- `test/core/design_system/components/goldens/app_data_table_mode_dark.png`
- `test/core/design_system/components/goldens/app_data_table_card_light.png`
- `test/core/design_system/components/goldens/app_data_table_card_dark.png`
- `test/core/design_system/components/goldens/app_kpi_card_light.png`
- `test/core/design_system/components/goldens/app_kpi_card_dark.png`
- `docs/tasks/TASK-023-criar-componentes-de-dados-CONCLUIDA.md`

## Arquivos alterados

- `lib/core/design_system/components/components.dart` (exporta os 4 novos componentes de dados e
  atualiza o comentário do barrel para mencionar apresentação de dados)
- `docs/tasks/TASKS.md` (checkbox da TASK-023 marcado e progresso atualizado para 23/220 — apenas
  esse trecho foi incluído no commit; o arquivo já tinha outra alteração não relacionada a esta
  task, referente à documentação do `/proximas-tasks`, que foi deixada como estava, sem ser
  revertida nem incluída neste commit)

## Arquitetura utilizada

Design System puro (widgets sem estado de negócio), seguindo o padrão já estabelecido nas
TASK-020/021/022: componentes totalmente controlados pelo chamador (o estado real — linhas,
seleção, ordenação, página atual — vive sempre no BLoC/repositório da feature, nunca dentro do
componente).

- `AppDataTable<T>` é `StatelessWidget` genérico: `columns` define como renderizar cabeçalho e
  célula via `cellBuilder`, reaproveitado sem alterações tanto no modo tabela quanto no modo card —
  a conversão para card usa `LayoutBuilder` + `AppBreakpoints.resolve(constraints.maxWidth)`
  (nunca `MediaQuery` da tela toda), garantindo que não existam duas implementações de tela. Ações
  em lote destrutivas (`AppDataTableBatchAction.isDestructive`) são sempre interceptadas pelo
  próprio componente, que chama `AppConfirmationDialog.show` antes de invocar `onConfirmed` —
  nenhum chamador pode contornar essa confirmação.
- `AppPagination` é `StatelessWidget` puro de controle (não guarda nem busca itens): modo
  `numeric` (setas anterior/próxima + indicador de página) e modo `loadMore` (botão "Carregar
  mais", compatível com paginação por cursor via `hasMore`). Como nunca é dono da lista, não pode
  perder itens já carregados — quem decide acrescentar/substituir é sempre o BLoC chamador.
- `AppKpiCard` é `StatelessWidget` que apenas exibe `value`/`trendPercentage` já calculados e
  formatados pelo chamador; a tendência usa sempre ícone (`trending_up`/`trending_down`/
  `trending_flat`) além da cor, para não depender só de cor.
- `AppManagementChart` é `StatefulWidget` (guarda apenas o estado local de toggle
  gráfico/tabela). Desenho é feito via `CustomPainter` próprio (`_AppChartPainter`), decisão
  documentada abaixo. Todo o conteúdo fica dentro de um `Semantics` com um resumo textual gerado
  automaticamente a partir de `series`/`points`, e um botão alterna para uma tabela de dados
  textual exata (`_AppChartDataTable`) — a cor/forma do gráfico nunca é o único canal de leitura
  dos valores.

## Regras de negócio implementadas

Nenhuma — por definição, estes componentes **não podem** conter regra de negócio (ver seção
"Regras de negócio e restrições" da task). O que foi implementado são as garantias estruturais que
a task exige:

- `AppDataTable`/`AppPagination`/`AppKpiCard`/`AppManagementChart` nunca calculam, ordenam,
  paginam ou agregam dados — apenas exibem o que o chamador fornece e reportam intenção do usuário
  via callbacks (`onSort`, `onSelectionChanged`, `onPageChanged`, `onLoadMore`, etc.).
- `AppDataTableBatchAction` com `isDestructive: true` exige `confirmationTitle`,
  `confirmationMessage` e `confirmLabel` (validado por `assert` no construtor) e só chama
  `onConfirmed` depois que `AppConfirmationDialog.show` resolve `true` — nenhum caminho alternativo
  de confirmação é permitido.
- `AppDataTable` nunca depende de rolagem horizontal sem alternativa em mobile: abaixo do
  breakpoint `mobile` (`AppBreakpoints.mobile`/`tablet`), a tabela é substituída por uma lista de
  cards construída com os mesmos `cellBuilder`s.
- `AppManagementChart` deliberadamente não oferece gráfico de pizza (apenas `line`/`bar`),
  documentado no próprio `enum AppChartType` como orientação para não usar pizza com muitas
  categorias.

## Regras Firebase implementadas

Não aplicável — Design System puro, sem acesso a Firestore/Storage/Functions.

## Analytics implementado

Não aplicável neste escopo (Design System). Eventos de analytics ao redor de ordenação, seleção,
paginação e navegação do gráfico ficam a cargo de cada feature que os utiliza.

## Crashlytics implementado

Não aplicável neste escopo.

## Impacto offline

Nenhum — componentes de apresentação puros, sem leitura/escrita de dados. `AppPagination` foi
desenhado explicitamente para ser compatível com paginação por cursor (campo `hasMore`, sem
depender de contagem total), que é o padrão que o `flutter-senior-architect` usará nos
repositórios offline-first.

## Impacto multi-tenant

Nenhum — componentes de apresentação puros, sem acesso a `organizationId`/dados de tenant.

## Testes criados

- `app_data_table_test.dart`: ordenação (primeiro toque e alternância ascendente/descendente),
  seleção individual e "selecionar todos", ação em lote destrutiva só executando após confirmação
  do `AppConfirmationDialog`, ação em lote não destrutiva executando imediatamente, ação
  contextual por linha, estados de vazio e erro (com retry), e conversão para cards abaixo do
  breakpoint mobile preservando seleção e ações contextuais.
- `app_pagination_test.dart`: avanço e retrocesso no modo numérico, desabilitação das setas nos
  extremos, modo "carregar mais" acrescentando itens sem descartar os já carregados, rótulo de fim
  de lista quando `hasMore` é falso, e botão desabilitado durante `isLoadingMore`.
- `app_kpi_card_test.dart`: renderização de label/valor, variação positiva (ícone
  `trending_up`), negativa (`trending_down`) e neutra (`trending_flat`), e ausência da linha de
  tendência quando nenhuma variação é fornecida.
- `app_management_chart_test.dart`: dataset vazio (série vazia e série sem pontos) renderizando o
  estado vazio, dataset de um único ponto para linha e para barra sem lançar exceção, resumo
  acessível (`Semantics`) contendo o valor exato, alternância para a tabela de dados subjacente
  mostrando o valor exato como texto, e dataset multi-série renderizando a legenda.
- `design_system_data_golden_test.dart`: golden tests de `AppDataTable` (modo tabela e modo card)
  e `AppKpiCard`, em tema claro e escuro (6 imagens de referência).

## Comandos executados

```bash
flutter analyze lib/core/design_system
flutter test test/core/design_system/components/tables test/core/design_system/components/cards test/core/design_system/components/charts
flutter test --update-goldens test/core/design_system/components/goldens/design_system_data_golden_test.dart
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

Sucesso. `dart format --set-exit-if-changed .` não encontrou diferenças pendentes na revisão final
(235 arquivos verificados, 0 alterados).

## Resultado do analyzer

Sucesso. `flutter analyze` → "No issues found!".

## Resultado dos testes

Sucesso. Suíte completa (`flutter test`): 354 testes, todos passando (exit code 0), incluindo os
29 novos testes de widget e os 6 novos golden tests desta task (319 preexistentes + 35 novos).

## Decisões técnicas

- **Gráfico gerencial construído com `CustomPainter` nativo, sem adicionar `fl_chart`** (ou
  qualquer outra biblioteca de gráficos) como dependência. Justificativa: o pubspec do projeto
  ainda não depende de nenhuma biblioteca de gráficos; adicionar uma dependência pesada só para
  dois tipos de gráfico simples (linha/barra) não se justifica frente ao critério "sem adicionar
  biblioteca pesada desnecessária" da própria task, e a implementação nativa dá controle total
  sobre tokens de cor/tipografia do Design System, sobre a geração do resumo textual acessível e
  sobre casos-limite (dataset vazio, dataset de um ponto) sem depender da API de terceiros. Fica
  registrado aqui, como a task exige, para uma revisão futura reconsiderar `fl_chart` caso surjam
  necessidades de gráficos mais sofisticados (radar, candlestick, animações complexas).
- **Nenhum tipo de gráfico de pizza foi implementado.** `AppChartType` só define `line`/`bar` —
  decisão deliberada e documentada no próprio enum, já que pizza deixa de ser legível com muitas
  categorias (regra do agente de front-end) e nenhum caso de uso desta task pede pizza.
- **`AppDataTable.maxHeight` opcional**: quando informado, o corpo da tabela rola dentro de uma
  região de altura fixa com cabeçalho fixo acima (grid clássico). Quando omitido (padrão), cabeçalho
  e linhas dimensionam ao conteúdo (`shrink-wrap`), permitindo compor a tabela dentro de uma página
  já rolável sem duplo scroll — decisão pragática já que os critérios de aceite testados não exigem
  um cabeçalho *pinado durante o scroll* em todo cenário, apenas a ausência de rolagem horizontal
  forçada no mobile.
- **`AppDataTableBatchAction` decide sozinho se precisa confirmar** (via `isDestructive`), em vez
  de deixar cada chamador decidir se chama `AppConfirmationDialog` manualmente — isso torna
  estruturalmente impossível uma tela esquecer a confirmação de uma ação em lote destrutiva.
- Testes que dependem de `find.bySemanticsLabel`/`tester.getSemantics` no gráfico usam
  `tester.ensureSemantics()` com `handle.dispose()` explícito ao final do teste (padrão usado nos
  próprios testes do framework Flutter) — `addTearDown(handle.dispose)` dispara a verificação
  interna de "semantics handle não descartado" do `flutter_test` antes da fila de tear-downs
  rodar, então o dispose precisa ser síncrono ao final do corpo do teste.

## Riscos conhecidos

- Os golden tests são sensíveis à versão do engine Flutter/fontes de teste; como todos os goldens
  já existentes no repositório (TASK-021/TASK-022) seguem a mesma convenção, o risco é o mesmo já
  aceito para aquele conjunto.
- `AppManagementChart` assume que todas as séries comparadas estão alinhadas por índice de posição
  (ex.: índice 0 = "Janeiro" em todas as séries) — não faz correspondência por `AppChartPoint.x`.
  Isso é suficiente para os casos de uso de dashboard descritos em `tasks.md` (comparação mês a
  mês, ano a ano), mas deve ser revisitado se um dashboard futuro precisar de séries com eixos X
  desalinhados.
- `AppDataTable` não implementa rolagem horizontal nem cabeçalho realmente "pinado durante o
  scroll" no modo padrão (sem `maxHeight`) — ver decisão técnica acima. Se uma tela futura precisar
  de fato de um cabeçalho fixo enquanto uma lista muito longa rola, ela deve usar
  `AppDataTable(maxHeight: ...)`.

## Pendências

Nenhuma pendência dentro do escopo desta task. Uso destes componentes nas telas reais (listagens
de usuários/clientes/produtos/pedidos e os dashboards do EPIC-17) é escopo de tasks futuras que
consomem o Design System.

## Evidências

- `flutter analyze`: "No issues found!".
- `flutter test`: "+354: All tests passed!" (exit code 0).
- Golden PNGs gerados e revisados visualmente em
  `test/core/design_system/components/goldens/app_data_table_mode_*.png`,
  `app_data_table_card_*.png` e `app_kpi_card_*.png`.

## Commit

`feat(design-system): add data presentation components (table, pagination, kpi card, chart)`

## Push

Sim — autorizado nesta rodada.

## Hash do commit

`f5bb069`

## Branch

`main`
