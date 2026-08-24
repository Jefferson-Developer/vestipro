import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_segment.dart';
import '../entities/customer_segment_criteria.dart';
import '../repositories/customer_segment_repository.dart';
import '../value_objects/customer_segment_visibility.dart';

@injectable
final class CreateCustomerSegmentUseCase {
  const CreateCustomerSegmentUseCase(this._repository);

  final CustomerSegmentRepository _repository;

  Future<AppResult<CustomerSegment>> call({
    required String id,
    required String organizationId,
    required String name,
    CustomerSegmentCriteria criteria = CustomerSegmentCriteria.empty,
    CustomerSegmentVisibility visibility = CustomerSegmentVisibility.private,
    required String createdBy,
    DateTime? now,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CustomerSegment>(
        ValidationFailure(
          'Invalid customer segment payload.',
          code: 'invalid_customer_segment_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final effectiveNow = (now ?? DateTime.now()).toUtc();
    final segment = CustomerSegment(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      criteria: criteria.normalized(),
      visibility: visibility,
      createdBy: trimmedCreatedBy,
      createdAt: effectiveNow,
      updatedAt: effectiveNow,
      updatedBy: trimmedCreatedBy,
      version: 1,
    );

    return _repository.create(segment);
  }
}
