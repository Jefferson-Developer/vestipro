enum PolicyDocumentType { privacyPolicy, termsOfUse }

extension PolicyDocumentTypeCode on PolicyDocumentType {
  String get code => switch (this) {
    PolicyDocumentType.privacyPolicy => 'privacy_policy',
    PolicyDocumentType.termsOfUse => 'terms_of_use',
  };

  String get label => switch (this) {
    PolicyDocumentType.privacyPolicy => 'Política de Privacidade',
    PolicyDocumentType.termsOfUse => 'Termos de Uso',
  };
}

final class PolicyDocument {
  const PolicyDocument({
    required this.type,
    required this.version,
    required this.content,
    required this.publishedAt,
    this.url,
  });

  final PolicyDocumentType type;
  final String version;
  final String content;
  final DateTime publishedAt;
  final Uri? url;

  String get id => '${type.code}_$version';
}
