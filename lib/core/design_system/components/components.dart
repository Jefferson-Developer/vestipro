/// Reusable Design System components: the widgets every feature composes
/// screens from (buttons, inputs, selection, chips, badges and feedback
/// states). Every component here consumes tokens from
/// `design_system/foundations/` exclusively — none defines its own color,
/// spacing, radius, shadow or typography value.
///
/// Exported from the `design_system.dart` barrel; features must not import
/// a file inside `components/` directly.
library;

export 'badges/app_status_badge.dart';
export 'buttons/app_button.dart';
export 'buttons/app_icon_button.dart';
export 'chips/app_filter_chip.dart';
export 'feedback/app_empty_state.dart';
export 'feedback/app_error_state.dart';
export 'feedback/app_skeleton.dart';
export 'inputs/app_number_field.dart';
export 'inputs/app_search_field.dart';
export 'inputs/app_text_field.dart';
export 'selection/app_dropdown.dart';
