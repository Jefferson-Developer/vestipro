# TASK-080 — Concluída (2026-08-26)

## Resumo

Implementado o CRUD administrativo completo de `CatalogCampaign` (título, subtítulo, texto
editorial, imagem de capa, imagens editoriais reordenáveis, produtos relacionados, período de
vigência e status ativo/inativo) e a tela pública de lookbook que consome esses dados — a
narrativa visual por coleção/campanha (EPIC-10) que TASK-076 já havia modelado como leitura
apenas ("campanhas em destaque" na home) e deixou explicitamente para esta task ("TASK-080: CRUD
real de `CatalogCampaign`, hoje só leitura").

Toda a persistência é orientada a dados (`SharedPreferences`, seguindo o mesmo padrão
local-first já usado por `Collection`/`Product`/`CatalogCampaign` desde TASK-065/066/076 — ver
"Decisões técnicas"), nenhuma campanha é hardcoded no app, e a vigência é resolvida no momento da
leitura (`CatalogCampaign.statusAt`), então uma campanha expira/inicia sem exigir refresh manual
do cliente nem novo deploy.

## Agentes utilizados

- `flutter-senior-architect` (domínio: `CatalogCampaign` estendido, `CatalogCampaignStatus`,
  contrato de escrita do repositório, 6 use cases novos, implementação local, integração com
  `StorageDataSource`/`ImageUploadCompressor` já existentes, RBAC via `Capability.catalogManage`
  já existente, analytics, testes).
- `flutter-ui-design-specialist` (tela administrativa `CampaignsPage`/`CampaignFormPage` com
  upload/reordenação de imagem e seleção de produtos relacionados reaproveitando
  `ProductSearchPage`; tela pública `LookbookPage` com layout editorial responsivo mobile/tablet/
  desktop reaproveitando `AppProductCarousel`/`AppProductCardData`).

## Arquivos criados

Domínio (`lib/features/catalog/domain`):
- `value_objects/catalog_campaign_status.dart`
- `usecases/campaign_use_case_validation.dart`
- `usecases/create_campaign_use_case.dart`
- `usecases/update_campaign_use_case.dart`
- `usecases/delete_campaign_use_case.dart`
- `usecases/get_campaign_use_case.dart`
- `usecases/list_campaigns_use_case.dart`
- `usecases/list_campaign_related_products_use_case.dart`

Apresentação (`lib/features/catalog/presentation`):
- `widgets/campaign_status_badge.dart`
- `bloc/campaign_list_event.dart`, `bloc/campaign_list_state.dart`, `bloc/campaign_list_bloc.dart`
- `bloc/campaign_form_event.dart`, `bloc/campaign_form_state.dart`, `bloc/campaign_form_bloc.dart`
- `bloc/lookbook_event.dart`, `bloc/lookbook_state.dart`, `bloc/lookbook_bloc.dart`
- `pages/campaigns_page.dart` (admin, lista)
- `pages/campaign_form_page.dart` (admin, criar/editar)
- `pages/lookbook_page.dart` (pública, consumo do lookbook)

Testes novos:
- `test/features/catalog/domain/usecases/create_campaign_use_case_test.dart`
- `test/features/catalog/domain/usecases/update_campaign_use_case_test.dart`
- `test/features/catalog/domain/usecases/delete_campaign_use_case_test.dart`
- `test/features/catalog/domain/usecases/get_campaign_use_case_test.dart`
- `test/features/catalog/domain/usecases/list_campaigns_use_case_test.dart`
- `test/features/catalog/domain/usecases/list_campaign_related_products_use_case_test.dart`
- `test/features/catalog/presentation/bloc/campaign_list_bloc_test.dart`
- `test/features/catalog/presentation/bloc/campaign_form_bloc_test.dart`
- `test/features/catalog/presentation/bloc/lookbook_bloc_test.dart`
- `test/features/catalog/presentation/pages/campaigns_page_test.dart`
- `test/features/catalog/presentation/pages/campaign_form_page_test.dart`
- `test/features/catalog/presentation/pages/lookbook_page_test.dart`

## Arquivos alterados

- `lib/features/catalog/domain/entities/catalog_campaign.dart` (+ `.freezed.dart` gerado):
  campos `description`, `editorialImageUrls`, `relatedProductIds`; `statusAt(now)` (novo, fonte
  única de status) com `isVisibleAt` reescrito em termos dele — comportamento idêntico ao já
  testado por TASK-076, sem quebrar contrato.
- `lib/features/catalog/domain/repositories/catalog_campaign_repository.dart`: adicionados
  `getById`/`create`/`update`/`delete` (aditivo, mesmo precedente incremental
  `CollectionRepository` TASK-064→065 já seguiu).
- `lib/features/catalog/data/repositories/shared_preferences_catalog_campaign_repository.dart`:
  implementa os 4 novos métodos do contrato.
- `lib/features/catalog/catalog.dart`: exporta os novos domínios/blocs/páginas/widget.
- `lib/core/storage/storage_paths.dart`: novo `StoragePaths.campaignFile` (mesma convenção de
  `productFile`, pasta `campaigns/{campaignId}/`).
- `lib/core/analytics/analytics_events.dart`: novos `campaignViewed` (`campaign_viewed`) e
  `campaignProductClicked` (`campaign_product_clicked`).
- `lib/app/injection.config.dart`: gerado por `build_runner` (DI dos novos tipos `@injectable`).
- `test/features/catalog/catalog_test_fakes.dart`: `FakeCatalogCampaignRepository` estendido com
  os 4 novos métodos (implementações que lançam `UnimplementedError`, mesmo padrão de
  `FakeCollectionRepository`); novas classes reutilizáveis
  `InMemoryCatalogCampaignRepository`/`InMemoryCatalogProductRepository`, usadas pelos 12 novos
  arquivos de teste (evita redefinir o mesmo fake em cada um).
- `test/features/catalog/domain/usecases/get_catalog_campaigns_section_use_case_test.dart`: seu
  `_FakeRepository` local também implementa os 4 novos métodos do contrato.
- `test/features/catalog/domain/entities/catalog_campaign_test.dart`: novo grupo
  `CatalogCampaign.statusAt` (ativa/agendada/expirada/inativa).
- `test/features/catalog/data/repositories/shared_preferences_catalog_campaign_repository_test.dart`:
  novos testes de `create`/`update`/`getById`/`delete` (round-trip, not-found, soft-delete).
- `test/core/analytics/analytics_events_test.dart`: taxonomia atualizada com os 2 novos eventos.
- `test/core/storage/storage_paths_test.dart`: novos casos para `StoragePaths.campaignFile`.
- `docs/tasks/TASKS.md`: checkbox da TASK-080 marcado e progresso atualizado para 80/220.

## Arquitetura utilizada

Clean Architecture feature-first, mesmo padrão do restante do catálogo:
`CampaignsPage`/`CampaignFormPage`/`LookbookPage` (UI) → `CampaignListBloc`/`CampaignFormBloc`/
`LookbookBloc` → 6 use cases novos (`Create`/`Update`/`Delete`/`Get`/`ListCampaigns`/
`ListCampaignRelatedProducts`) → `CatalogCampaignRepository` (contrato estendido) →
`SharedPreferencesCatalogCampaignRepository` (mesmo local-first já usado por
`Collection`/`Product`). Upload de imagem reaproveita `StorageDataSource`/`ImageUploadCompressor`
(TASK-068) sem duplicar pipeline. Seleção de produtos relacionados reaproveita `ProductSearchPage`
(busca global já existente) em vez de um picker novo. Domínio não importa Flutter/Firebase; UI
nunca acessa Storage/`SharedPreferences` diretamente.

## Regras de negócio implementadas

- `CatalogCampaign.statusAt(now)` é a única fonte de status (ativa/agendada/expirada/inativa),
  reutilizada por `CampaignsPage` (coluna Status), `GetCatalogCampaignsSectionUseCase` (home) e
  `LookbookBloc` (visibilidade) — nenhum dos três decide "está visível?" com lógica própria.
- Uma campanha fora da janela de vigência (ou desativada, ou soft-deleted) é tratada por
  `LookbookBloc` como indistinguível de "não encontrada": nunca revela ao visitante *por que*
  desapareceu, e nunca continua sinalizando "em campanha" em nenhuma tela — resolvido no momento
  da leitura, sem depender de refresh manual do app.
- Criação nunca aceita o campo `active`/`order` fora do fluxo normal do formulário; edição
  reaproveita a mesma validação de criação (`campaign_use_case_validation.dart`, mesmo padrão
  `Collection` já usa).
- Exclusão é sempre soft-delete (`deletedAt`), nunca remoção definitiva — mesmo padrão
  `Product`/`Collection`.
- Adicionar o mesmo produto relacionado duas vezes nunca duplica a entrada (`CampaignFormBloc`).
- RBAC: `CampaignsPage` e `CampaignFormPage` são gated por `Capability.catalogManage` (a mesma
  capability que já protege `CollectionsPage`/`ProductFormPage`) via `PermissionBuilder`, negando
  acesso a `SALES_REP`/`SALES_ASSISTANT` sem permissão explícita.

## Regras Firebase implementadas

Nenhuma regra nova de Firestore/Storage nesta task: a persistência de `CatalogCampaign` continua
local-first (`SharedPreferences`), o mesmo padrão que TASK-076 já havia estabelecido para leitura
e que esta task estende para escrita — ver "Decisões técnicas" para o racional dessa escolha
dentro do escopo desta execução. Upload de imagem reaproveita o `StorageDataSource`/regras de
Storage já existentes de TASK-068 (nenhuma regra nova, nenhuma enfraquecida); o novo path
`StoragePaths.campaignFile` segue exatamente a mesma convenção
`organizations/{organizationId}/...` que `storage.rules` já isola por tenant.

## Analytics implementado

- `campaign_viewed`: disparado uma única vez por sessão de `LookbookPage`, quando a campanha
  carrega com sucesso e está visível, com `organization_id`/`campaign_id`.
- `campaign_product_clicked`: disparado quando o visitante toca em um produto relacionado no
  carrossel do lookbook, com `organization_id`/`campaign_id`/`product_id`.
- `product_media_updated`/eventos existentes não foram alterados.

## Crashlytics implementado

Nenhuma instrumentação nova: falhas de repositório/upload já convertem para `Failure`/`AppResult`
pelo fluxo central existente (`mapAppExceptionToFailure`); nenhum `print`/exceção não tratada foi
introduzido.

## Impacto offline

Igual ao restante do catálogo hoje: `SharedPreferencesCatalogCampaignRepository` é local-first,
então leitura/escrita de campanha funcionam offline (útil para o representante consultar um
lookbook já cacheado). O upload de imagem em si depende de conectividade (mesma limitação já
existente para mídia de produto, TASK-068) — uma falha de upload não corrompe o restante do
formulário, apenas mantém a imagem/URL anterior.

## Impacto multi-tenant

Toda leitura/escrita passa `organizationId` explicitamente (repositório, use cases, `StoragePaths`
inclui `organizationId` no path); a chave local (`catalog_campaigns_<organizationId>`) já isolava
por tenant desde TASK-076 e continua isolando após a escrita ser adicionada. RBAC nunca confia
apenas em `organizationId` vindo do cliente — `Capability.catalogManage` é resolvido por
`PermissionService`/`Membership` real.

## Testes criados

- Domínio: `CatalogCampaign.statusAt` (ativa/agendada/expirada/inativa, incluindo soft-delete);
  os 6 use cases novos (validação, not-found, soft-delete, resolução de produtos relacionados
  descartando id inexistente sem falhar o lote).
- Dados: `SharedPreferencesCatalogCampaignRepository` — round-trip completo de `create`/`getById`,
  `update`, `delete` (soft-delete reflete em `listByOrganization`), `NotFoundFailure` para id
  inexistente.
- BLoC (`CampaignListBloc`): carregamento com todos os status, busca, exclusão sem reload
  completo, falha de carregamento.
- BLoC (`CampaignFormBloc`): novo campanha gera id estável antes do primeiro save; edição
  hidrata campos e produtos relacionados; upload/substituição/remoção de capa (com limpeza
  best-effort do Storage); upload/reordenação/remoção de imagem editorial; adicionar/remover
  produto relacionado sem duplicar; submissão cria/atualiza com sucesso; validação de título em
  branco sem persistir.
- BLoC (`LookbookBloc`): campanha ativa carrega produtos relacionados e loga `campaign_viewed`
  uma única vez; campanha inexistente/agendada/expirada/inativa tratada uniformemente como
  indisponível; campanha sem produtos relacionados; `campaign_product_clicked` ao tocar em um
  produto.
- Widget (`CampaignsPage`): RBAC nega acesso a `SALES_REP`; estado vazio/erro/lista com badge de
  status.
- Widget (`CampaignFormPage`): RBAC; formulário vazio para nova campanha; formulário pré-
  preenchido ao editar; erro de campo ao submeter título em branco; fluxo completo de criação
  populando o repositório e fechando a tela.
- Widget (`LookbookPage`): estado indisponível para campanha inexistente/expirada; conteúdo
  completo (capa, texto, carrossel de produtos); estado "sem conteúdo publicado" (campanha ativa
  sem imagens/produtos, ainda assim renderiza normalmente); layout empilhado em mobile vs.
  lado a lado em desktop.
- Regressão: `AnalyticsEvents` (taxonomia); `StoragePaths.campaignFile`; fakes existentes
  (`FakeCatalogCampaignRepository`, use case da seção de campanhas da home) atualizados para o
  contrato estendido.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

Primeira execução formatou os arquivos novos e reformatou 3 arquivos preexistentes e não
relacionados a esta task (`lib/core/navigation/active_organization_guard.dart`,
`lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart`,
`lib/features/settings/presentation/widgets/about_app_content.dart` — já modificados por outra
frente de trabalho em andamento no repositório antes desta task, apenas reformatação de
espaçamento). Esses 3 arquivos **não** foram adicionados a este commit (fora do escopo da
TASK-080). Execução final sobre os arquivos desta task: sem diferenças pendentes.

## Resultado do analyzer

`No issues found! (ran in 12.8s)`.

## Resultado dos testes

`flutter test` (suíte completa): `All tests passed!` — `+1742` (1742 testes, 0 falhas), sem
`skip`.

## Decisões técnicas

- **Persistência continua local-first (`SharedPreferences`), não Firestore**: a task descreve o
  modelo "no Firestore", mas o repositório inteiro do catálogo (TASK-064 a TASK-076) segue hoje o
  precedente explícito "local store até o backend real existir" — inclusive a própria
  `CatalogCampaign` (TASK-076) e `Collection`/`Product` (TASK-065/066). Implementar Firestore +
  `firestore.rules` aqui exigiria uma migração de toda a família `Collection`/`Product`/
  `CatalogCampaign` simultaneamente para não deixar o catálogo com dois backends distintos, o que
  está fora do escopo desta task isolada e não foi pedido por nenhuma outra task já concluída.
  Mantido o mesmo padrão incremental já usado, documentado aqui como pendência explícita — o
  contrato (`CatalogCampaignRepository`) já é backend-agnóstico, então trocar a implementação por
  uma Firestore no futuro não exige mudar nenhum use case/bloc/página.
- **`campaignId` gerado no início do formulário, mesmo para uma campanha nova**: diferente de
  `ProductFormPage` (que só libera upload de mídia depois do produto já existir),
  `CampaignFormPage` é uma página única onde o admin pode subir imagens antes do primeiro save —
  um id estável gerado em `CampaignFormStarted` permite `StoragePaths.campaignFile` funcionar
  desde o primeiro upload, e `CampaignFormSubmitted` cria o documento com esse mesmo id.
- **Seleção de produtos relacionados reaproveita `ProductSearchPage`** (busca global já
  existente) em vez de um picker específico de campanha — evita duplicar UI/lógica de busca.
- **Sem barra de progresso de upload** (diferente de `ProductMediaBloc`): a campanha só tem
  imagens (nunca vídeo), e simplificar para "upload síncrono com spinner" manteve o escopo do
  formulário administrativo tratável sem duplicar toda a máquina de `StorageUploadCancelToken`/
  `StorageUploadProgress` de TASK-068 — pode ser adicionado depois reaproveitando o mesmo
  `StorageDataSource.uploadFile(onProgress:...)` já usado internamente.
- **`now` injetável via `@ignoreParam DateTime Function()`** em `CampaignListBloc`/`LookbookBloc`:
  necessário para status/visibilidade determinísticos em teste; `@ignoreParam` evita que o
  `injectable_generator` tente resolver `DateTime Function()` como dependência (erro de geração
  "Can not resolve function type"), o mesmo mecanismo que `AboutAppBloc.pageSize` já usa para um
  parâmetro com valor padrão não injetável.
- **Sem integração com `AppRouter`**: nenhuma página de catálogo/produto já concluída está
  registrada no router (mesmo padrão de `CatalogHomePage`/`ProductSearchPage`/`CollectionsPage`);
  a navegação real fica para uma task de shell/navegação dedicada, como as próprias conclusões de
  TASK-076/078 já registraram.

## Riscos conhecidos

- Persistência local-first: like o restante do catálogo hoje, campanhas criadas em um dispositivo
  não sincronizam para outro até uma migração Firestore existir — mesmo risco já assumido e
  documentado por TASK-076.
- Sem barra de progresso/cancelamento de upload no formulário de campanha (ver "Decisões
  técnicas") — upload grande trava a UI até concluir; aceitável para o volume de imagens de uma
  campanha (poucas fotos), mas pode incomodar em conexão muito lenta.
- TASK-082 ("catálogo por campanha" como modo de visualização) ainda não existe: `LookbookPage`
  funciona de forma independente/standalone hoje, sem um ponto de entrada dedicado além do que
  TASK-076 já linka via `onSectionItemTap` na home.

## Pendências

- Migrar `CatalogCampaign`/`Collection`/`Product` para Firestore quando essa migração for
  planejada para toda a família de uma vez (fora do escopo desta task isolada).
- TASK-082: usar `LookbookPage` como o modo de visualização "catálogo por campanha".
- Integração de `CampaignsPage`/`CampaignFormPage`/`LookbookPage` ao `AppRouter` (nenhuma página
  de catálogo/produto está integrada ainda — pendência já registrada por TASK-076/078).
- Barra de progresso/cancelamento de upload de imagem de campanha, se o volume justificar.

## Evidências

- `flutter analyze`: `No issues found!`
- `flutter test`: `All tests passed!` (1742 testes).
- `dart format --set-exit-if-changed .`: sem diferenças pendentes nos arquivos desta task.

## Commit

`feat(catalog): implement campaign CRUD and public lookbook screen`

## Push

Não realizado nesta rodada (não autorizado).

## Hash do commit

Ver seção "Commit" da resposta final — hash real do `git commit`, nunca inventado.

## Branch

main
