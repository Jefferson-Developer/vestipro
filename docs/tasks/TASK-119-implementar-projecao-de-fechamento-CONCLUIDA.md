# TASK-119 — Implementar projeção de fechamento (CONCLUÍDA)

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ✅ Concluída
**Data:** terça-feira, 1 de setembro de 2026
**Branch:** `main`

## O que foi feito

### Metodologia documentada (`docs/architecture/`)

- `docs/architecture/closing-projection-methodology.md` (novo): descreve a
  fórmula de projeção linear padrão (`realizado / fração decorrida do
  período`), os casos-limite (período recém-iniciado/<10% decorrido,
  período encerrado, meta zerada), a garantia de consistência com o
  dashboard de atingimento (TASK-116) e o espaço deixado para metodologias
  futuras (média móvel ponderada, sazonalidade) via `ProjectionStrategy`.
  Complementa (nunca duplica) a documentação de domínio já embutida nos
  próprios arquivos de código — a regra "nunca uma caixa preta" exige que a
  metodologia seja legível tanto por quem lê o código quanto por quem só
  tem acesso a `docs/`.

### Domínio (`lib/features/targets/domain/`)

- `ProjectionStrategy` (novo, interface): contrato mínimo para qualquer
  metodologia de extrapolação — `project({realizedValue, elapsedFraction})`
  + `methodologyDescription` (o texto curto exibido ao usuário, para nunca
  ser uma caixa preta). Permite metodologias futuras (média móvel
  ponderada, sazonalidade) sem quebrar `ClosingProjectionService`.
- `LinearProjectionStrategy` (novo, implementação padrão, `@Injectable(as:
  ProjectionStrategy)`): `realizado / fração decorrida`, mesma fórmula que
  `TargetProgressViewModel.projectedValue` (TASK-116) já usava embutida —
  agora isolada e documentada explicitamente, sem alterar o resultado
  numérico de nada que já existia.
- `ProjectionReliability` (novo, enum): `lowConfidence` (< 10% do período
  decorrido), `reliable`, `periodEnded`.
- `ClosingProjectionService`/`ClosingProjectionResult` (novos,
  `@injectable`): recebem o mesmo `TargetProgressViewModel` que o dashboard
  de atingimento (TASK-116) já calculou — nunca buscam ou recalculam
  "realizado" de forma independente. Para período em andamento, recomputam
  a fração decorrida a partir dos mesmos `target.startDate`/`target.endDate`
  /`progress.now` que o próprio `TargetProgressViewModel` usou (nunca de um
  novo `DateTime.now()`), garantindo resultado bit-idêntico ao que o
  dashboard mostra, e delegam a extrapolação em si à `ProjectionStrategy`
  injetada. Para período encerrado, a "projeção" é simplesmente o valor
  final realizado (`ProjectionReliability.periodEnded`), sem aplicar a
  fórmula. Percentual de atingimento projetado nunca divide por zero (mesma
  regra de `TargetProgressViewModel.achievementPercentage`).

### Apresentação (`lib/features/targets/presentation/`)

- `TargetDashboardCubit` (alterado): agora recebe `ClosingProjectionService`
  por construtor (mesmo padrão de injeção de `RankingCalculationService`
  na TASK-118) e o chama logo após `TargetProgressViewModel.compute` em
  `_onAchievement`, guardando o resultado em
  `TargetDashboardState.closingProjection` — nunca recalculado
  separadamente, sempre derivado do mesmo tick de atingimento.
- `TargetDashboardState` (alterado): novo campo `closingProjection`
  (`ClosingProjectionResult?`), limpo (`clearClosingProjection`) em todo
  lugar onde `progress` também já era limpo (troca de dimensão/período,
  RBAC negado), para nunca mostrar uma projeção de um período diferente do
  que está selecionado.
- `TargetDashboardPage` (alterado): novo card "Projeção de fechamento"
  logo após os KPIs de atingimento — rotulado explicitamente como
  "estimativa", com estilo tipográfico distinto (itálico, cor neutra) do
  valor "Realizado" (headline sólida) para nunca ser confundido com o
  realizado real. Mostra o valor projetado, se está acima/abaixo da meta
  (ícone + cor), o texto de metodologia
  (`ClosingProjectionResult.methodologyDescription`) e um `AppStatusBadge`
  de "Baixa confiabilidade" (quando `isLowConfidence`) ou "Período
  encerrado" (quando `isFinalResult`) — reaproveitando o componente já
  existente do Design System, nenhum componente novo criado.
- `targets.dart` (barrel): novos exports de
  `closing_projection_service.dart`, `projection_strategy.dart` e
  `projection_reliability.dart`.

## Arquivos criados

- `lib/features/targets/domain/value_objects/projection_reliability.dart`
- `lib/features/targets/domain/services/projection_strategy.dart`
- `lib/features/targets/domain/services/closing_projection_service.dart`
- `docs/architecture/closing-projection-methodology.md`
- `test/features/targets/domain/services/closing_projection_service_test.dart`
- `docs/tasks/TASK-119-implementar-projecao-de-fechamento-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/features/targets/presentation/cubit/target_dashboard_cubit.dart` (injeta `ClosingProjectionService`, computa a projeção a cada tick de atingimento)
- `lib/features/targets/presentation/cubit/target_dashboard_state.dart` (novo campo `closingProjection` + `clearClosingProjection`)
- `lib/features/targets/presentation/pages/target_dashboard_page.dart` (novo card `_ClosingProjectionCard`)
- `lib/features/targets/targets.dart` (novos exports)
- `lib/app/injection.config.dart` (gerado pelo `build_runner`, registra `ProjectionStrategy` → `LinearProjectionStrategy`, `ClosingProjectionService` e o novo parâmetro de `TargetDashboardCubit`)
- `test/features/targets/presentation/pages/target_dashboard_page_test.dart` (cubit atualizado para o novo parâmetro; 2 asserções pré-existentes de `Atingimento` restritas ao `AppKpiCard` correto, pois o novo card de projeção também podia conter o mesmo percentual; 3 novos testes de widget: rótulo "estimativa" sempre visível e distinto do "Realizado", flag de baixa confiabilidade, flag de período encerrado)
- `docs/tasks/TASKS.md` (checkbox da TASK-119 e progresso 118/220 → 119/220)

## Validações executadas

- `dart run build_runner build --delete-conflicting-outputs` (duas vezes —
  a primeira gerou uma referência a `ProjectionStrategy` sem nenhum
  provedor registrado, já que só `ClosingProjectionService` estava anotado
  `@injectable`; corrigido anotando `LinearProjectionStrategy` com
  `@Injectable(as: ProjectionStrategy)` e regenerando) — sucesso nas duas
  execuções, sem erros.
- `flutter analyze` (projeto completo) — sem issues.
- `dart format --set-exit-if-changed .` (projeto completo) — sem
  alterações pendentes (1886 arquivos, 0 alterados).
- `flutter test test/features/targets/` — 121 testes, todos passando.
- `flutter test` (suíte completa do projeto) — todos passando (ver
  contagem exata no log da sessão; nenhuma regressão fora de `targets`).

## Decisões e riscos conhecidos

- **A fórmula numérica não mudou, só foi isolada e documentada**:
  `TargetProgressViewModel.projectedValue` (TASK-116) já calculava a mesma
  projeção linear embutida. Esta task extraiu essa fórmula para
  `ProjectionStrategy`/`ClosingProjectionService` — deliberadamente sem
  alterar `TargetProgressViewModel` em si (ele continua sendo a fonte única
  de "realizado" que o gráfico e os KPIs já usam) — para não arriscar
  divergência entre o gráfico existente (que já usa
  `progress.projectedValue`) e o novo card. O teste de consistência
  (`closing_projection_service_test.dart`) prova essa equivalência
  numericamente para múltiplos cenários.
- **Mesma pendência de infraestrutura já registrada em TASK-116/117/118**:
  a projeção depende de `TargetAchievementSnapshot.realizedValue`, que
  ainda não tem nenhuma Cloud Function server-side escrevendo nele em
  produção. Funcionalmente correto e testado, mas hoje renderiza
  majoritariamente com `realizedValue = 0`/`notCalculated` até essa
  pipeline existir.
- **Limiar de baixa confiabilidade fixo em 10%**: valor do próprio enunciado
  da task ("ex.: menos de 10% do período"), exposto como constante pública
  `ClosingProjectionService.lowConfidenceElapsedThreshold` para facilitar
  ajuste futuro sem caçar o número espalhado pelo código.
- **`ProjectionStrategy` tem hoje uma única implementação real**
  (`LinearProjectionStrategy`): a interface existe para não travar a porta
  a metodologias futuras (média móvel ponderada, sazonalidade — ambas
  descritas em `docs/architecture/closing-projection-methodology.md`), mas
  nenhuma delas foi implementada nesta task — fora do escopo pedido.

Nenhum teste, análise ou comando foi apenas assumido: todos os comandos
listados em "Validações executadas" foram executados nesta sessão e
retornaram sucesso.
