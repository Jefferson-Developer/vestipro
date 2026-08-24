import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_segment.dart';
import '../repositories/customer_segment_repository.dart';

/// Deletes a [CustomerSegment], enforced to the creator only: sharing a
/// segment lets others apply it, but never edit or remove it (TASK-053).
@injectable
final class DeleteCustomerSegmentUseCase {
  const DeleteCustomerSegmentUseCase(this._repository);

  final CustomerSegmentRepository _repository;

  Future<AppResult<void>> call({
    required CustomerSegment segment,
    required String requestedBy,
  }) async {
    if (!segment.isEditableBy(requestedBy.trim())) {
      return const AppFailure<void>(
        PermissionFailure(
          'Only the segment creator can delete it.',
          code: 'customer_segment_delete_forbidden',
        ),
      );
    }

    return _repository.delete(
      organizationId: segment.organizationId,
      id: segment.id,
    );
  }
}
