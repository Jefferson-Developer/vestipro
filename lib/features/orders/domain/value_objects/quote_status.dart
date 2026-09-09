enum QuoteStatus { draft, sent, expired, converted, declined }

extension QuoteStatusX on QuoteStatus {
  String get wireName {
    return switch (this) {
      QuoteStatus.draft => 'draft',
      QuoteStatus.sent => 'sent',
      QuoteStatus.expired => 'expired',
      QuoteStatus.converted => 'converted',
      QuoteStatus.declined => 'declined',
    };
  }

  bool get canConvert => this == QuoteStatus.sent;
}

QuoteStatus quoteStatusFromWire(String value) {
  return switch (value) {
    'draft' => QuoteStatus.draft,
    'sent' => QuoteStatus.sent,
    'expired' => QuoteStatus.expired,
    'converted' => QuoteStatus.converted,
    'declined' => QuoteStatus.declined,
    _ => QuoteStatus.draft,
  };
}
