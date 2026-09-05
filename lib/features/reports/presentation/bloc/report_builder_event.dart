import '../../domain/entities/report_definition.dart';

sealed class ReportBuilderEvent {
  const ReportBuilderEvent();
}

final class ReportBuilderStarted extends ReportBuilderEvent {
  const ReportBuilderStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });
  final String organizationId;
  final String companyId;
  final String userId;
}

final class ReportDimensionToggled extends ReportBuilderEvent {
  const ReportDimensionToggled(this.id);
  final String id;
}

final class ReportMetricToggled extends ReportBuilderEvent {
  const ReportMetricToggled(this.id);
  final String id;
}

final class ReportFilterChanged extends ReportBuilderEvent {
  const ReportFilterChanged(this.filter);
  final ReportFilter filter;
}

final class ReportComparisonChanged extends ReportBuilderEvent {
  const ReportComparisonChanged(this.value);
  final ReportComparisonPeriod value;
}

final class ReportSortChanged extends ReportBuilderEvent {
  const ReportSortChanged(this.value);
  final ReportSort? value;
}

final class ReportExecutionRequested extends ReportBuilderEvent {
  const ReportExecutionRequested();
}

final class ReportBuilderRetried extends ReportBuilderEvent {
  const ReportBuilderRetried();
}
