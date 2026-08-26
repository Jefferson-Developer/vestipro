import 'dart:typed_data';

import '../../../products/domain/entities/product.dart';
import '../../domain/entities/catalog_campaign.dart';

sealed class CampaignFormEvent {
  const CampaignFormEvent();
}

final class CampaignFormStarted extends CampaignFormEvent {
  const CampaignFormStarted({
    required this.organizationId,
    required this.userId,
    this.initialCampaign,
  });

  final String organizationId;
  final String userId;
  final CatalogCampaign? initialCampaign;
}

final class CampaignFormTitleChanged extends CampaignFormEvent {
  const CampaignFormTitleChanged(this.title);

  final String title;
}

final class CampaignFormSubtitleChanged extends CampaignFormEvent {
  const CampaignFormSubtitleChanged(this.subtitle);

  final String subtitle;
}

final class CampaignFormDescriptionChanged extends CampaignFormEvent {
  const CampaignFormDescriptionChanged(this.description);

  final String description;
}

final class CampaignFormStartAtChanged extends CampaignFormEvent {
  const CampaignFormStartAtChanged(this.startAt);

  final DateTime? startAt;
}

final class CampaignFormEndAtChanged extends CampaignFormEvent {
  const CampaignFormEndAtChanged(this.endAt);

  final DateTime? endAt;
}

final class CampaignFormActiveChanged extends CampaignFormEvent {
  const CampaignFormActiveChanged(this.active);

  final bool active;
}

final class CampaignFormCoverImagePicked extends CampaignFormEvent {
  const CampaignFormCoverImagePicked(this.bytes);

  final Uint8List bytes;
}

final class CampaignFormCoverImageRemoved extends CampaignFormEvent {
  const CampaignFormCoverImageRemoved();
}

final class CampaignFormEditorialImagePicked extends CampaignFormEvent {
  const CampaignFormEditorialImagePicked(this.bytes);

  final Uint8List bytes;
}

final class CampaignFormEditorialImagesReordered extends CampaignFormEvent {
  const CampaignFormEditorialImagesReordered(this.orderedUrls);

  final List<String> orderedUrls;
}

final class CampaignFormEditorialImageRemoved extends CampaignFormEvent {
  const CampaignFormEditorialImageRemoved(this.url);

  final String url;
}

final class CampaignFormRelatedProductAdded extends CampaignFormEvent {
  const CampaignFormRelatedProductAdded(this.product);

  final Product product;
}

final class CampaignFormRelatedProductRemoved extends CampaignFormEvent {
  const CampaignFormRelatedProductRemoved(this.productId);

  final String productId;
}

final class CampaignFormSubmitted extends CampaignFormEvent {
  const CampaignFormSubmitted();
}
