import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../../domain/usecases/delete_campaign_use_case.dart';
import '../../domain/usecases/list_campaigns_use_case.dart';
import 'campaign_list_event.dart';
import 'campaign_list_state.dart';

/// Drives the administrative `CampaignsPage` (TASK-080): lists every
/// campaign of the organization (active, scheduled, expired or inactive —
/// unlike the catalog home's section, this screen must still show what is
/// not currently visible to end users) and soft-deletes one on request.
@injectable
final class CampaignListBloc
    extends Bloc<CampaignListEvent, CampaignListState> {
  CampaignListBloc({
    required this.listCampaigns,
    required this.deleteCampaign,
    @ignoreParam DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(CampaignListState()) {
    on<CampaignListStarted>(_onStarted, transformer: restartable());
    on<CampaignListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<CampaignListSearchChanged>(_onSearchChanged, transformer: sequential());
    on<CampaignListDeleteRequested>(
      _onDeleteRequested,
      transformer: sequential(),
    );
  }

  final ListCampaignsUseCase listCampaigns;
  final DeleteCampaignUseCase deleteCampaign;
  final DateTime Function() _now;

  Future<void> _onStarted(
    CampaignListStarted event,
    Emitter<CampaignListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: CampaignListLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        now: _now().toUtc(),
        clearLoadFailure: true,
      ),
    );
    await _load(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    CampaignListRefreshRequested event,
    Emitter<CampaignListState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: CampaignListLoadStatus.loading,
        now: _now().toUtc(),
        clearLoadFailure: true,
      ),
    );
    await _load(state.organizationId, emit);
  }

  Future<void> _load(
    String organizationId,
    Emitter<CampaignListState> emit,
  ) async {
    final result = await listCampaigns(organizationId);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<List<CatalogCampaign>>(value: final campaigns):
        emit(
          state.copyWith(
            loadStatus: CampaignListLoadStatus.ready,
            campaigns: campaigns,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<List<CatalogCampaign>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CampaignListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    CampaignListSearchChanged event,
    Emitter<CampaignListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onDeleteRequested(
    CampaignListDeleteRequested event,
    Emitter<CampaignListState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStatus: CampaignListDeleteStatus.deleting,
        clearDeleteFailure: true,
      ),
    );
    final result = await deleteCampaign(
      organizationId: state.organizationId,
      id: event.campaign.id,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<CatalogCampaign>():
        emit(
          state.copyWith(
            deleteStatus: CampaignListDeleteStatus.success,
            campaigns: state.campaigns
                .where((campaign) => campaign.id != event.campaign.id)
                .toList(growable: false),
          ),
        );
        emit(state.copyWith(deleteStatus: CampaignListDeleteStatus.idle));
      case AppFailure<CatalogCampaign>(failure: final failure):
        emit(
          state.copyWith(
            deleteStatus: CampaignListDeleteStatus.failure,
            deleteFailure: failure,
          ),
        );
    }
  }
}
