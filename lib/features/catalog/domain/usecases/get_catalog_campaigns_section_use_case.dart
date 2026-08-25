import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';
import '../entities/catalog_home_item.dart';
import '../entities/catalog_home_section.dart';
import '../entities/catalog_home_section_config.dart';
import '../repositories/catalog_campaign_repository.dart';

/// Builds the catalog home's "campanhas em destaque" section (TASK-076)
/// from the `CatalogCampaign`s of [organizationId] currently visible at
/// [now] (`CatalogCampaign.isVisibleAt`) — inactive, soft-deleted or
/// out-of-window campaigns are filtered out here, never left for the widget
/// to hide (TASK-076: "nenhuma seção pode simular urgência falsa").
@injectable
final class GetCatalogCampaignsSectionUseCase {
  GetCatalogCampaignsSectionUseCase(this._campaignRepository);

  final CatalogCampaignRepository _campaignRepository;

  Future<AppResult<CatalogHomeSection>> call({
    required String organizationId,
    required CatalogHomeSectionConfig config,
    DateTime? now,
  }) async {
    final result = await _campaignRepository.listByOrganization(
      organizationId.trim(),
    );
    final effectiveNow = now ?? DateTime.now().toUtc();

    return result.fold(
      onSuccess: (campaigns) {
        final visible =
            campaigns
                .where((campaign) => campaign.isVisibleAt(effectiveNow))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));

        return AppSuccess<CatalogHomeSection>(
          CatalogHomeSection(
            type: config.type,
            title: config.title,
            order: config.order,
            priority: config.priority,
            items: visible
                .take(config.itemLimit)
                .map(_toItem)
                .toList(growable: false),
          ),
        );
      },
      onFailure: (failure) => AppFailure<CatalogHomeSection>(failure),
    );
  }

  CatalogHomeItem _toItem(CatalogCampaign campaign) {
    return CatalogHomeItem(
      id: campaign.id,
      title: campaign.title,
      subtitle: campaign.subtitle,
      imageUrl: campaign.imageUrl,
    );
  }
}
