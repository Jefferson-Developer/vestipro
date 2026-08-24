import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CustomerSegment', () {
    final now = DateTime.utc(2026, 8, 24);

    CustomerSegment buildSegment({
      required CustomerSegmentVisibility visibility,
    }) {
      return CustomerSegment(
        id: 'segment-1',
        organizationId: 'org-1',
        name: 'Alto potencial SC',
        criteria: CustomerSegmentCriteria.empty,
        visibility: visibility,
        createdBy: 'rep-1',
        createdAt: now,
        updatedAt: now,
        updatedBy: 'rep-1',
      );
    }

    test('a private segment is only visible to its creator', () {
      final segment = buildSegment(
        visibility: CustomerSegmentVisibility.private,
      );

      expect(segment.isVisibleTo('rep-1'), isTrue);
      expect(segment.isVisibleTo('rep-2'), isFalse);
    });

    test('a shared segment is visible to any user', () {
      final segment = buildSegment(
        visibility: CustomerSegmentVisibility.shared,
      );

      expect(segment.isVisibleTo('rep-1'), isTrue);
      expect(segment.isVisibleTo('rep-2'), isTrue);
    });

    test('only the creator may edit or delete a segment, shared or not', () {
      final privateSegment = buildSegment(
        visibility: CustomerSegmentVisibility.private,
      );
      final sharedSegment = buildSegment(
        visibility: CustomerSegmentVisibility.shared,
      );

      expect(privateSegment.isEditableBy('rep-1'), isTrue);
      expect(privateSegment.isEditableBy('rep-2'), isFalse);
      expect(sharedSegment.isEditableBy('rep-1'), isTrue);
      expect(sharedSegment.isEditableBy('rep-2'), isFalse);
    });
  });
}
