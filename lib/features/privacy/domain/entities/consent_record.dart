enum ConsentPurpose {
  location(
    code: 'location',
    label: 'Localização',
    description:
        'Permite usar sua localização em roteirização, visitas e check-ins.',
  ),
  marketing(
    code: 'marketing',
    label: 'Marketing e novidades',
    description:
        'Permite receber novidades, dicas e comunicações promocionais da VestiPro.',
  );

  const ConsentPurpose({
    required this.code,
    required this.label,
    required this.description,
  });

  final String code;
  final String label;
  final String description;
}

/// Immutable audit event for one explicit consent decision.
final class ConsentRecord {
  const ConsentRecord({
    required this.organizationId,
    required this.userId,
    required this.purpose,
    required this.granted,
    required this.recordedAt,
    this.id = '',
  });

  final String id;
  final String organizationId;
  final String userId;
  final ConsentPurpose purpose;
  final bool granted;
  final DateTime recordedAt;
}
