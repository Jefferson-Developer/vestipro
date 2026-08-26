import '../../../../core/errors/errors.dart';
import '../../domain/entities/catalog_campaign.dart';

enum CampaignListLoadStatus { loading, ready, failure }

enum CampaignListDeleteStatus { idle, deleting, success, failure }

/// State for `CampaignListBloc` (TASK-080)'s administrative campaign list.
///
/// [now] is captured once per load (`_onStarted`/`_onRefreshRequested`),
/// never read fresh from `DateTime.now()` inside the widget tree: every row
/// derives its `CatalogCampaignStatus` label from the exact same instant,
/// so a screen showing many rows never shows two campaigns disagreeing
/// about "what time is it" just because a frame rendered a few
/// milliseconds apart.
final class CampaignListState {
  CampaignListState({
    this.loadStatus = CampaignListLoadStatus.loading,
    this.deleteStatus = CampaignListDeleteStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.campaigns = const <CatalogCampaign>[],
    this.searchQuery = '',
    this.loadFailure,
    this.deleteFailure,
    DateTime? now,
  }) : now = now ?? DateTime.now().toUtc();

  final CampaignListLoadStatus loadStatus;
  final CampaignListDeleteStatus deleteStatus;
  final String organizationId;
  final String userId;
  final List<CatalogCampaign> campaigns;
  final String searchQuery;
  final Failure? loadFailure;
  final Failure? deleteFailure;
  final DateTime now;

  List<CatalogCampaign> get filteredCampaigns {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return campaigns;
    return campaigns
        .where((campaign) => campaign.title.toLowerCase().contains(query))
        .toList(growable: false);
  }

  CampaignListState copyWith({
    CampaignListLoadStatus? loadStatus,
    CampaignListDeleteStatus? deleteStatus,
    String? organizationId,
    String? userId,
    List<CatalogCampaign>? campaigns,
    String? searchQuery,
    Failure? loadFailure,
    Failure? deleteFailure,
    DateTime? now,
    bool clearLoadFailure = false,
    bool clearDeleteFailure = false,
  }) {
    return CampaignListState(
      loadStatus: loadStatus ?? this.loadStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      campaigns: campaigns ?? this.campaigns,
      searchQuery: searchQuery ?? this.searchQuery,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      deleteFailure: clearDeleteFailure
          ? null
          : deleteFailure ?? this.deleteFailure,
      now: now ?? this.now,
    );
  }
}
