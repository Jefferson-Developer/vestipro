# TASK-141 — Implementar dashboard de funil (CRM) (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

- Dashboard de funil com etapas configuráveis da TASK-058, mantendo inclusive etapas sem
  oportunidades.
- Contagem e valor total sempre exibidos juntos por etapa, pipeline ponderado pela probabilidade,
  conversão para a etapa seguinte e aging médio calculado apenas sobre oportunidades abertas.
- Ranking de motivos de perda por período e filtro pela etapa em que a perda ocorreu.
- Registro de `outcomeFromStageId` ao encerrar uma oportunidade como perdida, preservando a etapa
  de origem mesmo quando o card é movido para uma coluna terminal.
- RBAC de escopo: representantes/assistentes consultam somente o próprio funil; gestores consultam
  membros das equipes geridas; OWNER/ADMIN/FINANCE podem consultar a organização.
- UI responsiva: lista/cards no mobile e etapas empilhadas horizontalmente no desktop, com estados
  de loading, erro, vazio e sem permissão.
- Drill-down por etapa por callback de navegação e rota tipada
  `/org/:orgId/companies/:companyId/dashboards/funnel`.
- Analytics `dashboard_viewed` com `dashboard_type: funnel` e filtros técnicos do escopo.

## Arquitetura e decisões

- `BuildFunnelDashboardSnapshotUseCase` concentra todas as fórmulas; widgets apenas formatam os
  resultados.
- `LoadFunnelDashboardUseCase` compõe as fontes canônicas já existentes de etapas e oportunidades,
  aplica período e RBAC antes de montar o snapshot. O BLoC apenas coordena estados e analytics.
- A TASK-133 não criou uma dimensão server-side de oportunidades: seu `AggregationRepository`
  atual contém agregados de pedidos/vendas, enquanto o módulo de oportunidades ainda persiste por
  `OpportunityRepository`. Usar uma dimensão de vendas para representar CRM produziria métricas
  incorretas; por isso esta implementação usa uma única leitura limitada pelo contrato existente
  do pipeline e gera o snapshot de funil no domínio. Quando oportunidades migrarem para Firestore,
  esse loader é o ponto único para trocar a fonte por snapshots server-side sem alterar BLoC/UI.
- Conversão segue a fórmula disponível no modelo atual: `contagem da próxima etapa / contagem da
  etapa atual * 100`; etapa vazia produz 0%, nunca divisão por zero.
- Pipeline ponderado soma `revenueForecast`, valor derivado canônico de
  `estimatedValue * probability / 100` já mantido pela entidade Opportunity.

## Principais arquivos

- `lib/features/dashboards/domain/entities/funnel_dashboard_*.dart`
- `lib/features/dashboards/domain/services/funnel_dashboard_visibility_service.dart`
- `lib/features/dashboards/domain/usecases/build_funnel_dashboard_snapshot_use_case.dart`
- `lib/features/dashboards/domain/usecases/load_funnel_dashboard_use_case.dart`
- `lib/features/dashboards/presentation/bloc/funnel_dashboard_*.dart`
- `lib/features/dashboards/presentation/pages/funnel_dashboard_page.dart`
- `lib/features/opportunities/domain/entities/opportunity.dart`
- `lib/features/opportunities/domain/usecases/mark_opportunity_lost_use_case.dart`
- `lib/core/navigation/app_route_paths.dart`, `lib/core/navigation/app_router.dart`
- `lib/app/bootstrap.dart`, `lib/app/injection.config.dart`

## Testes e validações

- `flutter test` direcionado a dashboard, BLoC, widget, encerramento de oportunidade e mapper:
  **19 testes aprovados**.
- Coberturas verificadas: carregamento completo, etapa vazia, conversão, pipeline ponderado, aging
  somente de oportunidades abertas, ranking/filtro de motivos de perda, negação RBAC, cards mobile,
  etapas empilhadas desktop e drill-down.
- `flutter analyze` direcionado aos arquivos de dashboard, navegação, bootstrap e testes: **nenhum
  problema encontrado**.
- `dart run build_runner build`: concluído; gerou Freezed de `Opportunity` e registros de DI. O
  generator repetiu avisos preexistentes de dependências não registradas em outros módulos.

## Commit e push

Não realizados, conforme instrução explícita desta rodada.
