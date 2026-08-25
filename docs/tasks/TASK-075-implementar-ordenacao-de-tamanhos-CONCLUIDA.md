# TASK-075 — Concluída (2026-08-25)

## Resumo
A TASK-071 já havia introduzido `SizeGridSize.orderScore` como campo obrigatório e não nulo, além
de um getter `SizeGridTemplate.orderedSizes` que ordena pelo score explícito. Nesta task, o
comparator foi extraído de uma implementação privada duplicada (uma cópia dentro de
`SizeGridTemplate` e outra reimplementada em `normalizeSizeGridSizes`) para um utilitário central
público e único (`compareSizeGridSizesByOrder` + extensão `SizeGridSizeOrdering.sortedByCommercialOrder()`),
eliminando a divergência entre as duas implementações e servindo como ponto único de ordenação
comercial para qualquer tela futura. Foram adicionados testes cobrindo grades alfabéticas,
numéricas e mistas, consistência de ordem entre grade comercial/formulário/persistência, e
regressão para score ausente/inconsistente na camada de dados.

## Agentes utilizados
- `flutter-senior-architect`

## Arquivos criados
- `test/features/products/domain/entities/size_grid_template_test.dart`
- `test/features/products/data/repositories/shared_preferences_size_grid_template_repository_test.dart`
- `docs/tasks/TASK-075-implementar-ordenacao-de-tamanhos-CONCLUIDA.md`

## Arquivos alterados
- `lib/features/products/domain/entities/size_grid_template.dart`
- `lib/features/products/domain/usecases/size_grid_template_use_case_helpers.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first em `features/products`, camada de domínio. Nenhuma mudança de
camada foi necessária: a ordenação já vivia no domínio (entidade `SizeGridTemplate`); o trabalho
desta task foi consolidar a lógica de comparação em um único ponto público reutilizável em vez de
duas implementações privadas idênticas (uma na entidade, outra no use case helper), reduzindo risco
de divergência futura.

## Regras de negócio implementadas
- `compareSizeGridSizesByOrder` é o único comparator de tamanhos: ordena sempre pelo `orderScore`
  explícito e obrigatório, nunca por ordem alfabética como regra primária.
- O label só é usado como critério de desempate determinístico quando dois tamanhos do mesmo
  template compartilham o mesmo score — nunca como substituto de um score ausente.
- `SizeGridTemplate.orderedSizes` (usada por página administrativa de templates, formulário de
  produto e grade comercial) e `normalizeSizeGridSizes` (usada por criação/atualização de template)
  agora delegam ao mesmo comparator central, garantindo ordem idêntica em toda a UI que exibe
  tamanhos para o mesmo template.
- Score ausente ou de tipo inconsistente em dados persistidos continua sendo tratado como erro de
  dado explícito (`ValidationException` com código `invalid_size_grid_template_local_payload`,
  propagado como `AppFailure<UnexpectedFailure>`), nunca "adivinhado" silenciosamente — comportamento
  já existente na TASK-071, agora coberto por teste de regressão dedicado.

## Regras Firebase implementadas
Nenhuma alteração em Firestore Rules, Storage Rules ou Cloud Functions nesta task — mudança restrita
ao domínio Dart/Flutter.

## Analytics implementado
Nenhum evento novo. Nenhum fluxo de analytics existente foi alterado.

## Crashlytics implementado
Sem alteração. Falhas de ordenação/score inconsistente continuam propagadas como `Failure` de
domínio para tratamento pelos BLoCs, sem mudança neste fluxo.

## Impacto offline
Nenhum impacto: a persistência local (SharedPreferences) e sua validação de payload permanecem
inalteradas; apenas a lógica de comparação em memória foi centralizada.

## Impacto multi-tenant
Nenhum impacto: `SizeGridSize.organizationId` e o escopo por `organizationId` já existente não foram
alterados.

## Testes criados
- `size_grid_template_test.dart`: comparator/`sortedByCommercialOrder` cobrindo grade alfabética
  (PP/P/M/G/GG/XGG), grade numérica (34–46), grade mista (P/M/G/G1/G2/G3), desempate por label em
  scores iguais, imutabilidade da lista original, `SizeGridTemplate.orderedSizes` com inserção fora
  de ordem, e um teste de consistência cruzada garantindo que `SizeGridTemplate.orderedSizes`
  (formulário/página administrativa), `CommercialSizeGridState.orderedSizes` (grade comercial) e
  `normalizeSizeGridSizes` (persistência) retornam exatamente a mesma ordem para o mesmo template.
- `shared_preferences_size_grid_template_repository_test.dart`: regressão garantindo que
  `listByOrganization` e `getById` falham explicitamente (nunca ordenam silenciosamente errado)
  quando um tamanho persistido está com `orderScore` ausente ou com tipo inconsistente.

## Comandos executados
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 1183 files, 0 changed.

## Resultado do analyzer
`flutter analyze` passou: No issues found! (ran in 19.7s).

## Resultado dos testes
`flutter test` passou: 1551 testes, All tests passed! (inclui os 8 novos testes desta task).

## Decisões técnicas
- O comparator central foi colocado em `size_grid_template.dart`, arquivo de domínio onde
  `SizeGridSize`/`SizeGridTemplate` já são definidos, evitando import circular e mantendo o
  utilitário no mesmo lugar onde qualquer novo código que precise ordenar tamanhos já precisa
  importar o tipo `SizeGridSize`.
- Foi exposta também uma extensão `List<SizeGridSize>.sortedByCommercialOrder()` para uso ergonômico
  em qualquer tela futura, reduzindo a chance de reimplementação ad-hoc mencionada como risco no
  próprio backlog da task.
- Não foi necessário alterar o tipo de `orderScore` (já `int` obrigatório e não nulo desde a
  TASK-071): a garantia de "nunca ausente" já é imposta pelo compilador Dart no domínio; a única
  fronteira onde um score pode estar "ausente" é a desserialização de JSON persistido, que já
  lançava erro explícito antes desta task e agora tem teste de regressão dedicado.

## Riscos conhecidos
- A tela de "detalhe de produto no catálogo" (grid/detalhe visual do catálogo) ainda não existe no
  código — está prevista nas TASK-076/077/078, ainda pendentes no backlog. Quando essa tela for
  implementada, ela deve obrigatoriamente consumir `SizeGridTemplate.orderedSizes` ou
  `sortedByCommercialOrder()` para permanecer consistente com esta task; isso não pôde ser validado
  por teste automatizado nesta rodada por não existir a tela ainda.
- Backend/regras definitivos de sincronização para templates de grade seguem pendentes (risco já
  registrado na TASK-071), sem relação direta com o escopo desta task.

## Pendências
Nenhuma pendência bloqueante para a TASK-075 dentro do escopo atual do código. O ponto de atenção
sobre a futura tela de detalhe de produto no catálogo está registrado em "Riscos conhecidos" para
ser observado nas TASK-076/077/078.

## Evidências
- `flutter analyze` sem issues.
- `flutter test` com 1551 testes aprovados, incluindo os 8 testes novos desta task (comparator,
  consistência cruzada e regressão de score ausente/inconsistente).

## Commit
Local, a ser preenchido após o commit.

## Push
Não realizado, conforme instrução do usuário (push não autorizado nesta rodada).

## Hash do commit
A ser preenchido após o commit.

## Branch
main
