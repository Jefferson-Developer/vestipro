import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/pipeline_stage_terminal_type.dart';

part 'pipeline_stage.freezed.dart';

/// A configurable column of the sales pipeline/funnel (TASK-058), scoped by
/// [organizationId].
///
/// [order] is a dense, zero-based rank among the organization's stages,
/// always kept contiguous by `ReorderPipelineStagesUseCase` — no other code
/// may write it directly. [colorHex] is the visual indicator shown on the
/// column header/badge (`'#RRGGBB'`), validated by
/// `CreatePipelineStageUseCase`/`RenamePipelineStageUseCase`.
///
/// [terminalType] is fixed at creation and never changed afterwards (not
/// even by `RenamePipelineStageUseCase`, which only edits [name]/[colorHex]):
/// retroactively turning a routine column into a won/lost outcome (or vice
/// versa) would silently reinterpret every Opportunity already sitting in
/// it. A stage whose [terminalType] is not
/// [PipelineStageTerminalType.none] (see [isTerminal]) is the only kind of
/// column `SalesPipelineBloc` allows an Opportunity to enter through the
/// mandatory-reason won/lost flow instead of a plain stage move.
@freezed
abstract class PipelineStage with _$PipelineStage {
  const PipelineStage._();

  const factory PipelineStage({
    required String id,
    required String organizationId,
    required String name,
    required int order,
    required String colorHex,
    required PipelineStageTerminalType terminalType,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    required int version,
  }) = _PipelineStage;

  bool get isTerminal => terminalType != PipelineStageTerminalType.none;
}
