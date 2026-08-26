import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_share.dart';
import '../../domain/entities/issued_catalog_share.dart';
import '../../domain/usecases/create_catalog_share_link_use_case.dart';
import '../../domain/usecases/get_catalog_share_use_case.dart';
import '../../domain/value_objects/catalog_share_scope.dart';
import 'catalog_share_sheet_event.dart';
import 'catalog_share_sheet_state.dart';

/// Orchestrates the "Compartilhar" sheet opened from the catalog grid/detail
/// (TASK-081, EPIC-10): creates the share as soon as it opens, exposes the
/// shareable link, and lets the vendor refresh it later to see whether/when
/// the recipient opened it.
@injectable
final class CatalogShareSheetBloc
    extends Bloc<CatalogShareSheetEvent, CatalogShareSheetState> {
  CatalogShareSheetBloc({
    required this.createCatalogShareLink,
    required this.getCatalogShare,
    required this.analyticsService,
  }) : super(const CatalogShareSheetState()) {
    on<CatalogShareSheetStarted>(_onStarted, transformer: restartable());
    on<CatalogShareSheetRetried>(_onRetried, transformer: droppable());
    on<CatalogShareSheetRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
  }

  final CreateCatalogShareLinkUseCase createCatalogShareLink;
  final GetCatalogShareUseCase getCatalogShare;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    CatalogShareSheetStarted event,
    Emitter<CatalogShareSheetState> emit,
  ) async {
    emit(
      CatalogShareSheetState(
        status: CatalogShareSheetStatus.submitting,
        organizationId: event.organizationId,
        scope: event.scope,
        items: event.items,
        collectionId: event.collectionId,
        collectionName: event.collectionName,
      ),
    );
    await _create(emit);
  }

  Future<void> _onRetried(
    CatalogShareSheetRetried event,
    Emitter<CatalogShareSheetState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.items.isEmpty) return;
    emit(
      state.copyWith(
        status: CatalogShareSheetStatus.submitting,
        clearFailure: true,
      ),
    );
    await _create(emit);
  }

  Future<void> _create(Emitter<CatalogShareSheetState> emit) async {
    final result = await createCatalogShareLink(
      organizationId: state.organizationId,
      scope: state.scope,
      items: state.items,
      collectionId: state.collectionId,
      collectionName: state.collectionName,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<IssuedCatalogShare>(value: final issued):
        emit(
          state.copyWith(
            status: CatalogShareSheetStatus.success,
            issuedShare: issued,
            clearFailure: true,
          ),
        );
        await analyticsService.logEvent(
          AnalyticsEvents.catalogShareCreated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'scope': issued.share.scope.code,
            'items_count': issued.share.items.length,
          },
        );
      case AppFailure<IssuedCatalogShare>(failure: final failure):
        emit(
          state.copyWith(
            status: CatalogShareSheetStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onRefreshRequested(
    CatalogShareSheetRefreshRequested event,
    Emitter<CatalogShareSheetState> emit,
  ) async {
    final issued = state.issuedShare;
    if (issued == null || state.isRefreshing) return;

    emit(state.copyWith(isRefreshing: true));
    final result = await getCatalogShare(
      organizationId: state.organizationId,
      shareId: issued.share.id,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<CatalogShare>(value: final share):
        emit(state.copyWith(refreshedShare: share, isRefreshing: false));
      case AppFailure<CatalogShare>():
        // Refreshing the open-count is a nice-to-have, not the sheet's main
        // purpose — a failure here never disturbs the already-shown link.
        emit(state.copyWith(isRefreshing: false));
    }
  }
}
