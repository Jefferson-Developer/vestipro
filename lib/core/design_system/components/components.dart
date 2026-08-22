/// Reusable Design System components: the widgets every feature composes
/// screens from (buttons, inputs, selection, chips, badges, feedback states,
/// overlays — modals, bottom sheets, snackbars, tooltips and the
/// destructive confirmation dialog — data presentation — administrative
/// tables, KPI cards, management charts and pagination — and catalog/grade
/// components — product grid, color × size grade and quantity stepper).
/// Every component here consumes tokens from
/// `design_system/foundations/` exclusively — none defines its own color,
/// spacing, radius, shadow or typography value.
///
/// Exported from the `design_system.dart` barrel; features must not import
/// a file inside `components/` directly.
library;

export 'badges/app_status_badge.dart';
export 'buttons/app_button.dart';
export 'buttons/app_icon_button.dart';
export 'cards/app_kpi_card.dart';
export 'catalog/app_color_swatch_selector.dart';
export 'catalog/app_product_grid.dart';
export 'catalog/app_quantity_stepper.dart';
export 'catalog/app_size_grid.dart';
export 'charts/app_management_chart.dart';
export 'chips/app_filter_chip.dart';
export 'feedback/app_empty_state.dart';
export 'feedback/app_error_state.dart';
export 'feedback/app_skeleton.dart';
export 'feedback/app_snackbar.dart';
export 'inputs/app_number_field.dart';
export 'inputs/app_search_field.dart';
export 'inputs/app_text_field.dart';
export 'overlays/app_bottom_sheet.dart';
export 'overlays/app_confirmation_dialog.dart';
export 'overlays/app_modal.dart';
export 'overlays/app_tooltip.dart';
export 'selection/app_dropdown.dart';
export 'tables/app_data_table.dart';
export 'tables/app_pagination.dart';
