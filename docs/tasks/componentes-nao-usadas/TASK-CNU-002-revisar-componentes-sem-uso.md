# TASK-CNU-002 - Revisar componentes sem uso em producao

**Epic:** Debito tecnico - Design System e composicao de UI
**Status:** Pendente
**Origem:** Varredura estatica em `lib` em 2026-09-13

## Agentes obrigatorios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Revisar todos os componentes publicos que nao aparecem instanciados/chamados em producao e decidir, caso a caso, se devem ser integrados a fluxos reais, mantidos como API de Design System com documentacao/teste, ou removidos por obsolescencia.

## Componentes identificados

- `AppNumberField` - `lib/core/design_system/components/inputs/app_number_field.dart` - so teste
- `AppNotificationBellButton` - `lib/core/design_system/components/notifications/app_notification_bell_button.dart`
- `AppDataTableBatchAction` - `lib/core/design_system/components/tables/app_data_table.dart` - so teste
- `RepresentativeNextBestActionSection` - `lib/features/crm/presentation/widgets/next_best_action_card.dart`
- `DottedUploadArea` - `lib/features/customer_import/presentation/widgets/customer_import_upload_step.dart`
- `DataQualityScorePanel` - `lib/features/data_quality/presentation/widgets/data_quality_score_panel.dart` - so teste
- `DiscountValidationBanner` - `lib/features/pricing/presentation/widgets/discount_validation_banner.dart` - so teste
- `PaymentTermSelector` - `lib/features/pricing/presentation/widgets/payment_term_selector.dart` - so teste
- `PricingAdjustmentOriginCard` - `lib/features/pricing/presentation/widgets/pricing_adjustment_origin_card.dart` - so teste
- `CommercialSizeGrid` - `lib/features/products/presentation/widgets/commercial_size_grid.dart` - so teste
- `SampleInventoryPanel` - `lib/features/showroom_samples/presentation/widgets/sample_inventory_panel.dart` - so teste
- `TerritoryCoveragePanel` - `lib/features/territories/presentation/widgets/territory_coverage_panel.dart` - so teste

## Escopo tecnico

- Confirmar se cada componente continua alinhado ao design system e aos fluxos atuais.
- Integrar componentes reutilizaveis em telas reais quando houver ponto natural de uso.
- Remover componentes obsoletos apenas quando nao houver consumo planejado e os testes indicarem legado.
- Para componentes mantidos como API futura, documentar motivo, contrato visual e exemplo de uso.
- Atualizar exports se algum componente for removido ou promovido.

## Regras de negocio e restricoes

- Nao trocar componentes em telas criticas sem validar acessibilidade, responsividade e estados de erro/loading/empty.
- Nao remover componente de Design System apenas por nao estar em producao se ele for parte deliberada da API compartilhada.
- Nao deixar testes apontando para componente removido.

## Testes obrigatorios

- Teste de widget para qualquer componente alterado.
- Teste da tela consumidora quando um componente for integrado.
- Golden test quando houver impacto visual relevante.
- `dart format --set-exit-if-changed .`, `flutter analyze` e `flutter test` sem erros.

## Criterios de aceite

- Cada componente identificado tem uma decisao explicita: integrar, manter documentado ou remover.
- Componentes integrados aparecem em fluxo real de producao.
- Componentes removidos nao deixam exports, testes ou imports quebrados.
- A lista em `docs/tasks/componentes-nao-usadas/TASKS.md` e atualizada conforme as decisoes.

## Referencias

- `AGENTS.md`
- `lib/core/design_system/components/`
- `lib/core/design_system/layouts/`
- `docs/tasks/componentes-nao-usadas/TASKS.md`
