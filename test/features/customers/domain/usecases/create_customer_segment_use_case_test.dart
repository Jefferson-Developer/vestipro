import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CreateCustomerSegmentUseCase', () {
    test('creates a segment with normalized criteria', () async {
      final repository = _FakeCustomerSegmentRepository();
      final useCase = CreateCustomerSegmentUseCase(repository);

      final result = await useCase(
        id: 'segment-1',
        organizationId: 'org-1',
        name: '  Alto potencial SC  ',
        criteria: const CustomerSegmentCriteria(
          portfolioFilters: CustomerPortfolioFilters(
            stateCodes: <String>{'sc'},
          ),
        ),
        visibility: CustomerSegmentVisibility.shared,
        createdBy: 'rep-1',
        now: DateTime.utc(2026, 8, 24),
      );

      expect(result, isA<AppSuccess<CustomerSegment>>());
      final segment = (result as AppSuccess<CustomerSegment>).value;
      expect(segment.name, 'Alto potencial SC');
      expect(segment.criteria.portfolioFilters.stateCodes, <String>{'SC'});
      expect(segment.visibility, CustomerSegmentVisibility.shared);
      expect(repository.created.single.id, 'segment-1');
    });

    test('rejects an empty name explicitly', () async {
      final repository = _FakeCustomerSegmentRepository();
      final useCase = CreateCustomerSegmentUseCase(repository);

      final result = await useCase(
        id: 'segment-1',
        organizationId: 'org-1',
        name: '   ',
        createdBy: 'rep-1',
      );

      expect(result, isA<AppFailure<CustomerSegment>>());
      expect(
        (result as AppFailure<CustomerSegment>).failure.code,
        'invalid_customer_segment_payload',
      );
      expect(repository.created, isEmpty);
    });
  });
}

final class _FakeCustomerSegmentRepository
    implements CustomerSegmentRepository {
  final List<CustomerSegment> created = <CustomerSegment>[];

  @override
  Future<AppResult<CustomerSegment>> create(CustomerSegment segment) async {
    created.add(segment);
    return AppSuccess<CustomerSegment>(segment);
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
  ) {
    throw UnimplementedError();
  }
}
