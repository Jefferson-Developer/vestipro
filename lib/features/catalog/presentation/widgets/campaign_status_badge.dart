import 'package:flutter/widgets.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/catalog_campaign_status.dart';

/// Renders a `CatalogCampaignStatus` as the Design System's status pill
/// (TASK-080), shared by `CampaignsPage` (list row) and `CampaignFormPage`
/// (header) so both screens describe "ativa/agendada/expirada/inativa" with
/// the exact same label/color, never two independent switch-statements
/// drifting apart.
class CampaignStatusBadge extends StatelessWidget {
  const CampaignStatusBadge({required this.status, super.key});

  final CatalogCampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (status) {
      CatalogCampaignStatus.active => ('Ativa', AppStatusBadgeVariant.success),
      CatalogCampaignStatus.scheduled => (
        'Agendada',
        AppStatusBadgeVariant.info,
      ),
      CatalogCampaignStatus.expired => (
        'Expirada',
        AppStatusBadgeVariant.neutral,
      ),
      CatalogCampaignStatus.inactive => (
        'Inativa',
        AppStatusBadgeVariant.warning,
      ),
    };
    return AppStatusBadge(label: label, variant: variant);
  }
}
