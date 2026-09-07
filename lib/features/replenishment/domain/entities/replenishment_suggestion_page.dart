import 'replenishment_suggestion.dart';

final class ReplenishmentSuggestionPage {
  const ReplenishmentSuggestionPage({
    required this.suggestions,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ReplenishmentSuggestion> suggestions;
  final bool hasMore;
  final DateTime? nextCursor;
}
