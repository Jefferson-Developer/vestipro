# TASK-142 — Implementar dashboard de metas (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

- `TargetsDashboardBloc` com carregamento, alteração dos filtros de equipe, vendedor e período,
  retry e drill-down hierárquico organização → equipe → vendedor.
- Cruzamento entre os agregados server-side `sellerMonthly` da TASK-133 e as metas ativas
  cadastradas por empresa, equipe e vendedor. Metas inativas, removidas ou fora do período
  consultado nunca aparecem como em risco.
- KPIs de realizado/meta, atingimento absoluto e percentual, gap e previsão de fechamento.
- Ranking comercial produzido pelo `RankingCalculationService` já existente (TASK-118), mantendo a
  redação do ranking para vendedor e a visão completa para gestor/admin.
- RBAC reaproveitando `TargetVisibilityService`: vendedor vê somente a própria meta; gestor vê
  equipes/membros sob sua gestão; owner/admin vê a organização.
- Destaque de vendedores com insight ativo `sellerBelowTarget`, com deep link para a Central de
  Oportunidades.
- UI responsiva: tabela hierárquica expansível no desktop e navegação nível a nível no mobile,
  além de estados de loading, erro, sem permissão, sem meta e indicação de cache offline.
- Analytics `dashboard_viewed` com `dashboard_type: targets` e filtros técnicos.
- Rota tipada `/org/:orgId/companies/:companyId/dashboards/targets`, protegida por
  `Capability.targetView`, com filtros restauráveis pela URL.

## Arquitetura e decisões

- O dashboard faz uma leitura limitada da dimensão `sellerMonthly` pelo `AggregationRepository` e
  nunca consulta pedidos brutos. As definições de meta continuam vindo do `TargetRepository`.
- A previsão usa diretamente `InsightSalesRepBelowTargetSnapshot`, a primitiva de domínio da regra
  de insight da TASK-131. Assim, projeção e percentual projetado têm uma única fórmula nos dois
  fluxos.
- O período de uma meta é considerado vigente quando intersecta o mês consultado e seu status é
  `active`; metas sem vigência no período retornam explicitamente “Sem meta”.
- Falha ao consultar a Central de Oportunidades não derruba o dashboard: os KPIs continuam
  disponíveis e apenas o destaque de risco fica ausente.

## Principais arquivos

- `lib/features/dashboards/domain/entities/targets_dashboard_*.dart`
- `lib/features/dashboards/domain/usecases/load_targets_dashboard_use_case.dart`
- `lib/features/dashboards/presentation/bloc/targets_dashboard_*.dart`
- `lib/features/dashboards/presentation/pages/targets_dashboard_page.dart`
- `lib/core/navigation/app_route_paths.dart`, `lib/core/navigation/app_router.dart`
- `lib/app/bootstrap.dart`, `lib/app/injection.config.dart`
- `test/features/dashboards/domain/usecases/load_targets_dashboard_use_case_test.dart`
- `test/features/dashboards/presentation/bloc/targets_dashboard_bloc_test.dart`
- `test/features/dashboards/presentation/pages/targets_dashboard_page_test.dart`

## Testes e validações

- `flutter test test/features/dashboards`: **189 testes aprovados**.
- Coberturas específicas: hierarquia completa, filtro de período sem meta, consistência exata da
  projeção com TASK-131, RBAC de vendedor, alteração de filtros, analytics, drill-down e layouts
  desktop/mobile.
- `flutter analyze`: nenhum erro ou warning; permaneceram 6 infos preexistentes de
  `use_null_aware_elements` em testes antigos de dashboards.
- `dart run build_runner build --delete-conflicting-outputs`: concluído e DI regenerada. O comando
  informou que a opção foi removida e repetiu os avisos preexistentes de dependências não
  registradas em outros módulos.

## Commit e push

Não realizados, conforme instrução explícita desta rodada.
