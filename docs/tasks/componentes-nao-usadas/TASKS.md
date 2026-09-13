# Tasks - telas e componentes sem uso em producao

Levantamento gerado em 2026-09-13 a partir de varredura estatica em `lib`.

Critério: classes publicas em `presentation/pages`, `presentation/widgets` e componentes/layouts do Design System que nao aparecem instanciadas/chamadas no codigo de producao. Itens marcados como "so teste" aparecem em testes, mas nao em fluxos reais do app.

## Telas para inserir no projeto

- [ ] [TASK-CNU-001 - Inserir telas sem uso na navegacao e fluxos do app](TASK-CNU-001-inserir-telas-sem-uso-na-navegacao.md)

### Checklist por tela

- [ ] `BackorderQueuePage` - `lib/features/backorder/presentation/pages/backorder_queue_page.dart`
- [ ] `CampaignsPage` - `lib/features/catalog/presentation/pages/campaigns_page.dart` - so teste
- [ ] `LookbookPage` - `lib/features/catalog/presentation/pages/lookbook_page.dart` - so teste
- [ ] `ProductGridPage` - `lib/features/catalog/presentation/pages/product_grid_page.dart` - so teste
- [ ] `CommissionStatementPage` - `lib/features/commissions/presentation/pages/commission_statement_page.dart`
- [ ] `CrmTaskListPage` - `lib/features/crm/presentation/pages/crm_task_list_page.dart` - so teste
- [ ] `FavoritesPage` - `lib/features/favorites/presentation/pages/favorites_page.dart` - so teste
- [ ] `StockAlertsPage` - `lib/features/inventory/presentation/pages/stock_alerts_page.dart` - so teste
- [ ] `InviteListPage` - `lib/features/invites/presentation/pages/invite_list_page.dart`
- [ ] `InviteUserPage` - `lib/features/invites/presentation/pages/invite_user_page.dart`
- [ ] `LeadFormPage` - `lib/features/leads/presentation/pages/lead_form_page.dart` - so teste
- [ ] `LeadListPage` - `lib/features/leads/presentation/pages/lead_list_page.dart` - so teste
- [ ] `LineSheetPage` - `lib/features/line_sheets/presentation/pages/line_sheet_page.dart` - so teste
- [ ] `OpportunityOutcomeReasonAdminPage` - `lib/features/opportunities/presentation/pages/opportunity_outcome_reason_admin_page.dart` - so teste
- [ ] `PipelineStageAdminPage` - `lib/features/opportunities/presentation/pages/pipeline_stage_admin_page.dart` - so teste
- [ ] `SalesPipelinePage` - `lib/features/opportunities/presentation/pages/sales_pipeline_page.dart` - so teste
- [ ] `CommercialPackPickerPage` - `lib/features/orders/presentation/pages/commercial_pack_picker_page.dart`
- [ ] `RecurringOrderPlanPage` - `lib/features/orders/presentation/pages/recurring_order_plan_page.dart` - so teste
- [ ] `BrandingSettingsPage` - `lib/features/organizations/presentation/pages/branding_settings_page.dart` - so teste
- [ ] `PreBookProgramPage` - `lib/features/pre_book/presentation/pages/pre_book_program_page.dart` - so teste
- [ ] `DiscountPoliciesPage` - `lib/features/pricing/presentation/pages/discount_policies_page.dart` - so teste
- [ ] `PaymentTermsPage` - `lib/features/pricing/presentation/pages/payment_terms_page.dart` - so teste
- [ ] `PriceListItemBatchPage` - `lib/features/pricing/presentation/pages/price_list_item_batch_page.dart`
- [ ] `PromotionalCampaignsPage` - `lib/features/pricing/presentation/pages/promotional_campaigns_page.dart` - so teste
- [ ] `CategoriesPage` - `lib/features/products/presentation/pages/categories_page.dart` - so teste
- [ ] `CollectionsPage` - `lib/features/products/presentation/pages/collections_page.dart` - so teste
- [ ] `ProductColorPalettePage` - `lib/features/products/presentation/pages/product_color_palette_page.dart` - so teste
- [ ] `SeasonsPage` - `lib/features/products/presentation/pages/seasons_page.dart`
- [ ] `SizeGridTemplatesPage` - `lib/features/products/presentation/pages/size_grid_templates_page.dart` - so teste
- [ ] `ReportSchedulesPage` - `lib/features/reports/presentation/pages/report_schedules_page.dart`
- [ ] `PositivacaoDashboardPage` - `lib/features/targets/presentation/pages/positivacao_dashboard_page.dart` - so teste
- [ ] `PositivacaoSettingsFormPage` - `lib/features/targets/presentation/pages/positivacao_settings_form_page.dart`
- [ ] `RankingDashboardPage` - `lib/features/targets/presentation/pages/ranking_dashboard_page.dart` - so teste
- [ ] `TargetFormPage` - `lib/features/targets/presentation/pages/target_form_page.dart` - so teste
- [ ] `AssignPortfolioPage` - `lib/features/users/presentation/pages/assign_portfolio_page.dart` - so teste
- [ ] `TeamListPage` - `lib/features/users/presentation/pages/team_list_page.dart` - so teste

## Componentes para revisar

- [ ] [TASK-CNU-002 - Revisar componentes sem uso em producao](TASK-CNU-002-revisar-componentes-sem-uso.md)
