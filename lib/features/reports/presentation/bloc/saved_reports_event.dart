import '../../domain/entities/report_definition.dart';
import '../../domain/entities/saved_report.dart';

sealed class SavedReportsEvent {
  const SavedReportsEvent();
}

final class SavedReportsStarted extends SavedReportsEvent {
  const SavedReportsStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class SavedReportsRetried extends SavedReportsEvent {
  const SavedReportsRetried();
}

/// Saves the report builder's (TASK-144) current `ReportDefinition` as a new
/// [SavedReport].
final class SavedReportCreateRequested extends SavedReportsEvent {
  const SavedReportCreateRequested({
    required this.name,
    required this.definition,
    this.visibility = SavedReportVisibility.private,
  });

  final String name;
  final ReportDefinition definition;
  final SavedReportVisibility visibility;
}

final class SavedReportRenameRequested extends SavedReportsEvent {
  const SavedReportRenameRequested(this.report, this.newName);

  final SavedReport report;
  final String newName;
}

final class SavedReportVisibilityChangeRequested extends SavedReportsEvent {
  const SavedReportVisibilityChangeRequested(this.report, this.visibility);

  final SavedReport report;
  final SavedReportVisibility visibility;
}

final class SavedReportFavoriteToggleRequested extends SavedReportsEvent {
  const SavedReportFavoriteToggleRequested(this.report);

  final SavedReport report;
}

final class SavedReportDuplicateRequested extends SavedReportsEvent {
  const SavedReportDuplicateRequested(this.report, this.newName);

  final SavedReport report;
  final String newName;
}

/// Loads [report]'s definition back into the report builder (TASK-144) for
/// re-execution — see `OpenSavedReportInBuilder`.
final class SavedReportOpenRequested extends SavedReportsEvent {
  const SavedReportOpenRequested(this.report);

  final SavedReport report;
}

final class SavedReportOpenedMessageCleared extends SavedReportsEvent {
  const SavedReportOpenedMessageCleared();
}

final class SavedReportDeleteRequested extends SavedReportsEvent {
  const SavedReportDeleteRequested(this.report);

  final SavedReport report;
}

final class SavedReportsMessageCleared extends SavedReportsEvent {
  const SavedReportsMessageCleared();
}
