# TASK-144 — Implementar construtor de relatórios (CONCLUÍDA)

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ✅ Concluída
**Data:** 2026-09-04

## Resumo

Foi implementado o construtor ad-hoc de relatórios com catálogo server-side, definição reutilizável,
validação local, execução exclusiva sobre os snapshots da TASK-133, rascunho persistente, BLoC e UI
responsiva. A solução é a base de domínio para visualizações salvas, exportações e agendamentos das
TASK-145 a TASK-149.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-commercial-ops-strategist`
- `vestipro-sales-representative-specialist`

## Implementação

- `ReportDefinition` representa dimensões, métricas, filtros, agrupamento, ordenação e comparação.
- `ValidateReportDefinition` bloqueia campos indisponíveis, limites, período inválido, famílias de
  agregação incompatíveis e métrica incompatível antes de qualquer chamada de rede.
- `LoadReportCatalog` e `ExecuteReportQuery` isolam os casos de uso da infraestrutura.
- `ReportBuilderBloc` restaura e salva cada alteração do rascunho, remove métricas que se tornam
  incompatíveis, controla preview/erros e registra analytics.
- `ReportBuilderPage` oferece chips incrementais, filtro de período, comparação, ordenação,
  agrupamento explícito e preview tabular responsivo, com estados de loading, vazio e erro.
- Rota tipada `/org/:orgId/companies/:companyId/reports/builder` e DI de produção configuradas.

## Backend, RBAC e multi-tenant

- As callables `loadReportCatalog` e `executeReportQuery` validam autenticação, membership ativa,
  empresa pertencente à organização e perfil do chamador; o `organizationId` do cliente nunca é
  aceito como autorização por si só.
- O catálogo completo dos KPIs da seção 12.2 fica no servidor. KPIs ainda não publicados pela
  camada de agregação aparecem como indisponíveis, permitindo ativação futura sem hardcode na UI.
- OWNER/ADMIN/FINANCE recebem métricas financeiras; SALES_REP fica limitado ao próprio `uid` na
  dimensão vendedor; SALES_MANAGER fica limitado aos vendedores das suas `teamIds`.
- A execução lê somente coleções `*Aggregates` da TASK-133, com limite de 500 snapshots, e calcula
  ticket/desconto/peças por pedido e comparação percentual no backend. O Flutter renderiza
  exatamente as linhas retornadas.

## Persistência, analytics e impacto offline

- O rascunho é salvo em `SharedPreferences` por usuário + organização + empresa e sobrevive à
  navegação/reabertura. A execução permanece online porque depende de agregados server-side.
- Eventos adicionados: `report_built` e `report_query_executed`, sem PII.
- Não houve alteração de schema Drift, Outbox, Firestore Rules ou Storage Rules.

## Principais arquivos

- `functions/src/reports/report-catalog.ts`
- `functions/src/reports/execute-report-query.ts`
- `lib/features/reports/domain/entities/report_definition.dart`
- `lib/features/reports/domain/usecases/validate_report_definition.dart`
- `lib/features/reports/presentation/bloc/report_builder_bloc.dart`
- `lib/features/reports/presentation/pages/report_builder_page.dart`
- `lib/core/navigation/app_route_paths.dart`, `lib/core/navigation/app_router.dart`
- `lib/app/bootstrap.dart`, `lib/app/injection.config.dart`

## Testes e validações

- Testes Flutter direcionados: **15 aprovados**, cobrindo validação, RBAC via catálogo, isolamento
  tenant, sucesso, timeout, erro de permissão, BLoC, persistência e preview de widget.
- Testes Jest direcionados: **5 aprovados**, cobrindo catálogo por SALES_REP, FINANCE,
  default-deny e comparação server-side.
- `npm run lint`: aprovado.
- `npm run build`: aprovado.
- `dart run build_runner build --delete-conflicting-outputs`: concluído; DI regenerada, preservando
  os avisos preexistentes de dependências não registradas em outros módulos.
- `flutter analyze`: nenhum erro/warning novo; retorna código 1 por 6 infos preexistentes
  `use_null_aware_elements` em testes de dashboards fora desta task.
- Suíte Flutter completa: **2731 testes aprovados**.
- A suíte Jest completa depende de credenciais/Emulator e falhou em testes antigos que acessam
  Firestore por ausência de Application Default Credentials; os testes isolados desta task passam.

## Decisões e riscos conhecidos

- Somente KPIs deriváveis sem ambiguidade dos snapshots atuais são executáveis. Margem, churn,
  pipeline e demais indicadores sem agregado canônico ficam visíveis no catálogo como
  indisponíveis, evitando fórmulas divergentes.
- O limite de 500 linhas mantém a consulta bounded. Paginação/streaming de resultados muito grandes
  pertence às futuras tasks de exportação.
- Comparação com período anterior ou mesmo mês do ano anterior é executada no servidor e retorna
  colunas de valor-base e variação percentual para cada métrica selecionada.

## Commit e push

- Commit local específico da TASK-144.
- Push não realizado, conforme solicitação do usuário.
