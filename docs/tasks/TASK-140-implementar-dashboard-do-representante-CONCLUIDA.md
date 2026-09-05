# TASK-140 — Implementar dashboard do representante (CONCLUÍDA)

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ✅ Concluída

## O que foi implementado

- Dashboard individual com `RepresentativeDashboardBloc`, use case composto e rota tipada por
  organização, empresa e vendedor.
- KPIs de venda do dia, venda do mês, atingimento de meta, positivação da carteira e posição no
  ranking da equipe, sempre a partir de snapshots/agregações server-side.
- Nova dimensão `sellerDaily`, recalculada junto de `salesDaily` a cada alteração de pedido, e
  `representativeMonthly`, uma cópia com leitura individual protegida do agregado mensal que inclui
  ranking determinístico da equipe. O `sellerMonthly` gerencial existente foi preservado para não
  quebrar as consultas consolidadas das tasks anteriores.
- Follow-ups pendentes/vencidos ordenados por vencimento, com callback de navegação para o contexto
  CRM, e carteira resumida priorizando clientes com insight ativo.
- Layout mobile-first de uma coluna e grades com múltiplas colunas em tablet/Web, reutilizando
  `AppKpiCard` e tokens do Design System.
- Evento `dashboard_viewed` com `dashboard_type: representative`, sem dados pessoais nos parâmetros.

## Segurança, escopo e offline

- `RepresentativeDashboardVisibilityService` permite ao vendedor apenas o próprio painel; gestor
  acessa somente vendedores com equipe compartilhada; OWNER/ADMIN mantêm visão administrativa.
- `firestore.rules` aplica o mesmo escopo nos documentos `sellerDailyAggregates` e
  `sellerMonthlyAggregates`, relendo Memberships reais. Escritas do cliente seguem negadas.
- O `AggregationRepositoryImpl` agora persiste o último snapshot válido e o recupera após reinício
  quando a leitura remota falha. A UI sinaliza explicitamente uso offline e horário da última
  atualização.

## Testes e validações

- `flutter test test/features/dashboards` — 173 testes aprovados, incluindo BLoC (carga completa,
  meta ausente, follow-ups vazios e cache offline), RBAC, responsividade mobile/desktop e integração
  do atalho de follow-up com o fluxo CRM.
- `npm test -- --runInBand test/aggregations/aggregation-builders.test.ts test/aggregations/recompute-sales-daily-on-order-write.test.ts test/aggregations/recompute-monthly-aggregates.test.ts`
  — 27 testes aprovados, incluindo isolamento da venda diária por vendedor, ranking de equipe e a
  cópia mensal com leitura individual.
- `flutter analyze lib test` — sem erros/warnings; permaneceu com 6 infos preexistentes de
  `use_null_aware_elements` em testes das TASK-136 a TASK-138.
- `npm run build` e `npm run lint` em `functions/` — aprovados.
- A suíte unitária completa de agregações também passou; a variante
  `recompute-monthly-aggregates.emulator.test.ts` não pôde ser executada isoladamente sem o
  Firestore Emulator/credenciais locais (falha ambiental esperada: `Could not load the default
  credentials`).
- `flutter pub run build_runner build` — injeção de dependências regenerada; apenas avisos de
  dependências ausentes já preexistentes no projeto.
- `git diff --check` — somente reportou a linha em branco final de `AGENTS.md`, alteração
  preexistente e preservada.

## Arquivos principais

- `lib/features/dashboards/domain/entities/representative_*.dart`
- `lib/features/dashboards/domain/services/representative_dashboard_visibility_service.dart`
- `lib/features/dashboards/domain/usecases/load_representative_dashboard_use_case.dart`
- `lib/features/dashboards/presentation/bloc/representative_dashboard_*.dart`
- `lib/features/dashboards/presentation/pages/representative_dashboard_page.dart`
- `functions/src/aggregations/*`, `firestore.rules` e `firestore.indexes.json`
- `lib/core/navigation/*`, `lib/app/bootstrap.dart` e `lib/app/injection.config.dart`

## Commit e push

Não realizados, conforme solicitação explícita do usuário para executar o lote sem commit.
