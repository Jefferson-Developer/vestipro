import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/fulfillment/fulfillment.dart';

void main() {
  group('LogisticsIssueType.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final type in LogisticsIssueType.values) {
        expect(LogisticsIssueType.fromCode(type.code), type);
      }
    });

    test('throws for an unknown code', () {
      expect(
        () => LogisticsIssueType.fromCode('lost_in_space'),
        throwsArgumentError,
      );
    });
  });

  group('LogisticsIssueStatus.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final status in LogisticsIssueStatus.values) {
        expect(LogisticsIssueStatus.fromCode(status.code), status);
      }
    });

    test('throws for an unknown code', () {
      expect(
        () => LogisticsIssueStatus.fromCode('teleported'),
        throwsArgumentError,
      );
    });
  });
}
