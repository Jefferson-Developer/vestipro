/// One item whose current price-list price no longer matches what the buyer
/// approved — returned by `convertBuyerCollaborationSession` as a
/// defense-in-depth revalidation at the moment of conversion (`tasks.md`:
/// "toda alteração proposta precisa ser revalidada contra preço [...] no
/// momento da conversão"). [currentUnitPrice] is `null` when the
/// variant is no longer present in the price list at all.
final class BuyerCollaborationPriceDrift {
  const BuyerCollaborationPriceDrift({
    required this.itemId,
    required this.variantId,
    required this.approvedUnitPrice,
    this.currentUnitPrice,
  });

  final String itemId;
  final String variantId;
  final double approvedUnitPrice;
  final double? currentUnitPrice;
}

/// Result of `ConvertBuyerCollaborationSessionUseCase` — [converted] is
/// `false` when a price drift was detected and the caller did not pass
/// `acceptPriceDrift`, in which case [orderId] stays `null` and the caller
/// must show [priceDrift] before retrying with the flag set.
final class BuyerCollaborationConversionResult {
  const BuyerCollaborationConversionResult({
    required this.converted,
    this.orderId,
    this.priceDrift = const <BuyerCollaborationPriceDrift>[],
  });

  final bool converted;
  final String? orderId;
  final List<BuyerCollaborationPriceDrift> priceDrift;
}
