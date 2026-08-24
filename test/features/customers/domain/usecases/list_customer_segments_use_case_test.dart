import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('ListCustomerSegmentsUseCase', () {
    final now = DateTime.utc(2026, 8, 24);

    CustomerSegment segment({
      required String id,
      required String createdBy,
      required CustomerSegmentVisibility visibility,
    }) {
      return CustomerSegment(
        id: id,
        organizationId: 'org-1',
        name: id,
        criteria: CustomerSegmentCriteria.empty,
        visibility: visibility,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        updatedBy: createdBy,
      );
    }

    test('a private segment created by another user does not appear, a shared '
        'one does', () async {
      final repository = _FakeCustomerSegmentRepository(<CustomerSegment>[
        segment(
          id: 'private-mine',
          createdBy: 'rep-1',
          visibility: CustomerSegmentVisibility.private,
        ),
        segment(
          id: 'private-other',
          createdBy: 'rep-2',
          visibility: CustomerSegmentVisibility.private,
        ),
        segment(
          id: 'shared-other',
          createdBy: 'rep-2',
          visibility: CustomerSegmentVisibility.shared,
        ),
      ]);
      final useCase = ListCustomerSegmentsUseCase(repository);

      final result = await useCase(organizationId: 'org-1', userId: 'rep-1');

      expect(result, isA<AppSuccess<List<CustomerSegment>>>());
      final ids = (result as AppSuccess<List<CustomerSegment>>).value
          .map((segment) => segment.id)
          .toSet();
      expect(ids, <String>{'private-mine', 'shared-other'});
      expect(ids.contains('private-other'), isFalse);
    });

    test('rejects a missing userId explicitly', () async {
      final repository = _FakeCustomerSegmentRepository(<CustomerSegment>[]);
      final useCase = ListCustomerSegmentsUseCase(repository);

      final result = await useCase(organizationId: 'org-1', userId: '');

      expect(result, isA<AppFailure<List<CustomerSegment>>>());
    });
  });
}

final class _FakeCustomerSegmentRepository
    implements CustomerSegmentRepository {
  _FakeCustomerSegmentRepository(this._segments);

  final List<CustomerSegment> _segments;

  @override
  Future<AppResult<CustomerSegment>> create(CustomerSegment segment) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<CustomerSegment>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<CustomerSegment>>(
      _segments
          .where((segment) => segment.organizationId == organizationId)
          .toList(growable: false),
    );
  }
}
