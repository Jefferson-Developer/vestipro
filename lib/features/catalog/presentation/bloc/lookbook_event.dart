sealed class LookbookEvent {
  const LookbookEvent();
}

final class LookbookStarted extends LookbookEvent {
  const LookbookStarted({
    required this.organizationId,
    required this.campaignId,
  });

  final String organizationId;
  final String campaignId;
}

final class LookbookRelatedProductTapped extends LookbookEvent {
  const LookbookRelatedProductTapped(this.productId);

  final String productId;
}
