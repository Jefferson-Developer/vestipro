# TASK-145 — Implementar visualizações salvas e compartilhadas (CONCLUÍDA)

## Resumo

Implementado o recurso de "visualizações salvas" do construtor de relatórios (TASK-144):
qualquer usuário pode salvar uma `ReportDefinition` como `SavedReport` privado, e usuários com a
permissão dedicada podem compartilhá-la com a própria equipe ou com toda a organização. As telas
"Meus relatórios" e "Compartilhados comigo" permitem favoritar (= salvar), renomear, alterar
compartilhamento, duplicar, excluir e reabrir uma visualização salva no construtor de relatórios.

## Modelo de domínio e RBAC

- `SavedReport` (`lib/features/reports/domain/entities/saved_report.dart`): `id`, `organizationId`,
  `companyId`, `ownerId`, `name`, `definition` (a `ReportDefinition` da TASK-144), `visibility`
  (`private | team | organization`), `sharedWithTeamIds` (snapshot do `teamIds` do dono no momento em
  que `visibility` foi definida como `team`, usado só para a query cliente — a autorização real nunca
  confia nele, ver Firestore Rules abaixo), `favorite`, auditoria (`createdAt/By`, `updatedAt/By`) e
  `version`.
- Duas novas `Capability` (`lib/core/permissions/capability.dart`):
  `reportShareTeam` (`report.share.team`) e `reportShareOrganization` (`report.share.organization`).
  Concedidas em `RolePermissionMatrix`
  (`lib/core/permissions/role_permission_matrix.dart`) a: OWNER/ADMIN (via superset já existente),
  SALES_MANAGER e FINANCE (ambas), SALES_REP (só `reportShareTeam` — compartilha no máximo com a
  própria equipe, nunca com toda a organização, conforme pedido explícito da task). Salvar uma
  visualização `private` nunca exige capability.
- `firestore.rules`: nova subcoleção `organizations/{organizationId}/savedReports/{reportId}`.
  Leitura permitida ao dono, a qualquer membro ativo quando `visibility == 'organization'`, e a um
  membro da mesma equipe do dono (recalculada dinamicamente a partir do Membership real do dono via
  `get()`, nunca do campo `sharedWithTeamIds` do documento) quando `visibility == 'team'`. Escrita
  (`create`/`update`) exige a capability correspondente ao `visibility` alvo
  (`savedReportShareCapabilityAllowed`); `update`/`delete` só para o dono ou OWNER/ADMIN
  (`canManageSavedReport`) — outro membro com acesso de leitura nunca edita/exclui. Mirror manual da
  tabela Dart em `roleHasCapability`, mesma disciplina já documentada no cabeçalho do arquivo.
- Testes Firestore Rules (positivos e negativos) adicionados em `firestore-tests/firestore.rules.test.js`
  (novo `describe` + fixture `savedReportDoc`), cobrindo: leitura privada/equipe/organização,
  isolamento cross-tenant, criação por qualquer membro (privado), SALES_REP limitado a `team` vs
  SALES_MANAGER liberado para `organization`, edição por dono/ADMIN vs bloqueio para terceiro com
  acesso de leitura, tentativa de elevar `visibility` sem capability, e exclusão pelo dono.
  **Não foi possível executar esses testes no Firebase Emulator nesta máquina** — falta Java no
  ambiente (`firebase emulators:exec` falha em "Could not spawn `java -version`"). Ficam prontos para
  rodar assim que o emulador estiver disponível (`firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`).

## Casos de uso (`lib/features/reports/domain/usecases/saved_report_use_cases.dart`)

- `SaveReportView`: valida nome, resolve Membership ativo do dono, autoriza o `visibility` pedido
  (capability certa ou `PermissionFailure`), rejeita nome duplicado do mesmo dono
  (`ConflictFailure`, checagem best-effort via leitura prévia — não é uma transação; aceitável para
  um nome pessoal, diferente de preço/estoque) e cria o `SavedReport` (id via `uuid`).
- `UpdateSavedReport`: só o dono ou OWNER/ADMIN podem chamar com sucesso; muda nome, definição,
  `visibility` (reautorizando se mudou) e `favorite`; recalcula `sharedWithTeamIds` a partir do
  Membership atual do **dono** (nunca do requisitante) sempre que o resultado final é `team`.
- `DeleteSavedReport`: só dono ou OWNER/ADMIN; consulta `ReportScheduleReferenceChecker` antes de
  excluir e **bloqueia** (não apenas avisa) com `ConflictFailure` código
  `saved_report_has_active_schedule` se houver agendamento ativo referenciando o relatório — nunca
  falha silenciosa.
- `ListSavedReports`: combina `listOwned` + `listSharedWithMe` (este último escopado pelos
  `teamIds` atuais do requisitante) em `SavedReportsOverview`.
- `OpenSavedReportInBuilder`: reaproveita o `ReportDraftRepository` já existente da TASK-144 (mesmo
  mecanismo de rascunho) para carregar a `ReportDefinition` salva de volta no construtor — o
  builder não precisou de nenhuma mudança; reabrir uma visualização salva é indistinguível, do ponto
  de vista do builder, de retomar um rascunho. Nunca persiste `id`/`ownerId`/`visibility` — só a
  definição, que é sempre reexecutada com o RBAC de quem abre.
- `ReportScheduleReferenceChecker` (`lib/features/reports/domain/services/`): interface + implementação
  `NoActiveScheduleReportScheduleReferenceChecker` que hoje sempre responde `false`, documentada
  explicitamente como placeholder até a TASK-149 (agendamento de relatórios) existir e substituir o
  binding por uma checagem real — nenhuma mudança necessária em `DeleteSavedReport` quando isso
  acontecer.

## Dados (`lib/features/reports/data/`)

- `SavedReportDto` + `FirestoreSavedReportRemoteDataSource` (usa `FirestoreCollectionDataSource`,
  mesmo padrão de `favorites`/`catalogShares`) + `SavedReportRepositoryImpl`. `listOwned`/
  `listNonPrivate` buscam uma única página (sem cursor, limite 200) — aceitável para a escala
  esperada (dezenas de relatórios salvos por usuário/organização), documentado como limitação
  conhecida. Exclusão é hard delete (sem valor de auditoria, mesmo raciocínio de
  `FirestoreFavoriteRemoteDataSource.delete`).

## Apresentação

- `SavedReportsBloc`/`SavedReportsEvent`/`SavedReportsState`
  (`lib/features/reports/presentation/bloc/`): estado único reaproveitado tanto pela tela de listagem
  quanto pelo botão "Salvar visualização" do construtor de relatórios.
- `SavedReportsPage`: listas "Meus relatórios" e "Compartilhados comigo"; ações de favoritar,
  renomear, compartilhar (com opções de `team`/`organization` escondidas via `PermissionBuilder`
  quando o usuário não tem a capability), duplicar e excluir (com diálogo de confirmação) —
  disponíveis apenas para itens da própria lista "Meus relatórios" nesta primeira versão de UI (um
  OWNER/ADMIN editando um relatório compartilhado por outra pessoa já funciona no domínio/backend,
  mas ainda não tem affordance dedicada nesta tela — ver "Pendências" abaixo).
- `ReportBuilderPage` (TASK-144) ganhou dois botões opcionais na AppBar — "Salvar visualização"
  (abre diálogo com nome + `visibility`) e "Meus relatórios" — habilitados só quando
  `createSavedReportsBloc`/`permissionService` são passados, para não quebrar os testes/usos
  existentes do construtor "puro".
- Novas rotas: `SavedReportsRoute` (`/org/:orgId/companies/:companyId/reports/saved`) em
  `lib/core/navigation/app_route_paths.dart`/`app_router.dart`, sem `redirect` de RBAC própria (mesma
  lógica do `ReportBuilderRoute`: a autorização de fato mora no domínio/backend, a rota só carrega o
  escopo de tenant/empresa). Wiring final em `lib/app/bootstrap.dart`.

## Analytics

Três novos eventos em `lib/core/analytics/analytics_events.dart`: `report_view_saved`,
`report_view_shared` (só quando `visibility` deixa de ser `private`) e `report_view_deleted`.

## Infraestrutura de DI

- `SaveReportView` depende de `Uuid` (para gerar `SavedReport.id`), que **não estava registrado** no
  container de DI (`lib/app/injection_module.dart`) — um gap pré-existente que também afetava
  silenciosamente `ConflictResolutionService`/`CloudFunctionsService` (ambos também injetam `Uuid?`
  com fallback `const Uuid()`, mas o `injectable_generator` gera `gh<Uuid>()` de qualquer forma,
  o que lançaria em runtime na primeira resolução real). Corrigido registrando
  `@lazySingleton Uuid get uuid => const Uuid();` em `AppInjectionModule` — necessário para a própria
  TASK-145 funcionar, com o benefício colateral de também corrigir o gap pré-existente.
- `injection.config.dart` regenerado via `dart run build_runner build` (2 rodadas, para registrar
  primeiro os novos `@injectable`/`@LazySingleton` e depois o `Uuid`).

## Arquivos criados

- `lib/features/reports/domain/entities/saved_report.dart`
- `lib/features/reports/domain/repositories/saved_report_repository.dart`
- `lib/features/reports/domain/services/report_schedule_reference_checker.dart`
- `lib/features/reports/domain/services/no_active_schedule_report_schedule_reference_checker.dart`
- `lib/features/reports/domain/usecases/saved_report_use_cases.dart`
- `lib/features/reports/data/dtos/saved_report_dto.dart`
- `lib/features/reports/data/datasources/saved_report_remote_data_source.dart`
- `lib/features/reports/data/datasources/firestore_saved_report_remote_data_source.dart`
- `lib/features/reports/data/repositories/saved_report_repository_impl.dart`
- `lib/features/reports/presentation/bloc/saved_reports_event.dart`
- `lib/features/reports/presentation/bloc/saved_reports_state.dart`
- `lib/features/reports/presentation/bloc/saved_reports_bloc.dart`
- `lib/features/reports/presentation/pages/saved_reports_page.dart`
- `test/features/reports/domain/usecases/saved_report_use_cases_test.dart`
- `test/features/reports/presentation/bloc/saved_reports_bloc_test.dart`
- `docs/tasks/TASK-145-implementar-visualizacoes-salvas-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `firestore.rules` (nova subcoleção `savedReports` + duas novas capabilities no mirror
  `roleHasCapability`)
- `firestore-tests/firestore.rules.test.js` (fixture `savedReportDoc` + novo `describe`)
- `lib/core/permissions/capability.dart` (`reportShareTeam`, `reportShareOrganization`)
- `lib/core/permissions/role_permission_matrix.dart` (concessão das duas novas capabilities)
- `lib/core/analytics/analytics_events.dart` (3 novos eventos)
- `lib/core/navigation/app_route_paths.dart` (`SavedReportsRoute`)
- `lib/core/navigation/app_router.dart` (builder + `GoRoute` de `SavedReportsRoute`)
- `lib/app/injection_module.dart` (`Uuid` registrado)
- `lib/app/injection.config.dart` (gerado)
- `lib/app/bootstrap.dart` (wiring de `reportBuilderPageBuilder`/`savedReportsPageBuilder`)
- `lib/features/reports/presentation/pages/report_builder_page.dart` (ações "Salvar
  visualização"/"Meus relatórios" opcionais)
- `lib/features/reports/reports.dart` (barrel)
- `test/core/analytics/analytics_events_test.dart` (lista exata da taxonomia)
- `test/core/permissions/role_permission_matrix_test.dart` (novo teste de RBAC das capabilities de
  compartilhamento)

## Validações executadas

- `dart run build_runner build` (duas vezes) — sem erros de geração; aviso pré-existente sobre
  dependências de `Uuid` corrigido pela própria task.
- `flutter analyze` — 0 erros/warnings; restam só *infos* pré-existentes (não tocados por esta task)
  e 6 *infos* de depreciação do `RadioListTile.groupValue/onChanged` (API antiga, ainda suportada,
  substituição por `RadioGroup` fica como melhoria futura de baixo risco).
- `dart format --set-exit-if-changed` nos arquivos tocados por esta task — sem alterações pendentes.
- `flutter test` (suíte completa) — **2753/2753 testes passando**, incluindo os 19 novos testes desta
  task (14 de casos de uso + 5 de bloc).
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` — **não executado**:
  falta Java no ambiente local (`Could not spawn 'java -version'`). Os testes de Rules foram escritos
  e revisados manualmente contra a lógica de `firestore.rules`, mas não foram confirmados rodando de
  fato contra o Emulator.

## Decisões e limitações conhecidas

- "Favoritar" e "salvar" são a mesma ação nesta implementação (não existe um favorito pessoal
  separado sobre um relatório de terceiro) — decisão deliberada para bater com o critério de aceite
  "salva com um clique e reencontra na lista de favoritos", sem inventar um subsistema extra de
  favoritos por usuário sobre itens compartilhados.
- `SavedReportsPage` só oferece renomear/compartilhar/duplicar/excluir para itens da lista "Meus
  relatórios"; um OWNER/ADMIN editando/excluindo um relatório compartilhado por outra pessoa (already
  suportado e testado no domínio + Firestore Rules) ainda não tem affordance de UI dedicada — pode
  ser adicionado depois sem qualquer mudança de domínio/backend.
- Verificação de nome duplicado é best-effort (leitura seguida de escrita, não transacional) —
  aceitável para um nome pessoal de relatório, mesmo padrão de risco que outras listas nominais do
  app já assumem implicitamente.
- `ReportScheduleReferenceChecker` é um placeholder até a TASK-149 existir; `DeleteSavedReport` já
  implementa a regra "bloqueia, nunca falha silenciosa" e não precisará mudar quando a TASK-149
  substituir o binding.
