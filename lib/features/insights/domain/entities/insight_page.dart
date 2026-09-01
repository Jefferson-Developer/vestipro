import 'insight.dart';

final class InsightPage {
  const InsightPage({
    required this.insights,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Insight> insights;
  final bool hasMore;
  final DateTime? nextCursor;
}
