import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer_form_draft.dart';
import '../../domain/value_objects/customer_type.dart';
import '../dtos/customer_form_draft_dto.dart';

@lazySingleton
final class CustomerFormDraftMapper {
  const CustomerFormDraftMapper();

  CustomerFormDraft toEntity(CustomerFormDraftDto dto) {
    return CustomerFormDraft(
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      userId: dto.userId,
      type: _typeToEntity(dto.type),
      document: dto.document,
      legalName: dto.legalName,
      tradeName: dto.tradeName,
      fullName: dto.fullName,
      stateRegistration: dto.stateRegistration,
      primaryEmail: dto.primaryEmail,
      primaryPhone: dto.primaryPhone,
      classification: dto.classification,
      potential: dto.potential,
      responsibleSellerId: dto.responsibleSellerId,
      savedAt: dto.savedAt,
    );
  }

  CustomerFormDraftDto toDto(CustomerFormDraft entity) {
    return CustomerFormDraftDto(
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      userId: entity.userId,
      type: _typeToDto(entity.type),
      document: entity.document,
      legalName: entity.legalName,
      tradeName: entity.tradeName,
      fullName: entity.fullName,
      stateRegistration: entity.stateRegistration,
      primaryEmail: entity.primaryEmail,
      primaryPhone: entity.primaryPhone,
      classification: entity.classification,
      potential: entity.potential,
      responsibleSellerId: entity.responsibleSellerId,
      savedAt: entity.savedAt,
    );
  }

  CustomerType _typeToEntity(String value) {
    return switch (value) {
      'legalEntity' => CustomerType.legalEntity,
      'individual' => CustomerType.individual,
      _ => throw ValidationException(
        'Invalid customer draft type.',
        code: 'invalid_customer_draft_type',
        cause: value,
      ),
    };
  }

  String _typeToDto(CustomerType type) {
    return switch (type) {
      CustomerType.legalEntity => 'legalEntity',
      CustomerType.individual => 'individual',
    };
  }
}
