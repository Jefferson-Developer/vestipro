import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../entities/insight.dart';

@lazySingleton
final class InsightStructuralValidator {
  const InsightStructuralValidator();

  void validate(Insight insight) {
    if (insight.evidence.isEmpty) {
      throw const ValidationException(
        'Insight must include at least one evidence item.',
        code: 'insight_missing_evidence',
      );
    }
    if (!insight.estimatedImpact.hasValue) {
      throw const ValidationException(
        'Insight must include an estimated impact.',
        code: 'insight_missing_estimated_impact',
      );
    }
    if (insight.recommendation.trim().isEmpty) {
      throw const ValidationException(
        'Insight must include a recommendation.',
        code: 'insight_missing_recommendation',
      );
    }
  }
}
