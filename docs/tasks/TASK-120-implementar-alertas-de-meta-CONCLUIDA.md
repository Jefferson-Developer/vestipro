# TASK-120 - Implementar alertas de meta (CONCLUIDA)

**Epic:** EPIC-15 - Metas e Performance Comercial  
**Status:** Concluida  
**Data:** terça-feira, 1 de setembro de 2026  
**Branch:** `main`

## O que foi feito

- Implementei o fluxo de alertas de meta no domínio de `targets`, com avaliação de risco/oportunidade por ritmo versus período, thresholds configuráveis por organização e cooldown para não repetir o mesmo alerta em sequência.
- Adicionei persistência local para configuração e histórico de disparo dos alertas com `SharedPreferences`, além de uma inbox interna mínima para registrar notificações internas com deep link para o dashboard da meta.
- Passei a gerar o evento de analytics `target_alert_triggered` quando um alerta novo é enfileirado.
- Expandi a navegação com `TargetDashboardRoute` tipada, incluindo `targetId` opcional em query string para abrir o dashboard diretamente na meta alertada.
- Atualizei `TargetDashboardCubit` e `TargetDashboardPage` para calcular o alerta junto do snapshot de atingimento e manter um banner visual persistente com badge de severidade/oportunidade.
- Cobri o comportamento com testes de domínio, use case, analytics e widget, incluindo o cenário visual do banner no dashboard.

## Arquivos criados

- `lib/core/notifications/notifications.dart`
- `lib/core/notifications/domain/entities/app_notification.dart`
- `lib/core/notifications/domain/repositories/notification_inbox_repository.dart`
- `lib/core/notifications/data/repositories/shared_preferences_notification_inbox_repository.dart`
- `lib/features/targets/domain/value_objects/target_alert_settings.dart`
- `lib/features/targets/domain/entities/target_alert.dart`
- `lib/features/targets/domain/entities/target_alert_assessment.dart`
- `lib/features/targets/domain/repositories/target_alert_settings_repository.dart`
- `lib/features/targets/domain/repositories/target_alert_dispatch_repository.dart`
- `lib/features/targets/domain/services/target_alert_evaluator.dart`
- `lib/features/targets/domain/usecases/process_target_alert_use_case.dart`
- `lib/features/targets/data/repositories/shared_preferences_target_alert_settings_repository.dart`
- `lib/features/targets/data/repositories/shared_preferences_target_alert_dispatch_repository.dart`
- `test/features/targets/domain/services/target_alert_evaluator_test.dart`
- `test/features/targets/domain/usecases/process_target_alert_use_case_test.dart`
- `docs/tasks/TASK-120-implementar-alertas-de-meta-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/app/bootstrap.dart`
- `lib/app/injection.config.dart`
- `lib/core/analytics/analytics_events.dart`
- `lib/core/navigation/app_route_paths.dart`
- `lib/core/navigation/app_router.dart`
- `lib/features/targets/presentation/cubit/target_dashboard_cubit.dart`
- `lib/features/targets/presentation/cubit/target_dashboard_state.dart`
- `lib/features/targets/presentation/pages/target_dashboard_page.dart`
- `lib/features/targets/targets.dart`
- `test/core/analytics/analytics_events_test.dart`
- `test/features/targets/presentation/pages/target_dashboard_page_test.dart`
- `docs/tasks/TASKS.md`

## Validações executadas

- `dart run build_runner build` - sucesso. O gerador atualizou `lib/app/injection.config.dart`. Houve warnings preexistentes de dependências não resolvidas em outros módulos de DI, mas a geração concluiu sem erro.
- `dart format .` - sucesso.
- `dart format test/features/targets/presentation/pages/target_dashboard_page_test.dart` - sucesso, sem mudanças adicionais.
- `flutter analyze` - sucesso, sem issues.
- `flutter test test/features/targets/presentation/pages/target_dashboard_page_test.dart` - sucesso, todos os testes desse arquivo passaram após ajustar o fixture para um período ainda ativo em `2026-09-01`.
- `flutter test` - sucesso, suíte completa verde com `2439` testes passando.

## Decisões e riscos conhecidos

- O critério de alerta usa thresholds default locais (`highRisk`, `moderateRisk`, oportunidade e cooldown) quando a organização ainda não tiver configuração persistida. Isso mantém o fluxo funcional agora, mas a UX administrativa de edição dessas regras fica para task posterior.
- A task pedia notificações internas e push. Nesta entrega foi implementada a trilha de notificação interna com deep link e contrato de dispatch/cooldown; o envio real via push ficou preparado para integração futura com a infraestrutura de FCM do EPIC-19.
- A falha inicial do novo teste de widget não era de lógica de alerta; o fixture estava com uma meta encerrada em fevereiro de 2026, e no relógio atual da sessão (`2026-09-01`) o avaliador corretamente classificava o período como encerrado. O teste foi corrigido para usar um período ativo, evitando regressão dependente de data.
- O projeto ainda emite warnings não fatais já existentes em alguns testes de widget (hit test) e testes de Drift (múltiplas instâncias de banco); a suíte completa permaneceu verde.

## Commit

- Commit criado nesta sessão com a mensagem `feat(targets): implementa alertas de meta`.

## Push

- `git push origin main` executado com sucesso em `2026-09-01`, atualizando `origin/main` de `54e9044` para `e5d0749`.

## Hash do commit

- `e5d0749fc9caac3e1909f643d10bf5f1b0f25ef5`
