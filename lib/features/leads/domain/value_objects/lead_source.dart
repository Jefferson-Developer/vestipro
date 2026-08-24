import '../../../../core/errors/errors.dart';

/// Origin of a Lead captured by the sales funnel entry point.
///
/// Organizations may configure additional custom sources beyond the
/// defaults. The stable [code] is what gets persisted, while [label] is what
/// the UI shows to the sales rep.
final class LeadSource {
  const LeadSource._({
    required this.code,
    required this.label,
    this.isCustom = false,
  });

  factory LeadSource.custom(String value, {String? label}) {
    final raw = value.trim();
    final rawLabel = label?.trim();
    if (raw.isEmpty && (rawLabel == null || rawLabel.isEmpty)) {
      throw const ValidationException(
        'Invalid lead source.',
        code: 'invalid_lead_source',
        fieldErrors: <String, String>{'source': 'Lead source is required.'},
      );
    }

    final typeLabel = (rawLabel != null && rawLabel.isNotEmpty)
        ? rawLabel
        : raw;
    final normalizedCode = _normalizeLeadSourceCode(
      raw.isEmpty ? typeLabel : raw,
    );
    final standard = leadSourceFromCode(normalizedCode);
    if (standard != null) return standard;

    return LeadSource._(
      code: normalizedCode,
      label: typeLabel.isEmpty ? normalizedCode : typeLabel,
      isCustom: true,
    );
  }

  static const referral = LeadSource._(code: 'referral', label: 'Indicacao');
  static const event = LeadSource._(code: 'event', label: 'Evento');
  static const website = LeadSource._(code: 'website', label: 'Site');
  static const socialMedia = LeadSource._(
    code: 'social_media',
    label: 'Redes sociais',
  );
  static const activeProspecting = LeadSource._(
    code: 'active_prospecting',
    label: 'Prospeccao ativa',
  );
  static const other = LeadSource._(code: 'other', label: 'Outro');

  static const defaults = <LeadSource>[
    referral,
    event,
    website,
    socialMedia,
    activeProspecting,
    other,
  ];

  final String code;
  final String label;
  final bool isCustom;

  @override
  bool operator ==(Object other) {
    return other is LeadSource && other.code == code && other.label == label;
  }

  @override
  int get hashCode => Object.hash(code, label);

  @override
  String toString() => label;
}

LeadSource? leadSourceFromCode(String code, {String? label}) {
  final normalized = _normalizeLeadSourceCode(code);
  return switch (normalized) {
    'referral' => LeadSource.referral,
    'indicacao' => LeadSource.referral,
    'event' => LeadSource.event,
    'evento' => LeadSource.event,
    'website' => LeadSource.website,
    'site' => LeadSource.website,
    'social_media' => LeadSource.socialMedia,
    'redes_sociais' => LeadSource.socialMedia,
    'active_prospecting' => LeadSource.activeProspecting,
    'prospeccao_ativa' => LeadSource.activeProspecting,
    'other' => LeadSource.other,
    'outro' => LeadSource.other,
    _ when label != null && label.trim().isNotEmpty => LeadSource._(
      code: normalized,
      label: label.trim(),
      isCustom: true,
    ),
    _ => null,
  };
}

String _normalizeLeadSourceCode(String value) {
  final withoutDiacritics = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàãâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòõôö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
  final normalized = withoutDiacritics.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return normalized
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
