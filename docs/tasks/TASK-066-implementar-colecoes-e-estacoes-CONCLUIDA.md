# TASK-066 — Concluída (2026-08-24)

## Resumo
Implementada a organização de produtos por calendário de moda (EPIC-08): as entidades `Season`
(vocabulário de estação, único por nome dentro da organização) e `Collection` (nome, estação, ano,
período, status ativa/encerrada), CRUD administrativo completo para ambas (`SeasonsPage`/
`CollectionsPage`, reaproveitando `AppAdminPageLayout`/`AppDataTable`/`AppBottomSheet` do Design
System, mesmo padrão de `TeamListPage`/`TeamFormPage`), e a associação produto-coleção via um
registro de junção dedicado (`ProductCollectionLink`) que suporta N:N quando a organização
configurar `OrganizationSettings.allowMultipleCollectionsPerProduct = true` — e substitui a
associação anterior automaticamente (nunca silenciosamente) quando a organização não permitir
múltiplas coleções por produto. `ListCollectionsUseCase`/`ListSeasonsUseCase`/
`ListProductsByCollectionUseCase` são a mesma fonte de dados que o futuro filtro de catálogo
(EPIC-10) deverá reutilizar, evitando duplicar a taxonomia entre cadastro e vitrine.

## Agentes utilizados
- `flutter-senior-architect` (entidades, repositórios, casos de uso, regra de associação N:N
  configurável, flag em `OrganizationSettings`, testes de domínio/dados/bloc)
- `flutter-ui-design-specialist` (telas de gestão de coleções/estações reaproveitando componentes
  administrativos existentes, estados de loading/vazio/erro, formulário responsivo)

Não foi necessário nenhum agente de negócio (`vestipro-sales-representative-specialist`/
`vestipro-commercial-ops-strategist`): a task é administrativa/de catálogo (taxonomia de produto
mantida por um gestor de catálogo), sem impacto direto em rotina do representante, CRM, metas ou
governança comercial além do que já está descrito na própria task.

## Arquivos criados
- `lib/features/products/domain/value_objects/collection_status.dart`
- `lib/features/products/domain/entities/season.dart` (+ `.freezed.dart` gerado)
- `lib/features/products/domain/entities/collection.dart` (+ `.freezed.dart` gerado)
- `lib/features/products/domain/entities/product_collection_link.dart` (+ `.freezed.dart` gerado)
- `lib/features/products/domain/repositories/season_repository.dart`
- `lib/features/products/domain/repositories/collection_repository.dart`
- `lib/features/products/domain/repositories/product_collection_link_repository.dart`
- `lib/features/products/domain/usecases/create_season_use_case.dart`
- `lib/features/products/domain/usecases/update_season_use_case.dart`
- `lib/features/products/domain/usecases/delete_season_use_case.dart`
- `lib/features/products/domain/usecases/list_seasons_use_case.dart`
- `lib/features/products/domain/usecases/create_collection_use_case.dart`
- `lib/features/products/domain/usecases/update_collection_use_case.dart`
- `lib/features/products/domain/usecases/close_collection_use_case.dart`
- `lib/features/products/domain/usecases/list_collections_use_case.dart`
- `lib/features/products/domain/usecases/associate_product_with_collection_use_case.dart`
- `lib/features/products/domain/usecases/disassociate_product_from_collection_use_case.dart`
- `lib/features/products/domain/usecases/list_products_by_collection_use_case.dart`
- `lib/features/products/data/repositories/shared_preferences_season_repository.dart`
- `lib/features/products/data/repositories/shared_preferences_collection_repository.dart`
- `lib/features/products/data/repositories/shared_preferences_product_collection_link_repository.dart`
- `lib/features/products/presentation/bloc/season_list_bloc.dart` (+ `_event.dart`/`_state.dart`)
- `lib/features/products/presentation/bloc/season_form_bloc.dart` (+ `_event.dart`/`_state.dart`)
- `lib/features/products/presentation/bloc/collection_list_bloc.dart` (+ `_event.dart`/`_state.dart`)
- `lib/features/products/presentation/bloc/collection_form_bloc.dart` (+ `_event.dart`/`_state.dart`)
- `lib/features/products/presentation/pages/seasons_page.dart`
- `lib/features/products/presentation/pages/season_form_page.dart`
- `lib/features/products/presentation/pages/collections_page.dart`
- `lib/features/products/presentation/pages/collection_form_page.dart`
- `test/features/products/domain/usecases/create_season_use_case_test.dart`
- `test/features/products/domain/usecases/delete_season_use_case_test.dart`
- `test/features/products/domain/usecases/create_collection_use_case_test.dart`
- `test/features/products/domain/usecases/close_collection_use_case_test.dart`
- `test/features/products/domain/usecases/associate_product_with_collection_use_case_test.dart`
- `test/features/products/domain/usecases/list_products_by_collection_use_case_test.dart`
- `test/features/products/data/repositories/shared_preferences_season_repository_test.dart`
- `test/features/products/data/repositories/shared_preferences_collection_repository_test.dart`
- `test/features/products/presentation/bloc/collection_form_bloc_test.dart`
- `test/features/products/presentation/bloc/collection_list_bloc_test.dart`
- `test/features/products/presentation/pages/collections_page_test.dart`
- `docs/tasks/TASK-066-implementar-colecoes-e-estacoes-CONCLUIDA.md`

## Arquivos alterados
- `lib/features/products/domain/repositories/product_repository.dart`: contrato ganhou `getByIds`
  (batch, usado por `ListProductsByCollectionUseCase`).
- `lib/features/products/data/repositories/shared_preferences_product_repository.dart`: implementa
  `getByIds`.
- `lib/features/products/products.dart`: barrel atualizado com toda a superfície nova de
  coleção/estação/associação.
- `lib/features/organizations/domain/value_objects/organization_settings.dart` (+ `.freezed.dart`
  regenerado): novo campo `allowMultipleCollectionsPerProduct` (padrão `false`), com suporte em
  `OrganizationSettings.validated`.
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`: acompanha o novo campo
  (omitido do JSON quando `false`, mesmo padrão de omissão de valores default já usado para
  `segment`/`maxTeamsPerUser`).
- `lib/features/organizations/data/mappers/organization_mapper.dart`: `settingsToEntity`/
  `settingsToDto` passam o novo campo nos dois sentidos.
- `lib/features/organizations/domain/usecases/update_organization_settings_use_case.dart`: novo
  parâmetro opcional `allowMultipleCollectionsPerProduct` (padrão `false`), mesmo padrão dos demais
  parâmetros opcionais já existentes.
- `lib/app/injection.config.dart`: regenerado pelo `build_runner` com os novos registros
  (`SharedPreferencesSeasonRepository`, `SharedPreferencesCollectionRepository`,
  `SharedPreferencesProductCollectionLinkRepository`, os novos casos de uso `@injectable` e os
  quatro novos BLoCs).
- `test/features/products/domain/usecases/{create_product,update_product,publish_product,
  get_product_by_id}_use_case_test.dart`, `test/features/products/presentation/bloc/
  product_form_bloc_test.dart`, `test/features/products/presentation/pages/
  product_form_page_test.dart`: os fakes de `ProductRepository` precisaram implementar `getByIds`
  para continuar compilando após o contrato crescer (mesma situação que TASK-065 já havia deixado
  documentada para `existsBySku`/`create`/`update`).
- `test/features/organizations/data/mappers/organization_mapper_test.dart` e
  `test/features/organizations/domain/value_objects/organization_settings_test.dart`: cobertura do
  novo campo `allowMultipleCollectionsPerProduct` (round-trip no mapper, default e valor explícito
  na validação).
- `docs/tasks/TASKS.md`: checkbox da TASK-066 marcado e progresso 65 → 66.

Os dois arquivos `assets/images/unboxing_tiktok_*.mp4` (fora de escopo, deixados por uma rodada
anterior) não foram tocados nem adicionados ao commit.

## Arquitetura utilizada
Clean/feature-first, dentro de `lib/features/products/` (mesma feature de `Product`, já que
`Collection`/`Season` se associam diretamente a ele e ainda não existe uma feature "catalog"
separada). `Presentation -> BLoC -> Use case -> Repository (contrato) -> Repository impl
(SharedPreferences)`, mesmo padrão local-store-até-existir-sync que `SharedPreferencesProductRepository`/
`SharedPreferencesCustomerRepository` já estabeleceram (TASK-048/049, TASK-065). A associação
produto-coleção é modelada como um registro de junção próprio (`ProductCollectionLink`), não como
uma lista dentro de `Product`, para não alterar a entidade `Product` já testada e para generalizar
naturalmente o caso N:N sem precisar de duas fontes de verdade (campo único vs. lista) dentro da
mesma entidade.

## Regras de negócio implementadas
- Coleção pertence a exatamente uma organização (`organizationId` imutável, nunca vindo de outro
  tenant no repositório local).
- `CreateCollectionUseCase` sempre cria como `CollectionStatus.active`; a única forma de encerrar é
  `CloseCollectionUseCase` (idempotente: fechar uma coleção já encerrada não gera nova escrita).
  Encerrar uma coleção nunca apaga produtos nem os links já existentes — apenas passa a rejeitar
  *novas* associações (`AssociateProductWithCollectionUseCase` recusa associar a uma coleção
  encerrada com `ConflictFailure`/`collection_closed`).
- `UpdateCollectionUseCase` nunca altera `status` — fechar/reabrir é decisão exclusiva de
  `CloseCollectionUseCase`.
- Estação é vocabulário único por organização: `CreateSeasonUseCase`/`UpdateSeasonUseCase` rejeitam
  nomes equivalentes (trim + case-insensitive) com `ConflictFailure`/`season_name_already_exists`.
- `DeleteSeasonUseCase` bloqueia a exclusão quando qualquer coleção não excluída ainda referencia a
  estação (`SeasonRepository.hasCollections`), evitando referência órfã — mesmo espírito do guard
  `hasCommercialLinks` de `DeleteTeamUseCase`.
- Associação produto-coleção N:N controlada por
  `OrganizationSettings.allowMultipleCollectionsPerProduct` (padrão `false`), resolvida pelo
  chamador e passada explicitamente a `AssociateProductWithCollectionUseCase` (o caso de uso não
  depende do repositório de organizações):
  - `false`: uma nova associação remove automaticamente qualquer vínculo anterior do produto antes
    de criar o novo — comportamento explícito e documentado, nunca silencioso, exatamente como a
    task pede.
  - `true`: vínculos anteriores são preservados e o novo é adicionado ao lado deles (N:N);
    associar o mesmo par produto+coleção duas vezes é rejeitado como conflito
    (`product_collection_link_already_exists`) em vez de duplicar o link.
- `ListProductsByCollectionUseCase` lê exclusivamente da junção `ProductCollectionLink` — a mesma
  fonte que qualquer filtro futuro de catálogo (EPIC-10) deverá reutilizar, para nunca duplicar a
  taxonomia entre cadastro e vitrine.

## Regras Firebase implementadas
Nenhuma: `Season`/`Collection`/`ProductCollectionLink` ainda não têm implementação Firestore, pelo
mesmo motivo documentado em TASK-064/065 — `ProductRepository` (e agora os três repositórios novos)
seguem o precedente `SharedPreferences` local-até-existir-outbox, já que a carga offline/outbox real
é escopo do EPIC-14. `firestore.rules` não foi tocado.

## Analytics implementado
Nenhum evento novo em `AnalyticsEvents`: a task não pede analytics específico de coleção/estação, e
não introduzir eventos especulativos evita inflar a taxonomia sem consumidor real (mesma régua já
aplicada a outras tasks administrativas puras, como TASK-070+ ainda não implementadas). Fica como
pendência caso um evento `collection_created`/`collection_closed` seja necessário quando o BI de
catálogo (EPIC-17/18) existir.

## Crashlytics implementado
Não aplicável: nenhuma captura de exceção de runtime nova. Erros de validação já são
`ValidationException` tipada, convertida em `Failure` no limite de dados, mesmo padrão de
`Product`/`Team`.

## Impacto offline
`SharedPreferencesSeasonRepository`/`SharedPreferencesCollectionRepository`/
`SharedPreferencesProductCollectionLinkRepository` persistem localmente, escopados por
`organizationId` (chaves `seasons_<organizationId>`, `collections_<organizationId>`,
`product_collection_links_<organizationId>`). Nenhuma sincronização real (Drift/Outbox) foi
adicionada — mesma pendência estrutural já registrada para `Product`/`Customer`, a ser resolvida
quando o EPIC-14 alcançar essas entidades.

## Impacto multi-tenant
Toda leitura/escrita exige `organizationId` explícito nos contratos de repositório; nenhuma consulta
pode ser construída sem escopo de tenant por acidente (mesmo padrão defensivo de `TeamRepository`).
Como ainda não há Firestore Security Rules para essas coleções, o isolamento real por tenant
continua dependendo inteiramente do armazenamento local por chave — a mesma limitação que já existe
para `Product`/`Customer` até a migração para Firestore.

## Testes criados
- `create_season_use_case_test.dart`: cria com nome trimado, rejeita nome em branco, bloqueia nome
  duplicado (case-insensitive).
- `delete_season_use_case_test.dart`: soft-delete sem uso, bloqueia quando uma coleção referencia a
  estação.
- `create_collection_use_case_test.dart`: sempre cria ativa, rejeita nome em branco, rejeita data de
  término antes do início, rejeita ano fora do intervalo.
- `close_collection_use_case_test.dart`: fecha uma coleção ativa, é idempotente para uma já
  encerrada, falha para coleção inexistente.
- `associate_product_with_collection_use_case_test.dart`: modo single substitui o vínculo anterior;
  modo múltiplo preserva vínculos e adiciona um novo (N:N); modo múltiplo rejeita associar o mesmo
  par duas vezes; rejeita associar a uma coleção encerrada; falha para coleção inexistente — cobre
  diretamente o critério de aceite "regra de associação única/múltipla configurável por organização
  implementada e testada".
- `list_products_by_collection_use_case_test.dart`: retorna os produtos vinculados, inclui o caso em
  que a coleção foi encerrada e o produto continua listável (não removido/oculto pela junção) e
  retorna lista vazia sem consultar produtos quando não há vínculos.
- `shared_preferences_season_repository_test.dart` e
  `shared_preferences_collection_repository_test.dart`: persistência local, unicidade de nome de
  estação, soft-delete, isolamento por organização, e que criar uma coleção com `seasonId` marca a
  estação como em uso (`hasCollections`).
- `collection_form_bloc_test.dart`: cria uma coleção nova com estação selecionada, rejeita submissão
  sem nome, edita uma coleção existente preservando o status — cobre "criar" e "editar" do
  `bloc_test` pedido pela task.
- `collection_list_bloc_test.dart`: carrega as coleções da organização, encerra uma coleção ativa e
  reflete o novo status sem recarregar tudo, reporta falha de carregamento — cobre "encerrar".
- `collections_page_test.dart` (widget): estado vazio (nenhuma coleção), estado de erro (falha ao
  carregar) e estado de sucesso (lista com coleção ativa) — cobre exatamente os três estados pedidos
  pela task.
- `get_product_by_id_use_case_test.dart` e os demais testes de `ProductRepository` fake foram
  atualizados com `getByIds` para continuar compilando.
- `organization_mapper_test.dart`/`organization_settings_test.dart`: cobertura do novo campo
  `allowMultipleCollectionsPerProduct`.

## Comandos executados
```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/products lib/features/organizations test/features/products test/features/organizations
dart format lib test
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/products test/features/organizations
flutter test
```

## Resultado do formatter
`dart format --set-exit-if-changed .`: sem alterações pendentes (1044 arquivos formatados, 0
alterados — exit code 0).

## Resultado do analyzer
`flutter analyze`: `No issues found!` (~12s).

## Resultado dos testes
- `flutter test test/features/products test/features/organizations`: `All tests passed!` — 307
  testes.
- `flutter test` (suíte completa): `All tests passed!` — 1422 testes.

## Decisões técnicas
- **Associação como registro de junção (`ProductCollectionLink`), não campo em `Product`**: a task
  pede suporte a N:N configurável. Em vez de transformar `Product.collectionId` (campo único já
  existente, usado pelo formulário de produto da TASK-065) em uma lista — o que exigiria alterar a
  entidade `Product` já testada e sua serialização local — a associação real é modelada em uma
  entidade própria. `Product.collectionId` continua existindo como referência denormalizada
  definida pelo próprio formulário de produto (texto livre, decisão já registrada na TASK-065); a
  reconciliação entre os dois fica documentada como pendência.
- **Flag de configuração em `OrganizationSettings`, não em um objeto novo**: `OrganizationSettings`
  já é o lugar onde a organização guarda preferências de configuração opcionais
  (`maxTeamsPerUser`, `requiredCustomerFields`, ...), então adicionar
  `allowMultipleCollectionsPerProduct` ali segue o padrão existente em vez de criar uma segunda
  fonte de configuração. Nenhuma tela de configurações dedicada existe hoje para editar esse
  campo (o mesmo já vale para `maxTeamsPerUser`) — fica como pendência.
- **`AssociateProductWithCollectionUseCase` recebe o flag como parâmetro explícito**: o caso de uso
  não lê `OrganizationRepository` diretamente, mantendo-o desacoplado da feature `organizations` e
  100% testável com um repositório fake simples; o chamador (BLoC/tela futura) é responsável por
  resolver `organization.settings.allowMultipleCollectionsPerProduct` antes de chamar.
- **Remover vínculo anterior em vez de bloquear no modo single**: a task oferece as duas opções
  ("remover automaticamente ou bloquear... comportamento explícito, nunca silencioso"); optei por
  remover automaticamente por ser o comportamento mais útil para o fluxo comercial (reassociar um
  produto contínuo a uma nova coleção sem exigir uma etapa extra de "desassociar primeiro").
- **Sem tela combinada de coleções+estações**: implementei duas páginas administrativas irmãs
  (`CollectionsPage`, `SeasonsPage``) em vez de uma única tela com abas, para manter cada BLoC/tela
  simples e no mesmo padrão comprovado de `TeamListPage`/`TeamFormPage`, em vez de introduzir um
  componente de abas novo sem precedente no Design System atual.
- **Sem wiring de rota** (`AppRouter`/`AppRoutePaths`): mesmo precedente já aberto por
  `ProductFormPage`/`TeamListPage` (nenhuma delas está registrada em
  `lib/core/navigation/app_router.dart`).
- **Sem auditoria (`AuditLogRepository`)**: `Collection`/`Season` são taxonomia administrativa, não
  uma das operações "críticas" que `AGENTS.md` exige auditar (autorização, preço, número de pedido,
  aprovação); `DeleteTeamUseCase`, referência usada como guia, também não audita hoje. Fica como
  possível evolução futura, não como lacuna desta task.

## Riscos conhecidos
- `Product.collectionId`/`Product.seasonId` (campos livres definidos pelo formulário de produto,
  TASK-065) não são sincronizados automaticamente com `ProductCollectionLink` — um produto pode ter
  um `collectionId` de texto livre que não corresponde a nenhum vínculo real na junção até que o
  formulário de produto seja atualizado para usar os novos casos de uso (ver Pendências).
- Nenhuma implementação Firestore/Security Rules para as três novas coleções (`seasons`,
  `collections`, o equivalente de `productCollectionLinks`) — mesmo gap estrutural já existente para
  `Product`/`Customer`, a ser fechado quando o EPIC-14 alcançar essas entidades.
- `OrganizationSettings.allowMultipleCollectionsPerProduct` não tem UI de configuração própria —
  só pode ser alterado programaticamente via `UpdateOrganizationSettingsUseCase` até que exista uma
  tela de configurações administrativas (mesma limitação já existente para `maxTeamsPerUser`).

## Pendências
- Trocar os campos de texto livre "Coleção"/"Estação" do `ProductFormPage` (TASK-065) por
  dropdowns reais usando `ListCollectionsUseCase`/`ListSeasonsUseCase`, e conectar o botão de
  salvar à associação real via `AssociateProductWithCollectionUseCase` — item já era uma pendência
  explícita deixada pela TASK-065, agora desbloqueado.
- Implementar o filtro de catálogo por coleção/estação (EPIC-10, ainda não iniciado) reutilizando
  `ListCollectionsUseCase`/`ListSeasonsUseCase`/`ListProductsByCollectionUseCase`.
- Adicionar uma UI de configuração para `OrganizationSettings.allowMultipleCollectionsPerProduct`
  quando a tela de configurações administrativas existir.
- Avaliar se `Collection`/`Season` precisam de auditoria central (`AuditLogRepository`) quando a
  governança de catálogo evoluir.
- Registrar `CollectionsPage`/`SeasonsPage` em `AppRoutePaths`/`AppRouter` quando a navegação do
  catálogo administrativo (TASK-069 ou tela de listagem futura) precisar linkar para elas.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test test/features/products test/features/organizations`: 307/307 testes passaram.
- `flutter test`: 1422/1422 testes passaram (suíte completa).
- Backlog atualizado para 66 / 220.

## Commit
`feat(products): implement collections and seasons management`

## Push
Não realizado — autorizado apenas commit local nesta rodada.

## Hash do commit
Informado na resposta final da task, após a criação do commit.

## Branch
main
