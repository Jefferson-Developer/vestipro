import 'insight_dataset.dart';

final class InsightContext {
  const InsightContext({
    required this.organizationId,
    required this.companyId,
    required this.asOf,
    required this.dataset,
  });

  final String organizationId;
  final String companyId;
  final DateTime asOf;
  final InsightDataset dataset;
}
