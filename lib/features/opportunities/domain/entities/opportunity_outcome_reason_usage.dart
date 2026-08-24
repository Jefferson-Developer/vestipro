import '../value_objects/opportunity_outcome_type.dart';

final class OpportunityOutcomeReasonUsage {
  const OpportunityOutcomeReasonUsage({
    required this.reasonId,
    required this.description,
    required this.type,
    required this.count,
  });

  final String reasonId;
  final String description;
  final OpportunityOutcomeType type;
  final int count;
}
