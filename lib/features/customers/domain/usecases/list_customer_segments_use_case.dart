import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_segment.dart';
import '../repositories/customer_segment_repository.dart';

/// Lists the [CustomerSegment]s a user may see for an organization,
/// enforcing TASK-053's RBAC rule: private segments only show up for their
/// creator, shared segments show up for everyone.
@injectable
final class ListCustomerSegmentsUseCase {
  const ListCustomerSegmentsUseCase(this._repository);

  final CustomerSegmentRepository _repository;

  Future<AppResult<List<CustomerSegment>>> call({
    required String organizationId,
    required String userId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedOrganizationId.isEmpty || trimmedUserId.isEmpty) {
      return const AppFailure<List<CustomerSegment>>(
        ValidationFailure(
          'Invalid customer segment listing payload.',
          code: 'invalid_customer_segment_list_payload',
        ),
      );
    }

    final result = await _repository.listByOrganization(trimmedOrganizationId);
    return switch (result) {
      AppSuccess<List<CustomerSegment>>(value: final segments) =>
        AppSuccess<List<CustomerSegment>>(
          segments
              .where((segment) => segment.isVisibleTo(trimmedUserId))
              .toList(growable: false)
            ..sort(
              (first, second) =>
                  first.name.toLowerCase().compareTo(second.name.toLowerCase()),
            ),
        ),
      AppFailure<List<CustomerSegment>>() => result,
    };
  }
}
