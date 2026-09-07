import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/replenishment/replenishment.dart';

void main() {
  group('parseReplenishmentSuggestionStatus', () {
    test('parses every known status code', () {
      expect(
        parseReplenishmentSuggestionStatus('suggested'),
        ReplenishmentSuggestionStatus.suggested,
      );
      expect(
        parseReplenishmentSuggestionStatus('insufficientData'),
        ReplenishmentSuggestionStatus.insufficientData,
      );
      expect(
        parseReplenishmentSuggestionStatus('accepted'),
        ReplenishmentSuggestionStatus.accepted,
      );
      expect(
        parseReplenishmentSuggestionStatus('adjusted'),
        ReplenishmentSuggestionStatus.adjusted,
      );
      expect(
        parseReplenishmentSuggestionStatus('discarded'),
        ReplenishmentSuggestionStatus.discarded,
      );
    });

    test('throws ArgumentError for an unknown status', () {
      expect(
        () => parseReplenishmentSuggestionStatus('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('ReplenishmentSuggestionStatusCode.isDecided', () {
    test('is true only for accepted/adjusted/discarded', () {
      expect(ReplenishmentSuggestionStatus.suggested.isDecided, isFalse);
      expect(ReplenishmentSuggestionStatus.insufficientData.isDecided, isFalse);
      expect(ReplenishmentSuggestionStatus.accepted.isDecided, isTrue);
      expect(ReplenishmentSuggestionStatus.adjusted.isDecided, isTrue);
      expect(ReplenishmentSuggestionStatus.discarded.isDecided, isTrue);
    });
  });
}
