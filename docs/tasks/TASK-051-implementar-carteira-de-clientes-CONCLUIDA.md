# TASK-051 — Concluída (2026-08-24)

## Resumo
Implementada a carteira de clientes com rota própria, RBAC `customer.view`, filtros combináveis, busca com debounce, paginação por cursor e leitura local escopada por organização, empresa, papel e vínculos de carteira.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist
- vestipro-sales-representative-specialist

## Arquivos criados
- `lib/features/customers/domain/entities/customer_portfolio_filters.dart`
- `lib/features/customers/domain/entities/customer_portfolio_page_result.dart`
- `lib/features/customers/domain/usecases/list_customer_portfolio_use_case.dart`
- `lib/features/customers/presentation/bloc/customer_portfolio_bloc.dart`
- `lib/features/customers/presentation/bloc/customer_portfolio_event.dart`
- `lib/features/customers/presentation/bloc/customer_portfolio_state.dart`
- `lib/features/customers/presentation/pages/customer_portfolio_page.dart`
- `test/features/customers/data/repositories/customer_portfolio_repository_test.dart`
- `test/features/customers/domain/usecases/list_customer_portfolio_use_case_test.dart`
- `test/features/customers/presentation/bloc/customer_portfolio_bloc_test.dart`
- `test/features/customers/presentation/pages/customer_portfolio_page_test.dart`
- `docs/tasks/TASK-051-implementar-carteira-de-clientes-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md`
- `lib/app/bootstrap.dart`
- `lib/app/injection.config.dart`
- `lib/core/navigation/app_route_paths.dart`
- `lib/core/navigation/app_router.dart`
- `lib/core/permissions/capability.dart`
- `lib/core/permissions/role_permission_matrix.dart`
- `lib/features/customers/customers.dart`
- `lib/features/customers/data/repositories/shared_preferences_customer_repository.dart`
- `lib/features/customers/domain/repositories/customer_repository.dart`
- `test/core/navigation/app_router_test.dart`
- `test/features/customers/domain/usecases/customer_address_contact_use_cases_test.dart`
- `test/features/customers/presentation/bloc/customer_form_bloc_test.dart`
- `test/features/customers/presentation/pages/customer_form_page_test.dart`

## Arquitetura utilizada
Clean Architecture feature-first com use case compondo `PortfolioVisibilityService`, `PortfolioAssignmentRepository` e `CustomerRepository`. A UI usa BLoC e Design System; o repositório local aplica escopo antes de busca/filtros, evitando autorização apenas client-side na tela.

## Regras de negócio implementadas
- `SALES_REP` só lista clientes com vínculo ativo de carteira.
- `SALES_REP` sem vínculo ativo retorna erro explícito, não lista vazia.
- `SALES_MANAGER` lista vínculos das equipes visíveis.
- `ADMIN`/`OWNER` usam escopo amplo da organização/empresa sem depender da leitura de vínculos.
- Busca por nome/documento é normalizada e combinável com filtros.
- Filtros por status, UF/região, potencial e última compra usam AND.
- Paginação por cursor preserva itens já carregados.
- Busca invalida requisições em voo para evitar resultado stale.

## Regras Firebase implementadas
Não houve alteração em Firestore Rules, Storage Rules ou Cloud Functions. A task usa o contrato local atual; as garantias remotas definitivas continuam pendentes para as tasks de backend/sync.

## Analytics implementado
Não foram criados eventos novos. A carteira é leitura e não envia PII para analytics.

## Crashlytics implementado
Não aplicável. Falhas são propagadas por `AppResult`/`Failure` e renderizadas pela página.

## Impacto offline
`SharedPreferencesCustomerRepository` lista dados já persistidos localmente e marca a página como cache local/offline por `isFromLocalCache`.

## Impacto multi-tenant
Listagem sempre exige `organizationId` e `companyId`. O escopo é resolvido pelo Membership real via `PortfolioVisibilityService`, e os clientes são filtrados por organização/empresa antes de qualquer filtro visual.

## Testes criados
- Repository: escopo por organização/empresa/vínculo, filtros combinados e paginação por cursor.
- Use case: representante sem vínculo, admin sem dependência de vínculos e gestor restrito às equipes visíveis.
- BLoC: primeira carga, paginação, debounce/cancelamento, filtros e falha explícita.
- Widget: lista local/offline, vazio, erro e forbidden.
- Navegação: rota da carteira com query params e guard `customer.view`.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format --set-exit-if-changed .`
- `dart format --set-exit-if-changed .`
- `dart format --set-exit-if-changed .`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter analyze`
- `flutter analyze`
- `flutter test test/core/permissions/role_permission_matrix_test.dart`
- `flutter test test/features/customers/data/repositories/customer_portfolio_repository_test.dart`
- `flutter test test/features/customers/domain/usecases/list_customer_portfolio_use_case_test.dart`
- `flutter test test/features/customers/presentation/bloc/customer_portfolio_bloc_test.dart`
- `flutter test test/features/customers/presentation/pages/customer_portfolio_page_test.dart`
- `flutter test test/core/navigation/app_router_test.dart`
- `flutter test`

## Resultado do formatter
Execuções intermediárias formataram arquivos da TASK-051. Execução final: `Formatted 731 files (0 changed)`.

## Resultado do analyzer
Primeira execução apontou `prefer_initializing_formals` no novo use case, corrigido. Execução final: `No issues found!`.

## Resultado dos testes
`flutter test`: 1118 testes passaram.

## Decisões técnicas
- Criada `Capability.customerView` para separar leitura de carteira de criação/edição de cliente.
- `SALES_ASSISTANT` permaneceu sem `customer.view`, preservando a matriz existente.
- `CustomerPortfolioFilters` centraliza serialização de URL e normalização.
- A listagem local aplica visibilidade antes dos filtros funcionais.
- ADMIN/OWNER não carregam vínculos porque o escopo amplo independe deles.

## Riscos conhecidos
- A listagem remota e as regras de segurança definitivas ainda precisam ser implementadas quando o Customer sair do cache local provisório.
- O campo de equipe do cliente ainda é materializado por vínculo de carteira/assignment; Firestore futuro deve manter campos denormalizados equivalentes para query/rules eficientes.

## Pendências
- Implementar persistência remota, índices e rules para carteira em tasks futuras.
- Conectar ações comerciais da carteira ao detalhe 360º e pedido nas próximas tasks.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1118/1118 testes passaram.
- Backlog atualizado para 51 / 220.

## Commit
`feat(customers): add customer portfolio`

## Push
Não realizado por solicitação do lote (`sem push`).

## Hash do commit
Pendente no momento de criação deste documento; informado na resposta final da task.

## Branch
main
