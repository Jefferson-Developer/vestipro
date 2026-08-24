# TASK-067 — Concluída (2026-08-24)

## Resumo

Implementada a árvore hierárquica configurável de categorias e subcategorias por
organização (EPIC-08), com fonte única de verdade reutilizada tanto no cadastro de
produtos (TASK-065) quanto — futuramente — nos filtros de catálogo (EPIC-10). Antes
desta task, `Product.categoryId`/`subcategoryId` eram preenchidos por texto livre no
formulário, com um aviso explícito de que "telas dedicadas de categoria/subcategoria
chegam em tasks futuras" — confirmando que a task não estava implementada.

Entregue: entidade `Category` com hierarquia (`parentId` opcional, `sortOrder` manual),
validação de ciclo, CRUD administrativo completo (criar/editar/mover/reordenar/excluir),
bloqueio de exclusão insegura (subcategorias vinculadas ou produtos referenciando a
categoria) e integração do formulário de produto com os pickers de categoria/subcategoria
(substituindo os antigos campos de texto livre).

## Agentes utilizados

- `flutter-senior-architect` (arquitetura de domínio/dados, regras de negócio, testes)
- `flutter-ui-design-specialist` (árvore de categorias responsiva, reordenação
  drag-and-drop no Web e ação explícita no mobile, integração no formulário de produto)

## Arquivos criados

- `lib/features/products/domain/entities/category.dart` (+ `category.freezed.dart` gerado)
- `lib/features/products/domain/category_cycle_validator.dart`
- `lib/features/products/domain/repositories/category_repository.dart`
- `lib/features/products/domain/usecases/create_category_use_case.dart`
- `lib/features/products/domain/usecases/update_category_use_case.dart`
- `lib/features/products/domain/usecases/delete_category_use_case.dart`
- `lib/features/products/domain/usecases/list_categories_use_case.dart`
- `lib/features/products/domain/usecases/reorder_categories_use_case.dart`
- `lib/features/products/data/repositories/shared_preferences_category_repository.dart`
- `lib/features/products/presentation/bloc/category_list_event.dart`
- `lib/features/products/presentation/bloc/category_list_state.dart`
- `lib/features/products/presentation/bloc/category_list_bloc.dart`
- `lib/features/products/presentation/bloc/category_form_event.dart`
- `lib/features/products/presentation/bloc/category_form_state.dart`
- `lib/features/products/presentation/bloc/category_form_bloc.dart`
- `lib/features/products/presentation/pages/categories_page.dart`
- `lib/features/products/presentation/pages/category_form_page.dart`
- `test/features/products/domain/category_cycle_validator_test.dart`
- `test/features/products/domain/usecases/create_category_use_case_test.dart`
- `test/features/products/domain/usecases/update_category_use_case_test.dart`
- `test/features/products/domain/usecases/delete_category_use_case_test.dart`
- `test/features/products/domain/usecases/list_categories_use_case_test.dart`
- `test/features/products/domain/usecases/reorder_categories_use_case_test.dart`
- `test/features/products/data/repositories/shared_preferences_category_repository_test.dart`
- `test/features/products/presentation/pages/categories_page_test.dart`
- `test/features/products/category_tree_single_source_of_truth_test.dart`

## Arquivos alterados

- `lib/features/products/data/repositories/shared_preferences_product_repository.dart`
  (sincroniza o índice de uso `category_product_usage_<org>` a cada create/update, para
  `CategoryRepository.hasProducts` bloquear exclusão sem depender diretamente do
  repositório de produto — mesmo padrão já usado entre Season/Collection)
- `lib/features/products/presentation/bloc/product_form_bloc.dart` (injeta
  `ListCategoriesUseCase`, carrega a árvore ao iniciar o formulário)
- `lib/features/products/presentation/bloc/product_form_state.dart` (novo campo
  `categories` + getters `rootCategories`/`subcategoryOptions`)
- `lib/features/products/presentation/pages/product_form_page.dart` (campos de
  categoria/subcategoria trocados de texto livre para `AppDropdown` alimentado pela
  árvore real; seleciona subcategoria limpa ao trocar de categoria)
- `lib/features/products/products.dart` (exporta os novos símbolos públicos)
- `lib/app/injection.config.dart` (gerado por `build_runner`, registra os novos
  `@injectable`/`@LazySingleton`)
- `test/features/products/presentation/bloc/product_form_bloc_test.dart` e
  `test/features/products/presentation/pages/product_form_page_test.dart` (fake
  `_InMemoryCategoryRepository` + parâmetro `listCategories` no `ProductFormBloc`)
- `test/features/products/data/repositories/shared_preferences_product_repository_test.dart`
  (testes do índice de uso categoria↔produto)

## Arquitetura utilizada

Clean/feature-first + BLoC, seguindo exatamente o precedente de `Season`/`Collection`
(TASK-066): entidade Freezed, repositório abstrato + implementação local
`SharedPreferences` (até a sincronização remota/outbox existir), casos de uso isolados
por regra de negócio, e dois BLoCs de apresentação (`CategoryListBloc` para a árvore
administrativa, `CategoryFormBloc` para criar/editar). Nenhum widget acessa
Firestore/Storage/SharedPreferences diretamente — tudo passa pelos casos de uso.

## Regras de negócio implementadas

- Hierarquia com `parentId` opcional (dois níveis usados hoje por categoria/
  subcategoria do Product, estrutura já preparada para N níveis).
- Nome único (case-insensitive, trimmed) apenas entre irmãos do mesmo `parentId` —
  o mesmo nome é permitido em ramos diferentes.
- Validação de ciclo (`CategoryCycleValidator`): uma categoria nunca pode virar
  subcategoria de si mesma nem de um descendente seu; aplicada em toda reparentagem
  (`UpdateCategoryUseCase`).
- Exclusão bloqueada (nunca produto órfão silencioso) quando: (a) a categoria ainda tem
  subcategorias não excluídas (`category_has_children`), ou (b) algum Product ainda
  referencia a categoria como `categoryId`/`subcategoryId` (`category_in_use`).
- Reordenação (`ReorderCategoriesUseCase`) sempre exige o conjunto completo e exato dos
  irmãos daquele nível — nunca reparenta implicitamente; mover para outro pai é sempre a
  ação explícita separada de editar e escolher outra "categoria pai".
- `categoryId` é sempre resolvido do formulário/uso real, nunca aceito como
  autorização vinda do cliente sem passar pelos casos de uso.

## Regras Firebase implementadas

Nenhuma regra nova de Firestore/Storage — a persistência desta task permanece no
armazenamento local (`SharedPreferences`), mesmo racional documentado em
`SharedPreferencesSeasonRepository`/`SharedPreferencesCollectionRepository` (TASK-066):
solução local até a sincronização remota/outbox (EPIC-14) existir. Nenhuma regra de
segurança existente foi enfraquecida.

## Analytics implementado

Nenhum evento de Analytics novo — fora do escopo funcional desta task (CRUD
administrativo de taxonomia), consistente com `SeasonsPage`/`CollectionsPage`.

## Crashlytics implementado

Nenhuma instrumentação nova — os casos de uso retornam `AppResult`/`Failure`
tipados, mesmo padrão do restante do módulo `products`.

## Impacto offline

Compatível: a árvore de categorias vive no mesmo armazenamento local
(`SharedPreferences`) que Season/Collection/Product já usam, sem dependência de rede.
O índice de uso `category_product_usage_<organizationId>` é recalculado a cada
create/update de Product, então o bloqueio de exclusão de categoria funciona também
offline.

## Impacto multi-tenant

A árvore de `Category` é sempre escopada por `organizationId` — `listByOrganization`,
`existsByName`, `hasProducts` e `reorder` nunca misturam categorias de organizações
diferentes (coberto por teste de isolamento no repositório).

## Testes criados

- Unitários de ciclo: `category_cycle_validator_test.dart` (5 casos, incluindo dado
  corrompido pré-existente).
- Casos de uso: `create_category_use_case_test.dart`,
  `update_category_use_case_test.dart` (cobre o bloqueio de ciclo via caso de uso),
  `delete_category_use_case_test.dart` (bloqueio por subcategoria e por produto
  vinculado), `list_categories_use_case_test.dart`, `reorder_categories_use_case_test.dart`
  (rejeita conjunto incompleto/categoria de outro pai).
- Repositório local: `shared_preferences_category_repository_test.dart` +
  extensão de `shared_preferences_product_repository_test.dart` para o índice de uso.
- Widget: `categories_page_test.dart` — estado vazio, estado de erro, árvore
  desktop (expandir/recolher), reordenação mobile via ação explícita
  "mover para cima/baixo" (nunca drag), busca plana com "Subcategoria de: X".
- Integração: `category_tree_single_source_of_truth_test.dart` — comprova que dois
  consumidores independentes do mesmo `ListCategoriesUseCase`/`CategoryRepository`
  (o cadastro de produto e um leitor equivalente ao futuro filtro de catálogo do
  EPIC-10, que ainda não existe no backlog) sempre observam exatamente a mesma árvore,
  inclusive uma categoria criada depois da primeira leitura.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format` reformatou 6 arquivos recém-criados/editados na primeira passada
(quebras de linha); reexecutado sem alterações depois. Saída final:
`Formatted 1062 files (0 changed)` — sem pendências.

## Resultado do analyzer

`flutter analyze` → **No issues found!** (repositório completo).

## Resultado dos testes

`flutter test` (suíte completa do repositório) → **All tests passed!** (1460 testes).
`flutter test test/features/products` isolado → **138 testes**, todos verdes.

## Decisões técnicas

- Reaproveitado exatamente o padrão local-first já estabelecido por
  `SharedPreferencesSeasonRepository`/`SharedPreferencesCollectionRepository`
  (TASK-066) em vez de introduzir Firestore nesta task — mantém consistência com o
  restante do EPIC-08/EPIC-09 (ainda pré-sincronização remota).
- `CategoryRepository.hasProducts` lê um índice de uso mantido pelo
  `SharedPreferencesProductRepository` (mesma técnica de índice desacoplado que já
  liga `Season`↔`Collection`), evitando que o repositório de categoria dependa
  diretamente do repositório de produto.
- Reparentagem (mudar `parentId`) e reordenação (mudar `sortOrder` entre irmãos) foram
  deliberadamente separadas em dois casos de uso distintos — histórico de
  `ReorderCategoriesUseCase` nunca aceita um conjunto de ids fora do nível atual,
  garantindo que um drag no Web ou um toque no mobile jamais reparente uma categoria
  por acidente.
- Na árvore administrativa (`CategoriesPage`), o nível desktop/tablet usa
  `ReorderableListView` (drag-and-drop nativo) e o nível mobile substitui todo o
  conjunto de ações inline por duas setas (mover para cima/baixo) + um menu de
  overflow para "adicionar subcategoria/editar/excluir" — a versão anterior com seis
  ícones lado a lado estourava a largura em telas estreitas (bug encontrado e
  corrigido durante o próprio `flutter test` desta task).
- O teste de integração "catálogo reflete a mesma árvore do cadastro" não pôde
  apontar para uma tela de filtro de catálogo real porque o EPIC-10 (Catálogo Premium)
  ainda é backlog pendente; o teste cobre a garantia arquitetural equivalente —dois
  consumidores independentes do mesmo `CategoryRepository` nunca divergem — e fica
  documentado como ponto de reuso quando o EPIC-10 for implementado.

## Riscos conhecidos

- Sem sincronização remota ainda (por design, mesmo estado que Season/Collection):
  a árvore de categorias não sai do dispositivo até o outbox (EPIC-14) existir.
- `CategoriesPage`/`CategoryFormPage` ainda não estão ligadas ao `app_router.dart` —
  mesmo estado em que `SeasonsPage`/`CollectionsPage` já ficaram após a TASK-066
  (nenhuma dessas telas administrativas de catálogo está roteada ainda); a navegação
  para essas telas fica pendente de uma task de navegação/menu administrativo.
- O filtro de catálogo real (EPIC-10) ainda não existe, então a garantia de "mesma
  árvore reutilizada" está testada no nível de contrato (repositório/caso de uso),
  não numa tela de filtro de fato.

## Pendências

- Nenhuma pendência de implementação desta task específica. A integração visual do
  filtro de catálogo com `Category` acontece quando o EPIC-10 for implementado, e a
  navegação para `CategoriesPage` quando a task de menu administrativo for feita.

## Evidências

- `flutter test` → `All tests passed!` (1460 testes, incluindo os 41 novos/alterados
  desta task).
- `flutter analyze` → `No issues found!`.

## Commit

`feat(products): implement category and subcategory tree`

## Push

Não autorizado nesta rodada — apenas commit local, conforme instrução.

## Hash do commit

Preenchido após o commit (ver resposta final da task).

## Branch

`main`
