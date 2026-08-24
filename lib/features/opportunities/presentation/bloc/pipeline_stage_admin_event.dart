import '../../domain/value_objects/pipeline_stage_terminal_type.dart';

sealed class PipelineStageAdminEvent {
  const PipelineStageAdminEvent();
}

final class PipelineStageAdminStarted extends PipelineStageAdminEvent {
  const PipelineStageAdminStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class PipelineStageAdminRetried extends PipelineStageAdminEvent {
  const PipelineStageAdminRetried();
}

final class PipelineStageAdminStageCreated extends PipelineStageAdminEvent {
  const PipelineStageAdminStageCreated({
    required this.name,
    required this.colorHex,
    this.terminalType = PipelineStageTerminalType.none,
  });

  final String name;
  final String colorHex;
  final PipelineStageTerminalType terminalType;
}

final class PipelineStageAdminStageRenamed extends PipelineStageAdminEvent {
  const PipelineStageAdminStageRenamed({
    required this.stageId,
    required this.name,
    required this.colorHex,
  });

  final String stageId;
  final String name;
  final String colorHex;
}

/// Reflects the final drag order from the admin screen's
/// `ReorderableListView` — always the organization's full stage id set, in
/// the new desired order.
final class PipelineStageAdminStagesReordered extends PipelineStageAdminEvent {
  const PipelineStageAdminStagesReordered(this.orderedStageIds);

  final List<String> orderedStageIds;
}

final class PipelineStageAdminActionDismissed extends PipelineStageAdminEvent {
  const PipelineStageAdminActionDismissed();
}
