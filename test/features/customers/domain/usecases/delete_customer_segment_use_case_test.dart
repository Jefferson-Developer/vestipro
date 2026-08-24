import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('DeleteCustomerSegmentUseCase', () {
    final now = DateTime.utc(2026, 8, 24);

    CustomerSegment segment(String createdBy) {
      return CustomerSegment(
        id: 'segment-1',
        organizationId: 'org-1',
        name: 'Alto potencial SC',
        criteria: CustomerSegmentCriteria.empty,
        visibility: CustomerSegmentVisibility.shared,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        updatedBy: createdBy,
      );
    }

    test('deletes when requested by the creator', () async {
      final repository = _FakeCustomerSegmentRepository();
      final useCase = DeleteCustomerSegmentUseCase(repository);

      final result = await useCase(
        segment: segment('rep-1'),
        requestedBy: 'rep-1',
      );

      expect(result, isA<AppSuccess<void>>());
      expect(repository.deleted.single.id, 'segment-1');
    });

    test('rejects deletion by a user who did not create the segment, even '
        'when it is shared', () async {
      final repository = _FakeCustomerSegmentRepository();
      final useCase = DeleteCustomerSegmentUseCase(repository);

      final result = await useCase(
        segment: segment('rep-1'),
        requestedBy: 'rep-2',
      );

      expect(result, isA<AppFailure<void>>());
      expect(
        (result as AppFailure<void>).failure.code,
        'customer_segment_delete_forbidden',
      );
      expect(repository.deleted, isEmpty);
    });
  });
}

final class _FakeCustomerSegmentRepository
    implements CustomerSegmentRepository {
  final List<({String organizationId, String id})> deleted =
      <({String organizationId, String id})>[];

  @override
  Future<AppResult<CustomerSegment>> create(CustomerSegment segment) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  }) async {
    deleted.add((organizationId: organizationId, id: id));
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<List<CustomerSegment>>> listByOrganization(
    String organizationId,
  ) {
    throw UnimplementedError();
  }
}
