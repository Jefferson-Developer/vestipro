# TASK-093 — Concluída (2026-08-28)

## Resumo
Implementação da trilha de alertas de ruptura com thresholds por organização/produto/variante, trigger server-side com deduplicação por cruzamento de fronteira e tela administrativa de listagem com filtros por severidade, produto e unidade.

## Agentes utilizados
- flutter-senior-architect
- flutter-ui-design-specialist

## Arquivos criados
- `lib/features/inventory/domain/value_objects/stock_alert_level.dart`
- `lib/features/inventory/domain/value_objects/stock_alert_transition_type.dart`
- `lib/features/inventory/domain/entities/stock_alert_rule.dart`
- `lib/features/inventory/domain/entities/stock_alert.dart`
- `lib/features/inventory/domain/entities/stock_alert_page.dart`
- `lib/features/inventory/domain/repositories/stock_alert_repository.dart`
- `lib/features/inventory/domain/usecases/list_stock_alerts_use_case.dart`
- `lib/features/inventory/data/dtos/stock_alert_dto.dart`
- `lib/features/inventory/data/mappers/stock_alert_mapper.dart`
- `lib/features/inventory/data/datasources/stock_alert_data_source.dart`
- `lib/features/inventory/data/datasources/firestore_stock_alert_data_source.dart`
- `lib/features/inventory/data/repositories/stock_alert_repository_impl.dart`
- `lib/features/inventory/presentation/bloc/stock_alert_list_event.dart`
- `lib/features/inventory/presentation/bloc/stock_alert_list_state.dart`
- `lib/features/inventory/presentation/bloc/stock_alert_list_bloc.dart`
- `lib/features/inventory/presentation/pages/stock_alerts_page.dart`
- `functions/src/inventory/stock-alert-shared.ts`
- `functions/src/inventory/sync-stock-alerts.ts`
- `functions/test/inventory/sync-stock-alerts.test.ts`

## Arquivos alterados
- `lib/features/inventory/inventory.dart`
- `functions/src/index.ts`
- `firestore.rules`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Feature-first + Clean Architecture no app (`domain/data/presentation`) e trigger Firestore dedicado no backend de `functions/src/inventory`.

## Regras de negócio implementadas
- Thresholds ativos podem ser definidos em nível de organização, produto ou variante, com desempate pela regra mais específica e refinamento opcional por unidade (`warehouseId`).
- Alertas só são gerados quando o saldo vendável cruza a fronteira configurada.
- Atualizações repetidas abaixo do mesmo limite não recriam alertas.
- Recuperações e agravamentos geram eventos distintos (`entered`, `escalated`, `deescalated`, `recovered`).
- Alertas permanecem informativos e não bloqueiam venda automaticamente.

## Regras Firebase implementadas
- Export da Cloud Function `syncStockAlerts` acionada em `organizations/{organizationId}/inventory/{inventoryId}`.
- Regras Firestore para leitura de `stockAlerts`, gestão de `stockAlertRules` por perfis com gestão sensível e bloqueio total de `stockAlertEvents` para cliente.

## Analytics implementado
Não aplicável nesta task.

## Crashlytics implementado
Não aplicável nesta task.

## Impacto offline
Sem impacto direto no fluxo offline atual; a listagem consome a coleção remota de alertas gerados pelo backend.

## Impacto multi-tenant
Todas as leituras e escritas seguem escopo `organizations/{organizationId}` e a seleção de regras/alertas é sempre tenant-scoped.

## Testes criados
- `functions/test/inventory/sync-stock-alerts.test.ts`
- `test/features/inventory/presentation/pages/stock_alerts_page_test.dart`

## Comandos executados
- `dart format lib/features/inventory test/features/inventory/presentation/pages/stock_alerts_page_test.dart`
- `flutter test test/features/inventory/presentation/pages/stock_alerts_page_test.dart`
- `flutter analyze`
- `npm test -- sync-stock-alerts`
- `npm run build`

## Resultado do formatter
Sucesso.

## Resultado do analyzer
Sucesso (`flutter analyze` sem issues).

## Resultado dos testes
Sucesso nos testes Flutter da página e nos testes Jest do trigger/helper de alertas.

## Decisões técnicas
- O trigger usa um adaptador de persistência para manter a lógica testável sem depender de credenciais do Admin SDK no ambiente local.
- O hook futuro para a central de notificações foi materializado como coleção `stockAlertEvents` com payload consumível por outro módulo.
- O controle de deduplicação foi resolvido comparando o nível anterior e o atual a partir do snapshot do saldo e do conjunto de regras aplicável.

## Riscos conhecidos
- Ainda não existe UI de cadastro/edição de thresholds; a estrutura e as regras de leitura/escrita já estão prontas para esse passo.
- A listagem exibe IDs de produto/variante/unidade; enriquecimento com nomes amigáveis pode ser feito depois sem refatoração estrutural.

## Pendências
- Integrar a emissão de `stockAlertEvents` à futura central de notificações da TASK-151.
- Criar UI de configuração de thresholds quando o backlog pedir esse fluxo operacional.

## Evidências
- Teste Flutter validando filtros, vazio e RBAC da tela.
- Teste TypeScript validando cruzamento para baixo/para cima, deduplicação e seleção da regra mais específica.

## Commit
Pendente no momento da criação deste documento.

## Push
Não autorizado nesta rodada.

## Hash do commit
Pendente no momento da criação deste documento.

## Branch
`main`
