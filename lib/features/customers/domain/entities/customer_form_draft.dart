import '../value_objects/customer_type.dart';

/// Persisted local draft for an unfinished customer form.
final class CustomerFormDraft {
  const CustomerFormDraft({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.document,
    this.legalName,
    this.tradeName,
    this.fullName,
    this.stateRegistration,
    this.primaryEmail,
    this.primaryPhone,
    this.classification,
    this.potential,
    this.responsibleSellerId,
    required this.savedAt,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final CustomerType type;
  final String document;
  final String? legalName;
  final String? tradeName;
  final String? fullName;
  final String? stateRegistration;
  final String? primaryEmail;
  final String? primaryPhone;
  final String? classification;
  final String? potential;
  final String? responsibleSellerId;
  final DateTime savedAt;
}
