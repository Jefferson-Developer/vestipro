import '../entities/insight.dart';
import '../entities/insight_context.dart';

abstract interface class InsightRule {
  List<Insight> evaluate(InsightContext context);
}
