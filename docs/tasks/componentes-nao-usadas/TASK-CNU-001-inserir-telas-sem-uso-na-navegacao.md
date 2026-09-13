# TASK-CNU-001 - Inserir telas sem uso na navegacao e fluxos do app

**Epic:** Debito tecnico - navegacao e composicao de features
**Status:** Pendente
**Origem:** Varredura estatica em `lib` em 2026-09-13

## Agentes obrigatorios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Conectar as telas ja implementadas, mas nao chamadas em producao, aos fluxos reais do VestiPro. Cada tela deve ter uma decisao explicita: criar rota/menu/atalho, integrar como subfluxo de uma tela existente, ou documentar remocao/adiamento quando a tela nao fizer mais sentido.

## Escopo tecnico

- Declarar rotas tipadas em `lib/core/navigation/app_route_paths.dart` quando a tela precisar de URL/deep link.
- Registrar `GoRoute` e page builder em `lib/core/navigation/app_router.dart`.
- Ligar builders reais em `lib/app/bootstrap.dart` com `_withAuthenticatedMenu`, `_withConnectivityIndicator`, RBAC e DI corretos.
- Adicionar atalhos de menu, acoes de pagina ou navegacao contextual onde fizer sentido.
- Preservar RBAC por `Capability` e escopo `organizationId`/`companyId`.
- Criar ou ajustar testes de rota/widget para provar que a tela ficou alcancavel.

## Telas a inserir ou decidir

### Backorder

- `BackorderQueuePage` - `lib/features/backorder/presentation/pages/backorder_queue_page.dart`
  - Sugestao: rota em pedidos/estoque para fila de backorders.

### Catalogo

- `CampaignsPage` - `lib/features/catalog/presentation/pages/campaigns_page.dart`
  - Sugestao: tela administrativa de campanhas/lookbooks no menu Catalogo.
- `LookbookPage` - `lib/features/catalog/presentation/pages/lookbook_page.dart`
  - Sugestao: rota de detalhe/visualizacao de campanha.
- `ProductGridPage` - `lib/features/catalog/presentation/pages/product_grid_page.dart`
  - Sugestao: confirmar se foi substituida por `CatalogFilterPage`; se sim, remover ou documentar legado.

### Comissoes

- `CommissionStatementPage` - `lib/features/commissions/presentation/pages/commission_statement_page.dart`
  - Sugestao: rota em Relatorios ou area do vendedor/gestor.

### CRM e leads

- `CrmTaskListPage` - `lib/features/crm/presentation/pages/crm_task_list_page.dart`
  - Sugestao: rota em Clientes/Oportunidades.
- `LeadListPage` - `lib/features/leads/presentation/pages/lead_list_page.dart`
  - Sugestao: rota em Clientes/Oportunidades.
- `LeadFormPage` - `lib/features/leads/presentation/pages/lead_form_page.dart`
  - Sugestao: rota/acao "Novo lead" a partir da lista de leads.

### Favoritos e estoque

- `FavoritesPage` - `lib/features/favorites/presentation/pages/favorites_page.dart`
  - Sugestao: atalho no Catalogo ou perfil do vendedor.
- `StockAlertsPage` - `lib/features/inventory/presentation/pages/stock_alerts_page.dart`
  - Sugestao: rota em Estoque/Dashboards.

### Convites e usuarios

- `InviteListPage` - `lib/features/invites/presentation/pages/invite_list_page.dart`
  - Sugestao: subrota de usuarios/administracao.
- `InviteUserPage` - `lib/features/invites/presentation/pages/invite_user_page.dart`
  - Sugestao: acao "Convidar usuario" a partir da lista de convites/usuarios.
- `AssignPortfolioPage` - `lib/features/users/presentation/pages/assign_portfolio_page.dart`
  - Sugestao: acao dentro de gestao de usuarios.
- `TeamListPage` - `lib/features/users/presentation/pages/team_list_page.dart`
  - Sugestao: subrota de gestao comercial/usuarios.

### Line sheet e pre-book

- `LineSheetPage` - `lib/features/line_sheets/presentation/pages/line_sheet_page.dart`
  - Sugestao: rota no Catalogo ou fluxo de venda B2B.
- `PreBookProgramPage` - `lib/features/pre_book/presentation/pages/pre_book_program_page.dart`
  - Sugestao: rota em Catalogo/Colecoes ou Pedidos.

### Oportunidades

- `OpportunityOutcomeReasonAdminPage` - `lib/features/opportunities/presentation/pages/opportunity_outcome_reason_admin_page.dart`
  - Sugestao: administracao de motivos de fechamento.
- `PipelineStageAdminPage` - `lib/features/opportunities/presentation/pages/pipeline_stage_admin_page.dart`
  - Sugestao: administracao de etapas do funil.
- `SalesPipelinePage` - `lib/features/opportunities/presentation/pages/sales_pipeline_page.dart`
  - Sugestao: tela principal do funil em Oportunidades.

### Pedidos e sortimentos

- `CommercialPackPickerPage` - `lib/features/orders/presentation/pages/commercial_pack_picker_page.dart`
  - Sugestao: subfluxo do pedido para escolher kit/pacote/sortimento.
- `RecurringOrderPlanPage` - `lib/features/orders/presentation/pages/recurring_order_plan_page.dart`
  - Sugestao: rota em pedidos recorrentes.

### Organizacoes e precificacao

- `BrandingSettingsPage` - `lib/features/organizations/presentation/pages/branding_settings_page.dart`
  - Sugestao: rota em Ajustes/Organizacao.
- `DiscountPoliciesPage` - `lib/features/pricing/presentation/pages/discount_policies_page.dart`
  - Sugestao: rota em Politica comercial.
- `PaymentTermsPage` - `lib/features/pricing/presentation/pages/payment_terms_page.dart`
  - Sugestao: rota em Politica comercial.
- `PriceListItemBatchPage` - `lib/features/pricing/presentation/pages/price_list_item_batch_page.dart`
  - Sugestao: acao de edicao em massa a partir de listas de preco.
- `PromotionalCampaignsPage` - `lib/features/pricing/presentation/pages/promotional_campaigns_page.dart`
  - Sugestao: rota em campanhas/promocoes.

### Produtos

- `CategoriesPage` - `lib/features/products/presentation/pages/categories_page.dart`
  - Sugestao: rota administrativa em Catalogo para cadastrar categorias/subcategorias usadas por `ProductFormPage`.
- `CollectionsPage` - `lib/features/products/presentation/pages/collections_page.dart`
  - Sugestao: rota administrativa em Catalogo.
- `ProductColorPalettePage` - `lib/features/products/presentation/pages/product_color_palette_page.dart`
  - Sugestao: rota administrativa em Catalogo para paleta reutilizavel.
- `SeasonsPage` - `lib/features/products/presentation/pages/seasons_page.dart`
  - Sugestao: rota administrativa em Catalogo.
- `SizeGridTemplatesPage` - `lib/features/products/presentation/pages/size_grid_templates_page.dart`
  - Sugestao: rota administrativa em Catalogo para grades de tamanho.

### Relatorios e metas

- `ReportSchedulesPage` - `lib/features/reports/presentation/pages/report_schedules_page.dart`
  - Sugestao: rota em Relatorios.
- `PositivacaoDashboardPage` - `lib/features/targets/presentation/pages/positivacao_dashboard_page.dart`
  - Sugestao: rota em Dashboards/Metas.
- `PositivacaoSettingsFormPage` - `lib/features/targets/presentation/pages/positivacao_settings_form_page.dart`
  - Sugestao: configuracao a partir do dashboard de positivacao.
- `RankingDashboardPage` - `lib/features/targets/presentation/pages/ranking_dashboard_page.dart`
  - Sugestao: rota em Dashboards/Metas.
- `TargetFormPage` - `lib/features/targets/presentation/pages/target_form_page.dart`
  - Sugestao: acao de criacao/edicao de metas.

## Regras de negocio e restricoes

- Nao expor telas administrativas a perfis sem permissao.
- Nao criar rota publica para dados tenant-scoped.
- Nao ligar telas em menu sem validar se a feature ainda e vigente ou foi substituida.
- Quando uma tela for legado real, documentar a decisao e remover com testes, em task propria.

## Testes obrigatorios

- Testes de rota para cada nova rota tipada.
- Testes de permissionamento quando houver `Capability`.
- Testes de widget ou navegação cobrindo pelo menos um caminho real ate cada tela ligada.

## Criterios de aceite

- Cada tela listada tem uma decisao explicita registrada.
- Telas mantidas ficam alcancaveis por rota, menu ou acao contextual.
- Telas removidas/adiadas tem justificativa documentada.
- `dart format --set-exit-if-changed .`, `flutter analyze` e `flutter test` sem erros.

## Referencias

- `AGENTS.md`
- `lib/core/navigation/app_route_paths.dart`
- `lib/core/navigation/app_router.dart`
- `lib/app/bootstrap.dart`
- `docs/tasks/componentes-nao-usadas/TASKS.md`
