import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_context.dart';
import 'insight_rule.dart';
import 'insight_structural_validator.dart';

@lazySingleton
final class InsightEngine {
  InsightEngine(List<InsightRule> rules, this._validator)
    : _rules = List<InsightRule>.unmodifiable(rules);

  final List<InsightRule> _rules;
  final InsightStructuralValidator _validator;

  List<Insight> evaluate(InsightContext context) {
    final all = <Insight>[];
    for (final rule in _rules) {
      all.addAll(rule.evaluate(context));
    }
    for (final insight in all) {
      _validator.validate(insight);
    }

    final deduped = <String, Insight>{};
    for (final insight in all) {
      final existing = deduped[insight.deduplicationKey];
      if (existing == null ||
          _impactScore(insight) > _impactScore(existing) ||
          (_impactScore(insight) == _impactScore(existing) &&
              insight.generatedAt.isAfter(existing.generatedAt))) {
        deduped[insight.deduplicationKey] = insight;
      }
    }

    final insights = deduped.values.toList(growable: false)
      ..sort((left, right) {
        final impact = _impactScore(right).compareTo(_impactScore(left));
        if (impact != 0) {
          return impact;
        }
        return right.generatedAt.compareTo(left.generatedAt);
      });
    return insights;
  }

  double _impactScore(Insight insight) {
    final amount = insight.estimatedImpact.amount ?? 0;
    final percentage = insight.estimatedImpact.percentage ?? 0;
    return amount + (percentage * 1000);
  }
}
