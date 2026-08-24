import '../../../../core/errors/errors.dart';
import '../value_objects/pipeline_stage_terminal_type.dart';

final RegExp _hexColorPattern = RegExp(r'^#[0-9a-fA-F]{6}$');

/// Whether [value] is a valid `'#RRGGBB'` color indicator for a
/// [PipelineStage].
bool isValidPipelineStageColor(String value) =>
    _hexColorPattern.hasMatch(value);

/// Builds the failure returned when a use case tries to create a second
/// stage with the same non-[PipelineStageTerminalType.none] [terminalType]
/// inside the same organization. Each organization may have at most one
/// "won" stage and one "lost" stage, so `SalesPipelineBloc` can always
/// resolve a single unambiguous target when it needs to close an
/// Opportunity.
Failure duplicateTerminalPipelineStageFailure({
  required PipelineStageTerminalType terminalType,
}) {
  return ValidationFailure(
    'Organization already has a $terminalType pipeline stage.',
    fieldErrors: const <String, String>{
      'terminalType': 'Only one stage per terminal outcome is allowed.',
    },
    code: 'duplicate_terminal_pipeline_stage',
  );
}

/// Builds the failure returned when `ReorderPipelineStagesUseCase` receives
/// an `orderedStageIds` list that is not exactly the organization's current
/// full stage id set (missing id, unknown id, or duplicate).
Failure invalidPipelineStageReorderSetFailure() {
  return const ValidationFailure(
    'orderedStageIds must contain exactly the organization\'s current '
    'stages, once each.',
    fieldErrors: <String, String>{
      'orderedStageIds': 'Invalid pipeline stage reorder set.',
    },
    code: 'invalid_pipeline_stage_reorder_set',
  );
}
