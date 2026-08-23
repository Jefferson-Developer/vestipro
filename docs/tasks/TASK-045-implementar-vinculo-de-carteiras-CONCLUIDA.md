# TASK-045 — Concluída (2026-08-23)

## Resumo
Implementado o vínculo tenant-scoped de vendedores a carteiras com `PortfolioAssignment`, suporte a escopo por cliente ou critério comercial, tela administrativa `AssignPortfolioPage` para OWNER/ADMIN/SALES_MANAGER e contrato de visibilidade que a TASK-051 deverá consumir ao implementar `Customer`.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- vestipro-sales-representative-specialist
- vestipro-commercial-ops-strategist

## Arquivos criados
- `lib/features/users/domain/entities/portfolio_assignment.dart`
- `lib/features/users/domain/entities/customer_visibility_filter.dart`
- `lib/features/users/domain/repositories/portfolio_assignment_repository.dart`
- `lib/features/users/domain/services/portfolio_visibility_service.dart`
- `lib/features/users/domain/usecases/assign_portfolio_use_case.dart`
- `lib/features/users/domain/usecases/list_portfolio_assignments_use_case.dart`
- `lib/features/users/data/dtos/portfolio_assignment_dto.dart`
- `lib/features/users/data/mappers/portfolio_assignment_mapper.dart`
- `lib/features/users/data/datasources/portfolio_assignment_data_source.dart`
- `lib/features/users/data/datasources/firestore_portfolio_assignment_data_source.dart`
- `lib/features/users/data/repositories/portfolio_assignment_repository_impl.dart`
- `lib/features/users/presentation/bloc/assign_portfolio_bloc.dart`
- `lib/features/users/presentation/bloc/assign_portfolio_event.dart`
- `lib/features/users/presentation/bloc/assign_portfolio_state.dart`
- `lib/features/users/presentation/pages/assign_portfolio_page.dart`
- `test/features/users/domain/services/portfolio_visibility_service_test.dart`
- `test/features/users/domain/usecases/assign_portfolio_use_case_test.dart`
- `test/features/users/presentation/pages/assign_portfolio_page_test.dart`
- `docs/tasks/TASK-045-implementar-vinculo-de-carteiras-CONCLUIDA.md`

## Arquivos alterados
- `firestore.rules`
- `firestore.indexes.json`
- `firestore-tests/firestore.rules.test.js`
- `lib/app/injection.config.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/features/users/users.dart`
- `test/core/analytics/analytics_events_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first: Presentation (`AssignPortfolioPage` + BLoC) -> Use cases -> Repository contract -> Repository implementation -> Firestore datasource. A UI não acessa Firestore, Storage ou Drift diretamente.

## Regras de negócio implementadas
- `PortfolioAssignment` contém `organizationId`, `companyId`, `userId`, `teamId`, `scopeType`, `customerId`, `region`, `segment`, `status`, auditoria e soft delete.
- O escopo de carteira pode ser `customer` ou `criteria`; `customer` exige `customerId`, e `criteria` exige `region` ou `segment`.
- Um cliente tem um vendedor principal. Carteira compartilhada não foi suportada nesta task.
- Reatribuição de cliente encerra o vínculo ativo anterior como `reassigned` e cria novo vínculo ativo, preservando o histórico integral do cliente e dos vínculos.
- Todos os vínculos são escopados por organização e empresa ativa.
- `PortfolioVisibilityService` resolve visibilidade por role: SALES_REP vê somente seus clientes; SALES_MANAGER vê clientes das suas Teams; ADMIN/OWNER veem a organização; usuários inativos ou sem role suportada falham fechados.

## Regras Firebase implementadas
- Criadas regras para `organizations/{organizationId}/portfolioAssignments/{assignmentId}` com leitura por gestores/admins/owners e leitura restrita ao próprio vendedor.
- Create/update de vínculo exige `team.manage`, payload válido e tenant correto; delete físico é bloqueado.
- Criado contrato de `customers` para TASK-051: documentos em `organizations/{organizationId}/customers` devem expor `organizationId`, `companyId`, `primarySalesRepId`, `teamId` e `deletedAt`.
- `get` de cliente é validado por role e por campos denormalizados.
- `list` de clientes exige query compatível com o contrato: clientes ativos (`deletedAt == null`) e filtro por `primarySalesRepId` para SALES_REP ou `teamId` para SALES_MANAGER; ADMIN/OWNER podem listar a organização.
- Adicionados índices compostos para queries de `portfolioAssignments`.

## Analytics implementado
Adicionado evento sem PII `portfolio_assignment_saved`, emitido após salvar vínculo de carteira.

## Crashlytics implementado
Não houve integração específica nova. Falhas seguem o fluxo existente de exceptions/failures, BLoC state e feedback de UI.

## Impacto offline
Não foi criada persistência offline/Outbox nesta task. A modelagem preserva histórico por soft delete/status e evita cascade delete, preparando consumo offline futuro da carteira.

## Impacto multi-tenant
Todas as operações exigem `organizationId` e `companyId`; regras de Firestore e contratos de domínio impedem leitura/escrita fora do tenant ativo.

## Testes criados
- Testes de domínio para visibilidade por role em `PortfolioVisibilityService`.
- Testes de use case para criação por cliente, criação por critério, validação de payload e reatribuição preservando histórico.
- Teste widget para renderização da `AssignPortfolioPage` com permissão de OWNER.
- Testes de Firestore Rules cobrindo `portfolioAssignments` e o contrato de visibilidade de `customers`, incluindo SALES_REP bloqueado fora da carteira mesmo manipulando query.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format .`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter test test\core\analytics\analytics_events_test.dart`
- `flutter test test\features\users\presentation\pages\assign_portfolio_page_test.dart`
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test -- --silent"`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou: 646 arquivos, 0 alterados.

## Resultado do analyzer
`flutter analyze` passou: No issues found.

## Resultado dos testes
- `flutter test`: 1033/1033 testes passaram.
- Firestore Emulator Suite: 70/70 testes passaram.
- Primeira tentativa do emulator falhou por Java ausente no `PATH`; rerodado com o JBR do Android Studio.
- Uma rodada intermediária das rules expôs 3 falhas em `list` de clientes; o contrato foi ajustado para separar `get`/`list` e exigir `deletedAt == null` nas queries de carteira.

## Decisões técnicas
- `Customer` não foi modelado; a task entrega apenas ids, critérios e contrato de responsabilidade/visibilidade para TASK-051.
- Carteira compartilhada ficou explicitamente fora do escopo; o cliente possui um vendedor principal.
- O contrato de TASK-051 deve aplicar sempre `companyId` e `deletedAt == null`; para SALES_REP, `primarySalesRepId == userId`; para SALES_MANAGER, `teamId in teamIds`; para ADMIN/OWNER, sem filtro adicional de visibilidade.
- Reatribuição usa histórico append-only por fechamento do vínculo anterior e criação de novo vínculo ativo.

## Riscos conhecidos
- A sincronização futura entre `PortfolioAssignment` e o documento real de `Customer.primarySalesRepId/teamId` dependerá da implementação de Customer na TASK-051 ou de uma Cloud Function transacional futura.
- Queries com `teamId in` terão de respeitar o limite de valores do Firestore quando um gestor tiver muitas equipes.

## Pendências
Nenhuma pendência funcional para a TASK-045. A TASK-051 deve consumir o contrato documentado em `CustomerVisibilityFilter` e `firestore.rules`.

## Evidências
- Build runner executado com sucesso e `injection.config.dart` atualizado.
- Formatter: 646 arquivos, 0 alterados no modo verificação.
- Analyzer: sem issues.
- Flutter full test: 1033/1033 testes passaram.
- Firestore rules: 70/70 testes passaram via Emulator Suite.

## Commit
Pendente no momento de criação deste documento.

## Push
Pendente no momento de criação deste documento.

## Hash do commit
Pendente no momento de criação deste documento.

## Branch
main
