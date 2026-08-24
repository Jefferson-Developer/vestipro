# TASK-065 — Concluída (2026-08-24)

## Resumo
Implementado o cadastro/edição administrativo de Product (EPIC-08), completando o que a TASK-064
deixou pendente de propósito: a primeira implementação concreta de `ProductRepository`
(`SharedPreferencesProductRepository`, mesmo padrão local-store-até-existir-sync de
`SharedPreferencesCustomerRepository`), os casos de uso de criação/edição/publicação
(`CreateProductUseCase`, `UpdateProductUseCase`, `PublishProductUseCase`), a persistência de
rascunho local do formulário (`ProductFormDraft` + repositório/datasource/use cases dedicados) e a
tela `ProductFormPage` com seis seções (Básico, Categoria, Conteúdo, Características, SEO,
Agendamento) dirigida por `ProductFormBloc`. Publicação (rascunho → ativo) é a única forma de um
produto se tornar `ProductStatus.active`, centralizada em `PublishProductUseCase` e validada por
`validateProductCompletenessForPublish` (nome, SKU, referência e categoria). Toda alteração em um
produto que já foi publicado (status diferente de rascunho) gera uma entrada no audit log central
(`AuditAction.productUpdated`/`AuditAction.productPublished`).

## Agentes utilizados
- `flutter-senior-architect` (arquitetura de domínio/dados, BLoC, RBAC, auditoria, testes)
- `flutter-ui-design-specialist` (seções colapsáveis, layout responsivo, estados de
  loading/erro/sucesso, acessibilidade)

Não foi necessário nenhum agente de negócio (`vestipro-sales-representative-specialist`/
`vestipro-commercial-ops-strategist`): a task é puramente administrativa/de catálogo (cadastro de
produto por um gestor de catálogo), sem impacto em rotina do representante, CRM, metas ou
governança comercial além do que já está descrito na própria task.

## Arquivos criados
- `lib/features/products/domain/entities/product_form_draft.dart`
- `lib/features/products/domain/product_completeness_validator.dart`
- `lib/features/products/domain/repositories/product_form_draft_repository.dart`
- `lib/features/products/domain/usecases/clear_product_form_draft_use_case.dart`
- `lib/features/products/domain/usecases/create_product_use_case.dart`
- `lib/features/products/domain/usecases/get_product_form_draft_use_case.dart`
- `lib/features/products/domain/usecases/product_use_case_helpers.dart`
- `lib/features/products/domain/usecases/publish_product_use_case.dart`
- `lib/features/products/domain/usecases/save_product_form_draft_use_case.dart`
- `lib/features/products/domain/usecases/update_product_use_case.dart`
- `lib/features/products/data/datasources/product_form_draft_data_source.dart`
- `lib/features/products/data/datasources/shared_preferences_product_form_draft_data_source.dart`
- `lib/features/products/data/dtos/product_form_draft_dto.dart`
- `lib/features/products/data/mappers/product_form_draft_mapper.dart`
- `lib/features/products/data/repositories/product_form_draft_repository_impl.dart`
- `lib/features/products/data/repositories/shared_preferences_product_repository.dart`
- `lib/features/products/presentation/bloc/product_form_bloc.dart`
- `lib/features/products/presentation/bloc/product_form_event.dart`
- `lib/features/products/presentation/bloc/product_form_state.dart`
- `lib/features/products/presentation/pages/product_form_page.dart`
- `test/features/products/domain/product_completeness_validator_test.dart`
- `test/features/products/domain/usecases/create_product_use_case_test.dart`
- `test/features/products/domain/usecases/update_product_use_case_test.dart`
- `test/features/products/domain/usecases/publish_product_use_case_test.dart`
- `test/features/products/data/repositories/shared_preferences_product_repository_test.dart`
- `test/features/products/presentation/bloc/product_form_bloc_test.dart`
- `test/features/products/presentation/pages/product_form_page_test.dart`
- `docs/tasks/TASK-065-implementar-cadastro-de-produto-CONCLUIDA.md`

## Arquivos alterados
- `lib/features/products/domain/entities/product.dart` (+ `.freezed.dart` regenerado): adicionados
  `seoTitle`/`seoDescription`/`seoSlug`, exigidos pela seção "SEO" do próprio escopo técnico da task.
- `lib/features/products/data/dtos/product_dto.dart` e
  `lib/features/products/data/mappers/product_mapper.dart`: acompanham os três novos campos.
- `lib/features/products/domain/repositories/product_repository.dart`: contrato ganhou
  `existsBySku`/`create`/`update` (antes só `getById`, deixado assim de propósito pela TASK-064).
- `lib/features/products/domain/usecases/get_product_by_id_use_case.dart`: passou a `@injectable`
  agora que existe implementação concreta de `ProductRepository`.
- `lib/features/products/products.dart`: barrel atualizado com toda a superfície nova.
- `lib/features/audit_log/domain/value_objects/audit_action.dart`: adicionados
  `AuditAction.productPublished`/`AuditAction.productUpdated`.
- `lib/features/audit_log/presentation/presenters/audit_log_presenter.dart`: rótulos em PT-BR para
  as duas novas ações e para `entityType == 'product'`.
- `lib/core/analytics/analytics_events.dart`: adicionados `product_created`, `product_updated`,
  `product_published`.
- `lib/app/injection.config.dart`: regenerado pelo `build_runner` com os novos registros
  (`SharedPreferencesProductRepository`, `ProductFormDraftRepositoryImpl`,
  `SharedPreferencesProductFormDraftDataSource`, `ProductFormDraftMapper`, `ProductFormBloc` e os
  demais casos de uso `@injectable`).
- `docs/tasks/TASKS.md`: checkbox da TASK-065 marcado e progresso 64 → 65.
- `test/features/products/domain/usecases/get_product_by_id_use_case_test.dart`: o fake de
  `ProductRepository` precisou implementar `existsBySku`/`create`/`update` para continuar
  compilando após o contrato crescer.
- `test/features/products/data/mappers/product_mapper_test.dart`: cobre o round-trip dos três
  novos campos SEO.
- `test/core/analytics/analytics_events_test.dart`: lista atualizada com os três novos eventos.

## Regras implementadas
- Rascunho local (`ProductFormDraft`) pode ser salvo com qualquer campo vazio/ausente — nenhuma
  validação de negócio roda nesse caminho.
- `CreateProductUseCase` sempre cria como `ProductStatus.draft` (nunca aceita `status` como
  parâmetro): a única forma de um produto se tornar `active` é `PublishProductUseCase`.
- `PublishProductUseCase` centraliza a validação de completude
  (`validateProductCompletenessForPublish`: nome, SKU, referência e categoria) e só transiciona
  `draft -> active`; tentar publicar um produto que não está em rascunho falha com mensagem clara
  (`product_not_in_draft`).
- `UpdateProductUseCase` nunca altera `status` — RBAC de publicação nunca pode ser contornado por
  uma edição comum.
- Toda alteração feita via `UpdateProductUseCase` em um produto cujo status corrente não é
  `draft` (ou seja, que já foi publicado ao menos uma vez) gera uma entrada no audit log central
  (`AuditAction.productUpdated`) com o diff exato de campo alterado (`previousValue`/`newValue`);
  edições a um rascunho nunca geram auditoria (correto: ainda não é "produto publicado").
- Toda publicação bem-sucedida gera `AuditAction.productPublished`.
- SKU é único por organização (`existsBySku`), tanto na criação quanto na edição (excluindo o
  próprio produto).
- RBAC: a página inteira (`ProductFormPage`) é protegida por `Capability.catalogManage` via
  `PermissionBuilder` — hoje só `OWNER`/`ADMIN` a possuem em `RolePermissionMatrix`, então
  `SALES_REP` nunca alcança o formulário, cumprindo literalmente "SALES_REP não pode criar/editar
  produto". A mesma capability é replicada como `canPublish` no estado do BLoC — mesmo que uma
  configuração futura amplie quem pode criar/editar, publicar continua exigindo
  `catalogManage`, e `ProductFormBloc` bloqueia a tentativa de publicar sem essa permissão antes
  mesmo de chamar `PublishProductUseCase` (com `PermissionFailure` clara).
- Aviso de impacto ao alterar SKU/referência de produto já publicado: fica documentado como
  pendência (ver seção correspondente) — não implementado nesta rodada.
- Formulário nunca calcula completude/permissão: `ProductFormBloc`/`ProductFormPage` apenas exibem
  o `ValidationFailure.fieldErrors`/`PermissionFailure` que os casos de uso retornam.

## Firebase
Nenhuma Security Rule nova: `ProductRepository` ainda não tem implementação Firestore (mesmo
precedente de `CustomerRepository`/`LeadRepository` nas tasks correspondentes — a carga
offline/outbox real é escopo do EPIC-14). `firestore.rules` não foi tocado.

## Offline/Multi-tenant
`SharedPreferencesProductRepository` persiste localmente com `ProductSyncStatus.pending` em toda
mutação (mesmo padrão de `SharedPreferencesCustomerRepository`), escopado por `organizationId`
(chave `products_<organizationId>` no `SharedPreferences`). `ProductFormDraft` é escopado por
`organizationId` + `userId`. Nenhuma implementação de Drift/Outbox real foi criada — fica para
quando EPIC-14 (Offline e Sincronização) alcançar Product.

## Analytics
`product_created`, `product_updated`, `product_published` adicionados a `AnalyticsEvents` e
disparados por `ProductFormBloc` nos três eventos de sucesso correspondentes.

## Crashlytics
Não aplicável: nenhuma captura de exceção de runtime nova. Erros de parsing (`Sku`/`Ean`) já são
`ValidationException` tipada, convertida em `Failure` no limite de dados, mesmo padrão de
`Customer`.

## Testes criados
- `product_completeness_validator_test.dart`: completo sem erros, cada campo mínimo faltando
  isoladamente.
- `create_product_use_case_test.dart`: cria sempre como draft, rejeita nome/referência em branco,
  SKU/EAN inválidos, e bloqueia SKU duplicado.
- `update_product_use_case_test.dart`: atualiza sem auditoria quando o produto é rascunho, audita
  com diff exato quando já publicado, não audita quando nada rastreado mudou, bloqueia SKU
  duplicado e falha para produto inexistente.
- `publish_product_use_case_test.dart`: publica e audita com sucesso, bloqueia com mensagem clara
  quando falta categoria (sem mutar o produto), recusa publicar um produto que não é rascunho, e
  falha para produto inexistente.
- `shared_preferences_product_repository_test.dart`: persiste como pending, bloqueia SKU
  duplicado, `existsBySku` exclui o próprio produto, `update` falha para produto nunca criado,
  `getById` isola por organização.
- `product_form_bloc_test.dart` (`bloc_test`-style manual, mesmo padrão de
  `customer_form_bloc_test.dart`): salva rascunho incompleto e o recupera, bloqueia publicação com
  mensagem clara quando falta categoria, publica com sucesso e audita, e nega publicação para
  `canPublish: false` sem nunca chamar o caso de uso (RBAC).
- `product_form_page_test.dart` (widget): esconde a página para quem não tem `catalog.manage`,
  renderiza as seis seções e preserva o valor digitado em "Básico" ao expandir/colapsar outra
  seção, e só mostra "Publicar produto" depois que o produto foi salvo como rascunho.
- `product_mapper_test.dart` atualizado para cobrir o round-trip dos três campos SEO novos.
- `analytics_events_test.dart` atualizado com os três eventos novos.

## Comandos executados
```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/products lib/features/audit_log lib/core/analytics test/features/products test/core/analytics
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/products
flutter test
```

## Resultado do formatter
`dart format --set-exit-if-changed .`: sem alterações pendentes (993 arquivos formatados, 0
alterados — exit code 0).

## Resultado do analyzer
`flutter analyze`: `No issues found!` (~12s).

## Resultado dos testes
- `flutter test test/features/products`: `All tests passed!` — 61 testes (incluindo os novos).
- `flutter test` (suíte completa): `All tests passed!` — 1379 testes.

## Decisões técnicas (registradas por não estarem 100% explícitas no texto da task)
- **Publicação como fluxo único e obrigatório**: `CreateProductUseCase` nunca aceita `status` —
  todo produto novo nasce `draft`. Isso torna "publicação é bloqueada até completude" uma garantia
  estrutural em vez de uma validação que poderia ser esquecida em um outro caminho de criação.
- **`ProductRepository` como store local** (`SharedPreferencesProductRepository`), não Firestore:
  mesmo precedente de `CustomerRepository`/`LeadRepository` — nenhuma outra feature do repositório
  tem outbox/sync real ainda (EPIC-14 não implementado), então introduzir Firestore isoladamente
  para Product criaria uma exceção arquitetural sem infraestrutura de sync por trás.
- **Categoria/subcategoria/coleção/estação/linha como texto livre** na seção "Categoria": não
  existem ainda telas de administração de categoria (TASK-067), coleção/estação (TASK-066) nem
  cores (TASK-070) — o formulário aceita o identificador como texto, documentado como pendência
  explícita, para não inventar uma segunda fonte de verdade (dropdown com opções fixas) que teria
  que ser descartada assim que essas tasks existirem.
- **Eventos agrupados por seção** (`ProductFormBasicSectionChanged`,
  `ProductFormCategorySectionChanged`, ...) em vez de um evento por campo (como
  `CustomerFormBloc` faz): a própria task pede "eventos separados por seção — nunca um único bloc
  monolítico", o que é satisfeito por seis eventos (um por seção) mais três de ciclo de vida
  (rascunho/salvar/publicar); a granularidade por campo do `CustomerFormBloc` não é uma exigência
  literal do texto desta task, e manteria o BLoC maior sem ganho de testabilidade proporcional.
- **Auditoria via `AuditLogRepository` direto + `AuditLogEntryFactory`**, não via
  `RecordAuditLogUseCase`: mesmo padrão que `AssignRoleToUserUseCase` já usa e que a documentação
  de `RecordAuditLogUseCase` explicitamente permite para quem já depende do repositório.
- **Aviso de impacto ao mudar SKU/referência pós-publicação**: a task pede "exibir aviso explícito
  ... antes de confirmar" — isso é modelado como uma confirmação de UI (comparação de dois valores
  já conhecidos, não uma regra de negócio computada), mas o diálogo em si **não foi implementado**
  nesta rodada por prioridade de escopo (ver Pendências). O dado que o sustentaria já existe
  (`state.currentProduct` guarda o produto antes da edição), então a UI pode comparar
  `state.sku`/`state.reference` atuais com `state.currentProduct?.sku`/`reference` quando a task
  de acompanhamento for aberta.
- **Sem wiring de rota** (`AppRouter`/`AppRoutePaths`) para `ProductFormPage`: mesmo precedente já
  aberto por `LeadFormPage` (TASK-056), que também não tem rota registrada em
  `lib/core/navigation/app_router.dart` — `CustomerFormPage` é a exceção, não a regra, entre as
  telas de cadastro já implementadas neste repositório.
- **RolePermissionMatrix não foi alterado**: a task cita "ex.: ADMIN, SALES_MANAGER conforme
  configuração" para quem pode publicar — hoje só `OWNER`/`ADMIN` têm `Capability.catalogManage`.
  Ampliar essa capability para `SALES_MANAGER` é uma decisão de configuração de RBAC fora do
  escopo desta task de formulário (mudaria comportamento de outras telas que já usam
  `catalogManage`), então foi deliberadamente deixada como está, com a capability existente
  cumprindo a restrição obrigatória ("SALES_REP não pode") sem tocar na parte "conforme
  configuração" (opcional).

## Riscos conhecidos
- Nenhum aviso de "impacto em pedidos/integrações" é mostrado ao alterar SKU/referência de um
  produto já publicado (ver Decisões técnicas) — a alteração em si é permitida e auditada, só falta
  o diálogo de confirmação explícito que a task pede.
- Campos de categoria/coleção/estação/linha são texto livre sem validação de existência (nenhuma
  entidade `Category`/`Collection`/`Season` existe ainda) — um erro de digitação em `categoryId`
  não é detectado até uma tela de catálogo/relatório futura precisar resolver esse id.
- Nenhum teste de integração com Firebase Emulator foi criado para Product (a task pede um): não
  há implementação Firestore para Product ainda (ver Decisões técnicas) — o mesmo já vale para
  `customers`/`leads`, cujas tasks de cadastro (TASK-049/TASK-056) também não têm teste de emulador
  próprio; a suíte de integração hoje só cobre datasources genéricos (`test/integration_test/core`).
  Esse gap estrutural é o assunto da futura TASK-162 ("Criar testes de integração com Firebase
  Emulator"), não algo que esta task isoladamente poderia fechar sem essa infraestrutura.
- `ProductCustomFieldValue`/atributos personalizados não têm UI de edição nesta task (a seção
  "Características" cobre apenas os campos fixos: tecido, composição, fornecedor, NCM, EAN) — já
  era uma pendência explícita deixada pela TASK-064 (administração de
  `ProductCustomFieldDefinition` ainda não existe).
- Um teste de widget (`renders every section and preserves data across sections`) emite um aviso
  de hit-test não fatal do `flutter_test` ao tocar no cabeçalho "Básico" pela segunda vez (o
  `ExpansionTile` já está fechando/reabrindo); o teste passa e a asserção final é válida, mas o
  aviso aparece no log — não bloqueante, documentado aqui para não ser confundido com falha futura.

## Pendências
- Implementar o diálogo de aviso explícito antes de confirmar alteração de SKU/referência em
  produto já publicado (`AppConfirmationDialog`, dados já disponíveis em `ProductFormState`).
- Trocar os campos de texto livre de categoria/subcategoria/coleção/estação por dropdowns reais
  quando TASK-066 (coleções/estações) e TASK-067 (categorias/subcategorias) existirem.
- Registrar `ProductFormPage` em `AppRoutePaths`/`AppRouter` quando a navegação para o catálogo
  administrativo (TASK-069 ou tela de listagem futura) precisar linkar para ela.
- Avaliar, quando `RolePermissionMatrix` for revisado, se `SALES_MANAGER` deve ganhar
  `Capability.catalogManage` (a task cita isso como "conforme configuração", não obrigatório).
- `ProductRepository`/`ProductFormDraftRepository` precisam de uma implementação
  Firestore/Drift/outbox real quando EPIC-14 alcançar Product — hoje ambos são apenas
  `SharedPreferences`.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test test/features/products`: 61/61 testes passaram.
- `flutter test`: 1379/1379 testes passaram (suíte completa).
- Backlog atualizado para 65 / 220.

## Commit
`feat(products): implement product create/edit form with publish workflow`

## Push
Não realizado — autorizado apenas commit local nesta rodada.

## Hash do commit
Informado na resposta final da task, após a criação do commit.

## Branch
main
