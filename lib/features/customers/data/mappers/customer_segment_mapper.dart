import 'package:injectable/injectable.dart';

import '../../domain/entities/customer_segment.dart';
import '../../domain/entities/customer_segment_criteria.dart';
import '../../domain/value_objects/customer_segment_visibility.dart';
import '../dtos/customer_segment_dto.dart';

@lazySingleton
final class CustomerSegmentMapper {
  const CustomerSegmentMapper();

  CustomerSegment toEntity(CustomerSegmentDto dto) {
    return CustomerSegment(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      criteria: CustomerSegmentCriteria.fromJson(<String, dynamic>{
        'statuses': dto.statuses,
        'stateCodes': dto.stateCodes,
        'potentials': dto.potentials,
        'lastPurchase': dto.lastPurchase,
        'purchasedCategoryCodes': dto.purchasedCategoryCodes,
      }),
      visibility: CustomerSegmentVisibilityCode.fromCode(dto.visibility),
      createdBy: dto.createdBy,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      version: dto.version,
    );
  }

  CustomerSegmentDto toDto(CustomerSegment segment) {
    final criteriaJson = segment.criteria.normalized().toJson();
    return CustomerSegmentDto(
      id: segment.id,
      organizationId: segment.organizationId,
      name: segment.name,
      visibility: segment.visibility.code,
      statuses: List<String>.from(criteriaJson['statuses'] as List<dynamic>),
      stateCodes: List<String>.from(
        criteriaJson['stateCodes'] as List<dynamic>,
      ),
      potentials: List<String>.from(
        criteriaJson['potentials'] as List<dynamic>,
      ),
      lastPurchase: criteriaJson['lastPurchase'] as String,
      purchasedCategoryCodes: List<String>.from(
        criteriaJson['purchasedCategoryCodes'] as List<dynamic>,
      ),
      createdBy: segment.createdBy,
      createdAt: segment.createdAt,
      updatedAt: segment.updatedAt,
      updatedBy: segment.updatedBy,
      version: segment.version,
    );
  }
}
