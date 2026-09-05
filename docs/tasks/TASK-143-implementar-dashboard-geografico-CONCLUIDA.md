# TASK-143 — Implementar dashboard geográfico (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

- `GeographicDashboardBloc` com carregamento, retry, filtros restauráveis pela URL, seleção de
  área para drill-down e analytics `dashboard_viewed` com `dashboard_type: geographic`.
- Hierarquia região brasileira → UF → cidade, ordenada por faturamento, com KPIs de faturamento,
  clientes ativos, ticket médio, pedidos, quantidade e produtos mais vendidos.
- Enriquecimento de `regionMonthlyAggregates` na recomputação server-side: cidade, clientes,
  pedidos, vendedores e top produtos são denormalizados sem expor endereços individuais.
- Ranking responsivo e expansível, com ações para clientes/pedidos da cidade selecionada,
  estados de loading, vazio, erro, sem permissão e cache offline.
- Fallback explícito e não bloqueante quando latitude/longitude agregadas não existem. A base
  atual não persiste coordenadas nos snapshots, portanto a tabela/ranking é a visualização ativa.
- Rota tipada `/org/:orgId/companies/:companyId/dashboards/geographic`, protegida por
  `Capability.reportViewSensitive`, e DI regenerada.

## Arquitetura e decisões

- A tela consome somente snapshots mensais pelo `AggregationRepository`; não consulta pedidos,
  clientes ou endereços brutos.
- O RBAC reutiliza `ExecutiveDashboardVisibilityService`: owner/admin/finance acessam o consolidado
  e o gestor fica limitado às empresas de suas equipes. Perfis sem a capacidade sensível são
  bloqueados na rota e no use case, mantendo a mesma proteção das regras do Firestore.
- Clientes e pedidos são deduplicados ao consolidar cidade, UF e região; ticket médio usa
  faturamento líquido dividido pela quantidade de pedidos.
- O mapa continua preparado por `hasMapData`, mas não simula coordenadas nem envia geolocalização
  pessoal ao analytics, em conformidade com o fallback e a restrição LGPD da task.

## Principais arquivos

- `functions/src/aggregations/aggregation-shared.ts`
- `functions/src/aggregations/aggregation-builders.ts`
- `functions/src/aggregations/recompute-monthly-aggregates.ts`
- `lib/features/dashboards/domain/entities/geographic_dashboard_*.dart`
- `lib/features/dashboards/domain/usecases/load_geographic_dashboard_use_case.dart`
- `lib/features/dashboards/presentation/bloc/geographic_dashboard_*.dart`
- `lib/features/dashboards/presentation/pages/geographic_dashboard_page.dart`
- `lib/core/navigation/app_route_paths.dart`, `lib/core/navigation/app_router.dart`
- `lib/app/bootstrap.dart`, `lib/app/injection.config.dart`
- `test/features/dashboards/domain/usecases/load_geographic_dashboard_use_case_test.dart`
- `test/features/dashboards/presentation/bloc/geographic_dashboard_bloc_test.dart`

## Testes e validações

- Testes direcionados Flutter: **5 testes aprovados**, cobrindo hierarquia completa, período vazio,
  RBAC, carregamento/analytics, drill-down e fallback sem coordenadas.
- `functions/test/aggregations/aggregation-builders.test.ts`: **12 testes aprovados**.
- `npm --prefix functions run build`: TypeScript compilado com sucesso.
- `flutter analyze`: sem erros ou warnings; 6 infos preexistentes de
  `use_null_aware_elements` em testes antigos de dashboards.
- `dart run build_runner build --delete-conflicting-outputs`: concluído; DI regenerada. O comando
  repetiu avisos preexistentes de dependências não registradas em outros módulos.

## Commit e push

Não realizados, conforme instrução explícita desta rodada.
