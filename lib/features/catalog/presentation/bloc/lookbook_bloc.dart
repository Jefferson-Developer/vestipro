import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../../domain/usecases/get_campaign_use_case.dart';
import '../../domain/usecases/list_campaign_related_products_use_case.dart';
import 'lookbook_event.dart';
import 'lookbook_state.dart';

/// Drives `LookbookPage` (TASK-080): loads a single `CatalogCampaign` by
/// id, applies the exact same visibility rule every other reader does
/// (`CatalogCampaign.isVisibleAt`) so an inactive/scheduled/expired
/// campaign is indistinguishable from "does not exist" — never a
/// client-side hint about *why* it disappeared — then resolves its related
/// products and logs `campaign_viewed`/`campaign_product_clicked`.
@injectable
final class LookbookBloc extends Bloc<LookbookEvent, LookbookState> {
  LookbookBloc({
    required this.getCampaign,
    required this.listRelatedProducts,
    required this.analyticsService,
    @ignoreParam DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const LookbookState()) {
    on<LookbookStarted>(_onStarted, transformer: restartable());
    on<LookbookRelatedProductTapped>(
      _onRelatedProductTapped,
      transformer: sequential(),
    );
  }

  final GetCampaignUseCase getCampaign;
  final ListCampaignRelatedProductsUseCase listRelatedProducts;
  final AnalyticsService analyticsService;
  final DateTime Function() _now;

  Future<void> _onStarted(
    LookbookStarted event,
    Emitter<LookbookState> emit,
  ) async {
    emit(
      LookbookState(
        status: LookbookStatus.loading,
        organizationId: event.organizationId,
        campaignId: event.campaignId,
      ),
    );

    final result = await getCampaign(
      organizationId: event.organizationId,
      id: event.campaignId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure<CatalogCampaign>(failure: final failure):
        emit(
          state.copyWith(
            status: failure is NotFoundFailure
                ? LookbookStatus.unavailable
                : LookbookStatus.failure,
            failure: failure,
          ),
        );
        return;
      case AppSuccess<CatalogCampaign>(value: final campaign):
        if (!campaign.isVisibleAt(_now().toUtc())) {
          emit(state.copyWith(status: LookbookStatus.unavailable));
          return;
        }

        final relatedResult = await listRelatedProducts(
          organizationId: event.organizationId,
          productIds: campaign.relatedProductIds,
        );
        if (emit.isDone) return;

        switch (relatedResult) {
          case AppSuccess<List<Product>>(value: final products):
            emit(
              state.copyWith(
                status: LookbookStatus.ready,
                campaign: campaign,
                relatedProducts: products,
              ),
            );
          case AppFailure<List<Product>>(failure: final failure):
            // The campaign itself loaded fine — a failure resolving its
            // related products should never hide the whole lookbook, only
            // its carousel (the same "one section failing never derails
            // the rest" rule TASK-076 established for the catalog home).
            emit(
              state.copyWith(
                status: LookbookStatus.ready,
                campaign: campaign,
                relatedProducts: const <Product>[],
                failure: failure,
              ),
            );
        }

        if (!state.hasLoggedView) {
          emit(state.copyWith(hasLoggedView: true));
          await analyticsService.logEvent(
            AnalyticsEvents.campaignViewed,
            parameters: <String, Object?>{
              'organization_id': event.organizationId,
              'campaign_id': campaign.id,
            },
          );
        }
    }
  }

  Future<void> _onRelatedProductTapped(
    LookbookRelatedProductTapped event,
    Emitter<LookbookState> emit,
  ) async {
    final campaign = state.campaign;
    if (campaign == null) return;
    await analyticsService.logEvent(
      AnalyticsEvents.campaignProductClicked,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'campaign_id': campaign.id,
        'product_id': event.productId,
      },
    );
  }
}
